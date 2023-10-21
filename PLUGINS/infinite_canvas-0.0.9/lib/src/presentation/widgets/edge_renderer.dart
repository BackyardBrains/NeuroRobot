import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../domain/model/edge.dart';
import '../state/controller.dart';
import 'inline_painter.dart';

/// A widget that renders all the edges in the [InfiniteCanvas].
class InfiniteCanvasEdgeRenderer extends StatelessWidget {
  const InfiniteCanvasEdgeRenderer(
      {super.key,
      required this.controller,
      required this.edges,
      this.linkStart,
      this.linkEnd,
      this.straightLines = false});

  final InfiniteCanvasController controller;
  final List<InfiniteCanvasEdge> edges;
  final Offset? linkStart, linkEnd;
  final bool straightLines;


  final double arrowSize = 15.0;
  final double arrowMultiplier = 1.0;
  final arrowAngle=  25 * pi / 180;


  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return CustomPaint(
      painter: InlinePainter(
        brush: Paint()
          ..color = colors.outlineVariant
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
        builder: (brush, canvas, rect) {
          for (final edge in edges) {
            final from =
                controller.nodes.firstWhere((node) => node.key == edge.from);
            final to =
                controller.nodes.firstWhere((node) => node.key == edge.to);
            drawEdge(
              context,
              canvas,
              from.rect.center,
              to.rect.center,
              brush,
              label: edge.label,
            );
          }
        },
      ),
      foregroundPainter: InlinePainter(
        brush: Paint()
          ..color = colors.primary
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
        builder: (brush, canvas, child) {
          if (linkStart != null && linkEnd != null) {
            drawEdge(
              context,
              canvas,
              linkStart!,
              controller.toLocal(linkEnd!),
              brush,
            );
          }
        },
      ),
    );
  }

  void drawEdge(
    BuildContext context,
    Canvas canvas,
    Offset fromOffset,
    Offset toOffset,
    Paint brush, {
    String? label,
  }) {
    final colors = Theme.of(context).colorScheme;
    // Draw line from fromRect.center to toRect.center
    final path = Path();
    path.moveTo(fromOffset.dx, fromOffset.dy);

    if (straightLines) {
      path.moveTo(toOffset.dx, toOffset.dy);
    } else {
      // path.moveTo(fromOffset.dx, fromOffset.dy);
      path.lineTo(toOffset.dx, toOffset.dy);
      drawArrow(context, canvas, fromOffset, toOffset, brush, path);
      // path.cubicTo(
      //   fromOffset.dx,
      //   fromOffset.dy,
      //   fromOffset.dx,
      //   toOffset.dy,
      //   toOffset.dx,
      //   toOffset.dy,
      // );
    }
    canvas.drawPath(path, brush);
    if (label != null) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: colors.onSurface,
            shadows: [
              Shadow(
                offset: const Offset(0.8, 0.8),
                blurRadius: 3,
                color: colors.surface,
              ),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      // Render label on line
      Offset textOffset = Offset(
        (fromOffset.dx + toOffset.dx) / 2,
        (fromOffset.dy + toOffset.dy) / 2,
      );
      // Center on curve, if used
      final pathMetrics = path.computeMetrics();
      final pathMetric = pathMetrics.first;
      final pathLength = pathMetric.length;
      final middle = pathMetric.getTangentForOffset(pathLength / 2);
      textOffset = middle?.position ?? textOffset;
      // Offset to top left
      textOffset = textOffset.translate(
        -textPainter.width / 2,
        -textPainter.height / 2,
      );
      textPainter.paint(canvas, textOffset);
    }
  }

  void drawArrow(
    BuildContext context,
    Canvas canvas,
    Offset fromOffset,
    Offset rawToOffset,
    Paint rawBrush,
    Path line,
  ) {
    Paint brush = Paint()
      ..color = rawBrush.color
      ..style = PaintingStyle.fill
      ..strokeWidth = 2;

    
    // Rect r = Rect.fromCenter(center: rawToOffset, width: 20, height: 20);
    // Rect r2 = Rect.fromPoints(fromOffset, rawToOffset);
    // Rect intersect = r2.intersect(r);
    // List<Offset> checkList = [
    //   intersect.topLeft, intersect.topCenter,intersect.topRight,
    //   intersect.centerLeft, intersect.center,intersect.centerRight,
    //   intersect.bottomLeft, intersect.bottomCenter,intersect.bottomRight
    // ];

    // Offset toOffset = Offset.zero;
    // print("anther line");
    // print(rawToOffset);
    // print("Intersect");
    // print(intersect);
    // for (Offset check in checkList){
    //   if (line.contains(check) && check != rawToOffset){
    //     print("line contains check");
    //     print(check);
    //     toOffset = check;
    //   }
    // }

    PathMetric pathMetric = line.computeMetrics().first;
    Path extractPath =
        pathMetric.extractPath(0.0, pathMetric.length * 0.93);
    var metric = extractPath.computeMetrics().first;
    final offsetMetricPos = metric.getTangentForOffset(metric.length)!.position;
    Offset toOffset = offsetMetricPos;

    final dX = toOffset.dx - fromOffset.dx;
    final dY = toOffset.dy - fromOffset.dy;
    final angle = atan2(dY, dX);
    Path path = Path();


    final rx1 = arrowSize * cos(angle - arrowAngle);
    final ry1 = arrowSize * sin(angle - arrowAngle);
    final rx2 = arrowSize * cos(angle + arrowAngle);
    final ry2 = arrowSize * sin(angle + arrowAngle);

    final x1 = toOffset.dx - rx1 * arrowMultiplier;
    final y1 = toOffset.dy - ry1 * arrowMultiplier;

    // final Float64List scalingMatrix = Float64List.fromList(
    //   [0.995, 0, 0, 0,
    //   0, 0.995, 0, 0,
    //   0, 0, 1, 0,
    //   0, 0, 0, 1]);


    // int signX = dX > 0? 1 : -1;
    // int signY = dY > 0? 1 : -1;

    // double subX = 10.0 * -signX;
    // double subY = 10.0 * -signY;

    // final spaceWidth = MediaQuery.of(context).size.width * 0.005;
    // final translateMatrix = Float64List.fromList([
    //     1,             0,     0, 0,
    //     0,             1,     0, 0,
    //     0,             0,     1, 0,
    //     subX, subY, 0, 1]);

    path.moveTo(x1, y1);
    path.lineTo(toOffset.dx, toOffset.dy);
    path.lineTo(toOffset.dx - rx2, toOffset.dy - ry2);
    // path = path.transform(scalingMatrix);
    // path = path.transform(translateMatrix);

    path.close();
    canvas.drawPath(path, brush);
  }
}
