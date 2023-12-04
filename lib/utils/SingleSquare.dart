import 'package:flutter/material.dart';

class SingleSquare extends CustomPainter {
  Color activeColor = Colors.green.shade700;
  Color inactiveColor = Colors.black;
  final double squareRadius = 20.0;
  final double arrowSize = 2.0;
  late Offset centerPos;
  late Paint squarePaint;
  SingleSquare({
    required bool isActive,
  }){
    centerPos = Offset(squareRadius, squareRadius);
    squarePaint = Paint()
          ..style = PaintingStyle.fill
          ..color = inactiveColor
          ..strokeWidth = 1;
    if (isActive){
      squarePaint.color = activeColor;
    }

  }


  @override
  void paint(Canvas canvas, Size size) {
    Rect rect = Rect.fromCenter(center: centerPos, width: squareRadius, height: squareRadius);
    canvas.drawRect(rect, squarePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}