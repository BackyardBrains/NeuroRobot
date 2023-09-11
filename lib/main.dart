import 'dart:async';
import 'dart:ffi' as ffi;
import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';
import 'package:another_xlider/another_xlider.dart';
import 'package:another_xlider/models/handler.dart';
import 'package:another_xlider/models/tooltip/tooltip.dart';
import 'package:async/async.dart';
import 'package:auto_orientation/auto_orientation.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_audio_waveforms/flutter_audio_waveforms.dart';
import 'package:mic_stream/mic_stream.dart';
// import 'package:nativec/nativec.dart';

import 'package:flutter/material.dart';
import 'package:nativec/allocation.dart';
import 'package:nativec/nativec.dart';
import 'package:neurorobot/bloc/bloc.dart';
import 'package:neurorobot/utils/Debouncers.dart';
import 'package:neurorobot/utils/NeuronCircle.dart';
import 'package:neurorobot/utils/ProtoCircle.dart';
import 'package:winaudio/winaudio.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isMacOS || Platform.isWindows || Platform.isLinux){
    await windowManager.ensureInitialized();

    WindowOptions windowOptions = const WindowOptions(
      minimumSize: Size(800, 600),
      size: Size(1200, 800),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.hidden,
    );
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });

  }else{
    AutoOrientation.landscapeLeftMode();
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Neuro Robot',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'NeuroRobot - Prototype 2'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

void sampleBufferingEntryPoint(List<dynamic> values) {
  final iReceivePort = ReceivePort();
  SendPort sendPort = values[0];
  iReceivePort.listen((Object? message) async {});
  // sendPort.send([buffers, arrHeads[0], eventPositionResultInt]);
}

class _MyHomePageState extends State<MyHomePage> {
  Debouncer debouncerScroll = Debouncer(milliseconds: 300);  
  StreamSubscription<dynamic>? winAudioSubscription;
  late Nativec nativec;
  static int neuronSize = 5;
  static ffi.Pointer<ffi.Uint16> positionsBuf = allocate<ffi.Uint16>(
      count: neuronSize, sizeOfType: ffi.sizeOf<ffi.Uint16>());
  late Uint16List positionsBufView  = Uint16List(0);

  static ffi.Pointer<ffi.Double> aBuf = allocate<ffi.Double>(
      count: neuronSize, sizeOfType: ffi.sizeOf<ffi.Double>());
  late Float64List aBufView  = Float64List(0);

  static ffi.Pointer<ffi.Double> bBuf = allocate<ffi.Double>(
      count: neuronSize, sizeOfType: ffi.sizeOf<ffi.Double>());
  late Float64List bBufView  = Float64List(0);

  
  static ffi.Pointer<ffi.Int16> cBuf = allocate<ffi.Int16>(
      count: neuronSize, sizeOfType: ffi.sizeOf<ffi.Int16>());
  late Int16List cBufView  = Int16List(0);
  
  static ffi.Pointer<ffi.Int16> dBuf = allocate<ffi.Int16>(
      count: neuronSize, sizeOfType: ffi.sizeOf<ffi.Int16>());
  late Int16List dBufView  = Int16List(0);

  static ffi.Pointer<ffi.Int16> iBuf = allocate<ffi.Int16>(
      count: neuronSize, sizeOfType: ffi.sizeOf<ffi.Int16>());
  late Int16List iBufView  = Int16List(0);
  
  static ffi.Pointer<ffi.Double> wBuf = allocate<ffi.Double>(
      count: neuronSize, sizeOfType: ffi.sizeOf<ffi.Double>());
  late Float64List wBufView  = Float64List(0);


  static ffi.Pointer<ffi.Double> connectomeBuf = allocate<ffi.Double>(
      count: neuronSize * neuronSize, sizeOfType: ffi.sizeOf<ffi.Double>());
  late Float64List connectomeBufView  = Float64List(0);

  
  List<double> varA = List<double>.filled(neuronSize, 0.02);
  List<double> varB = List<double>.filled(neuronSize, 0.18);
  List<int> varC = List<int>.filled(neuronSize, -65);
  List<int> varD = List<int>.filled(neuronSize, 2);
  List<int> varI = List<int>.filled(neuronSize, 5);
  List<double> varW = List<double>.filled(neuronSize, 2.0);
  
  List<bool> firingFlags = List<bool>.filled(neuronSize, false);
  ValueNotifier<int> spikingFlags = ValueNotifier(0);

  // Float64List canvasBufferBytes = Float64List(6000);
  
  int isPlaying = 1;
  double levelMedian = 20;
  double chartGain = 1;

  bool isInitialized = false;
  
  late ProtoCircle protoCircle;
  ValueNotifier<int> redrawNeuronLine = ValueNotifier(0);
  
  TextEditingController neuronInputController = TextEditingController(text:"25");

  void resetNeuronParameters(){
    free(positionsBuf);
    free(aBuf);
    free(bBuf);
    free(cBuf);
    free(dBuf);
    free(iBuf);
    free(wBuf);
    free(connectomeBuf);

    const a = 0.02;
    const b = 0.18;
    const c = -65;
    const d = 2;
    const i = 5;
    const w = 2.0;   
    
    positionsBuf = allocate<ffi.Uint16>(count: neuronSize, sizeOfType: ffi.sizeOf<ffi.Uint16>());
    aBuf = allocate<ffi.Double>(count: neuronSize, sizeOfType: ffi.sizeOf<ffi.Double>());
    bBuf = allocate<ffi.Double>(count: neuronSize, sizeOfType: ffi.sizeOf<ffi.Double>());
    cBuf = allocate<ffi.Int16>(count: neuronSize, sizeOfType: ffi.sizeOf<ffi.Int16>());
    dBuf = allocate<ffi.Int16>(count: neuronSize, sizeOfType: ffi.sizeOf<ffi.Int16>());
    iBuf = allocate<ffi.Int16>(count: neuronSize, sizeOfType: ffi.sizeOf<ffi.Int16>());
    wBuf = allocate<ffi.Double>(count: neuronSize, sizeOfType: ffi.sizeOf<ffi.Double>());   
    connectomeBuf = allocate<ffi.Double>(count: neuronSize * neuronSize, sizeOfType: ffi.sizeOf<ffi.Double>());

    aBufView = aBuf.asTypedList(neuronSize);
    bBufView = bBuf.asTypedList(neuronSize);
    cBufView = cBuf.asTypedList(neuronSize);
    dBufView = dBuf.asTypedList(neuronSize);
    iBufView = iBuf.asTypedList(neuronSize);
    wBufView = wBuf.asTypedList(neuronSize);
    positionsBufView = positionsBuf.asTypedList(neuronSize);
    connectomeBufView = connectomeBuf.asTypedList(neuronSize * neuronSize);

    aBufView.fillRange(0, neuronSize, a);
    bBufView.fillRange(0, neuronSize, b);
    cBufView.fillRange(0, neuronSize, c);
    dBufView.fillRange(0, neuronSize, d);
    iBufView.fillRange(0, neuronSize, i);
    wBufView.fillRange(0, neuronSize, w);
    positionsBufView.fillRange(0, neuronSize, 0);
    connectomeBufView.fillRange(0, neuronSize * neuronSize, 0);

    
    varA = List<double>.filled(neuronSize, 0.02);
    varB = List<double>.filled(neuronSize, 0.18);
    varC = List<int>.filled(neuronSize, -65);
    varD = List<int>.filled(neuronSize, 2);
    varI = List<int>.filled(neuronSize, 5);
    varW = List<double>.filled(neuronSize, 2.0);
    firingFlags = List<bool>.filled(neuronSize, false);    
    
  }
  void initNativeC(){
    // for (int i = 0;i<3000;i++){
    //   canvasBufferBytes[i] = Random().nextDouble() * 100;
    // }
    // canvasBufferBytes.fillRange(0, 3000,-2);
    nativec = Nativec();
    const a = 0.02;
    const b = 0.18;
    const c = -65;
    const d = 2;
    const i = 5;
    const w = 2.0;
    
    // int neuronSizeType = neuronSize;
    aBufView = aBuf.asTypedList(neuronSize);
    bBufView = bBuf.asTypedList(neuronSize);
    cBufView = cBuf.asTypedList(neuronSize);
    dBufView = dBuf.asTypedList(neuronSize);
    iBufView = iBuf.asTypedList(neuronSize);
    wBufView = wBuf.asTypedList(neuronSize);
    positionsBufView = positionsBuf.asTypedList(neuronSize);
    connectomeBufView = connectomeBuf.asTypedList(neuronSize * neuronSize);

    aBufView.fillRange(0, neuronSize, a);
    bBufView.fillRange(0, neuronSize, b);
    cBufView.fillRange(0, neuronSize, c);
    dBufView.fillRange(0, neuronSize, d);
    iBufView.fillRange(0, neuronSize, i);
    wBufView.fillRange(0, neuronSize, w);
    positionsBufView.fillRange(0, neuronSize, 0);
    connectomeBufView.fillRange(0, neuronSize * neuronSize, 0);

    const level = 1;
    const envelopeSize = 200;
    const bufferSize = 2000;
    nativec.changeNeuronSimulatorProcess(aBuf, bBuf, cBuf, dBuf, iBuf, wBuf, positionsBuf, connectomeBuf, level, neuronSize, envelopeSize, bufferSize, 1);
    Nativec.cPublicationStream!.listen((message) {
      if (message.indexOf("S|")>-1){
        List<String> arr = message.split("|");
        bool needRedraw = false;
        for (int i = 1; i < arr.length ; i++){
          int neuronIndex = i - 1;
          if (arr[i] == '1'){
            if (protoCircle.circles[neuronIndex].isSpiking != 1){
              needRedraw = true;
            }
            protoCircle.circles[neuronIndex].isSpiking = 1;
          }else{
            if (protoCircle.circles[neuronIndex].isSpiking != 0){
              needRedraw = true;
            }
            protoCircle.circles[neuronIndex].isSpiking = -1;
          }
        }
        // print(needRedraw);
        // if (needRedraw) {
          redrawNeuronLine.value=Random().nextInt(1000);
        // }

        // int firingFlags=0;
        // List<int> firingFlags= [0,0];
        // if (arr[1]=="1" && arr[2]=="1"){
        //   // firingFlags[0] = 1;
        //   // firingFlags[1] = 1;
        //   firingFlags = 3000 + Random().nextInt(1000);
        //   spikingFlags.value = firingFlags;
        //   // mainBloc.refreshNow(firingFlags);
        // }else
        // if (arr[1]=="1" ){
        //   // firingFlags[0] = 1;
        //   // firingFlags[1] = 0;
        //   firingFlags = 1000 + Random().nextInt(1000);
        //   spikingFlags.value = firingFlags;
        //   // mainBloc.refreshNow(firingFlags);
        // }else
        // if (arr[2]=="1"){
        //   // firingFlags[0] = 0;
        //   // firingFlags[1] = 1;
        //   firingFlags = 2000 + Random().nextInt(1000);
        //   spikingFlags.value = firingFlags;
        //   // mainBloc.refreshNow(firingFlags);
        // }else{
        //   // firingFlags[0] = 0;
        //   // firingFlags[1] = 0;
        //   firingFlags = 0 + Random().nextInt(1000);
        //   spikingFlags.value = firingFlags;
        //   // mainBloc.refreshNow(firingFlags);
        // }

      }else{
        print("PRINT C++ MESSAGE222 : ");
        print(message);

      }
    });    
  }

  bool canvasDraw(params){

    return true;
  }

  void initState(){
    super.initState();
    initNativeC();


    Timer.periodic(Duration(milliseconds: 50), (timer) { 
      // print(Nativec.canvasBufferBytes1.sublist(0,5));
      setState(()=>{

      });
    });
  }

  void _incrementCounter() async {
    print("Nativec.canvasBufferBytes1");
    print(Nativec.canvasBufferBytes1);
  }

  List<Widget> sideWidget(int idx, double screenWidth){
    double labelSliderWidth= 40.0;
    return [
      const Text("a: speed of recovery"),
      Row(
        children: [
          if (idx==1)...{
            SizedBox(
              width:labelSliderWidth,
              child:Text(varA[idx].toStringAsFixed(2)),
            ),
            
          },
          SizedBox(
            width:screenWidth*0.23,
            child: FlutterSlider(
              handlerWidth: 20,
              handlerHeight: 20,

              handler: FlutterSliderHandler(
                decoration: BoxDecoration(),
                child: Material(
                  type: MaterialType.canvas,
                  color: Colors.green,
                  elevation: 3,
                  child: Container(
                      padding: EdgeInsets.all(5),
                      child: Icon(Icons.adjust, size: 7,)),
                ),
              ),              
              tooltip: FlutterSliderTooltip(
                disabled: true,
              ),              
              values: [ varA[idx] * 10000],
              max: 1500,
              min: 0,
              onDragging: (handlerIndex, lowerValue, upperValue) {
                varA[idx] = lowerValue/10000;
                aBufView[idx] = varA[idx];
                changeNeuronSimulatorParameters();

                setState(() {});
              },
            ),
          ),
          if (idx==0)...{
            Text(varA[idx].toStringAsFixed(2))

          },
        ],
      ),

      const Text("b: sensitivity of fluctuations"),
      Row(
        children: [
          if (idx==1)...{
            SizedBox(
              width:labelSliderWidth,
              child:Text(varB[idx].toStringAsFixed(2)),
            ),
          },
          SizedBox(
            width:screenWidth*0.23,
            child: FlutterSlider(
              handlerWidth: 20,
              handlerHeight: 20,
              handler: FlutterSliderHandler(
                decoration: BoxDecoration(),
                child: Material(
                  type: MaterialType.canvas,
                  color: Colors.green,
                  elevation: 3,
                  child: Container(
                      padding: EdgeInsets.all(5),
                      child: Icon(Icons.adjust, size: 7,)),
                ),
              ),              

              tooltip: FlutterSliderTooltip(
                disabled: true,
              ),              
              values: [ varB[idx] * 10000],
              max: 5000,
              min: 0,
              onDragging: (handlerIndex, lowerValue, upperValue) {
                varB[idx] = lowerValue/10000;
                bBufView[idx] = varB[idx];
                changeNeuronSimulatorParameters();

                setState(() {});
              },
            ),
          ),
          if (idx==0)...{
            Text(varB[idx].toStringAsFixed(2))
          },
        ],
      ),

      const Text("c: after-spike reset value"),
      Row(
        children: [
          if (idx==1)...{
            SizedBox(
              width:labelSliderWidth,
              child:Text(varC[idx].toStringAsFixed(0)),
            ),

          },

          SizedBox(
            width:screenWidth*0.23,
            child: FlutterSlider(
              handlerWidth: 20,
              handlerHeight: 20,
              handler: FlutterSliderHandler(
                decoration: BoxDecoration(),
                child: Material(
                  type: MaterialType.canvas,
                  color: Colors.green,
                  elevation: 3,
                  child: Container(
                      padding: EdgeInsets.all(5),
                      child: Icon(Icons.adjust, size: 7,)),
                ),
              ),              

              tooltip: FlutterSliderTooltip(
                disabled: true,
              ),              
              values: [ varC[idx] * 10000],
              max: 0,
              min: -1000000,
              onDragging: (handlerIndex, lowerValue, upperValue) {
                varC[idx] = (lowerValue/10000).floor();
                cBufView[idx] = varC[idx];
                changeNeuronSimulatorParameters();

                setState(() {});
              },
            ),
          ),
          if (idx==0)...{
            Text(varC[idx].toStringAsFixed(0)),
          },
        ],
      ),

      const Text("d: after-spike inhibition"),
      Row(
        children: [
          if (idx==1)...{
            SizedBox(
              width:labelSliderWidth,
              child:Text(varD[idx].toStringAsFixed(0)),
            ),
          },

          SizedBox(
            width:screenWidth*0.23,
            child: FlutterSlider(
              handlerWidth: 20,
              handlerHeight: 20, 
              handler: FlutterSliderHandler(
                decoration: BoxDecoration(),
                child: Material(
                  type: MaterialType.canvas,
                  color: Colors.green,
                  elevation: 3,
                  child: Container(
                      padding: EdgeInsets.all(5),
                      child: Icon(Icons.adjust, size: 7,)),
                ),
              ),              

              tooltip: FlutterSliderTooltip(
                disabled: true,
              ),              
              values: [ varD[idx] * 10000],
              max: 100000,
              min: 0,
              onDragging: (handlerIndex, lowerValue, upperValue) {
                varD[idx] = (lowerValue/10000).floor();
                dBufView[idx] = varD[idx];
                changeNeuronSimulatorParameters();

                setState(() {});
              },
            ),
          ),
          if (idx==0)...{
            Text(varD[idx].toStringAsFixed(0)),
          },
        ],
      ),

      const Text("i: input noise"),
      Row(
        children: [
          if (idx==1)...{
            SizedBox(
              width:labelSliderWidth,
              child:Text(varI[idx].toStringAsFixed(0)),
            ),
          },
          SizedBox(
            width:screenWidth*0.23,
            child: FlutterSlider(
              handlerWidth: 20,
              handlerHeight: 20,
              handler: FlutterSliderHandler(
                decoration: BoxDecoration(),
                child: Material(
                  type: MaterialType.canvas,
                  color: Colors.green,
                  elevation: 3,
                  child: Container(
                      padding: EdgeInsets.all(5),
                      child: Icon(Icons.adjust, size: 7,)),
                ),
              ),              

              tooltip: FlutterSliderTooltip(
                disabled: true,
              ),              
              values: [ varI[idx] * 10000],
              max: 200000,
              min: 0,
              onDragging: (handlerIndex, lowerValue, upperValue) {
                varI[idx] = (lowerValue/10000).floor();
                iBufView[idx] = varI[idx];
                changeNeuronSimulatorParameters();

                setState(() {});
              },
            ),
          ),
          if (idx==0)...{
            Text(varI[idx].toStringAsFixed(0)),
            const Padding(padding: EdgeInsets.only(right:10)),
          },
        ],
      ),    
      const Text("w: synaptic strength"),
      Row(
        children: [
          if (idx==1)...{
            SizedBox(
              width:labelSliderWidth,
              child:Text(varW[idx].toStringAsFixed(0),),
            ),
          },
          SizedBox(
            width:screenWidth*0.23,
            child: FlutterSlider(
              handlerWidth: 20,
              handlerHeight: 20, 
              handler: FlutterSliderHandler(
                decoration: BoxDecoration(),
                child: Material(
                  type: MaterialType.canvas,
                  color: Colors.green,
                  elevation: 3,
                  child: Container(
                      padding: EdgeInsets.all(5),
                      child: Icon(Icons.adjust, size: 7,)),
                ),
              ),              

              tooltip: FlutterSliderTooltip(
                disabled: true,
              ),              
              values: [ varW[idx] * 10000],
              max: 300000,
              min: 0,
              onDragging: (handlerIndex, lowerValue, upperValue) {
                varW[idx] = (lowerValue/10000);
                wBufView[idx] = varW[idx];
                changeNeuronSimulatorParameters();

                setState(() {});
              },
            ),
          ),
          if (idx==0)...{
            Text(varW[idx].toStringAsFixed(0)),
          },
        ],
      ),  
    ];
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    if (!isInitialized){
      isInitialized = true;
      protoCircle = ProtoCircle(notifier:redrawNeuronLine, neuronSize:neuronSize, screenWidth:screenWidth, screenHeight:screenHeight, 
        aBufView:aBufView,bBufView:bBufView,cBufView:cBufView,dBufView:dBufView,iBufView:iBufView,wBufView:wBufView, connectomeBufView:connectomeBufView);
      const level = 1;
      const envelopeSize = 200;
      const bufferSize = 2000;

      nativec.changeNeuronSimulatorProcess(aBuf, bBuf, cBuf, dBuf, iBuf, wBuf, positionsBuf,connectomeBuf, level, neuronSize, envelopeSize, bufferSize, 1);
      // protoCircle.setNeuronParameters(aBufView,bBufView,cBufView,dBufView,iBufView,wBufView);
      // print(wBufView);
    }
    return Scaffold(
      // appBar: AppBar(
      //   title: Text(widget.title),
      // ),
      body: Stack(
        children: [
          const Positioned(
            top: 0,
            right: 0,
            child: Center(
              child: Text("Prototype 2", style: TextStyle(fontSize: 25),),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            child: SizedBox(
              width: screenWidth * 2 / 3 + 50,
              height: screenHeight * 0.5 +50,
              child: GestureDetector(
                onTapUp: (TapUpDetails tapUp){
                  print("protoCircle.isSelected");
                  // print(protoCircle.isSelected);
                  // print(protoCircle.idxSelected);
                  bool flag = protoCircle.testHit(tapUp.globalPosition);
                  if (flag){
                    nativec.changeIdxSelected(protoCircle.idxSelected);
                    setState(() {});
                  }
                  redrawNeuronLine.value=Random().nextInt(100);
                },
                child :CustomPaint(
                  painter:protoCircle,
                  willChange: true,
                  isComplex: true,
                  // child:Container(),
                ),
                // child: ValueListenableBuilder(
                //   valueListenable: redrawNeuron,
                //   builder: (BuildContext context, value, child) {
                //     print("redraw");
                //     return CustomPaint(
                //       painter:protoCircle,
                //       willChange: true,
                //       isComplex: true,
                //       child:Container(),
                //     );
                //   }
                // ),
              ),
            ),

          ),

          Positioned(
            top: 50,
            right:20,
            child: SizedBox(
              width:150,
              height:50,
              child: TextField(controller: neuronInputController,keyboardType: TextInputType.number)
            )
          ),

          Positioned(
            top: 120,
            right:20,
            child: SizedBox(
                width:150,
                height:30,
                child: ElevatedButton(
                  child:const Text("Update"),
                  onPressed:(){
                    // pause the thread
                    // nativec.changeIsPlayingProcess(-1);
                    nativec.stopThreadProcess(0);
                    protoCircle.isSelected = false;
                    protoCircle.idxSelected = -1;
                    neuronSize = int.parse(neuronInputController.text);
                    resetNeuronParameters();

                    protoCircle = ProtoCircle(notifier:redrawNeuronLine, neuronSize:neuronSize, screenWidth:screenWidth, screenHeight:screenHeight, 
                      aBufView:aBufView,bBufView:bBufView,cBufView:cBufView,dBufView:dBufView,iBufView:iBufView,wBufView:wBufView, connectomeBufView:connectomeBufView);
                    // nativec.changeIsPlayingProcess(-1);

                    // update the parameters
                    Future.delayed(const Duration(milliseconds: 300), (){
                      const level = 1;
                      const envelopeSize = 200;
                      const bufferSize = 2000;

                      nativec.changeNeuronSimulatorProcess(aBuf, bBuf, cBuf, dBuf, iBuf, wBuf, positionsBuf, connectomeBuf, level, neuronSize, envelopeSize, bufferSize, 1);

                    });
                  },
                )
            )
          ),

          if (isInitialized && protoCircle.isSelected)...{
            Positioned(
              top: 220,
              right:20,
              child:SizedBox(
                width:250,
                height:250,
                child:Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: getMatrixData(protoCircle.idxSelected),
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              child:Container(
                margin: const EdgeInsets.all(10.0),
                decoration: BoxDecoration(border: Border.all(color:Colors.black)),

                // color:Colors.red,
                height:screenHeight/2-150,
                width: screenWidth-20,
                child: PolygonWaveform(
                  activeColor: Colors.black,
                  inactiveColor: Colors.black,
                  gain:chartGain,
                  channelIdx: 0,
                  channelActive: 0,
                  levelMedian:levelMedian,
                  // levelMedian:0,
                  strokeWidth: 1.0,

                  height: screenHeight/2-150,
                  width: screenWidth-20, 
                  samples: Nativec.canvasBufferBytes1, 
                  // samples: Float64List(0), 
                  maxDuration: const Duration(seconds:3), 
                  elapsedDuration: const Duration(seconds:1),
                  eventMarkersPosition: [positionsBufView[0].toDouble()],
                )
              )
            ),

          },
        ],
      ),
      // floatingActionButton: FloatingActionButton(
      //   onPressed: _incrementCounter,
      //   tooltip: 'Increment',
      //   child: const Icon(Icons.add),
      // ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
  
  void changeNeuronSimulatorParameters() {
    const level = 1;
    const envelopeSize = 200;
    const bufferSize = 2000;
    debouncerScroll.run(() { 
      nativec.changeNeuronSimulatorProcess(aBuf, bBuf, cBuf, dBuf, iBuf, wBuf, positionsBuf, connectomeBuf,level, neuronSize, envelopeSize, bufferSize, 1);
    });

  }
  
  List<Widget> getMatrixData(int idxSelected) {
    List<Widget> widgets = [];
    int idxSelected = protoCircle.idxSelected;
    widgets.add( Text("Neuron : ${idxSelected.toString()}" , style: TextStyle(fontWeight: FontWeight.bold)) );
    widgets.add( Text("Neuron Type : ${protoCircle.circles[idxSelected].neuronType.toString()}" , style: TextStyle(fontWeight: FontWeight.bold)) );
    widgets.add( const Text("Incoming" , style: TextStyle(fontWeight: FontWeight.bold)) );
    widgets.add( Text(protoCircle.matrixTranspose[idxSelected].toList().toString()) );
    widgets.add( const Text("Outwards : " , style: TextStyle(fontWeight: FontWeight.bold)) );
    widgets.add( Text(protoCircle.matrix[idxSelected].toList().toString()) );
    return widgets;
  }
}
