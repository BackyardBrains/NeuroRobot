import 'package:flutter/material.dart';
import 'package:infinite_canvas/infinite_canvas.dart';
import 'package:infinite_canvas/src/domain/model/drop_target.dart';
import 'package:infinite_canvas/src/presentation/widgets/inline_painter.dart';

class InfiniteDropTargetsRenderer extends StatelessWidget {
  final InfiniteCanvasController controller;
  final List<InfiniteDropTarget> dropTargets;

  InfiniteDropTargetsRenderer(
      {super.key, required this.controller, required this.dropTargets});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: dropTargets.map((e) => e.child).toList(),
    );

    // return CustomPaint(
    //   painter: InlinePainter(
    //       brush: Paint()..color = Colors.transparent,
    //       builder: (Paint paint, Canvas canvas, Rect rect) {}),
    // );
  }
}
