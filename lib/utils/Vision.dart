import 'dart:ffi' as ffi;
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:native_opencv/native_opencv.dart';
import 'package:spikerbot/utils/Allocator.dart';

ffi.Pointer<ffi.Uint8> ptrFrame =
    allocate<ffi.Uint8>(count: 320 * 240, sizeOfType: ffi.sizeOf<ffi.Uint8>());
/*
ffi.Pointer<ffi.Uint8> ptrMaskedFrame =
    // allocate<ffi.Uint8>(count: 320 * 240, sizeOfType: ffi.sizeOf<ffi.Uint8>());
    allocate<ffi.Uint8>(count: 0, sizeOfType: ffi.sizeOf<ffi.Uint8>());
ffi.Pointer<ffi.Uint8> ptrResizedFrame =
    allocate<ffi.Uint8>(count: 320 * 240, sizeOfType: ffi.sizeOf<ffi.Uint8>());
ffi.Pointer<ffi.Uint32> ptrResizedFrameLength =
    allocate<ffi.Uint32>(count: 1, sizeOfType: ffi.sizeOf<ffi.Uint32>());
Uint32List resizedFrameLength = ptrResizedFrameLength.asTypedList(1);
*/

// Future<bool> checkColorCV(frameData, ptrLowerB, ptrUpperB) async {
initializeOpenCV(stateBuf, visPrefVals, visPrefs, neuronContacts) {
  NativeOpenCV ocv = NativeOpenCV();
  ocv.initializeOpenCV();
  ocv.passPreprocessPointers(stateBuf, visPrefVals, visPrefs, neuronContacts);
}

// Future<bool> resizeImageFrame(frameData) async {
//   await compute(_resizeImageFrame, frameData);
//   return true;
// }

// bool _resizeImageFrame(rawFrameData) {
//   NativeOpenCV nativeocv = NativeOpenCV();

//   ptrResizedFrame = allocate<ffi.Uint8>(
//       count: rawFrameData.length, sizeOfType: ffi.sizeOf<ffi.Uint8>());
//   ffi.Pointer<ffi.Uint8> ptrRawFrame = allocate<ffi.Uint8>(
//       count: rawFrameData.length, sizeOfType: ffi.sizeOf<ffi.Uint8>());

//   Uint8List data = ptrRawFrame.asTypedList(rawFrameData.length);

//   int i = 0;
//   // copy data manually
//   for (i = 0; i < data.length; i++) {
//     data[i] = rawFrameData[i];
//   }

//   // nativeocv
//   nativeocv.resizeImage(
//       ptrRawFrame, rawFrameData.length, ptrResizedFrame, ptrResizedFrameLength);
//   try {
//     // freeMemory(ptrResizedFrame);
//     freeMemory(ptrRawFrame);
//   } catch (err) {}

//   return true;
// }

Future<bool> checkImageAi(frameData) async {
  return true;
}

Future<Map<String, dynamic>> checkColorCV(frameData) async {
  Map map = Map();
  map["frameData"] = frameData;

  Map<String, dynamic> res = await compute(_checkNativeColorCv, map);
  // print("res");
  // print(res);
  map = {};
  return res;
}

Map<String, dynamic> _checkNativeColorCv(map) {
  NativeOpenCV nativeocv = NativeOpenCV();
  Uint8List frameData = map['frameData'];
  // Uint8List redBg = frameData;
  // try {
  //   freeMemory(ptrFrame);
  // } catch (err) {
  //   print("err allocating memory");
  // }
  ptrFrame = calloc<ffi.Uint8>(frameData.length);

  Uint8List data = ptrFrame.asTypedList(frameData.length);

  int i = 0;
  // copy data manually
  for (i = 0; i < data.length; i++) {
    data[i] = frameData[i];
    // dataMaskedImage[i] = redBg[i];
  }
  // x, y, score
  // Use calloc to ensure zero-initialized memory
  // CRITICAL FIX: Buffer size increased to 100 (needs at least 22*3=66) to prevent overflow
  // as C++ loops through all visual preferences.
  ffi.Pointer<ffi.Uint16> centroid =
      calloc<ffi.Uint16>(100);

  // nativeocv
  // int result =
  //     nativeocv.findColorInImage(ptrFrame, frameData.length, ptrMaskedFrame);

  int result = nativeocv.findColorInImage(ptrFrame, frameData.length, centroid);
  print("DEBUG: Centroid result: $result, Values: [${centroid[0]}, ${centroid[1]}, ${centroid[2]}]");
  // map["centroidX"] = centroid[0].toDouble();
  // map["centroidY"] = centroid[1].toDouble();
  // print("centroid map");
  // print(map);

  Map<String, dynamic> res = {
    "result": result,
    "centroids": centroid.asTypedList(9).toList(),
  };

  try {
    // data.clear();
    calloc.free(ptrFrame);
    calloc.free(centroid);
    // frameData.clear();
  } catch (err) {
    print("Error Freeing frameData");
  }
  // print("res centroid");
  // print(res);
  return res;
}
