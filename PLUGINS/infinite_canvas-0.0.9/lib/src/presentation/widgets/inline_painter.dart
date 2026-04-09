import 'package:flutter/material.dart';

/// A [CustomPainter] that allows you to paint on the canvas inline the widget tree.
class InlinePainter extends CustomPainter {
  const InlinePainter({
    required this.brush,
    required this.builder,
    this.isAntiAlias = true,
    this.repaintTracker,
    super.repaint,
  });
  final Paint brush;
  final bool isAntiAlias;
  final void Function(Paint brush, Canvas canvas, Rect rect) builder;
  final int? repaintTracker;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    brush.isAntiAlias = isAntiAlias;
    canvas.save();
    builder(brush, canvas, rect);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant InlinePainter oldDelegate) {
    if (repaintTracker != null && oldDelegate.repaintTracker != null) {
      return repaintTracker != oldDelegate.repaintTracker;
    }
    // Trust the superclass Listenable (repaint property) if provided
    return true; 
  }
}
