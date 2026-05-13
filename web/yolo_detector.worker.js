/**
 * yolo_detector.worker.js
 * Web Worker for YOLOv8n-seg inference via ONNX Runtime Web.
 *
 * Processes camera frames and returns detection + segmentation results
 * matching the native TFLite detector_service.dart output format.
 *
 * Architecture:
 *   Main thread → postMessage({type:'detect', imageData, width, height})
 *   Worker      → ONNX inference → postMessage({type:'result', result})
 *
 * Model specs (matching native):
 *   Input:   [1, 3, 320, 320] float32 (RGB, normalized 0-1)
 *   Output0: [1, 116, 2100] — 2100 proposals × (4 box + 80 classes + 32 mask coeffs)
 *   Output1: [1, 32, 80, 80] — 32 prototype masks at 80×80
 */

// ONNX Runtime Web — bundled locally (no CDN dependency)
importScripts('ort.min.js');

const MODEL_INPUT_SIZE = 320;
const NUM_CLASSES = 80;
const NUM_MASK_COEFFS = 32;
const PROTO_H = 80;
const PROTO_W = 80;
const CONF_THRESHOLD = 0.25;
const IOU_THRESHOLD = 0.45;

// COCO class names (80 classes — matching the native labelmap.txt)
const COCO_CLASSES = [
  'person', 'bicycle', 'car', 'motorcycle', 'airplane', 'bus', 'train', 'truck', 'boat',
  'traffic light', 'fire hydrant', 'stop sign', 'parking meter', 'bench', 'bird', 'cat',
  'dog', 'horse', 'sheep', 'cow', 'elephant', 'bear', 'zebra', 'giraffe', 'backpack',
  'umbrella', 'handbag', 'tie', 'suitcase', 'frisbee', 'skis', 'snowboard', 'sports ball',
  'kite', 'baseball bat', 'baseball glove', 'skateboard', 'surfboard', 'tennis racket',
  'bottle', 'wine glass', 'cup', 'fork', 'knife', 'spoon', 'bowl', 'banana', 'apple',
  'sandwich', 'orange', 'broccoli', 'carrot', 'hot dog', 'pizza', 'donut', 'cake', 'chair',
  'couch', 'potted plant', 'bed', 'dining table', 'toilet', 'tv', 'laptop', 'mouse',
  'remote', 'keyboard', 'cell phone', 'microwave', 'oven', 'toaster', 'sink',
  'refrigerator', 'book', 'clock', 'vase', 'scissors', 'teddy bear', 'hair drier',
  'toothbrush'
];

let session = null;
let isReady = false;

/**
 * Initialize ONNX Runtime session with the YOLOv8n-seg model.
 */
async function initModel(modelUrl) {
  try {
    console.log('YOLO Worker: Loading model from', modelUrl);
    var t0 = performance.now();
    
    // Configure ONNX Runtime WASM backend
    ort.env.wasm.wasmPaths = './';  // Local WASM files
    // Single-threaded: avoids SharedArrayBuffer COOP/COEP issues
    // SIMD is auto-detected from ort-wasm-simd.wasm (2-3x faster than plain WASM)
    ort.env.wasm.numThreads = 1;
    
    // Fetch the model file
    var response = await fetch(modelUrl);
    if (!response.ok) {
      throw new Error('Failed to fetch model: ' + response.status + ' ' + response.statusText);
    }
    var modelBuffer = await response.arrayBuffer();
    var t1 = performance.now();
    console.log('YOLO Worker: Model fetched in ' + (t1-t0).toFixed(0) + 'ms (' + (modelBuffer.byteLength/1024/1024).toFixed(1) + 'MB)');
    
    // Create inference session with WASM backend
    // ONNX Runtime auto-selects SIMD WASM if browser supports it
    session = await ort.InferenceSession.create(modelBuffer, {
      executionProviders: ['wasm'],
      graphOptimizationLevel: 'all',
    });
    
    var t2 = performance.now();
    console.log('YOLO Worker: Session created in ' + (t2-t1).toFixed(0) + 'ms');
    console.log('YOLO Worker: Input names:', session.inputNames);
    console.log('YOLO Worker: Output names:', session.outputNames);
    
    // Warm up with a dummy inference (compiles WASM, 2-3s one-time cost)
    console.log('YOLO Worker: Warming up...');
    var warmupTensor = new ort.Tensor('float32', new Float32Array(3 * MODEL_INPUT_SIZE * MODEL_INPUT_SIZE), [1, 3, MODEL_INPUT_SIZE, MODEL_INPUT_SIZE]);
    var warmupFeeds = {};
    warmupFeeds[session.inputNames[0]] = warmupTensor;
    await session.run(warmupFeeds);
    var t3 = performance.now();
    console.log('YOLO Worker: Warmup done in ' + (t3-t2).toFixed(0) + 'ms. Total init: ' + (t3-t0).toFixed(0) + 'ms');
    
    isReady = true;
    postMessage({ type: 'ready' });
  } catch (e) {
    console.error('YOLO Worker: Model init error:', e);
    postMessage({ type: 'error', error: e.message || String(e) });
  }
}

// Pre-allocated tensor buffer (zero allocation per frame)
var _tensorData = null;
var _invScale = 1.0 / 255.0;

/**
 * Preprocess RGBA image data to model input tensor.
 * Nearest-neighbor resize (2x faster than bilinear, minimal quality loss at 320px).
 * Pre-allocated buffer eliminates GC pressure.
 */
function preprocessImage(rgbaBuffer, srcWidth, srcHeight) {
  var rgba = new Uint8Array(rgbaBuffer);
  var inputSize = MODEL_INPUT_SIZE;
  var area = inputSize * inputSize;
  
  // Calculate letterbox dimensions
  var scale = Math.min(inputSize / srcWidth, inputSize / srcHeight);
  var newW = Math.round(srcWidth * scale);
  var newH = Math.round(srcHeight * scale);
  var padX = (inputSize - newW) >> 1;
  var padY = (inputSize - newH) >> 1;
  
  // Reuse tensor buffer
  if (!_tensorData) _tensorData = new Float32Array(3 * area);
  var td = _tensorData;
  
  // Fill with letterbox gray (114/255)
  td.fill(0.44706);
  
  // Nearest-neighbor resize + CHW layout + normalize
  var invScale = 1.0 / scale;
  for (var y = 0; y < newH; y++) {
    var srcY = (y * invScale) | 0;
    if (srcY >= srcHeight) srcY = srcHeight - 1;
    var dstY = y + padY;
    
    for (var x = 0; x < newW; x++) {
      var srcX = (x * invScale) | 0;
      if (srcX >= srcWidth) srcX = srcWidth - 1;
      var si = (srcY * srcWidth + srcX) * 4;
      var dstIdx = dstY * inputSize + (x + padX);
      
      td[dstIdx] = rgba[si] * _invScale;             // R → channel 0
      td[area + dstIdx] = rgba[si + 1] * _invScale;  // G → channel 1
      td[area * 2 + dstIdx] = rgba[si + 2] * _invScale; // B → channel 2
    }
  }
  
  return {
    tensor: td,
    scale: scale,
    padX: padX,
    padY: padY,
    newW: newW,
    newH: newH,
  };
}

/**
 * Run NMS (Non-Maximum Suppression) on detections.
 */
function nms(boxes, scores, iouThreshold) {
  const indices = [];
  const sorted = scores.map((s, i) => ({ score: s, idx: i }))
    .sort((a, b) => b.score - a.score);
  
  const used = new Set();
  
  for (const item of sorted) {
    if (used.has(item.idx)) continue;
    indices.push(item.idx);
    used.add(item.idx);
    
    for (const other of sorted) {
      if (used.has(other.idx)) continue;
      const iou = computeIoU(boxes[item.idx], boxes[other.idx]);
      if (iou > iouThreshold) {
        used.add(other.idx);
      }
    }
  }
  
  return indices;
}

/**
 * Compute Intersection over Union between two boxes [x1,y1,x2,y2].
 */
function computeIoU(a, b) {
  const x1 = Math.max(a[0], b[0]);
  const y1 = Math.max(a[1], b[1]);
  const x2 = Math.min(a[2], b[2]);
  const y2 = Math.min(a[3], b[3]);
  
  const inter = Math.max(0, x2 - x1) * Math.max(0, y2 - y1);
  const areaA = (a[2] - a[0]) * (a[3] - a[1]);
  const areaB = (b[2] - b[0]) * (b[3] - b[1]);
  const union = areaA + areaB - inter;
  
  return union > 0 ? inter / union : 0;
}

/**
 * Generate per-instance segmentation mask from prototypes + coefficients.
 * @param {Float32Array} protos - [32, 80, 80] prototype masks
 * @param {number[]} coeffs - 32 mask coefficients for this detection
 * @param {number[]} box - [x1, y1, x2, y2] in model coords (320×320)
 * @returns {Object} { grid: boolean[], width: int, height: int }
 */
function generateMask(protos, coeffs, box) {
  // 1. Compute mask = sigmoid(sum(coeffs[i] * protos[i]))  at 80×80
  const protoHW = PROTO_H * PROTO_W;
  const maskRaw = new Float32Array(protoHW);
  
  for (let i = 0; i < NUM_MASK_COEFFS; i++) {
    const offset = i * protoHW;
    for (let j = 0; j < protoHW; j++) {
      maskRaw[j] += coeffs[i] * protos[offset + j];
    }
  }
  
  // 2. Apply sigmoid
  for (let j = 0; j < protoHW; j++) {
    maskRaw[j] = 1.0 / (1.0 + Math.exp(-maskRaw[j]));
  }
  
  // 3. Crop mask to bounding box (in proto coords: box / 4)
  const protoScale = MODEL_INPUT_SIZE / PROTO_H;
  const px1 = Math.max(0, Math.floor(box[0] / protoScale));
  const py1 = Math.max(0, Math.floor(box[1] / protoScale));
  const px2 = Math.min(PROTO_W, Math.ceil(box[2] / protoScale));
  const py2 = Math.min(PROTO_H, Math.ceil(box[3] / protoScale));
  
  const cropW = px2 - px1;
  const cropH = py2 - py1;
  
  if (cropW <= 0 || cropH <= 0) {
    return { grid: [], width: 0, height: 0 };
  }
  
  // 4. Extract cropped boolean mask (threshold at 0.5)
  const grid = [];
  for (let y = py1; y < py2; y++) {
    for (let x = px1; x < px2; x++) {
      grid.push(maskRaw[y * PROTO_W + x] > 0.5);
    }
  }
  
  return { grid: grid, width: cropW, height: cropH };
}

/**
 * Postprocess YOLOv8-seg outputs to Recognition-compatible objects.
 */
function postprocess(output0Data, output1Data, preInfo) {
  // output0: [1, 116, 2100] → transpose to [2100, 116]
  // output1: [1, 32, 80, 80] → flatten to [32, 80*80]
  const numAnchors = 2100;
  const numChannels = 116; // 4 box + 80 classes + 32 mask coeffs
  
  const detections = [];
  
  for (let a = 0; a < numAnchors; a++) {
    // Extract class scores (channels 4-83)
    let maxScore = 0;
    let maxClass = -1;
    
    for (let c = 0; c < NUM_CLASSES; c++) {
      // output0 layout: [1, 116, 2100] → index = channel * numAnchors + anchor
      const score = output0Data[(4 + c) * numAnchors + a];
      if (score > maxScore) {
        maxScore = score;
        maxClass = c;
      }
    }
    
    if (maxScore < CONF_THRESHOLD) continue;
    
    // Extract box (cx, cy, w, h) in model coords
    const cx = output0Data[0 * numAnchors + a];
    const cy = output0Data[1 * numAnchors + a];
    const w  = output0Data[2 * numAnchors + a];
    const h  = output0Data[3 * numAnchors + a];
    
    // Convert to x1, y1, x2, y2
    const x1 = cx - w / 2;
    const y1 = cy - h / 2;
    const x2 = cx + w / 2;
    const y2 = cy + h / 2;
    
    // Extract mask coefficients (channels 84-115)
    const maskCoeffs = [];
    for (let m = 0; m < NUM_MASK_COEFFS; m++) {
      maskCoeffs.push(output0Data[(4 + NUM_CLASSES + m) * numAnchors + a]);
    }
    
    detections.push({
      classId: maxClass,
      score: maxScore,
      box: [x1, y1, x2, y2],
      maskCoeffs: maskCoeffs,
    });
  }
  
  if (detections.length === 0) {
    return { recognitions: [], stats: {} };
  }
  
  // NMS
  const boxes = detections.map(d => d.box);
  const scores = detections.map(d => d.score);
  const nmsIndices = nms(boxes, scores, IOU_THRESHOLD);
  
  // Build Recognition-compatible results
  const recognitions = [];
  const startTime = performance.now();
  
  for (const idx of nmsIndices) {
    const det = detections[idx];
    
    // Convert box from model coords (320×320) back to original image coords
    const x1 = (det.box[0] - preInfo.padX) / preInfo.scale;
    const y1 = (det.box[1] - preInfo.padY) / preInfo.scale;
    const x2 = (det.box[2] - preInfo.padX) / preInfo.scale;
    const y2 = (det.box[3] - preInfo.padY) / preInfo.scale;
    
    // Generate segmentation mask
    const mask = generateMask(output1Data, det.maskCoeffs, det.box);
    
    recognitions.push({
      id: det.classId,
      label: COCO_CLASSES[det.classId] || `class_${det.classId}`,
      score: det.score,
      location: { left: x1, top: y1, right: x2, bottom: y2 },
      maskCoeffs: det.maskCoeffs,
      maskGrid: mask.grid,
      maskWidth: mask.width,
      maskHeight: mask.height,
    });
  }
  
  const inferenceTime = performance.now() - startTime;
  
  return {
    recognitions: recognitions,
    stats: {
      'Total Prediction time': inferenceTime.toFixed(1) + 'ms',
      'Detections': recognitions.length,
    }
  };
}

/**
 * Run detection on a frame.
 */
var _frameCount = 0;

async function detectFrame(rgbaBuffer, width, height) {
  if (!session) return;
  
  var t0 = performance.now();
  
  // Preprocess (reuses pre-allocated tensor buffer)
  var preInfo = preprocessImage(rgbaBuffer, width, height);
  var t1 = performance.now();
  
  // Create input tensor (wraps existing buffer, no copy)
  var inputTensor = new ort.Tensor('float32', preInfo.tensor, [1, 3, MODEL_INPUT_SIZE, MODEL_INPUT_SIZE]);
  var feeds = {};
  feeds[session.inputNames[0]] = inputTensor;
  
  // Run ONNX inference
  var results = await session.run(feeds);
  var t2 = performance.now();
  
  // Get outputs
  var output0 = results[session.outputNames[0]];
  var output1 = results[session.outputNames[1]];
  
  // Postprocess (NMS + mask generation)
  var detectionResult = postprocess(output0.data, output1.data, preInfo);
  var t3 = performance.now();
  
  detectionResult.stats['Preprocess'] = (t1 - t0).toFixed(1) + 'ms';
  detectionResult.stats['ONNX Inference'] = (t2 - t1).toFixed(1) + 'ms';
  detectionResult.stats['Postprocess'] = (t3 - t2).toFixed(1) + 'ms';
  detectionResult.stats['Total'] = (t3 - t0).toFixed(1) + 'ms';
  
  _frameCount++;
  if (_frameCount % 10 === 0) {
    console.log('YOLO: pre=' + (t1-t0).toFixed(0) + 'ms onnx=' + (t2-t1).toFixed(0) + 'ms post=' + (t3-t2).toFixed(0) + 'ms total=' + (t3-t0).toFixed(0) + 'ms dets=' + detectionResult.recognitions.length);
  }
  
  postMessage({ type: 'result', result: detectionResult });
}

/**
 * Message handler.
 */
self.onmessage = async function(e) {
  switch (e.data.type) {
    case 'init':
      await initModel(e.data.modelUrl);
      break;
    case 'detect':
      if (isReady) {
        await detectFrame(e.data.imageData, e.data.width, e.data.height);
      }
      break;
  }
};
