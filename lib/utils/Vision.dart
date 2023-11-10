import 'dart:ffi' as ffi;
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:native_opencv/native_opencv.dart';
import 'package:neurorobot/utils/Allocator.dart';


late ffi.Pointer<ffi.Uint8> ptrFrame;
ffi.Pointer<ffi.Uint8> ptrMaskedFrame = allocate<ffi.Uint8>(
      count: 320*240, sizeOfType: ffi.sizeOf<ffi.Uint8>());
Future<bool> checkColorCV(frameData, ptrLowerB, ptrUpperB) {
    // print("testColorCV");

    Map map = Map();
    map["frameData"] = frameData;
    // map["lowerB"] = ptrLowerB.asTypedList(3);
    // map["upperB"] = ptrUpperB.asTypedList(3);
    map["lowerB"] = ptrLowerB;
    map["upperB"] = ptrUpperB;
    return compute(_checkNativeColorCv,map);
}

bool _checkNativeColorCv(map){

    NativeOpenCV nativeocv = NativeOpenCV();
    // print(nativeocv.opencvVersion());
    Uint8List frameData = map['frameData']; 
    Uint8List redBg = frameData;
    ptrFrame = allocate<ffi.Uint8>(count: redBg.length, sizeOfType: ffi.sizeOf<ffi.Uint8>());
    
    ffi.Pointer<ffi.Uint8> ptrLowerB = allocate<ffi.Uint8>(count: 3, sizeOfType: ffi.sizeOf<ffi.Uint8>());; 
    ffi.Pointer<ffi.Uint8> ptrUpperB = allocate<ffi.Uint8>(count: 3, sizeOfType: ffi.sizeOf<ffi.Uint8>());; 

    Uint8List lowerB = ptrLowerB.asTypedList(3);
    Uint8List upperB = ptrUpperB.asTypedList(3);
    
    Uint8List _lowerB = map["lowerB"];
    Uint8List _upperB = map["upperB"];
    
    lowerB[0] = _lowerB[0];
    lowerB[1] = _lowerB[1];
    lowerB[2] = _lowerB[2];
    upperB[0] = _upperB[0];
    upperB[1] = _upperB[1];
    upperB[2] = _upperB[2];
    

    Uint8List data = ptrFrame.asTypedList(redBg.length);
    
    int i = 0;
    // copy data manually
    for (i=0;i<data.length;i++){
      data[i] = redBg[i];
      // dataMaskedImage[i] = redBg[i];
    }

    
    // nativeocv
    int status = nativeocv.findColorInImage(ptrFrame, redBg.length, ptrLowerB, ptrUpperB, 40, ptrMaskedFrame);
    try{

      freeMemory(ptrFrame);
      freeMemory(ptrLowerB);
      freeMemory(ptrUpperB);
    }catch(err){

    }

    int area = 320 * 240;
    int percentage = (status * 100 /area).floor();
    if (percentage > 20){
      print("!Occupied by that color");
      return true;
    }else{
      print("#Not Occupied by that color");
      return false;
    }


  }
