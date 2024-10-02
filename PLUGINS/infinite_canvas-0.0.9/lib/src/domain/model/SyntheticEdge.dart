import 'package:flutter/material.dart';

class Connection {
  // final int neuronIndex1;
  // final int neuronIndex2;
  final LocalKey neuronIndex1;
  final LocalKey neuronIndex2;
  // final int neuronKey1;
  // final int neuronKey2;
  double connectionStrength = 25;
  Path outlinePath;
  int isExcitatory = 1;

  Connection(this.neuronIndex1, this.neuronIndex2, this.connectionStrength,
      this.outlinePath, this.isExcitatory);
}

class InputOutput {
  bool isInput;
  double x;
  double y;
  double outputOrientationAngleDeg;
  InputOutput(
      {required this.isInput,
      required this.x,
      required this.y,
      required this.outputOrientationAngleDeg});
}

class SinapsePoint {
  int dendriteIndex;
  double distance;
  bool isFirstLevel;
  SinapsePoint(
      {required this.dendriteIndex,
      required this.distance,
      required this.isFirstLevel});
}
