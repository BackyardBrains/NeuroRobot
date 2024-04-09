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
  final arrowAngle = 25 * pi / 180;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final Paint foundEdgeBrush = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final Paint selectedEdgeBrush = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    return CustomPaint(
      painter: InlinePainter(
        brush: Paint()
          ..color = colors.outlineVariant
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
        builder: (brush, canvas, rect) {
          // List<InfiniteCanvasEdge> reciprocateList = [];
          for (final edge in edges) {
            final from =
                controller.nodes.firstWhere((node) => node.key == edge.from);
            final to =
                controller.nodes.firstWhere((node) => node.key == edge.to);

            Paint curBrush = brush;
            if (controller.isSelectingEdge && controller.edgeSelected == edge) {
              curBrush = selectedEdgeBrush;
              drawHitArea(canvas, edge);
            } else if (controller.isFoundEdge && controller.edgeFound == edge) {
              curBrush = foundEdgeBrush;
            } else {}
            
            
            double pairSpace = edge.isReciprocate * 7;
            drawEdge(
              context,
              canvas,
              // IS RECIPROCATE
              // from.rect.center,
              // to.rect.center,
              Offset(from.rect.center.dx + pairSpace,
                  from.rect.center.dy + pairSpace),
              Offset(
                  to.rect.center.dx + pairSpace, to.rect.center.dy + pairSpace),
              curBrush,
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
      // path.cubicTo(
      //   fromOffset.dx,
      //   fromOffset.dy,
      //   fromOffset.dx,
      //   toOffset.dy,
      //   toOffset.dx,
      //   toOffset.dy,
      // );

      drawArrow(context, canvas, fromOffset, toOffset, brush, path);

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

    try {
      PathMetric pathMetric = line.computeMetrics().first;
      Path extractPath = pathMetric.extractPath(0.0, pathMetric.length -10);
      var metric = extractPath.computeMetrics().first;
      final offsetMetricPos =
          metric.getTangentForOffset(metric.length)!.position;
      Offset toOffset = offsetMetricPos;

      final dX = toOffset.dx - fromOffset.dx;
      final dY = toOffset.dy - fromOffset.dy;
      final angle = atan2(dY, dX);

      final rx1 = arrowSize * cos(angle - arrowAngle);
      final ry1 = arrowSize * sin(angle - arrowAngle);
      final rx2 = arrowSize * cos(angle + arrowAngle);
      final ry2 = arrowSize * sin(angle + arrowAngle);

      final x1 = toOffset.dx - rx1 * arrowMultiplier;
      final y1 = toOffset.dy - ry1 * arrowMultiplier;

      Path path = Path();
      path.moveTo(x1, y1);
      path.lineTo(toOffset.dx, toOffset.dy);
      path.lineTo(toOffset.dx - rx2, toOffset.dy - ry2);

      path.close();
      canvas.drawPath(path, brush);
    } catch (err) {
      print("err edge renderer");
      print(err);
      return;
    }
  }

  void drawHitArea(
      // BuildContext context,
      Canvas canvas,
      InfiniteCanvasEdge edge) {
    const lineWidth = 7;
    int radius = 10;

    var eFrom = controller.nodes.where((e) => edge.from == (e.key)).toList()[0];
    var eTo = controller.nodes.where((e) => edge.to == (e.key)).toList()[0];

    double dx = eTo.offset.dx - eFrom.offset.dx;
    double dy = eTo.offset.dy - eFrom.offset.dy;

    // Normalize the direction vector
    double length = sqrt(dx * dx + dy * dy);
    double unitDx = dx / length;
    double unitDy = dy / length;

    // Compute the perpendicular direction
    double perpDx = -unitDy;
    double perpDy = unitDx;

    double pairSpace = edge.isReciprocate * 7;
    var iFrom = Offset(eFrom.offset.dx - perpDx * lineWidth + radius + pairSpace,
        eFrom.offset.dy - perpDy * lineWidth + radius + pairSpace);
    var oFrom = Offset(eFrom.offset.dx + perpDx * lineWidth + radius + pairSpace,
        eFrom.offset.dy + perpDy * lineWidth + radius + pairSpace);

    var iTo = Offset(eTo.offset.dx - perpDx * lineWidth + radius + pairSpace,
        eTo.offset.dy - perpDy * lineWidth + radius + pairSpace);
    var oTo = Offset(eTo.offset.dx + perpDx * lineWidth + radius + pairSpace,
        eTo.offset.dy + perpDy * lineWidth + radius + pairSpace);

    Path p = Path()
      ..moveTo(iFrom.dx, iFrom.dy)
      ..lineTo(iTo.dx, iTo.dy)
      ..lineTo(oTo.dx, oTo.dy)
      ..lineTo(oFrom.dx, oFrom.dy)
      ..lineTo(iFrom.dx, iFrom.dy);

    // print("OFFSET DRAW");
    // print(eFrom.value);
    // print(eTo.value);
    // print(eFrom.offset);
    // print(eTo.offset);
    // print(iFrom);
    // print(oFrom);
    // print(iTo);
    // print(oTo);

    p.close();
    Paint paint = Paint()
      ..color = Colors.yellow
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawPath(p, paint);
  }
}
