import 'dart:async';
import 'dart:io';
import 'dart:isolate';

// import 'package:stream_channel/stream_channel.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

void createWebSocket(List<dynamic> args) async {
  // Timer heartbeatTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
  //   timer.cancel();
  // });
  // int heartbeatMissingLastTime = DateTime.now().millisecondsSinceEpoch;
  // int heartbeatMissingCounter = 0;

  // final wsUrl = Uri.parse('ws://192.168.1.3:9876');
  SendPort writeMainPort = args[0] as SendPort;
  late WebSocketChannel channel;
  try {
    final wsUrl = Uri.parse(args[1]);
    print("TRY WEBSOCKET CONNECT");
    final client = HttpClient();
    bool clientErrorFlag = false;
    try {
      final request =
          await client.openUrl('GET', Uri.parse('http://192.168.4.1/ws'));
      request.headers
        ..set('Connection', 'Upgrade')
        ..set('Upgrade', 'websocket')
        ..set('Sec-WebSocket-Key', 'x3JJHMbDL1EzLkh9GBhXDw==')
        ..set('Sec-WebSocket-Version', '13');
      await request.close();
    } catch (err) {
      clientErrorFlag = true;
    }

    if (clientErrorFlag) {
      writeMainPort.send("RESTART");
      return;
    }

    // await client.openUrl('GET', wsUrl);
    print("request close");
    // final response = await request.close();
    // final socket = await response.detachSocket();
    // final innerChannel = StreamChannel<List<int>>(socket, socket);
    // channel = WebSocketChannel(innerChannel, serverSide: false);
    // channel = WebSocketChannel.connect(wsUrl);
    channel = IOWebSocketChannel.connect(wsUrl,
        headers: {
          'Connection': 'Upgrade',
          'Upgrade': 'websocket',
          'Sec-WebSocket-Key': 'x3JJHMbDL1EzLkh9GBhXDw==',
          'Sec-WebSocket-Version': '13'
        },
        customClient: client,
        connectTimeout: const Duration(seconds: 1),
        pingInterval: const Duration(seconds: 1));
    // await Future.delayed(const Duration(milliseconds: 500));
    await channel.ready;

    print("WEBSOCKET CONNECT READY");
    channel.stream.listen((message) {
      // print("message");
      // print(message);
      writeMainPort.send(message);
      // heartbeatMissingCounter = 0;
      // heartbeatMissingLastTime = DateTime.now().millisecondsSinceEpoch;
    }, onError: (error) {
      print("error websocket channel");
      print(error);
      writeMainPort.send("RESTART");
    }, onDone: () {
      print("done websocket channel");
      // writeMainPort.send("DISCONNECTED");

      // writeMainPort.send("RESTART");
    }, cancelOnError: false);

    //Listen from main isolate to write into web socket
    final rcvWriteChannelPort = ReceivePort();
    // rcvWriteChannelPort.sendPort.send(message)
    rcvWriteChannelPort.listen((message) async {
      // print("socketisolate message");
      // print(message.length);
      if (message == "DISCONNECT") {
        print("=====================DISCONNECT");
        await channel.sink.close();
        rcvWriteChannelPort.close();
        print(message);
        // heartbeatTimer.cancel();
        // Future.delayed(const Duration(milliseconds: 500), () {
        //   writeMainPort.send("DISCONNECTED");
        // });
      } else {
        channel.sink.add(message);
      }
    });

    // heartbeatTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
    //   var now = DateTime.now().millisecondsSinceEpoch;
    //   if (now - heartbeatMissingLastTime >= 1000) {
    //     // if ( DateTime.now().millisecondsSinceEpoch - heartbeatMissingLastTime >= 100000000){
    //     heartbeatMissingLastTime = now;
    //     heartbeatMissingCounter++;
    //   }

    //   // print("CLLOSEEE HEART BEAT0");
    //   // print(heartbeatMissingCounter);
    //   // print(DateTime.now().millisecondsSinceEpoch - heartbeatMissingLastTime);
    //   // if (heartbeatMissingCounter > 10){
    //   //   heartbeatMissingCounter = 0;
    //   //   print("CLLOSEEE HEART BEAT");
    //   //   channel.sink.close();
    //   //   writeMainPort.send("DISCONNECTED");
    //   //   rcvWriteChannelPort.close();
    //   //   timer.cancel();
    //   // }
    // });

    // Send port back to main isolate
    writeMainPort.send(rcvWriteChannelPort.sendPort);
  } on HttpException catch (error) {
    print('HttpExceptionXX caught: $error');
    try {
      await channel.sink.close();
    } on SocketException catch (err) {
      print("err channel sink");
      print(err);
    }
    print('Restart: $error');

    // Implement error handling logic here
    writeMainPort.send("RESTART");
  }

// catch (err) {
//     print("Websocket channel");
//     writeMainPort.send("RESTART");
//   }
}
