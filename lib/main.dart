import 'dart:async';
import 'dart:convert';
// import 'dart:ffi' as ffi;
import 'dart:io';
import 'dart:isolate';
import 'dart:js' as js;
import 'dart:math';
import 'dart:typed_data';
import 'package:another_xlider/another_xlider.dart';
import 'package:another_xlider/models/handler.dart';
import 'package:another_xlider/models/tooltip/tooltip.dart';
// import 'package:async/async.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_audio_waveforms/flutter_audio_waveforms.dart';
import 'package:flutter/material.dart';

// import 'package:auto_orientation/auto_orientation.dart';
// import 'package:mic_stream/mic_stream.dart';

// import 'package:nativec/allocation.dart';
// import 'package:nativec/nativec.dart';
// import 'package:neurorobot/bloc/bloc.dart';
import 'package:neurorobot/utils/Debouncers.dart';
// import 'package:neurorobot/utils/NeuronCircle.dart';
import 'package:neurorobot/utils/ProtoNeuron.dart';
import 'package:neurorobot/utils/SingleCircle.dart';
import 'package:neurorobot/utils/WaveWidget.dart';
// import 'package:winaudio/winaudio.dart';
// import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // if (Platform.isMacOS || Platform.isWindows || Platform.isLinux){
  //   await windowManager.ensureInitialized();

  //   WindowOptions windowOptions = const WindowOptions(
  //     minimumSize: Size(800, 600),
  //     size: Size(800, 600),
  //     center: true,
  //     backgroundColor: Colors.transparent,
  //     skipTaskbar: false,
  //     titleBarStyle: TitleBarStyle.hidden,
  //   );
  //   windowManager.waitUntilReadyToShow(windowOptions, () async {
  //     await windowManager.show();
  //     await windowManager.focus();
  //   });

  // }else{
  //   AutoOrientation.landscapeLeftMode();
  // }

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
  // late Nativec nativec;
  static int neuronSize = 25;
  static const int maxPosBuffer = 627;

  // static ffi.Pointer<ffi.Uint16> positionsBuf = allocate<ffi.Uint16>(
  //     count: maxPosBuffer, sizeOfType: ffi.sizeOf<ffi.Uint16>());
  // late Uint16List positionsBufView  = Uint16List(0);

  // static ffi.Pointer<ffi.Double> aBuf = allocate<ffi.Double>(
  //     count: maxPosBuffer, sizeOfType: ffi.sizeOf<ffi.Double>());
  // late Float64List aBufView  = Float64List(0);

  // static ffi.Pointer<ffi.Double> bBuf = allocate<ffi.Double>(
  //     count: maxPosBuffer, sizeOfType: ffi.sizeOf<ffi.Double>());
  // late Float64List bBufView  = Float64List(0);

  
  // static ffi.Pointer<ffi.Int16> cBuf = allocate<ffi.Int16>(
  //     count: maxPosBuffer, sizeOfType: ffi.sizeOf<ffi.Int16>());
  // late Int16List cBufView  = Int16List(0);
  
  // static ffi.Pointer<ffi.Int16> dBuf = allocate<ffi.Int16>(
  //     count: maxPosBuffer, sizeOfType: ffi.sizeOf<ffi.Int16>());
  // late Int16List dBufView  = Int16List(0);

  // static ffi.Pointer<ffi.Int16> iBuf = allocate<ffi.Int16>(
  //     count: maxPosBuffer, sizeOfType: ffi.sizeOf<ffi.Int16>());
  // late Int16List iBufView  = Int16List(0);
  
  // static ffi.Pointer<ffi.Double> wBuf = allocate<ffi.Double>(
  //     count: maxPosBuffer, sizeOfType: ffi.sizeOf<ffi.Double>());
  // late Float64List wBufView  = Float64List(0);


  // static ffi.Pointer<ffi.Double> connectomeBuf = allocate<ffi.Double>(
  //     count: maxPosBuffer * maxPosBuffer, sizeOfType: ffi.sizeOf<ffi.Double>());
  // late Float64List connectomeBufView  = Float64List(0);
  Float64List aBufView  = Float64List(neuronSize);
  Float64List bBufView  = Float64List(neuronSize);
  Int16List cBufView  = Int16List(neuronSize);
  Int16List dBufView  = Int16List(neuronSize);
  Float64List iBufView  = Float64List(neuronSize);
  Float64List wBufView  = Float64List(neuronSize);
  // List<int> positionsBufView  = List<int>.filled(neuronSize, 0);
  Uint16List positionsBufView  = Uint16List(neuronSize);
  Float64List connectomeBufView  = Float64List(neuronSize*neuronSize);
  
  List<double> varA = List<double>.filled(neuronSize, 0.02);
  List<double> varB = List<double>.filled(neuronSize, 0.18);
  List<int> varC = List<int>.filled(neuronSize, -65);
  List<int> varD = List<int>.filled(neuronSize, 2);
  List<double> varI = List<double>.filled(neuronSize, 5);
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
  double levelMedian = 20;
  double chartGain = 1;

  bool isInitialized = false;
  
  late ProtoNeuron protoNeuron;
  ValueNotifier<int> redrawNeuronLine = ValueNotifier(0);
  
  TextEditingController neuronInputController = TextEditingController(text:"25");
  
  late WaveWidget waveWidget;
  
  Int16List neuronCircleBridge = Int16List(0);

  void resetNeuronParameters(){
    double a = 0.02;
    double b = 0.18;
    int c = -65;
    int d = 2;
    double i = 5.0;
    double w = 2.0;   
    
    aBufView  = Float64List(neuronSize);
    bBufView  = Float64List(neuronSize);
    cBufView  = Int16List(neuronSize);
    dBufView  = Int16List(neuronSize);
    iBufView  = Float64List(neuronSize);
    wBufView  = Float64List(neuronSize);
    
    aBufView.fillRange(0, neuronSize, a);
    bBufView.fillRange(0, neuronSize, b);
    cBufView.fillRange(0, neuronSize, c);
    dBufView.fillRange(0, neuronSize, d);
    iBufView.fillRange(0, neuronSize, i);
    wBufView.fillRange(0, neuronSize, w);
    
    positionsBufView  = Uint16List(neuronSize);
    connectomeBufView  = Float64List(neuronSize*neuronSize);

    positionsBufView.fillRange(0, neuronSize, 0);
    connectomeBufView.fillRange(0, neuronSize * neuronSize, 0);

    
    varA = List<double>.filled(neuronSize, 0.02);
    varB = List<double>.filled(neuronSize, 0.18);
    varC = List<int>.filled(neuronSize, -65);
    varD = List<int>.filled(neuronSize, 2);
    varI = List<double>.filled(neuronSize, 5.0);
    varW = List<double>.filled(neuronSize, 2.0);
    firingFlags = List<bool>.filled(neuronSize, false);    
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
    
  }
  void initNativeC(){
    // for (int i = 0;i<3000;i++){
    //   canvasBufferBytes[i] = Random().nextDouble() * 100;
    // }
    // canvasBufferBytes.fillRange(0, 3000,-2);

    // nativec = Nativec();
    double a = 0.02;
    double b = 0.18;
    int c = -65;
    int d = 2;
    double i = 5.0;
    double w = 2.0;   
    
    // int neuronSizeType = neuronSize;
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


    const level = 1;
    const envelopeSize = 200;
    const bufferSize = 2000;
    // js.context.callMethod('setIzhikevichParameters', 
    //   [jsonEncode([aBufView,bBufView,cBufView,dBufView,iBufView,wBufView,positionsBufView, connectomeBufView,level, neuronSize,envelopeSize,bufferSize,1])]
    // );

    // nativec.changeNeuronSimulatorProcess(aBuf, bBuf, cBuf, dBuf, iBuf, wBuf, positionsBuf, connectomeBuf, level, neuronSize, envelopeSize, bufferSize, 1);
    // Nativec.cPublicationStream!.listen((message) {
    //   // print("message");
    //   // print(message);
    //   if (message.indexOf("S|")>-1){
    //     List<String> arr = message.split("|");
    //     // bool needRedraw = false;
    //     try{
    //       for (int i = 1; i < arr.length ; i++){
    //         int neuronIndex = i - 1;
    //         if (arr[i] == '1'){
    //           // if (protoNeuron.circles[neuronIndex].isSpiking != 1){
    //           //   needRedraw = true;
    //           // }
    //           protoNeuron.circles[neuronIndex].isSpiking = 1;
    //           neuronSpikeFlags[neuronIndex].value = Random().nextInt(10000);
    //         }else{
    //           // if (protoNeuron.circles[neuronIndex].isSpiking != 0){
    //           //   needRedraw = true;
    //           // }
    //           protoNeuron.circles[neuronIndex].isSpiking = -1;
    //           neuronSpikeFlags[neuronIndex].value = Random().nextInt(10000);
    //         }
    //       }
    //     }catch(ex){

    //     }
    //     // print(needRedraw);
    //     // if (needRedraw) {
    //       // redrawNeuronLine.value=Random().nextInt(1000);
    //     // }
    //   }else{
    //     print("PRINT C++ MESSAGE222 : ");
    //     print(message);

    //   }
    // });    
  }

  // bool canvasDraw(params){

  //   return true;
  // }
  setCanvasBuffer(buffer, positionsBuf, neuronBridge){
    WaveWidget.canvasBufferBytes1 = buffer;
    WaveWidget.positionsBufView = positionsBuf;
    neuronCircleBridge = neuronBridge;
  }

  canvasDraw(){
    // print(params);
    // WaveWidget.canvasBufferBytes1 = Float64List.fromList((params[0]).toList().cast<double>());
    // canvasBufferBytes[1] = Float64List.fromList((params[1]).toList().cast<double>());
    // positionsBufView[0] = (params[1]).toList().cast<double>()[0];
    // WaveWidget.positionsBufView = positionsBufView;
    // canvasBufferBytes[0] = params[0];
    // canvasBufferBytes[1] = params[1];
    setState((){});
  }

  neuronTrigger(params){
    int firingFlags=0;
    // List<int> arr = (params).toList().cast<int>();
    try{
      for (int i = 1; i < neuronCircleBridge.length ; i++){
        int neuronIndex = i - 1;
        if (neuronCircleBridge[i] == 1){
          // if (protoNeuron.circles[neuronIndex].isSpiking != 1){
          //   needRedraw = true;
          // }
          protoNeuron.circles[neuronIndex].isSpiking = 1;
          neuronSpikeFlags[neuronIndex].value = Random().nextInt(10000);
        }else{
          // if (protoNeuron.circles[neuronIndex].isSpiking != 0){
          //   needRedraw = true;
          // }
          protoNeuron.circles[neuronIndex].isSpiking = -1;
          neuronSpikeFlags[neuronIndex].value = Random().nextInt(10000);
        }
      }
    }catch(ex){
      print(ex);
    }
  }


  void initState(){
    super.initState();
    initNativeC();
    if (kIsWeb){
      js.context['setCanvasBuffer'] = setCanvasBuffer;
      js.context['canvasDraw'] = canvasDraw;
      js.context['neuronTrigger'] = neuronTrigger;

    }

    // Future.delayed(const Duration(milliseconds: 300), (){
    //   setState(()=>{

    //   });
    // });
    Timer.periodic(const Duration(milliseconds: 50), (timer) { 
      // print(Nativec.canvasBufferBytes1.sublist(0,5));
      if (protoNeuron.idxSelected !=-1){
        waveRedraw.value = Random().nextInt(10000);
        // setState(()=>{

        // });
      }
    });
  }

  void _incrementCounter() async {
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
                decoration: const BoxDecoration(),
                child: Material(
                  type: MaterialType.canvas,
                  color: Colors.green,
                  elevation: 3,
                  child: Container(
                      padding: const EdgeInsets.all(5),
                      child: const Icon(Icons.adjust, size: 7,)),
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
                decoration: const BoxDecoration(),
                child: Material(
                  type: MaterialType.canvas,
                  color: Colors.green,
                  elevation: 3,
                  child: Container(
                      padding: const EdgeInsets.all(5),
                      child: const Icon(Icons.adjust, size: 7,)),
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
                decoration: const BoxDecoration(),
                child: Material(
                  type: MaterialType.canvas,
                  color: Colors.green,
                  elevation: 3,
                  child: Container(
                      padding: const EdgeInsets.all(5),
                      child: const Icon(Icons.adjust, size: 7,)),
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
                decoration: const BoxDecoration(),
                child: Material(
                  type: MaterialType.canvas,
                  color: Colors.green,
                  elevation: 3,
                  child: Container(
                      padding: const EdgeInsets.all(5),
                      child: const Icon(Icons.adjust, size: 7,)),
                ),
              ),              

              tooltip: FlutterSliderTooltip(
                disabled: true,
              ),              
              values: [ varI[idx] * 10000],
              max: 200000,
              min: 0,
              onDragging: (handlerIndex, lowerValue, upperValue) {
                varI[idx] = (lowerValue/10000);
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
      waveWidget = WaveWidget(valueNotifier: waveRedraw,
        chartGain:chartGain,levelMedian: levelMedian,screenHeight: screenHeight,screenWidth: screenWidth);

      protoNeuron = ProtoNeuron(notifier:redrawNeuronLine, neuronSize:neuronSize, screenWidth:screenWidth, screenHeight:screenHeight, 
        aBufView:aBufView,bBufView:bBufView,cBufView:cBufView,dBufView:dBufView,iBufView:iBufView,wBufView:wBufView, connectomeBufView:connectomeBufView);
      const level = 1;
      const envelopeSize = 200;
      const bufferSize = 2000;
      // js.context.callMethod('changeNeuronSimulatorProcess', [aBufView, bBufView, cBufView, dBufView, iBufView, wBufView, positionsBufView, connectomeBufView,level, neuronSize, envelopeSize, bufferSize, 1] );

      js.context.callMethod("initializeModels",
        [ jsonEncode([aBufView,bBufView,cBufView,dBufView,iBufView,wBufView,positionsBufView, connectomeBufView,level, neuronSize,envelopeSize,bufferSize,1]) ]
      );

      // js.context.callMethod('setIzhikevichParameters', 
      //   [jsonEncode([aBufView,bBufView,cBufView,dBufView,iBufView,wBufView,positionsBufView, connectomeBufView,level, neuronSize,envelopeSize,bufferSize,1])]
      // );

      // nativec.changeNeuronSimulatorProcess(aBuf, bBuf, cBuf, dBuf, iBuf, wBuf, positionsBuf,connectomeBuf, level, neuronSize, envelopeSize, bufferSize, 1);
    }
    return Scaffold(
      body: Stack(
        children: getAllWidgets(screenWidth,screenHeight),
      ),
    );
  }
  
  void changeNeuronSimulatorParameters() {
    const level = 1;
    const envelopeSize = 200;
    const bufferSize = 2000;
    debouncerScroll.run(() { 
      js.context.callMethod('setIzhikevichParameters', 
        [jsonEncode([aBufView,bBufView,cBufView,dBufView,iBufView,wBufView,positionsBufView, connectomeBufView,level, neuronSize,envelopeSize,bufferSize,1])]
      );

      // js.context.callMethod('changeNeuronSimulatorProcess', [aBufView, bBufView, cBufView, dBufView, iBufView, wBufView, positionsBufView, connectomeBufView,level, neuronSize, envelopeSize, bufferSize, 1] );
      // nativec.changeNeuronSimulatorProcess(aBuf, bBuf, cBuf, dBuf, iBuf, wBuf, positionsBuf, connectomeBuf,level, neuronSize, envelopeSize, bufferSize, 1);
    });

  }
  
  List<Widget> getMatrixData(int idxSelected) {
    List<Widget> widgets = [];
    int idxSelected = protoNeuron.idxSelected;
    widgets.add( Text("Neuron : ${idxSelected.toString()}" , style: const TextStyle(fontWeight: FontWeight.bold)) );
    widgets.add( Text("Neuron Type : ${protoNeuron.circles[idxSelected].neuronType.toString()}" , style: const TextStyle(fontWeight: FontWeight.bold)) );
    // widgets.add( const Text("Incoming" , style: TextStyle(fontWeight: FontWeight.bold)) );
    // widgets.add( Text(protoNeuron.matrixTranspose[idxSelected].toList().toString()) );
    // widgets.add( const Text("Outwards : " , style: TextStyle(fontWeight: FontWeight.bold)) );
    // widgets.add( Text(protoNeuron.matrix[idxSelected].toList().toString()) );
    return widgets;
  }
  
  Future<void> _showMyDialog(String str) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Input is invalid'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(str),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Ok'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  List<Widget> getAllWidgets(screenWidth,screenHeight) {
    List<Widget> widgets = [
      const Positioned(
        top: 0,
        right: 0,
        child: Center(
          child: Text("Prototype 2", style: TextStyle(fontSize: 25),),
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
              onPressed:() async {
                String input = neuronInputController.text;
                int inputNumber = 0;
                try{
                  inputNumber = int.parse(input);
                  if (inputNumber > 200){
                    await _showMyDialog('Please decrease the neuron size to be at least below or equal to 200');
                    neuronInputController.text = "200";
                    return;
                  }
                }catch(ex){
                  print(ex);
                  await _showMyDialog('Please only insert valid number');
                  neuronInputController.text = "25";
                  return;
                }
                
                // pause the thread
                // nativec.stopThreadProcess(0);
                js.context.callMethod("stopThreadProcess", [0]);
                protoNeuron.isSelected = false;
                protoNeuron.idxSelected = -1;
                neuronSize = int.parse(input);
                print("resetNeuronParameters");
                resetNeuronParameters();

                print("protoNeuron");
                protoNeuron = ProtoNeuron(notifier:redrawNeuronLine, neuronSize:neuronSize, screenWidth:screenWidth, screenHeight:screenHeight, 
                  aBufView:aBufView,bBufView:bBufView,cBufView:cBufView,dBufView:dBufView,iBufView:iBufView,wBufView:wBufView, connectomeBufView:connectomeBufView);

                Future.delayed(const Duration(milliseconds: 300), (){
                  const level = 1;
                  const envelopeSize = 200;
                  const bufferSize = 2000;
                  // js.context.callMethod('changeNeuronSimulatorProcess', [aBufView, bBufView, cBufView, dBufView, iBufView, wBufView, positionsBufView, connectomeBufView,level, neuronSize, envelopeSize, bufferSize, 1] );
                  js.context.callMethod("initializeModels",
                    [ jsonEncode([
                        aBufView,bBufView,cBufView,dBufView,iBufView,wBufView,
                        positionsBufView, connectomeBufView,
                        level, neuronSize,envelopeSize,bufferSize,1]) ]
                  );
                  setState(() {});

                  // js.context.callMethod('setIzhikevichParameters', 
                  //   [jsonEncode([aBufView,bBufView,cBufView,dBufView,iBufView,wBufView,positionsBufView, connectomeBufView,level, neuronSize,envelopeSize,bufferSize,1])]
                  // );


                  // nativec.changeNeuronSimulatorProcess(aBuf, bBuf, cBuf, dBuf, iBuf, wBuf, positionsBuf, connectomeBuf, level, neuronSize, envelopeSize, bufferSize, 1);

                });
              },
            )
        )
      ),

      if (isInitialized && protoNeuron.isSelected)...{
        Positioned(
          top: 220,
          right:20,
          child:SizedBox(
            width:250,
            height:250,
            child:ListView(
              // crossAxisAlignment: CrossAxisAlignment.start,
              children: getMatrixData(protoNeuron.idxSelected),
            ),
          ),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          child:Container(
            margin: const EdgeInsets.all(10.0),
            decoration: BoxDecoration(border: Border.all(color:Colors.black)),
            height:screenHeight/2-150,
            width: screenWidth-20,
            child: waveWidget
          )
        ),

      },
    ];
    // protoNeuron.
    for (int i = 0; i < neuronSize ;i++){
      SingleNeuron neuron = protoNeuron.circles[i];
      widgets.add(
        Positioned(
          top:neuron.centerPos.dy-15,
          left:neuron.centerPos.dx-15,
          child: SizedBox(
            key:neuronCircleKeys[i],
            child: neuronCircleBridge[i] == 0? neuronInactiveCircles[i]:neuronActiveCircles[i],
            // child: ValueListenableBuilder(
            //   valueListenable: neuronSpikeFlags[i],
            //   builder: ((context, value, child) {
            //     if (protoNeuron.circles[i].isSpiking == -1){
            //       return neuronInactiveCircles[i];
            //     }else{
            //       return neuronActiveCircles[i];
            //     }
            //   }),
            // ),
          ),
        )
      );

    }
    widgets.add(
      Positioned(
        top: 0,
        left: 0,
        child: SizedBox(
          // color:Colors.blue.shade100,
          width: screenWidth * 2 / 3 + 50,
          height: screenHeight * 0.5 +50,
          child: GestureDetector(
            onTapUp: (TapUpDetails tapUp){
              print("protoNeuron.isSelected");
              // print(protoNeuron.isSelected);
              // print(protoNeuron.idxSelected);
              bool flag = protoNeuron.testHit(tapUp.globalPosition);
              if (flag){
                // nativec.changeIdxSelected(protoNeuron.idxSelected);
              }
              js.context.callMethod("changeSelectedIdx",[protoNeuron.idxSelected]);
              setState(() {});
              redrawNeuronLine.value=Random().nextInt(100);
            },
            child :CustomPaint(
              painter:protoNeuron,
              willChange: true,
              isComplex: true,
            ),
          ),
        ),

      ),


    );
    return widgets;
  }
}
