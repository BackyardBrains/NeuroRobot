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
// import 'package:nativec/nativec.dart';

import 'package:flutter/material.dart';
import 'package:native_opencv/nativec.dart';
import 'package:neurorobot/utils/Allocator.dart';
import 'package:neurorobot/utils/Debouncers.dart';
import 'package:neurorobot/utils/NeuronCircle.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
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
  } else {
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

void sampleBufferingEntryPoint(List<dynamic> values) {
  final iReceivePort = ReceivePort();
  SendPort sendPort = values[0];
  iReceivePort.listen((Object? message) async {});
  // sendPort.send([buffers, arrHeads[0], eventPositionResultInt]);
}

class _MyHomePageState extends State<MyHomePage> {
  // int _counter = 0;
  // ReceivePort _receivePort = ReceivePort();
  // ReceivePort _receiveAudioPort = ReceivePort();
  // ReceivePort iReceiveDeviceInfoPort = ReceivePort();
  // ReceivePort iReceiveExpansionDeviceInfoPort = ReceivePort();
  // late SendPort iSendPort;
  // late SendPort iSendAudioPort;
  // late var _isolate;
  // late StreamQueue _receiveAudioQueue = StreamQueue(_receiveAudioPort);
  // late CustomPaint neuronActive0;
  // late CustomPaint neuronActive1;
  // late CustomPaint neuronActive2;
  // late CustomPaint neuronActive12;

  CustomPaint neuronActive0 = CustomPaint(
    willChange: true,
    isComplex: true,
    painter: NeuronCircle(const Color(0xffFEe6CB), [false, false]),
  );
  CustomPaint neuronActive1 = CustomPaint(
    willChange: true,
    isComplex: true,
    painter: NeuronCircle(const Color(0xffFEe6CB), [true, false]),
  );
  CustomPaint neuronActive2 = CustomPaint(
    willChange: true,
    isComplex: true,
    painter: NeuronCircle(const Color(0xffFEe6CB), [false, true]),
  );
  CustomPaint neuronActive12 = CustomPaint(
    willChange: true,
    isComplex: true,
    painter: NeuronCircle(const Color(0xffFEe6CB), [true, true]),
  );

  Debouncer debouncerScroll = Debouncer(milliseconds: 300);
  StreamSubscription<dynamic>? winAudioSubscription;
  late Nativec nativec;
  static int neuronSize = 2;
  static ffi.Pointer<ffi.Uint16> positionsBuf = allocate<ffi.Uint16>(
      count: neuronSize, sizeOfType: ffi.sizeOf<ffi.Uint16>());
  late Uint16List positionsBufView = Uint16List(0);

  static ffi.Pointer<ffi.Double> aBuf = allocate<ffi.Double>(
      count: neuronSize, sizeOfType: ffi.sizeOf<ffi.Double>());
  late Float64List aBufView = Float64List(0);

  static ffi.Pointer<ffi.Double> bBuf = allocate<ffi.Double>(
      count: neuronSize, sizeOfType: ffi.sizeOf<ffi.Double>());
  late Float64List bBufView = Float64List(0);

  static ffi.Pointer<ffi.Int16> cBuf = allocate<ffi.Int16>(
      count: neuronSize, sizeOfType: ffi.sizeOf<ffi.Int16>());
  late Int16List cBufView = Int16List(0);

  static ffi.Pointer<ffi.Int16> dBuf = allocate<ffi.Int16>(
      count: neuronSize, sizeOfType: ffi.sizeOf<ffi.Int16>());
  late Int16List dBufView = Int16List(0);

  static ffi.Pointer<ffi.Double> iBuf = allocate<ffi.Double>(
      count: neuronSize, sizeOfType: ffi.sizeOf<ffi.Double>());
  late Float64List iBufView = Float64List(0);

  static ffi.Pointer<ffi.Double> wBuf = allocate<ffi.Double>(
      count: neuronSize, sizeOfType: ffi.sizeOf<ffi.Double>());
  late Float64List wBufView = Float64List(0);

  List<double> varA = List<double>.filled(neuronSize, 0.02);
  List<double> varB = List<double>.filled(neuronSize, 0.18);
  List<int> varC = List<int>.filled(neuronSize, -65);
  List<int> varD = List<int>.filled(neuronSize, 2);
  List<int> varI = List<int>.filled(neuronSize, 5);
  List<double> varW = List<double>.filled(neuronSize, 2.0);

  List<bool> firingFlags = List<bool>.filled(neuronSize, false);
  ValueNotifier<int> spikingFlags = ValueNotifier(0);

  Float64List canvasBufferBytes = Float64List(3000);

  int isPlaying = 1;
  double levelMedian = 20;
  double chartGain = 2;

  void initNativeC() {
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

    int neuronSizeType = neuronSize;
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
    iBufView.fillRange(0, neuronSize, i.toDouble());
    wBufView.fillRange(0, neuronSize, w);
    positionsBufView.fillRange(0, neuronSize, 0);

    const level = 1;
    const envelopeSize = 200;
    const bufferSize = 2000;
  }

  bool canvasDraw(params) {
    return true;
  }

  void initState() {
    super.initState();
    initNativeC();

    Timer.periodic(Duration(milliseconds: 50), (timer) {
      // print(Nativec.canvasBufferBytes1.sublist(0,5));
      setState(() => {});
    });
  }

  void _incrementCounter() async {
    print("Nativec.canvasBufferBytes1");
    print(Nativec.canvasBufferBytes1);
    // flutter: [-67.69547283578389, -65.88836155290805, 2.22009137e-314, 6.9486051849013e-310, 6.95325024256085e-310]
    // flutter: [-70.23360574903995, -70.59600013808426, -2.315841784762842e+77, -2.3203618251475037e+77, 6.95325024256085e-310]

    // nativec.getThresholdHitProcess();
    // if (Platform.isWindows || Platform.isMacOS) {
    //   if (Platform.isMacOS) {
    //     Stream<List<int>>? stream = await MicStream.microphone(
    //         audioSource: AudioSource.DEFAULT,
    //         sampleRate: 44100,
    //         channelConfig: ChannelConfig.CHANNEL_IN_MONO,
    //         audioFormat: AudioFormat.ENCODING_PCM_16BIT);
    //     MicStream.stopListening();
    //   }

    //   try {
    //     await (Winaudio()).initBassAudio(44100);
    //     Future.delayed(Duration(milliseconds: 300), () {
    //       (Winaudio()).startRecording();
    //     });
    //   } catch (err) {
    //     print('init bass audio');
    //   }

    //   // _receiveAudioPort = ReceivePort();
    //   // _receiveAudioQueue = StreamQueue(_receiveAudioPort);

    //   // _isolate = await Isolate.spawn<List<dynamic>>(sampleBufferingEntryPoint, [
    //   //   _receiveAudioPort.sendPort,
    //   //   [197]
    //   // ]);
    //   // iSendAudioPort = await _receiveAudioQueue.next;

    //   // _receiveAudioQueue.rest.listen((curSamples) {
    //   //   // insertIntoNativeC();
    //   // });

    //   winAudioSubscription?.cancel();
    //   nativec.getThresholdHitProcess();
    //   winAudioSubscription = Winaudio.audioData().listen((samples) {
    //     // insertIntoNativeC();
    //   });

    //   return;
    // }
  }

  List<Widget> sideWidget(int idx, double screenWidth) {
    double labelSliderWidth = 40.0;
    return [
      const Text("a: speed of recovery"),
      Row(
        children: [
          if (idx == 1) ...{
            SizedBox(
              width: labelSliderWidth,
              child: Text(varA[idx].toStringAsFixed(2)),
            ),
          },
          SizedBox(
            width: screenWidth * 0.23,
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
                      child: Icon(
                        Icons.adjust,
                        size: 7,
                      )),
                ),
              ),
              tooltip: FlutterSliderTooltip(
                disabled: true,
              ),
              values: [varA[idx] * 10000],
              max: 1500,
              min: 0,
              onDragging: (handlerIndex, lowerValue, upperValue) {
                varA[idx] = lowerValue / 10000;
                aBufView[idx] = varA[idx];
                changeNeuronSimulatorParameters();

                setState(() {});
              },
            ),
          ),
          if (idx == 0) ...{Text(varA[idx].toStringAsFixed(2))},
        ],
      ),
      const Text("b: sensitivity of fluctuations"),
      Row(
        children: [
          if (idx == 1) ...{
            SizedBox(
              width: labelSliderWidth,
              child: Text(varB[idx].toStringAsFixed(2)),
            ),
          },
          SizedBox(
            width: screenWidth * 0.23,
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
                      child: Icon(
                        Icons.adjust,
                        size: 7,
                      )),
                ),
              ),
              tooltip: FlutterSliderTooltip(
                disabled: true,
              ),
              values: [varB[idx] * 10000],
              max: 5000,
              min: 0,
              onDragging: (handlerIndex, lowerValue, upperValue) {
                varB[idx] = lowerValue / 10000;
                bBufView[idx] = varB[idx];
                changeNeuronSimulatorParameters();

                setState(() {});
              },
            ),
          ),
          if (idx == 0) ...{Text(varB[idx].toStringAsFixed(2))},
        ],
      ),
      const Text("c: after-spike reset value"),
      Row(
        children: [
          if (idx == 1) ...{
            SizedBox(
              width: labelSliderWidth,
              child: Text(varC[idx].toStringAsFixed(0)),
            ),
          },
          SizedBox(
            width: screenWidth * 0.23,
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
                      child: Icon(
                        Icons.adjust,
                        size: 7,
                      )),
                ),
              ),
              tooltip: FlutterSliderTooltip(
                disabled: true,
              ),
              values: [varC[idx] * 10000],
              max: 0,
              min: -1000000,
              onDragging: (handlerIndex, lowerValue, upperValue) {
                varC[idx] = (lowerValue / 10000).floor();
                cBufView[idx] = varC[idx];
                changeNeuronSimulatorParameters();

                setState(() {});
              },
            ),
          ),
          if (idx == 0) ...{
            Text(varC[idx].toStringAsFixed(0)),
          },
        ],
      ),
      const Text("d: after-spike inhibition"),
      Row(
        children: [
          if (idx == 1) ...{
            SizedBox(
              width: labelSliderWidth,
              child: Text(varD[idx].toStringAsFixed(0)),
            ),
          },
          SizedBox(
            width: screenWidth * 0.23,
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
                      child: Icon(
                        Icons.adjust,
                        size: 7,
                      )),
                ),
              ),
              tooltip: FlutterSliderTooltip(
                disabled: true,
              ),
              values: [varD[idx] * 10000],
              max: 100000,
              min: 0,
              onDragging: (handlerIndex, lowerValue, upperValue) {
                varD[idx] = (lowerValue / 10000).floor();
                dBufView[idx] = varD[idx];
                changeNeuronSimulatorParameters();

                setState(() {});
              },
            ),
          ),
          if (idx == 0) ...{
            Text(varD[idx].toStringAsFixed(0)),
          },
        ],
      ),
      const Text("i: input noise"),
      Row(
        children: [
          if (idx == 1) ...{
            SizedBox(
              width: labelSliderWidth,
              child: Text(varI[idx].toStringAsFixed(0)),
            ),
          },
          SizedBox(
            width: screenWidth * 0.23,
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
                      child: Icon(
                        Icons.adjust,
                        size: 7,
                      )),
                ),
              ),
              tooltip: FlutterSliderTooltip(
                disabled: true,
              ),
              values: [varI[idx] * 10000],
              max: 200000,
              min: 0,
              onDragging: (handlerIndex, lowerValue, upperValue) {
                varI[idx] = (lowerValue / 10000).floor();
                iBufView[idx] = varI[idx];
                changeNeuronSimulatorParameters();

                setState(() {});
              },
            ),
          ),
          if (idx == 0) ...{
            Text(varI[idx].toStringAsFixed(0)),
            const Padding(padding: EdgeInsets.only(right: 10)),
          },
        ],
      ),
      const Text("w: synaptic strength"),
      Row(
        children: [
          if (idx == 1) ...{
            SizedBox(
              width: labelSliderWidth,
              child: Text(
                varW[idx].toStringAsFixed(0),
              ),
            ),
          },
          SizedBox(
            width: screenWidth * 0.23,
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
                      child: Icon(
                        Icons.adjust,
                        size: 7,
                      )),
                ),
              ),
              tooltip: FlutterSliderTooltip(
                disabled: true,
              ),
              values: [varW[idx] * 10000],
              max: 300000,
              min: 0,
              onDragging: (handlerIndex, lowerValue, upperValue) {
                varW[idx] = (lowerValue / 10000);
                wBufView[idx] = varW[idx];
                changeNeuronSimulatorParameters();

                setState(() {});
              },
            ),
          ),
          if (idx == 0) ...{
            Text(varW[idx].toStringAsFixed(0)),
          },
        ],
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      // appBar: AppBar(
      //   title: Text(widget.title),
      // ),
      body: Column(
        children: [
          const Center(
            child: Text(
              "Two Neuron Simulator",
              style: TextStyle(fontSize: 25),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              SizedBox(
                width: screenWidth * 0.3,
                child: Column(
                  children: sideWidget(0, screenWidth),
                ),
              ),
              SizedBox(
                width: screenWidth * 0.4,
                child: Column(
                  children: [
                    SizedBox(
                      width: 400,
                      height: 400,
                      child: ValueListenableBuilder(
                        valueListenable: spikingFlags,
                        builder: (context, value, child) {
                          // print("1.5----- Firing Flags ");
                          int firingFlags = value;
                          // print(firingFlags);
                          // if (firingFlags[0]== 1 && firingFlags[1]==1){
                          if (firingFlags >= 3000) {
                            return neuronActive12;
                          } else
                          // if (firingFlags[0]== 1){
                          if (firingFlags >= 1000 && firingFlags < 2000) {
                            // print("2----- neuron circle should redraw");
                            return neuronActive1;
                          } else
                          // if (firingFlags[1]==1){
                          if (firingFlags >= 2000 && firingFlags < 3000) {
                            return neuronActive2;
                          } else {
                            return neuronActive0;
                          }
                        },
                      ),
                    ),
                    SizedBox(
                      width: screenWidth * 0.4,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              if (isPlaying == 1) {
                                isPlaying = -1;
                              } else {
                                isPlaying = 1;
                              }
                              nativec.changeIsPlayingProcess(isPlaying);
                            },
                            child: isPlaying == -1
                                ? const Text("Play")
                                : const Text("Pause"),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton(
                              onPressed: () {
                                // if (chartGain-1>0)
                                // levelMedian*=2;
                                chartGain /= 2;
                                // print("chartGain");
                                // print(chartGain);
                              },
                              child: const Text("+")),
                          const SizedBox(width: 10),
                          ElevatedButton(
                              onPressed: () {
                                // if (chartGain+1<=20)
                                // levelMedian/=2;
                                chartGain *= 2;
                                // print("chartGain");
                                // print(chartGain);
                              },
                              child: const Text("-"))
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: screenWidth * 0.3,
                child: Column(
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
                    decoration:
                        BoxDecoration(border: Border.all(color: Colors.black)),
                    width: constraints.maxWidth,
                    height: constraints.maxHeight,
                    child: Column(
                      children: [
                        PolygonWaveform(
                          width: constraints.maxWidth,
                          activeColor: Colors.black,
                          inactiveColor: Colors.black,
                          height: constraints.maxHeight / 2 - 1,
                          gain: chartGain,
                          channelIdx: 0,
                          channelActive: 0,
                          levelMedian: levelMedian,
                          strokeWidth: 1.0,
                          // samples: Nativec.canvasBufferBytes1.sublist(0,600),
                          samples: Nativec.canvasBufferBytes1,
                          // samples: Float64List(0),
                          // samples: Nativec.canvasBufferBytes2,
                          // samples: canvasBufferBytes[0],
                          maxDuration: const Duration(seconds: 10),
                          elapsedDuration: const Duration(seconds: 10),
                          eventMarkersPosition: [
                            positionsBufView[0].toDouble()
                          ],
                          // eventMarkersPosition: [0],
                        ),
                        PolygonWaveform(
                          width: constraints.maxWidth,
                          activeColor: Colors.black,
                          inactiveColor: Colors.black,
                          height: constraints.maxHeight / 2 - 1,
                          gain: chartGain,
                          channelIdx: 1,
                          channelActive: 0,
                          levelMedian: levelMedian,
                          strokeWidth: 1.0,
                          // samples: Nativec.canvasBufferBytes2,
                          // samples: Float64List(0),
                          samples: Nativec.canvasBufferBytes2,
                          // samples: canvasBufferBytes[1],
                          maxDuration: const Duration(seconds: 10),
                          elapsedDuration: const Duration(seconds: 10),
                          eventMarkersPosition: [
                            positionsBufView[0].toDouble()
                          ],
                        ),
                      ],
                    ));
              }),
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
      nativec.changeNeuronSimulatorProcess(aBuf, bBuf, cBuf, dBuf, iBuf, wBuf,
          positionsBuf, wBuf, level, neuronSize, envelopeSize, bufferSize, 1);
    });
  }
}
