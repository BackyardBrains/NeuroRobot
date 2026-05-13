/// Conditional import for auto_orientation.
export 'auto_orientation_stub.dart'
    if (dart.library.io) 'auto_orientation_native.dart';
