import 'package:flutter/material.dart';

/// An edge in the [InfiniteCanvas].
class InfiniteCanvasEdge {
  InfiniteCanvasEdge({
    required this.from,
    required this.to,
    this.label,
  });

  final LocalKey from;
  final LocalKey to;
  final String? label;
  int isReciprocate = 0;
  double connectionStrength = 0;
}
