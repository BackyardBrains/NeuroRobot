/// Web stub for NativeOpenCV (vision processing).
/// On web, actual OpenCV runs via dart_vision_bridge.js → nativeopencv.wasm.
/// This stub mirrors the native NativeOpenCV API for compatibility.

import 'dart:js_util' as js_util;
import 'dart:html' as html;

class NativeOpenCV {
  String opencvVersion() => 'web-wasm';

  int initializeOpenCV() {
    try {
      final isReady = js_util.callMethod(html.window, 'isVisionBridgeReady', []);
      if (isReady == true) {
        print('NativeOpenCV: Bridge already ready');
        return 1;
      }
      // Init the bridge if not already done
      js_util.callMethod(html.window, 'initVisionBridge', []);
      print('NativeOpenCV: Vision bridge initialized');
      return 1;
    } catch (e) {
      print('NativeOpenCV: initializeOpenCV error: $e');
      return 0;
    }
  }

  int findColorInImage(dynamic pointer, dynamic imageLength,
      dynamic centroid, dynamic debugImageBuffer,
      dynamic boundingBoxes, dynamic boundingBoxesCount,
      dynamic activeColors) {
    // On web, color detection is handled asynchronously via vision_stub.dart
    // which calls processColorFrame in dart_vision_bridge.js.
    // This synchronous method is not used on web; the async checkColorCV() path
    // in vision_stub.dart is the primary entry point.
    print('NativeOpenCV: findColorInImage called (web delegates to JS bridge)');
    return 0;
  }

  int resizeImage(dynamic pointer, dynamic imageLength,
      dynamic pointerResizedFrame, dynamic resizedLength) {
    return 0;
  }

  int passPreprocessPointers(dynamic stateBuf, dynamic visPrefVals,
      dynamic visPrefs, dynamic neuronContacts) {
    // On web, passPreprocessPointers is called inside initVisionBridge
    // which handles WASM heap allocation internally.
    print('NativeOpenCV: passPreprocessPointers (web: handled by JS bridge)');
    return 0;
  }
}
