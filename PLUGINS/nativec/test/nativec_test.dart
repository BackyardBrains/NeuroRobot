import 'package:flutter_test/flutter_test.dart';
import 'package:nativec/nativec.dart';
import 'package:nativec/nativec_platform_interface.dart';
import 'package:nativec/nativec_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockNativecPlatform
    with MockPlatformInterfaceMixin
    implements NativecPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final NativecPlatform initialPlatform = NativecPlatform.instance;

  test('$MethodChannelNativec is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelNativec>());
  });

  test('getPlatformVersion', () async {
    Nativec nativecPlugin = Nativec();
    MockNativecPlatform fakePlatform = MockNativecPlatform();
    NativecPlatform.instance = fakePlatform;

    expect(await nativecPlugin.getPlatformVersion(), '42');
  });
}
