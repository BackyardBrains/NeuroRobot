/// Conditional import for WebSocketBridge.
/// Web: uses dart:html WebSocket directly.
/// Native: uses no-op stub (native uses Isolate-based WebSocket.dart).
export 'web_websocket_stub.dart'
    if (dart.library.html) 'web_websocket.dart';
