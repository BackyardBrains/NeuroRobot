import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'nativec_method_channel.dart';

abstract class NativecPlatform extends PlatformInterface {
  /// Constructs a NativecPlatform.
  NativecPlatform() : super(token: _token);

  static final Object _token = Object();

  static NativecPlatform _instance = MethodChannelNativec();

  /// The default instance of [NativecPlatform] to use.
  ///
  /// Defaults to [MethodChannelNativec].
  static NativecPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [NativecPlatform] when
  /// they register themselves.
  static set instance(NativecPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
