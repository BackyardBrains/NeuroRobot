/// Conditional import for dart:ffi.
/// On native (dart:io available): exports the real dart:ffi.
/// On web (dart:html available): exports ffi stubs.
export 'ffi_stub.dart'
    if (dart.library.io) 'ffi_native.dart';
