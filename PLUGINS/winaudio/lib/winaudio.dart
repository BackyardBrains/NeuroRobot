import 'dart:ffi' as ffi;
import 'dart:typed_data';
import 'winaudio_platform_interface.dart';
import 'dart:ffi';
import 'BassPlugin.dart';
// import 'package:ffi/ffi.dart' as pkg_ffi;
import 'package:flutter/services.dart';

late BassPlugin bassPlugin;

class Winaudio {
  static const EventChannel _nativeEventChannel =
      EventChannel('winaudio.backyardbrains.com/audio_channel');

  static Stream audioData() {
    return _nativeEventChannel
        .receiveBroadcastStream()
        .map((data) => data)
        .distinct();
  }

  static registerWith() {
    // bassPlugin = BassPlugin(DynamicLibrary.open("bass.dll"));
  }
  Future<String?> getPlatformVersion() {
    print("getPlatformVersion winaudio.dart");
    return WinaudioPlatform.instance.getPlatformVersion();
  }

  Future<Map<String, dynamic>?> initBassAudio(int sampleRate) {
    print("init Bass Audio");
    return WinaudioPlatform.instance.initBassAudio(sampleRate);
  }

  Future<bool> startRecording() {
    print("Recording Bass Audio");
    return WinaudioPlatform.instance.startRecording();
  }

  loadLibrary() {
    // bassPlugin = BassPlugin(DynamicLibrary.open("bass.dll"));
    // print(bassPlugin);33820928 to hex 0x2041100
    // The BASS version. For example, 0x02040103 (hex), would be version 2.4.1.3
    // print(bassPlugin.BassPlugin_version(nullptr));
    // print(bassPlugin.BassPlugin_init(nullptr));
    // Pointer<Pointer<Pointer<BassPlugin_sampleBuffer>>> sambleBufferPtr = pkg_ffi.calloc<Pointer<Pointer<BassPlugin_sampleBuffer>>>();
    // print(bassPlugin.BassPlugin_channelGetData(sambleBufferPtr));
    // print("bassPlugin.BassPlugin_error(nullptr)");
    // print(bassPlugin.BassPlugin_error(nullptr));

    // print(
    //   bassPlugin.BassPlugin_init(
    //     // int device,
    //     // DWORD freq,
    //     // DWORD flags,
    //     // HWND win,
    //     // void *clsid
    //   )
    // );
  }
}
