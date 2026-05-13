/// Native stub for WebSocketBridge — never used on native platforms.
/// On native, the real WebSocket runs in an Isolate (WebSocket.dart).

class WebSocketBridge {
  static WebSocketBridge? _instance;
  
  WebSocketBridge._();
  
  static WebSocketBridge instance(String url) {
    _instance ??= WebSocketBridge._();
    return _instance!;
  }
  
  void onMessage(void Function(dynamic) callback) {}
  void send(dynamic message) {}
  bool get isReady => false;
  void dispose() {}
}
