import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:winaudio/winaudio_method_channel.dart';

void main() {
  MethodChannelWinaudio platform = MethodChannelWinaudio();
  const MethodChannel channel = MethodChannel('winaudio');

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
