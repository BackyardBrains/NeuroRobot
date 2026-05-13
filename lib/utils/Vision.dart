import 'package:spikerbot/utils/ffi_imports.dart' as ffi;
import 'dart:typed_data';

import 'package:spikerbot/utils/ffi_package_imports.dart';
import 'package:flutter/foundation.dart';
import 'package:spikerbot/stubs/native_opencv_imports.dart';
import 'package:spikerbot/stubs/allocator_imports.dart';

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

Future<Map<String, dynamic>> checkColorCV(frameData, [Float32List? boundingBoxes, int activeColors = 7]) async {
  Map map = Map();
  map["frameData"] = frameData;
  if (boundingBoxes != null) {
    map["boundingBoxes"] = boundingBoxes;
  }
  map["activeColors"] = activeColors;

  Map<String, dynamic> res = await compute(_checkNativeColorCv, map);
  // print("res");
  // print(res);
  map = {};
  return res;
}

Map<String, dynamic> _checkNativeColorCv(map) {
  NativeOpenCV nativeocv = NativeOpenCV();
  Uint8List frameData = map['frameData'];
  Float32List? boundingBoxes = map['boundingBoxes'];
  int activeColors = map['activeColors'] ?? 7; // Default to all (1|2|4 = 7) if not provided.

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

  // Allocate debug buffer (320x240 * 4 bytes for RGBA)
  int debugBufferSize = 320 * 240 * 4;
  ffi.Pointer<ffi.Uint8> ptrDebugImage = calloc<ffi.Uint8>(debugBufferSize);

  // Allocate bounding boxes buffer
  ffi.Pointer<ffi.Float> ptrBoundingBoxes = ffi.nullptr;
  int boundingBoxesCount = 0;
  if (boundingBoxes != null && boundingBoxes.isNotEmpty) {
    int totalFloats = boundingBoxes.length;
    boundingBoxesCount = totalFloats ~/ 4;
    ptrBoundingBoxes = calloc<ffi.Float>(totalFloats);
    Float32List boundingBoxesData = ptrBoundingBoxes.asTypedList(totalFloats);
    for (int j = 0; j < totalFloats; j++) {
      boundingBoxesData[j] = boundingBoxes[j];
    }
  }

  // DEBUG: Check init
  // print("DEBUG: ptrDebugImage Address: ${ptrDebugImage.address}");
  // print("DEBUG: Before Call First 4 bytes: ${ptrDebugImage[0]}, ${ptrDebugImage[1]}, ${ptrDebugImage[2]}, ${ptrDebugImage[3]}");

  int result = nativeocv.findColorInImage(ptrFrame, frameData.length, centroid, ptrDebugImage, ptrBoundingBoxes, boundingBoxesCount, activeColors);

  // print("DEBUG: After Call First 4 bytes: ${ptrDebugImage[0]}, ${ptrDebugImage[1]}, ${ptrDebugImage[2]}, ${ptrDebugImage[3]}");

  Map<String, dynamic> res = {
    "result": result,
    "centroids": centroid.asTypedList(75).toList(),
    // Append BMP Header so Image.memory can read it
    "debugImage": _addBmpHeader(ptrDebugImage.asTypedList(debugBufferSize), 320, 240),
  };

  try {
    // data.clear();
    calloc.free(ptrFrame);
    calloc.free(centroid);
    calloc.free(ptrDebugImage);
    if (ptrBoundingBoxes != ffi.nullptr) {
      calloc.free(ptrBoundingBoxes);
    }
    // frameData.clear();
  } catch (err) {
    print("Error Freeing frameData");
  }
  // print("res centroid");
  // print(res);
  return res;
}

Uint8List _addBmpHeader(Uint8List rgbaData, int width, int height) {
  int contentSize = rgbaData.length;
  int headerSize = 54; // Standard BMP v3 header
  int fileSize = headerSize + contentSize;

  Uint8List bmp = Uint8List(fileSize);
  ByteData bd = bmp.buffer.asByteData();

  // 1. BMP Header (14 bytes)
  bd.setUint8(0, 0x42); // 'B'
  bd.setUint8(1, 0x4D); // 'M'
  bd.setUint32(2, fileSize, Endian.little); // File size
  bd.setUint32(6, 0, Endian.little); // Reserved
  bd.setUint32(10, headerSize, Endian.little); // Offset to pixel data

  // 2. DIB Header (BITMAPINFOHEADER - 40 bytes)
  bd.setUint32(14, 40, Endian.little); // Header size
  bd.setUint32(18, width, Endian.little); // Width
  bd.setUint32(22, -height, Endian.little); // Height (Negative = Top-down)
  bd.setUint16(26, 1, Endian.little); // Planes
  bd.setUint16(28, 32, Endian.little); // BPP (32 bit RGBA)
  bd.setUint32(30, 0, Endian.little); // Compression (BI_RGB)
  bd.setUint32(34, contentSize, Endian.little); // Image size
  bd.setUint32(38, 0, Endian.little); // X ppm
  bd.setUint32(42, 0, Endian.little); // Y ppm
  bd.setUint32(46, 0, Endian.little); // Colors in palette
  bd.setUint32(50, 0, Endian.little); // Important colors

  // Copy data
  bmp.setRange(headerSize, fileSize, rgbaData);
  return bmp;
}
