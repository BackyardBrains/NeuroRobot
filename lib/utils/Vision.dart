import 'dart:ffi' as ffi;
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:native_opencv/native_opencv.dart';
import 'package:neurorobot/utils/Allocator.dart';

ffi.Pointer<ffi.Uint8> ptrFrame =
    allocate<ffi.Uint8>(count: 320 * 240, sizeOfType: ffi.sizeOf<ffi.Uint8>());
ffi.Pointer<ffi.Uint8> ptrMaskedFrame =
    allocate<ffi.Uint8>(count: 320 * 240, sizeOfType: ffi.sizeOf<ffi.Uint8>());
ffi.Pointer<ffi.Uint8> ptrResizedFrame =
    allocate<ffi.Uint8>(count: 320 * 240, sizeOfType: ffi.sizeOf<ffi.Uint8>());
ffi.Pointer<ffi.Uint32> ptrResizedFrameLength =
    allocate<ffi.Uint32>(count: 1, sizeOfType: ffi.sizeOf<ffi.Uint32>());
Uint32List resizedFrameLength = ptrResizedFrameLength.asTypedList(1);
// Future<bool> checkColorCV(frameData, ptrLowerB, ptrUpperB) async {
initializeOpenCV() {
  NativeOpenCV ocv = NativeOpenCV();
  ocv.initializeOpenCV();
}

Future<bool> resizeImageFrame(frameData) async {
  await compute(_resizeImageFrame, frameData);
  return true;
}

bool _resizeImageFrame(rawFrameData) {
  NativeOpenCV nativeocv = NativeOpenCV();

  ptrResizedFrame = allocate<ffi.Uint8>(
      count: rawFrameData.length, sizeOfType: ffi.sizeOf<ffi.Uint8>());
  ffi.Pointer<ffi.Uint8> ptrRawFrame = allocate<ffi.Uint8>(
      count: rawFrameData.length, sizeOfType: ffi.sizeOf<ffi.Uint8>());

  Uint8List data = ptrRawFrame.asTypedList(rawFrameData.length);

  int i = 0;
  // copy data manually
  for (i = 0; i < data.length; i++) {
    data[i] = rawFrameData[i];
  }

  // nativeocv
  nativeocv.resizeImage(
      ptrRawFrame, rawFrameData.length, ptrResizedFrame, ptrResizedFrameLength);
  try {
    // freeMemory(ptrResizedFrame);
    freeMemory(ptrRawFrame);
  } catch (err) {}

  return true;
}

Future<bool> checkImageAi(frameData) async {
  return true;
}

Future<bool> checkColorCV(frameData) async {
  // print("testColorCV");

  Map map = Map();
  map["frameData"] = frameData;
  // map["lowerB"] = ptrLowerB.asTypedList(3);
  // map["upperB"] = ptrUpperB.asTypedList(3);
  // map["lowerB"] = ptrLowerB;
  // map["upperB"] = ptrUpperB;
  await compute(_checkNativeColorCv, map);
  return true;
}

bool _checkNativeColorCv(map) {
  NativeOpenCV nativeocv = NativeOpenCV();
  // print(nativeocv.opencvVersion());
  Uint8List frameData = map['frameData'];
  Uint8List redBg = frameData;
  try {
    freeMemory(ptrFrame);
  } catch (err) {
    print("err allocating memory");
  }
  ptrFrame = allocate<ffi.Uint8>(
      count: redBg.length, sizeOfType: ffi.sizeOf<ffi.Uint8>());

  // ffi.Pointer<ffi.Uint8> ptrLowerB = allocate<ffi.Uint8>(count: 3, sizeOfType: ffi.sizeOf<ffi.Uint8>());;
  // ffi.Pointer<ffi.Uint8> ptrUpperB = allocate<ffi.Uint8>(count: 3, sizeOfType: ffi.sizeOf<ffi.Uint8>());;

  // Uint8List lowerB = ptrLowerB.asTypedList(3);
  // Uint8List upperB = ptrUpperB.asTypedList(3);

  // Uint8List _lowerB = map["lowerB"];
  // Uint8List _upperB = map["upperB"];

  // lowerB[0] = _lowerB[0];
  // lowerB[1] = _lowerB[1];
  // lowerB[2] = _lowerB[2];
  // upperB[0] = _upperB[0];
  // upperB[1] = _upperB[1];
  // upperB[2] = _upperB[2];

  Uint8List data = ptrFrame.asTypedList(redBg.length);

  int i = 0;
  // copy data manually
  for (i = 0; i < data.length; i++) {
    data[i] = redBg[i];
    // dataMaskedImage[i] = redBg[i];
  }

  // nativeocv
  nativeocv.findColorInImage(ptrFrame, redBg.length, ptrMaskedFrame);
  // int status = nativeocv.findColorInImage(ptrFrame, redBg.length, ptrLowerB, ptrUpperB, 40, ptrMaskedFrame);
  try {
    freeMemory(ptrFrame);
    // freeMemory(ptrLowerB);
    // freeMemory(ptrUpperB);
  } catch (err) {}

  // int area = 320 * 240;
  // int percentage = (status * 100 /area).floor();
  // if (percentage > 20){
  //   print("!Occupied by that color");
  //   return true;
  // }else{
  //   print("#Not Occupied by that color");
  //   return false;
  // }
  return true;
}
