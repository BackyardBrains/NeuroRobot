import 'package:flutter_test/flutter_test.dart';
import 'package:mfi/mfi.dart';
import 'package:mfi/mfi_platform_interface.dart';
import 'package:mfi/mfi_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockMfiPlatform
    with MockPlatformInterfaceMixin
    implements MfiPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final MfiPlatform initialPlatform = MfiPlatform.instance;

  test('$MethodChannelMfi is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelMfi>());
  });

  test('getPlatformVersion', () async {
    Mfi mfiPlugin = Mfi();
    MockMfiPlatform fakePlatform = MockMfiPlatform();
    MfiPlatform.instance = fakePlatform;

    expect(await mfiPlugin.getPlatformVersion(), '42');
  });
}
