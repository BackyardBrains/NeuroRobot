import 'package:flutter_test/flutter_test.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'dart:io';

void main() {
  test('TFLite Model Shape', () async {
    final interpreter = await Interpreter.fromFile(
      File('assets/models/yolov8n-seg.tflite')
    );
    print("Input: \${interpreter.getInputTensors()[0].shape}");
    print("Output 0: \${interpreter.getOutputTensors()[0].shape}");
    print("Output 1: \${interpreter.getOutputTensors()[1].shape}");
  });
}
