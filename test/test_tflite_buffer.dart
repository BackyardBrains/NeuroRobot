import 'package:flutter_test/flutter_test.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'dart:typed_data';

void main() {
  test('TFLite buffer test', () {
      print(Float32List(1).buffer is List); 
      // ByteBuffer is NOT a List! tflite_flutter might fail!
  });
}
