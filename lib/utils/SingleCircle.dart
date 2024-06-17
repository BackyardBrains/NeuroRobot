import 'package:flutter/material.dart';

class SingleCircle extends CustomPainter {
  Color activeColor = Colors.green.shade700;
  // Color inactiveColor = const Color.fromRGBO(158, 158, 158, 1);
  Color inactiveColor = Colors.white;
  final double circleRadius = 10.0;
  final double arrowSize = 1.0;
  late Offset centerPos;
  late Paint circlePaint;
  late Rect rectPos;
  double zoomScale = 1.0;

  double xNucleus = 1.0;
  double yNucleus = 1.0;
  double widthNucleus = 1.0;
  double heightNucleus = 1.0;
  // Paint whiteBrush = Paint()
  //   ..color = Colors.white
  //   ..style = PaintingStyle.fill
  //   ..strokeWidth = 2;

  // SingleCircle({
  //   required ValueNotifier<int> notifier, required bool isActive,
  // }):super(repaint:notifier){
  SingleCircle({
    required bool isActive,
    required double circleRadius,
    required this.xNucleus,
    required this.yNucleus,
    required this.widthNucleus,
    required this.heightNucleus,
  }) {
    // print("Nucleus : $xNucleus, $yNucleus, $widthNucleus, $heightNucleus");
    rectPos = Rect.fromCenter(
        center: Offset(xNucleus, yNucleus),
        width: widthNucleus,
        height: heightNucleus);

    centerPos = Offset(circleRadius, circleRadius);
    circlePaint = Paint()
      ..style = PaintingStyle.fill
      ..color = inactiveColor
      ..strokeWidth = 1;
    if (isActive) {
      circlePaint.color = activeColor;
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    // print(
    //     "Paint Nucleus : $xNucleus, $yNucleus, $widthNucleus, $heightNucleus");
    // canvas.drawCircle(centerPos, circleRadius * zoomScale, circlePaint);
    canvas.drawOval(rectPos, circlePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
