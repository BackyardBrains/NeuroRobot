/// Conditional import for Allocator.
export 'allocator_stub.dart'
    if (dart.library.io) 'allocator_native.dart';
