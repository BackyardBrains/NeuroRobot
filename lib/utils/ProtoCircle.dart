import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';

class ProtoCircle extends CustomPainter{
  Color myColor = Color(0xff00FF00);
  int neuronSize = 25;
  double screenWidth = 1000;
  double screenHeight = 800;
  List<SingleCircle> circles = [];
  List<String> neuronFixedType = ["RS", "IB","CH","FS", "TC", "RZ","LTS"];
  late List<List<double>> matrix;
  late Paint myCurrentBarPaint;

  double circleRadius = 15.0;
  
  int idxSelected = -1;
  bool isSelected = false;
  bool isSpiking = false;
  late Paint boxPaint;

  late Float64List aBufList;
  late Float64List bBufList;
  late Int16List cBufList;
  late Int16List dBufList;
  late Int16List iBufList;
  late Float64List wBufList;


  ProtoCircle({
    required ValueNotifier<int> notifier, required this.neuronSize, required this.screenWidth, required this.screenHeight,
    required aBufView, required bBufView,required cBufView,required dBufView,required iBufView,required wBufView
  }):super(repaint:notifier){

    myCurrentBarPaint = Paint()
          ..style = PaintingStyle.stroke
          ..color = Color.fromARGB(255, 255, 80, 0)
          ..strokeWidth = 1;

    aBufList = aBufView;
    bBufList = bBufView;
    cBufList = cBufView;
    dBufList = dBufView;
    iBufList = iBufView;
    wBufList = wBufView;

    // matrix = List<List<double>>.generate(neuronSize, ()=>List<double>.generate()=> []);
    matrix = List.generate(neuronSize, (_) => List<double>.generate(neuronSize, (_)=> 0));
    generateSparseMatrix(neuronSize);
    generateCircle(neuronSize);
  }

  @override
  void paint(Canvas canvas, Size size) {

    drawArrow(canvas);
    for (int i = neuronSize - 1 ; i >= 0  ; i--){
      SingleCircle circle = circles[i];
      if (isSelected && i == idxSelected){
        Rect r = Rect.fromCenter(center: circle.centerPos, width: 32, height: 37);
        if (circle.isSpiking == -1){
          canvas.drawCircle(circle.centerPos, circleRadius, circle.inactivePaint);
        }else{
          canvas.drawCircle(circle.centerPos, circleRadius, circle.activePaint);
        }
        canvas.drawRect(r, boxPaint);
      }else{
        if (circle.isSpiking == -1){
          canvas.drawCircle(circle.centerPos, circleRadius, circle.inactivePaint);
        }else{
          canvas.drawCircle(circle.centerPos, circleRadius, circle.activePaint);
        }
      }
    }

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
      SingleCircle circle = SingleCircle();
      var tempPaint = Paint()
        ..color = myColor
        ..style = PaintingStyle.fill;
      circle.neuronType = randomNeuronType();
      fillNeuronType(circle, i, aBufList,bBufList,cBufList,dBufList,iBufList,wBufList);

      circle.activePaint = (tempPaint);
      circle.inactivePaint = (tempPaint);
      double x = Random().nextDouble() * screenWidth * 2/3 + 100;
      double y = Random().nextDouble() * screenHeight* 2/3 + 50;
      circle.centerPos = Offset(x, y);
      circle.zIndex = 0;
      circles.add(circle);
    }
  }
  
  void generateSparseMatrix(int neuronSize) {
    for (int i = 0; i < neuronSize ; i++){
      for (int j = 0; j < neuronSize ; j++){
        int r = (Random().nextInt(10)+1);
        if (r % 3 == 0){
          matrix[i][j] = Random().nextDouble() * 3;
        }else{
          matrix[i][j] = 0;
        }
      }
    }

    print("matrix");
    print(matrix);
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
      SingleCircle circle = circles[i];
      
      double distance = (circle.centerPos - globalPosition).distance;
      if (distance < circleRadius){
        _isSelected = true;
        _idxSelected = i;
        circle.isSelected = true;
      }
    }
    isSelected = _isSelected;
    idxSelected = _idxSelected;
    return isSelected;
  }
  
  void fillNeuronType(SingleCircle neuron, int idx, Float64List aBufList, Float64List bBufList, Int16List cBufList, Int16List dBufList, Int16List iBufList, Float64List wBufList) {
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

    neuron.a = aBufList[idx];
    neuron.b = bBufList[idx];
    neuron.c = cBufList[idx];
    neuron.d = dBufList[idx];
    neuron.i = iBufList[idx];
    neuron.w = wBufList[idx];

  }
  //https://stackoverflow.com/questions/72714333/flutter-how-do-i-make-arrow-lines-with-canvas
  void drawArrow(canvas) {
    for (int i = 0; i < neuronSize ; i++){
      for (int j = 0; j < neuronSize ; j++){
        if (i != j){
          if (matrix[i][j] != 0){
            canvas.drawLine(
              circles[i].centerPos,
              circles[j].centerPos,
              myCurrentBarPaint,
            );
          }
        }
      }
    }
    
  }
}

class SingleCircle{
  late Paint inactivePaint;
  late Paint activePaint;
  late Offset centerPos;
  
  double a = 0;
  double b = 0;
  int c = 0;
  int d = 0;
  int i = 0;
  double w = 0;
  // double x = 0; //center posX
  // double y = 0; //center posY
  int isSpiking = -1;
  int zIndex = 0;
  bool isSelected = false;

  String neuronType = "";
  
}