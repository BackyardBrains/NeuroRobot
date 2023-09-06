import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'mfi_method_channel.dart';

abstract class MfiPlatform extends PlatformInterface {
  /// Constructs a MfiPlatform.
  MfiPlatform() : super(token: _token);

  static final Object _token = Object();

  static MfiPlatform _instance = MethodChannelMfi();

  /// The default instance of [MfiPlatform] to use.
  ///
  /// Defaults to [MethodChannelMfi].
  static MfiPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [MfiPlatform] when
  /// they register themselves.
  static set instance(MfiPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
