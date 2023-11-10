import 'package:flutter_test/flutter_test.dart';
import 'package:native_opencv/native_opencv.dart';
import 'package:native_opencv/native_opencv_platform_interface.dart';
import 'package:native_opencv/native_opencv_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockNativeOpencvPlatform
    with MockPlatformInterfaceMixin
    implements NativeOpencvPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final NativeOpencvPlatform initialPlatform = NativeOpencvPlatform.instance;

  test('$MethodChannelNativeOpencv is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelNativeOpencv>());
  });

  test('getPlatformVersion', () async {
    NativeOpencv nativeOpencvPlugin = NativeOpencv();
    MockNativeOpencvPlatform fakePlatform = MockNativeOpencvPlatform();
    NativeOpencvPlatform.instance = fakePlatform;

    expect(await nativeOpencvPlugin.getPlatformVersion(), '42');
  });
}
