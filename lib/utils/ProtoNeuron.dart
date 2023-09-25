import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';

class ProtoNeuron extends CustomPainter{
  Color activeColor = Colors.green.shade700;
  Color inactiveColor = Colors.grey;

  int neuronSize = 1;
  double screenWidth = 1000;
  double screenHeight = 800;
  List<SingleNeuron> circles = [];
  // List<String> neuronFixedType = ["RS", "RS","RS","RS", "RS", "RS","RS","RS"];
  List<String> neuronFixedType = ["RS", "IB","CH","FS", "TC", "RZ","LTS"];
  late List<List<double>> matrix;
  late List<List<double>> matrixTranspose;

  final double circleRadius = 15.0;
  final double arrowSize = 15.0;
  final double arrowMultiplier = 1.0;
  final arrowAngle=  25 * pi / 180;
  
  int idxSelected = -1;
  bool isSelected = false;
  bool isSpiking = false;
  late Paint boxPaint;
  late Paint arrowPaint;

  late Float64List aBufList;
  late Float64List bBufList;
  late Int16List cBufList;
  late Int16List dBufList;
  late Float64List iBufList;
  late Float64List wBufList;
  late Float64List connectomeBufList;


  ProtoNeuron({
    required ValueNotifier<int> notifier, required this.neuronSize, required this.screenWidth, required this.screenHeight,
    required aBufView, required bBufView,required cBufView,required dBufView,required iBufView,required wBufView, required connectomeBufView,
  }):super(repaint:notifier){

    arrowPaint = Paint()
          ..style = PaintingStyle.stroke
          ..color = Colors.black
          ..strokeWidth = 1;

    aBufList = (aBufView);
    bBufList = (bBufView);
    cBufList = (cBufView);
    dBufList = (dBufView);
    iBufList = (iBufView);
    wBufList = (wBufView);
    connectomeBufList = (connectomeBufView);

    // matrix = List<List<double>>.generate(neuronSize, ()=>List<double>.generate()=> []);
    matrix = List.generate(neuronSize, (_) => List<double>.generate(neuronSize, (_)=> 0));
    matrixTranspose = List.generate(neuronSize, (_) => List<double>.generate(neuronSize, (_)=> 0));
    generateSparseMatrix(neuronSize);
    generateCircle(neuronSize);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (idxSelected > -1){
      SingleNeuron circle = circles[idxSelected];
      Rect r = Rect.fromCenter(center: circle.centerPos, width: 32, height: 37);
      canvas.drawRect(r, boxPaint);
    }

    // for (int i = neuronSize - 1 ; i >= 0  ; i--){
    //   SingleNeuron circle = circles[i];
    //   // canvas.drawCircle(circle.centerPos, circleRadius, circle.inactivePaint);

    //   if (isSelected && i == idxSelected){
    //     Rect r = Rect.fromCenter(center: circle.centerPos, width: 32, height: 37);
    //     // if (circle.isSpiking == -1){
    //     //   canvas.drawCircle(circle.centerPos, circleRadius, circle.inactivePaint);
    //     // }else{
    //     //   canvas.drawCircle(circle.centerPos, circleRadius, circle.activePaint);
    //     // }
    //     canvas.drawRect(r, boxPaint);
    //   }else{
    //     // canvas.drawCircle(circle.centerPos, circleRadius, circle.inactivePaint);
    //     // if (circle.isSpiking == -1){
    //     //   canvas.drawCircle(circle.centerPos, circleRadius, circle.inactivePaint);
    //     // }else{
    //     //   canvas.drawCircle(circle.centerPos, circleRadius, circle.activePaint);
    //     // }
    //   }
    // }
    drawArrow(canvas);

    // if (isSpiking == -1 && isSelected == false) return false;
    // else return true;

  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;

  String randomNeuronType(){
    int r = Random().nextInt(7); // <9
    return neuronFixedType[r];

  }

  void generateCircle(int neuronSize) {
    boxPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke;

    for (int i = 0;i<neuronSize;i++){
      SingleNeuron circle = SingleNeuron();
      final inactivePaint = Paint()
        ..color = inactiveColor
        ..style = PaintingStyle.fill;
      final activePaint = Paint()
        ..color = activeColor
        ..style = PaintingStyle.fill;
      circle.neuronType = randomNeuronType();

      fillNeuronType(circle, i, aBufList,bBufList,cBufList,dBufList,iBufList,wBufList);

      circle.activePaint = (activePaint);
      circle.inactivePaint = (inactivePaint);
      double x = Random().nextDouble() * screenWidth * 2/3 + 50;
      double y = Random().nextDouble() * screenHeight* 0.5 + 50;
      circle.centerPos = Offset(x, y);
      circle.zIndex = 0;
      circles.add(circle);
    }
    print("circles.length");
    print(screenWidth);
    print(screenHeight);
    print(circles.length);
  }
  
  void generateSparseMatrix(int neuronSize) {
    int ctr = 0;
    for (int i = 0; i < neuronSize ; i++){
      for (int j = 0; j < neuronSize ; j++){
        int r = (Random().nextInt(10)+1);
        if (r % 3 == 0){
          matrix[i][j] = Random().nextDouble() * 3;
          matrixTranspose[j][i] = matrix[i][j];
        }else{
          matrix[i][j] = 0;
          matrixTranspose[j][i] = 0;
        }
        connectomeBufList[ctr++] = matrix[i][j];
      }
    }

    // print("matrix");
    // print(matrix);
  }

  // void setNeuronParameters(aBufView,bBufView,cBufView,dBufView,iBufView,wBufView){
  //   aBufList = aBufView;
  //   bBufList = bBufView;
  //   cBufList = cBufView;
  //   dBufList = dBufView;
  //   iBufList = iBufView;
  //   wBufList = wBufView;
  // }

  bool testHit(Offset globalPosition) {
    // Calculate the distance between the point and the center of the circle.
    bool _isSelected = false;
    int _idxSelected = -1;
    for (int i = neuronSize - 1 ; i >= 0; i--){
      SingleNeuron circle = circles[i];
      
      double distance = (circle.centerPos - globalPosition).distance;
      if (distance < circleRadius){
        _isSelected = true;
        _idxSelected = i;
        circle.isSelected = true;
      }
    }
    isSelected = _isSelected;
    idxSelected = _idxSelected;
    print(isSelected);
    print(idxSelected);
    return isSelected;
  }
  
  void fillNeuronType(SingleNeuron neuron, int idx, Float64List aBufList, Float64List bBufList, Int16List cBufList, Int16List dBufList, Float64List iBufList, Float64List wBufList) {
    try{
      switch(neuron.neuronType){
        case "RS":
          aBufList[idx] = 0.02;
          bBufList[idx] = 0.2;
        break;
        case "IB":
          bBufList[idx] = 0.19;

          cBufList[idx] = -55;
          dBufList[idx] = 4;
        break;
        case "CH":
          bBufList[idx] = 0.19;

          cBufList[idx] = -50;
          dBufList[idx] = 2;
        break;
        case "FS": 
          aBufList[idx] = 0.1;
          bBufList[idx] = 0.2;
        break;

        case "TC": 
          bBufList[idx] = 0.19;
          cBufList[idx] = -65;
          // dBufList[idx] = 0.05;
          dBufList[idx] = 0;
        break;      
        case "RZ":
          aBufList[idx] = 0.1;
          bBufList[idx] = 0.3;
        break;      

        case "LTS":
          aBufList[idx] = 0.02;
          bBufList[idx] = 0.25;
        break;      
      }

    }catch(ex){

    }
    neuron.a = aBufList[idx];
    neuron.b = bBufList[idx];
    neuron.c = cBufList[idx];
    neuron.d = dBufList[idx];
    neuron.i = iBufList[idx];
    neuron.w = wBufList[idx];

  }
  
  void drawArrow(canvas) {
    if (!isSelected) return;

    for (int i = 0; i < neuronSize ; i++){
      for (int j = 0; j < neuronSize ; j++){
        if (i != j ){
          if (matrix[i][j] != 0 && ( i == idxSelected || j == idxSelected) ){

            final dX = circles[j].centerPos.dx - circles[i].centerPos.dx;
            final dY = circles[j].centerPos.dy - circles[i].centerPos.dy;
            final angle = atan2(dY, dX);
            final path = Path();
            final p2= circles[j].centerPos;


            final rx1 = arrowSize * cos(angle - arrowAngle);
            final ry1 = arrowSize * sin(angle - arrowAngle);
            final rx2 = arrowSize * cos(angle + arrowAngle);
            final ry2 = arrowSize * sin(angle + arrowAngle);

            final x1 = p2.dx - rx1 * arrowMultiplier;
            final y1 = p2.dy - ry1 * arrowMultiplier;

            path.moveTo(x1, y1);
            path.lineTo(p2.dx, p2.dy);
            path.lineTo(p2.dx - rx2, p2.dy - ry2);
            path.close();
            canvas.drawPath(path, arrowPaint);

            canvas.drawLine(
              circles[i].centerPos,
              circles[j].centerPos,
              arrowPaint,
            );

          }
        }
      }
    }
    
  }
}

class SingleNeuron{
  late Paint inactivePaint;
  late Paint activePaint;
  late Offset centerPos;
  
  double a = 0;
  double b = 0;
  int c = 0;
  int d = 0;
  double i = 0;
  double w = 0;
  // double x = 0; //center posX
  // double y = 0; //center posY
  int isSpiking = -1;
  int zIndex = 0;
  bool isSelected = false;

  String neuronType = "";
  
}