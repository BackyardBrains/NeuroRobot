import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'winaudio_platform_interface.dart';

/// An implementation of [WinaudioPlatform] that uses method channels.
class MethodChannelWinaudio extends WinaudioPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('winaudio');

  @override
  Future<String?> getPlatformVersion() async {
    print("method channel platform version");
    final version =
        await methodChannel.invokeMethod<String>('getPlatformVersion');
    print(version.toString());
    return version;
  }

  @override
  Future<Map<String, dynamic>?> initBassAudio(int sampleRate) async {
    print("initBassAudio winaudio channel");
    // final version = await methodChannel.invokeMethod<Map<String, dynamic>>('initBassAudio');
    Map<String, dynamic> maps = {};
    if (Platform.isWindows) {
      List<dynamic> lists = (await methodChannel
          .invokeMethod('initBassAudio', {'sampleRate': sampleRate}));
      lists.forEach((list) {
        var map = Map<String, dynamic>.from(list);
        maps[list['name']] = map;
      });
    } else {
      maps = Map<String, dynamic>.from(await methodChannel
          .invokeMethod('initBassAudio', {'sampleRate': sampleRate}));
    }

    print(maps.keys);
    print(maps.values);
    return maps;
  }

  @override
  Future<bool> startRecording() async {
    print("startRecording winaudio channel");
    // final version = await methodChannel.invokeMethod<Map<String, dynamic>>('initBassAudio');
    final flag = await methodChannel.invokeMethod<bool>('startRecording');

    print("startRecording winaudio channel done");
    return flag!;
  }
}
