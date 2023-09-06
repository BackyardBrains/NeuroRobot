import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mfi/mfi_method_channel.dart';

void main() {
  MethodChannelMfi platform = MethodChannelMfi();
  const MethodChannel channel = MethodChannel('mfi');

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
