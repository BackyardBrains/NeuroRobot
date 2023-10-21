import 'dart:async';
import 'dart:convert';
import 'dart:ffi' as ffi;
import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mjpeg/flutter_mjpeg.dart';
import 'package:gesture_x_detector/gesture_x_detector.dart';
import 'package:infinite_canvas/infinite_canvas.dart';
import 'package:metooltip/metooltip.dart';
import 'package:nativec/allocation.dart';
import 'package:nativec/nativec.dart';
import 'package:neurorobot/bloc/bloc.dart';
import 'package:neurorobot/utils/ProtoNeuron.dart';
import 'package:neurorobot/utils/SingleCircle.dart';
import 'package:neurorobot/utils/WaveWidget.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:neurorobot/components/right_toolbar.dart';

class DesignBrainPage extends StatefulWidget {
  DesignBrainPage({super.key});
  @override
  State<DesignBrainPage> createState() => _DesignBrainPageState();
}

class _DesignBrainPageState extends State<DesignBrainPage> {

  // SIMULATION SECTION
  static int neuronSize = 13;
  static const int maxPosBuffer = 220;
  int epochs = 30;

  late Nativec nativec;
  static ffi.Pointer<ffi.Uint32> npsBuf = allocate<ffi.Uint32>(
      count: 2, sizeOfType: ffi.sizeOf<ffi.Uint32>());
  static ffi.Pointer<ffi.Int16> neuronCircleBuf = allocate<ffi.Int16>(
      count: maxPosBuffer, sizeOfType: ffi.sizeOf<ffi.Int16>());

  static ffi.Pointer<ffi.Int16> positionsBuf = allocate<ffi.Int16>(
      count: 1, sizeOfType: ffi.sizeOf<ffi.Int16>());

  static ffi.Pointer<ffi.Double> aBuf = allocate<ffi.Double>(
      count: maxPosBuffer, sizeOfType: ffi.sizeOf<ffi.Double>());

  static ffi.Pointer<ffi.Double> bBuf = allocate<ffi.Double>(
      count: maxPosBuffer, sizeOfType: ffi.sizeOf<ffi.Double>());

  
  static ffi.Pointer<ffi.Int16> cBuf = allocate<ffi.Int16>(
      count: maxPosBuffer, sizeOfType: ffi.sizeOf<ffi.Int16>());
  
  static ffi.Pointer<ffi.Int16> dBuf = allocate<ffi.Int16>(
      count: maxPosBuffer, sizeOfType: ffi.sizeOf<ffi.Int16>());

  static ffi.Pointer<ffi.Double> iBuf = allocate<ffi.Double>(
      count: maxPosBuffer, sizeOfType: ffi.sizeOf<ffi.Double>());
  
  static ffi.Pointer<ffi.Double> wBuf = allocate<ffi.Double>(
      count: maxPosBuffer, sizeOfType: ffi.sizeOf<ffi.Double>());


  static ffi.Pointer<ffi.Double> connectomeBuf = allocate<ffi.Double>(
      count: maxPosBuffer * maxPosBuffer, sizeOfType: ffi.sizeOf<ffi.Double>());

  // NATIVE

  late Uint32List npsBufView  = Uint32List(0);
  late Int16List neuronCircleBridge  = Int16List(0);
  late Int16List positionsBufView  = Int16List(0);
  late Float64List aBufView  = Float64List(0);
  late Float64List bBufView  = Float64List(0);
  late Int16List cBufView  = Int16List(0);
  late Int16List dBufView  = Int16List(0);
  late Float64List iBufView  = Float64List(0);
  late Float64List wBufView  = Float64List(0);
  late Float64List connectomeBufView  = Float64List(0);
  
  List<double> varA = List<double>.filled(neuronSize, 0.02);
  List<double> varB = List<double>.filled(neuronSize, 0.18);
  List<int> varC = List<int>.filled(neuronSize, -65);
  List<int> varD = List<int>.filled(neuronSize, 2);
  List<double> varI = List<double>.filled(neuronSize, 5.0);
  List<double> varW = List<double>.filled(neuronSize, 2.0);
  
  List<bool> firingFlags = List<bool>.filled(neuronSize, false);
  ValueNotifier<int> spikingFlags = ValueNotifier(0);
  
  List<ValueNotifier<int>> neuronSpikeFlags = [];
  List<GlobalKey> neuronCircleKeys = [];
  List<CustomPaint> neuronActiveCircles = [];
  List<CustomPaint> neuronInactiveCircles = [];
  // Float64List canvasBufferBytes = Float64List(6000);
  ValueNotifier<int> waveRedraw = ValueNotifier(0);
  
  int isPlaying = 1;
  double levelMedian = 30;
  double chartGain = 0.67;

  bool isInitialized = false;
  
  late ProtoNeuron protoNeuron;
  bool isSelected = true;
  int selectedIdx = 0;
  ValueNotifier<int> redrawNeuronLine = ValueNotifier(0);
  
  late WaveWidget waveWidget;
  
  late Mjpeg mjpegComponent;
  
  bool isEmergencyPause = false;
  

  void runNativeC(){
    const level = 1;
    const envelopeSize = 200;
    const bufferSize = 2000;
    nativec.changeNeuronSimulatorProcess(aBuf, bBuf, cBuf, dBuf, iBuf, wBuf,connectomeBuf,level, neuronSize, envelopeSize, bufferSize, 1);    
  }
  
  void initNativeC(){
    const a = 0.02;
    const b = 0.18;
    const c = -65;
    const d = 2;
    const i = 5.0;
    const w = 2.0;
    
    // int neuronSizeType = neuronSize;
    if (kIsWeb){
      // aBufView  = Float64List(neuronSize);
      // bBufView  = Float64List(neuronSize);
      // cBufView  = Int16List(neuronSize);
      // dBufView  = Int16List(neuronSize);
      // iBufView  = Float64List(neuronSize);
      // wBufView  = Float64List(neuronSize);
      // positionsBufView  = Int16List(neuronSize);
      // connectomeBufView  = Float64List(neuronSize*neuronSize);
    }else{
      nativec = Nativec();
      nativec.passPointers(Nativec.canvasBuffer1, positionsBuf, neuronCircleBuf, npsBuf);
      aBufView = aBuf.asTypedList(neuronSize);
      bBufView = bBuf.asTypedList(neuronSize);
      cBufView = cBuf.asTypedList(neuronSize);
      dBufView = dBuf.asTypedList(neuronSize);
      iBufView = iBuf.asTypedList(neuronSize);
      wBufView = wBuf.asTypedList(neuronSize);
      npsBufView = npsBuf.asTypedList(2);
      neuronCircleBridge = neuronCircleBuf.asTypedList(neuronSize);
      positionsBufView = positionsBuf.asTypedList(neuronSize);
      connectomeBufView = connectomeBuf.asTypedList(neuronSize * neuronSize);
    }
    aBufView.fillRange(0, neuronSize, a);
    bBufView.fillRange(0, neuronSize, b);
    cBufView.fillRange(0, neuronSize, c);
    dBufView.fillRange(0, neuronSize, d);
    iBufView.fillRange(0, neuronSize, i);
    wBufView.fillRange(0, neuronSize, w);
    positionsBufView.fillRange(0, neuronSize, 0);
    connectomeBufView.fillRange(0, neuronSize * neuronSize, 0);
    neuronSpikeFlags = List<ValueNotifier<int>>.generate(neuronSize, (_)=>ValueNotifier(0));
    neuronCircleKeys = List<GlobalKey>.generate(neuronSize, (i)=>GlobalKey(debugLabel:"neuronWidget${i.toString()}"));
    neuronActiveCircles = List<CustomPaint>.generate(neuronSize, (int idx){
      return CustomPaint(
        painter: SingleCircle( isActive: true),
        willChange: false,
        isComplex: false,
      );
    });

    neuronInactiveCircles = List<CustomPaint>.generate(neuronSize, (int idx){
      return CustomPaint(
        painter: SingleCircle( isActive: false),
        willChange: false,
        isComplex: false,
      );
    });

    WaveWidget.positionsBufView = positionsBufView;

    if (kIsWeb){
      
    }else{
      // if (delay){
      //   Future.delayed(const Duration(milliseconds: 300), (){
      //   });
      // }else{
      //   nativec.changeNeuronSimulatorProcess(aBuf, bBuf, cBuf, dBuf, iBuf, wBuf,connectomeBuf,level, neuronSize, envelopeSize, bufferSize, 1);     
      // }
    }
  }

  // END of SIMULATION SECTION


  late InfiniteCanvasController controller;
  int menuIdx = 0;
  bool isCreatePoint = false;

  List<UniqueKey> neuronsKey = [];
  List<UniqueKey> axonsKey = [];
  
  Offset constraintOffsetTopLeft = const Offset(300, 170);
  Offset constraintOffsetTopRight = const Offset(500,170);
  Offset constraintOffsetBottomRight = const Offset(500, 430);
  Offset constraintOffsetBottomLeft = const Offset(300, 430);

  List<InfiniteCanvasNode> listDefaultSensor = [];
  List<String> listDefaultSensorLabel = [];
  ValueNotifier<int> tooltipValueChange = ValueNotifier(0);
  
  static var viewportKey = UniqueKey();
  InfiniteCanvasNode viewPortNode = InfiniteCanvasNode(
    key: viewportKey,
    allowMove: false,
    allowResize: false,
    offset: const Offset(800, 600),
    size: const Size(0, 0), 
    child: const SizedBox(width: 0,height:0,)
  );

  InfiniteCanvasNode nodeDistanceSensor = InfiniteCanvasNode(
    key: UniqueKey(),
    value:0,
    allowMove: false,
    allowResize: false,
    offset: const Offset(395, 150),
    size: const Size(20, 20), 
    child: Container(width: 15,height:15, color:Colors.black),
  );

  InfiniteCanvasNode nodeLeftEyeSensor = InfiniteCanvasNode(
    key: UniqueKey(),
    value:1,
    allowMove: false,
    allowResize: false,
    offset: const Offset(320, 150),
    size: const Size(20, 20), 
    child: Container(width: 15,height:15, color:Colors.black),
  );  
  InfiniteCanvasNode nodeRightEyeSensor = InfiniteCanvasNode(
    key: UniqueKey(),
    value:2,
    allowMove: false,
    allowResize: false,
    offset: const Offset(470, 150),
    size: const Size(20, 20), 
    child: Container(width: 15,height:15, color:Colors.black),
  );  

  InfiniteCanvasNode nodeMicrophoneSensor = InfiniteCanvasNode(
    key: UniqueKey(),
    value:3,
    allowMove: false,
    allowResize: false,
    offset: const Offset(267, 217),
    size: const Size(20, 20), 
    child: Container(width: 15,height:15, color:Colors.black),
  );  
  InfiniteCanvasNode nodeSpeakerSensor = InfiniteCanvasNode(
    key: UniqueKey(),
    value:4,
    allowMove: false,
    allowResize: false,
    offset: const Offset(523, 217),
    size: const Size(20, 20), 
    child: Container(width: 15,height:15, color:Colors.black),
  );  

  InfiniteCanvasNode nodeLeftMotorForwardSensor = InfiniteCanvasNode(
    key: UniqueKey(),
    value:5,
    allowMove: false,
    allowResize: false,
    offset: const Offset(243, 310),
    size: const Size(20, 20), 
    child: Container(width: 15,height:15, color:Colors.black),
  );  
  InfiniteCanvasNode nodeRightMotorForwardSensor = InfiniteCanvasNode(
    key: UniqueKey(),
    value:6,
    allowMove: false,
    allowResize: false,
    offset: const Offset(547, 310),
    size: const Size(20, 20), 
    child: Container(width: 15,height:15, color:Colors.black),
  );

  InfiniteCanvasNode nodeLeftMotorBackwardSensor = InfiniteCanvasNode(
    key: UniqueKey(),
    value:7,
    allowMove: false,
    allowResize: false,
    offset: const Offset(240, 405),
    size: const Size(20, 20), 
    child: Container(width: 15,height:15, color:Colors.black),
  );  
  InfiniteCanvasNode nodeRightMotorBackwardSensor = InfiniteCanvasNode(
    key: UniqueKey(),
    value:8,
    allowMove: false,
    allowResize: false,
    offset: const Offset(550, 405),
    size: const Size(20, 20), 
    child: Container(width: 15,height:15, color:Colors.black),
  );    
  // InfiniteCanvasNode constraintOffsetTopRight = InfiniteCanvasNode(
  //   key: UniqueKey(),
  //   allowMove: false,
  //   allowResize: false,
  //   offset: const Offset(500, 170),
  //   size: const Size(10, 10), 
  //   child: Container(width: 0,height:0, color:Colors.green),
  // );
  // InfiniteCanvasNode constraintOffsetBottomRight = InfiniteCanvasNode(
  //   key: UniqueKey(),
  //   allowMove: false,
  //   allowResize: false,
  //   offset: const Offset(300, 430),
  //   size: const Size(10, 10), 
  //   child: Container(width: 0,height:0, color:Colors.green),
  // );
  // InfiniteCanvasNode constraintOffsetBottomLeft = InfiniteCanvasNode(
  //     key: UniqueKey(),
  //     allowMove: false,
  //     allowResize: false,
  //     offset: const Offset(500, 430),
  //     size: const Size(10, 10), 
  //     child: Container(width: 0,height:0, color:Colors.green),
  // );


  double constraintBrainLeft = 300.0;
  double constraintBrainRight = 500.0;
  double constraintBrainTop = 170.0;
  double constraintBrainBottom = 430.0;
  
  double prevScreenWidth = 800.0;
  double prevScreenHeight = 600.0;
  double screenWidth = 800.0;
  double screenHeight = 600.0;
  bool isResizingFlag = false;

  
  bool axonFromSelected = false;
  bool axonToSelected = false;
  late LocalKey axonFrom;
  late LocalKey axonTo;
  
  double tooltipOverlayX = 10;
  double tooltipOverlayY = 10;
  String tooltipOverlayMessage = "";
  bool isTooltipOverlay = false;
  
  bool isPlayingMenu = false;
  @override
  void initState(){
    super.initState();
    initNativeC();
    mjpegComponent = Mjpeg(
      stream:"http://192.168.1.3:8081",
      preprocessor: ImagePreprocessor(),
      isLive: true,
      fit: BoxFit.fill,
      timeout: const Duration(seconds: 60),                  
    );

    Timer.periodic(const Duration(milliseconds: 70), (timer) { 
      if (isSelected){
        // print("redraw");
        waveRedraw.value = Random().nextInt(10000);
      }
      if (isPlayingMenu){
        for (int i = 10; i < neuronSize ; i++){
          int neuronIndex = i;
          if (neuronCircleBridge[i] == 1){
            protoNeuron.circles[neuronIndex].isSpiking = 1;
            neuronSpikeFlags[neuronIndex].value = Random().nextInt(10000);
          }else{
            try{
              protoNeuron.circles[neuronIndex].isSpiking = -1;
              neuronSpikeFlags[neuronIndex].value = Random().nextInt(10000);
            }catch(err){
              print(err);
            }
          }
        }
      }
    });    
  }

  @override
  Widget build(BuildContext context) {
    // double density = MediaQuery.of(context).devicePixelRatio;
    screenWidth = MediaQuery.of(context).size.width;
    screenHeight = MediaQuery.of(context).size.height;
    // Future.delayed(const Duration(milliseconds: 2000), (){
    //   repositionSensoryNeuron();
    // });

    if (!isInitialized && screenWidth>screenHeight){
      initCanvas();
      isInitialized = true;

      if (!kIsWeb){
        // WaveWidget.positionsBufView = positionsBufView;
      }
      waveWidget = WaveWidget(valueNotifier: waveRedraw,
        chartGain:chartGain,levelMedian: levelMedian,screenHeight: screenHeight,screenWidth: screenWidth);
    }    

    if (prevScreenWidth != screenWidth){
      isResizingFlag = true;
    }
    if (prevScreenHeight != screenHeight){
      isResizingFlag = true;
    }
    if (isResizingFlag){
      controller.getNode(viewportKey)?.offset = Offset(screenWidth, screenHeight);
      int idx = 0;
      double scaleX = screenWidth / prevScreenWidth;
      double scaleY = screenHeight / prevScreenHeight;

      constraintOffsetTopLeft = constraintOffsetTopLeft.scale(scaleX, scaleY);
      constraintOffsetTopRight = constraintOffsetTopRight.scale(scaleX, scaleY);
      constraintOffsetBottomRight = constraintOffsetBottomRight.scale(scaleX, scaleY);
      constraintOffsetBottomLeft = constraintOffsetBottomLeft.scale(scaleX, scaleY);

      constraintBrainLeft = constraintOffsetTopLeft.dx;
      constraintBrainRight = constraintOffsetTopRight.dx;
      constraintBrainTop = constraintOffsetTopLeft.dy;
      constraintBrainBottom = constraintOffsetBottomLeft.dy;

      // print("constraintBrainLeft");
      // print(controller.scale);
      // print(constraintOffsetTopLeft);
      // print(constraintBrainLeft);
      // print(constraintBrainTop);

      for (var element in controller.nodes) { 
        if (idx>0){
          element.offset = element.offset.scale( scaleX , scaleY );

          // constraintBrainLeft *= scaleX;
          // constraintBrainRight *= scaleX;
          // constraintBrainTop *= scaleY;
          // constraintBrainBottom *= scaleY;
          
          // print("screen dimension");
          // print(screenWidth);
          // print(screenHeight);
          // print("constraintBrainLeft");
          // print(constraintBrainLeft);
          // print(constraintBrainRight);
          // print(constraintBrainTop);
          // print(constraintBrainBottom);

          // Offset prevOffset = element.offset;
          // element.offset = element.offset.scale( scaleX , scaleY );
          // constraintBrainLeft += (element.offset.dx - prevOffset.dx);
          // constraintBrainRight += (element.offset.dx - prevOffset.dx);
          // constraintBrainTop += (element.offset.dy - prevOffset.dy);
          // constraintBrainBottom += (element.offset.dy - prevOffset.dy);
        }
        idx++;
      }
      isResizingFlag = false;
      // print("isResizingFlag");
      // print(isResizingFlag);

      prevScreenWidth = screenWidth;
      prevScreenHeight = screenHeight;

    }

    List<Widget> widgets = [];
    if (isPlayingMenu){

      for (int i = 10; i < neuronSize ;i++){
        SingleNeuron neuron = protoNeuron.circles[i];
        widgets.add(
          Positioned(
            top:neuron.centerPos.dy,
            left:neuron.centerPos.dx,
            child: SizedBox(
              key:neuronCircleKeys[i],
              child: ValueListenableBuilder(
                valueListenable: neuronSpikeFlags[i],
                builder: ((context, value, child) {
                  if (protoNeuron.circles[i].isSpiking == -1){
                    return neuronInactiveCircles[i];
                  }else{
                    return neuronActiveCircles[i];
                  }
                }),
              ),
            ),
          )
        );        

        // widgets.add(
        //   Positioned(
        //     top:neuron.centerPos.dy-10,
        //     left:neuron.centerPos.dx-10,
        //     child: SizedBox(
        //       key:neuronCircleKeys[i],
        //       child: neuronCircleBridge[i] == 0? neuronInactiveCircles[i]:neuronActiveCircles[i],
        //     ),
        //   )
        // );
      }
    }
    
    return Scaffold(
      // appBar: AppBar(
      //   title: Text(widget.title),
      // ),
      floatingActionButton: FloatingActionButton(
        onPressed: (){
          isEmergencyPause = !isEmergencyPause;
          if (!isEmergencyPause){
            rightToolbarCallback({"menuIdx": 8 });
            Future.delayed(const Duration(milliseconds: 100), (){
              menuIdx = 0;
              setState(() {
                
              });
            });
          }else{
            rightToolbarCallback({"menuIdx": 8 });
          }

          setState(() {
            
          });
        },
        child: 
          !isEmergencyPause?
            const Icon(Icons.play_arrow)
            :
            const Icon(Icons.pause)
      ),
      body: Stack(
        children: [
          Positioned(
            left:0,
            top:0,
            child: Container(
              color: Colors.white,
              width:screenWidth, 
              height:screenHeight,
              child: prepareWidget(
                InfiniteCanvas(
                  backgroundBuilder: (ctx, r){ 
                  // print("MediaQuery.of(context).screenWidth");
                  // print(screenWidth);
                  // print(screenHeight);
                
                
                    return Container(
                      color:Colors.white,
                      width:screenWidth * 2, 
                      height:screenHeight,
                      child: Image.asset(
                        width: screenWidth,
                        height: screenHeight,
                        // scale: screenWidth/800,
                        fit:BoxFit.contain,
                        // scale: density,
                        "assets/bg/bg1.0x.jpeg"
                      ),
                    );
                  },
                  drawVisibleOnly: true,
                  canAddEdges: true,
                  menuVisible: false,
                  controller: controller,
                ),
              ),
            ),
          ),
          Positioned(
            right:10,
            top:40,
            child: RightToolbar(key: GlobalKey(), menuIdx: menuIdx, callback: rightToolbarCallback),
          ),

          Positioned(
            right:90,
            bottom:20,
            child: Card(
              surfaceTintColor: Colors.white,
              // surfaceTintColor: Colors.transparent,
              shadowColor: Colors.white,
              // color: Colors.transparent,
              child: Container(
                color: Colors.transparent,
                width:128,
                child: Row(
                  children: [
                    MeTooltip(
                      message: "Zoom Out",
                      preferOri: PreferOrientation.up,
                      child: ElevatedButton(
                        onPressed: (){
                          controller.zoomOut();
                        }, 
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          surfaceTintColor: Colors.white,
                          shadowColor: Colors.transparent
                          // shadowColor: Colors.white,
                        ),
                        child: const Text("-", style:TextStyle(fontSize:25,color: Color(0xFF4e4e4e))),
                      ),
                    ),
                    MeTooltip(
                      message: "Zoom In",
                      preferOri: PreferOrientation.up,
                      child: ElevatedButton(
                        onPressed: (){
                          controller.zoomIn();
                        }, 
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          surfaceTintColor: Colors.white,
                          shadowColor: Colors.transparent

                          // shadowColor: Colors.white,
                        ),
                        child: const Text("+", style:TextStyle(fontSize:25,color: Color(0xFF4e4e4e))),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
          // Text(isPlayingMenu.toString()),

          if (isPlayingMenu)...[
            Positioned(
              left:50,
              top:0,
              // child:Container(
              //   width:100,height:200,
              //   child: Mjpeg(
              //     stream: "http://192.168.4.1:81/stream",
              //     isLive: true,
              //   ),
              // )
              child: ClipRect(
                clipper: EyeClipper(isLeft:true, width: screenWidth, height: screenHeight),
                child: mjpegComponent,
              ),
            ),
            Positioned(
              right:80,
              top:0,
              child: StreamBuilder<Uint8List>(
                stream: mainBloc.imageStream,
                builder: (context, snapshot) {
                  // print(snapshot.data);
                  if (snapshot.data == null) return Container();
                  return ClipRect(
                    clipper: EyeClipper(isLeft:false,width: screenWidth, height:screenHeight),
                    child: Image.memory(
                      snapshot.data!,
                      gaplessPlayback: true,
                    ),
                  );
                }
              ),
            ),
          ],

          if (isPlayingMenu && isSelected)...[

            Positioned(
              bottom: 0,
              left: 0,
              child:Container(
                margin: const EdgeInsets.all(10.0),
                decoration: BoxDecoration(border: Border.all(color:Colors.black)),

                // color:Colors.red,
                height:screenHeight/2-150,
                width: screenWidth-20,
                // child: isSelected?waveWidget : const SizedBox(),
                child: waveWidget,
              ),
            ),

          ],

          ValueListenableBuilder(
            valueListenable: tooltipValueChange, 
            builder: ((context, value, child) {
              return 
              !isTooltipOverlay? 
              Container():
              
              Positioned(
                left : tooltipOverlayX-20,
                top : tooltipOverlayY-50,
                child : Container(
                  color: Colors.black,
                  padding: const EdgeInsets.all(5),
                  child:Text(tooltipOverlayMessage, style : const TextStyle(color: Colors.white))
                ),
              );
            })
          )
        ]..addAll(widgets),
      ),      
      // body: Center(
      //   child: Column(
      //     mainAxisAlignment: MainAxisAlignment.center,
      //     children: <Widget>[
      //       Mjpeg(
      //         isLive:true,
      //         stream: 'http://192.168.4.1:81/stream',
      //       ),
      //       // const Text(
      //       //   'You have pushed the button this many times:',
      //       // ),
      //       CircularProgressIndicator(),
      //       // Text(
      //       //   '$_counter',
      //       //   style: Theme.of(context).textTheme.headlineMedium,
      //       // ),
      //     ],
      //   ),
      // ),
      // floatingActionButton: FloatingActionButton(
      //   // onPressed: startWebSocket,
      //   onPressed: (){
      //     controller.zoomReset();
      //   },
      //   tooltip: 'Increment',
      //   child: const Icon(Icons.add),
      // ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
  
  void allowMoveNodes() {
    int n = controller.nodes.length;
    for (int i = 0; i < n; i++){
      controller.nodes[i].allowMove = true;
    }
  }  
  void disallowMoveNodes() {
    int n = controller.nodes.length;
    for (int i = 0; i < n; i++){
      controller.nodes[i].allowMove = false;
    }
  }
  
  void runSimulation() {
    neuronSize = controller.nodes.length;
    initNativeC();    
    print("neuronSize");
    print(neuronSize);
    List<Offset> pos = [];
    
    // Map<int,String> nodeKey = {};
    Map<String, int> nodeKey = {};
    int idx = 0;
    for (InfiniteCanvasNode node in controller.nodes){
      // if (idx>=10){
        pos.add(node.offset);
        nodeKey[node.key.toString()] = idx;
        // nodeKey[idx] = node.key.toString();
      // }
      idx++;
    }
    print("nodeKey");
    print(nodeKey);
    
    List<List<double>> connectomeMatrix = List<List<double>>.generate(neuronSize, (index) => List<double>.generate(neuronSize, (index)=> 0.0, growable: false ), growable:false);
    controller.edges.forEach((edge) { 
      print("edge.from");
      print(edge.from);
      print(edge.to);
      int fromIdx = nodeKey[ edge.from.toString() ]!;
      int toIdx = nodeKey[ edge.to.toString() ]!;
      connectomeMatrix[fromIdx][toIdx] = Random().nextDouble() * 3;
    });
    //  List<List<double>> twoDList = List<List<>>.generate(row, (i) => List<dynamic>.generate(col, (index) => null, growable: false), growable: false);
    // print(nodeKey);
    // ProtoNeuron.nodes = controller.nodes;
    // ProtoNeuron.edges = controller.edges;
    protoNeuron = ProtoNeuron(notifier:redrawNeuronLine, neuronSize:neuronSize, screenWidth:screenWidth, screenHeight:screenHeight, 
      aBufView:aBufView,bBufView:bBufView,cBufView:cBufView,dBufView:dBufView,iBufView:iBufView,wBufView:wBufView, connectomeBufView:connectomeBufView);
    protoNeuron.generateCircle(neuronSize, pos);
    protoNeuron.setConnectome(neuronSize, connectomeMatrix);
    runNativeC();
    
  }
  
  prepareWidget(InfiniteCanvas canvas) {
    if (Platform.isAndroid || Platform.isIOS){
      return XGestureDetector(
        onMoveUpdate: (MoveEvent event){
          print("onMoveUpdate Press Move");
          return;
          Offset offset = event.delta;
          if (offset.dx > 0){
            // controller.panRight();
            Offset offset = Offset(2, 0);
            controller.pan(offset);
          }else
          if (offset.dx < 0){
            // controller.panLeft();
            Offset offset = Offset(-2, 0);
            controller.pan(offset);

          }
          if (offset.dy > 0){
            // controller.panDown();
            Offset offset = Offset(0, 2);
            controller.pan(offset);

          }else
          if (offset.dy < 0){
            Offset offset = Offset(0, -2);
            controller.pan(offset);
          }

        },
        onScaleUpdate: (ScaleEvent event){
          print("prepare scaling");
          var temp = controller.scale * event.scale;
          print(controller.minScale);
          print(controller.maxScale);
          print(controller.scale);
          if (temp < controller.maxScale && temp > controller.minScale){
            if (temp > controller.scale){
              controller.zoom(1.003);
            }else{
              controller.zoom(0.997);

            }
          }
        },
        child: canvas,
      );
    }else{
      return canvas;
    }

  }  


  rightToolbarCallback(map) {
    print("map");
    print(map);
    menuIdx = map["menuIdx"];
    isCreatePoint = false;
    if (menuIdx == 0){
      allowMoveNodes();
    }else{
      disallowMoveNodes();
    }
    if (menuIdx == 7){
      // print( json.encode(controller.nodes) );
      // print( json.encode(controller.edges) );
    }else
    if (menuIdx == 8){
      isPlayingMenu = !isPlayingMenu;
      isSelected = false;
      print("MENU IDX 8");
      controller.mouseDown = false;
      controller.setCanvasMove(false);

      controller.zoomReset();
      if (isPlayingMenu){
        controller.deselectAll();
        runSimulation();
      }else{
        if (kIsWeb){
          // js.context.callMethod("stopThreadProcess", [0]);
        }else{
          nativec.stopThreadProcess(0);
        }
        controller.deselectAll();
        controller.setCanvasMove(true);

      }
      setState(() {
        
      });
    }else
    if (menuIdx == 6){
      print("home");
      Navigator.pop(context);
    }
    // add nodes into canvas
  }
  
  void repositionSensoryNeuron() {
    // double screenHeight = MediaQuery.of(context).size.height/2;
    double ratio = screenHeight/600;
    print("screenDimension");
    print(screenWidth);
    print(screenHeight);
    print(ratio);
    print(MediaQuery.of(context).devicePixelRatio);
    Offset middleScreenOffset = Offset(MediaQuery.of(context).size.width/2-10, 150);

    // Offset offset = middleScreenOffset.scale(0.5, 0.5);
    // Offset offset = middleScreenOffset.scale(ratio, ratio);
    nodeDistanceSensor.offset = middleScreenOffset;

    Offset diff = Offset(screenHeight/8, 0);
    Offset offset = middleScreenOffset - diff;
    nodeLeftEyeSensor.offset = offset;

    Offset offsetMic = Offset(MediaQuery.of(context).size.width/2-12 - 1.75 * screenHeight/8, nodeMicrophoneSensor.offset.dy);
    nodeMicrophoneSensor.offset = offsetMic;

    Offset offsetLMF = Offset(MediaQuery.of(context).size.width/2-12 - 2 * screenHeight/8, nodeLeftMotorForwardSensor.offset.dy);
    nodeLeftMotorForwardSensor.offset = offsetLMF;

    Offset offsetLMB = Offset(MediaQuery.of(context).size.width/2-12 - 2 * screenHeight/8, nodeLeftMotorBackwardSensor.offset.dy);
    nodeLeftMotorBackwardSensor.offset = offsetLMB;


    Offset diffRight = Offset(screenHeight/8, 0);
    Offset offsetRight = middleScreenOffset + diffRight;
    nodeRightEyeSensor.offset = offsetRight;

    Offset offsetSpeaker = Offset(MediaQuery.of(context).size.width/2-12 + 1.725 * screenHeight/8, nodeSpeakerSensor.offset.dy);
    nodeSpeakerSensor.offset = offsetSpeaker;

    Offset offsetRMF = Offset(MediaQuery.of(context).size.width/2-12 + 2 * screenHeight/8, nodeRightMotorForwardSensor.offset.dy);
    nodeRightMotorForwardSensor.offset = offsetRMF;

    Offset offsetRMB = Offset(MediaQuery.of(context).size.width/2-12 + 2 * screenHeight/8, nodeRightMotorBackwardSensor.offset.dy);
    nodeRightMotorBackwardSensor.offset = offsetRMB;

    constraintOffsetTopLeft  = Offset(nodeMicrophoneSensor.offset.dx + 20 , middleScreenOffset.dy + 30);
    constraintOffsetTopRight = Offset(nodeSpeakerSensor.offset.dx -20, middleScreenOffset.dy + 30);
    constraintOffsetBottomLeft  = Offset(nodeMicrophoneSensor.offset.dx + 20 , nodeRightMotorBackwardSensor.offset.dy);
    constraintOffsetBottomRight = Offset(nodeSpeakerSensor.offset.dx -20, nodeRightMotorBackwardSensor.offset.dy);

    constraintBrainLeft = constraintOffsetTopLeft.dx;
    constraintBrainRight = constraintOffsetTopRight.dx;
    constraintBrainTop = constraintOffsetTopLeft.dy;
    constraintBrainBottom = constraintOffsetBottomLeft.dy;

    // Offset diffLMB = Offset(2 * screenHeight/10, 0);
    // Offset offsetLMB = Offset(MediaQuery.of(context).size.width/2-10, nodeLeftMotorBackwardSensor.offset.dy); - (diffLMB);
    // nodeLeftMotorBackwardSensor.offset = offsetLMB;

  }
  
  void initCanvas() {
    final rectangleNode = InfiniteCanvasNode(
      value: 10,
      key: UniqueKey(),
      // label: 'Rectangle',
      allowResize: false,
      
      offset: const Offset(300, 300),
      size: const Size(20, 20),
      child: Builder(
        builder: (context) {
          return CustomPaint(
            isComplex: true,
            willChange: true,
            painter: InlineCustomPainter(
              brush: Paint(),
              builder: (brush, canvas, rect) {
                // Draw rect
                brush.color = Theme.of(context).colorScheme.secondary;
                // canvas.drawRect(rect, brush);
                canvas.drawCircle(rect.center, rect.width / 2, brush);                
              },
            ),
          );
        },
      ),
    );
    final triangleNode = InfiniteCanvasNode(
      value: 11,
      key: UniqueKey(),
      // label: 'Triangle',
      offset: const Offset(500, 170),
      size: const Size(20, 20),
      child: Builder(
        builder: (context) {
          return CustomPaint(
            painter: InlineCustomPainter(
              brush: Paint(),
              builder: (brush, canvas, rect) {
                // Draw triangle
                brush.color = Theme.of(context).colorScheme.secondaryContainer;
                canvas.drawCircle(rect.center, rect.width / 2, brush);                
                // final path = Path();
                // path.addPolygon([
                //   rect.topCenter,
                //   rect.bottomLeft,
                //   rect.bottomRight,
                // ], true);
                // canvas.drawPath(path, brush);
              },
            ),
          );
        },
      ),
    );
    final circleNode = InfiniteCanvasNode(
      value: 12,
      key: UniqueKey(),
      // label: 'Circle',
      offset: const Offset(320, 430),
      size: const Size(20, 20),
      child: Builder(
        builder: (context) {
          return CustomPaint(
            painter: InlineCustomPainter(
              brush: Paint(),
              builder: (brush, canvas, rect) {
                // Draw circle
                brush.color = Theme.of(context).colorScheme.tertiary;
                canvas.drawCircle(rect.center, rect.width / 2, brush);
              },
            ),
          );
        },
      ),
    );

    if (Platform.isAndroid || Platform.isIOS){
      repositionSensoryNeuron();
    }
    var nodes = [
      viewPortNode,

      // constraintOffsetTopLeft,
      // constraintOffsetTopRight,
      // constraintOffsetBottomRight,
      // constraintOffsetBottomLeft,

      nodeDistanceSensor,
      nodeLeftEyeSensor,
      nodeRightEyeSensor,

      nodeLeftMotorForwardSensor,
      nodeRightMotorForwardSensor,
      nodeLeftMotorBackwardSensor,
      nodeRightMotorBackwardSensor,

      nodeMicrophoneSensor,
      nodeSpeakerSensor,

      rectangleNode,
      triangleNode,
      circleNode,


    ];    

    listDefaultSensorLabel = [
      "Distance Sensor",
      "Left Eye",
      "Right Eye",

      "Microphone",
      "Speaker",

      "Left Motor (Forward)",
      "Right Motor (Forward)",
      "Left Motor (Backward)",
      "Right Motor (Backward)",
    ];
    listDefaultSensor = [
      nodeDistanceSensor,
      nodeLeftEyeSensor,
      nodeRightEyeSensor,

      nodeMicrophoneSensor,
      nodeSpeakerSensor,

      nodeLeftMotorForwardSensor,
      nodeRightMotorForwardSensor,
      nodeLeftMotorBackwardSensor,
      nodeRightMotorBackwardSensor,
    ];
    controller = InfiniteCanvasController(nodes: nodes, edges: [
      InfiniteCanvasEdge(
        from: rectangleNode.key,
        to: triangleNode.key,
        // label: '4 -> 3',
      ),
      InfiniteCanvasEdge(
        from: rectangleNode.key,
        to: circleNode.key,
        // label: '[] -> ()',
      ),
      InfiniteCanvasEdge(
        from: triangleNode.key,
        to: circleNode.key,
      ),
    ]);
    controller.maxScale = 1.5;
    controller.scale = 1;
    controller.minScale = 0.75;
    controller.addListener(() {

      if (controller.mouseDown){

        if (menuIdx == 0 && controller.hasSelection){
          var selected = controller.selection[0];
          var pos = selected.offset;
          int defaultSensorLength = listDefaultSensor.length;
          bool foundSelected = false;
          for (int i = 0 ; i < defaultSensorLength; i++){
            if (selected == listDefaultSensor[i]){
              tooltipOverlayX = selected.offset.dx;
              tooltipOverlayY = selected.offset.dy;
              tooltipOverlayMessage = listDefaultSensorLabel[i];
              isTooltipOverlay = true;
              foundSelected = true;
            }
          }
          // print("foundSelected");
          // print(foundSelected);
          if (foundSelected) {
            tooltipValueChange.value = (Random().nextInt(10000));
            // setState((){});
            Future.delayed(const Duration(milliseconds: 1000),(){
              isTooltipOverlay = false;
              tooltipValueChange.value = (Random().nextInt(10000));

            });
            selected.update( offset:pos);
            return;
          }

          if (selected.offset.dx < constraintBrainLeft){
            var newOffset = Offset(constraintBrainLeft, pos.dy);
            selected.update(size:selected.size, offset:newOffset, label:"");
          }else
          if (selected.offset.dx > constraintBrainRight){
            var newOffset = Offset(constraintBrainRight, pos.dy);
            selected.update(size:selected.size, offset:newOffset, label:"");
          }

          pos = selected.offset;

          if (selected.offset.dy < constraintBrainTop){
            var newOffset = Offset(pos.dx, constraintBrainTop);
            selected.update(size:selected.size, offset:newOffset, label:"");
          }else
          if (selected.offset.dy > constraintBrainBottom){
            var newOffset = Offset(pos.dx, constraintBrainBottom);
            selected.update(size:selected.size, offset:newOffset, label:"");
          }
        }else
        if ( menuIdx == 1 && !isCreatePoint && !controller.hasSelection){
          isCreatePoint = true;
          double mouseX = controller.mousePosition.dx;
          double mouseY = controller.mousePosition.dy;
          if (mouseX < constraintBrainLeft || mouseX > constraintBrainRight){
            return;
          }
          if (mouseY < constraintBrainTop || mouseY > constraintBrainBottom){
            return;
          }
          neuronsKey.add(UniqueKey());
          controller.add(
            InfiniteCanvasNode(
              key: neuronsKey[ neuronsKey.length - 1 ],
              value: neuronsKey.length-1,
              allowMove: false,
              allowResize: false,
              offset: Offset(mouseX, mouseY),
              size: const Size(20, 20), 
              child: CustomPaint(
                isComplex: true,
                willChange: true,
                painter: InlineCustomPainter(
                  brush: Paint(),
                  builder: (brush, canvas, rect) {
                    brush.color = Theme.of(context).colorScheme.secondary;
                    canvas.drawCircle(rect.center, rect.width / 2, brush);                
                  },
                ),
              ),
              // child: Container(width: 0,height:0, color:Colors.green),
            )
          );
          Future.delayed(const Duration(milliseconds: 100),(){
            controller.deselect(neuronsKey[ neuronsKey.length - 1 ]);
          });

        }else
        if ( menuIdx == 2 && !isCreatePoint && controller.hasSelection){
          print('design brain start');
          print("------------------");
          print(controller.hasSelection);
          print(axonFromSelected);
          print(axonToSelected);
          isCreatePoint = true;
          if (!axonFromSelected && controller.hasSelection){
            axonFromSelected = true;
            axonFrom = controller.selection[0].key;
            Future.delayed(const Duration(milliseconds: 100),(){
              controller.deselect(axonFrom);
            });
            
            // isCreatePoint = false;
          }else
          if (!axonToSelected && controller.hasSelection){
            axonFromSelected = true;
            axonTo = controller.selection[0].key;
            
            if (axonFrom == axonTo){
              print('axon from = to');
              print(axonFrom);
              print(axonTo);

            }else{
              // if there is already the same edge from one node to another node, don't add
              bool isAddUniqueEdge = true;

              // int totalEdges = controller.edges.length;
              // for (int i = 0; i < totalEdges; i++){
              //   if (controller.edges[i].from == axonFrom.key && controller.edges[i].to == axonTo.key){
              //     isAddUniqueEdge = false;
              //   }
              // }
              print('axon to selected');
              if (isAddUniqueEdge){
              print('axon unique to selected');

                controller.edges.add(InfiniteCanvasEdge(from: axonFrom, to: axonTo));
              }
            }

            axonFromSelected = false;
            axonToSelected = false;
            Future.delayed(const Duration(milliseconds: 100),(){
              // controller.deselect(axonFrom);
              controller.deselect(axonTo);
            });
            
            // isCreatePoint = false;
          }
          print('design brain end');
          print("------------------");
          print(controller.hasSelection);
          print(axonFromSelected);
          print(axonToSelected);
          
        }else
        if (menuIdx == 7 && !controller.hasSelection){
          print("Zoom Reset");
          controller.zoomReset();
          isSelected = false;
          nativec.changeIdxSelected(-1);
          setState(() {
            
          });
        }else
        if (menuIdx == 7 && controller.hasSelection){
          var selected = controller.selection[0];
          print("selected.value");
          print(selected.value);
          isSelected = true;
          nativec.changeIdxSelected(selected.value);
          redrawNeuronLine.value = Random().nextInt(100);
          setState(() {
            
          });

        }


      }else{
        isCreatePoint = false;
        // isTooltipOverlay = false;
        // setState((){});
      }

     });

  }
}

class EyeClipper extends CustomClipper<Rect>{
  EyeClipper({required this.isLeft, required this.width, required this.height});
  final bool isLeft;
  final double width;
  final double height;
  @override
  Rect getClip(Size size) {
    if (isLeft){
      return const Rect.fromLTWH(0, 30, 160, 120);
    }else{
      return const Rect.fromLTWH(50, 30, 160, 120);
    }
  }

  @override
  bool shouldReclip(covariant CustomClipper<Rect> oldClipper) {
    return false;
  }
}


class InlineCustomPainter extends CustomPainter {
  const InlineCustomPainter({
    required this.brush,
    required this.builder,
    this.isAntiAlias = true,
  });
  final Paint brush;
  final bool isAntiAlias;
  final void Function(Paint paint, Canvas canvas, Rect rect) builder;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    brush.isAntiAlias = isAntiAlias;
    canvas.save();
    builder(brush, canvas, rect);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}



class ImagePreprocessor extends MjpegPreprocessor{
  
  @override
  List<int>? process(List<int> frame) {
    // print(frame);
    mainBloc.drawImageNow( Uint8List.fromList(frame) );
    return frame;
  }
}