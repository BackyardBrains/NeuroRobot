import 'dart:math';

import 'package:flutter/material.dart';
import 'package:infinite_canvas/infinite_canvas.dart';
import 'package:infinite_canvas/src/domain/model/SyntheticEdge.dart';

class SyntheticNeuron extends CustomPainter {
  static int totalNeuron = 0;
  int neuronIdx = 0;
  late SyntheticNeuron rawSyntheticNeuron;
  late InfiniteCanvasNode node;
  // late LocalKey neuronKey;
  Color activeColor = Colors.green.shade700;
  Color inactiveColor = const Color.fromRGBO(158, 158, 158, 1);
  final double circleRadius = 10.0;
  final double arrowSize = 1.0;
  late Offset centerPos;
  late Paint circlePaint;
  double zoomScale = 1.0;

  // New Neuron Design
  List<Dendrite> dendrites = [];
  // List<Sinapse> sinapFirst1 = [];
  // List<Sinapse> sinapSecond1 = [];
  Random random = Random();
  late double randomVariation1;
  late double randomVariation2;

  late Neuron newNeuron;
  Paint blackBrush = Paint()
    ..color = Colors.black
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

  // SingleCircle({
  //   required ValueNotifier<int> notifier, required bool isActive,
  // }):super(repaint:notifier){
  SyntheticNeuron({
    // required InfiniteCanvasNode node,
    // required LocalKey neuronKey,
    required bool isActive,
    required bool isIO,
    required double circleRadius,
  }) {
    neuronIdx = totalNeuron;
    centerPos = Offset(circleRadius, circleRadius);
    circlePaint = Paint()
      ..style = PaintingStyle.fill
      ..color = inactiveColor
      ..strokeWidth = 1;
    if (isActive) {
      circlePaint.color = activeColor;
    }
    totalNeuron++;
  }

  List<Sinapse> copyNeuronSinapse(List<Sinapse> rawSinapses) {
    return rawSinapses.map((e) {
      return Sinapse(
          presinapticNeuronIndex: e.presinapticNeuronIndex,
          sinapticValue: e.sinapticValue);
    }).toList();
  }

  void copyDrawingNeuron(SyntheticNeuron rawNeuron) {
    dendrites = rawNeuron.dendrites.map((e) {
      return Dendrite(
          hasSecondLevel: e.hasSecondLevel,
          angle: e.angle,
          sinapseFirstLevel: copyNeuronSinapse(e.sinapseFirstLevel),
          sinapseSecondLevel: copyNeuronSinapse(e.sinapseSecondLevel),
          xFirstLevel: e.xFirstLevel,
          yFirstLevel: e.yFirstLevel,
          xSecondLevel: e.xSecondLevel,
          ySecondLevel: e.ySecondLevel,
          xTriangleFirstLevel: e.xTriangleFirstLevel,
          yTriangleFirstLevel: e.yTriangleFirstLevel,
          xTriangleSecondLevel: e.xTriangleSecondLevel,
          yTriangleSecondLevel: e.yTriangleSecondLevel);
    }).toList();
    randomVariation1 = rawNeuron.randomVariation1;
    randomVariation2 = rawNeuron.randomVariation2;
  }

  void setupDrawingNeuron() {
    List<Sinapse> sinapFirst = [];
    List<Sinapse> sinapSecond = [];
    var totalAngle = random.nextDouble() * 70;

    Dendrite newDendrite = Dendrite(
        hasSecondLevel: random.nextDouble() < 0.4,
        angle: totalAngle,
        sinapseFirstLevel: sinapFirst,
        sinapseSecondLevel: sinapSecond,
        xFirstLevel: 0.0,
        xSecondLevel: 0.0,
        yFirstLevel: 0.0,
        ySecondLevel: 0.0,
        xTriangleFirstLevel: 0.0,
        yTriangleFirstLevel: 0.0,
        xTriangleSecondLevel: 0.0,
        yTriangleSecondLevel: 0.0);
    dendrites.add(newDendrite);

    //add rest of dendrites
    for (int i = 0; i < 5; i++) {
      totalAngle = totalAngle + 55 + random.nextDouble() * 40;
      if (totalAngle < (360 - (70 - dendrites[0].angle))) {
        List<Sinapse> sinapFirst = [];
        List<Sinapse> sinapSecond = [];
        Dendrite newDendrite = Dendrite(
            hasSecondLevel: random.nextDouble() < 0.4,
            angle: totalAngle,
            sinapseFirstLevel: sinapFirst,
            sinapseSecondLevel: sinapSecond,
            xFirstLevel: 0.0,
            xSecondLevel: 0.0,
            yFirstLevel: 0.0,
            ySecondLevel: 0.0,
            xTriangleFirstLevel: 0.0,
            yTriangleFirstLevel: 0.0,
            xTriangleSecondLevel: 0.0,
            yTriangleSecondLevel: 0.0);
        dendrites.add(newDendrite);
      }
    }

    double diameterOfNeuron = circleRadius;
    double drawX = centerPos.dx;
    double drawY = centerPos.dy;
    double x = circleRadius + node.offset.dx;
    double y = circleRadius + node.offset.dy;

    print("diameterOfNeuron");
    print(node.key.toString());
    print(diameterOfNeuron);
    print(drawX);
    print(drawY);
    print(x);
    print(y);

    // drawX, drawY need to use this because nucleus and dendrite positions are relative to the neuron
    // x,y positions are need so we can use the drawing algorithm.
    newNeuron = Neuron(
      x: x,
      y: y,
      drawX: drawX,
      drawY: drawY,
      diameter: diameterOfNeuron,
      dendrites: dendrites,
      axonAngle: -1.0,
      xCenterOfConnections: 0,
      yCenterOfConnections: 0,
      xNucleus: drawX -
          diameterOfNeuron / 3.0 +
          random.nextDouble() * 2.0 * diameterOfNeuron / 3.0,
      yNucleus: drawY + random.nextDouble() * diameterOfNeuron / 5.0,
      widthNucleus: diameterOfNeuron / (1.4 + random.nextDouble()),
      heightNucleus: diameterOfNeuron / 1.4 + random.nextDouble(),
      isIO: false,
    );

    randomVariation1 = 0.95 + 0.1 * random.nextDouble();
    randomVariation2 = 0.9 + 0.2 * random.nextDouble();
  }

  @override
  void paint(Canvas canvas, Size size) {
    // print("Neuron paint");
    recalculate(canvas);
  }

  @override
  bool shouldRepaint(covariant SyntheticNeuron oldDelegate) {
    // bool flag = oldDelegate.newNeuron.x != newNeuron.x ||
    //     oldDelegate.newNeuron.y != newNeuron.y;
    // print("flag");
    // print(flag);
    return true;
    // return flag;
  }

  void recalculate(Canvas? canvas) {
    newNeuron.x = centerPos.dx + node.offset.dx;
    newNeuron.y = centerPos.dy + node.offset.dy;

    // initial
    // canvas.drawCircle(centerPos, circleRadius * zoomScale, circlePaint);

    Neuron neur = newNeuron;
    // double neurX = neur.x - node.offset.dx;
    // double neurY = neur.y - node.offset.dy;
    // double neurXNucleus = neur.xNucleus - node.offset.dx;
    // double neurYNucleus = neur.yNucleus - node.offset.dy;
    double neurX = neur.drawX;
    double neurY = neur.drawY;
    double neurXNucleus = neur.xNucleus;
    double neurYNucleus = neur.yNucleus;

    // Draw circle at each point with predefined diameter
    if (canvas != null) {
      canvas.drawCircle(Offset(neurX, neurY), neur.diameter, blackBrush);
    }

    //draw nucleus
    Rect r = Rect.fromCenter(
        center: Offset(neurXNucleus, neurYNucleus),
        width: neur.widthNucleus,
        height: neur.heightNucleus);
    if (canvas != null) {
      canvas.drawOval(r, whiteBrush);
    }

    // print("neur.dendrites.length");
    // print(neur.dendrites.length);
    for (int i = 0; i < neur.dendrites.length; i++) {
      if (neur.isIO) {
        continue;
      }
      var angle = neur.dendrites[i].angle;

      bool hasSecondLevelNeuron = neur.dendrites[i].hasSecondLevel;

      var center_x = neurX + neur.diameter * cosDeg(angle);
      var center_y = neurY + neur.diameter * sinDeg(angle);

      var distanceToFirstLevelDendritesEnd = 1.8; //proportion do not scale
      var widthOfFirstLevelDendrites = 22.0; //angle do not scale
      var widthOfMiddleLevelDendrites = -10.0; //angle do not scale
      var distanceBetweenEndsOfFirstLevelDendrites = 13.0; //angle do not scale
      var distanceToMiddlePointOfCurve = 1.17; //proportion do not scale
      var ticknessOfEndOfDendrite = 1.2; //angle do not scale
      var ticknessOfMiddleOfDendrite = 4.0; //angle do not scale

      // randomVariation1 = 0.95 + 0.1 * random.nextDouble();
      // randomVariation1 = 1.0;
      distanceToFirstLevelDendritesEnd =
          distanceToFirstLevelDendritesEnd * randomVariation1;

      //calculate for left dendrite
      var leftStartDendrites_x =
          neurX + neur.diameter * cosDeg(angle - widthOfFirstLevelDendrites);
      var leftStartDendrites_y =
          neurY + neur.diameter * sinDeg(angle - widthOfFirstLevelDendrites);

      // randomVariation2 = 0.9 + 0.2 * random.nextDouble();
      //randomVariation2 = 1.0;
      var leftMiddleDendrites_x_plus = neurX +
          distanceToMiddlePointOfCurve *
              neur.diameter *
              cosDeg(angle -
                  widthOfMiddleLevelDendrites +
                  ticknessOfMiddleOfDendrite);
      var leftMiddleDendrites_y_plus = neurY +
          distanceToMiddlePointOfCurve *
              neur.diameter *
              sinDeg(angle -
                  widthOfMiddleLevelDendrites +
                  ticknessOfMiddleOfDendrite);
      var leftMiddleDendrites_x_minus = neurX +
          distanceToMiddlePointOfCurve *
              neur.diameter *
              cosDeg(angle -
                  widthOfMiddleLevelDendrites -
                  ticknessOfMiddleOfDendrite);
      var leftMiddleDendrites_y_minus = neurY +
          distanceToMiddlePointOfCurve *
              neur.diameter *
              sinDeg(angle -
                  widthOfMiddleLevelDendrites -
                  ticknessOfMiddleOfDendrite);

      var actualTicknessOfEndOfDendrite = hasSecondLevelNeuron
          ? 2.3 * ticknessOfEndOfDendrite
          : ticknessOfEndOfDendrite;

      var leftEndDendrites_x_plus = neurX +
          randomVariation2 *
              distanceToFirstLevelDendritesEnd *
              neur.diameter *
              cosDeg(angle -
                  distanceBetweenEndsOfFirstLevelDendrites +
                  actualTicknessOfEndOfDendrite);
      var leftEndDendrites_y_plus = neurY +
          randomVariation2 *
              distanceToFirstLevelDendritesEnd *
              neur.diameter *
              sinDeg(angle -
                  distanceBetweenEndsOfFirstLevelDendrites +
                  actualTicknessOfEndOfDendrite);

      var leftEndDendrites_x_center = neurX +
          randomVariation2 *
              distanceToFirstLevelDendritesEnd *
              1.06 *
              neur.diameter *
              cosDeg(angle - distanceBetweenEndsOfFirstLevelDendrites);
      var leftEndDendrites_y_center = neurY +
          randomVariation2 *
              distanceToFirstLevelDendritesEnd *
              1.06 *
              neur.diameter *
              sinDeg(angle - distanceBetweenEndsOfFirstLevelDendrites);

      var leftEndDendrites_x_minus = neurX +
          randomVariation2 *
              distanceToFirstLevelDendritesEnd *
              neur.diameter *
              cosDeg(angle -
                  distanceBetweenEndsOfFirstLevelDendrites -
                  actualTicknessOfEndOfDendrite);
      var leftEndDendrites_y_minus = neurY +
          randomVariation2 *
              distanceToFirstLevelDendritesEnd *
              neur.diameter *
              sinDeg(angle -
                  distanceBetweenEndsOfFirstLevelDendrites -
                  actualTicknessOfEndOfDendrite);

      //calculate for right dendrite
      var rightStartDendrites_x =
          neurX + neur.diameter * cosDeg(angle + widthOfFirstLevelDendrites);
      var rightStartDendrites_y =
          neurY + neur.diameter * sinDeg(angle + widthOfFirstLevelDendrites);

      var rightMiddleDendrites_x_plus = neurX +
          distanceToMiddlePointOfCurve *
              neur.diameter *
              cosDeg(angle +
                  widthOfMiddleLevelDendrites +
                  ticknessOfMiddleOfDendrite);
      var rightMiddleDendrites_y_plus = neurY +
          distanceToMiddlePointOfCurve *
              neur.diameter *
              sinDeg(angle +
                  widthOfMiddleLevelDendrites +
                  ticknessOfMiddleOfDendrite);
      var rightMiddleDendrites_x_minus = neurX +
          distanceToMiddlePointOfCurve *
              neur.diameter *
              cosDeg(angle +
                  widthOfMiddleLevelDendrites -
                  ticknessOfMiddleOfDendrite);
      var rightMiddleDendrites_y_minus = neurY +
          distanceToMiddlePointOfCurve *
              neur.diameter *
              sinDeg(angle +
                  widthOfMiddleLevelDendrites -
                  ticknessOfMiddleOfDendrite);

      var rightEndDendrites_x_plus = neurX +
          distanceToFirstLevelDendritesEnd *
              neur.diameter *
              cosDeg(angle +
                  distanceBetweenEndsOfFirstLevelDendrites +
                  ticknessOfEndOfDendrite);
      var rightEndDendrites_y_plus = neurY +
          distanceToFirstLevelDendritesEnd *
              neur.diameter *
              sinDeg(angle +
                  distanceBetweenEndsOfFirstLevelDendrites +
                  ticknessOfEndOfDendrite);

      double rightEndDendrites_x_center = neurX +
          distanceToFirstLevelDendritesEnd *
              1.06 *
              neur.diameter *
              cosDeg(angle + distanceBetweenEndsOfFirstLevelDendrites);
      var rightEndDendrites_y_center = neurY +
          distanceToFirstLevelDendritesEnd *
              1.06 *
              neur.diameter *
              sinDeg(angle + distanceBetweenEndsOfFirstLevelDendrites);

      var rightEndDendrites_x_minus = neurX +
          distanceToFirstLevelDendritesEnd *
              neur.diameter *
              cosDeg(angle +
                  distanceBetweenEndsOfFirstLevelDendrites -
                  ticknessOfEndOfDendrite);
      var rightEndDendrites_y_minus = neurY +
          distanceToFirstLevelDendritesEnd *
              neur.diameter *
              sinDeg(angle +
                  distanceBetweenEndsOfFirstLevelDendrites -
                  ticknessOfEndOfDendrite);

      //draw left dendrite
      var path = Path();
      if (canvas != null) {
        path.moveTo(center_x, center_y);
        path.quadraticBezierTo(
            leftMiddleDendrites_x_plus,
            leftMiddleDendrites_y_plus,
            leftEndDendrites_x_plus,
            leftEndDendrites_y_plus);
        path.quadraticBezierTo(
            leftEndDendrites_x_center,
            leftEndDendrites_y_center,
            leftEndDendrites_x_minus,
            leftEndDendrites_y_minus);
        path.quadraticBezierTo(
            leftMiddleDendrites_x_minus,
            leftMiddleDendrites_y_minus,
            leftStartDendrites_x,
            leftStartDendrites_y);
        path.lineTo(leftStartDendrites_x, leftStartDendrites_y);
        path.close();
        canvas.drawPath(path, blackBrush);
      }

      //draw right dendrite
      if (canvas != null) {
        path = Path();
        path.moveTo(center_x, center_y);
        path.quadraticBezierTo(
            rightMiddleDendrites_x_minus,
            rightMiddleDendrites_y_minus,
            rightEndDendrites_x_minus,
            rightEndDendrites_y_minus);
        path.quadraticBezierTo(
            rightEndDendrites_x_center,
            rightEndDendrites_y_center,
            rightEndDendrites_x_plus,
            rightEndDendrites_y_plus);
        path.quadraticBezierTo(
            rightMiddleDendrites_x_plus,
            rightMiddleDendrites_y_plus,
            rightStartDendrites_x,
            rightStartDendrites_y);
        path.lineTo(rightStartDendrites_x, rightStartDendrites_y);
        path.close();
        canvas.drawPath(path, blackBrush);
      }

      //calculate sinapse
      neur.dendrites[i].xFirstLevel =
          (rightEndDendrites_x_center + leftEndDendrites_x_center) * 0.5;
      neur.dendrites[i].yFirstLevel =
          (leftEndDendrites_y_center + rightEndDendrites_y_center) * 0.5;

      rawSyntheticNeuron.dendrites[i].xFirstLevel =
          neur.dendrites[i].xFirstLevel;
      rawSyntheticNeuron.dendrites[i].yFirstLevel =
          neur.dendrites[i].yFirstLevel;
      // print(
      //     "leftEndDendrites_y_center + rightEndDendrites_y_center : $leftEndDendrites_y_center $rightEndDendrites_y_center");

      //prepare central point for synapse
      double testx =
          0.5 * (leftMiddleDendrites_x_minus + rightMiddleDendrites_x_plus);
      double testy =
          0.5 * (leftMiddleDendrites_y_minus + rightMiddleDendrites_y_plus);

      if (neur.dendrites[i].hasSecondLevel) {
        neur.dendrites[i].xTriangleFirstLevel =
            0.5 * (testx + neur.dendrites[i].xFirstLevel);
        neur.dendrites[i].yTriangleFirstLevel =
            0.5 * (testy + neur.dendrites[i].yFirstLevel);

        rawSyntheticNeuron.dendrites[i].xTriangleFirstLevel =
            neur.dendrites[i].xTriangleFirstLevel;
        rawSyntheticNeuron.dendrites[i].yTriangleFirstLevel =
            neur.dendrites[i].yTriangleFirstLevel;
      } else {
        neur.dendrites[i].xTriangleFirstLevel =
            (0.75 * testx + 0.25 * neur.dendrites[i].xFirstLevel);
        neur.dendrites[i].yTriangleFirstLevel =
            (0.75 * testy + 0.25 * neur.dendrites[i].yFirstLevel);

        rawSyntheticNeuron.dendrites[i].xTriangleFirstLevel =
            neur.dendrites[i].xTriangleFirstLevel;
        rawSyntheticNeuron.dendrites[i].yTriangleFirstLevel =
            neur.dendrites[i].yTriangleFirstLevel;
      }
      // neur.dendrites[i].xTriangleFirstLevel = testx;
      // neur.dendrites[i].yTriangleFirstLevel = testy;

      //canvas.drawCircle(Offset(testx, testy), neur.diameter * 0.20, blackBrush);
      // canvas.drawCircle(
      //     Offset(
      //         neur.dendrites[i].xSecondLevel, neur.dendrites[i].ySecondLevel),
      //     neur.diameter * 0.20,
      //     greenBrush);
      //------------------------------ draw second level dendrites ------------------------------------
      if (hasSecondLevelNeuron) {
        var new_x = rightStartDendrites_x;
        var new_y = rightStartDendrites_y;

        var tip_first_level_x = leftEndDendrites_x_center;
        var tip_first_level_y = leftEndDendrites_y_center;

        //Calculate new radius and angle on new circle for 2nd level dendrites
        double newDiameter = euclideanDistance(
            new_x, new_y, tip_first_level_x, tip_first_level_y);
        double newAngle = angleBetweenTwoPoints(
            new_x, new_y, tip_first_level_x, tip_first_level_y);

        // distanceToMiddlePointOfCurve = distanceToMiddlePointOfCurve * 1.2;
        // ticknessOfMiddleOfDendrite = ticknessOfMiddleOfDendrite * -0.3;

        //calculate for left dendrite 2nd level
        var newLeftStartDendrites_x = leftEndDendrites_x_minus;
        var newLeftStartDendrites_y = leftEndDendrites_y_minus;

        distanceToMiddlePointOfCurve = 1.57; //1.17;
        widthOfMiddleLevelDendrites = 0.0; ////angle do not scale
        ticknessOfMiddleOfDendrite = 2.0; ////angle do not scale
        ticknessOfEndOfDendrite = 2.0; ////angle do not scale

        var newLeftMiddleDendrites_x_plus = new_x +
            distanceToMiddlePointOfCurve *
                neur.diameter *
                cosDeg(newAngle -
                    widthOfMiddleLevelDendrites +
                    ticknessOfMiddleOfDendrite);
        var newLeftMiddleDendrites_y_plus = new_y +
            distanceToMiddlePointOfCurve *
                neur.diameter *
                sinDeg(newAngle -
                    widthOfMiddleLevelDendrites +
                    ticknessOfMiddleOfDendrite);
        var newLeftMiddleDendrites_x_minus = new_x +
            distanceToMiddlePointOfCurve *
                neur.diameter *
                cosDeg(newAngle -
                    widthOfMiddleLevelDendrites -
                    ticknessOfMiddleOfDendrite);
        var newLeftMiddleDendrites_y_minus = new_y +
            distanceToMiddlePointOfCurve *
                neur.diameter *
                sinDeg(newAngle -
                    widthOfMiddleLevelDendrites -
                    ticknessOfMiddleOfDendrite);

        var newLeftEndDendrites_x_plus = new_x +
            distanceToFirstLevelDendritesEnd *
                neur.diameter *
                cosDeg(newAngle -
                    distanceBetweenEndsOfFirstLevelDendrites +
                    ticknessOfEndOfDendrite);
        var newLeftEndDendrites_y_plus = new_y +
            distanceToFirstLevelDendritesEnd *
                neur.diameter *
                sinDeg(newAngle -
                    distanceBetweenEndsOfFirstLevelDendrites +
                    ticknessOfEndOfDendrite);

        var newLeftEndDendrites_x_center = new_x +
            distanceToFirstLevelDendritesEnd *
                1.06 *
                neur.diameter *
                cosDeg(newAngle - distanceBetweenEndsOfFirstLevelDendrites);
        var newLeftEndDendrites_y_center = new_y +
            distanceToFirstLevelDendritesEnd *
                1.06 *
                neur.diameter *
                sinDeg(newAngle - distanceBetweenEndsOfFirstLevelDendrites);

        var newLeftEndDendrites_x_minus = new_x +
            distanceToFirstLevelDendritesEnd *
                neur.diameter *
                cosDeg(newAngle -
                    distanceBetweenEndsOfFirstLevelDendrites -
                    ticknessOfEndOfDendrite);
        var newLeftEndDendrites_y_minus = new_y +
            distanceToFirstLevelDendritesEnd *
                neur.diameter *
                sinDeg(newAngle -
                    distanceBetweenEndsOfFirstLevelDendrites -
                    ticknessOfEndOfDendrite);

        distanceToMiddlePointOfCurve = 1.57; //1.17;
        widthOfMiddleLevelDendrites = 0; ////angle do not scale
        ticknessOfMiddleOfDendrite = 2.0; //angle do not scale
        ticknessOfEndOfDendrite = 2.0; //angle do not scale

        //calculate for right dendrite 2nd level
        var newRightStartDendrites_x = leftEndDendrites_x_plus;
        var newRightStartDendrites_y = leftEndDendrites_y_plus;

        var newRightMiddleDendrites_x_plus = new_x +
            distanceToMiddlePointOfCurve *
                neur.diameter *
                cosDeg(newAngle +
                    widthOfMiddleLevelDendrites +
                    ticknessOfMiddleOfDendrite);
        var newRightMiddleDendrites_y_plus = new_y +
            distanceToMiddlePointOfCurve *
                neur.diameter *
                sinDeg(newAngle +
                    widthOfMiddleLevelDendrites +
                    ticknessOfMiddleOfDendrite);
        var newRightMiddleDendrites_x_minus = new_x +
            distanceToMiddlePointOfCurve *
                neur.diameter *
                cosDeg(newAngle +
                    widthOfMiddleLevelDendrites -
                    ticknessOfMiddleOfDendrite);
        var newRightMiddleDendrites_y_minus = new_y +
            distanceToMiddlePointOfCurve *
                neur.diameter *
                sinDeg(newAngle +
                    widthOfMiddleLevelDendrites -
                    ticknessOfMiddleOfDendrite);

        var newRightEndDendrites_x_plus = new_x +
            distanceToFirstLevelDendritesEnd *
                neur.diameter *
                cosDeg(newAngle +
                    distanceBetweenEndsOfFirstLevelDendrites +
                    ticknessOfEndOfDendrite);
        var newRightEndDendrites_y_plus = new_y +
            distanceToFirstLevelDendritesEnd *
                neur.diameter *
                sinDeg(newAngle +
                    distanceBetweenEndsOfFirstLevelDendrites +
                    ticknessOfEndOfDendrite);

        var newRightEndDendrites_x_center = new_x +
            distanceToFirstLevelDendritesEnd *
                1.06 *
                neur.diameter *
                cosDeg(newAngle + distanceBetweenEndsOfFirstLevelDendrites);
        var newRightEndDendrites_y_center = new_y +
            distanceToFirstLevelDendritesEnd *
                1.06 *
                neur.diameter *
                sinDeg(newAngle + distanceBetweenEndsOfFirstLevelDendrites);

        var newRightEndDendrites_x_minus = new_x +
            distanceToFirstLevelDendritesEnd *
                neur.diameter *
                cosDeg(newAngle +
                    distanceBetweenEndsOfFirstLevelDendrites -
                    ticknessOfEndOfDendrite);
        var newRightEndDendrites_y_minus = new_y +
            distanceToFirstLevelDendritesEnd *
                neur.diameter *
                sinDeg(newAngle +
                    distanceBetweenEndsOfFirstLevelDendrites -
                    ticknessOfEndOfDendrite);

        //draw left dendrite 2nd level
        var path = Path();
        if (canvas != null) {
          path.moveTo(newRightStartDendrites_x, newRightStartDendrites_y);
          path.quadraticBezierTo(
              newLeftMiddleDendrites_x_plus,
              newLeftMiddleDendrites_y_plus,
              newLeftEndDendrites_x_plus,
              newLeftEndDendrites_y_plus);
          path.quadraticBezierTo(
              newLeftEndDendrites_x_center,
              newLeftEndDendrites_y_center,
              newLeftEndDendrites_x_minus,
              newLeftEndDendrites_y_minus);
          path.quadraticBezierTo(
              newLeftMiddleDendrites_x_minus,
              newLeftMiddleDendrites_y_minus,
              newLeftStartDendrites_x,
              newLeftStartDendrites_y);
          path.lineTo(newRightStartDendrites_x, newRightStartDendrites_y);
          path.close();
          canvas.drawPath(path, blackBrush);
        }

        // //draw right dendrite 2nd level
        blackBrush.color = Colors.black;
        if (canvas != null) {
          path = Path();
          path.moveTo(newLeftStartDendrites_x, newLeftStartDendrites_y);
          path.quadraticBezierTo(
              newRightMiddleDendrites_x_minus,
              newRightMiddleDendrites_y_minus,
              newRightEndDendrites_x_minus,
              newRightEndDendrites_y_minus);
          path.quadraticBezierTo(
              newRightEndDendrites_x_center,
              newRightEndDendrites_y_center,
              newRightEndDendrites_x_plus,
              newRightEndDendrites_y_plus);
          path.quadraticBezierTo(
              newRightMiddleDendrites_x_plus,
              newRightMiddleDendrites_y_plus,
              newRightStartDendrites_x,
              newRightStartDendrites_y);
          path.lineTo(newLeftStartDendrites_x, newLeftStartDendrites_y);
          path.close();
          canvas.drawPath(path, blackBrush);
        }
        blackBrush.color = Colors.black;

        //draw sinapse second level
        //get coordinates of sinapse center

        neur.dendrites[i].xSecondLevel =
            (newRightEndDendrites_x_center + newLeftEndDendrites_x_center) *
                0.5;
        neur.dendrites[i].ySecondLevel =
            (newLeftEndDendrites_y_center + newRightEndDendrites_y_center) *
                0.5;
        // print("rawDendrite $neuronIdx $i");
        // // print(neur.dendrites[i].xFirstLevel);
        // // print(neur.dendrites[i].yFirstLevel);
        // print(neur.dendrites[i].xSecondLevel);
        // print(neur.dendrites[i].ySecondLevel);
        // print("=@@@@@@@@@@=");

        rawSyntheticNeuron.dendrites[i].xSecondLevel =
            neur.dendrites[i].xSecondLevel;
        rawSyntheticNeuron.dendrites[i].ySecondLevel =
            neur.dendrites[i].ySecondLevel;

        neur.dendrites[i].xTriangleSecondLevel = 0.5 *
            (newRightMiddleDendrites_x_minus + newRightMiddleDendrites_x_plus);
        neur.dendrites[i].yTriangleSecondLevel = 0.5 *
            (newRightMiddleDendrites_y_minus + newRightMiddleDendrites_y_plus);

        // print(
        //     "$i - ${neur.dendrites[i].xSecondLevel + neur.x}_${neur.dendrites[i].ySecondLevel + neur.y} ");

        // neur.dendrites[i].xTriangleSecondLevel = 0.5 * (neur.dendrites[i].xTriangleSecondLevel + neur.dendrites[i].xSecondLevel);
        // neur.dendrites[i].yTriangleSecondLevel = 0.5 * (neur.dendrites[i].yTriangleSecondLevel + neur.dendrites[i].ySecondLevel);
        //canvas.drawCircle(Offset(neur.dendrites[i].xSecondLevel, neur.dendrites[i].ySecondLevel), neur.diameter * 0.20, blackBrush);
        //canvas.drawCircle(Offset(neur.dendrites[i].xTriangleSecondLevel, neur.dendrites[i].yTriangleSecondLevel), neur.diameter * 0.20, blackBrush);
      }
    }
  }
}

class Sinapse {
  int presinapticNeuronIndex;
  double sinapticValue;
  Sinapse({required this.presinapticNeuronIndex, required this.sinapticValue});
}

class Dendrite {
  bool hasSecondLevel;
  double angle;
  List<Sinapse> sinapseFirstLevel;
  double xFirstLevel;
  double yFirstLevel;
  double xTriangleFirstLevel;
  double yTriangleFirstLevel;
  List<Sinapse> sinapseSecondLevel;
  double xSecondLevel;
  double ySecondLevel;
  double xTriangleSecondLevel;
  double yTriangleSecondLevel;
  // Constructor
  Dendrite(
      {required this.hasSecondLevel,
      required this.angle,
      required this.sinapseFirstLevel,
      required this.sinapseSecondLevel,
      required this.xFirstLevel,
      required this.yFirstLevel,
      required this.xSecondLevel,
      required this.ySecondLevel,
      required this.xTriangleFirstLevel,
      required this.xTriangleSecondLevel,
      required this.yTriangleFirstLevel,
      required this.yTriangleSecondLevel});
}

class Neuron {
  double x;
  double y;
  double drawX;
  double drawY;
  double diameter;
  List<Dendrite> dendrites;
  // List<double> dendriteAngles;
  // List<bool> dendritesSecondLevel;
  double xCenterOfConnections;
  double yCenterOfConnections;
  double axonAngle;
  double xNucleus;
  double yNucleus;
  double widthNucleus;
  double heightNucleus;
  bool isIO;
  // Stevanus
  int dendriteIdx = -1;
  double xAxon = 0;
  double yAxon = 0;

  // Constructor
  Neuron(
      {required this.x,
      required this.y,
      required this.drawX,
      required this.drawY,
      required this.diameter,
      required this.dendrites,
      required this.xCenterOfConnections,
      required this.yCenterOfConnections,
      required this.axonAngle,
      required this.xNucleus,
      required this.yNucleus,
      required this.widthNucleus,
      required this.heightNucleus,
      required this.isIO});

  // Method to display information about the neuron
  void displayInfo() {
    print('Neuron Information:');
    print('  Position: ($x, $y)');
    print('  Diameter: $diameter');
    print('  Axon angle: $axonAngle');
    print('  Nucleus Position: ($xNucleus, $yNucleus)');
    print('  Nucleus Size: $widthNucleus x $heightNucleus');
  }
}

double degToRad(double degrees) {
  return degrees * (pi / 180.0);
}

double sinDeg(double degrees) {
  return sin(degrees * (pi / 180.0));
}

double cosDeg(double degrees) {
  return cos(degrees * (pi / 180.0));
}

double euclideanDistance(double x1, double y1, double x2, double y2) {
  return sqrt(pow(x2 - x1, 2) + pow(y2 - y1, 2));
}

double angleBetweenTwoPoints(
    double centerX, double centerY, double pointX, double pointY) {
  // Calculate the angle in radians
  double angle = atan2(pointY - centerY, pointX - centerX);

  // Convert radians to degrees
  angle = angle * (180.0 / pi);

  // Ensure the angle is between 0 and 360 degrees
  angle = angle < 0 ? angle + 360.0 : angle;

  return angle;
}
