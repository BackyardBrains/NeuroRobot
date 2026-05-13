/**
 * dart_vision_bridge.js
 * Bridge between Dart (Flutter Web) and vision processing workers.
 *
 * OpenCV color detection runs in color_detector.worker.js (its own WASM instance).
 * YOLO object detection runs in yolo_detector.worker.js (ONNX Runtime Web).
 *
 * Dart calls window.processColorFrame() and window.processYoloFrame() via JS interop.
 * Results are returned via Promises (color) and callbacks (YOLO).
 */

(function() {
  'use strict';

  // ── Constants ─────────────────────────────────────────────────────────────
  const FRAME_W = 320;
  const FRAME_H = 240;
  const CENTROID_COUNT = 75;

  // ── Decode Canvas ─────────────────────────────────────────────────────────
  let decodeCanvas = null;
  let decodeCtx = null;

  function ensureDecodeCanvas() {
    if (decodeCtx) return;
    if (typeof OffscreenCanvas !== 'undefined') {
      decodeCanvas = new OffscreenCanvas(FRAME_W, FRAME_H);
    } else {
      decodeCanvas = document.createElement('canvas');
      decodeCanvas.width = FRAME_W;
      decodeCanvas.height = FRAME_H;
    }
    decodeCtx = decodeCanvas.getContext('2d', { willReadFrequently: true });
  }

  // ── OpenCV Color Detection Worker ─────────────────────────────────────────
  let colorWorker = null;
  let colorReady = false;
  let colorProcessing = false;
  let pendingColorResolve = null;

  /**
   * Initialize the vision bridge (color detection + decode canvas).
   */
  window.initVisionBridge = function() {
    if (colorWorker) return true;
    console.log('VisionBridge: Initializing...');
    
    ensureDecodeCanvas();

    try {
      colorWorker = new Worker('color_detector.worker.js');
      colorWorker.onmessage = function(e) {
        switch (e.data.type) {
          case 'ready':
            colorReady = true;
            colorProcessing = false;
            console.log('VisionBridge: Color detection worker ready!');
            break;
          case 'result':
            colorProcessing = false;
            if (pendingColorResolve) {
              pendingColorResolve(e.data.result);
              pendingColorResolve = null;
            }
            break;
        }
      };
      colorWorker.onerror = function(e) {
        console.error('VisionBridge: Color worker error:', e.message);
        colorProcessing = false;
        if (pendingColorResolve) {
          pendingColorResolve({
            result: 0,
            centroids: new Array(CENTROID_COUNT).fill(0),
            debugImage: new ArrayBuffer(0),
          });
          pendingColorResolve = null;
        }
      };
      console.log('VisionBridge: Color worker created');
      return true;
    } catch (e) {
      console.error('VisionBridge: Failed to create color worker:', e);
      return false;
    }
  };

  /**
   * Process a JPEG frame for color detection.
   * Called from Dart via JS interop.
   *
   * @param {Array} jpegBytesArray - JS array of byte values
   * @param {number} activeColors - Bitmask: 1=Blue, 2=Green, 4=Red
   * @returns {Promise<Object>} { result, centroids, debugImage }
   */
  window.processColorFrame = async function(jpegBytesArray, activeColors, wantDebugImage) {
    var emptyResult = {
      result: 0,
      centroids: new Array(CENTROID_COUNT).fill(0),
      debugImage: new Uint8Array(0),
    };

    if (!colorReady || !colorWorker) {
      return emptyResult;
    }

    // If still processing previous frame, skip (avoid backpressure)
    if (colorProcessing) {
      return emptyResult;
    }

    try {
      ensureDecodeCanvas();

      // 1. Decode JPEG → RGBA (accept typed array directly from Dart)
      var jpegBytes = (jpegBytesArray instanceof Uint8Array) ? jpegBytesArray : new Uint8Array(jpegBytesArray);
      var blob = new Blob([jpegBytes], { type: 'image/jpeg' });
      var bitmap = await createImageBitmap(blob);
      decodeCtx.clearRect(0, 0, FRAME_W, FRAME_H);
      decodeCtx.drawImage(bitmap, 0, 0, FRAME_W, FRAME_H);
      bitmap.close();
      var imageData = decodeCtx.getImageData(0, 0, FRAME_W, FRAME_H);

      colorProcessing = true;

      // 2. Send RGBA to color worker
      return new Promise(function(resolve) {
        var resolved = false;
        function doResolve(data) {
          if (!resolved) { resolved = true; resolve(data); }
        }

        pendingColorResolve = function(workerResult) {
          // Worker now returns BMP directly — pass straight through.
          // No OffscreenCanvas encoding needed. Zero main-thread image processing.
          var debugBytes;
          if (workerResult.debugImage && workerResult.debugImage.byteLength > 0) {
            debugBytes = new Uint8Array(workerResult.debugImage);
          } else {
            debugBytes = new Uint8Array(0);
          }
          doResolve({
            result: workerResult.result,
            centroids: workerResult.centroids,
            debugImage: debugBytes,
          });
        };

        var t0 = performance.now();
        colorWorker.postMessage({
          type: 'process',
          rgbaBuffer: imageData.data.buffer,
          activeColors: activeColors,
        }, [imageData.data.buffer]);

        // No timeout — colorProcessing flag prevents backpressure.
      });

    } catch (e) {
      console.error('VisionBridge: processColorFrame error:', e);
      colorProcessing = false;
      return emptyResult;
    }
  };

  /**
   * Check if the OpenCV vision bridge is ready.
   */
  window.isVisionBridgeReady = function() {
    return colorReady;
  };

  // ── YOLO Detector Bridge ─────────────────────────────────────────────────
  let yoloWorker = null;
  let yoloReady = false;
  let yoloProcessing = false;

  window._lastYoloResult = null;
  window._yoloResultCallback = null;

  /**
   * Initialize the YOLO detector web worker.
   */
  window.initYoloDetector = function() {
    if (yoloWorker) return true;
    console.log('VisionBridge: Initializing YOLO detector...');

    ensureDecodeCanvas();

    try {
      yoloWorker = new Worker('yolo_detector.worker.js');
      yoloWorker.onmessage = function(e) {
        switch (e.data.type) {
          case 'ready':
            yoloReady = true;
            yoloProcessing = false;
            console.log('VisionBridge: YOLO detector ready!');
            break;
          case 'result':
            yoloProcessing = false;
            window._lastYoloResult = e.data.result;
            if (window._yoloResultCallback) {
              try {
                window._yoloResultCallback(JSON.stringify(e.data.result));
              } catch (cbErr) {
                console.warn('VisionBridge: YOLO callback error:', cbErr);
              }
            }
            break;
          case 'error':
            yoloProcessing = false;
            console.error('VisionBridge: YOLO error:', e.data.error);
            break;
        }
      };
      yoloWorker.onerror = function(e) {
        console.error('VisionBridge: YOLO worker error:', e.message);
      };

      yoloWorker.postMessage({ type: 'init', modelUrl: 'assets/assets/models/yolov8n-seg.onnx' });
      return true;
    } catch (e) {
      console.error('VisionBridge: Failed to create YOLO worker:', e);
      return false;
    }
  };

  /**
   * Process a frame through YOLO detector.
   */
  window.processYoloFrame = async function(jpegBytesArray) {
    if (!yoloReady || yoloProcessing || !yoloWorker) return false;
    yoloProcessing = true;

    try {
      ensureDecodeCanvas();

      var jpegBytes = (jpegBytesArray instanceof Uint8Array) ? jpegBytesArray : new Uint8Array(jpegBytesArray);
      var blob = new Blob([jpegBytes], { type: 'image/jpeg' });
      var bitmap = await createImageBitmap(blob);
      decodeCtx.clearRect(0, 0, FRAME_W, FRAME_H);
      decodeCtx.drawImage(bitmap, 0, 0, FRAME_W, FRAME_H);
      bitmap.close();
      var imageData = decodeCtx.getImageData(0, 0, FRAME_W, FRAME_H);

      yoloWorker.postMessage(
        { type: 'detect', imageData: imageData.data.buffer, width: FRAME_W, height: FRAME_H },
        [imageData.data.buffer]
      );
      return true;
    } catch (e) {
      yoloProcessing = false;
      console.error('VisionBridge: processYoloFrame error:', e);
      return false;
    }
  };

  /**
   * Register a Dart callback for YOLO results.
   */
  window.registerYoloCallback = function(callback) {
    window._yoloResultCallback = callback;
  };

  /**
   * Get the latest YOLO result (for polling).
   */
  window.getLastYoloResult = function() {
    var r = window._lastYoloResult;
    window._lastYoloResult = null;
    return r ? JSON.stringify(r) : null;
  };

  /**
   * Check if YOLO detector is ready.
   */
  window.isYoloReady = function() {
    return yoloReady;
  };

})();
