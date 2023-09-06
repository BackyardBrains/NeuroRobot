// import 'mfi_platform_interface.dart';
import 'dart:async';

import 'package:flutter/services.dart';

class Mfi {
  static const MethodChannel _channel = MethodChannel('mfi');
  static late EventChannel spikeStatusChannel;
  static late EventChannel deviceStatusChannel;
  static late Stream<Uint8List> _spikeStatusStream;
  static late Stream<String> _deviceStatusStream;

  static void initMfi() async {
    deviceStatusChannel = EventChannel('devicestatus/event');
    spikeStatusChannel = EventChannel('spikestatus/event');
    await _channel.invokeMethod('initMfi', {"status": "init"});
  }

  static Future<String?> get platformVersion async {
    final String? version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

  static getSpikeStatus() async {
    await _channel.invokeMethod('getSpikeStatus');
    return "";
  }

  static setDeviceStatus(String s) async {
    await _channel.invokeMethod('setDeviceStatus', {"status": s});
    return "";
  }

  static setSpikeStatus(String s) async {
    await _channel.invokeMethod('setSpikeStatus', {"status": s});
    return "";
  }

  static Stream<Uint8List> getSpikeStatusStream() {
    _spikeStatusStream =
        spikeStatusChannel.receiveBroadcastStream().cast<Uint8List>();
    // .map<Uint8List>((value) => value);
    return _spikeStatusStream;
  }

  static Stream<String> getDeviceStatusStream() {
    _deviceStatusStream = deviceStatusChannel
        .receiveBroadcastStream()
        .map<String>((value) => value);
    return _deviceStatusStream;
  }
}
