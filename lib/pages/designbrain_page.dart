import 'dart:async';
import 'dart:collection';
import 'dart:convert';
// import 'dart:convert';
import 'dart:ffi' as ffi;
import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';
// import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:animated_battery_gauge/battery_gauge.dart';
import 'package:another_xlider/another_xlider.dart';
import 'package:another_xlider/models/trackbar.dart';
import 'package:ffi/ffi.dart';
import 'package:fialogs/fialogs.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_mjpeg/flutter_mjpeg.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gesture_x_detector/gesture_x_detector.dart';
import 'package:infinite_canvas/infinite_canvas.dart';
import 'package:infinite_canvas/src/domain/model/SyntheticNeuron.dart';
import 'package:infinite_canvas/src/domain/model/SyntheticEdge.dart';
import 'package:infinite_canvas/src/domain/model/drop_target.dart';
import 'package:matrix_gesture_detector_pro/matrix_gesture_detector_pro.dart';
import 'package:metooltip/metooltip.dart';
import 'package:mutex/mutex.dart';
import 'package:neurorobot/components/drop_targets.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:native_opencv/native_opencv.dart';
import 'package:native_opencv/nativec.dart';
import 'package:neurorobot/ai/models/recognition.dart';
import 'package:neurorobot/ai/service/detector_service.dart';
import 'package:neurorobot/ai/utils/StatsWidget.dart';
// import 'package:network_info_plus/network_info_plus.dart';
// import 'package:nativec/allocation.dart';
// import 'package:nativec/nativec.dart';
import 'package:neurorobot/bloc/bloc.dart';
import 'package:neurorobot/components/left_toolbar.dart';
import 'package:neurorobot/dialogs/load_brain.dart';
import 'package:neurorobot/dialogs/save_brain.dart';
import 'package:neurorobot/utils/Allocator.dart';
import 'package:neurorobot/utils/Debouncers.dart';
import 'package:neurorobot/utils/General.dart';
import 'package:neurorobot/utils/ProtoNeuron.dart';
import 'package:neurorobot/utils/Simulations.dart';
import 'package:neurorobot/utils/SingleCircle.dart';
import 'package:neurorobot/utils/Vision.dart';
import 'package:neurorobot/utils/WaveWidget.dart';
import 'package:screenshot/screenshot.dart';
import 'package:sn_progress_dialog/progress_dialog.dart';
// import 'package:opencv_ffi/opencv_ffi.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:neurorobot/components/right_toolbar.dart';
import 'package:window_manager/window_manager.dart';
import '../dialogs/info_dialog.dart';

// import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../dialogs/load_brain_new_ui.dart';
import '../main.dart';
import '../utils/ImageCapture.dart';
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
  static List<int> prevFrame = [];

  DesignBrainPage({super.key});
  @override
  State<DesignBrainPage> createState() => _DesignBrainPageState();
}

bool isCheckingImage = false;
bool isCheckingColor = false;

class _DesignBrainPageState extends State<DesignBrainPage> with WindowListener {
  // STEVE AI
  static Detector? detector;
  StreamSubscription? _imageDetectorSubscription;
  PackageInfo? packageInfo;

  /// Results to draw bounding boxes
  List<Recognition>? results;

  /// Realtime stats
  Map<String, String>? aiStats;

  // WEB SOCKET
  static late SendPort isolateWritePort;
  bool isIsolateWritePortInitialized = false;
  bool isReceivingCalculation = true;
  late ReceivePort writePort = ReceivePort();

  // SIMULATION SECTION
  // List<String> neuronTypes = [];
  Map<String, String> neuronTypes = {};
  Map<String, String> neuronStyles = {};
  static int neuronSize = 12;
  static const int motorCommandsLength = 6 * 2;
  static const int maxPosBuffer = 220;
  int epochs = 30;
  late List<SingleSquare> squareActiveCirclesPainter;
  late List<SingleSquare> squareInactiveCirclesPainter;
  late List<SingleCircle> neuronActiveCirclesPainter;
  late List<SingleCircle> neuronInactiveCirclesPainter;

  late Nativec nativec;

  bool isDeleteMenu = false;
  bool isNeuronMenu = false;
  bool isSynapseMenu = false;
  bool isCameraMenu = false;
  bool isDistanceMenu = false;
  bool isMotorMenu = false;
  bool isMicrophoneMenu = false;
  bool isSpeakerMenu = false;
  bool isLedMenu = false;

  String neuronMenuType = "Quiet";
  List<String> neuronTypesLabel = [
    "Quiet",
    "Occassionally active",
    "Highly active",
    "Generates bursts",
    "Bursts when activated",
    "Dopaminergic",
    "Striatal",
    "Custom",
    "Delay", //8
    "Rhytmic", //9
    "Counting", //10
  ];

  List<String> neuronMenuTypes = [
    "Quiet",
    "Occassionally active",
    "Highly active",
    "Generates bursts",
    "Bursts when activated",
    "Dopaminergic",
    "Striatal",
    "Custom",
    "Delay",
    "Rhytmic",
    "Counting", //10
  ];
  late List<DropdownMenuItem> dropdownNeuronItems;

  String cameraMenuType = "Green";
  List<String> cameraMenuTypes = [
    "Blue", // 1
    "Blue (side)",
    "Green",
    "Green (side)",
    "Red",
    "Red (side)",
    "Movement", // 7
    "person",
    "backpack",
    "bottle",
    "cup",
    "bowl",
    "banana",
    "apple",
    "orange",
    "chair",
    "couch",
    "potted plant",
    "laptop",
    "cell phone",
    "book",
    "vase",
  ];
  late List<DropdownMenuItem> dropdownCameraItems;

  String distanceMenuType = "Short";
  List<String> distanceMenuTypes = [
    "Short",
    "Medium",
    "Long",
    "Custom",
  ];
  late List<DropdownMenuItem> dropdownDistanceItems;

  String neuronStyle = "Excitatory";
  List<String> neuronMenuStyle = [
    "Excitatory",
    "Inhibitory",
  ];
  late List<DropdownMenuItem> dropdownNeuronStyleItems;

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
  late ffi.Pointer<ffi.Int16> neuronDistanceBuf;
  late ffi.Pointer<ffi.Int16> neuronSpeakerBuf;
  late ffi.Pointer<ffi.Int16> neuronMicrophoneBuf;
  late ffi.Pointer<ffi.Int16> neuronLedBuf;
  late ffi.Pointer<ffi.Int16> neuronLedPositionBuf;
  late ffi.Pointer<ffi.Double> distanceBuf;
  late ffi.Pointer<ffi.Int16> distanceMinLimitBuf;
  late ffi.Pointer<ffi.Int16> distanceMaxLimitBuf;

  late ffi.Pointer<ffi.Int16> mapNeuronTypeBuf;
  late ffi.Pointer<ffi.Int16> mapDelayNeuronBuf;
  late ffi.Pointer<ffi.Int16> mapRhytmicNeuronBuf;
  late ffi.Pointer<ffi.Int16> mapCountingNeuronBuf;

  late ffi.Pointer<ffi.Int32> stateBuf;
  late ffi.Pointer<ffi.Double> visPrefsValsBuf;
  late ffi.Pointer<ffi.Uint8> motorCommandMessageBuf;

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
  late Float64List visPrefsValsBufView = Float64List(0);
  late Float64List connectomeBufView = Float64List(0);
  static Float64List motorCommandBufView = Float64List(0);
  late Float64List neuronContactsBufView = Float64List(0);
  late Int16List neuronDistanceBufView = Int16List(0);
  late Int16List neuronSpeakerBufView = Int16List(0);
  late Int16List neuronMicrophoneBufView = Int16List(0);
  late Int16List neuronLedBufView = Int16List(0);
  late Int16List neuronLedPositionBufView = Int16List(0);
  late Float64List distanceBufView = Float64List(0);
  late Int16List distanceMinLimitBufView = Int16List(0);
  late Int16List distanceMaxLimitBufView = Int16List(0);

  late Int16List mapNeuronTypeBufView = Int16List(0);
  late Int16List mapDelayNeuronBufView = Int16List(0);
  late Int16List mapRhytmicNeuronBufView = Int16List(0);
  late Int16List mapCountingNeuronBufView = Int16List(0);

  String batteryVoltage = "0";

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
  double chartGain = 2;

  bool isInitialized = false;

  late ProtoNeuron protoNeuron;
  bool isChartSelected = false;
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
  int normalNeuronStartIdx = 12;
  int allNeuronStartIdx = 2; // beside viewport & tail node

  Uint8List dataMaskedImage = Uint8List(0);

  int bufPositionCount = 1;
  int bufDistanceCount = 1;
  int bufDistanceLimitCount = 100;

  late ImagePreprocessor processor;

  String httpdStream = "http://192.168.4.1:81/stream";
  // String httpdStream = "http://192.168.1.4:8081";

  late Isolate webSocket;

  bool isSimulationCallbackAttached = false;

  int StateLength = 20;
  int MotorMessageLength = 300;
  // int VisualPrefLength = 7 * 2;
  final rightEyeConstant = 15 + 7;
  int VisualPrefLength = 22 * 2;

  late Widget mainBody;

  double prevTransformScale = 1;
  Debouncer debouncerSnapNeuron = Debouncer(milliseconds: 3);
  Debouncer debouncerAIClassification = Debouncer(milliseconds: 300);

  List<Offset> rawPos = [];

  // String redLEDCmd = 'd:111;d:211;d:311;d:411;d:511;d:611;'; // red
  // String blueLEDCmd = 'd:131;d:231;d:331;d:431;d:531;d:631;'; // blue
  // String greenLEDCmd = 'd:121;d:221;d:321;d:421;d:521;d:621;;'; // green

  // String redLEDCmd = 'd:111;d:211;d:311;d:411;'; // red
  // String blueLEDCmd = 'd:131;d:231;d:331;d:431;'; // blue
  // String greenLEDCmd = 'd:121;d:221;d:321;d:421;'; // green
  String redLEDCmd = 'd:0,255,0,0;d:1,255,0,0;d:2,255,0,0;d:3,255,0,0;'; // red
  String blueLEDCmd =
      'd:0,0,0,255;d:1,0,0,255;d:2,0,0,255;d:3,0,0,255;'; // blue
  String greenLEDCmd =
      'd:0,0,255,0;d:1,0,255,0;d:2,0,255,0;d:3,0,255,0;'; // green
  // -- TopLeft idx 1
  // -- TopRight idx 2
  // -- BottomLeft idx 3
  // -- BottomRight idx 4
  // String offLED =
  //     'd:110;d:210;d:310;d:410;d:510;d:610;d:120;d:220;d:320;d:420;d:520;d:620;d:130;d:230;d:330;d:430;d:530;d:630;'; // off
  // String offLEDCmd = "d:120;d:220;d:320;d:420;d:520;d:620;";
  String offLEDCmd = "d:0,0,0,0;d:1,0,0,0;d:2,0,0,0;d:3,0,0,0;";
  String stopMotorCmd = "l:0;r:0;s:0;";

  GlobalKey rightToolbarGlobalKey = GlobalKey();
  LocalKey rightToolbarKey = UniqueKey();

  String activeCameraType = "";

  TextEditingController tecAWeight = TextEditingController();
  TextEditingController tecBWeight = TextEditingController();
  TextEditingController tecCWeight = TextEditingController();
  TextEditingController tecDWeight = TextEditingController();
  double sldAWeight = 0.02;
  double sldBWeight = 0.1;
  double sldCWeight = -65.0;
  double sldDWeight = 2;

  double sldTimeValue = 0;
  TextEditingController tecTimeValue = TextEditingController();

  final double defaultA = 0.02;
  final double defaultB = 0.18;
  final int defaultC = -65;
  final int defaultD = 2;

  Map<String, dynamic> aDesignArray = {};
  Map<String, dynamic> bDesignArray = {};
  Map<String, dynamic> cDesignArray = {};
  Map<String, dynamic> dDesignArray = {};

  TextEditingController tecFrequencyWeight = TextEditingController();
  double sldFrequencyWeight = 40.0;
  TextEditingController tecSynapticWeight = TextEditingController();
  double sldSynapticWeight = 50.0;

  int batteryPercent = 80;

  bool isPreventPlayClick = false;

  double neuronDrawSize = 20;

  int isSavingBrain = 0;
  String selectedFileName = "-";
  Map pMapStatus = {};

  Queue<String> commandList = Queue<String>();
  String strCommandList = "";
  final mutex = ReadWriteMutex();
  final mutexCommand = ReadWriteMutex();
  final mutexDistance = ReadWriteMutex();
  final mutexTorque = ReadWriteMutex();

  bool isSimulatingBrain = false;

  int previousBufferTime = 0;

  // bool isNorthWest = false;
  // bool isNorthEast = false;
  // bool isSouthWest = false;
  // bool isSouthEast = false;
  List<String> isActiveLeds = ["0", "0", "0", "0"];

  int captureSteps = 0;

  late Directory captureDirectory;

  String strSerialDataBuff = "";
  String strTorqueDataBuff = "";

  bool canCaptureData = false;

  int flagCommandDataLength = -1;
  int flagSerialDataLength = -1;
  int flagTorqueDataLength = -1;

  String prevStrTorqueDataBuff = "";

  int aiTypeLength = 15;

  bool isShowDelayTime = false;
  int maxDelayTimeValue = 5000;
  int minDelayTimeValue = 100;

  late List<int> mapDelayNeuronList = [];
  late List<int> mapRhytmicNeuronList = [];
  late List<int> mapCountingNeuronList = [];

  List<SyntheticNeuron> rawSyntheticNeuronList = [];
  List<SyntheticNeuron> syntheticNeuronList = [];
  List<Connection> syntheticConnections = [];

  late Positioned toolbarMenu;

  List<InfiniteCanvasNode> sensoryNeurons = [];

  int modeIdx = -1;

  Offset centerZoneOffset = const Offset(320, 220);

  List<Widget> bottomRightMenuWidgets = [];

  Map<String, String> mapBg = {
    "activeComponent": "assets/bg/BrainDrawings/No_image.svg",
    "activeBg": "assets/bg/BrainDrawings/BrainFullBlack.svg",
  };

  /* DISTANCE SENSOR
  */
  int selectedDistanceIdx = 0;
  bool isShowingInfo = false;

  double leftInnerWindowSpace = 0;
  double topInnerWindowSpace = 0;

  double minDistanceSlider = 1;
  double maxDistanceSlider = 130;

  TextEditingController txtDistanceMinController =
      TextEditingController(text: "1");
  TextEditingController txtDistanceMaxController =
      TextEditingController(text: "8");

  int isBrainTargetOverlayTop = -1;

  int containedIdx = -1;

  int brainContainedIdx = -1;

  Offset prevConstrainedPos = Offset.zero;
  bool prevConstrainedFlag = true;

  // late StreamSubscription<ConnectivityResult> subscriptionWifi;

  void runNativeC() {
    const level = 1;
    const envelopeSize = 200;
    const bufferSize = 2000;
    nativec.initialize();
    print("motorCommandBufView.length");
    print(neuronSize);
    // print(motorCommandBufView.length);
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
      neuronContactsBuf,
      mapNeuronTypeBuf,
      mapDelayNeuronBuf,
      mapRhytmicNeuronBuf,
      mapCountingNeuronBuf,
    );
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

    mapNeuronTypeBuf = allocate<ffi.Int16>(
        count: maxPosBuffer, sizeOfType: ffi.sizeOf<ffi.Int16>());
    mapDelayNeuronBuf = allocate<ffi.Int16>(
        count: maxPosBuffer * maxPosBuffer,
        sizeOfType: ffi.sizeOf<ffi.Int16>());
    mapRhytmicNeuronBuf = allocate<ffi.Int16>(
        count: maxPosBuffer * maxPosBuffer,
        sizeOfType: ffi.sizeOf<ffi.Int16>());
    mapCountingNeuronBuf = allocate<ffi.Int16>(
        count: maxPosBuffer * maxPosBuffer,
        sizeOfType: ffi.sizeOf<ffi.Int16>());

    visPrefsBuf = allocate<ffi.Int16>(
        count: maxPosBuffer * maxPosBuffer,
        sizeOfType: ffi.sizeOf<ffi.Int16>());
    visPrefsValsBuf = allocate<ffi.Double>(
        count: VisualPrefLength, sizeOfType: ffi.sizeOf<ffi.Double>());
    connectomeBuf = allocate<ffi.Double>(
        count: maxPosBuffer * maxPosBuffer,
        sizeOfType: ffi.sizeOf<ffi.Double>());
    neuronContactsBuf = allocate<ffi.Double>(
        count: maxPosBuffer * maxPosBuffer,
        sizeOfType: ffi.sizeOf<ffi.Double>());
    neuronDistanceBuf = allocate<ffi.Int16>(
        count: maxPosBuffer * maxPosBuffer,
        sizeOfType: ffi.sizeOf<ffi.Int16>());
    neuronSpeakerBuf = allocate<ffi.Int16>(
        count: maxPosBuffer * maxPosBuffer,
        sizeOfType: ffi.sizeOf<ffi.Int16>());
    neuronMicrophoneBuf = allocate<ffi.Int16>(
        count: maxPosBuffer * maxPosBuffer,
        sizeOfType: ffi.sizeOf<ffi.Int16>());
    neuronLedBuf = allocate<ffi.Int16>(
        count: maxPosBuffer * maxPosBuffer,
        sizeOfType: ffi.sizeOf<ffi.Int16>());
    neuronLedPositionBuf = allocate<ffi.Int16>(
        count: maxPosBuffer * maxPosBuffer,
        sizeOfType: ffi.sizeOf<ffi.Int16>());

    distanceBuf = allocate<ffi.Double>(
        count: bufDistanceCount, sizeOfType: ffi.sizeOf<ffi.Double>());

    // up to 144 neurons
    if (!isInitialized) {
      distanceMinLimitBuf = allocate<ffi.Int16>(
          count: bufDistanceLimitCount, sizeOfType: ffi.sizeOf<ffi.Int16>());
      distanceMaxLimitBuf = allocate<ffi.Int16>(
          count: bufDistanceLimitCount, sizeOfType: ffi.sizeOf<ffi.Int16>());
    }

    motorCommandBuf = allocate<ffi.Double>(
        count: motorCommandsLength, sizeOfType: ffi.sizeOf<ffi.Double>());

    stateBuf = allocate<ffi.Int32>(
        count: StateLength, sizeOfType: ffi.sizeOf<ffi.Int>());
    motorCommandMessageBuf = allocate<ffi.Uint8>(
        count: MotorMessageLength, sizeOfType: ffi.sizeOf<ffi.Uint8>());
    print("Init memory allocation");
    mapDelayNeuronList = List.generate(neuronSize, (index) => -1);
    mapRhytmicNeuronList = List.generate(neuronSize, (index) => -1);
    mapCountingNeuronList = List.generate(neuronSize, (index) => -1);
  }

  void initNativeC(bool isInitialized) {
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
      // print("try to pass pointers");

      nativec = Nativec();
      nativec.passInput(distanceBuf, distanceMinLimitBuf, distanceMaxLimitBuf);
      nativec.passPointers(
        Nativec.canvasBuffer1!,
        positionsBuf,
        neuronCircleBuf,
        npsBuf,
        stateBuf,
        visPrefsBuf,
        visPrefsValsBuf,
        motorCommandMessageBuf,
        neuronContactsBuf,
        neuronDistanceBuf,
        neuronSpeakerBuf,
        neuronMicrophoneBuf,
        neuronLedBuf,
        neuronLedPositionBuf,
      );
      // print("try to pass nativec pointers");
      aBufView = aBuf.asTypedList(neuronSize);
      bBufView = bBuf.asTypedList(neuronSize);
      cBufView = cBuf.asTypedList(neuronSize);
      dBufView = dBuf.asTypedList(neuronSize);
      iBufView = iBuf.asTypedList(neuronSize);
      wBufView = wBuf.asTypedList(neuronSize);
      npsBufView = npsBuf.asTypedList(2);
      // print("neuronSize neuronCircleBridge");
      // print(neuronSize);
      neuronCircleBridge = neuronCircleBuf.asTypedList(neuronSize);
      print(neuronCircleBridge.length);
      positionsBufView = positionsBuf.asTypedList(bufPositionCount);
      distanceBufView = distanceBuf.asTypedList(bufDistanceCount);
      distanceMinLimitBufView =
          distanceMinLimitBuf.asTypedList(bufDistanceLimitCount);
      distanceMaxLimitBufView =
          distanceMaxLimitBuf.asTypedList(bufDistanceLimitCount);
      connectomeBufView = connectomeBuf.asTypedList(neuronSize * neuronSize);
      visPrefsBufView = visPrefsBuf.asTypedList(neuronSize * neuronSize);
      visPrefsValsBufView = visPrefsValsBuf.asTypedList(VisualPrefLength);
      motorCommandBufView = motorCommandBuf.asTypedList(motorCommandsLength);
      neuronContactsBufView =
          neuronContactsBuf.asTypedList(neuronSize * neuronSize);
      neuronDistanceBufView =
          neuronDistanceBuf.asTypedList(neuronSize * neuronSize);
      neuronSpeakerBufView =
          neuronSpeakerBuf.asTypedList(neuronSize * neuronSize);
      neuronMicrophoneBufView =
          neuronMicrophoneBuf.asTypedList(neuronSize * neuronSize);
      neuronLedBufView = neuronLedBuf.asTypedList(neuronSize * neuronSize);
      neuronLedPositionBufView =
          neuronLedPositionBuf.asTypedList(neuronSize * neuronSize);

      mapNeuronTypeBufView = mapNeuronTypeBuf.asTypedList(neuronSize);
      mapDelayNeuronBufView = mapDelayNeuronBuf.asTypedList(neuronSize);
      mapRhytmicNeuronBufView = mapRhytmicNeuronBuf.asTypedList(neuronSize);
      mapCountingNeuronBufView = mapCountingNeuronBuf.asTypedList(neuronSize);

      // if (!isSimulationCallbackAttached) {
      //   isSimulationCallbackAttached = true;
      nativec.simulationCallback(updateFromSimulation);
      // }
    }

    // if (isInitialized) {
    // print("isInitialized anandasd");
    aBufView.fillRange(0, neuronSize, a);
    bBufView.fillRange(0, neuronSize, b);
    cBufView.fillRange(0, neuronSize, c);
    dBufView.fillRange(0, neuronSize, d);
    iBufView.fillRange(0, neuronSize, i);
    wBufView.fillRange(0, neuronSize, w);
    // }
    positionsBufView.fillRange(0, 1, 0);
    distanceBufView.fillRange(0, 1, 0);
    distanceMinLimitBufView.fillRange(0, bufDistanceLimitCount, 1);
    distanceMaxLimitBufView.fillRange(0, bufDistanceLimitCount, 8);
    // distanceLimitBufView[0] = 1;
    // distanceLimitBufView[1] = 8;

    connectomeBufView.fillRange(0, neuronSize * neuronSize, 0.0);
    visPrefsBufView.fillRange(0, neuronSize * neuronSize, -1);
    visPrefsValsBufView.fillRange(0, VisualPrefLength, 0);

    mapNeuronTypeBufView.fillRange(0, neuronSize, -1);
    mapDelayNeuronBufView.fillRange(0, neuronSize, -1);
    mapRhytmicNeuronBufView.fillRange(0, neuronSize, -1);
    mapCountingNeuronBufView.fillRange(0, neuronSize, -1);

    neuronContactsBufView.fillRange(0, neuronSize * neuronSize, 0);
    motorCommandBufView.fillRange(0, motorCommandsLength, 0.0);

    print("neuronSize * neuronSize");
    print(neuronSize * neuronSize);

    squareActiveCirclesPainter = List<SingleSquare>.generate(
        neuronSize, (index) => SingleSquare(isActive: true));
    squareInactiveCirclesPainter = List<SingleSquare>.generate(
        neuronSize, (index) => SingleSquare(isActive: false));

    squareActiveCircles = List<CustomPaint>.generate(neuronSize, (int idx) {
      return CustomPaint(
        // painter: SingleSquare(isActive: true),
        painter: squareActiveCirclesPainter[idx],
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

    neuronActiveCirclesPainter =
        List<SingleCircle>.generate(neuronSize, (index) {
      return SingleCircle(
        isActive: true,
        circleRadius: neuronDrawSize / 2,
        xNucleus: syntheticNeuronList[index].newNeuron.xNucleus,
        yNucleus: syntheticNeuronList[index].newNeuron.yNucleus,
        widthNucleus: syntheticNeuronList[index].newNeuron.widthNucleus,
        heightNucleus: syntheticNeuronList[index].newNeuron.heightNucleus,
      );
    });
    neuronInactiveCirclesPainter =
        List<SingleCircle>.generate(neuronSize, (index) {
      return SingleCircle(
        isActive: false,
        circleRadius: neuronDrawSize / 2,
        xNucleus: syntheticNeuronList[index].newNeuron.xNucleus,
        yNucleus: syntheticNeuronList[index].newNeuron.yNucleus,
        widthNucleus: syntheticNeuronList[index].newNeuron.widthNucleus,
        heightNucleus: syntheticNeuronList[index].newNeuron.heightNucleus,
      );
    });

    neuronActiveCircles = List<CustomPaint>.generate(neuronSize, (int idx) {
      return CustomPaint(
        painter: neuronActiveCirclesPainter[idx],
        willChange: false,
        isComplex: false,
      );
    });

    neuronInactiveCircles = List<CustomPaint>.generate(neuronSize, (int idx) {
      return CustomPaint(
        painter: neuronInactiveCirclesPainter[idx],
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

  static int aiVisualTypes = 0;
  static int imageVisualTypes = 0;

  Map mapConnectome = {};
  Map mapSensoryNeuron = {}; // vis prefs
  Map mapContactsNeuron = {};
  Map mapDistanceNeuron = {}; // dist prefs
  Map mapDistanceLimitNeuron = {}; // dist limit prefs
  Map mapSpeakerNeuron = {};
  Map mapMicrophoneNeuron = {};
  Map mapLedNeuron = {};
  Map mapLedNeuronPosition = {};

  List<UniqueKey> neuronsKey = [];
  List<UniqueKey> axonsKey = [];

  Offset constraintOffsetTopLeftRaw = const Offset(300, 170);
  Offset constraintOffsetTopRightRaw = const Offset(500, 170);
  Offset constraintOffsetBottomRightRaw = const Offset(500, 430);
  Offset constraintOffsetBottomLeftRaw = const Offset(300, 430);

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
    // @New Design
    // offset: const Offset(395, 150),
    offset: const Offset(220, 120),

    // offset: const Offset(852.0 / 2, 150),
    size: const Size(20, 20),
    child: Container(width: 15, height: 15, color: Colors.black),
  );

  InfiniteCanvasNode nodeLeftEyeSensor = InfiniteCanvasNode(
    key: UniqueKey(),
    value: 1,
    allowMove: false,
    allowResize: false,
    // @New Design
    // offset: const Offset(320, 150),
    offset: const Offset(410, 100),

    size: const Size(20, 20),
    child: Container(width: 15, height: 15, color: Colors.black),
  );
  InfiniteCanvasNode nodeRightEyeSensor = InfiniteCanvasNode(
    key: UniqueKey(),
    value: 2,
    allowMove: false,
    allowResize: false,
    // @New Design
    // offset: const Offset(470, 150),
    // size: const Size(20, 20),
    offset: const Offset(0, 0),
    size: const Size(0, 0),
    child: Container(width: 15, height: 15, color: Colors.black),
  );

  InfiniteCanvasNode nodeMicrophoneSensor = InfiniteCanvasNode(
    key: UniqueKey(),
    value: 3,
    allowMove: false,
    allowResize: false,
    // @New Design
    // offset: const Offset(267, 217),
    offset: const Offset(600, 170),
    size: const Size(20, 20),
    child: Container(width: 15, height: 15, color: Colors.black),
  );
  InfiniteCanvasNode nodeSpeakerSensor = InfiniteCanvasNode(
    key: UniqueKey(),
    value: 4,
    allowMove: false,
    allowResize: false,
    // @New Design
    // offset: const Offset(523, 217),
    offset: const Offset(535, 495),
    size: const Size(20, 20),
    child: Container(width: 15, height: 15, color: Colors.black),
  );

  InfiniteCanvasNode nodeLeftMotorForwardSensor = InfiniteCanvasNode(
    key: UniqueKey(),
    value: 5,
    allowMove: false,
    allowResize: false,
    // @New Design
    // offset: const Offset(243, 310),
    offset: const Offset(173, 240),
    size: const Size(20, 20),
    child: Container(width: 15, height: 15, color: Colors.black),
  );
  InfiniteCanvasNode nodeRightMotorForwardSensor = InfiniteCanvasNode(
    key: UniqueKey(),
    value: 6,
    allowMove: false,
    allowResize: false,
    // @New Design
    // offset: const Offset(547, 310),
    offset: const Offset(610, 280),
    size: const Size(20, 20),
    child: Container(width: 15, height: 15, color: Colors.black),
  );

  InfiniteCanvasNode nodeLeftMotorBackwardSensor = InfiniteCanvasNode(
    key: UniqueKey(),
    value: 7,
    allowMove: false,
    allowResize: false,
    // @New Design
    // offset: const Offset(240, 405),
    offset: const Offset(170, 350),
    size: const Size(20, 20),
    child: Container(width: 15, height: 15, color: Colors.black),
  );
  InfiniteCanvasNode nodeRightMotorBackwardSensor = InfiniteCanvasNode(
    key: UniqueKey(),
    value: 8,
    allowMove: false,
    allowResize: false,
    // @New Design
    // offset: const Offset(550, 405),
    offset: const Offset(600, 390),
    size: const Size(20, 20),
    child: Container(width: 15, height: 15, color: Colors.black),
  );

  InfiniteCanvasNode nodeRedLed = InfiniteCanvasNode(
    key: UniqueKey(),
    value: 9,
    allowMove: false,
    allowResize: false,
    offset: const Offset(320, 457),
    size: const Size(20, 20),
    child: Container(width: 15, height: 15, color: Colors.red),
  );
  InfiniteCanvasNode nodeGreenLed = InfiniteCanvasNode(
    key: UniqueKey(),
    value: 10,
    allowMove: false,
    allowResize: false,
    offset: const Offset(395, 437),
    size: const Size(20, 20),
    child: Container(width: 15, height: 15, color: Colors.green),
  );
  InfiniteCanvasNode nodeBlueLed = InfiniteCanvasNode(
    key: UniqueKey(),
    value: 11,
    allowMove: false,
    allowResize: false,
    offset: const Offset(470, 457),
    size: const Size(20, 20),
    child: Container(width: 15, height: 15, color: Colors.lightBlue),
  );

  double constraintBrainLeft = 300.0;
  double constraintBrainRight = 500.0;
  double constraintBrainTop = 170.0;
  double constraintBrainBottom = 430.0;

  double aspectRatio = 1.0;
  double prevScreenWidth = 870.0;
  double prevScreenHeight = 600.0;
  double screenWidth = 870.0;
  double screenHeight = 600.0;

  double prevWindowWidth = 870.0;
  double prevWindowHeight = 600.0;
  double windowWidth = 870.0;
  double windowHeight = 600.0;

  double currentImageWidth = 600.0;
  double currentImageHeight = 600.0;
  // double screenDensity = 1.0;
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
    // windowManager.removeListener(this);
    detector?.stop();
    _imageDetectorSubscription?.cancel();

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
    freeMemory(visPrefsValsBuf);
    freeMemory(Nativec.canvasBuffer1);
    // freeMemory(nativec.canvasBuffer2);
    freeMemory(mapNeuronTypeBuf);
    freeMemory(mapDelayNeuronBuf);
    freeMemory(mapRhytmicNeuronBuf);
    freeMemory(mapCountingNeuronBuf);
  }

  Future<String> startWebSocket() async {
    // const String webSocketLink = 'ws://192.168.4.1:81/ws';
    const String webSocketLink = 'ws://192.168.4.1:80/ws';
    // if (!isIsolateWritePortInitialized) {
    writePort = ReceivePort();
    webSocket = await Isolate.spawn(
      createWebSocket,
      [writePort.sendPort, webSocketLink],
    );
    // }

    // writePort.sendPort.send(message)
    writePort.listen((message) async {
      if (message is SendPort) {
        isolateWritePort = message;
        isIsolateWritePortInitialized = true;
        // Timer.periodic(const Duration(milliseconds: 300), (timer) {
        //   isolateWritePort.send("test from flutter");
        // });
      } else if (message == "RESTART") {
        isIsolateWritePortInitialized = false;
        print("RESTart");
        try {
          writePort.close();
          webSocket.kill();
        } catch (err) {
          print("err disconnected");
          print(err);
        }

        Future.delayed(const Duration(milliseconds: 1000), () async {
          if (isPlayingMenu) {
            startWebSocket();
            mjpegComponent = Mjpeg(
              stream: httpdStream,
              // stream: "http://192.168.1.4:8081/",
              preprocessor: processor,
              width: 320 / 2,
              height: 240 / 2,

              isLive: true,
              fit: BoxFit.fitHeight,
              timeout: const Duration(seconds: 60),
            );
          }
          // writePort = ReceivePort();
          // webSocket = await Isolate.spawn(
          //   createWebSocket,
          //   [writePort.sendPort, webSocketLink],
          // );
        });
      } else if (message == "DISCONNECTED") {
        if (isPlayingMenu) {
          // it is already change to false by the user interaction
          writePort.close();
          webSocket.kill();
          isIsolateWritePortInitialized = false;
          // alertDialog(
          //   context,
          //   "NeuroRobot Connection Loss",
          //   "Connection with NeuroRobot was disconnected, please reconnect again",
          //   positiveButtonText: "OK",
          //   positiveButtonAction: () {
          //     isEmergencyPause = false;
          //     isPlayingMenu = false;
          //     setState(() {});
          //   },
          //   hideNeutralButton: true,
          //   closeOnBackPress: false,
          // );
        } else {
          isIsolateWritePortInitialized = false;
          try {
            writePort.close();
            webSocket.kill();
          } catch (err) {
            print("err disconnected");
            print(err);
          }
        }

        try {
          if (kIsWeb) {
            // js.context.callMethod("stopThreadProcess", [0]);
          } else {
            nativec.stopThreadProcess(0);
            isSimulatingBrain = false;
          }
          controller.deselectAll();
          controller.setCanvasMove(true);
        } catch (err) {}

        Future.delayed(const Duration(milliseconds: 1000), () {
          // rightToolbarGlobalKey = GlobalKey();
          rightToolbarCallback({"menuIdx": 0});
          rightToolbarKey = UniqueKey();
          setState(() {});
        });
        clearUIMenu();

        isEmergencyPause = false;
        isPlayingMenu = false;
        setState(() {});
      } else {
        // print("--${DateTime.now().millisecondsSinceEpoch}");
        if (flagSerialDataLength > 0) {
          strSerialDataBuff = "";
          flagSerialDataLength = -1;
        }
        mutexDistance.protectWrite(() async {
          strSerialDataBuff += (message + ";");
          return "";
        });

        List<String> arr = message.split(",");
        // print("arr");
        // print(arr);
        distanceBufView[0] = int.parse(arr[2]).toDouble();
        // print("distanceBufView[0]");
        // print(distanceBufView[0]);
        int baseBottomBattery = int.parse(arr[3]) - 590;
        // print("baseBottomBattery");
        // print(baseBottomBattery);
        // print(baseBottomBattery / 278 * 100);
        batteryPercent = (baseBottomBattery / 278 * 100).floor();
        if (batteryPercent > 100) {
          batteryPercent = 100;
        } else if (batteryPercent <= 0) {
          batteryPercent = 0;
        }
        String batteryPercentage = "${(batteryPercent).floor()}%";
        batteryVoltage = "${int.parse(arr[3]).toDouble()} ($batteryPercentage)";
        setState(() {});
      }
    });

    // isolateWritePort.send();

    return "";
  }

  void initImageDetector() async {
    // Uint8List bananaImage =
    //     (await rootBundle.load("assets/bg/banana.jpeg")).buffer.asUint8List();
    Detector.start().then((instance) {
      setState(() {
        detector = instance;
        _imageDetectorSubscription =
            instance.resultsStream.stream.listen((values) {
          setState(() {
            isCheckingImage = false;
            results = values['recognitions'];
            // print("results");
            // print(results);
            aiStats = values['stats'];
            if (results!.isNotEmpty) {
              aiStats?["Confidence Score"] =
                  '${results?[0].label} - ${results?[0].score}';
            }

            //[Recognition(id: 0, label: banana, score: 0.7578125, location: Rect.fromLTRB(45.7, 89.0, 239.0, 241.5)), Recognition(id: 1, label: banana, score: 0.5390625, location: Rect.fromLTRB(150.9, 110.2, 234.4, 235.4)), Recognition(id: 2, label: banana, score: 0.5234375, location: Rect.fromLTRB(121.7, 98.1, 205.1, 238.1))]
          });
          // print("AI Visual Input Cancel");

          for (int i = 0; i < aiTypeLength; i++) {
            visPrefsValsBufView[7 + i] = 0;
            visPrefsValsBufView[7 + i + rightEyeConstant] = 0;
          }

          if (results != null && results!.isNotEmpty) {
            // int detectionLength = results!.length;
            int detectionLength = 1;
            for (int i = 0; i < 1; i++) {
              int foundIdx = cameraMenuTypes.indexOf(results![i].label.trim());
              // reset value
              // set new value
              for (String key in mapSensoryNeuron.keys) {
                if (mapSensoryNeuron[key] == foundIdx) {
                  // print("results");
                  Recognition r = results![i];
                  if (key.contains(nodeLeftEyeSensor.key.toString()) &&
                      containImage(r.location, false)) {
                    visPrefsValsBufView[foundIdx] = results![i].score * 50;
                  } else if (key.contains(nodeRightEyeSensor.key.toString()) &&
                      containImage(r.location, true)) {
                    visPrefsValsBufView[foundIdx + rightEyeConstant] =
                        results![i].score * 50;
                  }
                  // print(foundIdx);
                  // print(visPrefsValsBufView);

                  // set visual preference = score * 50
                } else {
                  // set visual preference = 0;
                }
              }
            }
          }
          debouncerAIClassification.run(() {
            // print("AI Visual Input run");
            for (int i = 0; i < aiTypeLength; i++) {
              visPrefsValsBufView[7 + i] = 0;
              visPrefsValsBufView[7 + i + rightEyeConstant] = 0;
            }
            // print(visPrefsValsBufView);
          });
        });
      });

      // Future.delayed(const Duration(milliseconds: 500), () {
      //   detector?.processFrame(bananaImage);
      // });
    });
  }

  @override
  void onWindowResize() {
    print("onWindowResize");
    // get the current window size
    windowWidth = MediaQuery.of(context).size.width;
    windowHeight = MediaQuery.of(context).size.height;
    // calculate imageSize
    final Size containerSize =
        Size(windowWidth, windowHeight); // Replace with your container size
    final Size imageSize = Size(600, 600); // Replace with your image size

    final fittedSizes = applyBoxFit(BoxFit.contain, imageSize, containerSize);
    // reposition nodes
    // double scaleX = windowWidth / prevWindowWidth;
    // double scaleY = windowHeight / prevWindowHeight;
    print("fittedSizes.destination.width");
    print(fittedSizes.destination.width);
    print("fittedSizes.destination.height");
    print(fittedSizes.destination.height);
    double scaleX = fittedSizes.destination.width / imageSize.width;
    double scaleY = fittedSizes.destination.height / imageSize.height;
    print("Scale X");
    print(scaleX);
    print("Scale Y");
    print(scaleY);

    viewPortNode.update(offset: Offset(windowWidth, windowHeight));
    controller.getNode(viewportKey)?.offset = Offset(windowWidth, windowHeight);
    // int idx = 0;

    constraintOffsetTopLeft = Offset(
        constraintOffsetBottomLeftRaw.dx, constraintOffsetBottomLeftRaw.dy);
    constraintOffsetTopRight =
        Offset(constraintOffsetTopRightRaw.dx, constraintOffsetTopRightRaw.dy);
    constraintOffsetBottomRight = Offset(
        constraintOffsetBottomRightRaw.dx, constraintOffsetBottomRightRaw.dy);
    constraintOffsetBottomLeft = Offset(
        constraintOffsetBottomLeftRaw.dx, constraintOffsetBottomLeftRaw.dy);

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
    int idx = 0;
    for (var element in controller.nodes) {
      if (idx > 1) {
        element.offset = element.offset.scale(scaleX, scaleY);
      }
      idx++;
    }
    currentImageWidth = windowWidth;
    currentImageHeight = windowHeight;
  }

  @override
  void initState() {
    super.initState();
    // windowManager.addListener(this);

    initImageDetector();
    if (Platform.isIOS || Platform.isAndroid) {
      neuronDrawSize = 20;
    }
    pMapStatus["isSavingBrain"] = 1;
    pMapStatus["currentFileName"] = "-";

    String capturePath = Platform.pathSeparator + "capture";
    getApplicationDocumentsDirectory().then((documentDirectory) {
      captureDirectory = Directory("${documentDirectory.path}$capturePath");
      if (!captureDirectory.existsSync()) captureDirectory.createSync();
    });
    Size brainSize = const Size(370, 390);
    constraintBrainLeft = (screenWidth - brainSize.width) / 2;
    constraintBrainTop = (screenHeight - brainSize.height) / 2 + 10;
    constraintBrainRight = screenWidth / 2 + brainSize.width / 2;
    constraintBrainBottom = (screenHeight + brainSize.height) / 2 - 50;

    constraintOffsetTopLeft = Offset(constraintBrainLeft, constraintBrainTop);
    constraintOffsetTopRight = Offset(constraintBrainRight, constraintBrainTop);
    constraintOffsetBottomRight =
        Offset(constraintBrainRight, constraintBrainBottom);
    constraintOffsetBottomLeft =
        Offset(constraintBrainLeft, constraintBrainBottom);

    // @New Design
    print("INIT STATEEE");
    try {
      initMemoryAllocation();
      initNativeC(true);
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

    processor = ImagePreprocessor();
    processor.isRunning = true;
    mjpegComponent = Mjpeg(
      stream: httpdStream,
      // stream: "http://192.168.1.4:8081/",
      preprocessor: processor,
      width: 320 / 2,
      height: 240 / 2,

      isLive: true,
      fit: BoxFit.fitHeight,
      timeout: const Duration(seconds: 60),
    );

    // List<String> empty = [];
    // previousBufferTime = DateTime.now().millisecondsSinceEpoch;
    // Timer.periodic(const Duration(milliseconds: 20), (timer) async {
    // });
    previousBufferTime = DateTime.now().millisecondsSinceEpoch;
    processRobotMessages();

    Timer.periodic(const Duration(milliseconds: 70), (timer) {
      if (isChartSelected) {
        // print("redraw");
        // print(Nativec.canvasBufferBytes1);
        waveRedraw.value = Random().nextInt(10000);
      }
      if (isPlayingMenu) {
        // for (int i = circleNeuronStartIndex - allNeuronStartIdx; i < neuronSize; i++) {
        // print("neuronCircleBridge");
        // print(neuronCircleBridge);
        /* MOVED TO PROCESS ROBOT MESSAGE
        try {
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
        } catch (err) {
          print(err);
        }
        */
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // print("BUILD WIDGET");
    if (packageInfo == null) {
      Future.delayed(const Duration(milliseconds: 10), () async {
        packageInfo = await PackageInfo.fromPlatform();
      });
    }
    if (isInitialized) {
      controller.dropTargets = (getDragTargets());
    }

    screenWidth = MediaQuery.of(context).size.width;
    screenHeight = MediaQuery.of(context).size.height;
    // screenDensity = MediaQuery.of(context).devicePixelRatio;

    safePadding = MediaQuery.of(context).padding.right;
    // aspectRatio = MediaQuery.of(context).devicePixelRatio;
    // Future.delayed(const Duration(milliseconds: 2000), (){
    //   repositionSensoryNeuron();
    // });

    if (!isInitialized && screenWidth > screenHeight) {
      initCanvas();
      isInitialized = true;
      repositionContactNeurons();

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
    // STEVANUS :
    // remove this
    if (isResizingFlag) {
      // print("isResizingFlag");
      viewPortNode.update(offset: Offset(screenWidth, screenHeight));
      controller.getNode(viewportKey)?.offset =
          Offset(screenWidth, screenHeight);
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

      repositionContactNeurons();
      int idx = 0;
      for (var element in controller.nodes) {
        if (idx > 13) {
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
          child: GestureDetector(
            onTap: () {
              nativec.changeIdxSelected(i);
            },
            child: SizedBox(
              width: neuronDrawSize,
              height: neuronDrawSize,
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
          ),
        ));
      }
    }
    // mainBody = Text(
    //   // String.fromCharCode(0x1F48E),
    //   String.fromCharCode(0x1F9E0),
    //   style: const TextStyle(fontFamily: "BybHanddrawn"),
    // );
    mainBody = !isInitialized
        ? const SizedBox()
        : prepareWidget(
            InfiniteCanvas(
              activeComponent: (ctx, r) {
                return Container(
                  color: Colors.transparent,
                  width: screenWidth,
                  height: screenHeight,
                  child: SvgPicture.asset(
                      width: screenWidth,
                      height: screenHeight,
                      fit: BoxFit.contain,
                      // @New Design
                      mapBg["activeComponent"]!),
                  // "assets/bg/BrainDrawings/BrainFullGrey.svg"),
                );
              },
              backgroundBuilder: (ctx, r) {
                // print("MediaQuery.of(context).screenWidth");
                // print(screenWidth);
                // print(screenHeight);
                // print(r);

                return Container(
                  color: const Color(0xFF5DA6EE),
                  width: screenWidth,
                  height: screenHeight,
                  child: SvgPicture.asset(
                      width: screenWidth,
                      height: screenHeight,
                      // scale: screenWidth/800,
                      fit: BoxFit.contain,
                      // scale: density,
                      // "assets/bg/bg1.0x.jpeg"),
                      // "assets/bg/Spikerbot2Vector.svg"),
                      // @New Design
                      // "assets/bg/BrainDrawings/BrainFullBlack.svg"),
                      mapBg["activeBg"]!),
                );
              },
              drawVisibleOnly: true,
              canAddEdges: true,
              menuVisible: false,
              controller: controller,
            ),
          );

    List<Widget> inlineWidgets = [];
    // @New Design
    // if (modeIdx == -1) {
    //   dragTargetWidgets = [];
    // }
    if (isPlayingMenu) {
      if (!isChartSelected) {
        inlineWidgets.add(Positioned(
          bottom: 100,
          right: 17 + safePadding,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(56, 56),
              maximumSize: const Size(76, 76),
              elevation: 7,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                  side: const BorderSide(color: Colors.transparent)),
              padding: Platform.isMacOS || Platform.isWindows
                  ? const EdgeInsets.symmetric(horizontal: 15, vertical: 22)
                  : const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
            ),
            child: const Icon(Icons.stacked_line_chart_rounded,
                color: Colors.black),
            onPressed: () {
              isChartSelected = true;
              setState(() {});
            },
          ),
        ));

        inlineWidgets.add(Positioned(
          bottom: 20,
          left: 20,
          child: SizedBox(
            width: 50,
            height: 80,
            child: Column(
              children: [
                BatteryGauge(
                    size: const Size(30, 50),
                    value: batteryPercent,
                    borderColor: Colors.black,
                    valueColor:
                        batteryPercent <= 25 ? Colors.red : Colors.black),
                Text(
                  "$batteryPercent%",
                  style: const TextStyle(fontSize: 17),
                ),
              ],
            ),
          ),
        ));
      } else {
        inlineWidgets.add(Positioned(
          bottom: MediaQuery.of(context).size.height / 2 - 130,
          right: 17 + safePadding,
          child: SizedBox(
            width: 150,
            height: 40,
            child: CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text("Capture Data"),
              value: canCaptureData,
              controlAffinity: ListTileControlAffinity.leading,
              onChanged: (flag) {
                canCaptureData = flag!;
                setState(() {});
              },
            ),
          ),
        ));
        inlineWidgets.add(Positioned(
          bottom: MediaQuery.of(context).size.height / 2 - 130 + 50,
          right: 17 + safePadding,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(56, 56),
              // maximumSize: const Size(56, 56),
              elevation: 7,
              padding: Platform.isMacOS || Platform.isWindows
                  ? const EdgeInsets.symmetric(horizontal: 15, vertical: 22)
                  : const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
              backgroundColor: const Color(0xFF00ABFF),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                  side: const BorderSide(color: Colors.transparent)),
            ),
            child: const Icon(Icons.stacked_line_chart_rounded,
                color: Colors.black),
            onPressed: () {
              isChartSelected = false;
              setState(() {});
            },
          ),
        ));
        inlineWidgets.add(Positioned(
          bottom: MediaQuery.of(context).size.height / 2 - 110,
          left: 20,
          child: SizedBox(
            width: 50,
            height: 80,
            child: Column(
              children: [
                BatteryGauge(
                    size: const Size(30, 50),
                    value: batteryPercent,
                    borderColor: Colors.black,
                    valueColor:
                        batteryPercent <= 25 ? Colors.red : Colors.black),
                Text(
                  "$batteryPercent%",
                  style: const TextStyle(fontSize: 17),
                ),
              ],
            ),
          ),
        ));
      }
    }

    if (!isPlayingMenu && isNeuronMenu && controller.hasSelection) {
      inlineWidgets.add(
        Positioned(
            top: 20,
            right: 20,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 7, 8, 3),
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(0, 0, 22, 0),
                      child: Text(
                        "Neuron${controller.selection[0].id}",
                        textAlign: TextAlign.end,
                        style: const TextStyle(
                          fontSize: 17,
                        ),
                      ),
                    ),
                    const Divider(height: 2),
                    DropdownButton(
                      alignment: Alignment.centerRight,
                      style: const TextStyle(
                        fontSize: 17.0,
                        color: Colors.black,
                      ),
                      underline: Container(
                        height: 1,
                      ),
                      value: neuronMenuType,
                      items: dropdownNeuronItems,
                      onChanged: (value) {
                        neuronMenuType = value;
                        neuronTypeChangeCallback(neuronMenuType);
                        if (value == "Delay") {
                          isShowDelayTime = true;
                          sldTimeValue = 3000;
                        } else {
                          isShowDelayTime = false;
                          // sldTimeValue = 1000;
                        }
                        tecTimeValue.text = sldTimeValue.floor().toString();
                        try {
                          InfiniteCanvasNode selected = controller.selection[0];
                          int neuronIdx = controller.nodes
                                  .map((e) => e.id)
                                  .toList()
                                  .indexOf(selected.id) -
                              2;

                          nativec.changeIdxSelected(neuronIdx);
                          if (value == "Delay") {
                            mapDelayNeuronList[neuronIdx] =
                                sldTimeValue.floor();
                          }
                        } catch (err) {
                          print("err");
                          print(err);
                        }

                        setState(() {});
                      },
                    ),
                    DropdownButton(
                      alignment: Alignment.centerRight,
                      style: const TextStyle(
                        fontSize: 17.0,
                        color: Colors.black,
                      ),
                      underline: Container(
                        height: 1,
                      ),
                      value: neuronStyle,
                      items: dropdownNeuronStyleItems,
                      onChanged: (value) {
                        neuronStyle = value;
                        if (value == "Custom") {
                          resizeIzhikevichParameters(neuronSize);
                          InfiniteCanvasNode selected = controller.selection[0];
                          int neuronIdx = controller.nodes
                                  .map((e) => e.id)
                                  .toList()
                                  .indexOf(selected.id) -
                              2;
                          bBufView[neuronIdx] = 0.18;
                          cBufView[neuronIdx] = -65;
                        }

                        try {
                          InfiniteCanvasNode selected = controller.selection[0];
                          neuronStyles[selected.id] = value;
                          // int neuronIdx = controller.nodes
                          //         .map((e) => e.id)
                          //         .toList()
                          //         .indexOf(selected.id) -
                          //     2;
                        } catch (err) {}
                        // neuronTypeChangeCallback(neuronMenuType);

                        setState(() {});
                      },
                    ),
                    if (neuronMenuType == "Custom") ...[
                      SizedBox(
                        width: MediaQuery.of(context).size.width / 4,
                        // height: MediaQuery.of(context).size.width / 4,
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.only(top: 5),
                              child: const Text("a :",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center),
                            ),
                            SizedBox(
                              width: 50,
                              height: 40,
                              child: TextField(
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true, signed: true),
                                inputFormatters:
                                    neuronListingTextInputFormatter,
                                maxLines: 1,
                                controller: tecAWeight,
                                onSubmitted: (value) {
                                  try {
                                    sldAWeight = double.parse(value);
                                    if (sldAWeight > 0.15) {
                                      sldAWeight = 0.15;
                                    }
                                    if (sldAWeight < 0) {
                                      sldAWeight = 0;
                                    }
                                    tecAWeight.text = sldAWeight.toString();

                                    resizeIzhikevichParameters(neuronSize);
                                    InfiniteCanvasNode selected =
                                        controller.selection[0];
                                    int neuronIdx = controller.nodes
                                            .map((e) => e.id)
                                            .toList()
                                            .indexOf(selected.id) -
                                        2;
                                    aDesignArray[selected.id] = sldAWeight;
                                    aBufView[neuronIdx] = sldAWeight;

                                    setState(() {});
                                  } catch (err) {}
                                },
                              ),
                            ),
                            Expanded(
                              child: SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  showValueIndicator: ShowValueIndicator.never,
                                ),
                                child: Slider(
                                  value: sldAWeight,
                                  min: 0,
                                  max: 0.15,
                                  divisions: 15,
                                  label: sldAWeight.round().toString(),
                                  onChanged: (double value) {
                                    value = (value * 100).round() / 100;
                                    sldAWeight = value;
                                    tecAWeight.text = (value).toString();
                                    resizeIzhikevichParameters(neuronSize);
                                    InfiniteCanvasNode selected =
                                        controller.selection[0];
                                    int neuronIdx = controller.nodes
                                            .map((e) => e.id)
                                            .toList()
                                            .indexOf(selected.id) -
                                        2;
                                    aDesignArray[selected.id] = sldAWeight;
                                    aBufView[neuronIdx] = sldAWeight;

                                    setState(() {});
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: MediaQuery.of(context).size.width / 4,
                        // height: MediaQuery.of(context).size.width / 4,
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.only(top: 5),
                              child: const Text("b :",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center),
                            ),
                            SizedBox(
                              width: 50,
                              height: 40,
                              child: TextField(
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true, signed: true),
                                inputFormatters:
                                    neuronListingTextInputFormatter,
                                maxLines: 1,
                                controller: tecBWeight,
                                onSubmitted: (value) {
                                  try {
                                    sldBWeight = double.parse(value);
                                    if (sldBWeight > 0.5) {
                                      sldBWeight = 0.5;
                                    }
                                    if (sldBWeight < 0) {
                                      sldBWeight = 0;
                                    }
                                    tecBWeight.text = sldBWeight.toString();

                                    resizeIzhikevichParameters(neuronSize);
                                    InfiniteCanvasNode selected =
                                        controller.selection[0];
                                    int neuronIdx = controller.nodes
                                            .map((e) => e.id)
                                            .toList()
                                            .indexOf(selected.id) -
                                        2;
                                    bDesignArray[selected.id] = sldBWeight;
                                    bBufView[neuronIdx] = sldBWeight;

                                    setState(() {});
                                  } catch (err) {}
                                },
                              ),
                            ),
                            Expanded(
                              child: SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  showValueIndicator: ShowValueIndicator.never,
                                ),
                                child: Slider(
                                  value: sldBWeight,
                                  min: 0,
                                  max: 0.5,
                                  divisions: 100,
                                  label: sldBWeight.round().toString(),
                                  onChanged: (double value) {
                                    value = (value * 100).round() / 100;
                                    sldBWeight = value;
                                    // tecBWeight.text = value.toString();
                                    tecBWeight.text = (value).toString();

                                    resizeIzhikevichParameters(neuronSize);
                                    InfiniteCanvasNode selected =
                                        controller.selection[0];
                                    int neuronIdx = controller.nodes
                                            .map((e) => e.id)
                                            .toList()
                                            .indexOf(selected.id) -
                                        2;
                                    bDesignArray[selected.id] = sldBWeight;
                                    bBufView[neuronIdx] = sldBWeight;

                                    setState(() {});
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: MediaQuery.of(context).size.width / 4,
                        // height: MediaQuery.of(context).size.width / 4,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.only(top: 5),
                              child: const Text("c :",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center),
                            ),
                            SizedBox(
                              width: 50,
                              height: 40,
                              child: TextField(
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true, signed: true),
                                inputFormatters:
                                    neuronListingTextInputFormatter,
                                maxLines: 1,
                                controller: tecCWeight,
                                onSubmitted: (value) {
                                  try {
                                    sldCWeight = double.parse(value);
                                    if (sldCWeight > 0) {
                                      sldCWeight = 0;
                                    }
                                    if (sldCWeight < -100) {
                                      sldCWeight = -100;
                                    }

                                    sldCWeight = sldCWeight.roundToDouble();
                                    tecCWeight.text =
                                        sldCWeight.round().toString();
                                    resizeIzhikevichParameters(neuronSize);
                                    InfiniteCanvasNode selected =
                                        controller.selection[0];
                                    int neuronIdx = controller.nodes
                                            .map((e) => e.id)
                                            .toList()
                                            .indexOf(selected.id) -
                                        2;
                                    cDesignArray[selected.id] =
                                        sldCWeight.floor();
                                    cBufView[neuronIdx] = sldCWeight.floor();

                                    setState(() {});
                                  } catch (err) {}
                                },
                              ),
                            ),
                            Expanded(
                              child: SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  showValueIndicator: ShowValueIndicator.never,
                                ),
                                child: Slider(
                                  value: sldCWeight,
                                  min: -100,
                                  max: 0,
                                  divisions: 100,
                                  label: sldCWeight.round().toString(),
                                  onChanged: (double value) {
                                    sldCWeight = value;
                                    sldCWeight = sldCWeight.roundToDouble();
                                    tecCWeight.text = value.round().toString();
                                    resizeIzhikevichParameters(neuronSize);
                                    InfiniteCanvasNode selected =
                                        controller.selection[0];
                                    int neuronIdx = controller.nodes
                                            .map((e) => e.id)
                                            .toList()
                                            .indexOf(selected.id) -
                                        2;
                                    cDesignArray[selected.id] =
                                        sldCWeight.floor();
                                    cBufView[neuronIdx] = sldCWeight.floor();

                                    setState(() {});
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: MediaQuery.of(context).size.width / 4,
                        // height: MediaQuery.of(context).size.width / 4,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.only(top: 5),
                              child: const Text("d :",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center),
                            ),
                            SizedBox(
                              width: 50,
                              height: 40,
                              child: TextField(
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true, signed: true),
                                inputFormatters:
                                    neuronListingTextInputFormatter,
                                maxLines: 1,
                                controller: tecDWeight,
                                onSubmitted: (value) {
                                  try {
                                    sldDWeight = double.parse(value);
                                    if (sldDWeight > 10) {
                                      sldDWeight = 10;
                                    }
                                    if (sldDWeight < 0) {
                                      sldDWeight = 0;
                                    }

                                    sldDWeight = sldDWeight.roundToDouble();
                                    tecDWeight.text =
                                        sldDWeight.round().toString();
                                    resizeIzhikevichParameters(neuronSize);
                                    InfiniteCanvasNode selected =
                                        controller.selection[0];
                                    int neuronIdx = controller.nodes
                                            .map((e) => e.id)
                                            .toList()
                                            .indexOf(selected.id) -
                                        2;
                                    dDesignArray[selected.id] =
                                        sldDWeight.floor();
                                    dBufView[neuronIdx] = sldDWeight.floor();

                                    setState(() {});
                                  } catch (err) {}
                                },
                              ),
                            ),
                            Expanded(
                              child: SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  showValueIndicator: ShowValueIndicator.never,
                                ),
                                child: Slider(
                                  value: sldDWeight,
                                  min: 0,
                                  max: 10,
                                  divisions: 10,
                                  label: sldDWeight.round().toString(),
                                  onChanged: (double value) {
                                    sldDWeight = value;
                                    sldDWeight = sldDWeight.roundToDouble();
                                    tecDWeight.text = value.round().toString();
                                    resizeIzhikevichParameters(neuronSize);
                                    InfiniteCanvasNode selected =
                                        controller.selection[0];
                                    int neuronIdx = controller.nodes
                                            .map((e) => e.id)
                                            .toList()
                                            .indexOf(selected.id) -
                                        2;
                                    dDesignArray[selected.id] =
                                        sldDWeight.floor();
                                    dBufView[neuronIdx] = sldDWeight.floor();

                                    setState(() {});
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (isShowDelayTime) ...[
                      SizedBox(
                        width: MediaQuery.of(context).size.width / 4,
                        child: Row(
                          children: [
                            SizedBox(
                              width: 50,
                              height: 40,
                              child: TextField(
                                enabled: false,
                                keyboardType: TextInputType.number,
                                inputFormatters: whiteListingTextInputFormatter,
                                maxLines: 1,
                                controller: tecTimeValue,
                                onChanged: (value) {
                                  return;
                                  try {
                                    sldTimeValue = double.parse(value);
                                    if (sldTimeValue > maxDelayTimeValue) {
                                      sldTimeValue = 100;
                                    } else if (sldTimeValue < 0) {
                                      sldTimeValue = 0;
                                    }
                                    sldTimeValue = sldTimeValue.roundToDouble();
                                    tecTimeValue.text =
                                        sldTimeValue.round().toString();

                                    InfiniteCanvasNode selected =
                                        controller.selection[0];
                                    int neuronIdx = controller.nodes
                                            .map((e) => e.id)
                                            .toList()
                                            .indexOf(selected.id) -
                                        2;

                                    mapDelayNeuronList[neuronIdx] =
                                        sldTimeValue.floor();

                                    setState(() {});
                                  } catch (err) {}
                                },
                              ),
                            ),
                            Expanded(
                              child: SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  showValueIndicator: ShowValueIndicator.never,
                                ),
                                child: Slider(
                                  value: sldTimeValue,
                                  max: maxDelayTimeValue.toDouble(),
                                  min: minDelayTimeValue.toDouble(),
                                  divisions: 40,
                                  // label: maxDelayTimeValue.round().toString(),
                                  onChanged: (double value) {
                                    try {
                                      sldTimeValue = value;
                                      sldTimeValue =
                                          sldTimeValue.roundToDouble();
                                      tecTimeValue.text =
                                          value.round().toString();

                                      InfiniteCanvasNode selected =
                                          controller.selection[0];
                                      int neuronIdx = controller.nodes
                                              .map((e) => e.id)
                                              .toList()
                                              .indexOf(selected.id) -
                                          2;

                                      mapDelayNeuronList[neuronIdx] =
                                          sldTimeValue.floor();
                                    } catch (err) {}
                                    setState(() {});
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    ],
                  ],
                ),
              ),
            )),
      );
    } else if (!isPlayingMenu && isCameraMenu && controller.isSelectingEdge) {
      inlineWidgets.add(
        Positioned(
            right: 20,
            top: 20,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 7, 8, 3),
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(0, 0, 22, 0),
                      child: Text(
                        activeCameraType,
                        textAlign: TextAlign.end,
                        style: const TextStyle(
                          fontSize: 17,
                        ),
                      ),
                    ),
                    const Divider(height: 2),
                    DropdownButton(
                      alignment: Alignment.centerRight,
                      style: const TextStyle(
                        fontSize: 17.0,
                        color: Colors.black,
                      ),
                      underline: Container(
                        height: 1,
                      ),
                      value: cameraMenuType,
                      items: dropdownCameraItems,
                      onChanged: (value) {
                        cameraMenuType = value;
                        linkSensoryConnection(cameraMenuType);
                        setState(() {});
                      },
                    ),
                  ],
                ),
              ),
            )),
      );
    } else if (!isPlayingMenu && isDistanceMenu && controller.isSelectingEdge) {
      List<Map<String, String>> listDistanceInfo = [
        {"icon": "🛑", "label": "Near", "idx": "0"},
        {"icon": "⚠️", "label": "Medium", "idx": "1"},
        {"icon": "🏁", "label": "Far", "idx": "2"},
        {"icon": "📏", "label": "Custom", "idx": "3"},
      ];
      InfiniteCanvasNode selected = findNeuronByKey(controller.edgeSelected.to);
      int idx = neuronTypes.keys.toList().indexOf(selected.id);
      List<Widget> distanceToolboxWidgets =
          generateDistanceToolboxWidgets(listDistanceInfo, idx);

      // dropdownDistanceItems
      inlineWidgets.add(
        Positioned(
            right: 20,
            top: 20,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 7, 8, 3),
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Padding(
                      padding: EdgeInsets.fromLTRB(22, 0, 22, 0),
                      child: Text(
                        "Select a Distance for Spiking",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 17,
                        ),
                      ),
                    ),
                    const Divider(height: 2),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: distanceToolboxWidgets,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        if (selectedDistanceIdx == 3) ...[
                          SizedBox(
                            width: 40,
                            height: 20,
                            child: TextField(
                              textAlign: TextAlign.center,
                              controller: txtDistanceMinController,
                              keyboardType: TextInputType.number,
                              inputFormatters: whiteListingTextInputFormatter,
                              maxLines: 1,
                              onSubmitted: (str) {
                                // print("123");
                                if (str.trim() == "") {
                                  str = minDistanceSlider.toString();
                                }

                                if (double.tryParse(str) != null) {
                                  double val = double.parse(str);
                                  distanceMinLimitBufView[idx] = val.toInt();
                                  if (distanceMinLimitBufView[idx] >=
                                      maxDistanceSlider) {
                                    distanceMinLimitBufView[idx] =
                                        ((distanceMaxLimitBufView[idx] - 1) > 0
                                                ? (distanceMaxLimitBufView[
                                                        idx] -
                                                    1)
                                                : minDistanceSlider)
                                            .toInt();
                                  } else if (distanceMinLimitBufView[idx] <=
                                      0) {
                                    distanceMinLimitBufView[idx] =
                                        minDistanceSlider.toInt();
                                  } else if (distanceMinLimitBufView[idx] >=
                                      distanceMaxLimitBufView[idx]) {
                                    distanceMinLimitBufView[idx] =
                                        distanceMinLimitBufView[idx].toInt();
                                  }

                                  txtDistanceMinController.text =
                                      distanceMinLimitBufView[idx].toString();
                                } else {
                                  str = minDistanceSlider.toString();
                                }

                                linkDistanceConnection(distanceMenuType);
                                setState(() {});
                              },
                            ),
                          ),
                          const SizedBox(
                            width: 3,
                          ),
                          SizedBox(
                            width: 270,
                            child: FlutterSlider(
                              values: [
                                distanceMinLimitBufView[idx].toDouble(),
                                distanceMaxLimitBufView[idx].toDouble()
                              ],
                              rangeSlider: true,
                              min: minDistanceSlider,
                              max: maxDistanceSlider,
                              trackBar: FlutterSliderTrackBar(
                                inactiveTrackBarHeight: 20,
                                activeTrackBarHeight: 20,
                                inactiveTrackBar: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  color: Colors.black12,
                                  border:
                                      Border.all(width: 3, color: Colors.blue),
                                ),
                                activeTrackBar: BoxDecoration(
                                    borderRadius: BorderRadius.circular(4),
                                    color: Colors.green),
                              ),
                              onDragging:
                                  (handlerIndex, lowerValue, upperValue) {
                                distanceMinLimitBufView[idx] =
                                    lowerValue.toInt();
                                distanceMaxLimitBufView[idx] =
                                    upperValue.toInt();
                                txtDistanceMinController.text =
                                    distanceMinLimitBufView[idx].toString();
                                txtDistanceMaxController.text =
                                    distanceMaxLimitBufView[idx].toString();

                                linkDistanceConnection(distanceMenuType);
                                setState(() {});
                              },
                            ),
                          ),
                          const SizedBox(
                            width: 3,
                          ),
                          SizedBox(
                            width: 40,
                            height: 20,
                            child: TextField(
                              textAlign: TextAlign.center,
                              controller: txtDistanceMaxController,
                              keyboardType: TextInputType.number,
                              inputFormatters: whiteListingTextInputFormatter,
                              maxLines: 1,
                              onSubmitted: (str) {
                                if (str.trim() == "") {
                                  str = maxDistanceSlider.toString();
                                }

                                if (double.tryParse(str) != null) {
                                  double val = double.parse(str);
                                  distanceMaxLimitBufView[idx] = val.toInt();
                                  if (distanceMaxLimitBufView[idx] >=
                                      maxDistanceSlider) {
                                    distanceMaxLimitBufView[idx] =
                                        maxDistanceSlider.toInt();
                                  } else if (distanceMaxLimitBufView[idx] ==
                                      0) {
                                    distanceMaxLimitBufView[idx] =
                                        minDistanceSlider.toInt();
                                  } else if (distanceMaxLimitBufView[idx] <=
                                      distanceMinLimitBufView[idx]) {
                                    distanceMaxLimitBufView[idx] =
                                        maxDistanceSlider.toInt();
                                  }

                                  txtDistanceMaxController.text =
                                      distanceMaxLimitBufView[idx].toString();
                                } else {
                                  str = maxDistanceSlider.toString();
                                }
                                print("asd");
                                linkDistanceConnection(distanceMenuType);
                                setState(() {});
                              },
                            ),
                          ),
                        ]
                      ],
                    ),
                    !isShowingInfo
                        ? const SizedBox()
                        : Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border:
                                      Border.all(color: Colors.white, width: 2),
                                  color: Colors.white,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withOpacity(0.5),
                                      spreadRadius: 0.3,
                                      blurRadius: 0.3,
                                      offset: const Offset(
                                          1, 1), // changes position of shadow
                                    ),
                                  ],
                                ),
                                child: SvgPicture.asset(
                                  "assets/icons/Info.svg",
                                ),
                              ),
                              const SizedBox(
                                width: 10,
                                height: 10,
                              ),
                              SizedBox(
                                width: 300,
                                child: const Text(
                                  "NEURON will SPIKE when on object is in front of the robot at a set distance.",
                                  style: TextStyle(
                                    fontFamily: "BybHanddrawn",
                                  ),
                                  maxLines: 2,
                                ),
                              ),
                            ],
                          ),
                    // DropdownButton(
                    //   alignment: Alignment.centerRight,
                    //   style: const TextStyle(
                    //     fontSize: 17.0,
                    //     color: Colors.black,
                    //   ),
                    //   underline: Container(
                    //     height: 1,
                    //   ),
                    //   value: distanceMenuType,
                    //   items: dropdownDistanceItems,
                    //   onChanged: (value) {
                    //     distanceMenuType = value;
                    //     switch (distanceMenuType) {
                    //       case "Short":
                    //         selectedDistanceIdx = 0;
                    //         break;
                    //       case "Medium":
                    //         selectedDistanceIdx = 1;
                    //         break;
                    //       case "Long":
                    //         selectedDistanceIdx = 2;
                    //         break;
                    //       case "Custom":
                    //         selectedDistanceIdx = 3;
                    //         // need to get the upperbound and lowerbound value
                    //         /*
                    //         distanceLimitBufView[0] = arr[0];
                    //         distanceLimitBufView[1] = arr[1];
                    //         */
                    //         break;
                    //     }
                    //     linkDistanceConnection(distanceMenuType);
                    //     setState(() {});
                    //   },
                    // ),
                    const SizedBox(
                      width: 10,
                      height: 10,
                    ),
                  ],
                ),
              ),
            )),
      );
    } else if (!isPlayingMenu &&
        (isSpeakerMenu || isMicrophoneMenu) &&
        controller.isSelectingEdge) {
      inlineWidgets.add(
        Positioned(
            right: 20,
            top: 20,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 7, 8, 3),
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Center(
                      child: Text("Frequency Weight (Hz)",
                          style: TextStyle(fontSize: 17)),
                    ),
                    const Divider(height: 2),
                    SizedBox(
                      width: MediaQuery.of(context).size.width / 4,
                      // height: MediaQuery.of(context).size.width / 4,
                      child: Row(
                        children: [
                          SizedBox(
                            width: 50,
                            height: 40,
                            child: TextField(
                              keyboardType: TextInputType.number,
                              inputFormatters: whiteListingTextInputFormatter,
                              maxLines: 1,
                              controller: tecFrequencyWeight,
                              onChanged: (value) {
                                try {
                                  sldFrequencyWeight = double.parse(value);
                                  if (sldFrequencyWeight > 4978) {
                                    sldFrequencyWeight =
                                        isSpeakerMenu ? 4978 : 5000;
                                  } else if (isSpeakerMenu) {
                                    if (sldFrequencyWeight < 3) {
                                      sldFrequencyWeight = 3;
                                    }
                                  } else {
                                    if (sldFrequencyWeight < 3) {
                                      sldFrequencyWeight = 0;
                                    }
                                  }

                                  sldFrequencyWeight =
                                      sldFrequencyWeight.roundToDouble();
                                  tecFrequencyWeight.text =
                                      sldFrequencyWeight.round().toString();

                                  if (isSpeakerMenu) {
                                    linkSpeakerConnection(
                                        sldFrequencyWeight.toString());
                                  } else if (isMicrophoneMenu) {
                                    linkMicrophoneConnection(
                                        sldFrequencyWeight.toString());
                                  }

                                  setState(() {});
                                } catch (err) {}
                              },
                            ),
                          ),
                          Expanded(
                            child: SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                showValueIndicator: ShowValueIndicator.never,
                              ),
                              child: Slider(
                                value: sldFrequencyWeight,
                                min: isSpeakerMenu ? 3 : 0,
                                max: isSpeakerMenu ? 4978 : 5000,
                                divisions: isSpeakerMenu ? 4978 : 5000,
                                label: sldFrequencyWeight.round().toString(),
                                onChanged: (double value) {
                                  sldFrequencyWeight = value;
                                  sldFrequencyWeight =
                                      sldFrequencyWeight.roundToDouble();
                                  tecFrequencyWeight.text =
                                      value.round().toString();

                                  if (isSpeakerMenu) {
                                    linkSpeakerConnection(
                                        sldFrequencyWeight.toString());
                                  } else if (isMicrophoneMenu) {
                                    linkMicrophoneConnection(
                                        sldFrequencyWeight.toString());
                                  }

                                  setState(() {});
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            )),
      );
    } else if (!isPlayingMenu &&
        (isMotorMenu || isSynapseMenu) &&
        controller.isSelectingEdge) {
      inlineWidgets.add(
        Positioned(
            top: 20,
            right: 20,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 7, 8, 3),
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Center(
                      child: Text("Synaptic Weight",
                          style: TextStyle(fontSize: 17)),
                    ),
                    const Divider(height: 2),
                    SizedBox(
                      width: MediaQuery.of(context).size.width / 4,
                      // height: MediaQuery.of(context).size.width / 4,
                      child: Row(
                        children: [
                          SizedBox(
                            width: 30,
                            height: 40,
                            child: TextField(
                              keyboardType: TextInputType.number,
                              inputFormatters: whiteListingTextInputFormatter,
                              maxLines: 1,
                              controller: tecSynapticWeight,
                              onChanged: (value) {
                                try {
                                  sldSynapticWeight = double.parse(value);
                                  if (sldSynapticWeight > 100) {
                                    sldSynapticWeight = 100;
                                  } else if (sldSynapticWeight < 0) {
                                    sldSynapticWeight = 0;
                                  }
                                  sldSynapticWeight =
                                      sldSynapticWeight.roundToDouble();
                                  tecSynapticWeight.text =
                                      sldSynapticWeight.round().toString();
                                  if (isSynapseMenu) {
                                    linkNeuronConnection(
                                        sldSynapticWeight.toString());
                                  } else if (isMotorMenu) {
                                    linkMotorConnection(
                                        sldSynapticWeight.toString());
                                  }

                                  updateSyntheticConnection(
                                      controller.edgeSelected.from,
                                      controller.edgeSelected.to,
                                      sldSynapticWeight);

                                  setState(() {});
                                } catch (err) {}
                              },
                            ),
                          ),
                          Expanded(
                            child: SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                showValueIndicator: ShowValueIndicator.never,
                              ),
                              child: Slider(
                                value: sldSynapticWeight,
                                max: 100,
                                divisions: 100,
                                label: sldSynapticWeight.round().toString(),
                                onChanged: (double value) {
                                  try {
                                    sldSynapticWeight = value;
                                    sldSynapticWeight =
                                        sldSynapticWeight.roundToDouble();
                                    tecSynapticWeight.text =
                                        value.round().toString();

                                    if (isSynapseMenu) {
                                      linkNeuronConnection(
                                          sldSynapticWeight.toString());
                                    } else if (isMotorMenu) {
                                      linkMotorConnection(
                                          sldSynapticWeight.toString());
                                    }

                                    setState(() {});
                                  } catch (err) {}
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            )),
      );
    } else if (!isPlayingMenu && (isLedMenu) && controller.isSelectingEdge) {
      inlineWidgets.add(
        Positioned(
            top: 20,
            right: 20,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 7, 8, 3),
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Center(
                      child: Text("Synaptic Weight",
                          style: TextStyle(fontSize: 17)),
                    ),
                    const Divider(height: 2),
                    SizedBox(
                      width: MediaQuery.of(context).size.width / 4,
                      // height: MediaQuery.of(context).size.width / 4,
                      child: Row(
                        children: [
                          SizedBox(
                            width: 30,
                            height: 40,
                            child: TextField(
                              keyboardType: TextInputType.number,
                              inputFormatters: whiteListingTextInputFormatter,
                              maxLines: 1,
                              controller: tecSynapticWeight,
                              onChanged: (value) {
                                try {
                                  sldSynapticWeight = double.parse(value);
                                  if (sldSynapticWeight > 100) {
                                    sldSynapticWeight = 100;
                                  } else if (sldSynapticWeight < 0) {
                                    sldSynapticWeight = 0;
                                  }

                                  sldSynapticWeight =
                                      sldSynapticWeight.roundToDouble();
                                  final lastCreatedEdge =
                                      controller.edgeSelected;
                                  final neuronFrom =
                                      findNeuronByKey(lastCreatedEdge.from);
                                  final neuronTo =
                                      findNeuronByKey(lastCreatedEdge.to);
                                  mapLedNeuron[
                                          "${neuronFrom.id}_${neuronTo.id}"] =
                                      sldSynapticWeight;

                                  setState(() {});
                                } catch (err) {}
                              },
                            ),
                          ),
                          Expanded(
                            child: SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                showValueIndicator: ShowValueIndicator.never,
                              ),
                              child: Slider(
                                value: sldSynapticWeight,
                                max: 100,
                                divisions: 100,
                                label: sldSynapticWeight.round().toString(),
                                onChanged: (double value) {
                                  try {
                                    sldSynapticWeight = value.roundToDouble();
                                    tecSynapticWeight.text =
                                        value.round().toString();

                                    final lastCreatedEdge =
                                        controller.edgeSelected;
                                    final neuronFrom =
                                        findNeuronByKey(lastCreatedEdge.from);
                                    final neuronTo =
                                        findNeuronByKey(lastCreatedEdge.to);
                                    mapLedNeuron[
                                            "${neuronFrom.id}_${neuronTo.id}"] =
                                        sldSynapticWeight;

                                    setState(() {});
                                  } catch (err) {}

                                  setState(() {});
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Center(
                      child: Text("Active Lights"),
                    ),
                    Row(
                      children: [
                        Column(children: [
                          Checkbox(
                              value: isActiveLeds[0] == "1",
                              onChanged: (flag) {
                                if (flag!) {
                                  isActiveLeds[0] = "1";
                                } else {
                                  isActiveLeds[0] = "0";
                                }

                                final lastCreatedEdge = controller.edgeSelected;
                                final neuronFrom =
                                    findNeuronByKey(lastCreatedEdge.from);
                                final neuronTo =
                                    findNeuronByKey(lastCreatedEdge.to);
                                mapLedNeuronPosition[
                                        "${neuronFrom.id}_${neuronTo.id}"] =
                                    isActiveLeds.join();

                                setState(() {});
                              }),
                          Checkbox(
                              value: isActiveLeds[2] == "1",
                              onChanged: (flag) {
                                if (flag!) {
                                  isActiveLeds[2] = "1";
                                } else {
                                  isActiveLeds[2] = "0";
                                }

                                final lastCreatedEdge = controller.edgeSelected;
                                final neuronFrom =
                                    findNeuronByKey(lastCreatedEdge.from);
                                final neuronTo =
                                    findNeuronByKey(lastCreatedEdge.to);
                                mapLedNeuronPosition[
                                        "${neuronFrom.id}_${neuronTo.id}"] =
                                    isActiveLeds.join();

                                setState(() {});
                              }),
                        ]),
                        const Icon(Icons.access_alarm),
                        Column(children: [
                          Checkbox(
                              value: isActiveLeds[1] == "1",
                              onChanged: (flag) {
                                if (flag!) {
                                  isActiveLeds[1] = "1";
                                } else {
                                  isActiveLeds[1] = "0";
                                }

                                final lastCreatedEdge = controller.edgeSelected;
                                final neuronFrom =
                                    findNeuronByKey(lastCreatedEdge.from);
                                final neuronTo =
                                    findNeuronByKey(lastCreatedEdge.to);
                                mapLedNeuronPosition[
                                        "${neuronFrom.id}_${neuronTo.id}"] =
                                    isActiveLeds.join();

                                setState(() {});
                              }),
                          Checkbox(
                              value: isActiveLeds[3] == "1",
                              onChanged: (flag) {
                                if (flag!) {
                                  isActiveLeds[3] = "1";
                                } else {
                                  isActiveLeds[3] = "0";
                                }

                                final lastCreatedEdge = controller.edgeSelected;
                                final neuronFrom =
                                    findNeuronByKey(lastCreatedEdge.from);
                                final neuronTo =
                                    findNeuronByKey(lastCreatedEdge.to);
                                mapLedNeuronPosition[
                                        "${neuronFrom.id}_${neuronTo.id}"] =
                                    isActiveLeds.join();

                                setState(() {});
                              }),
                        ]),
                      ],
                    )
                  ],
                ),
              ),
            )),
      );
    }

    if (!isPlayingMenu && isDeleteMenu) {
      inlineWidgets.add(Positioned(
        bottom: 20,
        left: 20,
        child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              elevation: 7,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5.0),
                  side: const BorderSide(color: Colors.transparent)),
              backgroundColor: const Color(0xFFEF5B5C),
              padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 20),
            ),
            onPressed: () {
              if (isDrawTail) {
                deleteNeuronCallback();
                resetMouse();
              } else {
                deleteEdgeCallback();
                resetMouse();
              }
            },
            child: const Icon(
              size: 30,
              Icons.delete,
              color: Colors.black,
            )),
      ));
    }
    if (!isPlayingMenu) {
      toolbarMenu = Positioned(
        // right: 10 + safePadding,
        left: safePadding,
        top: 10,
        child: LeftToolbar(
            key: rightToolbarKey,
            menuIdx: menuIdx,
            isPlaying: isPlayingMenu,
            callback: leftToolbarCallback),
      );
    }

    if (!isPlayingMenu) {
      bottomRightMenuWidgets = [];
      bottomRightMenuWidgets.add(Positioned(
          bottom: 15,
          right: 220,
          child: ElevatedButton(
            onPressed: () {
              isShowingInfo = !isShowingInfo;
              setState(() {});
            },
            style: ElevatedButton.styleFrom(
              shape: const CircleBorder(),
              padding: const EdgeInsets.all(10),
              elevation: 5,
              shadowColor: Colors.grey.withOpacity(0.5),
            ),
            child: SvgPicture.asset(
              isShowingInfo
                  ? "assets/icons/InfoDisabled.svg"
                  : "assets/icons/Info.svg",
              width: 53,
              height: 53,
            ),
          )));
      bottomRightMenuWidgets.add(Positioned(
          bottom: 15,
          right: 150,
          child: ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              shape: const CircleBorder(),
              padding: const EdgeInsets.all(10),
              elevation: 5,
              shadowColor: Colors.grey.withOpacity(0.5),
            ),
            child: SvgPicture.asset(
              "assets/icons/WifiFull.svg",
              width: 53,
              height: 53,
            ),
          )));
      bottomRightMenuWidgets.add(Positioned(
          bottom: 15,
          right: 80,
          child: ElevatedButton(
            onPressed: () async {
              if (pMapStatus["currentFilename"] == "-") {
                isSavingBrain = 1;
                pMapStatus["isSavingBrain"] = isSavingBrain;
                pMapStatus["currentFileName"] = "-";
              } else {
                if (pMapStatus["currentFileName"] != "-") {}
                // isSavingBrain == 10 - Saved
                // isSavingBrain == 1 - Default
                // isSavingBrain == 2 - There is a change in the design
              }
              await showLoadBrainDialog(context, "Load Brain", selectSavedBrain,
                  saveCurrentBrain, pMapStatus);
              Future.delayed(const Duration(milliseconds: 1200), () {
                // menuIdx = 0;
                rightToolbarKey = UniqueKey();
                rightToolbarCallback({"menuIdx": 0});
                setState(() {});
              });
            },
            style: ElevatedButton.styleFrom(
              shape: const CircleBorder(),
              padding: const EdgeInsets.all(10),
              elevation: 5,
              shadowColor: Colors.grey.withOpacity(0.5),
            ),
            child: SvgPicture.asset(
              "assets/icons/Save.svg",
              width: 53,
              height: 53,
            ),
          )));

      bottomRightMenuWidgets.add(Positioned(
          bottom: 85,
          left: 0,
          child: ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              shape: const CircleBorder(),
              padding: const EdgeInsets.all(10),
              elevation: 5,
              shadowColor: Colors.grey.withOpacity(0.5),
            ),
            child: SvgPicture.asset(
              "assets/icons/Undo.svg",
              width: 53,
              height: 53,
            ),
          )));
      bottomRightMenuWidgets.add(Positioned(
          bottom: 15,
          left: 0,
          child: ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              shape: const CircleBorder(),
              padding: const EdgeInsets.all(10),
              elevation: 5,
              shadowColor: Colors.grey.withOpacity(0.5),
            ),
            child: SvgPicture.asset(
              "assets/icons/Redo.svg",
              width: 53,
              height: 53,
            ),
          )));
    }

    return Scaffold(
      floatingActionButton: FloatingActionButton(
          shape: const CircleBorder(),
          hoverElevation: 1,
          elevation: 0,
          onPressed: () {
            if (isPreventPlayClick) return;
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
              ? SvgPicture.asset(
                  // Icons.play_arrow,
                  "assets/icons/Play.svg",
                  colorFilter: ColorFilter.mode(
                      isPreventPlayClick ? Colors.grey : Colors.black,
                      BlendMode.srcIn),
                  // color: isPreventPlayClick ? Colors.grey : Colors.black,
                )
              :
              // Icon(
              // Icons.pause,
              // color: isPreventPlayClick ? Colors.grey : Colors.black,
              SvgPicture.asset(
                  "assets/icons/Pause.svg",
                  colorFilter: ColorFilter.mode(
                      isPreventPlayClick ? Colors.grey : Colors.black,
                      BlendMode.srcIn),
                )),
      body: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            child: Container(
                color: const Color(0xFF5DA6EE),
                width: screenWidth,
                height: screenHeight,
                child: mainBody),
          ),
          if (!isPlayingMenu) ...[toolbarMenu],
          if (isPlayingMenu) ...[
            Positioned(
              left: 50,
              top: 0,
              child: ClipRect(
                clipper: EyeClipper(
                    isLeft: true, width: screenWidth, height: screenHeight),
                child: mjpegComponent,
              ),
            ),
            Positioned(
              right: 50,
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
                        // width: 320 / 2,
                        height: 240 / 2,
                        fit: BoxFit.fitHeight,
                      ),
                    );
                  }),
            ),
          ],
          if (isPlayingMenu && isChartSelected) ...[
            Positioned(
              bottom: 0,
              left: 0,
              child: Container(
                margin: const EdgeInsets.all(10.0),
                decoration:
                    BoxDecoration(border: Border.all(color: Colors.black)),

                // color:Colors.red,
                height: (Platform.isIOS || Platform.isAndroid)
                    ? screenHeight / 2 - 90
                    : screenHeight / 2 - 150,
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
          if (aiStats != null) ...{
            Positioned(
              left: 0,
              bottom: 0,
              child: SafeArea(
                child: SizedBox(
                  width: screenWidth - 200,
                  height: 200,
                  child: Column(
                    children: aiStats!.entries.map((e) {
                      return StatsWidget(e.key, e.value);
                    }).toList(),
                  ),
                ),
              ),
            )
          },
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
          Positioned(
            right: 5,
            top: 5,
            child: Text(
              style: const TextStyle(fontSize: 7),
              "${packageInfo?.version ?? ""} : ${packageInfo?.buildNumber ?? ""}",
            ),
          ),
        ]
          ..addAll(widgets)
          ..addAll(inlineWidgets)
          ..addAll(bottomRightMenuWidgets),
        // @New Design
        // ..addAll(dragTargetWidgets),
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
    print("connectionKeys");
    print(controller.nodes.map((e) => e.id).toList());

    for (int i = 0; i < neuronSize; i++) {
      // LocalKey neuronFromKey = findNeuronByValue(i).key;
      // InfiniteCanvasNode neuronFrom = findNeuronByValue(i);
      bool isRhytmicNeuron = false;
      InfiniteCanvasNode neuronFrom = controller.nodes[i + 2];

      int sign = 1;
      int inhibitor = 0;
      if (neuronStyles.containsKey(neuronFrom.id)) {
        if (neuronStyles[neuronFrom.id] == "Inhibitory") {
          sign = -1;
          inhibitor = 1000;
        }
      }

      if (neuronSize >= 2) {
        String? neuronType = neuronTypes[neuronFrom.id];
        if (neuronType != null) {
          int neuronTypeIdx = neuronTypesLabel.indexOf(neuronType);

          mapNeuronTypeBufView[i] = neuronTypeIdx + inhibitor;
          if (neuronTypeIdx == 8) {
            mapDelayNeuronBufView[i] = mapDelayNeuronList[i];
            // mapDelayNeuronBufView[i] = 3000;
          } else if (neuronTypeIdx == 9) {
            mapRhytmicNeuronBufView[i] = mapRhytmicNeuronList[i];
            // }
          } else if (neuronTypeIdx == 9) {
            mapCountingNeuronBufView[i] = mapCountingNeuronList[i];
          }
        }

        if (sign == 1) {
        } else {}
      }
      // print("neuronFrom.value");
      // print(neuronFrom.value);
      for (int j = 0; j < neuronSize; j++) {
        // LocalKey neuronToKey = findNeuronByValue(j).key;
        // InfiniteCanvasNode neuronTo = findNeuronByValue(j);
        InfiniteCanvasNode neuronTo = controller.nodes[j + 2];
        // String connectionKey = "${neuronFrom.value}_${neuronTo.value}";
        String connectionKey = "${neuronFrom.id}_${neuronTo.id}";

        // sensory neuron
        if (mapSensoryNeuron.containsKey(connectionKey)) {
          visPrefsBufView[ctr] = (mapSensoryNeuron[connectionKey]).floor();
        } else {
          visPrefsBufView[ctr] = -1;
        }

        // motor neuron
        if (mapContactsNeuron.containsKey(connectionKey)) {
          neuronContactsBufView[ctr] =
              (sign * mapContactsNeuron[connectionKey]).floorToDouble();
        } else {
          neuronContactsBufView[ctr] = 0;
        }

        if (mapDistanceNeuron.containsKey(connectionKey)) {
          neuronDistanceBufView[ctr] =
              (mapDistanceNeuron[connectionKey]).floor();
        } else {
          neuronDistanceBufView[ctr] = -1;
        }

        if (neuronFrom.id == nodeDistanceSensor.id) {
          try {
            int idx = neuronTypes.keys.toList().indexOf(neuronTo.id);
            if (mapDistanceLimitNeuron.containsKey(connectionKey)) {
              if (mapDistanceLimitNeuron.containsKey(connectionKey)) {
                String temp = mapDistanceLimitNeuron[connectionKey];
                List<String> arr = temp.split("_@_");
                distanceMinLimitBufView[idx] = int.parse(arr[0]);
                distanceMaxLimitBufView[idx] = int.parse(arr[1]);
                txtDistanceMinController.text = arr[0];
                txtDistanceMaxController.text = arr[1];
              }
            } else {
              distanceMinLimitBufView[idx] = 1;
              distanceMaxLimitBufView[idx] = 8;
              txtDistanceMinController.text = "1";
              txtDistanceMaxController.text = "8";
            }
          } catch (err) {
            print("errorrr getting limit");
            print(err);
          }
        }

        if (mapSpeakerNeuron.containsKey(connectionKey)) {
          neuronSpeakerBufView[ctr] = (mapSpeakerNeuron[connectionKey]).round();
        } else {
          neuronSpeakerBufView[ctr] = -1;
        }

        if (mapLedNeuron.containsKey(connectionKey)) {
          neuronLedBufView[ctr] = (mapLedNeuron[connectionKey]).round();
        } else {
          neuronLedBufView[ctr] = -1;
        }
        if (mapLedNeuronPosition.containsKey(connectionKey)) {
          neuronLedPositionBufView[ctr] =
              mapLedNeuronPosition[connectionKey] == null
                  ? 0
                  : int.parse((mapLedNeuronPosition[connectionKey]), radix: 2)
                      .round();
        } else {
          neuronLedPositionBufView[ctr] = -1;
        }

        if (mapMicrophoneNeuron.containsKey(connectionKey)) {
          neuronMicrophoneBufView[ctr] =
              (mapMicrophoneNeuron[connectionKey]).round();
        } else {
          neuronMicrophoneBufView[ctr] = -1;
        }

        // connectome
        if (mapConnectome.containsKey(connectionKey)) {
          connectomeBufView[ctr] =
              (sign * mapConnectome[connectionKey]).floorToDouble();
        } else {
          connectomeBufView[ctr] = 0;
        }

        ctr++;
      }
    }
    print("neuronContactsBufView");
    // print(mapNeuronTypeBufView);
    // print(mapConnectome);
    // print(neuronContactsBufView);
    // print(connectomeBufView);
    print(mapDistanceNeuron);
    print(mapDistanceLimitNeuron);
    print(distanceMinLimitBufView);
    print(distanceMaxLimitBufView);
    // print(neuronSpeakerBufView);
    // print(neuronLedBufView);
    // print(neuronMicrophoneBufView);
    // print(visPrefsBufView);
    print("mapDelayNeuronBufView");
    print(mapDelayNeuronBufView);
  }

  void runSimulation() {
    print("RUN SIMuLATION");
    // neuronSize = controller.nodes.length;
    initNativeC(false);
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
    for (InfiniteCanvasEdge edge in controller.edges) {
      // print("edge.from");
      // print(edge.from);
      // print(edge.to);
      int fromIdx = nodeKey[edge.from.toString()]!; // - allNeuronStartIdx;
      int toIdx = nodeKey[edge.to.toString()]!; // - allNeuronStartIdx;
      connectomeMatrix[fromIdx][toIdx] = Random().nextDouble() * 3;
    }
    // final vals = neuronTypes.values;
    int index = 0;
    neuronTypes.forEach((key, item) {
      if (item == "Custom") {
        aBufView[index] = aDesignArray[key];
        bBufView[index] = bDesignArray[key];
        cBufView[index] = cDesignArray[key].round();
        dBufView[index] = dDesignArray[key].round();
      }
      index++;
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
    protoNeuron.generateCircle(
        neuronSize, pos, neuronTypes.values.toList(growable: false));
    // protoNeuron.setConnectome(neuronSize, connectomeMatrix);
    // print("controller.nodes.map(((e) => e.id)).toList()");
    // print(controller.nodes.map(((e) => e.id)).toList());
    populateMatrix();
    // print("===> controller.nodes.map(((e) => e.id)).toList()");
    // print(controller.nodes.map(((e) => e.id)).toList());
    // print(mapContactsNeuron.keys);

    // Future.delayed(const Duration(seconds:1), (){
    print("BUFZ");
    // print(mapConnectome);
    // print(aBufView);
    // print(bBufView);
    // print(cBufView);
    // print(dBufView);
    // print(visPrefsBufView);
    // print(motorCommandBufView);
    // print(neuronContactsBufView);
    print(mapSpeakerNeuron);
    print(neuronSpeakerBufView);
    print(neuronLedBufView);
    print(neuronLedPositionBufView);
    // print(mapMicrophoneNeuron);
    // print(neuronMicrophoneBufView);
    runNativeC();

    // Future.delayed(const Duration(milliseconds: 1000), () {
    //   // String str = 'd:131;d:231;d:331;d:431;d:531;d:631;'; // blue
    //   try {
    //     _DesignBrainPageState.isolateWritePort.send(stopMotorCmd + offLEDCmd);
    //     // _DesignBrainPageState.isolateWritePort.send(offLEDCmd);
    //   } catch (err) {
    //     print("err sending command motor");
    //     print(err);
    //   }
    // });
    // });
  }

  neuronTypeChangeCallback(neuronType) {
    if (controller.hasSelection) {
      InfiniteCanvasNode selected = controller.selection[0];
      print("neuronType");
      print(neuronType);
      // int idx = selected.value;
      // neuronTypes[idx] = neuronType;
      neuronTypes[selected.id] = neuronType;
      int idx = neuronTypes.keys.toList().indexOf(selected.id);

      // aBufView = aBuf.asTypedList(neuronSize);
      // bBufView = bBuf.asTypedList(neuronSize);
      // cBufView = cBuf.asTypedList(neuronSize);
      // dBufView = dBuf.asTypedList(neuronSize);

      // switch (neuronType) {
      //   case "Quiet":
      //     aBufView[idx] = 0.02;
      //     bBufView[idx] = 0.1;
      //     cBufView[idx] = -65;
      //     dBufView[idx] = 2;
      //     break;
      //   case "Occassionally active":
      //     aBufView[idx] = 0.02;
      //     bBufView[idx] = 0.16;
      //     cBufView[idx] = -65;
      //     dBufView[idx] = 2;
      //     break;
      //   case "Highly active":
      //     aBufView[idx] = 0.02;
      //     bBufView[idx] = 0.2;
      //     cBufView[idx] = -65;
      //     dBufView[idx] = 2;
      //     break;
      //   case "Generates bursts":
      //     aBufView[idx] = 0.02;
      //     bBufView[idx] = 0.16;
      //     cBufView[idx] = -8;
      //     dBufView[idx] = 2;
      //     break;
      //   case "Bursts when activated":
      //     aBufView[idx] = 0.02;
      //     bBufView[idx] = 0.1;
      //     cBufView[idx] = -37;
      //     dBufView[idx] = 2;
      //     break;
      //   case "Dopaminergic":
      //     aBufView[idx] = 0.02;
      //     bBufView[idx] = 0.1;
      //     cBufView[idx] = -65;
      //     dBufView[idx] = 2;
      //     break;
      //   case "Striatal":
      //     aBufView[idx] = 0.02;
      //     bBufView[idx] = 0.1;
      //     cBufView[idx] = -65;
      //     dBufView[idx] = 2;
      //     break;
      // }
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
        if (mapSensoryNeuron.containsKey(
            "${inwardEdge.from.toString()}_${inwardEdge.to.toString()}")) {
          mapSensoryNeuron.remove(
              "${inwardEdge.from.toString()}_${inwardEdge.to.toString()}");
        }
        if (mapContactsNeuron.containsKey(
            "${inwardEdge.from.toString()}_${inwardEdge.to.toString()}")) {
          mapContactsNeuron.remove(
              "${inwardEdge.from.toString()}_${inwardEdge.to.toString()}");
        }
        if (mapConnectome.containsKey(
            "${inwardEdge.from.toString()}_${inwardEdge.to.toString()}")) {
          mapConnectome.remove(
              "${inwardEdge.from.toString()}_${inwardEdge.to.toString()}");
        }

        if (mapDistanceNeuron.containsKey(
            "${inwardEdge.from.toString()}_${inwardEdge.to.toString()}")) {
          mapDistanceNeuron.remove(
              "${inwardEdge.from.toString()}_${inwardEdge.to.toString()}");
        }
        if (mapDistanceLimitNeuron.containsKey(
            "${inwardEdge.from.toString()}_${inwardEdge.to.toString()}")) {
          mapDistanceLimitNeuron.remove(
              "${inwardEdge.from.toString()}_${inwardEdge.to.toString()}");
        }

        if (mapSpeakerNeuron.containsKey(
            "${inwardEdge.from.toString()}_${inwardEdge.to.toString()}")) {
          mapSpeakerNeuron.remove(
              "${inwardEdge.from.toString()}_${inwardEdge.to.toString()}");
        }
        if (mapMicrophoneNeuron.containsKey(
            "${inwardEdge.from.toString()}_${inwardEdge.to.toString()}")) {
          mapMicrophoneNeuron.remove(
              "${inwardEdge.from.toString()}_${inwardEdge.to.toString()}");
        }
        if (mapLedNeuron.containsKey(
            "${inwardEdge.from.toString()}_${inwardEdge.to.toString()}")) {
          mapLedNeuron.remove(
              "${inwardEdge.from.toString()}_${inwardEdge.to.toString()}");
        }
        if (mapLedNeuronPosition.containsKey(
            "${inwardEdge.from.toString()}_${inwardEdge.to.toString()}")) {
          mapLedNeuronPosition.remove(
              "${inwardEdge.from.toString()}_${inwardEdge.to.toString()}");
        }
      }

      // outward connection
      List<InfiniteCanvasEdge> outwardEdges =
          controller.edges.where((e) => e.from == selected.key).toList();
      for (int i = 0; i < outwardEdges.length; i++) {
        InfiniteCanvasEdge outwardEdge = outwardEdges[i];
        if (mapSensoryNeuron.containsKey(
            "${outwardEdge.from.toString()}_${outwardEdge.to.toString()}")) {
          mapSensoryNeuron.remove(
              "${outwardEdge.from.toString()}_${outwardEdge.to.toString()}");
        }
        if (mapContactsNeuron.containsKey(
            "${outwardEdge.from.toString()}_${outwardEdge.to.toString()}")) {
          mapContactsNeuron.remove(
              "${outwardEdge.from.toString()}_${outwardEdge.to.toString()}");
        }
        if (mapConnectome.containsKey(
            "${outwardEdge.from.toString()}_${outwardEdge.to.toString()}")) {
          mapConnectome.remove(
              "${outwardEdge.from.toString()}_${outwardEdge.to.toString()}");
        }

        if (mapDistanceNeuron.containsKey(
            "${outwardEdge.from.toString()}_${outwardEdge.to.toString()}")) {
          mapDistanceNeuron.remove(
              "${outwardEdge.from.toString()}_${outwardEdge.to.toString()}");
        }
        if (mapDistanceLimitNeuron.containsKey(
            "${outwardEdge.from.toString()}_${outwardEdge.to.toString()}")) {
          mapDistanceLimitNeuron.remove(
              "${outwardEdge.from.toString()}_${outwardEdge.to.toString()}");
        }

        if (mapSpeakerNeuron.containsKey(
            "${outwardEdge.from.toString()}_${outwardEdge.to.toString()}")) {
          mapSpeakerNeuron.remove(
              "${outwardEdge.from.toString()}_${outwardEdge.to.toString()}");
        }
        if (mapMicrophoneNeuron.containsKey(
            "${outwardEdge.from.toString()}_${outwardEdge.to.toString()}")) {
          mapMicrophoneNeuron.remove(
              "${outwardEdge.from.toString()}_${outwardEdge.to.toString()}");
        }
        if (mapLedNeuron.containsKey(
            "${outwardEdge.from.toString()}_${outwardEdge.to.toString()}")) {
          mapLedNeuron.remove(
              "${outwardEdge.from.toString()}_${outwardEdge.to.toString()}");
        }
        if (mapLedNeuronPosition.containsKey(
            "${outwardEdge.from.toString()}_${outwardEdge.to.toString()}")) {
          mapLedNeuronPosition.remove(
              "${outwardEdge.from.toString()}_${outwardEdge.to.toString()}");
        }
      }

      for (int i = 0; i < inwardEdges.length; i++) {
        InfiniteCanvasEdge inwardEdge = inwardEdges[i];
        controller.edges.remove(inwardEdge);
      }
      for (int i = 0; i < outwardEdges.length; i++) {
        InfiniteCanvasEdge outwardEdge = outwardEdges[i];
        controller.edges.remove(outwardEdge);
      }

      int deleteIdx = neuronTypes.keys.toList().indexOf(selected.id);
      mapDelayNeuronList.removeAt(deleteIdx);
      syntheticNeuronList.removeAt(deleteIdx);
      rawSyntheticNeuronList.removeAt(deleteIdx);

      neuronTypes.remove(selected.id);
      neuronStyles.remove(selected.id);
      aDesignArray.remove(selected.id);
      bDesignArray.remove(selected.id);
      cDesignArray.remove(selected.id);
      dDesignArray.remove(selected.id);

      // remove, still preserve order of the hashmap data.
      // print("neuronTypes");
      // print(neuronTypes);
      // print(neuronTypes.keys);
      // print(neuronTypes.values);

      controller.deleteSelection();
      neuronSize--;
      isDrawTail = false;
      isDeleteMenu = false;

      controller.deselectAll();
      // controller.select(prevSelectedNeuron.key);
      controller.controlPressed = false;
      clearUIMenu();
      setState(() => {});
      prevEdgesLength = controller.edges.length;
    }
  }

  deleteEdgeCallback() {
    if (controller.isSelectingEdge) {
      // var selectedEdge = controller.edges.where((element) => element.from == controller.edgeSelected.from && element.to == controller.edgeSelected.to).toList();
      int idx = controller.edges.indexOf(controller.edgeSelected);
      InfiniteCanvasEdge lastCreatedEdge = controller.edges[idx];
      if (mapSensoryNeuron.containsKey(
          "${lastCreatedEdge.from.toString()}_${lastCreatedEdge.to.toString()}")) {
        mapSensoryNeuron.remove(
            "${lastCreatedEdge.from.toString()}_${lastCreatedEdge.to.toString()}");
      }
      if (mapContactsNeuron.containsKey(
          "${lastCreatedEdge.from.toString()}_${lastCreatedEdge.to.toString()}")) {
        mapContactsNeuron.remove(
            "${lastCreatedEdge.from.toString()}_${lastCreatedEdge.to.toString()}");
      }
      if (mapConnectome.containsKey(
          "${lastCreatedEdge.from.toString()}_${lastCreatedEdge.to.toString()}")) {
        mapConnectome.remove(
            "${lastCreatedEdge.from.toString()}_${lastCreatedEdge.to.toString()}");
      }

      if (mapDistanceNeuron.containsKey(
          "${lastCreatedEdge.from.toString()}_${lastCreatedEdge.to.toString()}")) {
        mapDistanceNeuron.remove(
            "${lastCreatedEdge.from.toString()}_${lastCreatedEdge.to.toString()}");
      }
      if (mapDistanceLimitNeuron.containsKey(
          "${lastCreatedEdge.from.toString()}_${lastCreatedEdge.to.toString()}")) {
        mapDistanceLimitNeuron.remove(
            "${lastCreatedEdge.from.toString()}_${lastCreatedEdge.to.toString()}");
      }
      if (mapSpeakerNeuron.containsKey(
          "${lastCreatedEdge.from.toString()}_${lastCreatedEdge.to.toString()}")) {
        mapSpeakerNeuron.remove(
            "${lastCreatedEdge.from.toString()}_${lastCreatedEdge.to.toString()}");
      }
      if (mapMicrophoneNeuron.containsKey(
          "${lastCreatedEdge.from.toString()}_${lastCreatedEdge.to.toString()}")) {
        mapMicrophoneNeuron.remove(
            "${lastCreatedEdge.from.toString()}_${lastCreatedEdge.to.toString()}");
      }
      if (mapLedNeuron.containsKey(
          "${lastCreatedEdge.from.toString()}_${lastCreatedEdge.to.toString()}")) {
        mapLedNeuron.remove(
            "${lastCreatedEdge.from.toString()}_${lastCreatedEdge.to.toString()}");
      }
      if (mapLedNeuronPosition.containsKey(
          "${lastCreatedEdge.from.toString()}_${lastCreatedEdge.to.toString()}")) {
        mapLedNeuronPosition.remove(
            "${lastCreatedEdge.from.toString()}_${lastCreatedEdge.to.toString()}");
      }

      controller.edges.removeAt(idx);

      controller.isFoundEdge = false;
      controller.isSelectingEdge = false;
      // controller.edgeFound = null;
      // controller.edgeSelected = null;

      controller.deselectAll();
      controller.controlPressed = false;
      clearUIMenu();

      setState(() => {});

      prevEdgesLength = controller.edges.length;
    }
  }

  prepareWidget(InfiniteCanvas canvas) {
    if (Platform.isFuchsia) {
      return canvas;
    } else {
      return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapUp: (details) {
            // print("controller.isFoundEdge");
            // print(controller.isFoundEdge);
            if (controller.isFoundEdge) {
              controller.isSelectingEdge = true;
              controller.edgeSelected = controller.edgeFound;
            } else {
              controller.isSelectingEdge = false;
              // controller.edgeSelected = controller.edgeFound;
            }
            if (!isDrawTail && !controller.hasSelection) {
              isDeleteMenu = controller.isSelectingEdge;
              if (controller.isSelectingEdge) {
                try {
                  selectEdgeMenuType();
                } catch (err) {
                  print("err");
                  print(err);
                }
                setState(() {});
              }
            }
            // controller.notifyMousePosition();
          },
          onScaleEnd: (ScaleEndDetails details) {
            // print( details.scaleVelocity );
          },
          onScaleUpdate: (details) {
            print("details on scale update");
            print(details);
            // details.scale
          },
          // onLongPress: () {
          //   return;
          //   print("controller.mousePosition");
          //   // print(controller.mousePosition);
          //   if (controller.hasSelection) {
          //     var selected = controller.selection[0];
          //     // int neuronIdx = selected.value - normalNeuronStartIdx - 1;
          //     int neuronIdx = controller.nodes
          //             .map((e) => e.id)
          //             .toList()
          //             .indexOf(selected.id) -
          //         2;
          //     print("neuronIdx");
          //     print(neuronIdx);
          //     // print(neuronTypes);
          //     isChartSelected = true;
          //     try {
          //       nativec.changeIdxSelected(neuronIdx);
          //     } catch (err) {
          //       print("err");
          //       print(err);
          //     }
          //     if (neuronIdx < normalNeuronStartIdx) {
          //       return;
          //     }

          //     // String neuronType = protoNeuron.circles[neuronIdx].neuronType;
          //     String neuronType = neuronTypes[selected.id]!;
          //     // print(neuronIdx);

          //     //show dialog box to change neuron
          //     // neuronDialogBuilder(context, selected.value.toString(), "Neuron ",
          //     // /* CHANGE ME
          //     neuronDialogBuilder(context, "Neuron ", selected.id.toString(),
          //         neuronType, neuronTypeChangeCallback, deleteNeuronCallback);
          //     // */
          //   } else if (controller.isSelectingEdge) {
          //     // IMPORTANT - Check duplication when adding edge into the same neuron
          //     // 2-way axons
          //     // /* CHANGE ME
          //     // at this point - there is a minimum of 1 edge
          //     int isSensoryType = 0;

          //     final lastCreatedEdge = controller.edgeSelected;
          //     InfiniteCanvasNode neuronFrom =
          //         findNeuronByKey(lastCreatedEdge.from);
          //     InfiniteCanvasNode neuronTo = findNeuronByKey(lastCreatedEdge.to);
          //     // InfiniteCanvasNode neuronTo = findNeuronByKey(lastCreatedEdge.to);
          //     if (neuronFrom == nodeLeftEyeSensor ||
          //         neuronFrom == nodeRightEyeSensor) {
          //       isSensoryType = 1;
          //     } else if (neuronTo == nodeLeftMotorBackwardSensor ||
          //         neuronTo == nodeRightMotorBackwardSensor ||
          //         neuronTo == nodeLeftMotorForwardSensor ||
          //         neuronTo == nodeRightMotorForwardSensor)
          //       isSensoryType = 2;
          //     else if (neuronFrom == nodeDistanceSensor) isSensoryType = 3;

          //     print("isVisualSensory");
          //     print(isSensoryType);

          //     Map<String, double> map = {
          //       // "connectomeContact": connectomeBufView[ neuronFrom.value * neuronSize + neuronTo.value],
          //       // "neuronContact": neuronContactsBufView[ neuronFrom.value * neuronSize + neuronTo.value],
          //       // "visualPref": visPrefsBufView[ neuronFrom.value * neuronSize + neuronTo.value].toDouble(),
          //       "connectomeContact":
          //           mapConnectome.containsKey("${neuronFrom.id}_${neuronTo.id}")
          //               ? mapConnectome["${neuronFrom.id}_${neuronTo.id}"]
          //                   .toDouble()
          //               : 0,
          //       "neuronContact": mapContactsNeuron
          //               .containsKey("${neuronFrom.id}_${neuronTo.id}")
          //           ? mapContactsNeuron["${neuronFrom.id}_${neuronTo.id}"]
          //               .toDouble()
          //           : 0,
          //       "visualPref": mapSensoryNeuron
          //               .containsKey("${neuronFrom.id}_${neuronTo.id}")
          //           ? mapSensoryNeuron["${neuronFrom.id}_${neuronTo.id}"]
          //               .toDouble()
          //           : -1.0,
          //       "distanceContact": mapDistanceNeuron
          //               .containsKey("${neuronFrom.id}_${neuronTo.id}")
          //           ? mapDistanceNeuron["${neuronFrom.id}_${neuronTo.id}"]
          //               .toDouble()
          //           : -1,
          //     };
          //     // print("map sensory");
          //     // print(mapConnectome);
          //     // print(mapContactsNeuron);
          //     axonDialogBuilder(
          //         context,
          //         isSensoryType,
          //         "Edge",
          //         " ",
          //         map,
          //         neuronTypeChangeCallback,
          //         deleteEdgeCallback,
          //         linkSensoryConnection,
          //         linkMotorConnection,
          //         linkNeuronConnection,
          //         linkDistanceConnection);
          //     // */
          //   }
          //   // else
          //   // if (controller.hasEdgeSelection{
          //   //show dialog box to change edge

          //   // }
          // },
          onDoubleTap: () {
            // print("doubletap");
            // print(controller.scale);

            if (controller.scale >= 1.5) {
              controller.zoomReset();
              // controller.pan(const Offset(-60, 0));
              controller.scale = 1;

              if (isPlayingMenu) {
                transformNeuronPosition(1.0);
                // protoNeuron.generateCircle(neuronSize, pos, neuronTypes);
              }
            } else {
              controller.zoomReset();
              controller.zoom(1.5);
              controller.scale = 1.5;
              if (isPlayingMenu) {
                transformNeuronPosition(1.5);
              }
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

  leftToolbarCallback(map) async {
    modeIdx = map["modeIdx"];
    controller.modeIdx = modeIdx;
    isBrainTargetOverlayTop = -1;
    containedIdx = -1;
    if (modeIdx != -1) {
      mapBg["activeBg"] = "assets/bg/BrainDrawings/BrainFullGrey.svg";
    } else {
      mapBg["activeBg"] = defaultBg;
    }
    print("modeIdx");
    print(modeIdx);
    // if (modeIdx == -1) {
    //   menuIdx = 0;
    // }
    setState(() {});
  }

  rightToolbarCallback(map) async {
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
        if (scales == 1) {
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
      resetMouse();
      controller.deselectAll();
      clearUIMenu();
      // controller.setCanvasMove(false);
    } else if (menuIdx == 5) {
      // home
      // Navigator.pop(context);
      // Navigator.pop(context);

      // await loadBrainDialog(context, "Load Brain", selectSavedBrain);
      // await showLoadBrainDialog(context, "Load Brain", selectSavedBrain);

      if (pMapStatus["currentFilename"] == "-") {
        isSavingBrain = 1;
        pMapStatus["isSavingBrain"] = isSavingBrain;
        pMapStatus["currentFileName"] = "-";
      } else {
        if (pMapStatus["currentFileName"] != "-") {}
        // isSavingBrain == 10 - Saved
        // isSavingBrain == 1 - Default
        // isSavingBrain == 2 - There is a change in the design
      }

      await showLoadBrainDialog(context, "Load Brain", selectSavedBrain,
          saveCurrentBrain, pMapStatus);

      Future.delayed(const Duration(milliseconds: 1200), () {
        // menuIdx = 0;
        rightToolbarKey = UniqueKey();
        rightToolbarCallback({"menuIdx": 0});
        setState(() {});
      });
      // String filename = "1706316809745231";
      // selectSavedBrain(filename);
      // controller.nodes.clear();
    } else if (menuIdx == 6) {
      controller.spacePressed = false;
      controller.mouseDown = false;
      controller.setCanvasMove(false);
      // controller.zoomReset();
      // controller.pan(const Offset(-60, 0));

      // save
      // save neurons : position, index, color, shape, size
      // save edges : from node Id, to node Id
      // save as json.
      await saveBrainInfoDialog(context, saveCurrentBrain);

      // print( json.encode(controller.nodes) );
      // print( json.encode(controller.edges) );
    } else if (menuIdx == 7) {
      controller.spacePressed = false;

      isPlayingMenu = !isPlayingMenu;
      countEyeSensorConnection();
      // isSelected = false;
      print("MENU IDX 8");
      print("BUF IDX 7");
      print(mapConnectome);
      // print(aBufView);
      // print(bBufView);
      // print(cBufView);
      // print(dBufView);

      controller.mouseDown = false;
      controller.setCanvasMove(false);

      // controller.zoomReset();
      // controller.zoomReset();
      // controller.pan(const Offset(-60, 0));

      rawPos = [];
      for (InfiniteCanvasNode node in controller.nodes) {
        Offset position = controller.toLocal(node.offset);
        rawPos.add(position);
      }

      if (isPlayingMenu) {
        isCheckingColor = false;
        try {
          // for (int i = 0; i < 10; i++) {}
          isPreventPlayClick = true;

          startWebSocket();
          Future.delayed(const Duration(milliseconds: 2770), () {
            isSimulatingBrain = true;
            isPreventPlayClick = false;
            setState(() => {});
          });
        } catch (ex) {}
      } else {
        try {
          _DesignBrainPageState.isolateWritePort
              .send(stopMotorCmd + greenLEDCmd);
          // _DesignBrainPageState.isolateWritePort.send(greenLEDCmd);
        } catch (err) {}
        isSimulatingBrain = false;

        initializeOpenCV();
        isIsolateWritePortInitialized = false;
        processor.clearMemory();
        try {
          processor = ImagePreprocessor();
          mjpegComponent = Mjpeg(
            stream: httpdStream,
            // stream: "http://192.168.1.4:8081/",
            preprocessor: processor,
            width: 320 / 2,
            height: 240 / 2,

            isLive: true,
            fit: BoxFit.fitHeight,
            timeout: const Duration(seconds: 60),
          );

          // writePort.close();
        } catch (exc) {
          print("exception : ");
          print(exc);
        }
        isPreventPlayClick = true;
        try {
          isolateWritePort.send("DISCONNECT");
        } catch (err) {}

        Future.delayed(const Duration(milliseconds: 300), () {
          // rightToolbarGlobalKey = GlobalKey();
          rightToolbarKey = UniqueKey();
          setState(() {});
        });
        Future.delayed(const Duration(milliseconds: 4000), () {
          isPreventPlayClick = false;
          setState(() => {});
        });
      }

      // print("visPrefsBufView");
      // print(visPrefsBufView);

      if (isPlayingMenu) {
        controller.deselectAll();
        isPlayingMenu = false;
        Future.delayed(const Duration(milliseconds: 1650), () {
          isPlayingMenu = true;
          runSimulation();
          controller.isPlaying = true;
        });
      } else {
        if (kIsWeb) {
          // js.context.callMethod("stopThreadProcess", [0]);
        } else {
          nativec.stopThreadProcess(0);
        }
        controller.deselectAll();
        controller.setCanvasMove(true);
        controller.isPlaying = false;
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
      } else {}
    }
    int platformAdjuster = 0;
    if (Platform.isIOS || Platform.isAndroid) {
      platformAdjuster = 7;
    }

    Offset middleScreenOffset = Offset(screenWidth / 2 - platformAdjuster, 150);

    // Offset offset = middleScreenOffset.scale(0.5, 0.5);
    // Offset offset = middleScreenOffset.scale(ratio, ratio);
    nodeDistanceSensor.offset = middleScreenOffset;
    // print("nodeDistanceSensor.offset");
    // print(nodeDistanceSensor.offset);

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
        screenWidth / 2 - 12 + platformAdjuster + 1.725 * screenHeight / 8,
        nodeSpeakerSensor.offset.dy);
    nodeSpeakerSensor.offset = offsetSpeaker;

    Offset offsetRMF = Offset(
        screenWidth / 2 - 12 + platformAdjuster + 2 * screenHeight / 8,
        nodeRightMotorForwardSensor.offset.dy);
    nodeRightMotorForwardSensor.offset = offsetRMF;

    Offset offsetRMB = Offset(
        screenWidth / 2 - 12 + platformAdjuster + 2 * screenHeight / 8,
        nodeRightMotorBackwardSensor.offset.dy);
    nodeRightMotorBackwardSensor.offset = offsetRMB;

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

    Offset verticalLedSpacer = const Offset(0, 20);
    Offset ledGreenOffset =
        Offset(middleScreenOffset.dx, nodeGreenLed.offset.dy - 10);
    nodeGreenLed.offset = ledGreenOffset;

    Offset offsetRed = ledGreenOffset - diff + verticalLedSpacer;
    nodeRedLed.offset = offsetRed;

    Offset offsetBlue = ledGreenOffset + diff + verticalLedSpacer;
    nodeBlueLed.offset = offsetBlue;

    // Offset diffLMB = Offset(2 * screenHeight/10, 0);
    // Offset offsetLMB = Offset(MediaQuery.of(context).size.width/2-10, nodeLeftMotorBackwardSensor.offset.dy); - (diffLMB);
    // nodeLeftMotorBackwardSensor.offset = offsetLMB;
  }

  void clearBridge() {
    // controller.nodes.clear();
    // controller.edges.clear();
    mapContactsNeuron = {};
    mapMicrophoneNeuron = {};
    mapConnectome = {};
    mapContactsNeuron = {};
    mapDistanceNeuron = {};
    mapDistanceLimitNeuron = {};
    mapLedNeuron = {};
    mapLedNeuronPosition = {};
    mapSensoryNeuron = {};
    mapSpeakerNeuron = {};
    neuronSize = normalNeuronStartIdx;
    syntheticNeuronList.clear();
    rawSyntheticNeuronList.clear();

    for (InfiniteCanvasNode node in sensoryNeurons) {
      SyntheticNeuron synNeuron = SyntheticNeuron(
          isActive: false, isIO: true, circleRadius: neuronDrawSize / 2);
      synNeuron.node = node;
      synNeuron.setupDrawingNeuron();
      syntheticNeuronList.add(synNeuron);

      SyntheticNeuron rawSynNeuron = SyntheticNeuron(
          isActive: false, isIO: true, circleRadius: neuronDrawSize / 2);
      rawSynNeuron.node = node;
      rawSynNeuron.copyDrawingNeuron(synNeuron);
      rawSyntheticNeuronList.add(rawSynNeuron);
      synNeuron.rawSyntheticNeuron = rawSynNeuron;
    }

    initNeuronType();
  }

  void initCanvas() {
    dropdownNeuronItems =
        List<DropdownMenuItem>.generate(neuronMenuTypes.length, (index) {
      return DropdownMenuItem(
        value: neuronMenuTypes[index],
        child: Align(
          alignment: Alignment.centerRight,
          child: Text(
            neuronTypesLabel[index],
            textAlign: TextAlign.end,
          ),
        ),
      );
    });
    dropdownNeuronStyleItems =
        List<DropdownMenuItem>.generate(neuronMenuStyle.length, (index) {
      return DropdownMenuItem(
        value: neuronMenuStyle[index],
        child: Align(
          alignment: Alignment.centerRight,
          child: Text(
            neuronMenuStyle[index],
            textAlign: TextAlign.end,
          ),
        ),
      );
    });

    dropdownCameraItems =
        List<DropdownMenuItem>.generate(cameraMenuTypes.length, (index) {
      return DropdownMenuItem(
        value: cameraMenuTypes[index],
        child: Align(
          alignment: Alignment.centerRight,
          child: Text(
            cameraMenuTypes[index],
            textAlign: TextAlign.end,
          ),
        ),
      );
    });

    dropdownDistanceItems =
        List<DropdownMenuItem>.generate(distanceMenuTypes.length, (index) {
      return DropdownMenuItem(
        value: distanceMenuTypes[index],
        child: Align(
          alignment: Alignment.centerRight,
          child: Text(
            distanceMenuTypes[index],
            textAlign: TextAlign.end,
          ),
        ),
      );
    });
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

    Path pathTail = Path();
    bool isTailCreated = false;
    Paint blackStroke = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    Paint whiteBrush = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill
      ..strokeWidth = 2;

    int tailSize = 5;
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
                  // canvas.drawCircle(rect.center, rect.width / 3, brush);
                  // canvas.drawRect(rect, brush);
                  if (!isTailCreated) {
                    int offset = 0;
                    Offset topTriangle = Offset(offset + rect.center.dx,
                        offset + rect.center.dy - tailSize);
                    Offset rightTriangle = Offset(
                        offset + rect.center.dx + tailSize * 2,
                        offset + rect.center.dy + tailSize * 2);
                    Offset leftTriangle = Offset(
                        offset + rect.center.dx - tailSize * 2,
                        offset + rect.center.dy + tailSize * 2);
                    // print("topTriangle");
                    // print(topTriangle);
                    // print("rightTriangle");
                    // print(rightTriangle);
                    // print("leftTriangle");
                    // print(leftTriangle);

                    pathTail.moveTo(topTriangle.dx, topTriangle.dy);
                    pathTail.lineTo(leftTriangle.dx, leftTriangle.dy);
                    pathTail.lineTo(rightTriangle.dx, rightTriangle.dy);

                    // pathTail.moveTo(rightTriangle.dx, rightTriangle.dy);

                    // pathTail.moveTo(leftTriangle.dx, leftTriangle.dy);
                    // pathTail.lineTo(topTriangle.dx, topTriangle.dy);

                    pathTail.close();
                    isTailCreated = true;
                  }

                  // print("pathTail");
                  // print(pathTail.);
                  // brush.color = Colors.white;
                  brush.color = Colors.black;
                  // canvas.drawLine(topTriangle, rightTriangle, brush);
                  // canvas.drawLine(rightTriangle, leftTriangle, brush);
                  // canvas.drawLine(leftTriangle, topTriangle, brush);
                  canvas.drawLine(rect.center, parentOffset, brush);
                  canvas.drawPath(pathTail, blackStroke);
                  canvas.drawPath(pathTail, whiteBrush);

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

      nodeRedLed,
      nodeGreenLed,
      nodeBlueLed,

      // rectangleNode,
      // triangleNode,
      // circleNode,
    ];
    sensoryNeurons = [
      nodeDistanceSensor,
      nodeLeftEyeSensor,
      nodeRightEyeSensor,
      nodeLeftMotorForwardSensor,
      nodeRightMotorForwardSensor,
      nodeLeftMotorBackwardSensor,
      nodeRightMotorBackwardSensor,
      nodeMicrophoneSensor,
      nodeSpeakerSensor,
      nodeRedLed,
      nodeGreenLed,
      nodeBlueLed,
    ];
    for (InfiniteCanvasNode node in sensoryNeurons) {
      SyntheticNeuron synNeuron = SyntheticNeuron(
          isActive: false, isIO: true, circleRadius: neuronDrawSize / 2);
      synNeuron.node = node;
      synNeuron.setupDrawingNeuron();
      syntheticNeuronList.add(synNeuron);

      SyntheticNeuron rawSynNeuron = SyntheticNeuron(
          isActive: false, isIO: true, circleRadius: neuronDrawSize / 2);
      rawSynNeuron.node = node;
      rawSynNeuron.copyDrawingNeuron(synNeuron);
      rawSyntheticNeuronList.add(rawSynNeuron);
      synNeuron.rawSyntheticNeuron = rawSynNeuron;
    }

    nodeDistanceSensor.syntheticNeuron = syntheticNeuronList[0];
    nodeLeftEyeSensor.syntheticNeuron = syntheticNeuronList[1];
    nodeRightEyeSensor.syntheticNeuron = syntheticNeuronList[2];
    nodeLeftMotorForwardSensor.syntheticNeuron = syntheticNeuronList[3];
    nodeRightMotorForwardSensor.syntheticNeuron = syntheticNeuronList[4];
    nodeLeftMotorBackwardSensor.syntheticNeuron = syntheticNeuronList[5];
    nodeRightMotorBackwardSensor.syntheticNeuron = syntheticNeuronList[6];
    nodeMicrophoneSensor.syntheticNeuron = syntheticNeuronList[7];
    nodeSpeakerSensor.syntheticNeuron = syntheticNeuronList[8];
    nodeRedLed.syntheticNeuron = syntheticNeuronList[9];
    nodeGreenLed.syntheticNeuron = syntheticNeuronList[10];
    nodeBlueLed.syntheticNeuron = syntheticNeuronList[11];

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
      "Red Led",
      "Green Led",
      "Blue Led",
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
      nodeRedLed,
      nodeGreenLed,
      nodeBlueLed,
    ];
    print("Create Canvas Controller");
    print(nodes);
    // neuronTypes["abc"] = "1";
    controller = InfiniteCanvasController(
      rawSyntheticNeuronList: rawSyntheticNeuronList,
      syntheticNeuronList: syntheticNeuronList,
      syntheticConnections: syntheticConnections,
      neuronTypes: neuronTypes,
      onLongPress: onLongPress,
      onDoubleTap: onDoubleTap,
      onDeleteCallback: onDeleteCallback,
      // transformNeuronPositionWrapper: transformNeuronPositionWrapper,
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
    controller.zoomReset();
    controller.maxScale = 2.7;
    controller.scale = 1;
    controller.minScale = 0.85;
    controller.pan(const Offset(-60, 0));
    // controller.zoom(0.97);
    // controller.minScale = 1;

    if (Platform.isAndroid || Platform.isIOS) {
      repositionSensoryNeuron();
    }

    controller.transform.removeListener(transformNeuronListener);
    controller.transform.addListener(transformNeuronListener);
    controller.addListener(() {
      if (isPlayingMenu) {
        return;
      }
      if (controller.mouseDown) {
        if (menuIdx == 0 && !controller.hasSelection) {
          clearUIMenu();

          setState(() => {});

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

          // print("menuIdx == 1");
          // // print(menuIdx == 0);
          // print(controller.hasSelection);

          double scales = controller.getScale();
          // print("scales");
          // print(scales);
          if (scales == 1) {
            // controller.zoomReset();
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
            clearUIMenu();
            setState(() => {});

            prevEdgesLength = controller.edges.length;
          } else {
            // if (prevEdgesLength != controller.edges.length){
            //   prevEdgesLength = controller.edges.length;
            // }else{
            if (!isTooltipOverlay) {
              isDeleteMenu = true;
            } else {
              return;
            }
            prevSelectedNeuron = selected;
            isDrawTail = true;

            if (listDefaultSensor.contains(selected)) {
            } else {
              isNeuronMenu = true;
              isSynapseMenu = false;
              isCameraMenu = false;
              isDistanceMenu = false;
              isMotorMenu = false;
              isSpeakerMenu = false;
              isMicrophoneMenu = false;
              isLedMenu = false;
              isShowDelayTime = false;
              neuronMenuType = neuronTypes[selected.id]!;
              // print("neuronTypes");
              // print(neuronTypes);
              neuronStyle = neuronStyles[selected.id] != null
                  ? neuronStyles[selected.id]!
                  : "Excitatory";
              try {
                int neuronIdx = controller.nodes
                        .map((e) => e.id)
                        .toList()
                        .indexOf(selected.id) -
                    2;

                nativec.changeIdxSelected(neuronIdx);
                // print("neuronIdx");
                // print(neuronIdx);
                // print(mapDelayNeuronList);
                // print(mapDelayNeuronList[neuronIdx]);
                if (mapDelayNeuronList[neuronIdx] > 0) {
                  isShowDelayTime = true;
                  tecTimeValue.text = mapDelayNeuronList[neuronIdx].toString();
                  sldTimeValue = mapDelayNeuronList[neuronIdx].toDouble();
                } else {
                  isShowDelayTime = false;
                  sldTimeValue = minDelayTimeValue.toDouble();
                }

                sldAWeight = aDesignArray[selected.id];
                sldBWeight = bDesignArray[selected.id];
                sldCWeight = cDesignArray[selected.id].floorToDouble();
                sldDWeight = dDesignArray[selected.id].floorToDouble();

                tecAWeight.text = sldAWeight.toString();
                tecBWeight.text = sldBWeight.toString();
                tecCWeight.text = sldCWeight.round().toString();
                tecDWeight.text = sldDWeight.round().toString();
              } catch (err) {
                print("err init canvas");
                print(err);
              }

              setState(() => {});
            }

            if (foundSelected) {
              tailNode.update(
                  offset: Offset(selected.offset.dx + gapTailX,
                      selected.offset.dy + gapTailY));
            } else {
              // POLYGON RESTRICTIONS
              if (prevConstrainedFlag) {
                prevConstrainedPos = pos;
              }

              pos = selected.offset;
              // Offset posLocal = controller.toLocal(pos);
              // selected offset is a local offset that we get from Gesture Detector CustomChildLayout.
              Offset posLocal = (pos);
              List<Offset> arrPosConstraints = [
                // controller.toLocal(pos.translate(-10, -10)), // topLeft
                // controller.toLocal(pos.translate(30, -10)), // topRight
                // controller.toLocal(pos.translate(-10, 30)), // bottomLeft
                // controller.toLocal(pos.translate(30, 30)), // bottomRight

                posLocal.translate(
                    -brainPosition.dx + -10 * controller.getScale(),
                    -brainPosition.dy + -10 * controller.getScale()), // topLeft
                posLocal.translate(
                    -brainPosition.dx + 30 * controller.getScale(),
                    -brainPosition.dy +
                        -10 * controller.getScale()), // topRight
                posLocal.translate(
                    -brainPosition.dx + -10 * controller.getScale(),
                    -brainPosition.dy +
                        30 * controller.getScale()), // bottomLeft
                posLocal.translate(
                    -brainPosition.dx + 30 * controller.getScale(),
                    -brainPosition.dy +
                        30 * controller.getScale()), // bottomRight

                // controller.toLocal(pos.translate(
                //     -10 - brainPosition.dx, -10 - brainPosition.dy)), // topLeft
                // controller.toLocal(pos.translate(
                //     30 - brainPosition.dx, -10 - brainPosition.dy)), // topRight
                // controller.toLocal(pos.translate(-10 - brainPosition.dx,
                //     30 - brainPosition.dy)), // bottomLeft
                // controller.toLocal(pos.translate(30 - brainPosition.dx,
                //     30 - brainPosition.dy)), // bottomRight
              ];
              bool flag = true;
              for (Offset pos in arrPosConstraints) {
                // if (coreBrainPainter != null) {
                if (!coreBrainPainter.path.contains(pos)) {
                  flag = false;
                }
                // }
              }
              print("Polygon Restrictions");
              print(controller.getScale());
              print(controller.spacePressed);
              print(posLocal);
              print(arrPosConstraints);
              print(flag);

              if (!flag) {
                // selected.update(offset: Offset(435, 300));
                selected.update(offset: prevConstrainedPos);
              }
              prevConstrainedFlag = flag;
              // if (!coreBrainPainter.path.contains(pos))
              // sensorPolygonPaths[0]
              // CONSTRAINT RESTRICTIONS
              // if (selected.offset.dx < constraintBrainLeft) {
              //   var newOffset = Offset(constraintBrainLeft, pos.dy);
              //   selected.update(
              //       size: selected.size, offset: newOffset, label: "");
              // } else if (selected.offset.dx > constraintBrainRight) {
              //   var newOffset = Offset(constraintBrainRight, pos.dy);
              //   selected.update(
              //       size: selected.size, offset: newOffset, label: "");
              // }

              // pos = selected.offset;

              // if (selected.offset.dy < constraintBrainTop) {
              //   var newOffset = Offset(pos.dx, constraintBrainTop);
              //   selected.update(
              //       size: selected.size, offset: newOffset, label: "");
              // } else if (selected.offset.dy > constraintBrainBottom) {
              //   var newOffset = Offset(pos.dx, constraintBrainBottom);
              //   selected.update(
              //       size: selected.size, offset: newOffset, label: "");
              // }

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
          print("MenuIdx");
          print(menuIdx);
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
          UniqueKey newNodeKey = UniqueKey();
          neuronsKey.add(newNodeKey);
          mapDelayNeuronList.add(-1);
          mapRhytmicNeuronList.add(-1);
          mapCountingNeuronList.add(-1);
          // neuronTypes[newNodeKey.toString()] = (randomNeuronType());
          neuronTypes[newNodeKey.toString()] = "Quiet";
          neuronStyles[newNodeKey.toString()] = "Excitatory";

          // aDesignArray[newNodeKey.toString()] = defaultA;
          // bDesignArray[newNodeKey.toString()] = defaultB;
          // cDesignArray[newNodeKey.toString()] = defaultC;
          // dDesignArray[newNodeKey.toString()] = defaultD;
          aDesignArray[newNodeKey.toString()] = sldAWeight;
          bDesignArray[newNodeKey.toString()] = sldBWeight;
          cDesignArray[newNodeKey.toString()] = sldCWeight;
          dDesignArray[newNodeKey.toString()] = sldDWeight;

          SyntheticNeuron syntheticNeuron = SyntheticNeuron(
              // neuronKey: newNodeKey,
              isActive: false,
              isIO: false,
              circleRadius: neuronDrawSize / 2);
          InfiniteCanvasNode newNode = InfiniteCanvasNode(
            key: neuronsKey[neuronsKey.length - 1],
            value: neuronSize - 1,
            allowMove: false,
            allowResize: false,
            offset: Offset(mouseX - 10, mouseY - 10),
            size: Size(neuronDrawSize, neuronDrawSize),
            child: CustomPaint(
              isComplex: true,
              willChange: true,
              painter: syntheticNeuron,
              // painter: InlineCustomPainter(
              //   brush: Paint(),
              //   builder: (brush, canvas, rect) {
              //     // brush.color = Theme.of(context).colorScheme.secondary;
              //     brush.color = neuronColor.color;
              //     canvas.drawCircle(rect.center, rect.width / 2, brush);

              //     // canvas.drawCircle(
              //     //     rect.center, rect.width / 2 / controller.scale, brush);
              //   },
              // ),
            ),
            // child: Container(width: 0,height:0, color:Colors.green),
          );
          newNode.syntheticNeuron = syntheticNeuron;
          syntheticNeuron.node = newNode;
          syntheticNeuron.setupDrawingNeuron();
          syntheticNeuronList.add(syntheticNeuron);

          SyntheticNeuron rawSyntheticNeuron = SyntheticNeuron(
              // neuronKey: newNodeKey,
              isActive: false,
              isIO: false,
              circleRadius: neuronDrawSize / 2);
          rawSyntheticNeuron.node = newNode;
          rawSyntheticNeuron.copyDrawingNeuron(syntheticNeuron);
          rawSyntheticNeuronList.add(rawSyntheticNeuron);
          syntheticNeuron.rawSyntheticNeuron = rawSyntheticNeuron;

          controller.add(newNode);

          initNativeC(false);

          Future.delayed(const Duration(milliseconds: 100), () {
            controller.deselect(neuronsKey[neuronsKey.length - 1]);
          });
        } else if (menuIdx == 2 && !isCreatePoint && controller.hasSelection) {
          print('design brain start');
          print("------------------");
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
                // addSyntheticConnection(axonFrom, axonTo);

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
          // controller.zoomReset();
          // controller.pan(const Offset(-60, 0));
          isChartSelected = false;
          nativec.changeIdxSelected(-1);
          setState(() {});
        } else if (menuIdx == 6 && controller.hasSelection) {
          var selected = controller.selection[0];
          print("selected.value");
          print(selected.value);
          isChartSelected = false;

          int neuronIdx =
              controller.nodes.map((e) => e.id).toList().indexOf(selected.id) -
                  2;

          nativec.changeIdxSelected(neuronIdx);
          redrawNeuronLine.value = Random().nextInt(100);
          setState(() {});
        }
      } else {
        isCreatePoint = false;
        if (controller.controlPressed) {
          // create link
          Future.delayed(const Duration(milliseconds: 100), () {
            print("creating link0");
            // print(controller.edges.isNotEmpty);
            if (controller.edges.isNotEmpty) {
              final lastCreatedEdge =
                  controller.edges[controller.edges.length - 1];
              print("rawSyntheticNeuronList.length");
              print(rawSyntheticNeuronList.length);
              rawSyntheticNeuronList.map((e) {
                print("e.neuronIdx");
                print(e.neuronIdx);
              });

              InfiniteCanvasNode neuronFrom =
                  findNeuronByKey(lastCreatedEdge.from);
              InfiniteCanvasNode neuronTo = findNeuronByKey(lastCreatedEdge.to);
              int isDefaultRobotEdge = 0;
              for (var defaultSensor in listDefaultSensor) {
                if (defaultSensor == neuronFrom) {
                  isDefaultRobotEdge++;
                }
                if (defaultSensor == neuronTo) {
                  isDefaultRobotEdge++;
                }
              }
              print("creating link");

              // InfiniteCanvasNode nodeFrom = findNeuronByKey(controller.edgeSelected.from);
              // InfiniteCanvasNode nodeTo = findNeuronByKey(controller.edgeSelected.to);

              if (neuronFrom == nodeLeftEyeSensor ||
                  neuronFrom == nodeRightEyeSensor) {
                mapSensoryNeuron["${neuronFrom.id}_${neuronTo.id}"] = 2;
              } else if (neuronFrom == nodeDistanceSensor) {
                mapDistanceNeuron["${neuronFrom.id}_${neuronTo.id}"] = 0;
                mapDistanceLimitNeuron["${neuronFrom.id}_${neuronTo.id}"] = 0;
              } else if (neuronTo == nodeLeftMotorForwardSensor ||
                  neuronTo == nodeLeftMotorBackwardSensor ||
                  neuronTo == nodeRightMotorForwardSensor ||
                  neuronTo == nodeRightMotorBackwardSensor) {
                mapContactsNeuron["${neuronFrom.id}_${neuronTo.id}"] = 50.0;
              } else if (neuronTo == nodeSpeakerSensor) {
                mapSpeakerNeuron["${neuronFrom.id}_${neuronTo.id}"] = 40.0;
              } else if (neuronTo == nodeMicrophoneSensor) {
                // isMicrophoneMenu
                mapMicrophoneNeuron["${neuronFrom.id}_${neuronTo.id}"] = 40.0;
              } else if (neuronTo == nodeRedLed ||
                  neuronTo == nodeGreenLed ||
                  neuronTo == nodeBlueLed) {
                mapLedNeuron["${neuronFrom.id}_${neuronTo.id}"] = 50;
                mapLedNeuronPosition["${neuronFrom.id}_${neuronTo.id}"] =
                    "1111";
              } else {
                mapConnectome["${neuronFrom.id}_${neuronTo.id}"] = 50.0;
                lastCreatedEdge.connectionStrength = 50.0;
              }

              // print(isDefaultRobotEdge);
              if (isDefaultRobotEdge >= 2) {
                controller.edges.remove(lastCreatedEdge);
              }
              setState(() {});
            }
          });
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
          clearUIMenu();
          setState(() => {});

          tailNode.update(offset: tailNode.offset);
        }
        // isTooltipOverlay = false;
        // setState((){});
      }
    });

    initNeuronType();
  }

  InfiniteCanvasNode findNeuronByValue(val) {
    // print("val");
    // print(val);
    var list = controller.nodes.where((element) {
      // print("element.value");
      // print(element.value);
      // print(val);
      // print(element.value.runtimeType);
      // print(val.runtimeType);
      // print("------");
      return element.value == val;
    }).toList(growable: false);
    return list[0];
  }

  InfiniteCanvasNode findNeuronByValueKey(key) {
    var list = controller.nodes.where((InfiniteCanvasNode element) {
      return element.valKey == key;
    }).toList(growable: false);
    return list[0];
  }

  InfiniteCanvasNode findNeuronByKey(key) {
    var list = controller.nodes
        .where((element) => element.key == key)
        .toList(growable: false);
    return list[0];
  }

  void linkNeuronConnection(value) {
    // print("neuron");
    // print(value);
    if (value.trim().length == 0) return;
    double val = double.parse(value);
    if (val > 100) {
      val = 100;
    }
    final lastCreatedEdge = controller.edgeSelected;
    final neuronFrom = findNeuronByKey(lastCreatedEdge.from);
    final neuronTo = findNeuronByKey(lastCreatedEdge.to);

    // mapConnectome["${lastCreatedEdge.from}_${lastCreatedEdge.to}"] = val;
    mapConnectome["${neuronFrom.id}_${neuronTo.id}"] = val;
    lastCreatedEdge.connectionStrength = val;
    // print("${neuronFrom.id}_${neuronTo.id}");
  }

  void linkMotorConnection(value) {
    print("motor");
    print(value);
    if (value.trim().length == 0) return;
    double val = double.parse(value);
    if (val > 100) {
      val = 100;
    }

    final lastCreatedEdge = controller.edgeSelected;
    final neuronFrom = findNeuronByKey(lastCreatedEdge.from);
    final neuronTo = findNeuronByKey(lastCreatedEdge.to);

    // mapContactsNeuron["${lastCreatedEdge.from}_${lastCreatedEdge.to}"] = val;
    mapContactsNeuron["${neuronFrom.id}_${neuronTo.id}"] = val;
  }

  void linkSensoryConnection(value) {
    print("sensory");
    print(value);
    final selectedEdge = controller.edgeSelected;
    final neuronFrom = findNeuronByKey(selectedEdge.from);
    final neuronTo = findNeuronByKey(selectedEdge.to);
    String neuronFromToLabel = "${neuronFrom.id}_${neuronTo.id}";

    // mapSensoryNeuron["${lastCreatedEdge.from}_${lastCreatedEdge.to}"] = value;
    mapSensoryNeuron[neuronFromToLabel] = cameraMenuTypes.indexOf(value);
  }

  void linkDistanceConnection(value) {
    final lastCreatedEdge = controller.edgeSelected;
    final neuronFrom = findNeuronByKey(lastCreatedEdge.from);
    final neuronTo = findNeuronByKey(lastCreatedEdge.to);

    // mapDistanceNeuron["${lastCreatedEdge.from}_${lastCreatedEdge.to}"] = value;
    mapDistanceNeuron["${neuronFrom.id}_${neuronTo.id}"] =
        distanceMenuTypes.indexOf(value);
    print("distanceMenu $distanceMenuType");
    print(mapDistanceNeuron["${neuronFrom.id}_${neuronTo.id}"]);
    print(distanceMinLimitBufView);
    print(distanceMaxLimitBufView);
    int toIdx = neuronTypes.keys.toList().indexOf(neuronTo.id);
    // print(neuronTypes);
    // print(neuronTo);
    // print(toIdx);

    mapDistanceLimitNeuron["${neuronFrom.id}_${neuronTo.id}"] =
        "${distanceMinLimitBufView[toIdx]}_@_${distanceMaxLimitBufView[toIdx]}";
  }

  void initNeuronType() {
    // neuronTypes = {};
    print("init neuron tyep");
    neuronTypes.clear();
    mapDelayNeuronList = List.generate(neuronSize, (index) => -1);
    mapRhytmicNeuronList = List.generate(neuronSize, (index) => -1);
    mapCountingNeuronList = List.generate(neuronSize, (index) => -1);

    for (int i = 0; i < neuronSize; i++) {
      if (i < normalNeuronStartIdx) {
        LocalKey newNodeKey = controller.nodes[2 + i].key;
        neuronTypes[newNodeKey.toString()] = "Quiet";
        neuronStyles[newNodeKey.toString()] = "Excitatory";
        aDesignArray[newNodeKey.toString()] = 0.02;
        bDesignArray[newNodeKey.toString()] = 0.1;
        cDesignArray[newNodeKey.toString()] = -65;
        dDesignArray[newNodeKey.toString()] = 2;
        // neuronTypes.add("Quiet");
      } else {
        UniqueKey newNodeKey = UniqueKey();
        // neuronTypes[newNodeKey.toString()] = (randomNeuronType());
        neuronTypes[newNodeKey.toString()] = "Quiet";
        neuronStyles[newNodeKey.toString()] = "Excitatory";

        aDesignArray[newNodeKey.toString()] = 0.02;
        bDesignArray[newNodeKey.toString()] = 0.1;
        cDesignArray[newNodeKey.toString()] = -65;
        dDesignArray[newNodeKey.toString()] = 2;
      }
    }
  }

  void onLongPress() {
    return;
    print("longPress");
    MyApp.analytics.logEvent(
      name: 'longpress',
      parameters: <String, dynamic>{
        'longpress': 'true',
      },
    );
    if (controller.hasSelection) {
      var selected = controller.selection[0];
      int neuronIdx =
          controller.nodes.map((e) => e.id).toList().indexOf(selected.id) - 2;
      // print(neuronIdx);
      if (neuronIdx < normalNeuronStartIdx) {
        return;
      }
      isChartSelected = true;
      nativec.changeIdxSelected(neuronIdx);

      // String neuronType = neuronTypes[neuronIdx];
      String neuronType = neuronTypes[selected.id]!;
      neuronDialogBuilder(context, "Neuron ", (selected.id).toString(),
          neuronType, neuronTypeChangeCallback, deleteNeuronCallback);
    } else if (controller.isSelectingEdge) {
      int isSensoryType = 0;

      final lastCreatedEdge = controller.edgeSelected;
      InfiniteCanvasNode neuronFrom = findNeuronByKey(lastCreatedEdge.from);
      InfiniteCanvasNode neuronTo = findNeuronByKey(lastCreatedEdge.to);
      // InfiniteCanvasNode neuronTo = findNeuronByKey(lastCreatedEdge.to);
      if (neuronFrom == nodeLeftEyeSensor || neuronFrom == nodeRightEyeSensor) {
        isSensoryType = 1;
      } else if (neuronTo == nodeLeftMotorBackwardSensor ||
          neuronTo == nodeRightMotorBackwardSensor ||
          neuronTo == nodeLeftMotorForwardSensor ||
          neuronTo == nodeRightMotorForwardSensor) {
        isSensoryType = 2;
      } else if (neuronFrom == nodeDistanceSensor) isSensoryType = 3;

      print("isVisualSensory");
      print(isSensoryType);
      Map<String, double> map = {
        // "connectomeContact": connectomeBufView[ neuronFrom.value * neuronSize + neuronTo.value],
        // "neuronContact": neuronContactsBufView[ neuronFrom.value * neuronSize + neuronTo.value],
        // "visualPref": visPrefsBufView[ neuronFrom.value * neuronSize + neuronTo.value].toDouble(),
        "connectomeContact":
            mapConnectome.containsKey("${neuronFrom.id}_${neuronTo.id}")
                ? mapConnectome["${neuronFrom.id}_${neuronTo.id}"]
                : 0,
        "neuronContact":
            mapContactsNeuron.containsKey("${neuronFrom.id}_${neuronTo.id}")
                ? mapContactsNeuron["${neuronFrom.id}_${neuronTo.id}"]
                : 0,
        "visualPref":
            mapSensoryNeuron.containsKey("${neuronFrom.id}_${neuronTo.id}")
                ? mapSensoryNeuron["${neuronFrom.id}_${neuronTo.id}"].toDouble()
                : -1.0,
        "distanceContact":
            mapDistanceNeuron.containsKey("${neuronFrom.id}_${neuronTo.id}")
                ? mapDistanceNeuron["${neuronFrom.id}_${neuronTo.id}"]
                : -1,
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
          linkNeuronConnection,
          linkDistanceConnection);

      // axonDialogBuilder(context, isSensoryType, "Edge", " ",  neuronTypeChangeCallback,
      //     deleteEdgeCallback, linkSensoryConnection, linkMotorConnection, linkNeuronConnection);
      // axonDialogBuilder(
      //     context, isSensory, "Edge", " ", neuronTypeChangeCallback, deleteEdgeCallback);
    }
  }

  void onDoubleTap() {
    if (controller.scale == 2.0) {
      controller.zoomReset();
      // controller.pan(const Offset(-60, 0));
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

  void updateFromSimulation(String message) async {
    if (isReceivingCalculation) {
      // print("message");
      // print(message);
      await mutex.protectWrite(() async {
        commandList.add(message.toString());
      });

      if (flagCommandDataLength > 0) {
        strCommandList = "";
        flagCommandDataLength = -1;
      }
      await mutexCommand.protectWrite(() async {
        strCommandList += message;
      });
    }
  }

  void populateNode(v, nodeKey, nIdx, Map<String, dynamic> syntheticNeuronJson,
      savedFileJson) {
    // double savedRatio = savedFileJson["screenDensity"];
    // double curScale = savedRatio;
    // if (savedRatio >= MediaQuery.of(context).devicePixelRatio) {
    //   curScale = MediaQuery.of(context).devicePixelRatio;
    // }
    double curScale = 1;
    print("curScale111");
    print(curScale);
    SyntheticNeuron syntheticNeuron = SyntheticNeuron(
        // neuronKey: newNodeKey,
        isActive: false,
        isIO: false,
        circleRadius: neuronDrawSize / 2);

    InfiniteCanvasNode tempNode = InfiniteCanvasNode(
      value: v["index"],
      key: nodeKey,
      offset:
          Offset(v["position"][0], v["position"][1]).scale(curScale, curScale),
      size: Size(neuronDrawSize, neuronDrawSize),
      allowResize: false,
      child: Builder(
        builder: (context) {
          return CustomPaint(
            isComplex: true,
            willChange: true,
            painter: syntheticNeuronJson.containsKey("dendrites")
                ? syntheticNeuron
                : InlineCustomPainter(
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

    tempNode.valKey = v["valKey"];
    if (syntheticNeuronJson.containsKey("dendrites")) {
      syntheticNeuron.node = tempNode;
      syntheticNeuron.setupDrawingNeuron();

      double centerX = syntheticNeuronJson["centerPos"][0];
      double centerY = syntheticNeuronJson["centerPos"][1];
      syntheticNeuron.centerPos = Offset(centerX, centerY);
      syntheticNeuron.neuronIdx = nIdx;
      syntheticNeuron.randomVariation1 =
          syntheticNeuronJson["randomVariation1"];
      syntheticNeuron.randomVariation2 =
          syntheticNeuronJson["randomVariation2"];

      syntheticNeuron.newNeuron.xNucleus = syntheticNeuronJson["xNucleus"];
      syntheticNeuron.newNeuron.yNucleus = syntheticNeuronJson["yNucleus"];
      syntheticNeuron.newNeuron.widthNucleus =
          syntheticNeuronJson["widthNucleus"];
      syntheticNeuron.newNeuron.heightNucleus =
          syntheticNeuronJson["heightNucleus"];

      // List<Dendrite> dendrites = [];
      syntheticNeuron.dendrites.clear();
      for (Map<String, dynamic> dendriteJson
          in syntheticNeuronJson["dendrites"]) {
        Dendrite tempDendrite = Dendrite(
            hasSecondLevel: dendriteJson["hasSecondLevel"],
            angle: dendriteJson["angle"],
            sinapseFirstLevel: [],
            sinapseSecondLevel: [],
            xFirstLevel: dendriteJson["xFirstLevel"],
            yFirstLevel: dendriteJson["yFirstLevel"],
            xSecondLevel: dendriteJson["xSecondLevel"],
            ySecondLevel: dendriteJson["ySecondLevel"],
            xTriangleFirstLevel: dendriteJson["xTriangleFirstLevel"],
            xTriangleSecondLevel: dendriteJson["xTriangleSecondLevel"],
            yTriangleFirstLevel: dendriteJson["yTriangleFirstLevel"],
            yTriangleSecondLevel: dendriteJson["yTriangleSecondLevel"]);

        syntheticNeuron.dendrites.add(tempDendrite);
        // dendrites.add(
      }
      print("syntheticNeuronJson['dendrites'].length");
      print(syntheticNeuronJson["dendrites"].length);
      // syntheticNeuron.dendrites = dendrites;
    }
    if (syntheticNeuronJson.containsKey("dendrites")) {
      tempNode.syntheticNeuron = syntheticNeuron;
      // syntheticNeuron.setupDrawingNeuron();
      syntheticNeuronList.add(syntheticNeuron);

      SyntheticNeuron rawSyntheticNeuron = SyntheticNeuron(
          // neuronKey: newNodeKey,
          isActive: false,
          isIO: false,
          circleRadius: neuronDrawSize / 2);
      rawSyntheticNeuron.node = tempNode;
      rawSyntheticNeuron.copyDrawingNeuron(syntheticNeuron);
      syntheticNeuron.rawSyntheticNeuron = rawSyntheticNeuron;

      rawSyntheticNeuronList.add(rawSyntheticNeuron);
    }
    print("tempNode.key");
    print(tempNode.id);
    controller.nodes.add(tempNode);
  }

  Future<String> saveCurrentBrain(String title, String description) async {
    // mainBloc.setLoading(1);
    ProgressDialog pd = ProgressDialog(context: context);
    pd.show(msg: 'Saving Brain...');

    var nodesJson = [];
    for (InfiniteCanvasNode e in controller.nodes) {
      print("e.value == null");
      if (e.value == -2) {
        nodesJson.add({
          "valKey": e.key.toString(),
          "index": e.value,
          "position": [e.offset.dx, e.offset.dy],
          "color": [e.offset.dx, e.offset.dy],
          "shape": "SizedBox",
        });
      } else if (e.value == -1) {
        nodesJson.add({
          "valKey": e.key.toString(),
          "index": e.value,
          "position": [e.offset.dx, e.offset.dy],
          "color": [e.offset.dx, e.offset.dy],
          "shape": "CustomPainter"
        });
      } else if (e.value < normalNeuronStartIdx) {
        nodesJson.add({
          "valKey": e.key.toString(),
          "index": e.value,
          "position": [e.offset.dx, e.offset.dy],
          "color": [e.offset.dx, e.offset.dy],
          "shape": "CustomPaint"
        });
      } else {
        print("e.offset");
        print(e.offset);
        nodesJson.add({
          "valKey": e.key.toString(),
          "index": e.value,
          "position": [e.offset.dx, e.offset.dy],
          "color": [e.offset.dx, e.offset.dy],
          "shape": "CustomPaint"
        });
        // e.value >=normalNeuronStartIdx
      }
    }

    var edgesJson = [];
    for (var edge in controller.edges) {
      InfiniteCanvasNode from = findNeuronByKey(edge.from);
      InfiniteCanvasNode to = findNeuronByKey(edge.to);
      edgesJson.add("${from.id}_#_${to.id}");
    }

    var rawSyntheticNeuronListJson = [];
    // for (SyntheticNeuron syntheticNeuron in rawSyntheticNeuronList) {
    var idxSyntheticNeuron = 0;
    for (SyntheticNeuron syntheticNeuron in rawSyntheticNeuronList) {
      List<Map<String, dynamic>> dendrites = [];
      for (Dendrite dendrite in syntheticNeuron.dendrites) {
        dendrites.add({
          "angle": dendrite.angle,
          "hasSecondLevel": dendrite.hasSecondLevel,
          "sinapseFirstLevel": [],
          "sinapseSecondLevel": dendrite.sinapseSecondLevel,
          "xFirstLevel": dendrite.xFirstLevel,
          "xSecondLevel": dendrite.xSecondLevel,
          "xTriangleFirstLevel": dendrite.xTriangleFirstLevel,
          "xTriangleSecondLevel": dendrite.xTriangleSecondLevel,
          "yFirstLevel": dendrite.yFirstLevel,
          "ySecondLevel": dendrite.ySecondLevel,
          "yTriangleFirstLevel": dendrite.yTriangleFirstLevel,
          "yTriangleSecondLevel": dendrite.yTriangleSecondLevel,
        });
      }

      rawSyntheticNeuronListJson.add({
        // "activeColor": syntheticNeuron.activeColor.toString(),
        "arrowSize": syntheticNeuron.arrowSize,
        "xNucleus": syntheticNeuronList[idxSyntheticNeuron].newNeuron.xNucleus,
        "yNucleus": syntheticNeuronList[idxSyntheticNeuron].newNeuron.yNucleus,
        "widthNucleus":
            syntheticNeuronList[idxSyntheticNeuron].newNeuron.widthNucleus,
        "heightNucleus":
            syntheticNeuronList[idxSyntheticNeuron].newNeuron.heightNucleus,
        "dendrites": dendrites,
        "centerPos": [
          syntheticNeuron.centerPos.dx,
          syntheticNeuron.centerPos.dy
        ],
        "circleRadius": syntheticNeuron.circleRadius,
        "neuronIdx": syntheticNeuron.neuronIdx,
        // "random": syntheticNeuron.random,
        "randomVariation1": syntheticNeuron.randomVariation1,
        "randomVariation2": syntheticNeuron.randomVariation2,
        // "randomVariation2": syntheticNeuron.zoomScale,
      });
      idxSyntheticNeuron++;
    }
    // print("json.encode(rawSyntheticNeuronListJson)");
    // print(json.encode(rawSyntheticNeuronListJson));
    String strNodesJson = json.encode({
      "nodes": nodesJson,
      "edges": edgesJson,
      "neuronTypes": neuronTypes,
      "neuronStyles": neuronStyles,
      // "aDesignArray": aDesignArray,
      // "bDesignArray": bDesignArray,
      // "cDesignArray": cDesignArray,
      // "dDesignArray": dDesignArray,
      "mapConnectome": mapConnectome,
      "mapSensoryNeuron": mapSensoryNeuron,
      "mapContactsNeuron": mapContactsNeuron,
      "mapDistanceNeuron": mapDistanceNeuron,
      "mapDistanceLimitNeuron": mapDistanceLimitNeuron,
      "mapSpeakerNeuron": mapSpeakerNeuron,
      "mapMicrophoneNeuron": mapMicrophoneNeuron,
      "mapLedNeuron": mapLedNeuron,
      "mapLedNeuronPosition": mapLedNeuronPosition,

      "rawSyntheticNeuron": rawSyntheticNeuronListJson,

      "mapDelayNeuron": mapDelayNeuronList,
      "mapRhytmicNeuron": mapRhytmicNeuronList,
      "mapCountingNeuron": mapCountingNeuronList,
      "a": aBufView.toList(),
      "b": bBufView.toList(),
      "c": cBufView.toList(),
      "d": dBufView.toList(),
      "i": iBufView.toList(),
      "w": wBufView.toList(),
      "windowWidth": MediaQuery.of(context).size.width,
      "windowHeight": MediaQuery.of(context).size.height,
      "screenDensity": MediaQuery.of(context).devicePixelRatio,
    });
    print("strNodesJson");
    print(strNodesJson);
    // print("NEURON TYPES");
    // print(neuronTypes);

    String fileName = DateTime.now().microsecondsSinceEpoch.toString();
    Directory directory =
        (await getApplicationDocumentsDirectory()); //from path_provide package

    Directory imgDirectory =
        Directory("${(await getApplicationDocumentsDirectory()).path}/images");
    // Directory((await getApplicationDocumentsDirectory()).path);
    Directory txtDirectory =
        Directory("${(await getApplicationDocumentsDirectory()).path}/text");

    // Directory((await getApplicationDocumentsDirectory()).path);
    if (!imgDirectory.existsSync()) imgDirectory.createSync();
    if (!txtDirectory.existsSync()) txtDirectory.createSync();

    print(directory.path);
    String textPath = "${Platform.pathSeparator}text";
    // String textPath = "";
    String imagesPath = "${Platform.pathSeparator}images";
    // String imagesPath = "";
    final File file = File(
        '${directory.path}$textPath${Platform.pathSeparator}BrainText$fileName.txt');
    await file.writeAsString(strNodesJson);

    ScreenshotController screenshotController = ScreenshotController();
    String imagePath = "";
    await screenshotController
        .captureFromWidget(mainBody)
        .then((imageBytes) async {
      // String directory = (await getApplicacationDocumentsDirectory())
      //     .path; //from path_provide package
      // String fileName = DateTime.now().microsecondsSinceEpoch.toString();
      // path = '$directory';
      title = title.replaceAll(".", "|");
      description = description.replaceAll(".", "|");
      title = title.replaceAll("@", "#");
      description = description.replaceAll("@", "#");
      final directory = await getApplicationDocumentsDirectory();
      final imageFile = await File(
              '${directory.path}$imagesPath${Platform.pathSeparator}Brain$fileName@@@$title@@@$description.png')
          .create();
      await imageFile.writeAsBytes(imageBytes);
      pd.close();

      Future.delayed(const Duration(seconds: 1), () {
        rightToolbarCallback({"menuIdx": 0});
        setState(() {});
      });
      imagePath = imageFile.path;

      // mainBloc.setLoading(0);
    });

    return imagePath;
  }

  void selectSavedBrain(String filename, {String? filePath}) async {
    String textPath = "${Platform.pathSeparator}text";
    // String textPath = "";
    controller.deselectAll();
    clearUIMenu();
    // setState(() {});

    if (filename == "") return;
    controller.edges.clear();
    int len = controller.nodes.length;
    neuronTypes.clear();
    for (int i = normalNeuronStartIdx + 2; i < len; i++) {
      controller.nodes.removeLast();
    }
    clearBridge();

    if (filename == "-1") {
      return;
    }

    // if selectedFilename is not default and not the same then we need to delete the old file
    if (selectedFileName != "-" && selectedFileName != filename) {
      // delete the old file
    }
    selectedFileName = filename;
    pMapStatus["currentFileName"] = filePath ?? "";

    final Directory directory = await getApplicationDocumentsDirectory();
    final File savedFile = File(
        '${directory.path}$textPath${Platform.pathSeparator}BrainText$filename.txt');
    String savedFileText = await savedFile.readAsString();
    Map savedFileJson = json.decode(savedFileText);

    // END OF READING FILE

    double tempWidth = MediaQuery.of(context).size.width;
    double tempHeight = MediaQuery.of(context).size.height;

    try {
      if (savedFileJson["windowWidth"] != null) {
        double displayWidth = savedFileJson["windowWidth"];
        double displayHeight = savedFileJson["windowHeight"];
        // double displayWidth = savedFileJson["windowWidth"] *
        //     savedFileJson["screenDensity"] /
        //     MediaQuery.of(context).devicePixelRatio;
        // double displayHeight = savedFileJson["windowHeight"] *
        //     savedFileJson["screenDensity"] /
        //     MediaQuery.of(context).devicePixelRatio;
        // print("change window size");
        await windowManager.setSize(Size(displayWidth, displayHeight));
      }
    } catch (err) {
      print("err");
      print(err);
    }

    await Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {});
    });
    // print("change window size finished");

    List<dynamic> nodesJson = savedFileJson["nodes"];
    // List<String> tempNeuronTypes =
    //     List.generate(neuronTypes.length, (index) => neuronTypes[index]);
    List<LocalKey> tempNeuronsKey = [];

    Map<String, String> mapTranslateLoadKeys = {};
    // List<ValueKey> tempNeuronsKey =
    //     List.generate(neuronsKey.length, (index) => ValueKey(neuronsKey[index].toString()));
    var rawSyntheticNeuronListJson = savedFileJson["rawSyntheticNeuron"];
    int nIdx = 0;

    for (var v in nodesJson) {
      String loadedNeuronKey = v["valKey"];
      if (v["index"] == -2 || v["index"] == -1) {
        print("shadow neuron");
        InfiniteCanvasNode neuron = findNeuronByValue(v["index"]);
        neuron.valKey = loadedNeuronKey;
        tempNeuronsKey.add(neuron.key);
        mapTranslateLoadKeys[neuron.valKey] = neuron.id;

        // SyntheticNeuron synNeuron = SyntheticNeuron(
        //     isActive: false, isIO: true, circleRadius: neuronDrawSize / 2);
        // if (v["index"] == -2) {
        //   synNeuron.node = controller.nodes[0];
        // } else if (v["index"] == -1) {
        //   synNeuron.node = controller.nodes[1];
        // }
        // synNeuron.setupDrawingNeuron();
        // syntheticNeuronList.add(synNeuron);

        // SyntheticNeuron rawSynNeuron = SyntheticNeuron(
        //     isActive: false, isIO: true, circleRadius: neuronDrawSize / 2);
        // if (v["index"] == -2) {
        //   rawSynNeuron.node = controller.nodes[0];
        // } else if (v["index"] == -1) {
        //   rawSynNeuron.node = controller.nodes[1];
        // }

        // rawSynNeuron.copyDrawingNeuron(synNeuron);
        // rawSyntheticNeuronList.add(rawSynNeuron);
        // synNeuron.rawSyntheticNeuron = rawSynNeuron;
        // print("rawSyntheticNeuronList.length 0");
        // print(rawSyntheticNeuronList.length);
      } else if (v["index"] < normalNeuronStartIdx) {
        InfiniteCanvasNode neuron = findNeuronByValue(v["index"]);
        neuron.valKey = loadedNeuronKey;
        tempNeuronsKey.add(neuron.key);
        mapTranslateLoadKeys[neuron.valKey] = neuron.id;

        SyntheticNeuron synNeuron = SyntheticNeuron(
            isActive: false, isIO: true, circleRadius: neuronDrawSize / 2);
        // if (v["index"] == 0) {
        //   print('v["index"]');
        //   print(neuron.key.toString());
        //   print(neuron.offset.dx);
        //   print(neuron.offset.dy);
        // }
        synNeuron.node = controller.nodes[v["index"] + allNeuronStartIdx];
        synNeuron.setupDrawingNeuron();
        synNeuron.newNeuron.x = synNeuron.newNeuron.drawX + neuron.offset.dx;
        synNeuron.newNeuron.y = synNeuron.newNeuron.drawY + neuron.offset.dy;
        print(
            "XSynFrom: ${synNeuron.newNeuron.drawX} _ ${synNeuron.newNeuron.x}");
        print(
            "YSynFrom: ${synNeuron.newNeuron.drawY} _ ${synNeuron.newNeuron.y}");

        syntheticNeuronList.add(synNeuron);

        SyntheticNeuron rawSynNeuron = SyntheticNeuron(
            isActive: false, isIO: true, circleRadius: neuronDrawSize / 2);
        rawSynNeuron.node = controller.nodes[v["index"]];

        rawSynNeuron.copyDrawingNeuron(synNeuron);
        // rawSynNeuron.newNeuron.x =
        //     rawSynNeuron.newNeuron.drawX + neuron.offset.dx;
        // rawSynNeuron.newNeuron.y =
        //     rawSynNeuron.newNeuron.drawY + neuron.offset.dy;

        rawSyntheticNeuronList.add(rawSynNeuron);
        synNeuron.rawSyntheticNeuron = rawSynNeuron;

        nIdx++;
      } else {
        LocalKey nodeKey = UniqueKey();
        tempNeuronsKey.add(nodeKey);
        populateNode(
            v, nodeKey, nIdx, rawSyntheticNeuronListJson[nIdx], savedFileJson);
        mapTranslateLoadKeys[loadedNeuronKey] = nodeKey.toString();

        nIdx++;
      }
    }
    print("Map translated Load Keys ${syntheticNeuronList.length}");

    mapConnectome = translateLoadedMap(
        savedFileJson["mapConnectome"], mapTranslateLoadKeys);

    List<dynamic> edgesJson = savedFileJson["edges"];
    for (var v in edgesJson) {
      List<String> arr = v.toString().split("_#_");
      InfiniteCanvasNode nodeFrom = findNeuronByValueKey((arr[0]));
      InfiniteCanvasNode nodeTo = findNeuronByValueKey((arr[1]));

      InfiniteCanvasEdge edge = InfiniteCanvasEdge(
        from: nodeFrom.key,
        to: nodeTo.key,
      );
      String connectionKey = "${nodeFrom.id}_${nodeTo.id}";
      edge.connectionStrength = mapConnectome[connectionKey] ?? 0;
      controller.edges.add(edge);
    }
    print("Edges");

    mapSensoryNeuron = translateLoadedMap(
        savedFileJson["mapSensoryNeuron"], mapTranslateLoadKeys);
    mapContactsNeuron = translateLoadedMap(
        savedFileJson["mapContactsNeuron"], mapTranslateLoadKeys);
    mapDistanceNeuron = translateLoadedMap(
        savedFileJson["mapDistanceNeuron"], mapTranslateLoadKeys);
    try {
      mapDistanceLimitNeuron = translateLoadedMap(
          savedFileJson["mapDistanceLimitNeuron"], mapTranslateLoadKeys);
    } catch (err) {
      print("Distance Limit not found");
    }
    mapSpeakerNeuron = translateLoadedMap(
        savedFileJson["mapSpeakerNeuron"], mapTranslateLoadKeys);
    mapMicrophoneNeuron = translateLoadedMap(
        savedFileJson["mapMicrophoneNeuron"], mapTranslateLoadKeys);
    mapLedNeuron =
        translateLoadedMap(savedFileJson["mapLedNeuron"], mapTranslateLoadKeys);

    mapLedNeuronPosition = savedFileJson["mapLedNeuronPosition"] == null
        ? {}
        : translateLoadedMap(
            savedFileJson["mapLedNeuronPosition"], mapTranslateLoadKeys);

    // neuronTypes = List<String>.from(savedFileJson["neuronTypes"]);
    Map<String, String> tempNeuronTypes = translateLoadedNeuron(
        savedFileJson["neuronTypes"], mapTranslateLoadKeys);
    // print("mapDistanceLimitNeuron");
    // print(mapDistanceLimitNeuron);
    neuronTypes.clear();
    tempNeuronTypes.forEach((key, value) {
      neuronTypes[key] = value;
    });
    if (savedFileJson["neuronStyles"] != null) {
      neuronStyles = translateLoadedNeuron(
          savedFileJson["neuronStyles"], mapTranslateLoadKeys);
    }

    neuronSize = controller.nodes.length - 2;
    neuronsKey = List<UniqueKey>.from(tempNeuronsKey);

    initNativeC(true);
    // print(savedFileJson["a"]);
    print("mapContactsNeuron");
    print(mapContactsNeuron);
    rawPos = [];
    for (InfiniteCanvasNode node in controller.nodes) {
      Offset position = controller.toLocal(node.offset);
      rawPos.add(position);
    }

    // aBufView = Float64List.fromList(savedFileJson["a"].map((v)=>v as double).toList());
    // if (savedFileJson["aDesignArray"] != null) {
    Float64List aBufList =
        Float64List.fromList(List<double>.from(savedFileJson["a"]));
    Float64List bBufList =
        Float64List.fromList(List<double>.from(savedFileJson["b"]));
    Int16List cBufList = Int16List.fromList(List<int>.from(savedFileJson["c"]));
    Int16List dBufList = Int16List.fromList(List<int>.from(savedFileJson["d"]));

    List<String> neuronKeys = neuronTypes.keys.toList();
    print("neuronTypes.length");
    print(neuronTypes.length);
    print(aBufList.length);
    int n = neuronKeys.length;
    aDesignArray = {};
    bDesignArray = {};
    cDesignArray = {};
    dDesignArray = {};
    for (int i = 0; i < n; i++) {
      String key = neuronKeys[i];
      aDesignArray[key] = aBufList[i];
      bDesignArray[key] = bBufList[i];
      cDesignArray[key] = cBufList[i];
      dDesignArray[key] = dBufList[i];
    }

    try {
      Int16List delayBufList =
          Int16List.fromList(List<int>.from(savedFileJson["mapDelayNeuron"]));
      Int16List rhytmicBufList =
          Int16List.fromList(List<int>.from(savedFileJson["mapRhytmicNeuron"]));
      Int16List countingBufList = Int16List.fromList(
          List<int>.from(savedFileJson["mapCountingNeuron"]));

      // print("delayBufList");
      // print(delayBufList);
      // print(rhytmicBufList);
      // print(countingBufList);
      // print("delayBufList");
      // print(delayBufList);
      // print(rhytmicBufList);
      // print(countingBufList);
      mapDelayNeuronList = List.generate(n, (index) => -1);
      mapRhytmicNeuronList = List.generate(n, (index) => -1);
      mapCountingNeuronList = List.generate(n, (index) => -1);
      for (int i = 0; i < n; i++) {
        mapDelayNeuronList[i] = delayBufList[i];
        mapRhytmicNeuronList[i] = rhytmicBufList[i];
        mapCountingNeuronList[i] = countingBufList[i];
      }
      print(mapDelayNeuronBufView);
    } catch (err) {
      print("err");
      print(err);
    }

    await Future.delayed(const Duration(milliseconds: 370), () {
      try {
        windowManager.setSize(Size(tempWidth, tempHeight));
      } catch (err) {
        print("windowmanager error");
        print(err);
      }
    });

    // }
    // aDesignArray = List<double>.from(savedFileJson["a"]);
    // bDesignArray = List<double>.from(savedFileJson["b"]);
    // cDesignArray = List<int>.from(savedFileJson["c"]);
    // dDesignArray = List<int>.from(savedFileJson["d"]);
    // iBufView = Float64List.fromList(List<double>.from(savedFileJson["i"]));
    // wBufView = Float64List.fromList(List<double>.from(savedFileJson["w"]));

    // print("Loaded Neuron Type : ");
    // print(neuronTypes);
  }

  void setCirclesZoom(double scale, List<Offset> pos) {
    // squareActiveCirclesPainter.forEach((SingleSquare square) {
    //   square.zoomScale = scale;
    // });
    // squareInactiveCirclesPainter.forEach((SingleSquare square) {
    //   square.zoomScale = scale;
    // });

    int len = neuronActiveCircles.length;
    for (int i = 0; i < len; i++) {
      neuronActiveCirclesPainter[i].zoomScale = scale;
      neuronInactiveCirclesPainter[i].zoomScale = scale;
    }

    protoNeuron.generateCircle(neuronSize, pos, neuronTypes.values.toList());
    len = protoNeuron.circles.length;
    for (int i = 0; i < len; i++) {
      SingleNeuron circle = protoNeuron.circles[i];
      circle.centerPos = pos[allNeuronStartIdx + i];
    }

    // print("scale");
    // print(scale);
    // print("circle");
    // print(protoNeuron.circles.last.centerPos);

    setState(() {});
  }

  void transformNeuronPositionWrapper() {
    MatrixDecomposedValues matrixValues =
        MatrixGestureDetector.decomposeToValues(controller.transform.value);

    if (matrixValues.scale > 1 && prevTransformScale != matrixValues.scale) {
      prevTransformScale = matrixValues.scale;
      transformNeuronPosition(matrixValues.scale);
    } else if (matrixValues.scale < 1 &&
        prevTransformScale != matrixValues.scale) {
      prevTransformScale = matrixValues.scale;
      transformNeuronPosition(matrixValues.scale);
    } else {
      if (matrixValues.scale < 0.86 || matrixValues.scale > 2.7) {
        debouncerSnapNeuron.run(() {
          transformNeuronPosition(matrixValues.scale);
        });
      }
    }
  }

  void transformNeuronPosition(scale) {
    if (scale == 1) {
      List<Offset> pos = rawPos;
      // controller.zoomReset();
      controller.scale = 1;

      debouncerSnapNeuron.run(() {
        for (InfiniteCanvasNode node in controller.nodes) {
          pos.add(controller.toLocal(node.offset));
        }

        // print("pos");
        // print(pos);

        setCirclesZoom(controller.scale, pos);
      });
    } else {
      // controller.zoomReset();
      // if (scale < 0.85) scale = 0.85;
      // controller.zoom(scale);
      controller.scale = scale;
      MatrixDecomposedValues matrixValues =
          MatrixGestureDetector.decomposeToValues(controller.transform.value);
      // controller.scale = 1.5;
      controller.scale = matrixValues.scale;
      List<Offset> pos = [];
      List<Offset> rawDelta = [];
      int idx = 0;
      double gap = -(10 * matrixValues.scale - 10);
      // double gap = (0 * matrixValues.scale);
      Offset space = Offset(gap, gap);

      // Future.delayed(const Duration(milliseconds: 10), () {
      debouncerSnapNeuron.run(() {
        for (InfiniteCanvasNode node in controller.nodes) {
          Offset position = controller.toLocal(node.offset);
          Offset rawPosition = rawPos[idx];
          Offset delta = (position - rawPosition) * matrixValues.scale;
          delta = delta + space;

          pos.add(rawPosition - delta);
          rawDelta.add(delta); // inverse it
          idx++;

          // print("--------" + idx.toString());
          // print(controller.toLocal(node.offset));
          // print(rawPosition);
          // print(rawPosition - delta);
          // print(rawDelta);

          // pos.add(Offset(position.dx, position.dy));
          // pos.add(node.offset);
        }
        // print("======= controller.toLocal(node.offset) 1.5");
        // print(pos.last);
        // print(rawPos.last);

        setCirclesZoom(matrixValues.scale, pos);
      });
      // protoNeuron.generateCircle(neuronSize, pos, neuronTypes);
    }
  }

  void transformNeuronListener() {
    if (!isPlayingMenu) return;
    MatrixDecomposedValues matrixValues =
        MatrixGestureDetector.decomposeToValues(controller.transform.value);

    if (matrixValues.scale > 1 && prevTransformScale != matrixValues.scale) {
      prevTransformScale = matrixValues.scale;
      // transformNeuronPosition(matrixValues.scale);
      debouncerSnapNeuron.run(() {
        transformNeuronPosition(matrixValues.scale);
      });
    } else if (matrixValues.scale < 1 &&
        prevTransformScale != matrixValues.scale) {
      prevTransformScale = matrixValues.scale;
      // debouncerSnapNeuron.run(() {
      //   transformNeuronPosition(matrixValues.scale);
      // });

      transformNeuronPosition(matrixValues.scale);
    } else {
      if (matrixValues.scale < 0.86 || matrixValues.scale > 2.7) {
        debouncerSnapNeuron.run(() {
          transformNeuronPosition(matrixValues.scale);
        });
      }
    }
  }

  Map<String, String> translateLoadedNeuron(Map<String, dynamic> targetMap,
      Map<String, String> mapTranslateLoadKeys) {
    Map<String, String> transformedMap = {};
    print("mapTranslateLoadKeys");
    print(mapTranslateLoadKeys);
    targetMap.forEach((key, value) {
      // print("loaded Neuron");
      // print(key);
      String translatedKey = mapTranslateLoadKeys[key]!;
      transformedMap[translatedKey] = value;
    });
    return transformedMap;
  }

  Map<String, dynamic> translateLoadedMap(Map<String, dynamic> targetMap,
      Map<String, String> mapTranslateLoadKeys) {
    // print("mapTranslateLoadKeys");
    // print(mapTranslateLoadKeys);
    Map<String, dynamic> transformedMap = {};
    targetMap.forEach((key, value) {
      // print("key");
      // print(key);
      List<String> arr = key.split("_");

      String translatedKey0 = mapTranslateLoadKeys[arr[0]]!;
      String translatedKey1 = mapTranslateLoadKeys[arr[1]]!;
      String combineTranslatedKey = "${translatedKey0}_$translatedKey1";
      // print(combineTranslatedKey);
      transformedMap[combineTranslatedKey] = value;
    });
    return transformedMap;
  }

  void selectEdgeMenuType() {
    // isNeuronMenu = false;
    isSynapseMenu = false;
    isCameraMenu = false;
    isDistanceMenu = false;
    isMotorMenu = false;
    isSpeakerMenu = false;
    isMicrophoneMenu = false;
    isLedMenu = false;

    if (isPlayingMenu) {
      setState(() {});
      return;
    }

    InfiniteCanvasNode nodeFrom = findNeuronByKey(controller.edgeSelected.from);
    InfiniteCanvasNode nodeTo = findNeuronByKey(controller.edgeSelected.to);

    if (nodeFrom == nodeLeftEyeSensor) {
      isCameraMenu = true;
      activeCameraType = "Left Eye Visual Trigger";

      // mapSensoryNeuron["${lastCreatedEdge.from}_${lastCreatedEdge.to}"] = value;
      if (mapSensoryNeuron["${nodeFrom.id}_${nodeTo.id}"] != null) {
        cameraMenuType =
            cameraMenuTypes[mapSensoryNeuron["${nodeFrom.id}_${nodeTo.id}"]];
      }
    } else if (nodeFrom == nodeRightEyeSensor) {
      isCameraMenu = true;
      activeCameraType = "Right Eye Visual Trigger";
      if (mapSensoryNeuron["${nodeFrom.id}_${nodeTo.id}"] != null) {
        cameraMenuType =
            cameraMenuTypes[mapSensoryNeuron["${nodeFrom.id}_${nodeTo.id}"]];
      }
    } else if (nodeFrom == nodeDistanceSensor) {
      isDistanceMenu = true;
      if (mapDistanceNeuron["${nodeFrom.id}_${nodeTo.id}"] != null) {
        distanceMenuType =
            distanceMenuTypes[mapDistanceNeuron["${nodeFrom.id}_${nodeTo.id}"]];
        selectedDistanceIdx = distanceMenuTypes.indexOf(distanceMenuType);
      }
      if (mapDistanceLimitNeuron["${nodeFrom.id}_${nodeTo.id}"] != null) {
        String temp = mapDistanceLimitNeuron["${nodeFrom.id}_${nodeTo.id}"];
        List<String> arr = temp.split("_@_");
        int toIdx = neuronTypes.keys.toList().indexOf(nodeTo.id.toString());

        distanceMinLimitBufView[toIdx] = int.parse(arr[0]);
        distanceMaxLimitBufView[toIdx] = int.parse(arr[1]);
        txtDistanceMinController.text = arr[0];
        txtDistanceMaxController.text = arr[1];
      } else {
        selectedDistanceIdx = 0;
        txtDistanceMinController.text = "1";
        txtDistanceMaxController.text = "8";
      }
    } else if (nodeTo == nodeLeftMotorForwardSensor ||
        nodeTo == nodeLeftMotorBackwardSensor ||
        nodeTo == nodeRightMotorForwardSensor ||
        nodeTo == nodeRightMotorBackwardSensor) {
      isMotorMenu = true;
      if (mapContactsNeuron["${nodeFrom.id}_${nodeTo.id}"] != null) {
        sldSynapticWeight =
            mapContactsNeuron["${nodeFrom.id}_${nodeTo.id}"].roundToDouble();
        tecSynapticWeight.text = sldSynapticWeight.round().toString();
      }
    } else if (nodeTo == nodeSpeakerSensor) {
      isSpeakerMenu = true;
      if (mapSpeakerNeuron["${nodeFrom.id}_${nodeTo.id}"] != null) {
        sldFrequencyWeight =
            mapSpeakerNeuron["${nodeFrom.id}_${nodeTo.id}"].roundToDouble();
        tecFrequencyWeight.text = sldFrequencyWeight.round().toString();
      }
    } else if (nodeTo == nodeMicrophoneSensor) {
      isMicrophoneMenu = true;
      // isMicrophoneMenu
      if (mapMicrophoneNeuron["${nodeFrom.id}_${nodeTo.id}"] != null) {
        sldFrequencyWeight =
            mapMicrophoneNeuron["${nodeFrom.id}_${nodeTo.id}"].roundToDouble();
        tecFrequencyWeight.text = sldFrequencyWeight.round().toString();
      }
    } else if (nodeTo == nodeRedLed ||
        nodeTo == nodeGreenLed ||
        nodeTo == nodeBlueLed) {
      isLedMenu = true;
      // print('mapLedNeuron["${nodeFrom.id}_${nodeTo.id}"]');
      // print(mapLedNeuron["${nodeFrom.id}_${nodeTo.id}"]);
      if (mapLedNeuron["${nodeFrom.id}_${nodeTo.id}"] != null) {
        sldSynapticWeight =
            mapLedNeuron["${nodeFrom.id}_${nodeTo.id}"].roundToDouble();
        // sldSynapticWeight = 70;
        tecSynapticWeight.text = sldSynapticWeight.round().toString();
      } else {
        sldSynapticWeight = 0;
      }
      print("POSITION : ${nodeFrom.id}_${nodeTo.id}");
      print(mapLedNeuronPosition);
      print(isActiveLeds);

      if (mapLedNeuronPosition["${nodeFrom.id}_${nodeTo.id}"] != null) {
        isActiveLeds[0] =
            mapLedNeuronPosition["${nodeFrom.id}_${nodeTo.id}"][0];
        isActiveLeds[1] =
            mapLedNeuronPosition["${nodeFrom.id}_${nodeTo.id}"][1];
        isActiveLeds[2] =
            mapLedNeuronPosition["${nodeFrom.id}_${nodeTo.id}"][2];
        isActiveLeds[3] =
            mapLedNeuronPosition["${nodeFrom.id}_${nodeTo.id}"][3];
      } else {
        isActiveLeds = ["0", "0", "0", "0"];
      }
    } else {
      isSynapseMenu = true;
      if (mapConnectome["${nodeFrom.id}_${nodeTo.id}"] != null) {
        sldSynapticWeight =
            mapConnectome["${nodeFrom.id}_${nodeTo.id}"].roundToDouble();
        tecSynapticWeight.text = sldSynapticWeight.round().toString();
      }
    }
    setState(() {});
  }

  void linkSpeakerConnection(String value) {
    if (value.trim().isEmpty) return;
    double val = double.parse(value);
    if (val > 4978) {
      val = 4978;
    }
    if (val < 31) {
      val = 31;
    }

    final lastCreatedEdge = controller.edgeSelected;
    final neuronFrom = findNeuronByKey(lastCreatedEdge.from);
    final neuronTo = findNeuronByKey(lastCreatedEdge.to);
    // mapConnectome["${lastCreatedEdge.from}_${lastCreatedEdge.to}"] = val;
    mapSpeakerNeuron["${neuronFrom.id}_${neuronTo.id}"] = val;
    // print("${neuronFrom.id}_${neuronTo.id}");
  }

  void linkMicrophoneConnection(String value) {
    if (value.trim().isEmpty) return;
    double val = double.parse(value);
    if (val > 5000) {
      val = 5000;
    }
    if (val < 0) {
      val = 0;
    }

    final lastCreatedEdge = controller.edgeSelected;
    final neuronFrom = findNeuronByKey(lastCreatedEdge.from);
    final neuronTo = findNeuronByKey(lastCreatedEdge.to);
    // mapConnectome["${lastCreatedEdge.from}_${lastCreatedEdge.to}"] = val;
    mapMicrophoneNeuron["${neuronFrom.id}_${neuronTo.id}"] = val;
    // print("${neuronFrom.id}_${neuronTo.id}");
  }

  void resetMouse() {
    controller.deselectAll(true);
    controller.deselectAll();
    controller.mousePosition = Offset.zero;

    controller.marqueeStart = null;
    controller.marqueeEnd = null;
    controller.linkStart = null;
    controller.linkEnd = null;
    controller.mouseDown = false;
    controller.notifyMousePosition();
  }

  void clearUIMenu() {
    isDrawTail = false;
    isDeleteMenu = false;

    isNeuronMenu = false;
    isSynapseMenu = false;
    isCameraMenu = false;
    isDistanceMenu = false;
    isMotorMenu = false;
    isSpeakerMenu = false;
    isMicrophoneMenu = false;
    isLedMenu = false;
  }

  void resizeIzhikevichParameters(int neuronSize) {
    aBufView = aBuf.asTypedList(neuronSize);
    bBufView = bBuf.asTypedList(neuronSize);
    cBufView = cBuf.asTypedList(neuronSize);
    dBufView = dBuf.asTypedList(neuronSize);
  }

  List<String> empty = [];
  double multiplierConstant = 0.78;
  int robotMessageDelay = 75;
  List<int> infoStatusMax = [];
  List<List<int>> diodeStatusMax = [];
  List<int> periodicNeuronSpikingFlags = [];
  void processRobotMessages() {
    Future.delayed(Duration(milliseconds: robotMessageDelay), () {
      infoStatusMax = [0, 0, 0, 0, 0, 0, 0];
      periodicNeuronSpikingFlags =
          List<int>.generate(neuronSize - normalNeuronStartIdx, (_) {
        return 0;
      });
      diodeStatusMax = [
        [0, 0, 0],
        [0, 0, 0],
        [0, 0, 0],
        [0, 0, 0],
      ];
      int diodeCounter = 0;
      Map<int, int> leftAttentionValue = {};
      Map<int, int> rightAttentionValue = {};
      double leftSumValue = 0;
      double rightSumValue = 0;
      // print("processRobotMessages Delay");
      if (isPlayingMenu) {
        // print("processRobotMessages");
        int nowTime = DateTime.now().millisecondsSinceEpoch;
        // print("nowTime");
        // print(nowTime);
        if (nowTime - previousBufferTime >= robotMessageDelay) {
          previousBufferTime = nowTime;
        } else {
          // processRobotMessages();
          // return;
        }

        try {
          List<String> commands = commandList.toList();
          // print("commands.isNotEmpty");
          // print(commands);

          if (canCaptureData) {
            strTorqueDataBuff += strCommandList;
            if (strTorqueDataBuff != "") {
              prevStrTorqueDataBuff = strTorqueDataBuff;
            }
            if (captureSteps % 1 == 0) {
              int lenCommandData = strCommandList.length;
              int lenSerialData = strSerialDataBuff.length;
              int lenTorqueData = strTorqueDataBuff.length;
              Map<String, dynamic> map = {};
              map["frameData"] = Uint8List.fromList(DesignBrainPage.prevFrame);
              map["path"] = captureDirectory.path;
              map["serial_data"] = strSerialDataBuff;
              map["torque_data"] = strTorqueDataBuff == ""
                  ? prevStrTorqueDataBuff
                  : strTorqueDataBuff;
              flagCommandDataLength = lenCommandData;
              flagSerialDataLength = lenSerialData;
              flagTorqueDataLength = lenTorqueData;

              dataCaptureSave(map);

              // mutexCommand.protectWrite(() async {
              //   strCommandList = strCommandList.substring(lenCommandData);
              //   return "";
              // });
              // mutexDistance.protectWrite(() async {
              //   strSerialDataBuff = strSerialDataBuff.substring(lenSerialData);
              //   return "";
              // });

              // mutexTorque.protectWrite(() async {
              //   strTorqueDataBuff = strTorqueDataBuff.substring(lenTorqueData);
              //   return "";
              // });

              captureSteps = 0;
            }
            captureSteps++;
          }
          if (commands.isNotEmpty) {
            // print(commands.length);
            int len = commands.length;
            int validValueCounter = 0;
            for (int i = 0; i < len; i++) {
              List<String> arr = commands[i].split(";");
              int n = arr.length;
              for (int j = 0; j < n; j++) {
                List<String> arrStr = arr[j].split(":");
                if (arrStr[0] == "l") {
                  int val = int.parse(arrStr[1]);
                  if (val.abs() >= 5) {
                    validValueCounter++;
                    leftSumValue += val;
                  }
                  if (leftAttentionValue[val] == null) {
                    leftAttentionValue[val] = 1;
                  } else {
                    leftAttentionValue[val] = (leftAttentionValue[val])! + 1;
                  }

                  // if (infoStatusMax[0].abs() >= val.abs()) {
                  //   infoStatusMax[0] =
                  //       infoStatusMax[0].sign * infoStatusMax[0].abs();
                  // } else {
                  //   infoStatusMax[0] = val.sign * val.abs();
                  // }
                } else if (arrStr[0] == "r") {
                  int val = int.parse(arrStr[1]);
                  if (val.abs() >= 5) {
                    validValueCounter++;
                    rightSumValue += val;
                  }
                  if (rightAttentionValue[val] == null) {
                    rightAttentionValue[val] = 1;
                  } else {
                    rightAttentionValue[val] = (rightAttentionValue[val])! + 1;
                  }

                  // if (infoStatusMax[1].abs() >= val.abs()) {
                  //   infoStatusMax[1] =
                  //       infoStatusMax[1].sign * infoStatusMax[1].abs();
                  // } else {
                  //   infoStatusMax[1] = val.sign * val.abs();
                  // }
                } else if (arrStr[0] == "s") {
                  infoStatusMax[2] =
                      max(infoStatusMax[2], int.parse(arrStr[1]));
                } else if (arrStr[0] == "n") {
                  List<String> spikingFlags = arrStr[1].split("|");
                  // print("spikingFlags");
                  // print(spikingFlags);

                  for (int k = 0; k < spikingFlags.length; k++) {
                    periodicNeuronSpikingFlags[k] = max(
                        periodicNeuronSpikingFlags[k],
                        int.parse(spikingFlags[k]));
                  }
                } else if (arrStr[0] == "d") {
                  List<String> diodeSplit = arrStr[1].split(",");
                  diodeCounter = int.parse(diodeSplit[0]);
                  // diodeCounter %= 4;l
                  // if (diodeCounter == 2) {
                  // print("diodeSplit");
                  // print(diodeSplit);
                  // }

                  diodeStatusMax[diodeCounter][0] = max(
                      diodeStatusMax[diodeCounter][0],
                      int.parse(diodeSplit[1]));
                  diodeStatusMax[diodeCounter][1] = max(
                      diodeStatusMax[diodeCounter][1],
                      int.parse(diodeSplit[2]));
                  diodeStatusMax[diodeCounter][2] = max(
                      diodeStatusMax[diodeCounter][2],
                      int.parse(diodeSplit[3]));
                }
              }
            }
            // reconstruct motor message
            // message = "l:" + std::to_string(l_torque * l_dir) + ";r:" + std::to_string(r_torque * r_dir) + ";s:" + std::to_string(speaker_tone) + ";";
            String diodeString = "";

            for (int c = 0; c < 4; c++) {
              // [l:0, r:0, s:0, n:0|0|1, d:0,0,0,127, d:1,0,0,127, d:2,0,0,127, d:3,0,0,127, ]
              diodeString =
                  "${diodeString}d:$c,${diodeStatusMax[c][0]},${diodeStatusMax[c][1]},${diodeStatusMax[c][2]};";
            }
            // print("diodeString");
            // print(diodeString);
            // print("infoStatusMax");
            // print(infoStatusMax);

            /*
            String msg =
                "l:${infoStatusMax[0]};r:${infoStatusMax[1]};s:${infoStatusMax[2]};$diodeString";
            */
// /*
            int avgLeft = 0;
            int avgRight = 0;
            String msg = "";
            if (leftAttentionValue[0] == len) {
              avgLeft = 0;
            } else {
              leftSumValue = leftSumValue / validValueCounter;
              double calculatedValue = leftSumValue.sign *
                  ((leftSumValue.abs() - 250) * multiplierConstant + 250);
              // print("calculatedValue left");
              // print(calculatedValue);
              avgLeft = (calculatedValue).floor();
            }
            if (rightAttentionValue[0] == len) {
              avgRight = 0;
            } else {
              rightSumValue = rightSumValue / validValueCounter;
              double calculatedValue = rightSumValue.sign *
                  ((rightSumValue.abs() - 250) * multiplierConstant + 250);
              // print("calculatedValue right");
              // print(calculatedValue);
              avgRight = (calculatedValue).floor();
            }
            // print("avgLeft");
            // print(len);
            // print(avgLeft);
            // print(avgRight);
            // print(validValueCounter);
            // print("===============");
            // avgLeft = -60;
            // avgRight = 60;
            msg =
                "l:${avgLeft};r:${avgRight};s:${infoStatusMax[2]};$diodeString";
// */
            if (isIsolateWritePortInitialized) {
              // print("msg");
              // print(msg);
              // print(infoStatusMax);
              // print(periodicNeuronSpikingFlags);
              _DesignBrainPageState.isolateWritePort.send(msg);
            }

            try {
              for (int i = normalNeuronStartIdx; i < neuronSize; i++) {
                int neuronIndex = i;
                if (periodicNeuronSpikingFlags[i - normalNeuronStartIdx] == 1) {
                  protoNeuron.circles[neuronIndex].isSpiking = 1;
                  neuronSpikeFlags[neuronIndex].value = Random().nextInt(10000);
                } else {
                  try {
                    protoNeuron.circles[neuronIndex].isSpiking = -1;
                    neuronSpikeFlags[neuronIndex].value =
                        Random().nextInt(10000);
                  } catch (err) {
                    print(err);
                  }
                }
              }
            } catch (err) {
              print("err2");
              print(err);
            }

            /* CHANGED : DUE TO GET MAXIMUM VALUE
            if (commands.length > 20) {
              List<String> lastTwenty = commands
                  .getRange(commands.length - 20, commands.length)
                  .toList();
              if (isIsolateWritePortInitialized &&
                  isSimulatingBrain &&
                  isPlayingMenu) {
                // isPlayingMenu active if the simulation active
                _DesignBrainPageState.isolateWritePort.send(lastTwenty.join());
              }
            } else {
              if (isIsolateWritePortInitialized &&
                  isSimulatingBrain &&
                  isPlayingMenu) {
                _DesignBrainPageState.isolateWritePort.send(commands.join());
              }
            }
            */
          }
        } catch (err) {
          print("error Robot message");
          print(err);
        }
      }
      commandList.clear();
      // print("command list clear");

      strCommandList = "";
      strSerialDataBuff = "";
      strTorqueDataBuff = "";

      // mutex.protectWrite(() async {
      //   commandList.clear();
      //   return empty;
      // });
      processRobotMessages();
    });
  }

  void countEyeSensorConnection() {
    aiVisualTypes = 0;
    imageVisualTypes = 0;
    for (String key in mapSensoryNeuron.keys) {
      if (mapSensoryNeuron[key] >= 7) {
        aiVisualTypes++;
      } else {
        imageVisualTypes++;
      }
    }
    print("mapSensoryNeuron");
    print(mapSensoryNeuron);
    print(aiVisualTypes);
    print(imageVisualTypes);
  }

  void refillMapNeuronType() {
    mapNeuronTypeBufView.fillRange(0, neuronSize, -1);
  }

  bool containImage(Rect location, bool isRight) {
    // double spaceDeterminer = 80; // 320 x 240
    int centerX = 160; // 320/2
    if (isRight) {
      // print("location.left - centerX");
      // print(centerX - location.left);
      // print(location.right - centerX);

      if (centerX - location.left < location.right - centerX) {
        // right eye
        return true;
      } else if (centerX - location.left > location.right - centerX) {
        // left eye
        return false;
      }
    } else {
      if (centerX - location.left > location.right - centerX) {
        // left eye
        return true;
      } else if (centerX - location.left < location.right - centerX) {
        // right eye
        return false;
      }
    }
    return false;
  }

  void updateSyntheticConnection(
      LocalKey from, LocalKey to, double sldSynapticWeight) {
    int fromIdx = neuronTypes.keys.toList().indexOf(axonFrom.toString());
    int toIdx = neuronTypes.keys.toList().indexOf(axonTo.toString());
    for (Connection con in syntheticConnections) {
      if (con.neuronIndex1 == from && con.neuronIndex2 == to) {
        con.connectionStrength = sldSynapticWeight;
      }
    }
  }

/*
  Overlay with sensors first, then if it is not containing, check the background, and if it is not containing change to -1, if containing stay.
 */
  String activeBrainComponent = "assets/bg/BrainDrawings/BrainSoloBlack.svg";
  String defaultBg = "assets/bg/BrainDrawings/BrainFullBlack.svg";
  String greyBg = "assets/bg/BrainDrawings/BrainFullGrey.svg";
  String noActiveComponent = "assets/bg/BrainDrawings/No_image.svg";
  List<String> activeComponents = [
    "assets/bg/BrainDrawings/DistanceBlack.svg",
    "assets/bg/BrainDrawings/CameraBlack.svg",
    "assets/bg/BrainDrawings/No_image.svg",
    "assets/bg/BrainDrawings/LeftMotorBlack.svg",
    "assets/bg/BrainDrawings/RightMotorBlack.svg",
    "assets/bg/BrainDrawings/LeftMotorBlack.svg",
    "assets/bg/BrainDrawings/RightMotorBlack.svg",
    "assets/bg/BrainDrawings/MicBlack.svg",
    "assets/bg/BrainDrawings/SpeakerBlack.svg",
    "assets/bg/BrainDrawings/SpeakerBlack.svg",
  ];

  List<Map<String, dynamic>> dropTargeInformations = [
    {
      "left": 150.0,
      "top": 5.0,
      "offset": const Offset(300, 170),
      "size": const Size(95, 125),
      "zoneArea": [-1, -1],
      "xDiff": 18,
      "yDiff": 4,
    }, // distance
    {
      "left": 350.0,
      "top": 0.0,
      "offset": const Offset(310, 140),
      "size": const Size(175, 100),
      "zoneArea": [0, -1],
      "xDiff": 216,
      "yDiff": 5,
    }, // left eye sensor
    {
      "left": 0.0,
      "top": 0.0,
      "offset": const Offset(0, 0),
      "size": const Size(0, 0),
      "zoneArea": [0, 0],
      "xDiff": 0,
      "yDiff": 0,
    }, // right eye sensor
    {
      "left": 140.0,
      "top": 200.0,
      "offset": const Offset(240, 220),
      "size": const Size(65, 125),
      "zoneArea": [-1, 0],
      "xDiff": 0,
      "yDiff": 200,
    }, // left motor UP
    {
      "left": 665.0,
      "top": 200.0,
      "offset": const Offset(525, 240),
      "size": const Size(65, 125),
      "zoneArea": [1, 0],
      "xDiff": 529,
      "yDiff": 200,
    }, // right motor UP
    {
      "left": 140.0,
      "top": 320.0,
      "offset": const Offset(255, 370),
      "size": const Size(65, 125),
      "zoneArea": [-1, 1],
      "xDiff": 0,
      "yDiff": 322,
    }, // left motor Down
    {
      "left": 655.0,
      "top": 320.0,
      "offset": const Offset(525, 340),
      "size": const Size(65, 125),
      "zoneArea": [1, 1],
      "xDiff": 521,
      "yDiff": 323,
    }, // right motor Down
    {
      "left": 590.0,
      "top": 0.0,
      "offset": const Offset(470, 240),
      "size": const Size(130, 160),
      "zoneArea": [1, -1],
      "xDiff": 460,
      "yDiff": 7,
    }, // microphone
    {
      "left": 580.0,
      "top": 460.0,
      "offset": const Offset(470, 410),
      "size": const Size(145, 140),
      "zoneArea": [1, 2],
      "xDiff": 440,
      "yDiff": 460,
    }, // Speaker

// // left: 540,
// // top: 460,
// // size: const Size(145, 140), // Adjust size as needed
  ];

  List<GeneralSensorPainter> listPainters = [];

  Size brainSize = const Size(490, 480);
  Offset brainPosition = const Offset(190, 50);
  Size brainDiff = const Size(56, 55);
  late GeneralSensorPainter coreBrainPainter;
  List<InfiniteDropTarget> getDragTargets() {
    coreBrainPainter = GeneralSensorPainter(
      polygonPath: sensorPolygonPaths[9],
      positionDiff: [
        brainDiff.width,
        brainDiff.height,
      ],
    );
    InfiniteDropTarget brainTarget = InfiniteDropTarget(
      key: UniqueKey(),
      // offset: const Offset(200, 90),
      offset: Offset(brainPosition.dx, brainPosition.dy),
      size: brainSize,
      // color: Colors.green,
      child: Positioned(
        top: brainPosition.dy,
        left: brainPosition.dx,
        child: DragTarget(
            // hitTestBehavior: HitTestBehavior.opaque,
            onMove: (dragDetail) {
          Offset localAreaOffset = controller
              .toLocal(Offset(dragDetail.offset.dx, dragDetail.offset.dy));

          GeneralSensorPainter painter = (coreBrainPainter);
          Offset containOffset = localAreaOffset.translate(
              -brainPosition.dx + 45 / controller.getScale(),
              -brainPosition.dy + 45 / controller.getScale());
          // localAreaOffset.translate(-painter.xDiff, -painter.yDiff);
          bool isContaining = painter.path.contains(containOffset);
          print("------localAreaOffset core brain");
          print(containOffset);
          print(isContaining);
          if (isContaining) {
            brainContainedIdx = 0;

            if (mapBg["activeComponent"] == activeBrainComponent) {
            } else {
              mapBg["activeComponent"] = activeBrainComponent;
              Future.delayed(const Duration(milliseconds: 127), () {
                setState(() {});
              });
            }
          } else {
            isBrainTargetOverlayTop = -1;
            brainContainedIdx = -1;

            if (mapBg["activeComponent"] == noActiveComponent) {
            } else {
              mapBg["activeComponent"] = noActiveComponent;
              Future.delayed(const Duration(milliseconds: 127), () {
                setState(() {});
              });
            }
          }
        }, onWillAcceptWithDetails: (dragDetail) {
          // print("onWillAcceptWithDetails brain" +
          //     controller.toLocal(dragDetail.offset).toString());
          // mapBg["activeBg"] = greyBg;
          // mapBg["activeComponent"] = activeBrainComponent;
          Future.delayed(const Duration(milliseconds: 127), () {
            setState(() {});
          });
          if (dragDetail.data as int < 2) {
            print("containedIdx NOT containing brain");
            print(brainContainedIdx);

            return true;
          } else {
            print("return false");
            return false;
          }
        }, onAcceptWithDetails: (value) {
          clearUIMenu();
          if (brainContainedIdx != 0) return;

          // print("onAcceptWithDetails" +
          //     controller.toLocal(value.offset).toString());
          mapBg["activeBg"] = defaultBg;
          mapBg["activeComponent"] = noActiveComponent;

          isCreatePoint = true;
          if (neuronSize + 1 >= maxPosBuffer) {
            return;
          }
          neuronSize++;
          UniqueKey newNodeKey = UniqueKey();
          neuronsKey.add(newNodeKey);
          mapDelayNeuronList.add(-1);
          mapRhytmicNeuronList.add(-1);
          mapCountingNeuronList.add(-1);
          // neuronTypes[newNodeKey.toString()] = (randomNeuronType());
          neuronTypes[newNodeKey.toString()] = "Quiet";
          if (value.data == 0) {
            neuronStyles[newNodeKey.toString()] = "Excitatory";
          } else {
            neuronStyles[newNodeKey.toString()] = "Inhibitory";
          }

          aDesignArray[newNodeKey.toString()] = sldAWeight;
          bDesignArray[newNodeKey.toString()] = sldBWeight;
          cDesignArray[newNodeKey.toString()] = sldCWeight;
          dDesignArray[newNodeKey.toString()] = sldDWeight;

          // Offset canvasOffset = controller.toLocal(controller.getOffset());
          final Size containerSize = Size(
              windowWidth, windowHeight); // Replace with your container size

          Size initialImageSize = const Size(600, 600);
          final fittedSizes =
              applyBoxFit(BoxFit.contain, initialImageSize, containerSize);

          Offset mouseOffset = controller
              .toLocal(Offset(value.offset.dx + 30, value.offset.dy + 35));

          print("canvasOffset.dx");
          print(value.offset.dx.toString() + " _ " + mouseOffset.dx.toString());
          SyntheticNeuron syntheticNeuron = SyntheticNeuron(
              isActive: false, isIO: false, circleRadius: neuronDrawSize / 2);
          InfiniteCanvasNode newNode = InfiniteCanvasNode(
            key: neuronsKey[neuronsKey.length - 1],
            value: neuronSize - 1,
            allowMove: false,
            allowResize: false,
            offset: Offset(mouseOffset.dx + 0, mouseOffset.dy + 0),
            size: Size(neuronDrawSize, neuronDrawSize),
            child: CustomPaint(
              isComplex: true,
              willChange: true,
              painter: syntheticNeuron,
            ),
            // child: Container(width: 0,height:0, color:Colors.green),
          );
          newNode.syntheticNeuron = syntheticNeuron;
          syntheticNeuron.node = newNode;
          syntheticNeuron.setupDrawingNeuron();
          syntheticNeuronList.add(syntheticNeuron);

          SyntheticNeuron rawSyntheticNeuron = SyntheticNeuron(
              // neuronKey: newNodeKey,
              isActive: false,
              isIO: false,
              circleRadius: neuronDrawSize / 2);
          rawSyntheticNeuron.node = newNode;
          rawSyntheticNeuron.copyDrawingNeuron(syntheticNeuron);
          rawSyntheticNeuronList.add(rawSyntheticNeuron);
          syntheticNeuron.rawSyntheticNeuron = rawSyntheticNeuron;

          controller.add(newNode);

          initNativeC(false);
          isBrainTargetOverlayTop = -1;
          containedIdx = -1;

          Future.delayed(const Duration(milliseconds: 100), () {
            controller.deselect(neuronsKey[neuronsKey.length - 1]);
            modeIdx = -1;
            controller.modeIdx = modeIdx;
            setState(() {});
          });
        }, onLeave: (value) {
          print("On Leave Drag Target");
          mapBg["activeComponent"] = noActiveComponent;

          // modeIdx = -1;
          Future.delayed(const Duration(milliseconds: 127), () {
            setState(() {});
          });
        }, builder: (ctx, candidates, rejects) {
          // return Container(
          //     width: brainSize.width,
          //     height: brainSize.height,
          //     color: Colors.transparent);
          return CustomPaint(
            size: brainSize, // Adjust size as needed
            painter: coreBrainPainter,
          );
        }),
      ),
    );
    List<InfiniteDropTarget> list = [];
    if (isBrainTargetOverlayTop == -1) {
      list.add(brainTarget);
    }
    int idx = 0;
    int len = sensoryNeurons.length;
    for (idx = 0; idx < len - 3; idx++) {
      InfiniteCanvasNode neuron = sensoryNeurons[idx];
      Map<String, dynamic> neuronInfo = dropTargeInformations[idx];

      listPainters.add(GeneralSensorPainter(
          polygonPath: sensorPolygonPaths[idx],
          positionDiff: [
            neuronInfo["xDiff"].toDouble(),
            neuronInfo["yDiff"].toDouble()
          ]));
      if (idx == 2) continue;
      int tempIdx = idx;

      list.add(
        InfiniteDropTarget(
            key: UniqueKey(),
            size: neuronInfo["size"],
            // offset: const Offset(0, 0),
            offset: Offset(neuronInfo["left"], neuronInfo["top"]),
            child: Positioned(
              top: neuronInfo["top"],
              left: neuronInfo["left"],
              child: DragTarget(
                  hitTestBehavior: HitTestBehavior.translucent,
                  onMove: (dragDetail) {
                    Offset localAreaOffset = controller.toLocal(
                        Offset(dragDetail.offset.dx, dragDetail.offset.dy));
                    // print("====dragDetail.offset");
                    // print(dragDetail.offset);
                    // print(localAreaOffset);
                    //   // print(controller.scale);
                    //   // print(controller
                    //   //     .toLocal(Offset(neuronInfo["left"], neuronInfo["top"])));
                    //   // print(controller.toLocal(Offset(
                    //   //     neuronInfo["left"] + neuronInfo["size"].width,
                    //   //     neuronInfo["size"].height)));
                    //   Offset localAreaOffset = controller.toLocal(Offset(
                    //       dragDetail.offset.dx - neuronInfo["left"],
                    //       dragDetail.offset.dy - neuronInfo["top"]));
                    //   print("====localAreaOffset");
                    //   print(localAreaOffset);

                    //   // Offset mousePositionOffset = controller.toLocal(
                    //   //     Offset(dragDetail.offset.dx + 35, dragDetail.offset.dy + 35));
                    //   // print("mousePositionOffset");
                    //   // print(mousePositionOffset);

                    //   // Offset positionDifference = controller
                    //   //     .toLocal(Offset(neuronInfo["left"], neuronInfo["top"]));
                    //   // print("positionDifference");
                    //   // print(positionDifference);

                    //   // print("Calculate Difference");
                    //   // print(mousePositionOffset - positionDifference);

                    //   // print("Calculate upfront");
                    //   // print(controller.toLocal(Offset(
                    //   //     dragDetail.offset.dx - neuronInfo["left"] + 35,
                    //   //     dragDetail.offset.dy - neuronInfo["top"] + 35)));

                    GeneralSensorPainter painter = (listPainters[tempIdx]);
                    Offset containOffset = localAreaOffset.translate(
                        -neuronInfo["left"] + 45 / controller.getScale(),
                        -neuronInfo["top"] + 45 / controller.getScale());
                    // localAreaOffset.translate(-painter.xDiff, -painter.yDiff);
                    bool isContaining = painter.path.contains(containOffset);
                    print("------localAreaOffset");
                    print(containOffset);
                    print(isContaining);

                    if (isContaining) {
                      containedIdx = tempIdx;
                      print("containedIdx containing");
                      print(containedIdx);

                      if (mapBg["activeComponent"] ==
                          activeComponents[tempIdx]) {
                      } else {
                        mapBg["activeComponent"] = activeComponents[tempIdx];
                        Future.delayed(const Duration(milliseconds: 127), () {
                          setState(() {});
                        });
                      }
                    } else {
                      isBrainTargetOverlayTop *= -1;
                      containedIdx = -1;
                      print("containedIdx NOT containing");
                      print(containedIdx);

                      if (mapBg["activeComponent"] == noActiveComponent) {
                        setState(() {});
                      } else {
                        mapBg["activeComponent"] = noActiveComponent;
                        Future.delayed(const Duration(milliseconds: 127), () {
                          setState(() {});
                        });
                      }
                    }
                  },
                  onWillAcceptWithDetails: (dragDetail) {
                    // return true;

                    // mapBg["activeBg"] = greyBg;
                    // mapBg["activeComponent"] = activeComponents[tempIdx];
                    // if (mapBg["activeComponent"] == activeComponents[tempIdx]) {
                    // } else {
                    //   mapBg["activeBg"] = greyBg;
                    //   mapBg["activeComponent"] = activeComponents[tempIdx];
                    //   Future.delayed(const Duration(milliseconds: 127), () {
                    //     setState(() {});
                    //   });
                    // }
                    print("containedIdx");
                    print(containedIdx);
                    print(tempIdx);

                    if (dragDetail.data as int < 2) {
                      // print("------Accept");
                      // print(activeComponents[tempIdx]);
                      return true;
                    } else {
                      return false;
                    }
                  },
                  onAcceptWithDetails: (value) {
                    clearUIMenu();
                    if (containedIdx != tempIdx) return;
                    // print("------Accept");
                    // print(value.data);
                    Offset neuronZonePosition =
                        getUniqueZone(centerZoneOffset, neuronInfo);
                    mapBg["activeComponent"] = noActiveComponent;
                    mapBg["activeBg"] = defaultBg;

                    print("onAcceptWithDetails" + value.data.toString());
                    isCreatePoint = true;
                    if (neuronSize + 1 >= maxPosBuffer) {
                      return;
                    }
                    neuronSize++;
                    UniqueKey newNodeKey = UniqueKey();
                    neuronsKey.add(newNodeKey);
                    mapDelayNeuronList.add(-1);
                    mapRhytmicNeuronList.add(-1);
                    mapCountingNeuronList.add(-1);
                    // neuronTypes[newNodeKey.toString()] = (randomNeuronType());
                    neuronTypes[newNodeKey.toString()] = "Quiet";
                    if (value.data == 0) {
                      neuronStyles[newNodeKey.toString()] = "Excitatory";
                    } else {
                      neuronStyles[newNodeKey.toString()] = "Inhibitory";
                    }

                    aDesignArray[newNodeKey.toString()] = sldAWeight;
                    bDesignArray[newNodeKey.toString()] = sldBWeight;
                    cDesignArray[newNodeKey.toString()] = sldCWeight;
                    dDesignArray[newNodeKey.toString()] = sldDWeight;

                    SyntheticNeuron syntheticNeuron = SyntheticNeuron(
                        isActive: false,
                        isIO: false,
                        circleRadius: neuronDrawSize / 2);
                    InfiniteCanvasNode newNode = InfiniteCanvasNode(
                      key: neuronsKey[neuronsKey.length - 1],
                      value: neuronSize - 1,
                      allowMove: false,
                      allowResize: false,
                      // offset: neuronInfo["offset"],
                      offset: neuronZonePosition,
                      size: Size(neuronDrawSize, neuronDrawSize),
                      child: CustomPaint(
                        isComplex: true,
                        willChange: true,
                        painter: syntheticNeuron,
                      ),
                      // child: Container(width: 0,height:0, color:Colors.green),
                    );
                    newNode.syntheticNeuron = syntheticNeuron;
                    syntheticNeuron.node = newNode;
                    syntheticNeuron.setupDrawingNeuron();
                    syntheticNeuronList.add(syntheticNeuron);

                    SyntheticNeuron rawSyntheticNeuron = SyntheticNeuron(
                        // neuronKey: newNodeKey,
                        isActive: false,
                        isIO: false,
                        circleRadius: neuronDrawSize / 2);
                    rawSyntheticNeuron.node = newNode;
                    rawSyntheticNeuron.copyDrawingNeuron(syntheticNeuron);
                    rawSyntheticNeuronList.add(rawSyntheticNeuron);
                    syntheticNeuron.rawSyntheticNeuron = rawSyntheticNeuron;

                    controller.add(newNode);
                    InfiniteCanvasNode nodeFrom = neuron;
                    InfiniteCanvasNode nodeTo = newNode;
                    if (tempIdx >= 3 && tempIdx <= 6) {
                      nodeFrom = newNode;
                      nodeTo = neuron;
                    } else if (tempIdx == 8) {
                      nodeFrom = newNode;
                      nodeTo = neuron;
                    }
                    InfiniteCanvasEdge edge = InfiniteCanvasEdge(
                      from: nodeFrom.key,
                      to: nodeTo.key,
                    );
                    String connectionKey = "${newNode.id}_${nodeTo.id}";
                    mapConnectome[connectionKey] = 50;
                    edge.connectionStrength = 50;
                    controller.edges.add(edge);

                    initNativeC(false);
                    isBrainTargetOverlayTop = -1;
                    containedIdx = -1;

                    Future.delayed(const Duration(milliseconds: 100), () {
                      controller.deselect(neuronsKey[neuronsKey.length - 1]);
                      modeIdx = -1;
                      controller.modeIdx = modeIdx;

                      setState(() {});
                    });
                  },
                  onLeave: (value) {
                    print("On Leave Drag Target2");
                    mapBg["activeComponent"] = noActiveComponent;
                    // setState(() {});
                    Future.delayed(const Duration(milliseconds: 217), () {
                      // print("On Leave Drag Target delay finished");
                      setState(() {});
                    });
                  },
                  builder: (ctx, candidates, rejects) {
                    // return Container(
                    //   width: neuronInfo["size"].width,
                    //   height: neuronInfo["size"].height,
                    //   color: Colors.green.withOpacity(0.2),
                    // );
                    // return Container(
                    //     width: neuronInfo["size"].width,
                    //     height: neuronInfo["size"].height,
                    //     color: Colors.transparent);
                    return CustomPaint(
                      size: neuronInfo["size"], // Adjust size as needed
                      painter: listPainters[tempIdx],
                    );
                  }),
            )),
      );
    }
    if (isBrainTargetOverlayTop == 1) {
      list.add(brainTarget);
    }

    return list;
  }

  void repositionContactNeurons() {
    windowWidth = MediaQuery.of(context).size.width;
    windowHeight = MediaQuery.of(context).size.height;
    // calculate imageSize
    final Size containerSize =
        Size(windowWidth, windowHeight); // Replace with your container size

    Size initialImageSize = const Size(600, 600);
    final fittedSizes =
        applyBoxFit(BoxFit.contain, initialImageSize, containerSize);
    currentImageWidth = fittedSizes.destination.width;
    currentImageHeight = fittedSizes.destination.height;
    final Size imageSize = Size(
        currentImageWidth, currentImageHeight); // Replace with your image size

    double leftSpace = (windowWidth - currentImageWidth) / 2;
    double topSpace = (windowHeight - currentImageHeight) / 2;
    leftInnerWindowSpace = leftSpace;
    topInnerWindowSpace = topSpace;

    double widthRatio = currentImageWidth / 600;
    double heightRatio = currentImageHeight / 600;
    // 395, 150
    Offset centerOffset =
        Offset(windowWidth / 2 - 5, topSpace + (90 * heightRatio).ceil());
    nodeLeftEyeSensor.offset = centerOffset;

    nodeDistanceSensor.offset = Offset(
        centerOffset.dx - (195 * widthRatio).ceil(),
        topSpace + 115 * heightRatio);
    // @New design
    // nodeRightEyeSensor.offset = Offset(
    //     nodeDistanceSensor.offset.dx + (75 * widthRatio).ceil(),
    //     topSpace + 120 * heightRatio);

    nodeMicrophoneSensor.offset = Offset(
        centerOffset.dx + (210 * widthRatio).ceil(),
        centerOffset.dy + (50 * heightRatio).ceil());

    nodeLeftMotorForwardSensor.offset = Offset(
        nodeDistanceSensor.offset.dx - (45 * widthRatio).ceil(),
        nodeDistanceSensor.offset.dy + (140 * heightRatio).ceil());
    nodeLeftMotorBackwardSensor.offset = Offset(
        nodeLeftMotorForwardSensor.offset.dx - (10 * widthRatio).ceil(),
        nodeLeftMotorForwardSensor.offset.dy + (120 * heightRatio).ceil());

    nodeRightMotorForwardSensor.offset = Offset(
        nodeMicrophoneSensor.offset.dx + (15 * widthRatio).ceil(),
        nodeMicrophoneSensor.offset.dy + (117 * heightRatio).ceil());

    nodeRightMotorBackwardSensor.offset = Offset(
        nodeRightMotorForwardSensor.offset.dx + (10 * widthRatio).ceil(),
        nodeRightMotorForwardSensor.offset.dy + (120 * heightRatio).ceil());

    nodeSpeakerSensor.offset = Offset(
        nodeRightMotorBackwardSensor.offset.dx - (95 * widthRatio).ceil(),
        nodeRightMotorBackwardSensor.offset.dy + (125 * heightRatio).ceil());

    nodeRedLed.offset = Offset(
        nodeLeftMotorBackwardSensor.offset.dx + (30 * widthRatio).ceil(),
        nodeLeftMotorBackwardSensor.offset.dy + (60 * heightRatio).ceil());
    nodeGreenLed.offset = Offset(
        nodeLeftMotorBackwardSensor.offset.dx + (60 * widthRatio).ceil(),
        nodeLeftMotorBackwardSensor.offset.dy + (80 * heightRatio).ceil());
    nodeBlueLed.offset = Offset(
        nodeLeftMotorBackwardSensor.offset.dx + (90 * widthRatio).ceil(),
        nodeLeftMotorBackwardSensor.offset.dy + (110 * heightRatio).ceil());
  }

  void onDeleteCallback() {
    if (isDrawTail) {
      deleteNeuronCallback();
      resetMouse();
    } else {
      deleteEdgeCallback();
      resetMouse();
    }
  }

  int zoneWidth = 500;
  int zoneHeight = 150;
  Offset getUniqueZone(centerZoneOffset, neuronInfo) {
    int areaWidth = 0;
    int areaHeight = 0;
    Offset emptyArea;
    final random = Random();
    for (int i = 1; i <= 10; i++) {
      for (int j = 1; j <= 10; j++) {
        for (int k = 0; k < 30; k++) {
          if (neuronInfo["zoneArea"][0] > 0) {
            areaWidth = 160;
          }
          if (neuronInfo["zoneArea"][1] > 0) {
            areaHeight = 160;
          }
          emptyArea = Offset(
              centerZoneOffset.dx +
                  areaWidth +
                  neuronInfo["zoneArea"][0] * i * zoneWidth / 8 +
                  random.nextInt(50) -
                  neuronInfo["zoneArea"][0] * 50,
              centerZoneOffset.dy +
                  areaHeight +
                  neuronInfo["zoneArea"][1] * j * zoneHeight / 8 +
                  random.nextInt(20) +
                  0);
          if (emptyArea.dx < brainPosition.dx) {
            emptyArea = Offset(brainPosition.dx, emptyArea.dy);
          }
          if (emptyArea.dy < brainPosition.dy) {
            emptyArea = Offset(emptyArea.dx, brainPosition.dy);
          }

          if (emptyArea.dx > brainPosition.dx + brainSize.width) {
            emptyArea =
                Offset(brainPosition.dx + brainSize.width, emptyArea.dy);
          }
          if (emptyArea.dy > brainPosition.dy + brainSize.height) {
            emptyArea =
                Offset(emptyArea.dx, brainPosition.dy + brainSize.height);
          }

          if (isEmptyArea(emptyArea)) {
            print("!!emptyArea");
            print(neuronInfo["zoneArea"]);
            print(neuronInfo["zoneArea"][0] * i);
            print(neuronInfo["zoneArea"][0] * i * zoneWidth / 3);
            print(emptyArea);
            return emptyArea;
          }
        }
      }
    }
    return centerZoneOffset;
  }

  bool isEmptyArea(Offset emptyArea) {
    Rect srcNeuron = Rect.fromCenter(
        center: Offset(emptyArea.dx, emptyArea.dy), width: 15, height: 15);
    bool flag = true;
    controller.nodes.forEach((node) {
      Rect destNeuron = Rect.fromCenter(
          center: Offset(node.offset.dx, node.offset.dy),
          width: 15,
          height: 15);
      if (srcNeuron.overlaps(destNeuron)) {
        flag = false;
      }
    });
    return flag;
  }

  List<Widget> generateDistanceToolboxWidgets(
      List<Map<String, String>> listDistanceInfo, int toIdx) {
    int idx = -1;
    return listDistanceInfo.map((Map<String, String> mapDistanceInfo) {
      idx++;
      int index = idx;
      String distanceLabel = mapDistanceInfo["label"] ?? "";
      String distanceIcon = mapDistanceInfo["icon"] ?? "";
      return GestureDetector(
        onTap: () {
          selectedDistanceIdx = index;
          switch (selectedDistanceIdx) {
            case 0:
              distanceMenuType = "Short";
              distanceMinLimitBufView[toIdx] = 1;
              distanceMaxLimitBufView[toIdx] = 8;
              break;
            case 1:
              distanceMenuType = "Medium";
              distanceMinLimitBufView[toIdx] = 8;
              distanceMaxLimitBufView[toIdx] = 30;
              break;
            case 2:
              distanceMenuType = "Long";
              distanceMinLimitBufView[toIdx] = 30;
              distanceMaxLimitBufView[toIdx] = 100;
              break;
            case 3:
              distanceMenuType = "Custom";
              distanceMinLimitBufView[toIdx] = 35;
              distanceMaxLimitBufView[toIdx] = 65;
              txtDistanceMinController.text = "35";
              txtDistanceMaxController.text = "65";

              // if ()
              // distanceLimitBufView[0] = 35;
              // distanceLimitBufView[1] = 65;
              break;
          }
          linkDistanceConnection(distanceMenuType);
          setState(() {});
        },
        child: SizedBox(
          width: 90,
          height: 100,
          child: Stack(
            children: [
              Positioned(
                  left: 0,
                  top: 0,
                  child: Container(
                    width: 70,
                    height: 70,
                    margin: const EdgeInsets.fromLTRB(10, 0, 0, 0),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      color: selectedDistanceIdx.toString() ==
                              mapDistanceInfo["idx"]
                          ? Colors.orange
                          : Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withOpacity(0.5),
                          spreadRadius: 2,
                          blurRadius: 7,
                          offset:
                              const Offset(0, 3), // changes position of shadow
                        ),
                      ],
                    ),
                    child: Text(distanceIcon,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 45,
                          fontFamily: "NotoEmoji",
                        )),
                  )),
              Positioned(
                  left: 0,
                  bottom: 0,
                  child: Card(
                      // margin: const EdgeInsets.all(10),
                      child: Container(
                          width: 80,
                          height: 30,
                          child: Center(
                            child: Text(
                              distanceLabel,
                              textAlign: TextAlign.center,
                              style: TextStyle(),
                            ),
                          ))))
            ],
          ),
        ),
      );
    }).toList();
  }
}

class EyeClipper extends CustomClipper<Rect> {
  EyeClipper({required this.isLeft, required this.width, required this.height});
  final bool isLeft;
  final double width;
  final double height;
  @override
  Rect getClip(Size size) {
    // if (isLeft) {
    //   return const Rect.fromLTWH(0, 25, 150, 150);
    // } else {
    //   return const Rect.fromLTWH(50, 25, 150, 150);
    // }
    if (isLeft) {
      return const Rect.fromLTWH(0, 15, 210 / 2, 210 / 2);
    } else {
      return const Rect.fromLTWH(110 / 2, 15, 210 / 2, 210 / 2);
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
  // Uint8List emptyFrame = Uint8List(320 * 240);
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

  ImagePreprocessor() {
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

  clearMemory() {
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
    // if (isJpegValid) {
    //   await resizeImageFrame(frameData).then((flag) {
    //     ptrResizedFrame.asTypedList(resizedFrameLength);
    //   });

    // }
    if (isJpegValid &&
        !isCheckingImage &&
        _DesignBrainPageState.aiVisualTypes > 0) {
      isCheckingImage = true;
      // checkImageAi(frameData).then((flag) {});
      _DesignBrainPageState.detector!.processFrame(frameData);
    }

    if (!isCheckingColor && isJpegValid) {
      DesignBrainPage.prevFrame = frameData;
      if (_DesignBrainPageState.imageVisualTypes > 0) {
        isCheckingColor = true;
        checkColorCV(frameData).then((flag) {
          isCheckingColor = false;
        });
      }
    } else {
      if (!isJpegValid) {
        print("isNotValidJPEG");
        return DesignBrainPage.prevFrame;
      } else {
        DesignBrainPage.prevFrame = frame;
      }
    }
    // return emptyFrame;

    mainBloc.drawImageNow(frameData);
    return frame;
  }
}
