/// Conditional import for Vision.
export 'vision_stub.dart'
    if (dart.library.io) 'vision_native.dart';
