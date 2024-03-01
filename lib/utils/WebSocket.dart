import 'dart:async';
import 'dart:io';
import 'dart:isolate';

// import 'package:stream_channel/stream_channel.dart';
// import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

// import 'package:websocket_universal/websocket_universal.dart';

void createWebSocket(List<dynamic> args) async {
  // String offLEDCmd = "d:120;d:220;d:320;d:420;";
  String offLEDCmd = "d:0,0,0,0;d:1,0,0,0;d:2,0,0,0;d:3,0,0,0;";
  bool isReady = false;
  String stopMotorCmd = "l:0;r:0;s:0;";
  // Timer heartbeatTimer = Ti  mer.periodic(const Duration(seconds: 10), (timer) {
  //   timer.cancel();
  // });
  // int heartbeatMissingLastTime = DateTime.now().millisecondsSinceEpoch;
  // int heartbeatMissingCounter = 0;

  // final wsUrl = Uri.parse('ws://192.168.1.3:9876');
  SendPort writeMainPort = args[0] as SendPort;
  final rcvWriteChannelPort = ReceivePort();

  late WebSocketChannel channel;
  try {
    final wsUrl = Uri.parse(args[1]);
    print("TRY WEBSOCKET CONNECT");
    // heartbeatTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
    //   var now = DateTime.now().millisecondsSinceEpoch;
    //   if (now - heartbeatMissingLastTime >= 1000) {
    //     // if ( DateTime.now().millisecondsSinceEpoch - heartbeatMissingLastTime >= 100000000){
    //     heartbeatMissingLastTime = now;
    //     heartbeatMissingCounter++;
    //     print(now);
    //   }

    //   // print("CLLOSEEE HEART BEAT0");
    //   // print(heartbeatMissingCounter);
    //   // print(DateTime.now().millisecondsSinceEpoch - heartbeatMissingLastTime);
    //   if (heartbeatMissingCounter > 10) {
    //     heartbeatMissingCounter = 0;
    //     print("CLLOSEEE HEART BEAT");
    //     writeMainPort.send("RESTART");
    //     try {
    //       if (isReady) {
    //         channel.sink.close();
    //         isReady = false;
    //       }
    //     } catch (err) {}
    //     try {
    //       rcvWriteChannelPort.close();
    //       channel.sink.close();
    //     } catch (err) {}
    //     timer.cancel();
    //   }
    // });

// /*
    await Future.delayed(const Duration(milliseconds: 1400));

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
    } on HttpException catch (error) {
      clientErrorFlag = true;
      print("error");
      print(error);
    } catch (err) {
      clientErrorFlag = true;
    }

    if (clientErrorFlag) {
      isReady = false;
      print("Client Error Flag");
      writeMainPort.send("RESTART");
      return;
    }
// */
    // await client.openUrl('GET', wsUrl);
    print("request close");
    // channel = WebSocketChannel.connect(wsUrl);

    // final response = await request.close();
    // final socket = await response.detachSocket();
    // final innerChannel = StreamChannel<List<int>>(socket, socket);
    // channel = WebSocketChannel(innerChannel, serverSide: false);
// /*
    try {
      channel = IOWebSocketChannel.connect(wsUrl,
          headers: {
            'Connection': 'Upgrade',
            'Upgrade': 'websocket',
            'Sec-WebSocket-Key': 'x3JJHMbDL1EzLkh9GBhXDw==',
            'Sec-WebSocket-Version': '13'
          },
          customClient: client,
          connectTimeout: const Duration(seconds: 7),
          pingInterval: const Duration(seconds: 12));
    } on HttpException catch (err) {
      isReady = false;
      writeMainPort.send("RESTART");
      return;
    } catch (err) {
      isReady = false;
      writeMainPort.send("RESTART");
      return;
    }
    await channel.ready;

    // channel.sink.add(stopMotorCmd);

    print("WEBSOCKET CONNECT READY");
    print("stopMotorCmd+offLEDCmd : " + stopMotorCmd + offLEDCmd);
    channel.sink.add(stopMotorCmd + offLEDCmd);

    isReady = true;

    writeMainPort.send(rcvWriteChannelPort.sendPort);
    channel.stream.listen((message) {
      // print("message");
      // print(message);
      writeMainPort.send(message);
      // heartbeatMissingCounter = 0;
      // heartbeatMissingLastTime = DateTime.now().millisecondsSinceEpoch;
    }, onError: (error) {
      print("error websocket channel");
      print(error);
      // writeMainPort.send("RESTART");
      isReady = false;
      writeMainPort.send("DISCONNECTED");
    }, onDone: () {
      print("done websocket channel");
      print(channel.closeReason);
      print(channel.closeCode);
      // writeMainPort.send("DISCONNECTED");
      isReady = false;

      if (channel.closeCode == 1000 || channel.closeCode == 1005) {
      } else {
        writeMainPort.send("RESTART");
      }

      // heartbeatTimer.cancel();
      // writeMainPort.send("RESTART");
    }, cancelOnError: false);
// */
    //Listen from main isolate to write into web socket
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
        Future.delayed(const Duration(milliseconds: 500), () {
          writeMainPort.send("DISCONNECTED");
        });
      } else {
        // print("Awalan");
        // print(message);
        channel.sink.add(message);
      }
    });

    // Send port back to main isolate
  } on HttpException catch (error) {
    isReady = false;
    print('HttpExceptionXX caught');
    print('HttpExceptionXX caught: $error');
    writeMainPort.send("RESTART");

    try {
      await channel.sink.close();
    } on SocketException catch (err) {
      print("err channel sink");
      print(err);
    } catch (err2) {
      print("err channel sink 2");
      print(err2);
    }
    print('Restart: $error');

    // Implement error handling logic here
  }

// catch (err) {
//     print("Websocket channel");
//     writeMainPort.send("RESTART");
//   }
}
