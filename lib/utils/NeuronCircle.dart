import 'package:flutter/material.dart';

class NeuronCircle extends CustomPainter {
  TextSpan span1 = new TextSpan(
    style: new TextStyle( color: Colors.black, backgroundColor: Colors.transparent, fontSize: 75),
    text: "1",
  );
  TextSpan span2 = new TextSpan(
    style: new TextStyle( color: Colors.black, backgroundColor: Colors.transparent, fontSize: 75),
    text: "2",
  );

  late TextPainter tp1;
  late TextPainter tp2;
  Color myColor = Color(0xff00FF00);
  List<bool> flags = [];

  NeuronCircle(Color _myColor, List<bool> _flags){
    myColor = _myColor;
    flags = _flags;
    tp1 = new TextPainter(
        text: span1,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr);

    tp2 = new TextPainter(
        text: span2,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr);

    tp1.layout();    
    tp2.layout();    
    
  }
  final Offset textCenter1 = Offset(80, 150);
  final Offset textCenter2 = Offset(280, 150);
  final Offset center1 = Offset(100, 200);
  final Offset center2 = Offset(300, 200);
  
  final Offset lineOne1 = Offset(175, 255);
  final Offset lineOne2 = Offset(250, 255);
  final Offset lineTwo1 = Offset(225, 145);
  final Offset lineTwo2 = Offset(150, 145);
  @override
  void paint(Canvas canvas, Size size) {
    var paint1 = Paint()
      ..color = myColor
      ..style = PaintingStyle.fill;
    Paint paintBorder = Paint()
      ..color = Colors.black
      ..strokeWidth = size.width/36
      ..style = PaintingStyle.stroke;      

    canvas.drawLine(lineOne1, lineOne2, paintBorder);
    canvas.drawLine(lineTwo1, lineTwo2, paintBorder);
    if (flags[0] == true){
      paint1.color = Colors.green;
      canvas.drawCircle(center1, 75, paint1);
      paint1.color = myColor;
      // print("3---- draw neuron circle");
    }
    
    if (flags[1] == true){
      paint1.color = Colors.green;
      canvas.drawCircle(center2, 75, paint1);
      paint1.color = myColor;
    }

    canvas.drawCircle(center1, 75, paintBorder);
    canvas.drawCircle(center2, 75, paintBorder);
    // canvas.drawCircle(center1, 75, paint1);
    // canvas.drawCircle(center1, 75, paintBorder);
    // canvas.drawCircle(center2, 75, paint1);
    // canvas.drawCircle(center2, 75, paintBorder);

    canvas.drawCircle(lineOne1, 15, paint1);
    canvas.drawCircle(lineTwo1, 15, paint1);

    tp1.paint(canvas, textCenter1);
    tp2.paint(canvas, textCenter2);

  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}