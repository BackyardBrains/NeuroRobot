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
            if (controller.isSelectingEdge && controller.edgeSelected == edge){
              curBrush = selectedEdgeBrush;
              // drawHitArea(canvas,edge);
            }else
            if (controller.isFoundEdge && controller.edgeFound == edge){
              curBrush = foundEdgeBrush;
            }else{
            }
            double pairSpace = edge.isReciprocate * 7;            
            drawEdge(
              context,
              canvas,
              // IS RECIPROCATE
              // from.rect.center,
              // to.rect.center,
              Offset(from.rect.center.dx + pairSpace, from.rect.center.dy + pairSpace),
              Offset(to.rect.center.dx + pairSpace, to.rect.center.dy + pairSpace),
              curBrush,
              label: edge.label,
            );
            
            /*
            int isReciprocate = 0;
            if (reciprocateList.indexOf(edge)>-1){
              isReciprocate = 1;
              reciprocateList.remove(edge);
            }else{
              List<InfiniteCanvasEdge> pairEdges = controller.edges.where((e) => ( e.from == edge.to && e.to == edge.from) ).toList();
              if (pairEdges.isNotEmpty){
                reciprocateList.add(pairEdges[0]);
                isReciprocate = -1;
              }
            }

            
            if (isReciprocate !=0){
              drawEdge(
                context,
                canvas,
                Offset(from.rect.center.dx, from.rect.center.dy + isReciprocate * 15),
                Offset(to.rect.center.dx, to.rect.center.dy + isReciprocate * 15),
                curBrush,
                label: edge.label,
              );
              
              if (isReciprocate == 1){

              }else{

              }
            }else{
              drawEdge(
                context,
                canvas,
                from.rect.center,
                to.rect.center,
                curBrush,
                label: edge.label,
              );
            }
            */
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

      // const lineWidth = 2;
      // var iFrom = Offset(fromOffset.dx, fromOffset.dy);
      // var oFrom = Offset( fromOffset.dx + lineWidth, fromOffset.dy + lineWidth +7);

      // var iTo = Offset(toOffset.dx, toOffset.dy);
      // var oTo = Offset( toOffset.dx + lineWidth, toOffset.dy + lineWidth + 7 );
      // final Paint testBrush = Paint()
      //   ..color = Colors.red
      //   ..style = PaintingStyle.fill
      //   ..strokeWidth = 2;

      // Path p = Path()
      //   ..moveTo(iFrom.dx - lineWidth, iFrom.dy - lineWidth)
      //   ..lineTo(iTo.dx - lineWidth, iTo.dy - lineWidth)
      //   ..lineTo(oTo.dx, oTo.dy)
      //   ..lineTo(oFrom.dx, oFrom.dy)
      //   ..lineTo(iFrom.dx - lineWidth, iFrom.dy - lineWidth);

      // p.close();   
      // canvas.drawPath(p, testBrush);
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

  
    try{
      PathMetric pathMetric = line.computeMetrics().first;
      Path extractPath =
          pathMetric.extractPath(0.0, pathMetric.length * 0.93);
      var metric = extractPath.computeMetrics().first;
      final offsetMetricPos = metric.getTangentForOffset(metric.length)!.position;
      Offset toOffset = offsetMetricPos;

      // Path extractPathStart =
      //     pathMetric.extractPath(0.0, pathMetric.length * 0.9);
      // var metricStart = extractPathStart.computeMetrics().first;
      // final offsetMetricStartPos = metricStart.getTangentForOffset(metricStart.length)!.position;
      // Offset toOffsetStart = offsetMetricStartPos;

      // Path path = Path();
      // if ( (toOffset.dx - toOffsetStart.dx).abs() < (toOffset.dy - toOffsetStart.dy).abs() ){
      //   path.moveTo(toOffset.dx, toOffset.dy);
      //   path.lineTo(toOffsetStart.dx-10, toOffsetStart.dy-5 );
      //   path.lineTo(toOffsetStart.dx+10, toOffsetStart.dy-5 );

      // }else{
      //   path.moveTo(toOffset.dx, toOffset.dy);
      //   path.lineTo(toOffsetStart.dx, toOffsetStart.dy - 10);
      //   path.lineTo(toOffsetStart.dx, toOffsetStart.dy + 10);

      // }
      // path.close();
      // canvas.drawPath(path, brush);


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
      
    }catch(err){
      print("err");
      print(err);
      return;
    }



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


    // path = path.transform(scalingMatrix);
    // path = path.transform(translateMatrix);

  }
  
  void drawHitArea(
    // BuildContext context,
    Canvas canvas,
    InfiniteCanvasEdge edge) {
      const lineWidth = 3;
      const radius = 10;
      
      var eFrom = controller.nodes.where((e) => edge.from == (e.key)).toList()[0];
      var eTo = controller.nodes.where((e) => edge.to == (e.key)).toList()[0];
      
      double pairSpace = edge.isReciprocate * 7;
      var iFrom = Offset(eFrom.offset.dx - lineWidth + radius + pairSpace, eFrom.offset.dy - lineWidth + radius + pairSpace);
      var oFrom = Offset( eFrom.offset.dx + lineWidth + radius + pairSpace, eFrom.offset.dy + lineWidth  + radius + pairSpace);
      
      
      var iTo = Offset(eTo.offset.dx - lineWidth + radius + pairSpace, eTo.offset.dy - lineWidth + radius + pairSpace);
      var oTo = Offset( eTo.offset.dx + lineWidth + radius + pairSpace, eTo.offset.dy + lineWidth + radius + pairSpace);
      Path p = Path()
        ..moveTo(iFrom.dx, iFrom.dy)
        ..lineTo(iTo.dx, iTo.dy)
        ..lineTo(oTo.dx, oTo.dy)
        ..lineTo(oFrom.dx, oFrom.dy)
        ..lineTo(iFrom.dx, iFrom.dy);

      p.close();
      Paint paint = Paint()
        ..color = Colors.yellow
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawPath(p,paint);
  }
}
