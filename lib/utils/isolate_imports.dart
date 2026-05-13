/// Conditional import for dart:isolate.
/// On native: exports real dart:isolate.
/// On web: exports isolate stubs.
export 'isolate_stub.dart'
    if (dart.library.io) 'isolate_native.dart';
