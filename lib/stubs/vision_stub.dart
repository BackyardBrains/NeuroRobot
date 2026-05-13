/// Web stub for Vision utility.
/// On web, vision processing runs via dart_vision_bridge.js →
/// color_detector.worker.js (pure JavaScript pipeline).
/// Debug image is encoded as JPEG in JavaScript (fast OffscreenCanvas)
/// and transferred as ready-made bytes to Dart via bulk dartify().

import 'dart:typed_data';
import 'dart:js_util' as js_util;
import 'dart:html' as html;

bool _bridgeInitialized = false;

/// Initialize the vision bridge on web.
initializeOpenCV(dynamic stateBuf, dynamic visPrefVals,
    dynamic visPrefs, dynamic neuronContacts) {
  if (!_bridgeInitialized) {
    try {
      js_util.callMethod(html.window, 'initVisionBridge', []);
      _bridgeInitialized = true;
      print('Vision: Bridge initialized on web');
    } catch (e) {
      print('Vision: initVisionBridge error: $e');
    }
  }
}

Future<bool> checkImageAi(frameData) async {
  return true;
}

/// Process a camera frame for color detection via the JS bridge worker.
/// Returns {result: int, centroids: List<int>, debugImage: Uint8List?}
Future<Map<String, dynamic>> checkColorCV(frameData,
    [Float32List? boundingBoxes, int activeColors = 7]) async {
  final emptyResult = {
    "result": 0,
    "centroids": List<int>.filled(75, 0),
    "debugImage": null,
  };

  if (!_bridgeInitialized) {
    return emptyResult;
  }

  try {
    Uint8List frame;
    if (frameData is Uint8List) {
      frame = frameData;
    } else if (frameData is List<int>) {
      frame = Uint8List.fromList(frameData);
    } else {
      return emptyResult;
    }

    // Always request debug image — it IS the sketch overlay the user sees
    final jsResult = await js_util.promiseToFuture(
      js_util.callMethod(html.window, 'processColorFrame', [
        frame,  // Dart Uint8List → JS Uint8Array (zero-copy in dart2js)
        activeColors,
        true,   // always want debug image
      ])
    );

    if (jsResult == null) {
      return emptyResult;
    }

    // Extract result code
    int result = 0;
    try {
      result = (js_util.getProperty(jsResult, 'result') as num).toInt();
    } catch (_) {}

    // Extract centroids — bulk convert via dartify (1 interop call, not 75)
    List<int> centroids = List<int>.filled(75, 0);
    try {
      final jsCentroids = js_util.getProperty(jsResult, 'centroids');
      if (jsCentroids != null) {
        final dartified = js_util.dartify(jsCentroids);
        if (dartified is List) {
          for (int i = 0; i < dartified.length && i < 75; i++) {
            centroids[i] = (dartified[i] as num).toInt();
          }
        }
      }
    } catch (e) {
      print('Vision: centroids error: $e');
    }

    // Extract debug image — bulk convert via dartify (1 interop call)
    Uint8List? debugImage;
    try {
      final jsDebugImage = js_util.getProperty(jsResult, 'debugImage');
      if (jsDebugImage != null) {
        final debugLen = (js_util.getProperty(jsDebugImage, 'length') as num).toInt();
        if (debugLen > 0) {
          final dartified = js_util.dartify(jsDebugImage);
          if (dartified is Uint8List) {
            debugImage = dartified;
          } else if (dartified is List) {
            debugImage = Uint8List.fromList(List<int>.from(dartified));
          }
        }
      }
    } catch (e) {
      print('Vision: debugImage error: $e');
    }

    return {
      "result": result,
      "centroids": centroids,
      "debugImage": debugImage,
    };
  } catch (e) {
    print('Vision: checkColorCV error: $e');
    return emptyResult;
  }
}
