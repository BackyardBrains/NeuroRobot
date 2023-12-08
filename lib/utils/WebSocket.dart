import 'dart:async';
import 'dart:isolate';

import 'package:web_socket_channel/web_socket_channel.dart';

void createWebSocket(List<dynamic> args) {
  Timer heartbeatTimer = Timer.periodic(const Duration(seconds: 10), (timer) { timer.cancel(); });
  int heartbeatMissingLastTime = DateTime.now().millisecondsSinceEpoch;
  int heartbeatMissingCounter = 0;

  // final wsUrl = Uri.parse('ws://192.168.1.3:9876');
  SendPort writeMainPort = args[0] as SendPort;
  final wsUrl = Uri.parse(args[1]);
  WebSocketChannel channel = WebSocketChannel.connect(wsUrl);

  channel.stream.listen((message) {
    // print("message");
    // print(message);
    heartbeatMissingCounter = 0;
    heartbeatMissingLastTime = DateTime.now().millisecondsSinceEpoch;
  });

  //Listen from main isolate to write into web socket
  final rcvWriteChannelPort = ReceivePort();
  // rcvWriteChannelPort.sendPort.send(message)
  rcvWriteChannelPort.listen((message) {
    // print("socketisolate message");
    // print(message);
    if (message == "DISCONNECT"){
      heartbeatTimer.cancel();
      channel.sink.close();
      rcvWriteChannelPort.close();
      writeMainPort.send("DISCONNECTED");
    }else{
      channel.sink.add(message);
    }
  });

  heartbeatTimer = Timer.periodic(const Duration(seconds: 1), (timer){
    var now = DateTime.now().millisecondsSinceEpoch;
    if ( now - heartbeatMissingLastTime >= 1000){
    // if ( DateTime.now().millisecondsSinceEpoch - heartbeatMissingLastTime >= 100000000){
      heartbeatMissingLastTime = now;
      heartbeatMissingCounter++;
    }

    // print("CLLOSEEE HEART BEAT0");
    // print(heartbeatMissingCounter);
    // print(DateTime.now().millisecondsSinceEpoch - heartbeatMissingLastTime);
    // if (heartbeatMissingCounter > 10){
    //   heartbeatMissingCounter = 0;
    //   print("CLLOSEEE HEART BEAT");
    //   channel.sink.close();
    //   writeMainPort.send("DISCONNECTED");
    //   rcvWriteChannelPort.close();
    //   timer.cancel();
    // }
  });

  // Send port back to main isolate
  writeMainPort.send(rcvWriteChannelPort.sendPort);
}