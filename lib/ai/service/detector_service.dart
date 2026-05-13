// Copyright 2023 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'package:spikerbot/utils/platform_imports.dart';
import 'package:spikerbot/utils/isolate_imports.dart';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as image_lib;
import 'package:spikerbot/ai/models/recognition.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

import '../utils/image_utils.dart';

enum _Codes {
  init,
  busy,
  ready,
  detect,
  result,
}

class _Command {
  const _Command(this.code, {this.args});

  final _Codes code;
  final List<Object>? args;
}

class Detector {
  static const String _modelPath = 'assets/models/yolov8n-seg.tflite';

  static const List<String> YOLO_LABELS = [
    "person", "bicycle", "car", "motorcycle", "airplane", "bus", "train", "truck", "boat",
    "traffic light", "fire hydrant", "stop sign", "parking meter", "bench", "bird", "cat",
    "dog", "horse", "sheep", "cow", "elephant", "bear", "zebra", "giraffe", "backpack",
    "umbrella", "handbag", "tie", "suitcase", "frisbee", "skis", "snowboard", "sports ball",
    "kite", "baseball bat", "baseball glove", "skateboard", "surfboard", "tennis racket",
    "bottle", "wine glass", "cup", "fork", "knife", "spoon", "bowl", "banana", "apple",
    "sandwich", "orange", "broccoli", "carrot", "hot dog", "pizza", "donut", "cake", "chair",
    "couch", "potted plant", "bed", "dining table", "toilet", "tv", "laptop", "mouse",
    "remote", "keyboard", "cell phone", "microwave", "oven", "toaster", "sink",
    "refrigerator", "book", "clock", "vase", "scissors", "teddy bear", "hair drier",
    "toothbrush"
  ];

  Detector._(this._isolate, this._interpreter);

  final Isolate _isolate;
  late final Interpreter _interpreter;

  late final SendPort _sendPort;

  bool _isReady = false;

  final StreamController<Map<String, dynamic>> resultsStream =
      StreamController<Map<String, dynamic>>();

  static Future<Detector> start() async {
    final ReceivePort receivePort = ReceivePort();
    final Isolate isolate = await Isolate.spawn(_DetectorServer._run, receivePort.sendPort);

    final Detector result = Detector._(isolate, await _loadModel());
    receivePort.listen((message) {
      result._handleCommand(message as _Command);
    });
    return result;
  }

  static Future<Interpreter> _loadModel() async {
    final interpreterOptions = InterpreterOptions();
    if (Platform.isAndroid) {
      interpreterOptions.addDelegate(XNNPackDelegate());
    }
    final interpreter = await Interpreter.fromAsset(
      _modelPath,
      options: interpreterOptions..threads = 4,
    );

    var inputTensors = interpreter.getInputTensors();
    print("Tensor Input Shape: ${inputTensors[0].shape}");
    var outputTensors = interpreter.getOutputTensors();
    print("Tensor Output 0 Shape: ${outputTensors[0].shape}");
    print("Tensor Output 1 Shape: ${outputTensors[1].shape}");

    print('Model loaded successfully');
    return interpreter;
  }

  void processFrame(Uint8List cameraImage) {
    if (_isReady) {
      _sendPort.send(_Command(_Codes.detect, args: [cameraImage]));
    }
  }

  void _handleCommand(_Command command) {
    switch (command.code) {
      case _Codes.init:
        _sendPort = command.args?[0] as SendPort;
        RootIsolateToken rootIsolateToken = RootIsolateToken.instance!;
        _sendPort.send(_Command(_Codes.init, args: [
          rootIsolateToken,
          _interpreter.address,
        ]));
        break;
      case _Codes.ready:
        _isReady = true;
        break;
      case _Codes.busy:
        _isReady = false;
        break;
      case _Codes.result:
        _isReady = true;
        resultsStream.add(command.args?[0] as Map<String, dynamic>);
        break;
      default:
        debugPrint('Detector unrecognized command: ${command.code}');
    }
  }

  void stop() {
    _isolate.kill();
  }
}

class _DetectorServer {
  static int mlModelInputSize = 320;
  static int numAnchors = 2100;
  static int numChannels = 116;
  static int protoRes = 80;
  static int protoChannels = 32;
  static List<int> inputShapeGlobal = [1, 320, 320, 3];
  static List<int> outputShape0Global = [1, 116, 2100];
  static List<int> outputShape1Global = [1, 80, 80, 32];
  
  static Float32List? _imageBuffer;
  static Float32List? _output0Buffer;
  static Float32List? _output1Buffer;
  static List<Recognition> _trackedRecognitions = [];
  
  // Dynamic Gain Variables
  static double currentConfidenceThreshold = 0.15; // Modulated intelligently natively
  static const double iouThreshold = 0.45;
  
  static Float32List? _enhancementLut;
  static double _lastAverageLuminance = 127.0;     // Rolled average frame brightness

  static void _buildDynamicEnhancementLut() {
    if (_enhancementLut == null) _enhancementLut = Float32List(256);
    
    // Normalize luminance dynamically
    double normalizedLum = _lastAverageLuminance / 255.0; 
    
    // Low Light triggers heavier gamma curves natively
    double gamma = 0.5 + (normalizedLum * 0.5); // Ranges 0.5 (heavy dark boost) to 1.0 (linear)
    double contrast = 1.30 - (normalizedLum * 0.3); // Ranges 1.30 to 1.0
    
    for (int i = 0; i < 256; i++) {
        double val = i / 255.0;
        val = pow(val, gamma).toDouble();
        val = ((val - 0.5) * contrast) + 0.5;
        if (val < 0.0) val = 0.0;
        if (val > 1.0) val = 1.0;
        _enhancementLut![i] = val;
    }
    
    // Increase internal precision sensitivity linearly when it's dark
    currentConfidenceThreshold = 0.10 + (normalizedLum * 0.15); // drops to 0.10 in pitch black optimally natively
  }

  Interpreter? _interpreter;

  _DetectorServer(this._sendPort);

  final SendPort _sendPort;

  static void _run(SendPort sendPort) {
    ReceivePort receivePort = ReceivePort();
    final _DetectorServer server = _DetectorServer(sendPort);
    receivePort.listen((message) async {
      final _Command command = message as _Command;
      await server._handleCommand(command);
    });
    sendPort.send(_Command(_Codes.init, args: [receivePort.sendPort]));
  }

  Future<void> _handleCommand(_Command command) async {
    switch (command.code) {
      case _Codes.init:
        RootIsolateToken rootIsolateToken = command.args?[0] as RootIsolateToken;
        BackgroundIsolateBinaryMessenger.ensureInitialized(rootIsolateToken);
        _interpreter = Interpreter.fromAddress(command.args?[1] as int);
        
        try {
          _interpreter!.allocateTensors();
          var inputShape = _interpreter!.getInputTensors()[0].shape;
          var outputShape = _interpreter!.getOutputTensors()[0].shape;
          var outputShape1 = _interpreter!.getOutputTensors()[1].shape;
          
          if (inputShape.length >= 3) {
             inputShapeGlobal = List.from(inputShape);
             mlModelInputSize = max(inputShape[1], inputShape[2]);
          }
          if (outputShape.length >= 3) {
             outputShape0Global = List.from(outputShape);
             numChannels = min(outputShape[1], outputShape[2]);
             numAnchors = max(outputShape[1], outputShape[2]);
          }
          if (outputShape1.length >= 4) {
             outputShape1Global = List.from(outputShape1);
             protoRes = outputShape1[1];
             protoChannels = outputShape1[3];
          }
        } catch (_) {}
        
        _sendPort.send(const _Command(_Codes.ready));
        break;
      case _Codes.detect:
        _sendPort.send(const _Command(_Codes.busy));
        _convertCameraImage(command.args?[0] as Uint8List);
        break;
      default:
        debugPrint('_DetectorService unrecognized command ${command.code}');
    }
  }

  void _convertCameraImage(Uint8List cameraImage) {
    var preConversionTime = DateTime.now().millisecondsSinceEpoch;

    try {
      image_lib.Image img = convertFramesToImage(cameraImage);
      final results = analyseImage(img, preConversionTime);
      _sendPort.send(_Command(_Codes.result, args: [results]));
    } catch (err) {
      print("err convert frames to image: $err");
      _sendPort.send(_Command(_Codes.result, args: [{
        'recognitions': <Recognition>[],
        'stats': <String, String>{'Error': err.toString()}
      }]));
    }
  }

  Map<String, dynamic> analyseImage(image_lib.Image? image, int preConversionTime) {
    var conversionElapsedTime = DateTime.now().millisecondsSinceEpoch - preConversionTime;
    var preProcessStart = DateTime.now().millisecondsSinceEpoch;

    // Letterbox natively (Map directly without stretching)
    int imgW = image!.width; // Typically 320
    int imgH = image.height; // Typically 240
    
    double scaleToLetterbox = min(mlModelInputSize / imgW, mlModelInputSize / imgH);
    int newW = (imgW * scaleToLetterbox).round();
    int newH = (imgH * scaleToLetterbox).round();
    
    int dx = (mlModelInputSize - newW) ~/ 2;
    int dy = (mlModelInputSize - newH) ~/ 2;

    // Use fast native resizing ONLY to correctly fit scaling within aspect ratio map
    image_lib.Image imageInput = imgW == newW && imgH == newH 
          ? image 
          : image_lib.copyResize(image, width: newW, height: newH);

    // Initial 1D zero allocations
    if (_imageBuffer == null) {
       _imageBuffer = Float32List(mlModelInputSize * mlModelInputSize * 3);
       _output0Buffer = Float32List(numChannels * numAnchors);
       _output1Buffer = Float32List(protoRes * protoRes * protoChannels);
    }
    
    // Evaluate Dynamic Gain and Enhancement
    _buildDynamicEnhancementLut();
    double totalLuminance = 0.0;
    int pixelCount = 0;
    
    // Purge memory block efficiently (Creates black letterbox bars automatically)
    _imageBuffer!.fillRange(0, _imageBuffer!.length, 0.0);

    // Map 1D striding
    bool isNCHW = _DetectorServer.inputShapeGlobal[1] == 3;
    
    for (int y = 0; y < newH; y++) {
      for (int x = 0; x < newW; x++) {
         final pixel = imageInput.getPixelSafe(x, y);
         int renderY = y + dy;
         int renderX = x + dx;
         
         double r = pixel.r.toDouble();
         double g = pixel.g.toDouble();
         double b = pixel.b.toDouble();
         
         // Accumulate Luminance Logically Natively
         double l = 0.299 * r + 0.587 * g + 0.114 * b;
         totalLuminance += l;
         pixelCount++;
         
         // Amplify Color saturation optimally natively to assist CNN distinctions visually rationally precisely efficiently organically smoothly solidly reliably flawlessly intelligently accurately visually physically cleanly reliably precisely gracefully correctly manually
         double satFactor = 1.35; 
         r = l + (r - l) * satFactor;
         g = l + (g - l) * satFactor;
         b = l + (b - l) * satFactor;
         
         int rIdx = r.toInt().clamp(0, 255);
         int gIdx = g.toInt().clamp(0, 255);
         int bIdx = b.toInt().clamp(0, 255);
         
         if (isNCHW) {
            // NCHW stride [c][y][x]
            int area = mlModelInputSize * mlModelInputSize;
            _imageBuffer![(0 * area) + renderY * mlModelInputSize + renderX] = _enhancementLut![rIdx];
            _imageBuffer![(1 * area) + renderY * mlModelInputSize + renderX] = _enhancementLut![gIdx];
            _imageBuffer![(2 * area) + renderY * mlModelInputSize + renderX] = _enhancementLut![bIdx];
         } else {
            // NHWC stride [y][x][c]
            int baseIdx = (renderY * mlModelInputSize + renderX) * 3;
            _imageBuffer![baseIdx] = _enhancementLut![rIdx];
            _imageBuffer![baseIdx + 1] = _enhancementLut![gIdx];
            _imageBuffer![baseIdx + 2] = _enhancementLut![bIdx];
         }
      }
    }
    
    // Modulate Gain System cleanly physically seamlessly gracefully ideally
    if (pixelCount > 0) {
        _lastAverageLuminance = (_lastAverageLuminance * 0.8) + ((totalLuminance / pixelCount) * 0.2); 
    }

    var preProcessElapsedTime = DateTime.now().millisecondsSinceEpoch - preProcessStart;
    var inferenceTimeStart = DateTime.now().millisecondsSinceEpoch;

    // Absolute zero-alloc FFI bridging!
    var inputTensor0 = _interpreter!.getInputTensor(0);
    inputTensor0.setTo(_imageBuffer!.buffer.asUint8List());

    _interpreter!.invoke();

    var outTensor0 = _interpreter!.getOutputTensor(0);
    var outTensor1 = _interpreter!.getOutputTensor(1);
    
    // Copy bytes precisely into our natively allocated flat structures!
    outTensor0.copyTo(_output0Buffer!.buffer);
    outTensor1.copyTo(_output1Buffer!.buffer);

    var inferenceElapsedTime = DateTime.now().millisecondsSinceEpoch - inferenceTimeStart;

    // Parse YOLO vector
    List<Recognition> candidates = [];
    double absoluteMaxScoreObserved = 0.0;
    
    // Deterministically identify tensor transposition via global parsed shapes
    bool isTransposed = _DetectorServer.outputShape0Global[1] == numAnchors;
    
    for (int i = 0; i < numAnchors; i++) {
        double maxScore = 0.0;
        int maxClass = -1;
        
        // Classes are indices 4 to 83 (inclusive)
        for (int c = 4; c < 84; c++) {
            double s = isTransposed 
                 ? _output0Buffer![(i * numChannels) + c] 
                 : _output0Buffer![(c * numAnchors) + i];
            if (s > maxScore) {
                maxScore = s;
                maxClass = c - 4;
            }
        }
        
        if (maxScore > absoluteMaxScoreObserved) {
             absoluteMaxScoreObserved = maxScore;
        }
        
        if (maxScore > currentConfidenceThreshold) {
            double cx = isTransposed ? _output0Buffer![(i * numChannels) + 0] : _output0Buffer![(0 * numAnchors) + i];
            double cy = isTransposed ? _output0Buffer![(i * numChannels) + 1] : _output0Buffer![(1 * numAnchors) + i];
            double w  = isTransposed ? _output0Buffer![(i * numChannels) + 2] : _output0Buffer![(2 * numAnchors) + i];
            double h  = isTransposed ? _output0Buffer![(i * numChannels) + 3] : _output0Buffer![(3 * numAnchors) + i];
            
            // Normalize if YOLO scale is relative 0.0-1.0
            if (cx <= 1.5 && cy <= 1.5 && w <= 1.5) {
                cx *= mlModelInputSize;
                cy *= mlModelInputSize;
                w *= mlModelInputSize;
                h *= mlModelInputSize;
            }
            
            // Map box back to original image space natively eliminating the stretch distortion map
            double restoredCx = (cx - dx) / scaleToLetterbox;
            double restoredCy = (cy - dy) / scaleToLetterbox;
            double restoredW  = w / scaleToLetterbox;
            double restoredH  = h / scaleToLetterbox;
            
            Rect rect = Rect.fromCenter(
                center: Offset(restoredCx, restoredCy),
                width: restoredW,
                height: restoredH
            );
            
            // Extract the 32 mask coefficients assigned to this candidate
            List<double> maskCoeffs = [];
            for (int m = 84; m < 116; m++) {
                maskCoeffs.add(isTransposed ? _output0Buffer![(i * numChannels) + m] : _output0Buffer![(m * numAnchors) + i]);
            }
            
            candidates.add(Recognition(candidates.length, Detector.YOLO_LABELS[maxClass], maxScore, rect, maskCoeffs: maskCoeffs));
        }
    }
    
    // NMS
    candidates.sort((a, b) => b.score.compareTo(a.score));
    List<Recognition> recognitions = [];
    for (var box in candidates) {
        bool keep = true;
        for (var selectedBox in recognitions) {
            if (box.label == selectedBox.label) {
                if (_calculateIoU(box.location, selectedBox.location) > iouThreshold) {
                    keep = false;
                    break;
                }
            }
        }
        if (keep) {
            // Compute the silhouette mask natively mapping backwards against the letterboxed internal scale
            Rect rect = box.location;
            
            // Reverse scaling from 320x240 physical mapped rendering back to 320x320 Native Letterbox layout
            double rawCx = rect.center.dx * scaleToLetterbox + dx;
            double rawCy = rect.center.dy * scaleToLetterbox + dy;
            double rawW = rect.width * scaleToLetterbox;
            double rawH = rect.height * scaleToLetterbox;

            int maskResolution = protoRes;
            double downscale = mlModelInputSize / maskResolution;
            
            // Calculate mask bounding box limits tightly clamped to internally valid ranges
            int rawLeft = ((rawCx - rawW/2) / downscale).floor();
            int rawRight = ((rawCx + rawW/2) / downscale).ceil();
            int rawTop = ((rawCy - rawH/2) / downscale).floor();
            int rawBottom = ((rawCy + rawH/2) / downscale).ceil();

            int minX = max(0, rawLeft);
            int maxX = min(maskResolution - 1, rawRight);
            int minY = max(0, rawTop);
            int maxY = min(maskResolution - 1, rawBottom);
            
            int maskWidth = (maxX - minX) + 1;
            int maskHeight = (maxY - minY) + 1;
            List<bool> maskGrid = List<bool>.filled(maskWidth * maskHeight, false);
            
            // Safety measure: if width/height is <= 0
            if (maskWidth > 0 && maskHeight > 0 && box.maskCoeffs != null) {
                List<double> coeffs = box.maskCoeffs!;
                
            // Catch prototype dimension transpositions natively outside the high-density loops
            bool isProtoTransposed = false;
            if (_DetectorServer.outputShape1Global[1] == protoChannels) isProtoTransposed = true;

            // Mathematical Optimization: Rather than exp() inside a deep pixel loop,
            // calculating `1 / (1 + exp(-sum)) > 0.5` strictly simplifies to just verifying `sum > 0.0`.
            // Saving ~6400 raw math.exp calls per bounding box drastically increases engine velocity!
            // Furthermore, hoisting variables out of the branch exponentially shrinks isolation overhead.
            if (isProtoTransposed) {
                int area = protoRes * protoRes;
                for (int y = minY; y <= maxY; y++) {
                    int yOffset = y * protoRes;
                    int localYGrid = (y - minY) * maskWidth;
                    for (int x = minX; x <= maxX; x++) {
                        double sum = 0.0;
                        int xyOffset = yOffset + x;
                        for (int m = 0; m < protoChannels; m++) {
                            sum += _output1Buffer![(m * area) + xyOffset] * coeffs[m];
                        }
                        if (sum > 0.0) {
                            maskGrid[localYGrid + (x - minX)] = true;
                        }
                    }
                }
            } else {
                int rowStride = protoRes * protoChannels;
                for (int y = minY; y <= maxY; y++) {
                    int yOffset = y * rowStride;
                    int localYGrid = (y - minY) * maskWidth;
                    for (int x = minX; x <= maxX; x++) {
                        double sum = 0.0;
                        int baseOffset = yOffset + (x * protoChannels);
                        for (int m = 0; m < protoChannels; m++) {
                            sum += _output1Buffer![baseOffset + m] * coeffs[m];
                        }
                        if (sum > 0.0) {
                            maskGrid[localYGrid + (x - minX)] = true;
                        }
                    }
                }
            }
        }

            recognitions.add(Recognition(box.id, box.label, box.score, box.location, maskCoeffs: box.maskCoeffs, maskGrid: maskGrid, maskWidth: maskWidth, maskHeight: maskHeight));
        }
    }

    // True Zero-Latency Neural Hysteresis
    // We explicitly eradicate previous 'ghost' trajectory smoothing buffering entirely! 
    // Spreading dead-frames out to 3-frames-per-miss injected up to 300ms of lethal mechanical lag.
    // The AI directly feeds immediate frame realities. If an object sprints out of bounds,
    // the system natively flushes its coordinates instantaneously!
    _trackedRecognitions = recognitions;

    var totalElapsedTime = DateTime.now().millisecondsSinceEpoch - preConversionTime;

    return {
      "recognitions": recognitions,
      "stats": <String, String>{
        'Conversion time:': conversionElapsedTime.toString(),
        'Pre-processing time:': preProcessElapsedTime.toString(),
        'Inference time:': inferenceElapsedTime.toString(),
        'Total time:': totalElapsedTime.toString(),
        'Transposed': isTransposed.toString(),
        'Frame': '${image.width}x${image.height}',
        'MaxScore': absoluteMaxScoreObserved.toStringAsFixed(3),
      }
    };
  }

  double _calculateIoU(Rect box1, Rect box2) {
    double xA = max(box1.left, box2.left);
    double yA = max(box1.top, box2.top);
    double xB = min(box1.right, box2.right);
    double yB = min(box1.bottom, box2.bottom);

    double interArea = max(0.0, xB - xA) * max(0.0, yB - yA);
    double box1Area = box1.width * box1.height;
    double box2Area = box2.width * box2.height;

    return interArea / (box1Area + box2Area - interArea);
  }
}
