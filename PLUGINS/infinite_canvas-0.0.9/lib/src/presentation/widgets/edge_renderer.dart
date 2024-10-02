import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:infinite_canvas/infinite_canvas.dart';
import 'package:infinite_canvas/src/domain/model/SyntheticEdge.dart';
import 'package:infinite_canvas/src/domain/model/SyntheticNeuron.dart';

import '../../domain/model/edge.dart';
import '../state/controller.dart';
import 'inline_painter.dart';

/// A widget that renders all the edges in the [InfiniteCanvas].
class InfiniteCanvasEdgeRenderer extends StatelessWidget {
  double widthClickMask = 15;

  int refreshRetainer = 0;

  InfiniteCanvasEdgeRenderer(
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

  // NEW NEURON DRAWING
  Paint blackBrush = Paint()
    ..color = Colors.black
    ..style = PaintingStyle.fill
    ..strokeWidth = 2;
  Paint graykBrush = Paint()
    ..color = Colors.grey
    ..style = PaintingStyle.fill
    ..strokeWidth = 2;
  Paint whiteBrush = Paint()
    ..color = Colors.white
    ..style = PaintingStyle.fill
    ..strokeWidth = 2;

  Paint greenBrush = Paint()
    ..color = Colors.green
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;
  Paint yellowBrush = Paint()
    ..color = Colors.yellow
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1;

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
            int fromIdx = findSyntheticNeuronIdx(
                edge.from.toString(), controller.syntheticNeuronList);
            // controller.neuronTypes.keys
            //     .toList()
            //     .indexOf(edge.from.toString());
            int toIdx = findSyntheticNeuronIdx(
                edge.to.toString(), controller.syntheticNeuronList);
            // controller.neuronTypes.keys
            //     .toList()
            //     .indexOf(edge.to.toString());

            // print("edge.from.toString()");
            // print(fromIdx);
            // print(toIdx);
            // print(controller.neuronTypes);
            // print(controller.syntheticNeuronList);
            // print(edge.from.toString());
            // print(edge.to.toString());

            double connectionStrength = edge.connectionStrength /
                2; // !! change it to connectome divide by 2
            // if (fromIdx > -1 && toIdx > -1) {
            //   // drawNeuralAxon(edge.from, edge.to, fromIdx, toIdx,
            //   //     connectionStrength, canvas);
            //   // drawNeuralAxon(
            //   //     from, to, fromIdx, toIdx, connectionStrength, canvas);

            // // this is the one working
            controller.syntheticConnections.clear();
            for (InfiniteCanvasEdge edge in controller.edges) {
              addSyntheticConnection(edge.from, edge.to);
            }

            // print("refresh retainer");
            // print(
            //     "Add Synthetic Connection ${controller.syntheticConnections.length}");

            drawAxon(from, to, fromIdx, toIdx, connectionStrength, canvas,
                from.isExcitatory);
            // }
            // drawEdge(
            //   context,
            //   canvas,
            //   // IS RECIPROCATE
            //   // from.rect.center,
            //   // to.rect.center,
            //   Offset(from.rect.center.dx + pairSpace,
            //       from.rect.center.dy + pairSpace),
            //   Offset(
            //       to.rect.center.dx + pairSpace, to.rect.center.dy + pairSpace),
            //   curBrush,
            //   label: edge.label,
            // );
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
      Path extractPath = pathMetric.extractPath(0.0, pathMetric.length - 10);
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

    String pathKey = "${eFrom.key.toString()}_${eTo.key.toString()}";
    if (controller.axonPathMap.containsKey(pathKey)) {
      canvas.drawPath(controller.axonPathMap[pathKey]!, yellowBrush);
    }
    return;

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
    var iFrom = Offset(
        eFrom.offset.dx - perpDx * lineWidth + radius + pairSpace,
        eFrom.offset.dy - perpDy * lineWidth + radius + pairSpace);
    var oFrom = Offset(
        eFrom.offset.dx + perpDx * lineWidth + radius + pairSpace,
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

  void drawNeuralAxon(InfiniteCanvasNode from, InfiniteCanvasNode to,
      int fromIdx, int toIdx, double connectionStrength, Canvas canvas) {
    List<SyntheticNeuron> neurons = controller.syntheticNeuronList;
    Neuron neuronTo = neurons[toIdx].newNeuron;

    if (neuronTo.isIO) {
      int emptySpotIndex = 0;
      int smalestNumber = 9999999;
      for (int dendriteIndex = 0;
          dendriteIndex < neuronTo.dendrites.length;
          dendriteIndex++) {
        if (neuronTo.dendrites[dendriteIndex].sinapseFirstLevel.length <
            smalestNumber) {
          emptySpotIndex = dendriteIndex;
          smalestNumber =
              neuronTo.dendrites[dendriteIndex].sinapseFirstLevel.length;
        }
      }
      Sinapse newSinapse = Sinapse(
        presinapticNeuronIndex: fromIdx,
        sinapticValue: connectionStrength,
      );
      neuronTo.dendrites[emptySpotIndex].sinapseFirstLevel.add(newSinapse);
      // continue;
      return;
    }

    Neuron neuronFrom = neurons[fromIdx].newNeuron;
    // neuronFrom.displayInfo();
    // neuronTo.displayInfo();
    //neuron to neuron connection
    List<SinapsePoint> distancesToSinapses = [];
    //find dendrite (on posinaptic neuron ) that is pointing toward center of connections of presinaptic neuron
    for (int dendriteIndex = 0;
        dendriteIndex < neuronFrom.dendrites.length;
        dendriteIndex++) {
      double distance = euclideanDistance(
          neuronFrom.xCenterOfConnections,
          neuronFrom.yCenterOfConnections,
          neuronTo.dendrites[dendriteIndex].xFirstLevel,
          neuronTo.dendrites[dendriteIndex].yFirstLevel);
      distancesToSinapses.add(SinapsePoint(
          dendriteIndex: dendriteIndex,
          distance: distance,
          isFirstLevel: true));
      if (neuronTo.dendrites[dendriteIndex].hasSecondLevel) {
        distance = euclideanDistance(
            neuronFrom.xCenterOfConnections,
            neuronFrom.yCenterOfConnections,
            neuronTo.dendrites[dendriteIndex].xSecondLevel,
            neuronTo.dendrites[dendriteIndex].ySecondLevel);
        distancesToSinapses.add(SinapsePoint(
            dendriteIndex: dendriteIndex,
            distance: distance,
            isFirstLevel: false));
      }
    }
    distancesToSinapses.sort((a, b) => a.distance.compareTo(b.distance));
    // for (var sinapse in distancesToSinapses) {
    //   print("distancesToSinapses");
    //   print(
    //       "${sinapse.dendriteIndex} : ${sinapse.distance} ${sinapse.isFirstLevel}");
    // }
    //distancesToSinapses = distancesToSinapses.reversed.toList();

    bool foundPlace = false;
    for (int disin = 0; disin < distancesToSinapses.length; disin++) {
      if (distancesToSinapses[disin].isFirstLevel) {
        if (neuronTo.dendrites[distancesToSinapses[disin].dendriteIndex]
            .sinapseFirstLevel.isEmpty) {
          foundPlace = true;

          Sinapse newSinapse = Sinapse(
            presinapticNeuronIndex: fromIdx,
            sinapticValue: connectionStrength,
          );
          neuronTo.dendrites[distancesToSinapses[disin].dendriteIndex]
              .sinapseFirstLevel
              .add(newSinapse);
          break;
        }
      } else {
        if (neuronTo.dendrites[distancesToSinapses[disin].dendriteIndex]
            .sinapseSecondLevel.isEmpty) {
          foundPlace = true;
          Sinapse newSinapse = Sinapse(
            presinapticNeuronIndex: fromIdx,
            sinapticValue: connectionStrength,
          );
          neuronTo.dendrites[distancesToSinapses[disin].dendriteIndex]
              .sinapseSecondLevel
              .add(newSinapse);
          break;
        }
      }
    }

    if (!foundPlace) {
      Sinapse newSinapse = Sinapse(
        presinapticNeuronIndex: fromIdx,
        sinapticValue: connectionStrength,
      );
      neuronTo.dendrites[distancesToSinapses[0].dendriteIndex].sinapseFirstLevel
          .add(newSinapse);
    }
    drawAxon(from, to, fromIdx, toIdx, connectionStrength, canvas,
        from.isExcitatory);
  }

  void drawAxon(InfiniteCanvasNode from, InfiniteCanvasNode to, int fromIdx,
      int toIdx, double connectionStrength, Canvas canvas, int isExcitatory) {
    double initialAxonExtensionSize = 0.5;
    List<SyntheticNeuron> neurons = controller.syntheticNeuronList;
    // if (neurons.length <= toIdx || neurons.length <= fromIdx) return;
    Neuron neuronFrom = neurons[fromIdx].newNeuron;
    Neuron neuronTo = neurons[toIdx].newNeuron;
    double circleRadius = neurons[fromIdx].circleRadius;

    if (neuronFrom.axonAngle <= -1) return;

    double centerBeginAxon_x =
        neuronFrom.x + neuronFrom.diameter * cosDeg(neuronFrom.axonAngle);
    double centerBeginAxon_y =
        neuronFrom.y + neuronFrom.diameter * sinDeg(neuronFrom.axonAngle);

    double diameterOfNeuron = neurons[fromIdx].circleRadius;
    // int maxAbsoluteConnectionStrength = connectionStrength.floor();
    int maxAbsoluteConnectionStrength = 110 - connectionStrength.floor().abs();
    double minimalTicknessOfAxon = 1;

    for (int posin = 0; posin < neuronTo.dendrites.length; posin++) {
      if (neuronTo.dendrites[posin].sinapseFirstLevel.isNotEmpty) {
        for (int sinindex = 0;
            sinindex < neuronTo.dendrites[posin].sinapseFirstLevel.length;
            sinindex++) {
          // print(
          //     "${neuronTo.dendrites[posin].sinapseFirstLevel[sinindex].presinapticNeuronIndex} == $fromIdx");
          if (neuronTo.dendrites[posin].sinapseFirstLevel[sinindex]
                  .presinapticNeuronIndex ==
              fromIdx) {
            ////////calculate basic parameters for sinapse and axons
            //found sinapse
            double xc = neuronTo.x -
                circleRadius +
                neuronTo.dendrites[posin].xFirstLevel;
            double yc = neuronTo.y -
                circleRadius +
                neuronTo.dendrites[posin].yFirstLevel;
            // print("xc,yc: $xc $yc");

            var initialPortionOfAxon = initialAxonExtensionSize *
                euclideanDistance(
                    centerBeginAxon_x, centerBeginAxon_y, xc, yc) /
                diameterOfNeuron;

            double centerEndAxon_x = neuronFrom.x -
                circleRadius +
                initialPortionOfAxon *
                    neuronFrom.diameter *
                    //diameterOfNeuronFrom *
                    cosDeg(neuronFrom.axonAngle);
            double centerEndAxon_y = neuronFrom.y -
                circleRadius +
                initialPortionOfAxon *
                    neuronFrom.diameter *
                    // diameterOfNeuronFrom *
                    sinDeg(neuronFrom.axonAngle);

            double strength = ((neuronTo.dendrites[posin]
                            .sinapseFirstLevel[sinindex].sinapticValue)
                        .abs() /
                    maxAbsoluteConnectionStrength) *
                diameterOfNeuron /
                2;
            if ((diameterOfNeuron * 0.1) > strength) {
              strength = diameterOfNeuron * 0.1;
            }
            if (strength < minimalTicknessOfAxon) {
              strength = minimalTicknessOfAxon;
            }

            blackBrush.strokeWidth = neuronFrom.diameter * (0.1);
            blackBrush.style = PaintingStyle.fill;

            // if (neuronTo.dendrites[posin].sinapseFirstLevel[sinindex]
            //         .sinapticValue >
            //     0) {
            if (isExcitatory == 1) {
              //triangle size
              double triangleSinapseSize = diameterOfNeuron / 1.5;
              //center of triangle
              double xcent = neuronTo.x -
                  circleRadius +
                  neuronTo.dendrites[posin].xFirstLevel;
              double ycent = neuronTo.y -
                  circleRadius +
                  neuronTo.dendrites[posin].yFirstLevel;

              //calculate vertex of triangle is pointy side is toward dendrite
              double xt = neuronTo.x -
                  circleRadius +
                  neuronTo.dendrites[posin].xTriangleFirstLevel;
              double yt = neuronTo.y -
                  circleRadius +
                  neuronTo.dendrites[posin].yTriangleFirstLevel;
              // print("xt,yt: $xt $yt");

              double centralAngle = angleBetweenTwoPoints(xt, yt, xcent, ycent);

              double xLeftTriangle =
                  xt + triangleSinapseSize * cosDeg(centralAngle - 30);
              double yLeftTriangle =
                  yt + triangleSinapseSize * sinDeg(centralAngle - 30);

              double xRightTriangle =
                  xt + triangleSinapseSize * cosDeg(centralAngle + 30);
              double yRightTriangle =
                  yt + triangleSinapseSize * sinDeg(centralAngle + 30);

              //calculate distance between dendrite and most far vertex if triangle is blunt side toward dendrite
              double xDoubleHeight = xt +
                  2 * triangleSinapseSize * cosDeg(30) * cosDeg(centralAngle);
              double yDoubleHeight = yt +
                  2 * triangleSinapseSize * cosDeg(30) * sinDeg(centralAngle);

              if (neuronTo.dendrites[posin].hasSecondLevel) {
                //draw axon lines
                blackBrush.strokeWidth =
                    strength; // Set stroke width for thin line
                blackBrush.style = PaintingStyle.stroke;
                double controlX = xc - 15 * (xc - xRightTriangle);
                double controlY = yc - 15 * (yc - yRightTriangle);

                double triangleCenterX =
                    (xt + xLeftTriangle + xRightTriangle) / 3;
                double triangleCenterY =
                    (yt + yLeftTriangle + yRightTriangle) / 3;

                Path clickPath = Path();
                clickPath.moveTo(centerBeginAxon_x, centerBeginAxon_y);
                clickPath.cubicTo(centerEndAxon_x, centerEndAxon_y, controlX,
                    controlY, triangleCenterX, triangleCenterY);
                String pathKey = "${from.key.toString()}_${to.key.toString()}";
                controller.axonPathMap[pathKey] =
                    getOutlinePath(clickPath, widthClickMask);

                Path path = Path();
                path.moveTo(centerBeginAxon_x, centerBeginAxon_y);
                path.cubicTo(centerEndAxon_x, centerEndAxon_y, controlX,
                    controlY, triangleCenterX, triangleCenterY);
                // print(
                //     "0--cX,cY:$controlX,$controlY - $xRightTriangle $yRightTriangle");

                canvas.drawPath(path, blackBrush);
                //draw sinapse triangle
                //draw triangle sinapse first level
                blackBrush.strokeWidth = neuronFrom.diameter * (0.07);
                blackBrush.style = PaintingStyle.stroke;
                path = Path();
                path.moveTo(xt, yt);
                path.lineTo(xLeftTriangle, yLeftTriangle);
                path.lineTo(xRightTriangle, yRightTriangle);
                path.close();
                canvas.drawPath(path, whiteBrush);
              } else {
                //draw axon line
                blackBrush.strokeWidth =
                    strength; // Set stroke width for thin line
                blackBrush.style = PaintingStyle.stroke;
                double controlX = xc + 3 * (xc - (neuronTo.x));
                double controlY = yc + 3 * (yc - (neuronTo.y));
                double triangleCenterX =
                    (xDoubleHeight + xLeftTriangle + xRightTriangle) / 3;
                double triangleCenterY =
                    (yDoubleHeight + yLeftTriangle + yRightTriangle) / 3;

                Path clickPath = Path();
                clickPath.moveTo(centerBeginAxon_x, centerBeginAxon_y);
                clickPath.cubicTo(centerEndAxon_x, centerEndAxon_y, controlX,
                    controlY, triangleCenterX, triangleCenterY);
                String pathKey = "${from.key.toString()}_${to.key.toString()}";
                controller.axonPathMap[pathKey] =
                    getOutlinePath(clickPath, widthClickMask);

                var path = Path();
                path.moveTo(centerBeginAxon_x, centerBeginAxon_y);
                path.cubicTo(centerEndAxon_x, centerEndAxon_y, controlX,
                    controlY, triangleCenterX, triangleCenterY);

                // print(
                //     "${neuronTo.x} ,, ${neuronTo.y} : ${neuronFrom.x} ,, ${neuronFrom.y} : $fromIdx,$toIdx | xcent: $xcent - ycent: $ycent | xSecondLevel : ${neuronTo.dendrites[neuronTo.dendriteIdx].xSecondLevel} | ySecondLevel : ${neuronTo.dendrites[neuronTo.dendriteIdx].ySecondLevel}");

                // print(
                //     "1--cX,cY:$controlX,$controlY - $xRightTriangle $yRightTriangle - $fromIdx:$toIdx");
                canvas.drawPath(path, blackBrush);
                //draw sinapse
                //draw triangle sinapse first level
                blackBrush.strokeWidth = neuronFrom.diameter * (0.07);
                blackBrush.style = PaintingStyle.stroke;
                path = Path();
                path.moveTo(xDoubleHeight, yDoubleHeight);
                path.lineTo(xLeftTriangle, yLeftTriangle);
                path.lineTo(xRightTriangle, yRightTriangle);
                path.close();
                canvas.drawPath(path, whiteBrush);
              }

              Path path = Path();
              if (neuronTo.dendrites[posin].hasSecondLevel) {
                path.moveTo(xt, yt);
              } else {
                path.moveTo(xDoubleHeight, yDoubleHeight);
              }

              path.lineTo(xLeftTriangle, yLeftTriangle);
              path.lineTo(xRightTriangle, yRightTriangle);
              path.close();
              canvas.drawPath(path, blackBrush);
            } else {
              blackBrush.strokeWidth =
                  strength; // Set stroke width for thin line
              blackBrush.style = PaintingStyle.stroke;
              double controlX = xc + 3 * (xc - (neuronTo.x));
              double controlY = yc + 3 * (yc - (neuronTo.y));

              // Create Mask for Click Detection
              Path clickPath = Path();
              clickPath.moveTo(centerBeginAxon_x, centerBeginAxon_y);
              clickPath.cubicTo(
                  centerEndAxon_x, centerEndAxon_y, controlX, controlY, xc, yc);
              String pathKey = "${from.key.toString()}_${to.key.toString()}";
              controller.axonPathMap[pathKey] =
                  getOutlinePath(clickPath, widthClickMask);

              var path = Path();
              path.moveTo(centerBeginAxon_x, centerBeginAxon_y);
              path.cubicTo(
                  centerEndAxon_x, centerEndAxon_y, controlX, controlY, xc, yc);
              canvas.drawPath(path, blackBrush);
              //draw circle sinapse first level
              blackBrush.strokeWidth = neuronFrom.diameter * (0.1);
              blackBrush.style = PaintingStyle.fill;
              canvas.drawCircle(
                  Offset(xc, yc), neuronFrom.diameter * 0.25, blackBrush);
              canvas.drawCircle(
                  Offset(xc, yc), neuronFrom.diameter * 0.18, whiteBrush);
            }
          }
        }
      }

      if (neuronTo.dendrites[posin].sinapseSecondLevel.isNotEmpty) {
        for (int sinindex = 0;
            sinindex < neuronTo.dendrites[posin].sinapseSecondLevel.length;
            sinindex++) {
          if (neuronTo.dendrites[posin].sinapseSecondLevel[sinindex]
                  .presinapticNeuronIndex ==
              fromIdx) {
            double xc = neuronTo.x -
                circleRadius +
                neuronTo.dendrites[posin].xSecondLevel;
            double yc = neuronTo.y -
                circleRadius +
                neuronTo.dendrites[posin].ySecondLevel;

            var initialPortionOfAxon = initialAxonExtensionSize *
                euclideanDistance(
                    centerBeginAxon_x, centerBeginAxon_y, xc, yc) /
                diameterOfNeuron;

            var centerEndAxon_x = neuronFrom.x +
                initialPortionOfAxon *
                    neuronFrom.diameter *
                    cosDeg(neuronFrom.axonAngle);
            var centerEndAxon_y = neuronFrom.y +
                initialPortionOfAxon *
                    neuronFrom.diameter *
                    sinDeg(neuronFrom.axonAngle);

            double strength = ((neuronTo.dendrites[posin]
                            .sinapseSecondLevel[sinindex].sinapticValue)
                        .abs() /
                    maxAbsoluteConnectionStrength) *
                diameterOfNeuron /
                2;
            if ((diameterOfNeuron * 0.1) > strength) {
              strength = diameterOfNeuron * 0.1;
            }

            if (strength < minimalTicknessOfAxon) {
              strength = minimalTicknessOfAxon;
            }

            // if (neuronTo.dendrites[posin].sinapseSecondLevel[sinindex]
            //         .sinapticValue >
            //     0) {
            if (isExcitatory == 1) {
              //triangle size
              double triangleSinapseSize = diameterOfNeuron / 1.5;
              //center of triangle
              double xcent = neuronTo.x -
                  circleRadius +
                  neuronTo.dendrites[posin].xSecondLevel;
              double ycent = neuronTo.y -
                  circleRadius +
                  neuronTo.dendrites[posin].ySecondLevel;

              //vertex of an isosceles triangle
              double xt = neuronTo.x -
                  circleRadius +
                  neuronTo.dendrites[posin].xTriangleSecondLevel;
              double yt = neuronTo.y -
                  circleRadius +
                  neuronTo.dendrites[posin].yTriangleSecondLevel;
              xt = xt + (xt - xcent);
              yt = yt + (yt - ycent);
              double centralAngle = angleBetweenTwoPoints(xt, yt, xcent, ycent);

              double xLeftTriangle =
                  xt + triangleSinapseSize * cosDeg(centralAngle - 30);
              double yLeftTriangle =
                  yt + triangleSinapseSize * sinDeg(centralAngle - 30);

              double xRightTriangle =
                  xt + triangleSinapseSize * cosDeg(centralAngle + 30);
              double yRightTriangle =
                  yt + triangleSinapseSize * sinDeg(centralAngle + 30);

              //calculate distance between dendrite and most far vertex if triangle is blunt side toward dendrite
              double xDoubleHeight = xt +
                  2 * triangleSinapseSize * cosDeg(30) * cosDeg(centralAngle);
              double yDoubleHeight = yt +
                  2 * triangleSinapseSize * cosDeg(30) * sinDeg(centralAngle);

              //second level sinapse
              blackBrush.strokeWidth =
                  strength; // Set stroke width for thin line
              blackBrush.style = PaintingStyle.stroke;

              double controlX = xc - 10 * (xc - xDoubleHeight);
              double controlY = yc - 10 * (yc - yDoubleHeight);

              double centerOfTriangleX =
                  (xDoubleHeight + xLeftTriangle + xRightTriangle) / 3;
              double centerOfTriangleY =
                  (yDoubleHeight + yLeftTriangle + yRightTriangle) / 3;

              // Create Mask for Click Detection
              Path clickPath = Path();
              clickPath.moveTo(centerBeginAxon_x, centerBeginAxon_y);
              clickPath.cubicTo(centerEndAxon_x, centerEndAxon_y, controlX,
                  controlY, centerOfTriangleX, centerOfTriangleY);
              String pathKey = "${from.key.toString()}_${to.key.toString()}";
              controller.axonPathMap[pathKey] =
                  getOutlinePath(clickPath, widthClickMask);

              Path path = Path();
              path.moveTo(centerBeginAxon_x, centerBeginAxon_y);
              path.cubicTo(centerEndAxon_x, centerEndAxon_y, controlX, controlY,
                  centerOfTriangleX, centerOfTriangleY);
              // print(
              //     "${neuronTo.x},${neuronTo.y} : ${neuronFrom.x},${neuronFrom.y} : $fromIdx,$toIdx");

              canvas.drawPath(path, blackBrush);

              blackBrush.strokeWidth = neuronFrom.diameter * (0.07);
              blackBrush.style = PaintingStyle.stroke;

              path = Path();
              path.moveTo(xDoubleHeight, yDoubleHeight);

              path.lineTo(xLeftTriangle, yLeftTriangle);
              path.lineTo(xRightTriangle, yRightTriangle);
              path.close();
              // canvas.drawPath(path, whiteBrush);

              path = Path();
              path.moveTo(xDoubleHeight, yDoubleHeight);
              path.lineTo(xLeftTriangle, yLeftTriangle);
              path.lineTo(xRightTriangle, yRightTriangle);
              path.close();
              canvas.drawPath(path, blackBrush);
            } else {
              var path = Path();
              blackBrush.strokeWidth =
                  strength; // Set stroke width for thin line
              blackBrush.style = PaintingStyle.stroke;
              double controlX = xc + 3 * (xc - (neuronTo.x));
              double controlY = yc + 3 * (yc - (neuronTo.y));

              // Create Mask for Click Detection
              Path clickPath = Path();
              clickPath.moveTo(centerBeginAxon_x, centerBeginAxon_y);
              clickPath.cubicTo(
                  centerEndAxon_x, centerEndAxon_y, controlX, controlY, xc, yc);
              String pathKey = "${from.key.toString()}_${to.key.toString()}";
              controller.axonPathMap[pathKey] =
                  getOutlinePath(clickPath, widthClickMask);

              path.moveTo(centerBeginAxon_x, centerBeginAxon_y);
              path.cubicTo(
                  centerEndAxon_x, centerEndAxon_y, controlX, controlY, xc, yc);
              canvas.drawPath(path, blackBrush);

              blackBrush.strokeWidth = neuronFrom.diameter * (0.1);
              blackBrush.style = PaintingStyle.fill;
              canvas.drawCircle(
                  Offset(xc, yc), neuronFrom.diameter * 0.25, blackBrush);
              canvas.drawCircle(
                  Offset(xc, yc), neuronFrom.diameter * 0.18, whiteBrush);
            }
          }
        }
      }
    }
  }

  List<SyntheticNeuron> copyFromRawSynthetics(
      List<SyntheticNeuron> syntheticNeuronList) {
    var neuronIdx = 0;
    for (SyntheticNeuron syntheticNeuron in syntheticNeuronList) {
      SyntheticNeuron rawSyntheticNeuron = syntheticNeuron.rawSyntheticNeuron;
      if (rawSyntheticNeuron.dendrites.isNotEmpty) {
        // print("raw dendrite length: ${rawSyntheticNeuron.dendrites.length}");
        // print(
        //     "dendrite length: ${syntheticNeuronList[neuronIdx].dendrites.length}");
        syntheticNeuronList[neuronIdx].dendrites.clear();

        // List<Dendrite> tempDendritesList = [];
        int dendriteIdx = 0;
        for (Dendrite rawDendrite in rawSyntheticNeuron.dendrites) {
          Dendrite newDendrite = Dendrite(
              hasSecondLevel: rawDendrite.hasSecondLevel,
              angle: rawDendrite.angle,
              // sinapseFirstLevel: rawDendrite.sinapseFirstLevel,
              // sinapseSecondLevel: rawDendrite.sinapseSecondLevel,
              // xFirstLevel: rawDendrite.xFirstLevel,
              // xSecondLevel: rawDendrite.xSecondLevel,
              sinapseFirstLevel: [],
              sinapseSecondLevel: [],
              xFirstLevel: rawDendrite.xFirstLevel,
              yFirstLevel: rawDendrite.yFirstLevel,
              xSecondLevel: rawDendrite.xSecondLevel,
              ySecondLevel: rawDendrite.ySecondLevel,
              xTriangleFirstLevel: rawDendrite.xTriangleFirstLevel,
              yTriangleFirstLevel: rawDendrite.yTriangleFirstLevel,
              xTriangleSecondLevel: rawDendrite.xTriangleSecondLevel,
              yTriangleSecondLevel: rawDendrite.yTriangleSecondLevel);
          // tempDendritesList.add(newDendrite);
          syntheticNeuronList[neuronIdx].dendrites.add(newDendrite);
          dendriteIdx++;
        }
        // syntheticNeuronList[neuronIdx].dendrites.addAll(tempDendritesList);
      }
      syntheticNeuronList[neuronIdx].recalculate(null);

      neuronIdx++;
    }
    return syntheticNeuronList;
  }

  void addSyntheticConnection(
      LocalKey axonFrom, LocalKey axonTo, double connectionStrength) {
    Map<String, String> neuronTypes = controller.neuronTypes;
    List<SyntheticNeuron> syntheticNeuronList = controller.syntheticNeuronList;
    // we must use the default raw neuron to get the initial state of the neuron
    List<SyntheticNeuron> syntheticNeurons =
        copyFromRawSynthetics(syntheticNeuronList);
    syntheticNeuronList = syntheticNeurons;

    int fromIdx = findSyntheticNeuronIdx(axonFrom.toString(), syntheticNeurons);
    //neuronTypes.keys.toList().indexOf(axonFrom.toString());
    int toIdx = findSyntheticNeuronIdx(axonTo.toString(), syntheticNeurons);
    // neuronTypes.keys.toList().indexOf(axonTo.toString());
    final nodeFrom =
        controller.nodes.firstWhere((node) => node.key == axonFrom);
    // final nodeTo = controller.nodes.firstWhere((node) => node.key == axonTo);
    double circleRadius = nodeFrom.syntheticNeuron.circleRadius;

    controller.syntheticConnections
        .add(Connection(axonFrom, axonTo, 25.0, Path()));
    // print("Add Synthetic Connection ${syntheticConnections.length}");
    // for (int i = syntheticNeurons.length - 1;
    for (int i = 0; i < syntheticNeurons.length; i++) {
      Neuron syntheticRawNeuron = syntheticNeurons[i].newNeuron;

      if (syntheticRawNeuron.isIO) {
        continue;
      }

      double numberofConnections = 1;
      double averageX = syntheticRawNeuron.x;
      double averageY = syntheticRawNeuron.y;
      bool hasAxon = false;
      for (Connection con in controller.syntheticConnections) {
        int fromNeuronIdx = findSyntheticNeuronIdx(
            con.neuronIndex1.toString(), syntheticNeurons);
        // neuronTypes.keys.toList().indexOf(con.neuronIndex1.toString());
        int toNeuronIdx = findSyntheticNeuronIdx(
            con.neuronIndex2.toString(), syntheticNeurons);
        // neuronTypes.keys.toList().indexOf(con.neuronIndex2.toString());
        if (fromNeuronIdx == i) {
          hasAxon = true;
          averageX +=
              (syntheticNeurons[toNeuronIdx].newNeuron.x - circleRadius);
          averageY +=
              (syntheticNeurons[toNeuronIdx].newNeuron.y - circleRadius);
          numberofConnections = numberofConnections + 1;
          // print(
          //     "Connection ${con.neuronIndex1} $i == $fromNeuronIdx NewNeuronX:${syntheticNeurons[toNeuronIdx].newNeuron.x} NewNeuronY:${syntheticNeurons[toNeuronIdx].newNeuron.y} $numberofConnections $averageX, $averageY");
        }
      }
      averageX = averageX / numberofConnections;
      averageY = averageY / numberofConnections;
      syntheticRawNeuron.xCenterOfConnections = averageX;
      syntheticRawNeuron.yCenterOfConnections = averageY;
      if (hasAxon && !syntheticRawNeuron.isIO) {
        double tempAxonAngle = angleBetweenTwoPoints(
            syntheticRawNeuron.x, syntheticRawNeuron.y, averageX, averageY);
        double minDistanceValue = 361;
        int minDistanceIndex = 0;
        for (int angleIndex = 0;
            angleIndex < syntheticRawNeuron.dendrites.length;
            angleIndex++) {
          double distance1 =
              ((tempAxonAngle - syntheticRawNeuron.dendrites[angleIndex].angle)
                  .abs());
          double distance2 = ((tempAxonAngle -
                  360 -
                  syntheticRawNeuron.dendrites[angleIndex].angle)
              .abs());
          // print(
          //     "$tempAxonAngle 360 ${syntheticRawNeuron.dendrites[angleIndex].angle}");
          // print(
          //     "distance1: $distance1 , distance2: $distance2 ,angleIndex: $angleIndex, ${syntheticRawNeuron.dendrites[angleIndex].angle},i:$i = minDistanceValue: $minDistanceValue minDistanceIndex:$minDistanceIndex");
          if (distance1 < minDistanceValue) {
            minDistanceValue = distance1;
            minDistanceIndex = angleIndex;
          }
          if (distance2 < minDistanceValue) {
            minDistanceValue = distance2;
            minDistanceIndex = angleIndex;
          }
        }

        syntheticRawNeuron.axonAngle =
            syntheticRawNeuron.dendrites[minDistanceIndex].angle;
        syntheticRawNeuron.dendriteIdx = minDistanceIndex;
        syntheticRawNeuron.xAxon =
            syntheticRawNeuron.dendrites[minDistanceIndex].xFirstLevel;
        syntheticRawNeuron.yAxon =
            syntheticRawNeuron.dendrites[minDistanceIndex].yFirstLevel;
        // print("remove how many times? $i - $minDistanceIndex");
        syntheticRawNeuron.dendrites.removeAt(minDistanceIndex);
      }
    }
    for (SyntheticNeuron syntheticNeuron in syntheticNeuronList) {
      syntheticNeuron.recalculate(null);
    }
    createSyntheticAxon2(syntheticNeurons, fromIdx, toIdx, 50 / 2);
  }

  void createSyntheticAxon2(List<SyntheticNeuron> syntheticNeurons,
      int pfromIdx, int ptoIdx, double d) {
    List<SyntheticNeuron> neurons = syntheticNeurons;
    List<Connection> connections = controller.syntheticConnections;
    // print("connections");
    // print(connections);
    for (int i = 0; i < neurons.length; i++) {
      for (Connection con in connections) {
        int fromIdx = findSyntheticNeuronIdx(
            con.neuronIndex1.toString(), syntheticNeurons);
        // controller.neuronTypes.keys
        //     .toList()
        //     .indexOf(con.neuronIndex1.toString());
        int toIdx = findSyntheticNeuronIdx(
            con.neuronIndex2.toString(), syntheticNeurons);
        // print("con.neuronIndex1.toString()");
        // print(con.neuronIndex1.toString());
        // print(con.neuronIndex2.toString());
        // print(fromIdx);
        // print(toIdx);

        // controller.neuronTypes.keys
        //     .toList()
        //     .indexOf(con.neuronIndex2.toString());
        // if (fromIdx == -1 || toIdx == -1) {
        //   print("neuron");
        //   print(controller.neuronTypes.keys.toList().toString());
        //   print(con.neuronIndex1.toString());
        //   print(con.neuronIndex2.toString());
        // }

        // if (neurons.length <= toIdx || neurons.length <= fromIdx) return;
        Neuron neuronTo = neurons[toIdx].newNeuron;
        Neuron neuronFrom = neurons[fromIdx].newNeuron;

        // Neuron neuronFrom = neurons[fromIdx].newNeuron;

        if (toIdx == i) {
          //check if we are connection to IO connections
          //use different logic
          if (neurons[toIdx].newNeuron.isIO) {
            int emptySpotIndex = 0;
            int smalestNumber = 9999999;
            for (int dendriteIndex = 0;
                dendriteIndex < neurons[toIdx].dendrites.length;
                dendriteIndex++) {
              if (neurons[toIdx]
                      .dendrites[dendriteIndex]
                      .sinapseFirstLevel
                      .length <
                  smalestNumber) {
                emptySpotIndex = dendriteIndex;
                smalestNumber = neurons[toIdx]
                    .dendrites[dendriteIndex]
                    .sinapseFirstLevel
                    .length;
              }
            }
            Sinapse newSinapse = Sinapse(
              presinapticNeuronIndex: fromIdx,
              sinapticValue: con.connectionStrength,
            );
            neurons[toIdx]
                .dendrites[emptySpotIndex]
                .sinapseFirstLevel
                .add(newSinapse);
            continue;
          }

          //neuron to neuron connection
          List<SinapsePoint> distancesToSinapses = [];
          //find dendrite (on posinaptic neuron ) that is pointing toward center of connections of presinaptic neuron
          for (int dendriteIndex = 0;
              dendriteIndex < neurons[toIdx].dendrites.length;
              dendriteIndex++) {
            double distance = euclideanDistance(
                neurons[fromIdx].newNeuron.xCenterOfConnections,
                neurons[fromIdx].newNeuron.yCenterOfConnections,
                neurons[toIdx].newNeuron.dendrites[dendriteIndex].xFirstLevel +
                    neuronTo.x,
                neurons[toIdx].newNeuron.dendrites[dendriteIndex].yFirstLevel +
                    neuronTo.y);
            distancesToSinapses.add(SinapsePoint(
                dendriteIndex: dendriteIndex,
                distance: distance,
                isFirstLevel: true));
            if (neurons[toIdx].dendrites[dendriteIndex].hasSecondLevel) {
              distance = euclideanDistance(
                  neurons[fromIdx].newNeuron.xCenterOfConnections,
                  neurons[fromIdx].newNeuron.yCenterOfConnections,
                  neurons[toIdx].dendrites[dendriteIndex].xSecondLevel +
                      neuronTo.x,
                  neurons[toIdx].dendrites[dendriteIndex].ySecondLevel +
                      neuronTo.y);
              distancesToSinapses.add(SinapsePoint(
                  dendriteIndex: dendriteIndex,
                  distance: distance,
                  isFirstLevel: false));
            }
            // print(
            //     "${dendriteIndex} : ${distance} ${neuronFrom.xCenterOfConnections}, ${neuronFrom.yCenterOfConnections}, SecondLevel: ${neuronTo.dendrites[dendriteIndex].xSecondLevel + neuronTo.x}, ${neuronTo.dendrites[dendriteIndex].ySecondLevel + neuronTo.y} - ${neuronTo.dendrites[dendriteIndex].hasSecondLevel} ${neuronTo.dendrites[dendriteIndex].hasSecondLevel} isFirstLevel false");
          }
          distancesToSinapses.sort((a, b) => a.distance.compareTo(b.distance));
          // print("distancesToSinapses ${distancesToSinapses.length}");
          // for (var sinapse in distancesToSinapses) {
          //   print(
          //       " $fromIdx @ $toIdx-- ${sinapse.dendriteIndex} : ${sinapse.distance} ${sinapse.isFirstLevel} == ${neuronFrom.x}|${neuronFrom.y} __ ${neuronTo.x}|${neuronTo.y}");
          // }

          //distancesToSinapses = distancesToSinapses.reversed.toList();

          bool foundPlace = false;
          for (int disin = 0; disin < distancesToSinapses.length; disin++) {
            if (distancesToSinapses[disin].isFirstLevel) {
              if (neurons[toIdx]
                  .dendrites[distancesToSinapses[disin].dendriteIndex]
                  .sinapseFirstLevel
                  .isEmpty) {
                foundPlace = true;

                Sinapse newSinapse = Sinapse(
                  presinapticNeuronIndex: fromIdx,
                  sinapticValue: con.connectionStrength,
                );
                neurons[toIdx]
                    .dendrites[distancesToSinapses[disin].dendriteIndex]
                    .sinapseFirstLevel
                    .add(newSinapse);
                break;
              }
            } else {
              if (neurons[toIdx]
                  .dendrites[distancesToSinapses[disin].dendriteIndex]
                  .sinapseSecondLevel
                  .isEmpty) {
                foundPlace = true;
                Sinapse newSinapse = Sinapse(
                  presinapticNeuronIndex: fromIdx,
                  sinapticValue: con.connectionStrength,
                );
                neurons[toIdx]
                    .dendrites[distancesToSinapses[disin].dendriteIndex]
                    .sinapseSecondLevel
                    .add(newSinapse);
                break;
              }
            }
          }

          if (!foundPlace) {
            Sinapse newSinapse = Sinapse(
              presinapticNeuronIndex: fromIdx,
              sinapticValue: con.connectionStrength,
            );
            neurons[toIdx]
                .dendrites[distancesToSinapses[0].dendriteIndex]
                .sinapseFirstLevel
                .add(newSinapse);
          }
        }
      }
    }
  }

  Path getOutlinePath(Path path, double thickness) {
    Path outlinePath = Path();
    for (PathMetric pathMetric in path.computeMetrics()) {
      for (double distance = 0.0;
          distance < pathMetric.length;
          distance += 1.0) {
        Tangent? tangent = pathMetric.getTangentForOffset(distance);
        if (tangent != null) {
          // Create a rectangle path to simulate thickness
          Rect rect = Rect.fromCenter(
            center: tangent.position,
            width: thickness,
            height: thickness,
          );
          outlinePath.addRect(rect);
        }
      }
    }
    outlinePath.close();
    return outlinePath;
  }

  int findSyntheticNeuronIdx(
      String key, List<SyntheticNeuron> syntheticNeurons) {
    int len = syntheticNeurons.length;
    for (int i = 0; i < len; i++) {
      if (syntheticNeurons[i].node.id == key) {
        return i;
      }
    }
    return -1;
  }
}
