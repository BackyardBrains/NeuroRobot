import 'package:flutter/material.dart';

class SingleCircle extends CustomPainter {
  int isExcitatory = 1;
  // Color inactiveColor = const Color.fromRGBO(158, 158, 158, 1);
  Color activeColor = const Color(0xFF18A953);
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
  SingleCircle(
      {required bool isActive,}) {
    // print("Nucleus : $xNucleus, $yNucleus, $widthNucleus, $heightNucleus");
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
