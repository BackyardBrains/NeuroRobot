import 'package:flutter/material.dart';
import 'package:infinite_canvas/src/presentation/state/controller.dart';
import 'inline_painter.dart';

/// Overlay that draws teal highlight paths over annotated edges.
///
/// Sits in the canvas Stack ABOVE the edge renderer.  It fills the outline
/// paths already cached in [InfiniteCanvasController.axonPathMap] with a
/// semi-transparent teal colour, requiring zero extra geometry computation.
class AnnotationEdgeHighlighter extends StatelessWidget {
  const AnnotationEdgeHighlighter({super.key, required this.controller});

  final InfiniteCanvasController controller;

  static final _fill = Paint()
    ..color = const Color(0x9900CFFF)
    ..style = PaintingStyle.fill
    ..blendMode = BlendMode.srcOver;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: InlinePainter(
        repaint: controller.synapseFadeNotifier,
        brush: _fill,
        builder: (brush, canvas, rect) {
          if (!controller.isInAnnotationMode || controller.annotationHighlightEdges.isEmpty) return;

          for (final edge in controller.annotationHighlightEdges) {
            final fromStr = edge.from.toString();
            final toStr = edge.to.toString();

            // 1. Direct single-edge path (key: "fromKey_toKey")
            final directKey = '${fromStr}_$toStr';
            if (controller.axonPathMap.containsKey(directKey)) {
              canvas.drawPath(controller.axonPathMap[directKey]!, brush);
            }

            // 2. Trunk segment paths for this source — key: "fromKey_trunk_N"
            //    Trunk covers the shared axon leading from source to branch points.
            final trunkPrefix = '${fromStr}_trunk_';
            for (final entry in controller.axonPathMap.entries) {
              if (entry.key.startsWith(trunkPrefix)) {
                canvas.drawPath(entry.value, brush);
              }
            }
          }
        },
      ),
    );
  }
}
