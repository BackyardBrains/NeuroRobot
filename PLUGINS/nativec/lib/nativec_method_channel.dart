import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'nativec_platform_interface.dart';

/// An implementation of [NativecPlatform] that uses method channels.
class MethodChannelNativec extends NativecPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('nativec');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
