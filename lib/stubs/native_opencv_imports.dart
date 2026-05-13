/// Conditional import for NativeOpenCV.
export 'native_opencv_stub.dart'
    if (dart.library.io) 'native_opencv_native.dart';
