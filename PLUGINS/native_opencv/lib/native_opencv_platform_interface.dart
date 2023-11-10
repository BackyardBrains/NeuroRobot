import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'native_opencv_method_channel.dart';

abstract class NativeOpencvPlatform extends PlatformInterface {
  /// Constructs a NativeOpencvPlatform.
  NativeOpencvPlatform() : super(token: _token);

  static final Object _token = Object();

  static NativeOpencvPlatform _instance = MethodChannelNativeOpencv();

  /// The default instance of [NativeOpencvPlatform] to use.
  ///
  /// Defaults to [MethodChannelNativeOpencv].
  static NativeOpencvPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [NativeOpencvPlatform] when
  /// they register themselves.
  static set instance(NativeOpencvPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
