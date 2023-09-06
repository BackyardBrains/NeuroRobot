import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'mfi_platform_interface.dart';

/// An implementation of [MfiPlatform] that uses method channels.
class MethodChannelMfi extends MfiPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('mfi');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
