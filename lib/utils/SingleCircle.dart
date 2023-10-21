import 'package:flutter/material.dart';

class SingleCircle extends CustomPainter {
  Color activeColor = Colors.green.shade700;
  Color inactiveColor = Colors.grey;
  final double circleRadius = 10.0;
  final double arrowSize = 1.0;
  late Offset centerPos;
  late Paint circlePaint;
  // SingleCircle({
  //   required ValueNotifier<int> notifier, required bool isActive,
  // }):super(repaint:notifier){
  SingleCircle({
    required bool isActive,
  }){
    centerPos = Offset(circleRadius, circleRadius);
    circlePaint = Paint()
          ..style = PaintingStyle.fill
          ..color = inactiveColor
          ..strokeWidth = 1;
    if (isActive){
      circlePaint.color = activeColor;
    }

  }


  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawCircle(centerPos, circleRadius, circlePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}