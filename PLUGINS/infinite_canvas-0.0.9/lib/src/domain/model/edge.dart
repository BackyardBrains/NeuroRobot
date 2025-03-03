import 'package:flutter/material.dart';

/// An edge in the [InfiniteCanvas].
class InfiniteCanvasEdge {
  static bool isShowingInfo = false;

  InfiniteCanvasEdge({
    required this.from,
    required this.to,
    this.label,
  });

  final LocalKey from;
  final LocalKey to;
  String? label;
  int isReciprocate = 0;
  int isDrawn = 0;
  double connectionStrength = 0;
  Color? color;
  double isExcitatory = 1;
}
