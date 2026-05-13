/// Web implementation of detector_service.dart (YOLO AI object detection).
/// Uses ONNX Runtime Web via yolo_detector.worker.js for browser inference.
///
/// Provides the same Detector API as the native TFLite implementation:
///   - Detector.start() → initializes the ONNX worker
///   - processFrame(Uint8List) → sends frame to worker
///   - resultsStream → receives Recognition objects

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:js_util' as js_util;
import 'dart:html' as html;

import 'package:flutter/painting.dart';
import 'package:spikerbot/ai/models/recognition.dart';

/// Web Detector — YOLO inference via ONNX Runtime Web worker.
class Detector {
  bool _initialized = false;
  Timer? _pollTimer;

  /// Stream that emits detection results matching the native format:
  /// { 'recognitions': List<Recognition>, 'stats': Map<String,String> }
  final StreamController<Map<String, dynamic>> resultsStream =
      StreamController<Map<String, dynamic>>.broadcast();

  Detector._();

  /// Start the YOLO detector web worker.
  static Future<Detector> start() async {
    final detector = Detector._();
    await detector._init();
    return detector;
  }

  Future<void> _init() async {
    try {
      // Initialize the vision bridge (if not already done)
      try {
        js_util.callMethod(html.window, 'initVisionBridge', []);
      } catch (_) {}

      // Initialize the YOLO detector worker
      js_util.callMethod(html.window, 'initYoloDetector', []);

      // Register Dart callback for results
      js_util.setProperty(html.window, '_yoloResultCallback',
        js_util.allowInterop((String jsonResult) {
          _handleResult(jsonResult);
        })
      );

      _initialized = true;
      print('Detector: YOLO web worker initialized');

      // Also poll for results as a fallback (in case callback doesn't fire)
      _pollTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
        _pollResults();
      });
    } catch (e) {
      print('Detector: init error: $e');
    }
  }

  /// Process a camera frame through YOLO detection.
  void processFrame(Uint8List frame, {int width = 320, int height = 240}) {
    if (!_initialized) return;

    try {
      // Check if YOLO is ready
      final isReady = js_util.callMethod(html.window, 'isYoloReady', []);
      if (isReady != true) return;

      // Send frame to JS bridge
      // Pass Uint8List directly — it IS a JS Uint8Array in dart2js (zero-copy)
      js_util.callMethod(html.window, 'processYoloFrame', [
        frame,
      ]);
    } catch (e) {
      print('Detector: processFrame error: $e');
    }
  }

  /// Handle YOLO result from JS callback.
  void _handleResult(String jsonResult) {
    try {
      final data = json.decode(jsonResult) as Map<String, dynamic>;
      final result = _parseResult(data);
      resultsStream.add(result);
    } catch (e) {
      print('Detector: _handleResult error: $e');
    }
  }

  /// Poll for results (fallback for when callback doesn't fire).
  void _pollResults() {
    if (!_initialized) return;
    try {
      final jsonStr = js_util.callMethod(html.window, 'getLastYoloResult', []);
      if (jsonStr != null && jsonStr is String && jsonStr.isNotEmpty) {
        _handleResult(jsonStr);
      }
    } catch (_) {}
  }

  /// Parse JSON result into Recognition objects.
  Map<String, dynamic> _parseResult(Map<String, dynamic> data) {
    final List<Recognition> recognitions = [];
    final rawRecognitions = data['recognitions'] as List<dynamic>? ?? [];

    for (final r in rawRecognitions) {
      final loc = r['location'] as Map<String, dynamic>?;
      final Rect location = loc != null
          ? Rect.fromLTRB(
              (loc['left'] as num).toDouble(),
              (loc['top'] as num).toDouble(),
              (loc['right'] as num).toDouble(),
              (loc['bottom'] as num).toDouble(),
            )
          : Rect.zero;

      // Parse mask coefficients
      List<double>? maskCoeffs;
      if (r['maskCoeffs'] != null) {
        maskCoeffs = (r['maskCoeffs'] as List<dynamic>)
            .map((v) => (v as num).toDouble())
            .toList();
      }

      // Parse mask grid (boolean array from prototype synthesis)
      List<bool>? maskGrid;
      int? maskWidth;
      int? maskHeight;
      if (r['maskGrid'] != null && r['maskWidth'] != null) {
        maskGrid = (r['maskGrid'] as List<dynamic>).map((v) => v == true).toList();
        maskWidth = (r['maskWidth'] as num).toInt();
        maskHeight = (r['maskHeight'] as num).toInt();
      }

      recognitions.add(Recognition(
        (r['id'] as num).toInt(),
        r['label'] as String? ?? '',
        (r['score'] as num).toDouble(),
        location,
        maskCoeffs: maskCoeffs,
        maskGrid: maskGrid,
        maskWidth: maskWidth,
        maskHeight: maskHeight,
      ));
    }

    // Parse stats
    final Map<String, dynamic> stats = {};
    if (data['stats'] != null) {
      (data['stats'] as Map<String, dynamic>).forEach((k, v) {
        stats[k] = v.toString();
      });
    }

    return {
      'recognitions': recognitions,
      'stats': stats,
    };
  }

  /// Stop the detector.
  void stop() {
    _pollTimer?.cancel();
    _pollTimer = null;
    _initialized = false;
  }
}
