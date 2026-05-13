/// Conditional import for Nativec.
/// On native: exports real plugin Nativec (FFI-backed).
/// On web: exports stub Nativec (will be wired to JS/WASM).
export 'nativec_stub.dart'
    if (dart.library.io) 'nativec_native.dart';
