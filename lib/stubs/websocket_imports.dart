/// Conditional import for WebSocket utility.
export 'websocket_stub.dart'
    if (dart.library.io) 'websocket_native.dart';
