import 'package:flutter_test/flutter_test.dart';
import 'package:winaudio/winaudio.dart';
import 'package:winaudio/winaudio_platform_interface.dart';
import 'package:winaudio/winaudio_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockWinaudioPlatform
    with MockPlatformInterfaceMixin
    implements WinaudioPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final WinaudioPlatform initialPlatform = WinaudioPlatform.instance;

  test('$MethodChannelWinaudio is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelWinaudio>());
  });

  test('getPlatformVersion', () async {
    Winaudio winaudioPlugin = Winaudio();
    MockWinaudioPlatform fakePlatform = MockWinaudioPlatform();
    WinaudioPlatform.instance = fakePlatform;

    expect(await winaudioPlugin.getPlatformVersion(), '42');
  });
}
