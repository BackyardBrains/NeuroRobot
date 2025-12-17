import 'dart:ffi' as ffi;
import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';

// C function signatures
typedef _version_func = ffi.Pointer<Utf8> Function();
// typedef _find_color_in_image_func = ffi.Int Function(ffi.Pointer<ffi.Uint8>, ffi.Uint32, ffi.Pointer<ffi.Uint8>, ffi.Pointer<ffi.Uint8>, ffi.Uint8, ffi.Pointer<ffi.Uint8>);
typedef _find_color_in_image_func = ffi.Int Function(
    ffi.Pointer<ffi.Uint8>, ffi.Uint32, ffi.Pointer<ffi.Uint16>);
typedef _resize_image_func = ffi.Int Function(ffi.Pointer<ffi.Uint8>,
    ffi.Uint32, ffi.Pointer<ffi.Uint8>, ffi.Pointer<ffi.Uint32>);

typedef _initialize_open_cv_func = ffi.Int Function();
typedef _pass_preprocess_pointers_func = ffi.Int Function(
    ffi.Pointer<ffi.Int32>,
    ffi.Pointer<ffi.Double>,
    ffi.Pointer<ffi.Int16>,
    ffi.Pointer<ffi.Double>);

typedef _InitializeOpenCVFunc = int Function();
// typedef _find_color_in_image_func = ffi.Int Function(ffi.Pointer<ffi.Uint8>, ffi.Uint32, ffi.Pointer<ffi.Uint8>, ffi.Pointer<ffi.Uint8>, ffi.Uint8, ffi.Pointer<ffi.Uint8>);
// typedef _initialize_open_cv_func = ffi.Int Function();

// Dart function signatures
typedef _VersionFunc = ffi.Pointer<Utf8> Function();
// typedef _FindColorInImageFunc = int Function(ffi.Pointer<ffi.Uint8>, int, ffi.Pointer<ffi.Uint8>, ffi.Pointer<ffi.Uint8>, int, ffi.Pointer<ffi.Uint8>);

typedef _FindColorInImageFunc = int Function(
    ffi.Pointer<ffi.Uint8>, int, ffi.Pointer<ffi.Uint16>);
typedef _ResizeImageFunc = int Function(ffi.Pointer<ffi.Uint8>, int,
    ffi.Pointer<ffi.Uint8>, ffi.Pointer<ffi.Uint32>);
typedef _PassPreprocessPointersFunc = int Function(
    ffi.Pointer<ffi.Int32>,
    ffi.Pointer<ffi.Double>,
    ffi.Pointer<ffi.Int16>,
    ffi.Pointer<ffi.Double>);

// Getting a library that holds needed symbols
ffi.DynamicLibrary _lib = Platform.isAndroid
    ? Platform.isWindows
        ? ffi.DynamicLibrary.open('native_opencv.dll')
        : ffi.DynamicLibrary.open('libnative_opencv.so')
    : ffi.DynamicLibrary.process();

// Looking for the functions
final _InitializeOpenCVFunc _initializeOpenCV = _lib
    .lookup<ffi.NativeFunction<_initialize_open_cv_func>>('initializeOpenCV')
    .asFunction();
final _VersionFunc _version =
    _lib.lookup<ffi.NativeFunction<_version_func>>('version').asFunction();
final _FindColorInImageFunc _findColorInImage = _lib
    .lookup<ffi.NativeFunction<_find_color_in_image_func>>('findColorInImage_opencv')
    .asFunction();

final _ResizeImageFunc _resizeImage = _lib
    .lookup<ffi.NativeFunction<_resize_image_func>>('resizeImage')
    .asFunction();

final _PassPreprocessPointersFunc _passPreprocessPointers = _lib
    .lookup<ffi.NativeFunction<_pass_preprocess_pointers_func>>(
        'passPreprocessPointers')
    .asFunction();

class NativeOpenCV {
  String opencvVersion() {
    print(_lib);
    return _version().toDartString();
  }

  int initializeOpenCV() {
    // print(_lib);
    return _initializeOpenCV();
  }

  // int findColorInImage(_pointer, imageLength, lowerB, upperB, int colorSpace, _pointerMaskedFrame) {
  int findColorInImage(_pointer, imageLength, _centroid) {
    // print("dart - findColorInImage");
    // return _findColorInImage(_pointer, imageLength, lowerB, upperB, colorSpace, _pointerMaskedFrame);
    // return _findColorInImage(_pointer, imageLength, _pointerMaskedFrame);
    return _findColorInImage(_pointer, imageLength, _centroid);
    // _processImage(ffi.Utf8.toUtf8(inputPath), Utf8.toUtf8(outputPath));
    // _processImage(ffi.Utf8.toUtf8(inputPath), Utf8.toUtf8(outputPath));
  }

  int resizeImage(_pointer, imageLength, _pointerResizedFrame, resizedLength) {
    // print("dart - findColorInImage");
    // return _findColorInImage(_pointer, imageLength, lowerB, upperB, colorSpace, _pointerMaskedFrame);
    return _resizeImage(
        _pointer, imageLength, _pointerResizedFrame, resizedLength);
    // _processImage(ffi.Utf8.toUtf8(inputPath), Utf8.toUtf8(outputPath));
    // _processImage(ffi.Utf8.toUtf8(inputPath), Utf8.toUtf8(outputPath));
  }

  int passPreprocessPointers(stateBuf, visPrefVals, visPrefs, neuronContacts) {
    return _passPreprocessPointers(
        stateBuf, visPrefVals, visPrefs, neuronContacts);
  }
}



// import 'native_opencv_platform_interface.dart';

// class NativeOpencv {
//   Future<String?> getPlatformVersion() {
//     return NativeOpencvPlatform.instance.getPlatformVersion();
//   }
// }


