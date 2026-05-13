/// Web stub for WebSocket utility.
/// On web, WebSocket runs directly in the browser (no Isolate needed).

import 'dart:async';

void createWebSocket(List<dynamic> args) async {
  // On web, this function is never called — WebSocket is 
  // handled directly in the main thread or via a Web Worker.
  // The kIsWeb guard in designbrain_page.dart prevents this path.
}
