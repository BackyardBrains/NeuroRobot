import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'dart:io';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Check TFLite shapes', (WidgetTester tester) async {
    final interpreter = await Interpreter.fromAsset('assets/models/yolov8n-seg.tflite');
    print("------- MODEL DEBUG -------");
    print("INPUT: ${interpreter.getInputTensors()[0].shape}");
    print("OUTPUT 0: ${interpreter.getOutputTensors()[0].shape}");
    print("OUTPUT 1: ${interpreter.getOutputTensors()[1].shape}");
    print("---------------------------");
  });
}
