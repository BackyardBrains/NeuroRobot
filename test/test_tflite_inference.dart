import 'package:flutter_test/flutter_test.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'dart:typed_data';
import 'dart:io';

void main() {
  test('TFLite inference run', () {
      final interpreter = Interpreter.fromFile(File('assets/models/yolov8n-seg.tflite'));
      
      var inputShape = interpreter.getInputTensors()[0].shape;
      var outputShape0 = interpreter.getOutputTensors()[0].shape;
      var outputShape1 = interpreter.getOutputTensors()[1].shape;

      int inSize = 1;
      for (int s in inputShape) inSize *= s;
      
      int out0Size = 1;
      for (int s in outputShape0) out0Size *= s;

      int out1Size = 1;
      for (int s in outputShape1) out1Size *= s;

      final inputData = Float32List(inSize);
      final output0Data = Float32List(out0Size);
      final output1Data = Float32List(out1Size);

      interpreter.runForMultipleInputs([inputData], {0: output0Data, 1: output1Data});
      print('Inference success!');
      print('Input shape: \${inputShape}');
      print('Output 0 shape: \${outputShape0}');
      print('Output 1 shape: \${outputShape1}');
      
      // Try to determine logic
      double max116 = 0.0, max2100 = 0.0;
      for (int i = 0; i < outputShape0[2]; i++) {
          for (int c = 4; c < 84; c++) {
              max116 = output0Data[c * outputShape0[2] + i] > max116 ? output0Data[c * outputShape0[2] + i] : max116;
              max2100 = output0Data[i * outputShape0[1] + c] > max2100 ? output0Data[i * outputShape0[1] + c] : max2100;
          }
      }
      print('max116: \${max116}, max2100: \${max2100}');
  });
}
