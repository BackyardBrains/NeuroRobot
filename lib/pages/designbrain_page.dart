import 'dart:async';
// import 'dart:convert';
import 'dart:ffi' as ffi;
import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';
import 'package:fialogs/fialogs.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mjpeg/flutter_mjpeg.dart';
import 'package:gesture_x_detector/gesture_x_detector.dart';
import 'package:infinite_canvas/infinite_canvas.dart';
import 'package:metooltip/metooltip.dart';
import 'package:native_opencv/native_opencv.dart';
import 'package:native_opencv/nativec.dart';
// import 'package:nativec/allocation.dart';
// import 'package:nativec/nativec.dart';
import 'package:neurorobot/bloc/bloc.dart';
import 'package:neurorobot/utils/Allocator.dart';
import 'package:neurorobot/utils/ProtoNeuron.dart';
import 'package:neurorobot/utils/Simulations.dart';
import 'package:neurorobot/utils/SingleCircle.dart';
import 'package:neurorobot/utils/Vision.dart';
import 'package:neurorobot/utils/WaveWidget.dart';
// import 'package:opencv_ffi/opencv_ffi.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:neurorobot/components/right_toolbar.dart';
import '../dialogs/info_dialog.dart';

// import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../utils/SingleSquare.dart';
import '../utils/WebSocket.dart';
// import 'package:opencv_ffi/src/generated/opencv_ffi_bindings.dart' as ocv;

// String _getPath() {
//   final cjsonExamplePath = Directory.current.absolute.path;
//   var path = p.join(cjsonExamplePath, 'opencv_ffi/');
//   if (Platform.isMacOS) {
//     path = p.join(path, 'libopencv_ffi.dylib');
//   } else if (Platform.isWindows) {
//     path = p.join(path, 'Debug', 'opencv_ffi.dll');
//   } else {
//     path = p.join(path, 'libopencv_ffi.so');
//   }
//   return path;
// }

class DesignBrainPage extends StatefulWidget {
  DesignBrainPage({super.key});
  @override
  State<DesignBrainPage> createState() => _DesignBrainPageState();
}

bool isCheckingColor = false;

class _DesignBrainPageState extends State<DesignBrainPage> {
  // WEB SOCKET
  static late SendPort isolateWritePort;
  bool isIsolateWritePortInitialized = false;
  late ReceivePort writePort = ReceivePort();

  // SIMULATION SECTION
  List<String> neuronTypes = [];
  static int neuronSize = 10;
  static const int motorCommandsLength = 6 * 2;
  static const int maxPosBuffer = 220;
  int epochs = 30;

  late Nativec nativec;
  // static ffi.Pointer<ffi.Uint32> npsBuf =
  //     allocate<ffi.Uint32>(count: 2, sizeOfType: ffi.sizeOf<ffi.Uint32>());

  // static ffi.Pointer<ffi.Int16> neuronCircleBuf = allocate<ffi.Int16>(
  //     count: maxPosBuffer, sizeOfType: ffi.sizeOf<ffi.Int16>());

  // static ffi.Pointer<ffi.Int16> positionsBuf =
  //     allocate<ffi.Int16>(count: 1, sizeOfType: ffi.sizeOf<ffi.Int16>());

  // static ffi.Pointer<ffi.Double> aBuf = allocate<ffi.Double>(
  //     count: maxPosBuffer, sizeOfType: ffi.sizeOf<ffi.Double>());

  // static ffi.Pointer<ffi.Double> bBuf = allocate<ffi.Double>(
  //     count: maxPosBuffer, sizeOfType: ffi.sizeOf<ffi.Double>());

  // static ffi.Pointer<ffi.Int16> cBuf = allocate<ffi.Int16>(
  //     count: maxPosBuffer, sizeOfType: ffi.sizeOf<ffi.Int16>());

  // static ffi.Pointer<ffi.Int16> dBuf = allocate<ffi.Int16>(
  //     count: maxPosBuffer, sizeOfType: ffi.sizeOf<ffi.Int16>());

  // static ffi.Pointer<ffi.Double> iBuf = allocate<ffi.Double>(
  //     count: maxPosBuffer, sizeOfType: ffi.sizeOf<ffi.Double>());

  // static ffi.Pointer<ffi.Double> wBuf = allocate<ffi.Double>(
  //     count: maxPosBuffer, sizeOfType: ffi.sizeOf<ffi.Double>());

  // static ffi.Pointer<ffi.Double> connectomeBuf = allocate<ffi.Double>(
  //     count: maxPosBuffer * maxPosBuffer, sizeOfType: ffi.sizeOf<ffi.Double>());

  static int frameQVGASize = 320 * 240;
  late ffi.Pointer<ffi.Uint8> ptrFrame;
  static ffi.Pointer<ffi.Uint8> ptrMaskedFrame = allocate<ffi.Uint8>(
      count: frameQVGASize, sizeOfType: ffi.sizeOf<ffi.Uint8>());

  static ffi.Pointer<ffi.Uint8> ptrLowerB =
      allocate<ffi.Uint8>(count: 3, sizeOfType: ffi.sizeOf<ffi.Uint8>());
  static ffi.Pointer<ffi.Uint8> ptrUpperB =
      allocate<ffi.Uint8>(count: 3, sizeOfType: ffi.sizeOf<ffi.Uint8>());

  late ffi.Pointer<ffi.Uint32> npsBuf;
  late ffi.Pointer<ffi.Int16> neuronCircleBuf;
  late ffi.Pointer<ffi.Int16> positionsBuf;
  late ffi.Pointer<ffi.Double> aBuf;
  late ffi.Pointer<ffi.Double> bBuf;
  late ffi.Pointer<ffi.Int16> cBuf;
  late ffi.Pointer<ffi.Int16> dBuf;
  late ffi.Pointer<ffi.Double> iBuf;
  late ffi.Pointer<ffi.Double> wBuf;
  late ffi.Pointer<ffi.Int16> visPrefsBuf;
  late ffi.Pointer<ffi.Double> connectomeBuf;
  late ffi.Pointer<ffi.Double> motorCommandBuf;
  late ffi.Pointer<ffi.Double> neuronContactsBuf;

  // NATIVE

  late Uint32List npsBufView = Uint32List(0);
  late Int16List neuronCircleBridge = Int16List(0);
  late Int16List positionsBufView = Int16List(0);
  late Float64List aBufView = Float64List(0);
  late Float64List bBufView = Float64List(0);
  late Int16List cBufView = Int16List(0);
  late Int16List dBufView = Int16List(0);
  late Float64List iBufView = Float64List(0);
  late Float64List wBufView = Float64List(0);
  late Int16List visPrefsBufView = Int16List(0);
  late Float64List connectomeBufView = Float64List(0);
  static Float64List motorCommandBufView = Float64List(0);
  late Float64List neuronContactsBufView = Float64List(0);

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
  // SQUARE
  List<CustomPaint> squareInactiveCircles = [];
  List<CustomPaint> squareActiveCircles = [];
  // Float64List canvasBufferBytes = Float64List(6000);
  ValueNotifier<int> waveRedraw = ValueNotifier(0);

  int isPlaying = 1;
  double levelMedian = 30;
  double chartGain = 0.67;

  bool isInitialized = false;

  late ProtoNeuron protoNeuron;
  bool isSelected = false;
  int selectedIdx = 0;
  ValueNotifier<int> redrawNeuronLine = ValueNotifier(0);

  late WaveWidget waveWidget;

  late Mjpeg mjpegComponent;

  bool isEmergencyPause = false;
  bool isDrawTail = false;
  int prevEdgesLength = 0;
  late InfiniteCanvasNode prevSelectedNeuron;
  late InfiniteCanvasEdge prevSelectedEdge;
  bool isPrevSelectedEdge = false;

  late InfiniteCanvasNode tailNode;
  late InfiniteCanvasNode triangleNode;
  late InfiniteCanvasNode rectangleNode;
  late InfiniteCanvasNode circleNode;

  bool isPanningCanvas = false;

  Paint circleColor = Paint()..color = Colors.red;
  Paint triangleColor = Paint()..color = Colors.green;
  Paint rectangleColor = Paint()..color = Colors.blue;

  Paint neuronColor = Paint()..color = Colors.grey;
  Paint tailColor = Paint()..color = Colors.green;

  int gapTailX = 0;
  int gapTailY = 40;

  double prevMouseX = 0.0, prevMouseY = 0.0;

  int circleNeuronStartIndex = 11;
  int normalNeuronStartIdx = 9;
  int allNeuronStartIdx = 2;

  Uint8List dataMaskedImage = Uint8List(0);

  int bufPositionCount = 1;
  
  late ImagePreprocessor processor;
  
  String httpdStream = "http://192.168.4.1:81/stream";
  
  late Isolate webSocket;
  
  bool isSimulationCallbackAttached = false;

  void runNativeC() {
    const level = 1;
    const envelopeSize = 200;
    const bufferSize = 2000;
    nativec.initialize();
    print("motorCommandBufView.length");
    print(motorCommandBufView.length);
    // print(visPrefsBufView);
    nativec.changeNeuronSimulatorProcess(
        aBuf,
        bBuf,
        cBuf,
        dBuf,
        iBuf,
        wBuf,
        connectomeBuf,
        level,
        neuronSize,
        envelopeSize,
        bufferSize,
        1,
        visPrefsBuf,
        motorCommandBuf,
        neuronContactsBuf);
  }

  void initMemoryAllocation() {
    npsBuf =
        allocate<ffi.Uint32>(count: 2, sizeOfType: ffi.sizeOf<ffi.Uint32>());
    neuronCircleBuf = allocate<ffi.Int16>(
        count: maxPosBuffer, sizeOfType: ffi.sizeOf<ffi.Int16>());
    positionsBuf = allocate<ffi.Int16>(
        count: bufPositionCount, sizeOfType: ffi.sizeOf<ffi.Int16>());
    aBuf = allocate<ffi.Double>(
        count: maxPosBuffer, sizeOfType: ffi.sizeOf<ffi.Double>());
    bBuf = allocate<ffi.Double>(
        count: maxPosBuffer, sizeOfType: ffi.sizeOf<ffi.Double>());
    cBuf = allocate<ffi.Int16>(
        count: maxPosBuffer, sizeOfType: ffi.sizeOf<ffi.Int16>());
    dBuf = allocate<ffi.Int16>(
        count: maxPosBuffer, sizeOfType: ffi.sizeOf<ffi.Int16>());
    iBuf = allocate<ffi.Double>(
        count: maxPosBuffer, sizeOfType: ffi.sizeOf<ffi.Double>());
    wBuf = allocate<ffi.Double>(
        count: maxPosBuffer, sizeOfType: ffi.sizeOf<ffi.Double>());

    visPrefsBuf = allocate<ffi.Int16>(
        count: maxPosBuffer * maxPosBuffer,
        sizeOfType: ffi.sizeOf<ffi.Int16>());
    connectomeBuf = allocate<ffi.Double>(
        count: maxPosBuffer * maxPosBuffer,
        sizeOfType: ffi.sizeOf<ffi.Double>());
    neuronContactsBuf = allocate<ffi.Double>(
        count: maxPosBuffer * maxPosBuffer,
        sizeOfType: ffi.sizeOf<ffi.Double>());

    motorCommandBuf = allocate<ffi.Double>(
        count: motorCommandsLength, sizeOfType: ffi.sizeOf<ffi.Double>());
  }

  void initNativeC() {
    double a = 0.02;
    double b = 0.18;
    int c = -65;
    int d = 2;
    double i = 5.0;
    double w = 2.0;

    // int neuronSizeType = neuronSize;
    if (kIsWeb) {
      // aBufView  = Float64List(neuronSize);
      // bBufView  = Float64List(neuronSize);
      // cBufView  = Int16List(neuronSize);
      // dBufView  = Int16List(neuronSize);
      // iBufView  = Float64List(neuronSize);
      // wBufView  = Float64List(neuronSize);
      // positionsBufView  = Int16List(neuronSize);
      // connectomeBufView  = Float64List(neuronSize*neuronSize);
    } else {
      nativec = Nativec();
      nativec.passPointers(
          Nativec.canvasBuffer1!, positionsBuf, neuronCircleBuf, npsBuf);
      aBufView = aBuf.asTypedList(neuronSize);
      bBufView = bBuf.asTypedList(neuronSize);
      cBufView = cBuf.asTypedList(neuronSize);
      dBufView = dBuf.asTypedList(neuronSize);
      iBufView = iBuf.asTypedList(neuronSize);
      wBufView = wBuf.asTypedList(neuronSize);
      npsBufView = npsBuf.asTypedList(2);
      neuronCircleBridge = neuronCircleBuf.asTypedList(neuronSize);
      positionsBufView = positionsBuf.asTypedList(bufPositionCount);
      connectomeBufView = connectomeBuf.asTypedList(neuronSize * neuronSize);
      visPrefsBufView = visPrefsBuf.asTypedList(neuronSize * neuronSize);
      motorCommandBufView = motorCommandBuf.asTypedList(motorCommandsLength);
      neuronContactsBufView =
          neuronContactsBuf.asTypedList(neuronSize * neuronSize);

      if (!isSimulationCallbackAttached){
        isSimulationCallbackAttached = true;
        nativec.simulationCallback(updateFromSimulation);
      }
    }
    aBufView.fillRange(0, neuronSize, a);
    bBufView.fillRange(0, neuronSize, b);
    cBufView.fillRange(0, neuronSize, c);
    dBufView.fillRange(0, neuronSize, d);
    iBufView.fillRange(0, neuronSize, i);
    wBufView.fillRange(0, neuronSize, w);
    positionsBufView.fillRange(0, 1, 0);
    connectomeBufView.fillRange(0, neuronSize * neuronSize, 0.0);
    visPrefsBufView.fillRange(0, neuronSize * neuronSize, -1);

    neuronContactsBufView.fillRange(0, neuronSize * neuronSize, 0);
    motorCommandBufView.fillRange(0, motorCommandsLength, 0.0);

    print("neuronSize * neuronSize");
    print(neuronSize * neuronSize);

    squareActiveCircles = List<CustomPaint>.generate(neuronSize, (int idx) {
      return CustomPaint(
        painter: SingleSquare(isActive: true),
        willChange: false,
        isComplex: false,
      );
    });
    squareInactiveCircles = List<CustomPaint>.generate(neuronSize, (int idx) {
      return CustomPaint(
        painter: SingleSquare(isActive: false),
        willChange: false,
        isComplex: false,
      );
    });

    neuronSpikeFlags =
        List<ValueNotifier<int>>.generate(neuronSize, (_) => ValueNotifier(0));
    neuronCircleKeys = List<GlobalKey>.generate(neuronSize,
        (i) => GlobalKey(debugLabel: "neuronWidget${i.toString()}"));
    neuronActiveCircles = List<CustomPaint>.generate(neuronSize, (int idx) {
      return CustomPaint(
        painter: SingleCircle(isActive: true),
        willChange: false,
        isComplex: false,
      );
    });

    neuronInactiveCircles = List<CustomPaint>.generate(neuronSize, (int idx) {
      return CustomPaint(
        painter: SingleCircle(isActive: false),
        willChange: false,
        isComplex: false,
      );
    });

    WaveWidget.positionsBufView = positionsBufView;

    if (kIsWeb) {
    } else {
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

  Map mapConnectome = {}; 
  Map mapSensoryNeuron = {}; // vis prefs
  Map mapContactsNeuron = {};

  List<UniqueKey> neuronsKey = [];
  List<UniqueKey> axonsKey = [];

  Offset constraintOffsetTopLeft = const Offset(300, 170);
  Offset constraintOffsetTopRight = const Offset(500, 170);
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
      child: const SizedBox(
        width: 0,
        height: 0,
      ));

  InfiniteCanvasNode nodeDistanceSensor = InfiniteCanvasNode(
    key: UniqueKey(),
    value: 0,
    allowMove: false,
    allowResize: false,
    offset: const Offset(395, 150),
    // offset: const Offset(852.0 / 2, 150),
    size: const Size(20, 20),
    child: Container(width: 15, height: 15, color: Colors.black),
  );

  InfiniteCanvasNode nodeLeftEyeSensor = InfiniteCanvasNode(
    key: UniqueKey(),
    value: 1,
    allowMove: false,
    allowResize: false,
    offset: const Offset(320, 150),
    size: const Size(20, 20),
    child: Container(width: 15, height: 15, color: Colors.black),
  );
  InfiniteCanvasNode nodeRightEyeSensor = InfiniteCanvasNode(
    key: UniqueKey(),
    value: 2,
    allowMove: false,
    allowResize: false,
    offset: const Offset(470, 150),
    size: const Size(20, 20),
    child: Container(width: 15, height: 15, color: Colors.black),
  );

  InfiniteCanvasNode nodeMicrophoneSensor = InfiniteCanvasNode(
    key: UniqueKey(),
    value: 3,
    allowMove: false,
    allowResize: false,
    offset: const Offset(267, 217),
    size: const Size(20, 20),
    child: Container(width: 15, height: 15, color: Colors.black),
  );
  InfiniteCanvasNode nodeSpeakerSensor = InfiniteCanvasNode(
    key: UniqueKey(),
    value: 4,
    allowMove: false,
    allowResize: false,
    offset: const Offset(523, 217),
    size: const Size(20, 20),
    child: Container(width: 15, height: 15, color: Colors.black),
  );

  InfiniteCanvasNode nodeLeftMotorForwardSensor = InfiniteCanvasNode(
    key: UniqueKey(),
    value: 5,
    allowMove: false,
    allowResize: false,
    offset: const Offset(243, 310),
    size: const Size(20, 20),
    child: Container(width: 15, height: 15, color: Colors.black),
  );
  InfiniteCanvasNode nodeRightMotorForwardSensor = InfiniteCanvasNode(
    key: UniqueKey(),
    value: 6,
    allowMove: false,
    allowResize: false,
    offset: const Offset(547, 310),
    size: const Size(20, 20),
    child: Container(width: 15, height: 15, color: Colors.black),
  );

  InfiniteCanvasNode nodeLeftMotorBackwardSensor = InfiniteCanvasNode(
    key: UniqueKey(),
    value: 7,
    allowMove: false,
    allowResize: false,
    offset: const Offset(240, 405),
    size: const Size(20, 20),
    child: Container(width: 15, height: 15, color: Colors.black),
  );
  InfiniteCanvasNode nodeRightMotorBackwardSensor = InfiniteCanvasNode(
    key: UniqueKey(),
    value: 8,
    allowMove: false,
    allowResize: false,
    offset: const Offset(550, 405),
    size: const Size(20, 20),
    child: Container(width: 15, height: 15, color: Colors.black),
  );
  double constraintBrainLeft = 300.0;
  double constraintBrainRight = 500.0;
  double constraintBrainTop = 170.0;
  double constraintBrainBottom = 430.0;

  double prevScreenWidth = 800.0;
  double prevScreenHeight = 600.0;
  double screenWidth = 800.0;
  double screenHeight = 600.0;
  double safePadding = 0.0;
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
  void dispose() {
    super.dispose();
    print("DISPOSEEE");
    freeUsedMemory();
  }

  void freeUsedMemory() {
    freeMemory(npsBuf);
    freeMemory(neuronCircleBuf);
    freeMemory(positionsBuf);
    freeMemory(aBuf);
    freeMemory(bBuf);
    freeMemory(cBuf);
    freeMemory(dBuf);
    freeMemory(iBuf);
    freeMemory(wBuf);
    freeMemory(connectomeBuf);
    freeMemory(motorCommandBuf);
    freeMemory(visPrefsBuf);
    freeMemory(Nativec.canvasBuffer1);
    // freeMemory(nativec.canvasBuffer2);
  }

  Future<String> startWebSocket() async {
    // const String webSocketLink = 'ws://192.168.4.1:81';
    const String webSocketLink = 'ws://192.168.4.1/ws';
    writePort = ReceivePort();
    // try{
    //   webSocket.kill();
    // }catch(err){
    //   print("err");
    //   print(err);
    // }

    webSocket = await Isolate.spawn(
      createWebSocket,
      [writePort.sendPort, webSocketLink],
    );

    // writePort.sendPort.send(message)
    writePort.listen((message) async {
      if (message is SendPort) {
        isolateWritePort = message;
        isIsolateWritePortInitialized = true;
        // Timer.periodic(const Duration(milliseconds: 300), (timer) {
        //   isolateWritePort.send("test from flutter");
        // });
      } else if (message == "DISCONNECTED") {
        if (isPlayingMenu) {
          isIsolateWritePortInitialized = false;
          writePort.close();
          alertDialog(
            context,
            "NeuroRobot Connection Loss",
            "Connection with NeuroRobot was disconnected, please reconnect again",
            positiveButtonText: "OK",
            positiveButtonAction: () {
              isPlayingMenu = false;
              setState(() {});
            },
            hideNeutralButton: true,
            closeOnBackPress: false,
          );
        }
      } else {}
    });

    // isolateWritePort.send();

    return "";
  }

  @override
  void initState() {
    super.initState();

    print("INIT STATEEE");
    // Future.delayed(const Duration(milliseconds: 700), () {
    try {
      initMemoryAllocation();
      initNativeC();
      // final ocsvlib = ocv.OpenCVBindings(ffi.DynamicLibrary.open(_getPath()));
      // testColorCV();

      Uint8List lowerB = ptrLowerB.asTypedList(3);
      Uint8List upperB = ptrUpperB.asTypedList(3);

      //RED
      lowerB[0] = 0;
      lowerB[1] = 43;
      lowerB[2] = 46;
      upperB[0] = 0;
      upperB[1] = 255;
      upperB[2] = 255;

      // GREEN
      lowerB[0] = 36;
      lowerB[1] = 25;
      lowerB[2] = 25;
      upperB[0] = 86;
      upperB[1] = 255;
      upperB[2] = 255;

      rootBundle.load("assets/bg/ObjectColorRange.jpeg").then((raw) async {
        Uint8List redBg = raw.buffer.asUint8List();
        try {
          // freeMemory(ptrFrame);
          // freeMemory(ptrMaskedFrame);
        } catch (err) {}

        print(redBg.length);
        ptrFrame = allocate<ffi.Uint8>(
            count: redBg.length, sizeOfType: ffi.sizeOf<ffi.Uint8>());
        if (!isCheckingColor) {
          // isCheckingColor = true;

          // print('abc');
          // Directory appDocumentsDir = await getTemporaryDirectory();
          // String path = appDocumentsDir.path;
          // File file = File('$path/bg.png');
          // print('$path/bg.png');
          // file.writeAsBytesSync(redBg, mode: FileMode.write);
          // CHECK COLOR FIRST TIME
          Future.delayed(const Duration(milliseconds: 300), () {
            // checkColorCV(redBg, lowerB, upperB).then((flag){
            //   if (flag){// forward or backward

            //   }

            //   // double r_torque = motorCommandBufView[0];
            //   // double r_dir = motorCommandBufView[1];
            //   // if (r_dir == 2){
            //   //   r_dir = -1;
            //   // }

            //   // double l_torque = motorCommandBufView[2];
            //   // double l_dir = motorCommandBufView[3];
            //   // if (l_dir == 2){
            //   //   l_dir = -1;
            //   // }

            //   // String message = "l:" + (l_torque * l_dir).toString() +";r:"+(r_torque * r_dir).toString()+";";

            //   isCheckingColor = false;
            // });
          });
        }
      });
      // });
    } catch (err) {
      print("err Memory Allocation");
      print(err);
    }

    initNeuronType();


    processor = ImagePreprocessor();
    processor.isRunning = true;
    mjpegComponent = Mjpeg(
      stream: httpdStream,
      // stream: "http://192.168.1.4:8081/",
      preprocessor: processor,
      isLive: true,
      fit: BoxFit.fill,
      timeout: const Duration(seconds: 60),
    );

    Timer.periodic(const Duration(milliseconds: 70), (timer) {
      if (isSelected) {
        // print("redraw");
        // print(Nativec.canvasBufferBytes1);
        waveRedraw.value = Random().nextInt(10000);
      }
      if (isPlayingMenu) {
        // for (int i = circleNeuronStartIndex - allNeuronStartIdx; i < neuronSize; i++) {
        for (int i = normalNeuronStartIdx; i < neuronSize; i++) {
          int neuronIndex = i;
          if (neuronCircleBridge[i] == 1) {
            protoNeuron.circles[neuronIndex].isSpiking = 1;
            neuronSpikeFlags[neuronIndex].value = Random().nextInt(10000);
          } else {
            try {
              protoNeuron.circles[neuronIndex].isSpiking = -1;
              neuronSpikeFlags[neuronIndex].value = Random().nextInt(10000);
            } catch (err) {
              print(err);
            }
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    screenWidth = MediaQuery.of(context).size.width;
    screenHeight = MediaQuery.of(context).size.height;
    safePadding = MediaQuery.of(context).padding.right;
    // Future.delayed(const Duration(milliseconds: 2000), (){
    //   repositionSensoryNeuron();
    // });

    if (!isInitialized && screenWidth > screenHeight) {
      initCanvas();
      isInitialized = true;

      if (!kIsWeb) {
        // WaveWidget.positionsBufView = positionsBufView;
      }
      waveWidget = WaveWidget(
          valueNotifier: waveRedraw,
          chartGain: chartGain,
          levelMedian: levelMedian,
          screenHeight: screenHeight,
          screenWidth: screenWidth);
      // testColorCV();
    }

    // if (Platform.isAndroid || Platform.isIOS) {
    //   prevScreenWidth = screenWidth;
    //   prevScreenHeight = screenHeight;
    // } else
    if (isInitialized) {
      if (prevScreenWidth != screenWidth) {
        isResizingFlag = true;
      }
      if (prevScreenHeight != screenHeight) {
        isResizingFlag = true;
      }
    }
    // }

    if (isResizingFlag) {
      // print("isResizingFlag");
      viewPortNode.update(offset: Offset(screenWidth, screenHeight));
      controller.getNode(viewportKey)?.offset =
          Offset(screenWidth, screenHeight);
      int idx = 0;
      // double scaleX = screenWidth / prevScreenWidth;
      double scaleX = screenWidth / prevScreenWidth;
      if (Platform.isIOS || Platform.isAndroid) {
        scaleX = 1;
      }
      double scaleY = screenHeight / prevScreenHeight;

      constraintOffsetTopLeft = constraintOffsetTopLeft.scale(scaleX, scaleY);
      constraintOffsetTopRight = constraintOffsetTopRight.scale(scaleX, scaleY);
      constraintOffsetBottomRight =
          constraintOffsetBottomRight.scale(scaleX, scaleY);
      constraintOffsetBottomLeft =
          constraintOffsetBottomLeft.scale(scaleX, scaleY);

      constraintBrainLeft = constraintOffsetTopLeft.dx;
      constraintBrainRight = constraintOffsetTopRight.dx;
      constraintBrainTop = constraintOffsetTopLeft.dy;
      constraintBrainBottom = constraintOffsetBottomLeft.dy;

      for (var element in controller.nodes) {
        if (idx > 1) {
          element.offset = element.offset.scale(scaleX, scaleY);

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
    if (isPlayingMenu) {
      // for (int i = circleNeuronStartIndex - allNeuronStartIdx; i < neuronSize; i++) {
      for (int i = 0; i < normalNeuronStartIdx; i++) {
        SingleNeuron neuron = protoNeuron.circles[i];
        widgets.add(Positioned(
          top: neuron.centerPos.dy - 10,
          left: neuron.centerPos.dx - 10,
          child: SizedBox(
            key: neuronCircleKeys[i],
            child: ValueListenableBuilder(
              valueListenable: neuronSpikeFlags[i],
              builder: ((context, value, child) {
                if (protoNeuron.circles[i].isSpiking == -1) {
                  // return squareInactiveCircles[i];
                  return const SizedBox();
                } else {
                  return squareActiveCircles[i];
                }
              }),
            ),
          ),
        ));
      }
      for (int i = normalNeuronStartIdx; i < neuronSize; i++) {
        SingleNeuron neuron = protoNeuron.circles[i];
        widgets.add(Positioned(
          top: neuron.centerPos.dy,
          left: neuron.centerPos.dx,
          child: SizedBox(
            key: neuronCircleKeys[i],
            child: ValueListenableBuilder(
              valueListenable: neuronSpikeFlags[i],
              builder: ((context, value, child) {
                if (protoNeuron.circles[i].isSpiking == -1) {
                  return neuronInactiveCircles[i];
                } else {
                  return neuronActiveCircles[i];
                }
              }),
            ),
          ),
        ));
      }
    }

    return Scaffold(
      floatingActionButton: FloatingActionButton(
          onPressed: () {
            isEmergencyPause = !isEmergencyPause;
            if (!isEmergencyPause) {
              rightToolbarCallback({"menuIdx": 7});
              Future.delayed(const Duration(milliseconds: 100), () {
                menuIdx = 0;
                controller.isInteractable = true;

                setState(() {});
              });
            } else {
              rightToolbarCallback({"menuIdx": 7});
              controller.isInteractable = true;
            }

            setState(() {});
          },
          child: !isEmergencyPause
              ? const Icon(Icons.play_arrow)
              : const Icon(Icons.pause)),
      body: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            child: Container(
              color: Colors.white,
              width: screenWidth,
              height: screenHeight,
              child: !isInitialized
                  ? const SizedBox()
                  : prepareWidget(
                      InfiniteCanvas(
                        backgroundBuilder: (ctx, r) {
                          // print("MediaQuery.of(context).screenWidth");
                          // print(screenWidth);
                          // print(screenHeight);
                          // print(r);

                          return Container(
                            color: Colors.white,
                            width: screenWidth,
                            height: screenHeight,
                            child: Image.asset(
                                width: screenWidth,
                                height: screenHeight,
                                // scale: screenWidth/800,
                                fit: BoxFit.contain,
                                // scale: density,
                                "assets/bg/bg1.0x.jpeg"),
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
            right: 10 + safePadding,
            top: 10,
            child: RightToolbar(
                key: GlobalKey(),
                menuIdx: menuIdx,
                callback: rightToolbarCallback),
          ),
          if (!(Platform.isIOS || Platform.isAndroid)) ...[
            Positioned(
              right: 90,
              bottom: 20,
              child: Card(
                surfaceTintColor: Colors.white,
                // surfaceTintColor: Colors.transparent,
                shadowColor: Colors.white,
                // color: Colors.transparent,
                child: Container(
                  color: Colors.transparent,
                  width: 129,
                  child: Row(
                    children: [
                      MeTooltip(
                        message: "Zoom Out",
                        preferOri: PreferOrientation.up,
                        child: ElevatedButton(
                          onPressed: () {
                            controller.zoomOut();
                          },
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              surfaceTintColor: Colors.white,
                              shadowColor: Colors.transparent
                              // shadowColor: Colors.white,
                              ),
                          child: const Text("-",
                              style: TextStyle(
                                  fontSize: 25, color: Color(0xFF4e4e4e))),
                        ),
                      ),
                      MeTooltip(
                        message: "Zoom In",
                        preferOri: PreferOrientation.up,
                        child: ElevatedButton(
                          onPressed: () {
                            controller.zoomIn();
                          },
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              surfaceTintColor: Colors.white,
                              shadowColor: Colors.transparent

                              // shadowColor: Colors.white,
                              ),
                          child: const Text("+",
                              style: TextStyle(
                                  fontSize: 25, color: Color(0xFF4e4e4e))),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ],
          if (isPlayingMenu) ...[
            Positioned(
              left: 50,
              top: 0,
              // child:Container(
              //   width:100,height:200,
              //   child: Mjpeg(
              //     stream: "http://192.168.4.1:81/stream",
              //     isLive: true,
              //   ),
              // )
              child: ClipRect(
                clipper: EyeClipper(
                    isLeft: true, width: screenWidth, height: screenHeight),
                child: mjpegComponent,
              ),
            ),
            Positioned(
              right: 80,
              top: 0,
              child: StreamBuilder<Uint8List>(
                  stream: mainBloc.imageStream,
                  builder: (context, snapshot) {
                    // print(snapshot.data);
                    if (snapshot.data == null) return Container();
                    return ClipRect(
                      clipper: EyeClipper(
                          isLeft: false,
                          width: screenWidth,
                          height: screenHeight),
                      child: Image.memory(
                        snapshot.data!,
                        gaplessPlayback: true,
                      ),
                    );
                  }),
            ),
          ],
          if (isPlayingMenu && isSelected) ...[
            Positioned(
              bottom: 0,
              left: 0,
              child: Container(
                margin: const EdgeInsets.all(10.0),
                decoration:
                    BoxDecoration(border: Border.all(color: Colors.black)),

                // color:Colors.red,
                height: screenHeight / 2 - 150,
                width: screenWidth - 20,
                // child: isSelected?waveWidget : const SizedBox(),
                child: waveWidget,
              ),
            ),
          ],
          ValueListenableBuilder(
              valueListenable: tooltipValueChange,
              builder: ((context, value, child) {
                return !isTooltipOverlay
                    ? Container()
                    : Positioned(
                        left: tooltipOverlayX - 20,
                        top: tooltipOverlayY - 50,
                        child: Container(
                            color: Colors.black,
                            padding: const EdgeInsets.all(5),
                            child: Text(tooltipOverlayMessage,
                                style: const TextStyle(color: Colors.white))),
                      );
              })),
          // Positioned(
          //   left: 825 / 2,
          //   top: 0,
          //   child: Container(
          //     width: 30,
          //     height: 30,
          //     color: Colors.green,
          //   ),
          // ),
          // Positioned(
          //   left:10,
          //   top:10,
          //   child: Image.memory(dataMaskedImage)
          // )
        ]..addAll(widgets),
      ),
    );
  }

  void allowMoveNodes() {
    int n = controller.nodes.length;
    for (int i = normalNeuronStartIdx + 2; i < n; i++) {
      controller.nodes[i].allowMove = true;
    }
  }

  void disallowMoveNodes() {
    int n = controller.nodes.length;
    for (int i = normalNeuronStartIdx + 2; i < n; i++) {
      controller.nodes[i].allowMove = false;
    }
  }

  void populateMatrix() {
    // populate connectome, neuroncontacts, and visual preferences
    int ctr = 0;

    for (int i = 0; i < neuronSize; i++) {
      LocalKey neuronFromKey = findNeuronByValue(i).key;
      for (int j = 0; j < neuronSize; j++) {
        LocalKey neuronToKey = findNeuronByValue(j).key;
        String connectionKey = "${neuronFromKey}_${neuronToKey}";

        // sensory neuron
        // print("visPrefsBufView.length");
        // print(visPrefsBufView.length);
        if (mapSensoryNeuron.containsKey(connectionKey)) {
          // print("mapSensoryNeuron");
          // print(mapSensoryNeuron[connectionKey]);
          visPrefsBufView[ctr] = mapSensoryNeuron[connectionKey];
        } else {
          visPrefsBufView[ctr] = -1;
        }

        // motor neuron
        if (mapContactsNeuron.containsKey(connectionKey)) {
          neuronContactsBufView[ctr] = mapContactsNeuron[connectionKey];
        } else {
          neuronContactsBufView[ctr] = 0;
        }

        // connectome
        if (mapConnectome.containsKey(connectionKey)) {
          connectomeBufView[ctr] = mapConnectome[connectionKey];
        } else {
          connectomeBufView[ctr] = 0;
        }

        ctr++;
      }
    }
  }

  void runSimulation() {
    // neuronSize = controller.nodes.length;
    initNativeC();
    print("neuronSize");
    print(neuronSize);
    List<Offset> pos = [];

    // Map<int,String> nodeKey = {};
    Map<String, int> nodeKey = {};
    int idx = 0;
    for (InfiniteCanvasNode node in controller.nodes) {
      if (idx >= allNeuronStartIdx) {
        pos.add(node.offset);
        nodeKey[node.key.toString()] = idx - allNeuronStartIdx;
        // nodeKey[idx] = node.key.toString();
      }
      idx++;
    }
    print("nodeKey");
    print(nodeKey);

    List<List<double>> connectomeMatrix = List<List<double>>.generate(
        neuronSize,
        (index) =>
            List<double>.generate(neuronSize, (index) => 0.0, growable: false),
        growable: false);
    controller.edges.forEach((edge) {
      // print("edge.from");
      // print(edge.from);
      // print(edge.to);
      int fromIdx = nodeKey[edge.from.toString()]!; // - allNeuronStartIdx;
      int toIdx = nodeKey[edge.to.toString()]!; // - allNeuronStartIdx;
      connectomeMatrix[fromIdx][toIdx] = Random().nextDouble() * 3;
    });
    protoNeuron = ProtoNeuron(
        notifier: redrawNeuronLine,
        neuronSize: neuronSize,
        screenWidth: screenWidth,
        screenHeight: screenHeight,
        aBufView: aBufView,
        bBufView: bBufView,
        cBufView: cBufView,
        dBufView: dBufView,
        iBufView: iBufView,
        wBufView: wBufView,
        connectomeBufView: connectomeBufView);
    protoNeuron.generateCircle(neuronSize, pos, neuronTypes);
    // protoNeuron.setConnectome(neuronSize, connectomeMatrix);
    populateMatrix();

    // Future.delayed(const Duration(seconds:1), (){
    print("BUF");
    print(mapConnectome);
    print(aBufView);
    print(bBufView);
    print(cBufView);
    print(dBufView);

    runNativeC();
    // });
  }

  neuronTypeChangeCallback(neuronType) {
    if (controller.hasSelection) {
      InfiniteCanvasNode selected = controller.selection[0];
      print("neuronType");
      print(neuronType);
      int idx = selected.value;
      neuronTypes[idx] = neuronType;
      switch (neuronType) {
        case "Quiet":
          aBufView[idx] = 0.02;
          bBufView[idx] = 0.1;
          cBufView[idx] = -65;
          dBufView[idx] = 2;
          break;
        case "Occassionally active":
          aBufView[idx] = 0.02;
          bBufView[idx] = 0.16;
          cBufView[idx] = -65;
          dBufView[idx] = 2;
          break;
        case "Highly active":
          aBufView[idx] = 0.02;
          bBufView[idx] = 0.2;
          cBufView[idx] = -65;
          dBufView[idx] = 2;
          break;
        case "Generates bursts":
          aBufView[idx] = 0.02;
          bBufView[idx] = 0.16;
          cBufView[idx] = -8;
          dBufView[idx] = 2;
          break;
        case "Bursts when activated":
          aBufView[idx] = 0.02;
          bBufView[idx] = 0.1;
          cBufView[idx] = -37;
          dBufView[idx] = 2;
          break;
        case "Dopaminergic":
          aBufView[idx] = 0.02;
          bBufView[idx] = 0.1;
          cBufView[idx] = -65;
          dBufView[idx] = 2;
          break;
        case "Striatal":
          aBufView[idx] = 0.02;
          bBufView[idx] = 0.1;
          cBufView[idx] = -65;
          dBufView[idx] = 2;
          break;
      }
    }
  }

  deleteNeuronCallback() {
    if (controller.hasSelection) {
      InfiniteCanvasNode selected = controller.selection[0];
      // find inward or outward connection
      // inward connection
      List<InfiniteCanvasEdge> inwardEdges =
          controller.edges.where((e) => e.to == selected.key).toList();
      for (int i = 0; i < inwardEdges.length; i++) {
        InfiniteCanvasEdge inwardEdge = inwardEdges[i];
        if (mapSensoryNeuron.containsKey("${inwardEdge.from}_${inwardEdge.to}"))
          mapSensoryNeuron.remove("${inwardEdge.from}_${inwardEdge.to}");
        if (mapContactsNeuron
            .containsKey("${inwardEdge.from}_${inwardEdge.to}"))
          mapContactsNeuron.remove("${inwardEdge.from}_${inwardEdge.to}");
        if (mapConnectome.containsKey("${inwardEdge.from}_${inwardEdge.to}"))
          mapConnectome.remove("${inwardEdge.from}_${inwardEdge.to}");
      }

      // outward connection
      List<InfiniteCanvasEdge> outwardEdges =
          controller.edges.where((e) => e.from == selected.key).toList();
      for (int i = 0; i < outwardEdges.length; i++) {
        InfiniteCanvasEdge outwardEdge = outwardEdges[i];
        if (mapSensoryNeuron.containsKey("${outwardEdge.from}_${outwardEdge.to}"))
          mapSensoryNeuron.remove("${outwardEdge.from}_${outwardEdge.to}");
        if (mapContactsNeuron
            .containsKey("${outwardEdge.from}_${outwardEdge.to}"))
          mapContactsNeuron.remove("${outwardEdge.from}_${outwardEdge.to}");
        if (mapConnectome.containsKey("${outwardEdge.from}_${outwardEdge.to}"))
          mapConnectome.remove("${outwardEdge.from}_${outwardEdge.to}");
      }

      controller.deleteSelection();
      neuronSize--;
      isDrawTail = false;

      controller.deselectAll();
      // controller.select(prevSelectedNeuron.key);
      controller.controlPressed = false;
      isDrawTail = false;
      prevEdgesLength = controller.edges.length;
    }
  }

  deleteEdgeCallback() {
    if (controller.isSelectingEdge) {
      // var selectedEdge = controller.edges.where((element) => element.from == controller.edgeSelected.from && element.to == controller.edgeSelected.to).toList();
      int idx = controller.edges.indexOf(controller.edgeSelected);
      InfiniteCanvasEdge lastCreatedEdge = controller.edges[idx];
      if (mapSensoryNeuron
          .containsKey("${lastCreatedEdge.from}_${lastCreatedEdge.to}"))
        mapSensoryNeuron.remove("${lastCreatedEdge.from}_${lastCreatedEdge.to}");
      if (mapContactsNeuron
          .containsKey("${lastCreatedEdge.from}_${lastCreatedEdge.to}"))
        mapContactsNeuron
            .remove("${lastCreatedEdge.from}_${lastCreatedEdge.to}");
      if (mapConnectome
          .containsKey("${lastCreatedEdge.from}_${lastCreatedEdge.to}"))
        mapConnectome.remove("${lastCreatedEdge.from}_${lastCreatedEdge.to}");

      controller.edges.removeAt(idx);

      controller.isFoundEdge = false;
      controller.isSelectingEdge = false;
      // controller.edgeFound = null;
      // controller.edgeSelected = null;

      controller.deselectAll();
      controller.controlPressed = false;
      isDrawTail = false;
      prevEdgesLength = controller.edges.length;
    }
  }

  prepareWidget(InfiniteCanvas canvas) {
    if (Platform.isIOS) {
      return canvas;
    } else {
      return GestureDetector(
          onTapUp: (details) {
            print("controller.isFoundEdge");
            print(controller.isFoundEdge);
            if (controller.isFoundEdge) {
              controller.isSelectingEdge = true;
              controller.edgeSelected = controller.edgeFound;
            } else {
              controller.isSelectingEdge = false;
              // controller.edgeSelected = controller.edgeFound;
            }
            // controller.notifyMousePosition();
          },
          onScaleEnd: (ScaleEndDetails details) {
            // print( details.scaleVelocity );
          },
          onScaleUpdate: (details) {
            // print(details);
            // details.scale
          },
          onLongPress: () {
            print("controller.mousePosition");
            // print(controller.mousePosition);
            if (controller.hasSelection) {
              var selected = controller.selection[0];
              // int neuronIdx = selected.value - normalNeuronStartIdx - 1;
              int neuronIdx = selected.value;
              print("neuronIdx");
              print(neuronIdx);
              isSelected = true;
              nativec.changeIdxSelected(neuronIdx);
              if (neuronIdx < normalNeuronStartIdx) {
                return;
              }

              // String neuronType = protoNeuron.circles[neuronIdx].neuronType;
              String neuronType = neuronTypes[neuronIdx];
              // print(neuronIdx);

              //show dialog box to change neuron
              // neuronDialogBuilder(context, selected.value.toString(), "Neuron ",
              // /* CHANGE ME
              neuronDialogBuilder(
                  context,
                  "Neuron ",
                  (neuronIdx + 1).toString(),
                  neuronType,
                  neuronTypeChangeCallback,
                  deleteNeuronCallback);
              // */
            } else if (controller.isSelectingEdge) {
              // IMPORTANT - Check duplication when adding edge into the same neuron
              // 2-way axons
              // /* CHANGE ME
              // at this point - there is a minimum of 1 edge
              int isSensoryType = 0;

              final lastCreatedEdge = controller.edgeSelected;
              InfiniteCanvasNode neuronFrom =
                  findNeuronByKey(lastCreatedEdge.from);
              InfiniteCanvasNode neuronTo = findNeuronByKey(lastCreatedEdge.to);
              // InfiniteCanvasNode neuronTo = findNeuronByKey(lastCreatedEdge.to);
              if (neuronFrom == nodeLeftEyeSensor ||
                  neuronFrom == nodeRightEyeSensor)
                isSensoryType = 1;
              else if (neuronTo == nodeLeftMotorBackwardSensor ||
                  neuronTo == nodeRightMotorBackwardSensor ||
                  neuronTo == nodeLeftMotorForwardSensor ||
                  neuronTo == nodeRightMotorForwardSensor) isSensoryType = 2;

              print("isVisualSensory");
              print(isSensoryType);

              Map<String, double> map = {
                // "connectomeContact": connectomeBufView[ neuronFrom.value * neuronSize + neuronTo.value],
                // "neuronContact": neuronContactsBufView[ neuronFrom.value * neuronSize + neuronTo.value],
                // "visualPref": visPrefsBufView[ neuronFrom.value * neuronSize + neuronTo.value].toDouble(),
                "connectomeContact": mapConnectome
                        .containsKey("${neuronFrom.key}_${neuronTo.key}")
                    ? mapConnectome["${neuronFrom.key}_${neuronTo.key}"]
                        .toDouble()
                    : 0,
                "neuronContact": mapContactsNeuron
                        .containsKey("${neuronFrom.key}_${neuronTo.key}")
                    ? mapContactsNeuron["${neuronFrom.key}_${neuronTo.key}"]
                        .toDouble()
                    : 0,
                "visualPref": mapSensoryNeuron
                        .containsKey("${neuronFrom.key}_${neuronTo.key}")
                    ? mapSensoryNeuron["${neuronFrom.key}_${neuronTo.key}"]
                        .toDouble()
                    : -1.0,
              };
              axonDialogBuilder(
                  context,
                  isSensoryType,
                  "Edge",
                  " ",
                  map,
                  neuronTypeChangeCallback,
                  deleteEdgeCallback,
                  linkSensoryConnection,
                  linkMotorConnection,
                  linkNeuronConnection);
              // */
            }
            // else
            // if (controller.hasEdgeSelection{
            //show dialog box to change edge

            // }
          },
          onDoubleTap: () {
            if (controller.scale == 1.5) {
              controller.zoomReset();
              controller.scale = 1;
            } else {
              controller.zoomReset();
              controller.zoom(1.5);
              controller.scale = 1.5;
            }
          },
          child: canvas);
    }
    if ((Platform.isAndroid || Platform.isIOS) && isPanningCanvas) {
      return XGestureDetector(
        onMoveUpdate: (MoveEvent event) {
          print("onMoveUpdate Press Move");
          // return;
          Offset offset = event.delta;
          if (offset.dx > 0) {
            // controller.panRight();
            Offset offset = const Offset(2, 0);
            controller.pan(offset);
          } else if (offset.dx < 0) {
            // controller.panLeft();
            Offset offset = const Offset(-2, 0);
            controller.pan(offset);
          }
          if (offset.dy > 0) {
            // controller.panDown();
            Offset offset = const Offset(0, 2);
            controller.pan(offset);
          } else if (offset.dy < 0) {
            Offset offset = const Offset(0, -2);
            controller.pan(offset);
          }
        },
        onScaleUpdate: (ScaleEvent event) {
          print("prepare scaling");
          var temp = controller.scale * event.scale;
          print(controller.minScale);
          print(controller.maxScale);
          print(controller.scale);
          if (temp < controller.maxScale && temp > controller.minScale) {
            if (temp > controller.scale) {
              controller.zoom(1.003);
            } else {
              controller.zoom(0.997);
            }
          }
        },
        child: canvas,
      );
    } else {
      return canvas;
    }
  }

  rightToolbarCallback(map) {
    print("map");
    print(map);
    menuIdx = map["menuIdx"];
    isCreatePoint = false;
    if (menuIdx == 0) {
      controller.isInteractable = true;
      controller.setCanvasMove(true);
      if (controller.hasSelection) {
        controller.spacePressed = false;
        allowMoveNodes();
      } else {
        double scales = controller.getScale();
        print("scales");
        print(scales);
        if (scales == 0.95) {
          controller.spacePressed = true;
          disallowMoveNodes();
        } else {
          controller.spacePressed = true;
          disallowMoveNodes();
        }
      }
    } else {
      controller.isInteractable = false;
      disallowMoveNodes();
    }

    // if (menuIdx == 6) {
    //   isPanningCanvas = !isPanningCanvas;
    //   if (!isPanningCanvas) {
    //     controller.spacePressed = false;
    //     menuIdx = 0;
    //     allowMoveNodes();
    //     setState(() {});
    //   }
    // } else
    if (menuIdx == 1) {
      // controller.setCanvasMove(false);
    } else if (menuIdx == 5) {
      print("home");
      Navigator.pop(context);
    } else if (menuIdx == 6) {
      // print( json.encode(controller.nodes) );
      // print( json.encode(controller.edges) );
    } else if (menuIdx == 7) {
      controller.spacePressed = false;
      isPlayingMenu = !isPlayingMenu;
      // isSelected = false;
      print("MENU IDX 8");
      print("BUF");
      print(mapConnectome);
      print(aBufView);
      print(bBufView);
      print(cBufView);
      print(dBufView);

      controller.mouseDown = false;
      controller.setCanvasMove(false);

      controller.zoomReset();

      if (isPlayingMenu) {
        isCheckingColor = false;
        try {
          startWebSocket();
        } catch (ex) {}
      } else {
        initializeOpenCV();
        isIsolateWritePortInitialized = false;
        processor.clearMemory();
        try {
          processor = ImagePreprocessor();
          mjpegComponent = Mjpeg(
            stream: httpdStream,
            // stream: "http://192.168.1.4:8081/",
            preprocessor: processor,
            isLive: true,
            fit: BoxFit.fill,
            timeout: const Duration(seconds: 60),
          );

          // writePort.close();
        } catch (exc) {
          print("exception : ");
          print(exc);
        }

        // isolateWritePort.send("DISCONNECT");
        Future.delayed(const Duration(milliseconds: 300), () {
        });
      }

      // print("visPrefsBufView");
      // print(visPrefsBufView);

      if (isPlayingMenu) {
        controller.deselectAll();
        runSimulation();
      } else {
        if (kIsWeb) {
          // js.context.callMethod("stopThreadProcess", [0]);
        } else {
          nativec.stopThreadProcess(0);
        }
        controller.deselectAll();
        controller.setCanvasMove(true);
      }
      setState(() {});
    }
    // add nodes into canvas
  }

  void repositionSensoryNeuron() {
    // double screenHeight = MediaQuery.of(context).size.height/2;
    // double ratio = screenHeight / 600;
    double screenWidth = MediaQuery.of(context).size.width;
    // print("controller.toLocal(Offset(screenWidth / 2, 0))");
    // print(controller.toLocal(Offset(screenWidth / 2, 0)));
    if (Platform.isIOS || Platform.isAndroid) {
      if (MediaQuery.of(context).padding.left == 0 &&
          MediaQuery.of(context).padding.right == 0 &&
          MediaQuery.of(context).padding.top == 0 &&
          MediaQuery.of(context).padding.bottom == 0) {
        screenWidth += 140;
      } else {
        print(MediaQuery.of(context).padding.right);
        print(MediaQuery.of(context).padding.left);

        // screenWidth -= (MediaQuery.of(context).padding.right +
        //     MediaQuery.of(context).padding.left);
        // screenWidth += 14;
        // screenWidth *= 0.87;
      }
    }
    print("screenDimension");
    print(screenWidth);
    // print(screenHeight);
    // print(MediaQuery.of(context).padding.left);
    // print(MediaQuery.of(context).padding.right);
    // print(ratio);
    // print(MediaQuery.of(context).devicePixelRatio);
    Offset middleScreenOffset = Offset(screenWidth / 2, 150);

    // Offset offset = middleScreenOffset.scale(0.5, 0.5);
    // Offset offset = middleScreenOffset.scale(ratio, ratio);
    nodeDistanceSensor.offset = middleScreenOffset;
    print("nodeDistanceSensor.offset");
    print(nodeDistanceSensor.offset);

    Offset diff = Offset(screenHeight / 8, 0);
    Offset offset = middleScreenOffset - diff;
    nodeLeftEyeSensor.offset = offset;

    Offset offsetMic = Offset(screenWidth / 2 - 12 - 1.725 * screenHeight / 8,
        nodeMicrophoneSensor.offset.dy);
    nodeMicrophoneSensor.offset = offsetMic;

    Offset offsetLMF = Offset(screenWidth / 2 - 12 - 2 * screenHeight / 8,
        nodeLeftMotorForwardSensor.offset.dy);
    nodeLeftMotorForwardSensor.offset = offsetLMF;

    Offset offsetLMB = Offset(screenWidth / 2 - 12 - 2 * screenHeight / 8,
        nodeLeftMotorBackwardSensor.offset.dy);
    nodeLeftMotorBackwardSensor.offset = offsetLMB;

    Offset diffRight = Offset(screenHeight / 8, 0);
    Offset offsetRight = middleScreenOffset + diffRight;
    nodeRightEyeSensor.offset = offsetRight;

    Offset offsetSpeaker = Offset(
        screenWidth / 2 - 12 + 1.725 * screenHeight / 8,
        nodeSpeakerSensor.offset.dy);
    nodeSpeakerSensor.offset = offsetSpeaker;

    Offset offsetRMF = Offset(screenWidth / 2 - 12 + 2 * screenHeight / 8,
        nodeRightMotorForwardSensor.offset.dy);
    nodeRightMotorForwardSensor.offset = offsetRMF;

    Offset offsetRMB = Offset(screenWidth / 2 - 12 + 2 * screenHeight / 8,
        nodeRightMotorBackwardSensor.offset.dy);
    nodeRightMotorBackwardSensor.offset = offsetRMB;

    print("nodeMicrophoneSensor");
    print(nodeMicrophoneSensor.offset);
    print("nodeSpeakerSensor");
    print(nodeSpeakerSensor.offset);

    constraintOffsetTopLeft =
        Offset(nodeMicrophoneSensor.offset.dx + 20, middleScreenOffset.dy + 30);
    constraintOffsetTopRight =
        Offset(nodeSpeakerSensor.offset.dx - 20, middleScreenOffset.dy + 30);
    constraintOffsetBottomLeft = Offset(nodeMicrophoneSensor.offset.dx + 20,
        nodeRightMotorBackwardSensor.offset.dy);
    constraintOffsetBottomRight = Offset(nodeSpeakerSensor.offset.dx - 20,
        nodeRightMotorBackwardSensor.offset.dy);

    constraintBrainLeft = constraintOffsetTopLeft.dx;
    constraintBrainRight = constraintOffsetTopRight.dx;
    constraintBrainTop = constraintOffsetTopLeft.dy;
    constraintBrainBottom = constraintOffsetBottomLeft.dy;

    triangleNode.offset = constraintOffsetTopRight;
    rectangleNode.offset = constraintOffsetTopLeft;
    circleNode.offset = constraintOffsetBottomLeft;

    // Offset diffLMB = Offset(2 * screenHeight/10, 0);
    // Offset offsetLMB = Offset(MediaQuery.of(context).size.width/2-10, nodeLeftMotorBackwardSensor.offset.dy); - (diffLMB);
    // nodeLeftMotorBackwardSensor.offset = offsetLMB;
  }

  void initCanvas() {
    // controller.getNode(viewportKey)?.offset = Offset(screenWidth, screenHeight);
    // viewPortNode.update(offset:Offset(screenWidth,screenHeight));
    viewPortNode = InfiniteCanvasNode(
        value: -2,
        key: viewportKey,
        allowMove: false,
        allowResize: false,
        offset: Offset(screenWidth, screenHeight),
        size: const Size(0, 0),
        child: const SizedBox(
          width: 0,
          height: 0,
        ));

    tailNode = InfiniteCanvasNode(
      // allowMove: true,
      // allowResize: false,
      value: -1,
      key: UniqueKey(),
      // label: 'Triangle',
      offset: const Offset(0, 0),
      size: const Size(24, 24),
      child: Builder(
        builder: (context) {
          return CustomPaint(
            painter: InlineCustomPainter(
              brush: tailColor,
              builder: (brush, canvas, rect) {
                // Draw triangle
                // brush.color = Theme.of(context).colorScheme.tertiary;
                // brush.color = Colors.blue;
                if (isDrawTail) {
                  Offset parentOffset =
                      Offset(rect.center.dx, rect.center.dy - gapTailY);
                  canvas.drawCircle(rect.center, rect.width / 3, brush);
                  brush.color = Colors.black;
                  canvas.drawLine(rect.center, parentOffset, brush);
                  brush.color = tailColor.color;
                }
              },
            ),
          );
        },
      ),
    );
    rectangleNode = InfiniteCanvasNode(
      value: 9,
      key: UniqueKey(),
      // label: 'Rectangle',

      offset: const Offset(300, 300),
      size: const Size(20, 20),
      child: Builder(
        builder: (context) {
          return CustomPaint(
            isComplex: true,
            willChange: true,
            painter: InlineCustomPainter(
              brush: neuronColor,
              // brush: rectangleColor,
              builder: (brush, canvas, rect) {
                canvas.drawCircle(rect.center, rect.width / 2, brush);
              },
            ),
          );
        },
      ),
    );
    triangleNode = InfiniteCanvasNode(
      // allowMove: true,
      // allowResize: false,
      value: 10,
      key: UniqueKey(),
      // label: 'Triangle',
      offset: const Offset(500, 170),
      size: const Size(20, 20),
      child: Builder(
        builder: (context) {
          return CustomPaint(
            painter: InlineCustomPainter(
              brush: neuronColor,
              // brush: triangleColor,
              builder: (brush, canvas, rect) {
                canvas.drawCircle(rect.center, rect.width / 2, brush);
              },
            ),
          );
        },
      ),
    );
    circleNode = InfiniteCanvasNode(
      // allowMove: true,
      // allowResize: false,
      value: 11,
      key: UniqueKey(),
      // label: 'Circle',
      offset: const Offset(320, 430),
      size: const Size(20, 20),
      child: Builder(
        builder: (context) {
          return CustomPaint(
            painter: InlineCustomPainter(
              brush: neuronColor,
              // brush: circleColor,
              builder: (brush, canvas, rect) {
                // Draw circle
                // brush.color = Theme.of(context).colorScheme.tertiary;
                // brush.color = Colors.blue;
                canvas.drawCircle(rect.center, rect.width / 2, brush);
              },
            ),
          );
        },
      ),
    );

    var nodes = [
      tailNode,
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
      // triangleNode,
      // circleNode,
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
      nodeLeftMotorForwardSensor, //5
      nodeRightMotorForwardSensor,
      nodeLeftMotorBackwardSensor,
      nodeRightMotorBackwardSensor,
    ];
    controller = InfiniteCanvasController(
      onLongPress: onLongPress,
      onDoubleTap: onDoubleTap,
      nodes: nodes,
      // edges: [
      //   InfiniteCanvasEdge(
      //     from: rectangleNode.key,
      //     to: triangleNode.key,
      //     // label: '4 -> 3',
      //   ),
      //   InfiniteCanvasEdge(
      //     from: rectangleNode.key,
      //     to: circleNode.key,
      //     // label: '[] -> ()',
      //   ),
      //   InfiniteCanvasEdge(
      //     from: triangleNode.key,
      //     to: circleNode.key,
      //   ),
      // ]
    );
    controller.maxScale = 2.7;
    controller.scale = 1;
    controller.minScale = 0.85;

    if (Platform.isAndroid || Platform.isIOS) {
      repositionSensoryNeuron();
    }

    controller.addListener(() {
      if (controller.mouseDown) {
        // if (menuIdx == 6) {
        //   controller.spacePressed = isPanningCanvas;
        // } else
        // print("menuIdx == 0");
        // print(menuIdx);
        // print(controller.hasSelection);
        // print(isCreatePoint);

        if (menuIdx == 0 && !controller.hasSelection) {
          isDrawTail = false;
          // if (controller.isSelectingEdge && isPrevSelectedEdge == false){
          //   isPrevSelectedEdge = true;
          //   prevSelectedEdge = controller.edgeSelected;

          //   controller.isFoundEdge = false;
          //   controller.isSelectingEdge = false;

          // }
          // else
          // if (controller.isSelectingEdge && isPrevSelectedEdge == true  ){
          //   isPrevSelectedEdge = false;
          //   prevSelectedEdge = controller.edgeSelected;

          //   controller.isFoundEdge = false;
          //   controller.isSelectingEdge = false;
          // }

          // print("menuIdx == 0");
          // // print(menuIdx == 0);
          // print(controller.hasSelection);

          double scales = controller.getScale();
          // print("scales");
          // print(scales);
          if (scales == 0.95) {
            controller.zoomReset();
            controller.setCanvasMove(false);
            controller.spacePressed = false;
            disallowMoveNodes();
          } else {
            controller.setCanvasMove(true);
            controller.spacePressed = true;
            disallowMoveNodes();
          }
        } else if (menuIdx == 0 && controller.controlPressed) {
          // print("Controle pRessed");
        } else if (menuIdx == 0 &&
            controller.hasSelection &&
            !controller.controlPressed) {
          var selected = controller.selection[0];

          var pos = selected.offset;
          int defaultSensorLength = listDefaultSensor.length;
          bool foundSelected = false;
          for (int i = 0; i < defaultSensorLength; i++) {
            if (selected == listDefaultSensor[i]) {
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
            Future.delayed(const Duration(milliseconds: 1000), () {
              isTooltipOverlay = false;
              tooltipValueChange.value = (Random().nextInt(10000));
            });
            // selected.update(offset: pos);
            // return;
            // print("disallowMoveNodes");
            // disallowMoveNodes();
            // controller.setCanvasMove(false);
          }

          if (selected == tailNode) {
            controller.deselectAll();
            controller.select(prevSelectedNeuron.key);
            controller.controlPressed = true;
            isDrawTail = false;
            prevEdgesLength = controller.edges.length;
          } else {
            // if (prevEdgesLength != controller.edges.length){
            //   prevEdgesLength = controller.edges.length;
            // }else{
            prevSelectedNeuron = selected;
            isDrawTail = true;
            if (foundSelected) {
              tailNode.update(
                  offset: Offset(selected.offset.dx + gapTailX,
                      selected.offset.dy + gapTailY));
            } else {
              if (selected.offset.dx < constraintBrainLeft) {
                var newOffset = Offset(constraintBrainLeft, pos.dy);
                selected.update(
                    size: selected.size, offset: newOffset, label: "");
              } else if (selected.offset.dx > constraintBrainRight) {
                var newOffset = Offset(constraintBrainRight, pos.dy);
                selected.update(
                    size: selected.size, offset: newOffset, label: "");
              }

              pos = selected.offset;

              if (selected.offset.dy < constraintBrainTop) {
                var newOffset = Offset(pos.dx, constraintBrainTop);
                selected.update(
                    size: selected.size, offset: newOffset, label: "");
              } else if (selected.offset.dy > constraintBrainBottom) {
                var newOffset = Offset(pos.dx, constraintBrainBottom);
                selected.update(
                    size: selected.size, offset: newOffset, label: "");
              }

              if (selected.offset.dx < constraintBrainLeft) {
                var newOffset = Offset(constraintBrainLeft, selected.offset.dy);
                tailNode.update(
                    offset: Offset(
                        newOffset.dx + gapTailX, newOffset.dy + gapTailY));
              } else if (selected.offset.dx > constraintBrainRight) {
                var newOffset =
                    Offset(constraintBrainRight, selected.offset.dy);
                tailNode.update(
                    offset: Offset(
                        newOffset.dx + gapTailX, newOffset.dy + gapTailY));
              } else if (selected.offset.dy < constraintBrainTop) {
                var newOffset = Offset(selected.offset.dx, constraintBrainTop);
                tailNode.update(
                    offset: Offset(
                        newOffset.dx + gapTailX, newOffset.dy + gapTailY));
              } else if (selected.offset.dy > constraintBrainBottom) {
                var newOffset =
                    Offset(selected.offset.dx, constraintBrainBottom);
                tailNode.update(
                    offset: Offset(
                        newOffset.dx + gapTailX, newOffset.dy + gapTailY));
              } else {
                // print("updateee");
                tailNode.update(
                    offset: Offset(selected.offset.dx + gapTailX,
                        selected.offset.dy + gapTailY));
              }
            }
            controller.spacePressed = false;
            controller.setCanvasMove(false);
            allowMoveNodes();
          }
        } else if (menuIdx == 1 && !isCreatePoint && !controller.hasSelection) {
          if (Platform.isIOS || Platform.isAndroid) {
            if (prevMouseX == controller.mousePosition.dx &&
                prevMouseY == controller.mousePosition.dy) {
              prevMouseX = controller.mousePosition.dx;
              prevMouseY = controller.mousePosition.dy;
              return;
            } else {
              prevMouseX = controller.mousePosition.dx;
              prevMouseY = controller.mousePosition.dy;
            }
          }
          Offset localPosition = controller.toLocal(controller.mousePosition);
          double mouseX = localPosition.dx;
          double mouseY = localPosition.dy;
          print("Create neuron1");
          print(prevMouseX);
          print(prevMouseY);
          print(mouseX);
          print(mouseY);
          // print(constraintBrainLeft);
          // print(constraintBrainRight);
          // print(constraintBrainTop);
          // print(constraintBrainBottom);

          if (mouseX < constraintBrainLeft || mouseX > constraintBrainRight) {
            return;
          }
          if (mouseY < constraintBrainTop || mouseY > constraintBrainBottom) {
            return;
          }
          isCreatePoint = true;

          if (neuronSize + 1 >= maxPosBuffer) {
            return;
          }
          neuronSize++;
          neuronTypes.add(randomNeuronType());
          neuronsKey.add(UniqueKey());
          initNativeC();
          controller.add(InfiniteCanvasNode(
            key: neuronsKey[neuronsKey.length - 1],
            value: neuronSize - 1,
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
          ));
          Future.delayed(const Duration(milliseconds: 100), () {
            controller.deselect(neuronsKey[neuronsKey.length - 1]);
          });
        } else if (menuIdx == 2 && !isCreatePoint && controller.hasSelection) {
          // print('design brain start');
          // print("------------------");
          // print(controller.hasSelection);
          // print(axonFromSelected);
          // print(axonToSelected);
          isCreatePoint = true;
          if (!axonFromSelected && controller.hasSelection) {
            axonFromSelected = true;
            axonFrom = controller.selection[0].key;
            Future.delayed(const Duration(milliseconds: 100), () {
              controller.deselect(axonFrom);
            });

            // isCreatePoint = false;
          } else if (!axonToSelected && controller.hasSelection) {
            axonFromSelected = true;
            axonTo = controller.selection[0].key;

            if (axonFrom == axonTo) {
              print('axon from = to');
              print(axonFrom);
              print(axonTo);
            } else {
              // if there is already the same edge from one node to another node, don't add
              bool isAddUniqueEdge = true;

              // int totalEdges = controller.edges.length;
              // for (int i = 0; i < totalEdges; i++){
              //   if (controller.edges[i].from == axonFrom.key && controller.edges[i].to == axonTo.key){
              //     isAddUniqueEdge = false;
              //   }
              // }
              print('axon to selected');
              if (isAddUniqueEdge) {
                print('axon unique to selected');

                controller.edges
                    .add(InfiniteCanvasEdge(from: axonFrom, to: axonTo));
              }
            }

            axonFromSelected = false;
            axonToSelected = false;
            Future.delayed(const Duration(milliseconds: 100), () {
              // controller.deselect(axonFrom);
              controller.deselect(axonTo);
            });

            // isCreatePoint = false;
          }
          // print('design brain end');
          // print("------------------");
          // print(controller.hasSelection);
          // print(axonFromSelected);
          // print(axonToSelected);
        } else if (menuIdx == 6 && !controller.hasSelection) {
          print("Zoom Reset");
          controller.zoomReset();
          isSelected = false;
          nativec.changeIdxSelected(-1);
          setState(() {});
        } else if (menuIdx == 6 && controller.hasSelection) {
          var selected = controller.selection[0];
          print("selected.value");
          print(selected.value);
          isSelected = true;
          nativec.changeIdxSelected(selected.value);
          redrawNeuronLine.value = Random().nextInt(100);
          setState(() {});
        }
      } else {
        isCreatePoint = false;
        if (controller.controlPressed) {
          //create link
          // final lastCreatedEdge = controller.edges[controller.edges.length-1];
          // InfiniteCanvasNode neuronFrom = findNeuronByKey(lastCreatedEdge.from);
          // InfiniteCanvasNode neuronTo = findNeuronByKey(lastCreatedEdge.to);

          // int prevValue = neuronFrom.value;
          // if (prevValue >=0 && prevValue <=8){
          //   linkDialogBuilder(context, "-", linkSensoryConnection);
          // }else{
          //   int toValue = neuronTo.value;
          //   if (toValue >=0 && toValue <=8){
          //     linkDialogBuilder(context, "-", linkSensoryConnection);
          //   }else{
          //   }

          // }
          controller.controlPressed = false;
          controller.deselectAll();
          isDrawTail = false;
          tailNode.update(offset: tailNode.offset);
        }
        // isTooltipOverlay = false;
        // setState((){});
      }
    });
  }

  InfiniteCanvasNode findNeuronByValue(val) {
    // print("val");
    // print(val);
    var list = controller.nodes
        .where((element) => element.value == val)
        .toList(growable: false);
    return list[0];
  }

  InfiniteCanvasNode findNeuronByKey(key) {
    var list = controller.nodes
        .where((element) => element.key == key)
        .toList(growable: false);
    return list[0];
  }

  void linkNeuronConnection(value) {
    print("neuron");
    print(value);
    if (value.trim().length == 0) return;
    double val = double.parse(value);
    if (val > 30) {
      val = 30;
    }
    final lastCreatedEdge = controller.edgeSelected;
    mapConnectome["${lastCreatedEdge.from}_${lastCreatedEdge.to}"] = val;
  }

  void linkMotorConnection(value) {
    print("motor");
    print(value);
    if (value.trim().length == 0) return;
    double val = double.parse(value);
    if (val > 50) {
      val = 50;
    }
    final lastCreatedEdge = controller.edgeSelected;
    mapContactsNeuron["${lastCreatedEdge.from}_${lastCreatedEdge.to}"] = val;
  }

  void linkSensoryConnection(value) {
    print("sensory");
    print(value);
    final lastCreatedEdge = controller.edgeSelected;
    // final neuronFrom = findNeuronByKey(lastCreatedEdge.from);
    // final neuronTo = findNeuronByKey(lastCreatedEdge.to);
    mapSensoryNeuron["${lastCreatedEdge.from}_${lastCreatedEdge.to}"] = value;
  }

  void initNeuronType() {
    neuronTypes = [];
    for (int i = 0; i < neuronSize; i++) {
      if (i < normalNeuronStartIdx) {
        neuronTypes.add("Quiet");
      } else {
        neuronTypes.add(randomNeuronType());
      }
    }
  }

  void onLongPress() {
    if (controller.hasSelection) {
      var selected = controller.selection[0];
      int neuronIdx = selected.value;
      // print(neuronIdx);
      if (neuronIdx < normalNeuronStartIdx) {
        return;
      }
      isSelected = true;
      nativec.changeIdxSelected(neuronIdx);

      String neuronType = neuronTypes[neuronIdx];
      neuronDialogBuilder(context, "Neuron ", (neuronIdx + 1).toString(),
          neuronType, neuronTypeChangeCallback, deleteNeuronCallback);
    } else if (controller.isSelectingEdge) {
      int isSensoryType = 0;

      final lastCreatedEdge = controller.edgeSelected;
      InfiniteCanvasNode neuronFrom = findNeuronByKey(lastCreatedEdge.from);
      InfiniteCanvasNode neuronTo = findNeuronByKey(lastCreatedEdge.to);
      // InfiniteCanvasNode neuronTo = findNeuronByKey(lastCreatedEdge.to);
      if (neuronFrom == nodeLeftEyeSensor || neuronFrom == nodeRightEyeSensor)
        isSensoryType = 1;
      else if (neuronTo == nodeLeftMotorBackwardSensor ||
          neuronTo == nodeRightMotorBackwardSensor ||
          neuronTo == nodeLeftMotorForwardSensor ||
          neuronTo == nodeRightMotorForwardSensor) isSensoryType = 2;

      print("isVisualSensory");
      print(isSensoryType);
      Map<String, double> map = {
        // "connectomeContact": connectomeBufView[ neuronFrom.value * neuronSize + neuronTo.value],
        // "neuronContact": neuronContactsBufView[ neuronFrom.value * neuronSize + neuronTo.value],
        // "visualPref": visPrefsBufView[ neuronFrom.value * neuronSize + neuronTo.value].toDouble(),
        "connectomeContact":
            mapConnectome.containsKey("${neuronFrom.key}_${neuronTo.key}")
                ? mapConnectome["${neuronFrom.key}_${neuronTo.key}"]
                : 0,
        "neuronContact":
            mapContactsNeuron.containsKey("${neuronFrom.key}_${neuronTo.key}")
                ? mapContactsNeuron["${neuronFrom.key}_${neuronTo.key}"]
                : 0,
        "visualPref":
            mapSensoryNeuron.containsKey("${neuronFrom.key}_${neuronTo.key}")
                ? mapSensoryNeuron["${neuronFrom.key}_${neuronTo.key}"].toDouble()
                : -1.0,
      };
      axonDialogBuilder(
          context,
          isSensoryType,
          "Edge",
          " ",
          map,
          neuronTypeChangeCallback,
          deleteEdgeCallback,
          linkSensoryConnection,
          linkMotorConnection,
          linkNeuronConnection);

      // axonDialogBuilder(context, isSensoryType, "Edge", " ",  neuronTypeChangeCallback,
      //     deleteEdgeCallback, linkSensoryConnection, linkMotorConnection, linkNeuronConnection);
      // axonDialogBuilder(
      //     context, isSensory, "Edge", " ", neuronTypeChangeCallback, deleteEdgeCallback);
    }
  }

  void onDoubleTap() {
    if (controller.scale == 2.0) {
      controller.zoomReset();
      controller.scale = 1;
    } else {
      controller.zoomReset();
      controller.zoom(2.0);
      controller.scale = 2.0;
    }
  }

//   void testColorCV() async {
//     // print("testColorCV");
//     NativeOpenCV nativeocv = NativeOpenCV();
//     // print(nativeocv.opencvVersion());

//     Uint8List lowerB = ptrLowerB.asTypedList(3);
//     Uint8List upperB = ptrUpperB.asTypedList(3);

//     //RED
//     lowerB[0] = 0;
//     lowerB[1] = 43;
//     lowerB[2] = 46;
//     upperB[0] = 0;
//     upperB[1] = 255;
//     upperB[2] = 255;

//     // GREEN
//     lowerB[0] = 36;
//     lowerB[1] = 25;
//     lowerB[2] = 25;
//     upperB[0] = 86;
//     upperB[1] = 255;
//     upperB[2] = 255;

// // lower_red = (0, 43, 46)
// // upper_red = (0, 255, 255)

// // lower_green = (36, 25, 25)
// // upper_green = (86, 255, 255)

// // lower_blue = (100, 130, 46)
// // upper_blue = (124, 255, 255)
//     // Uint8List redBg = ( await rootBundle.load("assets/bg/ObjBlackRedBg.jpg") ).buffer.asUint8List();
//     Uint8List redBg = (await rootBundle.load("assets/bg/MatLabExample.png"))
//         .buffer
//         .asUint8List();
//     // String path = Directory.current.absolute.path;
//     print('abc');
//     Directory appDocumentsDir = await getTemporaryDirectory();
//     String path = appDocumentsDir.path;
//     File file = File('$path/bg.png');
//     print('$path/bg.png');
//     file.writeAsBytesSync(redBg, mode: FileMode.write);

//     try {
//       freeMemory(ptrFrame);
//       // freeMemory(ptrMaskedFrame);
//     } catch (err) {}
//     ptrFrame = allocate<ffi.Uint8>(
//         count: redBg.length, sizeOfType: ffi.sizeOf<ffi.Uint8>());
//     // ptrMaskedFrame = allocate<ffi.Uint8>(count: frameQVGASize * 3, sizeOfType: ffi.sizeOf<ffi.Uint8>());
//     // ptrMaskedFrame = allocate<ffi.Uint8>(count: redBg.length, sizeOfType: ffi.sizeOf<ffi.Uint8>());

//     Uint8List data = ptrFrame.asTypedList(redBg.length);
//     // dataMaskedImage = ptrMaskedFrame.asTypedList(redBg.length);
//     // print("redBg");
//     // print(redBg);

//     int i = 0;
//     // copy data manually
//     for (i = 0; i < data.length; i++) {
//       data[i] = redBg[i];
//       // dataMaskedImage[i] = redBg[i];
//     }

//     // nativeocv

//   int status = nativeocv.findColorInImage(ptrFrame, redBg.length, ptrMaskedFrame);
//     // dataMaskedImage = ptrMaskedFrame.asTypedList(8202);
//     // dataMaskedImage = ptrMaskedFrame.asTypedList(redBg.length);
//     // dataMaskedImage = ( await rootBundle.load("assets/bg/greenbg.jpeg") ).buffer.asUint8List();

//     // setState((){});

//     // print("status");
//     // print(status);
//     // int area = 320 * 240;
//     // int percentage = (status * 100 / area).floor();
//     // if (percentage > 30) {
//     //   // print("Occupied by that color");
//     // } else {
//     //   print("#Not Occupied by that color");
//     // }
//   }

  void updateFromSimulation(String message) {
    if (isIsolateWritePortInitialized) {
      // print(message);
      _DesignBrainPageState.isolateWritePort.send(message);
    }
  }
}

class EyeClipper extends CustomClipper<Rect> {
  EyeClipper({required this.isLeft, required this.width, required this.height});
  final bool isLeft;
  final double width;
  final double height;
  @override
  Rect getClip(Size size) {
    if (isLeft) {
      return const Rect.fromLTWH(0, 30, 160, 120);
    } else {
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

class ImagePreprocessor extends MjpegPreprocessor {
  static int frameQVGASize = 320 * 240;
  ffi.Pointer<ffi.Uint8> ptrFrame = allocate<ffi.Uint8>(
      count: frameQVGASize, sizeOfType: ffi.sizeOf<ffi.Uint8>());
  // static ffi.Pointer<ffi.Uint8> ptrMaskedFrame = allocate<ffi.Uint8>(
  //     count: frameQVGASize, sizeOfType: ffi.sizeOf<ffi.Uint8>());

  // static ffi.Pointer<ffi.Uint8> ptrLowerB =
  //     allocate<ffi.Uint8>(count: 3, sizeOfType: ffi.sizeOf<ffi.Uint8>());
  // static ffi.Pointer<ffi.Uint8> ptrUpperB =
  //     allocate<ffi.Uint8>(count: 3, sizeOfType: ffi.sizeOf<ffi.Uint8>());

  double processedMotorCounter = -1;
  bool isRunning = true;

  ImagePreprocessor(){
    ptrFrame = allocate<ffi.Uint8>(
      count: frameQVGASize, sizeOfType: ffi.sizeOf<ffi.Uint8>());
  }

  bool isValidJpeg(Uint8List bytes) {
    if (bytes.length < 4) {
      return false;
    }
    return bytes[0] == 0xFF &&
        bytes[1] == 0xD8 &&
        bytes[bytes.length - 2] == 0xFF &&
        bytes[bytes.length - 1] == 0xD9;
  }

  clearMemory(){
    isRunning = false;
    freeMemory(ptrFrame);
  }

  @override
  List<int>? process(List<int> frame) {
    // if (!isRunning) return frame;
    // print(frame);
    // print("process Frame");

    // print("Receive Image DateTime");
    // print(DateTime.now().microsecondsSinceEpoch);
    //send to isolate

    Uint8List frameData = Uint8List.fromList(frame);
    // Uint8List maskedFrameData = Uint8List(frame.length);
    // mainBloc.drawImageNow(frameData);
    // return frame;

    // Uint8List lowerB = ptrLowerB.asTypedList(3);
    // Uint8List upperB = ptrUpperB.asTypedList(3);

    // // RED
    // lowerB[0] = 0;
    // lowerB[1] = 43;
    // lowerB[2] = 46;
    // upperB[0] = 0;
    // upperB[1] = 255;
    // upperB[2] = 255;

    // // BLUE
    // lowerB[0] = 92;
    // lowerB[1] = 57;
    // lowerB[2] = 50;
    // upperB[0] = 142;
    // upperB[1] = 153;
    // upperB[2] = 178;

    // Uint8List data = ptrFrame.asTypedList(frameQVGASize);
    // int i = 0;
    // for (i=0;i<frameQVGASize;i++){
    //   data[i] = frameData[i];
    // }

    // OpenCVImage image = OpenCVImage(length: frameQVGASize, pointer: ptrFrame);
    // image.inRange(lowerB,upperB,ptrMaskedFrame,40);

    // image.inRange();
    // checkColorCV(frameData,ptrLowerB,ptrUpperB);

    bool isJpegValid = isValidJpeg(frameData);
    if (!isCheckingColor && isJpegValid) {
      // print("isCheckingColor");
      // print(isCheckingColor);
      // print(frameData.length);
      isCheckingColor = true;
      // print("C++CallImageProcessingStartDateTime");
      // print(DateTime.now().microsecondsSinceEpoch);

      checkColorCV(frameData).then((flag) {
        if (flag) {
          // forward or backward
        }
        // print("C++CallImageProcessingEndDateTime");
        // print(DateTime.now().microsecondsSinceEpoch);

        // if (processedMotorCounter !=
        //     _DesignBrainPageState.motorCommandBufView[5]) {
        //   processedMotorCounter = _DesignBrainPageState.motorCommandBufView[5];
        //   double r_torque = _DesignBrainPageState.motorCommandBufView[0];
        //   double r_dir = _DesignBrainPageState.motorCommandBufView[1];
        //   if (r_dir == 2) {
        //     r_dir = -1;
        //   }

        //   double l_torque = _DesignBrainPageState.motorCommandBufView[2];
        //   double l_dir = _DesignBrainPageState.motorCommandBufView[3];
        //   if (l_dir == 2) {
        //     l_dir = -1;
        //   }

        //   String message = "l:${l_torque * l_dir};r:${r_torque * r_dir};";

        //   // print("wheel message");
        //   // print(r_torque.toString() + " ___@___" + r_dir.toString());
        //   _DesignBrainPageState.isolateWritePort.send(message);
        // }
        isCheckingColor = false;
      });
    } else {
      if (!isJpegValid) {
        print("isNotValidJPEG");
      }
    }

    mainBloc.drawImageNow(frameData);
    return frame;
  }
}
