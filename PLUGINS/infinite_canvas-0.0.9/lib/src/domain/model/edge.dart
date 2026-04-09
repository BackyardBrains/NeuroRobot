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
  /// True only when this edge genuinely connects to an LED output node.
  /// Guards the gradient rendering in edge_renderer so stale edge.color
  /// on non-LED axons never triggers the black-to-color LED gradient.
  bool isLedEdge = false;
}
