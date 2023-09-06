import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'winaudio_method_channel.dart';

abstract class WinaudioPlatform extends PlatformInterface {
  /// Constructs a WinaudioPlatform.
  WinaudioPlatform() : super(token: _token);

  static final Object _token = Object();

  static WinaudioPlatform _instance = MethodChannelWinaudio();

  /// The default instance of [WinaudioPlatform] to use.
  ///
  /// Defaults to [MethodChannelWinaudio].
  static WinaudioPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [WinaudioPlatform] when
  /// they register themselves.
  static set instance(WinaudioPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    print("method channel platform version ");
    final version = _instance.getPlatformVersion();

    return version;

    // throw UnimplementedError('platformVersion() has not been implemented.');
  }

  Future<Map<String, dynamic>?> initBassAudio(int sampleRate) {
    final version = _instance.initBassAudio(sampleRate);
    return version;
  }

  Future<bool> startRecording() {
    final version = _instance.startRecording();
    return version;
  }
}
