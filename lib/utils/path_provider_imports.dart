/// Conditional import for path_provider.
/// On native: exports real path_provider.
/// On web: exports stub (functions come from platform_stub.dart).
export 'path_provider_stub.dart'
    if (dart.library.io) 'path_provider_native.dart';
