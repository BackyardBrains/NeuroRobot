import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nativec/nativec_method_channel.dart';

void main() {
  MethodChannelNativec platform = MethodChannelNativec();
  const MethodChannel channel = MethodChannel('nativec');

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return '42';
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  test('getPlatformVersion', () async {
    expect(await platform.getPlatformVersion(), '42');
  });
}
