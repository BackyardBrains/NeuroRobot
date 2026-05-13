/// Conditional import for package:ffi/ffi.dart.
/// On native: exports real package:ffi.
/// On web: exports ffi package stubs.
export 'ffi_package_stub.dart'
    if (dart.library.io) 'ffi_package_native.dart';
