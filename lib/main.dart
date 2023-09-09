// import 'dart:async';
import 'dart:convert';
// import 'dart:ffi' as ffi;
// import 'dart:io';
// import 'dart:isolate';
import 'dart:js' as js;
import 'dart:math';
// import 'dart:typed_data';
// import 'dart:typed_data';
import 'package:another_xlider/another_xlider.dart';
import 'package:another_xlider/models/handler.dart';
import 'package:another_xlider/models/tooltip/tooltip.dart';
// import 'package:async/async.dart';
// import 'package:auto_orientation/auto_orientation.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_audio_waveforms/flutter_audio_waveforms.dart';

import 'package:flutter/material.dart';
import 'package:neurorobot/utils/Debouncers.dart';
import 'package:neurorobot/utils/NeuronCircle.dart';
// import 'package:mic_stream/mic_stream.dart';
// import 'package:nativec/allocation.dart';
// import 'package:nativec/nativec.dart';
// import 'package:neurorobot/bloc/bloc.dart';
// import 'package:winaudio/winaudio.dart';
// import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // if (Platform.isMacOS || Platform.isWindows || Platform.isLinux){
  //   await windowManager.ensureInitialized();

  //   WindowOptions windowOptions = const WindowOptions(
  //     minimumSize: Size(800, 600),
  //     size: Size(1200, 800),
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
      home: const MyHomePage(title: 'NeuroRobot - 2 Neurons Simulator'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

// void sampleBufferingEntryPoint(List<dynamic> values) {
//   final iReceivePort = ReceivePort();
//   SendPort sendPort = values[0];
//   iReceivePort.listen((Object? message) async {});
//   // sendPort.send([buffers, arrHeads[0], eventPositionResultInt]);
// }

class _MyHomePageState extends State<MyHomePage> {
    CustomPaint neuronActive0=CustomPaint(
      willChange: true,
      isComplex: true,
      painter: NeuronCircle(const Color(0xffFEe6CB), [false,false]),
    );
    CustomPaint neuronActive1=CustomPaint(
      willChange: true,
      isComplex: true,
      painter: NeuronCircle(const Color(0xffFEe6CB), [true,false]),
    );
    CustomPaint neuronActive2=CustomPaint(
      willChange: true,
      isComplex: true,
      painter: NeuronCircle(const Color(0xffFEe6CB), [false,true]),
    );
    CustomPaint neuronActive12=CustomPaint(
      willChange: true,
      isComplex: true,
      painter: NeuronCircle(const Color(0xffFEe6CB), [true,true]),
    );

  Debouncer debouncerScroll = Debouncer(milliseconds: 300);  
  static int neuronSize = 2;
  /* Flutter Native
  StreamSubscription<dynamic>? winAudioSubscription;
  late Nativec nativec;
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
  
  static ffi.Pointer<ffi.Int16> wBuf = allocate<ffi.Int16>(
      count: neuronSize, sizeOfType: ffi.sizeOf<ffi.Int16>());
  late Int16List wBufView  = Int16List(0);
  
*/  
  List<double> aBufView  = List<double>.filled(neuronSize, 0);
  List<double> bBufView  = List<double>.filled(neuronSize, 0);
  List<int> cBufView  = List<int>.filled(neuronSize, 0);
  List<int> dBufView  = List<int>.filled(neuronSize, 0);
  List<double> iBufView  = List<double>.filled(neuronSize, 0);
  List<int> wBufView  = List<int>.filled(neuronSize, 0);
  List<int> positionsBufView  = List<int>.filled(neuronSize, 0);

  List<double> varA = List<double>.filled(neuronSize, 0.02);
  List<double> varB = List<double>.filled(neuronSize, 0.18);
  List<int> varC = List<int>.filled(neuronSize, -65);
  List<int> varD = List<int>.filled(neuronSize, 2);
  List<double> varI = List<double>.filled(neuronSize, 5);
  List<int> varW = List<int>.filled(neuronSize, 2);

  List<bool> firingFlags = List<bool>.filled(neuronSize, false);
  ValueNotifier<int> spikingFlags = ValueNotifier(0);

  List<Float64List> canvasBufferBytes = [Float64List(0),Float64List(0)];
  
  int isPlaying = 1;
  double levelMedian = 20;
  double chartGain = 1;

  void initNativeC(){
    // for (int i = 0;i<3000;i++){
    //   canvasBufferBytes[i] = Random().nextDouble() * 100;
    // }
    // canvasBufferBytes.fillRange(0, 3000,-2);
    const a = 0.02;
    const b = 0.18;
    const c = -65;
    const d = 2;
    const i = 5.0;
    const w = 2;
    
    int neuronSizeType = neuronSize;

    aBufView.fillRange(0, neuronSize, a);
    bBufView.fillRange(0, neuronSize, b);
    cBufView.fillRange(0, neuronSize, c);
    dBufView.fillRange(0, neuronSize, d);
    iBufView.fillRange(0, neuronSize, i);
    wBufView.fillRange(0, neuronSize, w);
    // aBufView.fillRange(0, neuronSize, a);
    // bBufView.fillRange(0, neuronSize, b);
    // cBufView.fillRange(0, neuronSize, c);
    // dBufView.fillRange(0, neuronSize, d);
    // iBufView.fillRange(0, neuronSize, i);
    // wBufView.fillRange(0, neuronSize, w);
    // positionsBufView.fillRange(0, neuronSize, 0);

/*    nativec = Nativec();
    aBufView = aBuf.asTypedList(neuronSizeType);
    bBufView = bBuf.asTypedList(neuronSizeType);
    cBufView = cBuf.asTypedList(neuronSizeType);
    dBufView = dBuf.asTypedList(neuronSizeType);
    iBufView = iBuf.asTypedList(neuronSizeType);
    wBufView = wBuf.asTypedList(neuronSizeType);
    positionsBufView = positionsBuf.asTypedList(neuronSizeType);

    aBufView.fillRange(0, neuronSize, a);
    bBufView.fillRange(0, neuronSize, b);
    cBufView.fillRange(0, neuronSize, c);
    dBufView.fillRange(0, neuronSize, d);
    iBufView.fillRange(0, neuronSize, i);
    wBufView.fillRange(0, neuronSize, w);
    positionsBufView.fillRange(0, neuronSize, 0);

    const level = 1;
    const envelopeSize = 200;
    const bufferSize = 2000;
    nativec.changeNeuronSimulatorProcess(aBuf, bBuf, cBuf, dBuf, iBuf, wBuf, positionsBuf, level, neuronSize, envelopeSize, bufferSize, 1);    
    Nativec.cPublicationStream!.listen((message) {
      if (message.indexOf("S|")>-1){
        List<String> arr = message.split("|");
        int firingFlags=0;
        // List<int> firingFlags= [0,0];
        if (arr[1]=="1" && arr[2]=="1"){
          // firingFlags[0] = 1;
          // firingFlags[1] = 1;
          firingFlags = 3000 + Random().nextInt(1000);
          spikingFlags.value = firingFlags;
          // mainBloc.refreshNow(firingFlags);
        }else
        if (arr[1]=="1" ){
          // firingFlags[0] = 1;
          // firingFlags[1] = 0;
          firingFlags = 1000 + Random().nextInt(1000);
          spikingFlags.value = firingFlags;
          // mainBloc.refreshNow(firingFlags);
        }else
        if (arr[2]=="1"){
          // firingFlags[0] = 0;
          // firingFlags[1] = 1;
          firingFlags = 2000 + Random().nextInt(1000);
          spikingFlags.value = firingFlags;
          // mainBloc.refreshNow(firingFlags);
        }else{
          // firingFlags[0] = 0;
          // firingFlags[1] = 0;
          firingFlags = 0 + Random().nextInt(1000);
          spikingFlags.value = firingFlags;
          // mainBloc.refreshNow(firingFlags);
        }
        // print("1---Redraw1");
        // print(firingFlags);

        // setState(() {
          
        // });
      }else{
        print("PRINT C++ MESSAGE222 : ");
        print(message);

      }
    });    
*/
  }

  canvasDraw(params){
    // print(params);
    canvasBufferBytes[0] = Float64List.fromList((params[0]).toList().cast<double>());
    canvasBufferBytes[1] = Float64List.fromList((params[1]).toList().cast<double>());
    positionsBufView[0] = (params[2]).toList().cast<double>()[0];
    // canvasBufferBytes[0] = params[0];
    // canvasBufferBytes[1] = params[1];
    setState((){});
  }

  neuronTrigger(params){
    int firingFlags=0;
    List<int> arr = (params).toList().cast<int>();

    if (arr[0]==1 && arr[1]==1){
      firingFlags = 3000 + Random().nextInt(1000);
      spikingFlags.value = firingFlags;
      // mainBloc.refreshNow(firingFlags);
    }else
    if (arr[0]==1 ){
      firingFlags = 1000 + Random().nextInt(1000);
      spikingFlags.value = firingFlags;
      // mainBloc.refreshNow(firingFlags);
    }else
    if (arr[1]==1){
      firingFlags = 2000 + Random().nextInt(1000);
      spikingFlags.value = firingFlags;
      // mainBloc.refreshNow(firingFlags);
    }else{
      firingFlags = 0 + Random().nextInt(1000);
      spikingFlags.value = firingFlags;
    }
  }

  void initState(){
    super.initState();
    initNativeC();
    if (kIsWeb){
      js.context['canvasDraw'] = canvasDraw;
      js.context['neuronTrigger'] = neuronTrigger;
      js.context.callMethod("initializeModels",[]);
    }


    // Timer.periodic(Duration(milliseconds: 50), (timer) { 
    //   // print(Nativec.canvasBufferBytes1.sublist(0,5));
    //   setState(()=>{

    //   });
    // });
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
                varW[idx] = (lowerValue/10000).floor();
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
    return Scaffold(
      // appBar: AppBar(
      //   title: Text(widget.title),
      // ),
      body: Column(
        children: [
          const Center(
            child: Text("Two Neuron Simulator", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold ),),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              SizedBox(
                width: screenWidth*0.3,
                child:Column(
                  children: sideWidget(0, screenWidth),
                ),
              ),
              SizedBox(
                width: screenWidth *0.4,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 400,
                      height: 300,
                      child: ValueListenableBuilder(
                        valueListenable: spikingFlags,
                        builder: (context, value, child) {
                          // print("1.5----- Firing Flags ");
                          int firingFlags = value;
                          // print(firingFlags);
                          // if (firingFlags[0]== 1 && firingFlags[1]==1){
                          if (firingFlags >= 3000){
                            return neuronActive12;
                          }else
                          // if (firingFlags[0]== 1){
                          if (firingFlags>= 1000 && firingFlags < 2000){
                            // print("2----- neuron circle should redraw");
                            return neuronActive1;
                          }else
                          // if (firingFlags[1]==1){
                          if (firingFlags>= 2000 && firingFlags < 3000){
                            return neuronActive2;
                          }else{
                            return neuronActive0;
                          }                      
                        },
                      ),
                    ),
                    SizedBox(
                      width:screenWidth * 0.4,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          ElevatedButton(
                            onPressed: (){
                              if (isPlaying == 1){
                                isPlaying = -1;
                              }else{
                                isPlaying = 1;
                              }
                              js.context.callMethod('setIsPlaying',[isPlaying]);
                              // nativec.changeIsPlayingProcess(isPlaying);
                            }, 
                            child: isPlaying==-1?const Text("Play"):const Text("Pause"),
                          ),
                          const SizedBox(
                            width:10
                          ),
                          ElevatedButton(
                            onPressed: (){
                              // if (chartGain-1>0)
                              // levelMedian*=2;
                              chartGain/=2;
                              // print("chartGain");
                              // print(chartGain);
                            }, 
                            child: const Text("+")
                          ),
                          const SizedBox(
                            width:10
                          ),
                          ElevatedButton(
                            onPressed: (){
                              // if (chartGain+1<=20)
                              // levelMedian/=2;
                              chartGain*=2;
                              // print("chartGain");
                              // print(chartGain);
                            }, 
                            child: const Text("-")
                          )

                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: screenWidth *0.3,
                child:Column(
                  children: sideWidget(1, screenWidth),
                ),
              ),
            ],
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(10.0),
              child: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  return Container(
                    decoration: BoxDecoration(border: Border.all(color:Colors.black)),
                    width: constraints.maxWidth,
                    height: constraints.maxHeight,
                    child: Column(
                      children: [
                        PolygonWaveform(
                          width:constraints.maxWidth,
                          activeColor: Colors.black,
                          inactiveColor: Colors.black,
                          height:constraints.maxHeight/2, 
                          gain:chartGain,
                          channelIdx: 0,
                          channelActive: 0,
                          levelMedian:levelMedian,
                          strokeWidth: 1.0,
                          // samples: Nativec.canvasBufferBytes1.sublist(0,600), 
                          // samples: Nativec.canvasBufferBytes1, 
                          // samples: Float64List(0), 
                          // samples: Nativec.canvasBufferBytes2, 
                          samples: canvasBufferBytes[0], 
                          maxDuration: const Duration(seconds: 10), 
                          elapsedDuration: const Duration(seconds: 10), 
                          eventMarkersPosition: [positionsBufView[0].toDouble()],
                          // eventMarkersPosition: [0],
                        ),
                        PolygonWaveform(
                          width:constraints.maxWidth,
                          activeColor: Colors.black,
                          inactiveColor: Colors.black,
                          height:constraints.maxHeight/2, 
                          gain:chartGain,
                          channelIdx: 1,
                          channelActive: 0,
                          levelMedian:levelMedian,
                          strokeWidth: 1.0,
                          // samples: Nativec.canvasBufferBytes2, 
                          // samples: Float64List(0), 
                          // samples: Nativec.canvasBufferBytes2, 
                          samples: canvasBufferBytes[1], 
                          maxDuration: const Duration(seconds: 10), 
                          elapsedDuration: const Duration(seconds: 10), 
                          eventMarkersPosition: [positionsBufView[0].toDouble()],
              
                        ),
                    
                      ],
                    )
                  );
                }
              ),
            ),
          )
        
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
      if (kIsWeb){
        print("changeNeuronSimulatorParameters");
        js.context.callMethod('setIzhikevichParameters', 
          [jsonEncode([aBufView,bBufView,cBufView,dBufView,iBufView,wBufView,positionsBufView,level, neuronSize,envelopeSize,bufferSize,isPlaying])]
        );
      }else{
        // nativec.changeNeuronSimulatorProcess(aBuf, bBuf, cBuf, dBuf, iBuf, wBuf, positionsBuf,level, neuronSize, envelopeSize, bufferSize, 1);
      }
    });

  }
}
