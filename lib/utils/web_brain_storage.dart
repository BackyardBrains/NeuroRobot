/// Conditional import for web brain storage.
/// On web: exports real IndexedDB implementation.
/// On native: exports stub with no-op methods.
export 'web_brain_storage_stub.dart'
    if (dart.library.html) 'web_brain_storage_web.dart';
