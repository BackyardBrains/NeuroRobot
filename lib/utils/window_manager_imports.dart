/// Conditional import for window_manager.
export 'window_manager_stub.dart'
    if (dart.library.io) 'window_manager_native.dart';
