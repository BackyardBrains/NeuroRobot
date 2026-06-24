/// Web-specific WebSocket bridge for robot communication.
/// Used by designbrain_page.dart when kIsWeb is true.
/// Mirrors the protocol of the native WebSocket.dart isolate approach.

import 'dart:async';
import 'dart:html' as html;

/// Singleton web WebSocket bridge
class WebSocketBridge {
  static WebSocketBridge? _instance;
  
  html.WebSocket? _ws;
  String _url;
  bool _isReady = false;
  bool _gracefulDisconnect = false;
  void Function(dynamic)? _onMessage;
  
  static const String _greenLED = 'd:0,0,255,0;d:1,0,255,0;d:2,0,255,0;d:3,0,255,0;';
  static const String _stopMotor = 'l:0;r:0;s:0;';
  
  WebSocketBridge._(this._url);
  
  /// Get or create the singleton bridge
  static WebSocketBridge instance(String url) {
    _instance ??= WebSocketBridge._(url);
    _instance!._url = url;
    return _instance!;
  }
  
  /// Register a callback for incoming messages from the robot
  void onMessage(void Function(dynamic) callback) {
    _onMessage = callback;
  }
  
  /// Send a command to the robot (motor/LED/speaker/etc)
  void send(dynamic message) {
    if (message == 'INIT_WEBSOCKET') {
      print('WEB_WS: INIT_WEBSOCKET received');
      _connect();
    } else if (message == 'DISCONNECT') {
      _gracefulDisconnect = true;
      print('WEB_WS: DISCONNECT');
      try { _ws?.close(1000, 'Stop Button'); } catch (_) {}
      _isReady = false;
      Future.delayed(const Duration(milliseconds: 500), () {
        _onMessage?.call('DISCONNECTED');
      });
    } else {
      if (_isReady && _ws?.readyState == html.WebSocket.OPEN) {
        _ws!.send(message);
      }
    }
  }
  
  /// Whether the WebSocket is connected and ready
  bool get isReady => _isReady;
  
  void _connect() async {
    // Close existing connection if any
    if (_ws != null) {
      try { _ws!.close(); } catch (_) {}
    }
    _isReady = false;
    
    // Match native 1400ms delay
    await Future.delayed(const Duration(milliseconds: 1400));
    
    print('WEB_WS: Connecting to $_url (from origin: ${html.window.location.origin})');
    try {
      _ws = html.WebSocket(_url);
      print('WEB_WS: WebSocket created, readyState=${_ws!.readyState}');
      
      _ws!.onOpen.listen((_) {
        print('WEB_WS: WEBSOCKET CONNECT READY');
        String initialCmd = (_stopMotor + _greenLED).padRight(1450, ' ');
        _ws!.send(initialCmd);
        _isReady = true;
      });
      
      _ws!.onMessage.listen((event) {
        _onMessage?.call(event.data);
      });
      
      _ws!.onError.listen((event) {
        print('WEB_WS: WebSocket error — type=${event.type}, readyState=${_ws?.readyState}');
        print('WEB_WS: This may be a Private Network Access (PNA) block if connecting from a public origin to 192.168.x.x');
        _isReady = false;
        _onMessage?.call('DISCONNECTED');
      });
      
      _ws!.onClose.listen((event) {
        print('WEB_WS: closed code=${event.code} reason="${event.reason}" wasClean=${event.wasClean}');
        _isReady = false;
        if (event.code == 1000) {
          // Normal close
        } else if (event.code == 1005 && _gracefulDisconnect) {
          _gracefulDisconnect = false;
        } else {
          _onMessage?.call('RESTART');
        }
      });
    } catch (e) {
      print('WEB_WS: Connection failed: $e');
      _isReady = false;
      _onMessage?.call('RESTART');
    }
  }
  
  void dispose() {
    try { _ws?.close(); } catch (_) {}
    _ws = null;
    _isReady = false;
    _instance = null;
  }
}
