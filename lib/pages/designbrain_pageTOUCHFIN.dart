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
import 'package:another_xlider/models/handler.dart';
import 'package:another_xlider/models/trackbar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:ffi/ffi.dart';
import 'package:fialogs/fialogs.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_mjpeg/flutter_mjpeg.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gesture_x_detector/gesture_x_detector.dart';
import 'package:infinite_canvas/infinite_canvas.dart';
import 'package:infinite_canvas/src/domain/model/SyntheticNeuron.dart';
import 'package:infinite_canvas/src/domain/model/SyntheticEdge.dart';
import 'package:infinite_canvas/src/domain/model/drop_target.dart';
import 'package:matrix_gesture_detector_pro/matrix_gesture_detector_pro.dart';
// import 'package:metooltip/metooltip.dart';
import 'package:mutex/mutex.dart';
import 'package:neurorobot/components/search_textfield.dart';
import 'package:neurorobot/dialogs/version_dialog.dart';
import 'package:neurorobot/components/drop_targets.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:infinite_canvas/src/presentation/widgets/nucleus.dart';

// import 'package:native_opencv/native_opencv.dart';
// import 'package:native_opencv/nativec.dart';
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
import 'package:url_launcher/url_launcher.dart';
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
  List<LocalKey> temporaryEdge = [];
  int isTemporaryEdge = -1;
  static Detector? detector;
  StreamSubscription? _imageDetectorSubscription;
  PackageInfo? packageInfo;
  Map<String, String> lookup = {
    "person": "🧍",
    "backpack": "🎒",
    "bottle": "🧴", // 🍶 🍼 🍾
    "cup": "☕",
    "bowl": "🥣", // 🥣
    "banana": "🍌",
    "apple": "🍎",
    "orange": "🍊",
    "chair": "🪑", // 💺
    "couch": "🛋️",
    "potted plant": "🪴",
    "laptop": "💻",
    "cell phone": "📱",
    "book": "📒",
    "vase": "🏺",
    "Movement": "🏃",
  };

  /// Results to draw bounding boxes
  List<Recognition>? results;

  /// Realtime stats
  Map<String, dynamic>? aiStats;
  Map<String, dynamic> aiObjectsInfo = {};

  // WEB SOCKET
  static late SendPort isolateWritePort;
  bool isIsolateWritePortInitialized = false;
  bool isReceivingCalculation = true;
  late ReceivePort writePort = ReceivePort();

  // SIMULATION SECTION
  // List<String> neuronTypes = [];
  Map<String, String> neuronTypes = {};
  Map<String, String> neuronStyles = {};
  static const int motorCommandsLength = 6 * 2;
  static const int maxPosBuffer = 220;
  int epochs = 30;
  late List<SingleSquare> squareActiveCirclesPainter;
  late List<SingleSquare> squareInactiveCirclesPainter;
  late List<SingleCircle> neuronActiveCirclesPainter;
  late List<SingleCircle> neuronInactiveCirclesPainter;

  // late Nativec nativec;

  bool isDeleteMenu = false;
  bool isNeuronMenu = false;
  bool isSynapseMenu = false;
  bool isCameraMenu = false;
  bool isDistanceMenu = false;
  bool isMotorMenu = false;
  bool isMicrophoneMenu = false;
  bool isSpeakerMenu = false;
  bool isLedMenu = false;

  Color colorOrange = const Color(0XFFFD8164);
  Color colorGreen = const Color(0XFF18a953);
  String neuronMenuType = "Quiet";
  List<String> neuronTypesLabel = [
    "Quiet",
    "Occassionally active",
    "Highly active",
    "Generates bursts",
    "Bursts when activated",
    // "Dopaminergic",
    // "Striatal",
    "Custom",
    "Delay", //8
    // "Rhytmic", //9
    // "Counting", //10
  ];

  List<String> neuronMenuTypes = [
    "Quiet",
    "Occassionally active",
    "Highly active",
    "Generates bursts",
    "Bursts when activated",
    // "Dopaminergic",
    // "Striatal",
    "Custom",
    "Delay",
    // "Rhytmic",
    // "Counting", //10
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

  String distanceMenuType = "Medium";
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
  // late ffi.Pointer<ffi.Uint8> ptrFrame;
  // static ffi.Pointer<ffi.Uint8> ptrMaskedFrame = allocate<ffi.Uint8>(
  //     count: frameQVGASize, sizeOfType: ffi.sizeOf<ffi.Uint8>());

  // static ffi.Pointer<ffi.Uint8> ptrLowerB =
  //     allocate<ffi.Uint8>(count: 3, sizeOfType: ffi.sizeOf<ffi.Uint8>());
  // static ffi.Pointer<ffi.Uint8> ptrUpperB =
  //     allocate<ffi.Uint8>(count: 3, sizeOfType: ffi.sizeOf<ffi.Uint8>());

  // late ffi.Pointer<ffi.Uint32> npsBuf;
  // late ffi.Pointer<ffi.Int16> neuronCircleBuf;
  // late ffi.Pointer<ffi.Int16> positionsBuf;
  // late ffi.Pointer<ffi.Double> aBuf;
  // late ffi.Pointer<ffi.Double> bBuf;
  // late ffi.Pointer<ffi.Int16> cBuf;
  // late ffi.Pointer<ffi.Int16> dBuf;
  // late ffi.Pointer<ffi.Double> iBuf;
  // late ffi.Pointer<ffi.Double> wBuf;
  // late ffi.Pointer<ffi.Int16> visPrefsBuf;
  // late ffi.Pointer<ffi.Double> connectomeBuf;
  // late ffi.Pointer<ffi.Double> motorCommandBuf;
  // late ffi.Pointer<ffi.Double> neuronContactsBuf;
  // late ffi.Pointer<ffi.Int16> neuronDistanceBuf;
  // late ffi.Pointer<ffi.Int16> neuronSpeakerBuf;
  // late ffi.Pointer<ffi.Int16> neuronMicrophoneBuf;
  // late ffi.Pointer<ffi.Int16> neuronLedBuf;
  // late ffi.Pointer<ffi.Int16> neuronLedPositionBuf;
  // late ffi.Pointer<ffi.Double> distanceBuf;
  // late ffi.Pointer<ffi.Int16> distanceMinLimitBuf;
  // late ffi.Pointer<ffi.Int16> distanceMaxLimitBuf;

  // late ffi.Pointer<ffi.Int16> mapNeuronTypeBuf;
  // late ffi.Pointer<ffi.Int16> mapDelayNeuronBuf;
  // late ffi.Pointer<ffi.Int16> mapRhytmicNeuronBuf;
  // late ffi.Pointer<ffi.Int16> mapCountingNeuronBuf;

  // late ffi.Pointer<ffi.Int32> stateBuf;
  // late ffi.Pointer<ffi.Double> visPrefsValsBuf;
  // late ffi.Pointer<ffi.Uint8> motorCommandMessageBuf;

  // late ffi.Pointer<ffi.Double> visualInputBuf;

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
  static late Float64List visPrefsValsBufView = Float64List(0);
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
  static Float64List visualInputBufView = Float64List(0);

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
  bool isControllerInitialized = false;
  bool isReorientation = false;
  bool isFullScreen = false;

  late ProtoNeuron protoNeuron;
  bool isChartSelected = false;
  int selectedIdx = 0;
  ValueNotifier<int> redrawNeuronLine = ValueNotifier(0);

  late WaveWidget waveWidget;

  late Mjpeg mjpegComponent;

  bool isEmergencyPause = false;
  bool isDrawTail = false;
  int prevEdgesLength = 0;
  Offset? prevSelectedOffsetNode;
  InfiniteCanvasNode? prevSelectedNode;
  late InfiniteCanvasNode prevSelectedNeuron;
  late InfiniteCanvasEdge prevSelectedEdge;
  bool isPrevSelectedEdge = false;

  late InfiniteCanvasNode tailNode;
  late InfiniteCanvasNode triangleNode;
  late InfiniteCanvasNode rectangleNode;
  late InfiniteCanvasNode circleNode;

  bool isPanningCanvas = false;

  Paint circleColor = Paint()..color = Colors.red;
  Paint triangleColor = Paint()..color = const Color(0xFF18A953);
  Paint rectangleColor = Paint()..color = const Color(0xFF1996FC);

  Paint neuronColor = Paint()..color = Colors.grey;
  Paint tailColor = Paint()..color = const Color(0xFF18A953);

  int gapTailX = 0;
  int gapTailY = 40;

  double prevMouseX = 0.0, prevMouseY = 0.0;

  static int neuronSize = 13;
  int circleNeuronStartIndex = 12;
  int normalNeuronStartIdx = 13;
  int allNeuronStartIdx = 2; // beside viewport & tail node

  Uint8List dataMaskedImage = Uint8List(0);

  int bufPositionCount = 1;
  int bufDistanceCount = 1;
  int bufDistanceLimitCount = 100;

  late ImagePreprocessor processor;

  String httpdStream = "http://192.168.4.1:81/stream";
  // String httpdStream = "http://192.168.1.4:8081";

  Isolate? webSocket;

  bool isSimulationCallbackAttached = false;

  int StateLength = 20;
  int MotorMessageLength = 300;
  // int VisualPrefLength = 7 * 2;
  final rightEyeConstant = 15 + 7;
  int VisualPrefLength = 22 * 2;
  static int VisualInputLength = 22;

  late Widget mainBody;

  double prevTransformScale = 1;
  Debouncer debouncerActiveArea = Debouncer(milliseconds: 77);
  Debouncer debouncerSnapNeuron = Debouncer(milliseconds: 3);
  Debouncer debouncerAIClassification = Debouncer(milliseconds: 300);
  Debouncer debouncerNoResponse = Debouncer(milliseconds: 3700);
  Debouncer debouncerTooltip = Debouncer(milliseconds: 1000);
  Debouncer debouncerSave = Debouncer(milliseconds: 1);
  Debouncer debouncerActiveComponent = Debouncer(milliseconds: 100);
  Debouncer debouncerHoveringNeuron = Debouncer(milliseconds: 400);
  Map<String, int> mapHoveringNeuron = {};

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

  late SearchTextField searchCameraTargetTextField;
  TextEditingController tecHexColor = TextEditingController();
  TextEditingController tecSearchCameraTarget = TextEditingController();
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
  TextEditingController tecSynapticWeightR = TextEditingController();
  TextEditingController tecSynapticWeightG = TextEditingController();
  TextEditingController tecSynapticWeightB = TextEditingController();
  double sldSynapticWeight = 25.0;
  double sldSynapticWeightR = 25.0;
  double sldSynapticWeightG = 25.0;
  double sldSynapticWeightB = 25.0;

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
  late Directory versionDirectory;

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
  int activeSensoryIdx = -1;

  late List<int> mapDelayNeuronList = [];
  late List<int> mapRhytmicNeuronList = [];
  late List<int> mapCountingNeuronList = [];

  List<SyntheticNeuron> rawSyntheticNeuronList = [];
  List<SyntheticNeuron> syntheticNeuronList = [];
  List<Connection> syntheticConnections = [];

  late Positioned toolbarMenu;

  List<InfiniteCanvasNode> sensoryNeurons = [];

  int modeIdx = -1;
  String strFirmwareVersion = "";
  int firmwareVersionInt = 0;

  static bool isInfoMenu = true;
  static bool isShowingLeftColorMenu = false;
  static bool isShowingRightColorMenu = false;
  bool isShowingLeftAiMenu = false;
  bool isShowingRightAiMenu = false;

  static String strLeftColorMenu = '000';
  static String strRightColorMenu = '000';

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? configListener;

  String isTailType = "circle";

  int CONFIG_DELAY_NEURON = 6;
  int CONFIG_RHYTMIC_NEURON = 7;
  int CONFIG_COUNTING_NEURON = 8;

  String restartText = '';

  Offset centerZoneOffset = const Offset(320, 220);

  List<Widget> bottomRightMenuWidgets = [];

  Map<String, String> mapBg = {
    "activeComponent": "assets/bg/BrainDrawings/No_image.svg",
    "activeBg": "assets/bg/BrainDrawings/BrainFullBlack.svg",
  };

  /* DISTANCE SENSOR
  */
  int selectedDistanceIdx = 0;
  int isShowingInfo = 1;

  double leftInnerWindowSpace = 0;
  double topInnerWindowSpace = 0;

  double minDistanceSlider = 1;
  double maxDistanceSlider = 130;

  double minAreaSizeSlider = 1;
  double maxAreaSizeSlider = 320;
  Int16List areaSizeMinLimitBufView = Int16List(200);
  Int16List areaSizeMaxLimitBufView = Int16List(200);

  TextEditingController txtDistanceMinController =
      TextEditingController(text: "1");
  TextEditingController txtDistanceMaxController =
      TextEditingController(text: "8");
  TextEditingController txtAreaSizeMinController =
      TextEditingController(text: "1");
  TextEditingController txtAreaSizeMaxController =
      TextEditingController(text: "160");

  int isBrainTargetOverlayTop = -1;

  int containedIdx = -1;

  int brainContainedIdx = -1;

  Offset prevConstrainedPos = Offset.zero;
  bool prevConstrainedFlag = true;

  bool isContainingLabel = false;
  String distanceSensorContent =
      "NEURON will SPIKE when on object is in front of the robot at 1 to 8 cm.";

  double scaleMultiplier = 1.0;

  List<String> cameraRegions = ["Left", "Any", "Right", "Custom"];
  String selectedCameraPosition = "Left";
  int selectedCameraColor = 0;

  Row blueContainer = Row(
    children: [
      Container(
          width: 20,
          height: 20,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFF1996FC), // Replace with your desired color
          )),
      const Text("Blue"),
    ],
  );
  Row greenContainer = Row(
    children: [
      Container(
          width: 20,
          height: 20,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFF18A953), // Replace with your desired color
          )),
      const Text("Green"),
    ],
  );
  Row redContainer = Row(
    children: [
      Container(
          width: 20,
          height: 20,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.red, // Replace with your desired color
          )),
      const Text("Red"),
    ],
  );

  bool isSelectingCameraTarget = false;

  Map<String, dynamic> selectedEyeInfo = {
    "icon": "Green",
    "label": "Color Green",
    "idx": 2
  };
  String searchCameraTarget = "";
  bool isVisualDetection = true;

  List<bool> colorPositionFlags = [false, false, false];
  List<bool> aiPositionFlags = List<bool>.generate(22, (idx) => false);

  String selectedCameraRegion = "";

  bool isPlayingMode = false;
  List<Offset> arrPosConstraints = [];
  List<Widget> arrCirclePositions = [];
  // late StreamSubscription<ConnectivityResult> subscriptionWifi;

  bool? isPortrait;

  void runNativeC() {
    // const level = 1;
    // const envelopeSize = 200;
    // const bufferSize = 2000;
    // nativec.initialize();
    // printDebug("motorCommandBufView.length");
    // printDebug(neuronSize);
    // // printDebug(motorCommandBufView.length);
    // // printDebug(visPrefsBufView);
    // nativec.changeNeuronSimulatorProcess(
    //   aBuf,
    //   bBuf,
    //   cBuf,
    //   dBuf,
    //   iBuf,
    //   wBuf,
    //   connectomeBuf,
    //   level,
    //   neuronSize,
    //   envelopeSize,
    //   bufferSize,
    //   1,
    //   visPrefsBuf,
    //   motorCommandBuf,
    //   neuronContactsBuf,
    //   mapNeuronTypeBuf,
    //   mapDelayNeuronBuf,
    //   mapRhytmicNeuronBuf,
    //   mapCountingNeuronBuf,
    // );
  }

  void initMemoryAllocation() {
    // npsBuf =
    //     allocate<ffi.Uint32>(count: 2, sizeOfType: ffi.sizeOf<ffi.Uint32>());
    // neuronCircleBuf = allocate<ffi.Int16>(
    //     count: maxPosBuffer, sizeOfType: ffi.sizeOf<ffi.Int16>());
    // positionsBuf = allocate<ffi.Int16>(
    //     count: bufPositionCount, sizeOfType: ffi.sizeOf<ffi.Int16>());
    // aBuf = allocate<ffi.Double>(
    //     count: maxPosBuffer, sizeOfType: ffi.sizeOf<ffi.Double>());
    // bBuf = allocate<ffi.Double>(
    //     count: maxPosBuffer, sizeOfType: ffi.sizeOf<ffi.Double>());
    // cBuf = allocate<ffi.Int16>(
    //     count: maxPosBuffer, sizeOfType: ffi.sizeOf<ffi.Int16>());
    // dBuf = allocate<ffi.Int16>(
    //     count: maxPosBuffer, sizeOfType: ffi.sizeOf<ffi.Int16>());
    // iBuf = allocate<ffi.Double>(
    //     count: maxPosBuffer, sizeOfType: ffi.sizeOf<ffi.Double>());
    // wBuf = allocate<ffi.Double>(
    //     count: maxPosBuffer, sizeOfType: ffi.sizeOf<ffi.Double>());

    // mapNeuronTypeBuf = allocate<ffi.Int16>(
    //     count: maxPosBuffer, sizeOfType: ffi.sizeOf<ffi.Int16>());
    // mapDelayNeuronBuf = allocate<ffi.Int16>(
    //     count: maxPosBuffer * maxPosBuffer,
    //     sizeOfType: ffi.sizeOf<ffi.Int16>());
    // mapRhytmicNeuronBuf = allocate<ffi.Int16>(
    //     count: maxPosBuffer * maxPosBuffer,
    //     sizeOfType: ffi.sizeOf<ffi.Int16>());
    // mapCountingNeuronBuf = allocate<ffi.Int16>(
    //     count: maxPosBuffer * maxPosBuffer,
    //     sizeOfType: ffi.sizeOf<ffi.Int16>());

    // visPrefsBuf = allocate<ffi.Int16>(
    //     count: maxPosBuffer * maxPosBuffer,
    //     sizeOfType: ffi.sizeOf<ffi.Int16>());
    // visPrefsValsBuf = allocate<ffi.Double>(
    //     count: VisualPrefLength, sizeOfType: ffi.sizeOf<ffi.Double>());
    // visualInputBuf = allocate<ffi.Double>(
    //     count: maxPosBuffer * maxPosBuffer,
    //     sizeOfType: ffi.sizeOf<ffi.Double>());

    // connectomeBuf = allocate<ffi.Double>(
    //     count: maxPosBuffer * maxPosBuffer,
    //     sizeOfType: ffi.sizeOf<ffi.Double>());
    // neuronContactsBuf = allocate<ffi.Double>(
    //     count: maxPosBuffer * maxPosBuffer,
    //     sizeOfType: ffi.sizeOf<ffi.Double>());
    // neuronDistanceBuf = allocate<ffi.Int16>(
    //     count: maxPosBuffer * maxPosBuffer,
    //     sizeOfType: ffi.sizeOf<ffi.Int16>());
    // neuronSpeakerBuf = allocate<ffi.Int16>(
    //     count: maxPosBuffer * maxPosBuffer,
    //     sizeOfType: ffi.sizeOf<ffi.Int16>());
    // neuronMicrophoneBuf = allocate<ffi.Int16>(
    //     count: maxPosBuffer * maxPosBuffer,
    //     sizeOfType: ffi.sizeOf<ffi.Int16>());
    // neuronLedBuf = allocate<ffi.Int16>(
    //     count: maxPosBuffer * maxPosBuffer,
    //     sizeOfType: ffi.sizeOf<ffi.Int16>());
    // neuronLedPositionBuf = allocate<ffi.Int16>(
    //     count: maxPosBuffer * maxPosBuffer,
    //     sizeOfType: ffi.sizeOf<ffi.Int16>());

    // distanceBuf = allocate<ffi.Double>(
    //     count: bufDistanceCount, sizeOfType: ffi.sizeOf<ffi.Double>());

    // // up to 144 neurons
    // if (!isInitialized) {
    //   distanceMinLimitBuf = allocate<ffi.Int16>(
    //       count: bufDistanceLimitCount, sizeOfType: ffi.sizeOf<ffi.Int16>());
    //   distanceMaxLimitBuf = allocate<ffi.Int16>(
    //       count: bufDistanceLimitCount, sizeOfType: ffi.sizeOf<ffi.Int16>());
    //   areaSizeMinLimitBufView.fillRange(0, 100, 1);
    //   areaSizeMaxLimitBufView.fillRange(0, 100, 320);
    // }

    // motorCommandBuf = allocate<ffi.Double>(
    //     count: motorCommandsLength, sizeOfType: ffi.sizeOf<ffi.Double>());

    // stateBuf = allocate<ffi.Int32>(
    //     count: StateLength, sizeOfType: ffi.sizeOf<ffi.Int>());
    // motorCommandMessageBuf = allocate<ffi.Uint8>(
    //     count: MotorMessageLength, sizeOfType: ffi.sizeOf<ffi.Uint8>());
    // printDebug("Init memory allocation");
    // mapDelayNeuronList = List.generate(neuronSize, (index) => -1);
    // mapRhytmicNeuronList = List.generate(neuronSize, (index) => -1);
    // mapCountingNeuronList = List.generate(neuronSize, (index) => -1);
  }

  void initNativeC(bool isInitialized) {
  //   double a = 0.02;
  //   double b = 0.18;
  //   int c = -65;
  //   int d = 2;
  //   double i = 5.0;
  //   double w = 2.0;

  //   // int neuronSizeType = neuronSize;
  //   if (kIsWeb) {
  //     // aBufView  = Float64List(neuronSize);
  //     // bBufView  = Float64List(neuronSize);
  //     // cBufView  = Int16List(neuronSize);
  //     // dBufView  = Int16List(neuronSize);
  //     // iBufView  = Float64List(neuronSize);
  //     // wBufView  = Float64List(neuronSize);
  //     // positionsBufView  = Int16List(neuronSize);
  //     // connectomeBufView  = Float64List(neuronSize*neuronSize);
  //   } else {
  //     // printDebug("try to pass pointers");

  //     nativec = Nativec();
  //     nativec.passInput(distanceBuf, distanceMinLimitBuf, distanceMaxLimitBuf);
  //     nativec.passPointers(
  //       Nativec.canvasBuffer1!,
  //       positionsBuf,
  //       neuronCircleBuf,
  //       npsBuf,
  //       stateBuf,
  //       visPrefsBuf,
  //       visPrefsValsBuf,
  //       motorCommandMessageBuf,
  //       neuronContactsBuf,
  //       neuronDistanceBuf,
  //       neuronSpeakerBuf,
  //       neuronMicrophoneBuf,
  //       neuronLedBuf,
  //       neuronLedPositionBuf,
  //       visualInputBuf,
  //     );
  //     // printDebug("try to pass nativec pointers");
  //     aBufView = aBuf.asTypedList(neuronSize);
  //     bBufView = bBuf.asTypedList(neuronSize);
  //     cBufView = cBuf.asTypedList(neuronSize);
  //     dBufView = dBuf.asTypedList(neuronSize);
  //     iBufView = iBuf.asTypedList(neuronSize);
  //     wBufView = wBuf.asTypedList(neuronSize);
  //     npsBufView = npsBuf.asTypedList(2);
  //     // printDebug("neuronSize neuronCircleBridge");
  //     // printDebug(neuronSize);
  //     neuronCircleBridge = neuronCircleBuf.asTypedList(neuronSize);
  //     printDebug(neuronCircleBridge.length);
  //     positionsBufView = positionsBuf.asTypedList(bufPositionCount);
  //     distanceBufView = distanceBuf.asTypedList(bufDistanceCount);
  //     distanceMinLimitBufView =
  //         distanceMinLimitBuf.asTypedList(bufDistanceLimitCount);
  //     distanceMaxLimitBufView =
  //         distanceMaxLimitBuf.asTypedList(bufDistanceLimitCount);
  //     connectomeBufView = connectomeBuf.asTypedList(neuronSize * neuronSize);
  //     visPrefsBufView = visPrefsBuf.asTypedList(neuronSize * neuronSize);
  //     visPrefsValsBufView = visPrefsValsBuf.asTypedList(VisualPrefLength);
  //     motorCommandBufView = motorCommandBuf.asTypedList(motorCommandsLength);
  //     neuronContactsBufView =
  //         neuronContactsBuf.asTypedList(neuronSize * neuronSize);
  //     neuronDistanceBufView =
  //         neuronDistanceBuf.asTypedList(neuronSize * neuronSize);
  //     neuronSpeakerBufView =
  //         neuronSpeakerBuf.asTypedList(neuronSize * neuronSize);
  //     neuronMicrophoneBufView =
  //         neuronMicrophoneBuf.asTypedList(neuronSize * neuronSize);
  //     neuronLedBufView = neuronLedBuf.asTypedList(neuronSize * neuronSize);
  //     neuronLedPositionBufView =
  //         neuronLedPositionBuf.asTypedList(neuronSize * neuronSize);

  //     mapNeuronTypeBufView = mapNeuronTypeBuf.asTypedList(neuronSize);
  //     mapDelayNeuronBufView = mapDelayNeuronBuf.asTypedList(neuronSize);
  //     mapRhytmicNeuronBufView = mapRhytmicNeuronBuf.asTypedList(neuronSize);
  //     mapCountingNeuronBufView = mapCountingNeuronBuf.asTypedList(neuronSize);

  //     visualInputBufView =
  //         visualInputBuf.asTypedList(VisualInputLength * (neuronSize + 2));

  //     // if (!isSimulationCallbackAttached) {
  //     //   isSimulationCallbackAttached = true;
  //     if (isInitialized) {
  //       nativec.simulationCallback(updateFromSimulation);
  //     }
  //     // }
  //   }

  //   // if (isInitialized) {
  //   // printDebug("isInitialized anandasd");
  //   aBufView.fillRange(0, neuronSize, a);
  //   bBufView.fillRange(0, neuronSize, b);
  //   cBufView.fillRange(0, neuronSize, c);
  //   dBufView.fillRange(0, neuronSize, d);
  //   iBufView.fillRange(0, neuronSize, i);
  //   wBufView.fillRange(0, neuronSize, w);
  //   // }
  //   positionsBufView.fillRange(0, 1, 0);
  //   distanceBufView.fillRange(0, 1, 0);
  //   distanceMinLimitBufView.fillRange(0, bufDistanceLimitCount, 1);
  //   distanceMaxLimitBufView.fillRange(0, bufDistanceLimitCount, 8);
  //   // distanceLimitBufView[0] = 1;
  //   // distanceLimitBufView[1] = 8;

  //   connectomeBufView.fillRange(0, neuronSize * neuronSize, 0.0);
  //   visPrefsBufView.fillRange(0, neuronSize * neuronSize, -1);
  //   visPrefsValsBufView.fillRange(0, VisualPrefLength, 0);
  //   visualInputBufView.fillRange(0, VisualInputLength * neuronSize, -1);

  //   mapNeuronTypeBufView.fillRange(0, neuronSize, -1);
  //   mapDelayNeuronBufView.fillRange(0, neuronSize, -1);
  //   mapRhytmicNeuronBufView.fillRange(0, neuronSize, -1);
  //   mapCountingNeuronBufView.fillRange(0, neuronSize, -1);

  //   neuronContactsBufView.fillRange(0, neuronSize * neuronSize, 0);
  //   motorCommandBufView.fillRange(0, motorCommandsLength, 0.0);

  //   printDebug("neuronSize * neuronSize");
  //   printDebug(neuronSize * neuronSize);

  //   squareActiveCirclesPainter = List<SingleSquare>.generate(
  //       neuronSize, (index) => SingleSquare(isActive: true));
  //   squareInactiveCirclesPainter = List<SingleSquare>.generate(
  //       neuronSize, (index) => SingleSquare(isActive: false));

  //   squareActiveCircles = List<CustomPaint>.generate(neuronSize, (int idx) {
  //     return CustomPaint(
  //       // painter: SingleSquare(isActive: true),
  //       painter: squareActiveCirclesPainter[idx],
  //       willChange: false,
  //       isComplex: false,
  //     );
  //   });
  //   squareInactiveCircles = List<CustomPaint>.generate(neuronSize, (int idx) {
  //     return CustomPaint(
  //       painter: SingleSquare(isActive: false),
  //       willChange: false,
  //       isComplex: false,
  //     );
  //   });

  //   printDebug("NEW NEUORN SPIKE FLAGS!!!");
  //   neuronSpikeFlags =
  //       List<ValueNotifier<int>>.generate(neuronSize, (_) => ValueNotifier(0));
  //   neuronCircleKeys = List<GlobalKey>.generate(neuronSize,
  //       (i) => GlobalKey(debugLabel: "neuronWidget${i.toString()}"));

  //   // if (!isInitialized) {
  //   if (!isInitialized) {
  //     // printDebug("IS Initialized");
  //     // printDebug(syntheticNeuronList.length);
  //     // printDebug(syntheticNeuronList.map((SyntheticNeuron e) {
  //     //   return "${e.newNeuron.xNucleus} - ${e.newNeuron.yNucleus} @ ${e.newNeuron.widthNucleus} : ${e.newNeuron.heightNucleus}";
  //     // }).toList());

  //     neuronActiveCirclesPainter =
  //         List<SingleCircle>.generate(syntheticNeuronList.length, (index) {
  //       return SingleCircle(
  //         isActive: true,
  //         isExcitatory: syntheticNeuronList[index].node.isExcitatory,
  //         circleRadius: neuronDrawSize / 2,
  //         xNucleus: syntheticNeuronList.isEmpty
  //             ? 0
  //             : syntheticNeuronList[index].newNeuron.xNucleus,
  //         yNucleus: syntheticNeuronList.isEmpty
  //             ? 0
  //             : syntheticNeuronList[index].newNeuron.yNucleus,
  //         widthNucleus: syntheticNeuronList.isEmpty
  //             ? 0
  //             : syntheticNeuronList[index].newNeuron.widthNucleus,
  //         heightNucleus: syntheticNeuronList.isEmpty
  //             ? 0
  //             : syntheticNeuronList[index].newNeuron.heightNucleus,
  //       );
  //     });
  //     neuronInactiveCirclesPainter =
  //         List<SingleCircle>.generate(neuronSize, (index) {
  //       return SingleCircle(
  //         isActive: false,
  //         isExcitatory: syntheticNeuronList[index].node.isExcitatory,
  //         circleRadius: neuronDrawSize / 2,
  //         xNucleus: syntheticNeuronList.isEmpty
  //             ? 0
  //             : syntheticNeuronList[index].newNeuron.xNucleus,
  //         yNucleus: syntheticNeuronList.isEmpty
  //             ? 0
  //             : syntheticNeuronList[index].newNeuron.yNucleus,
  //         widthNucleus: syntheticNeuronList.isEmpty
  //             ? 0
  //             : syntheticNeuronList[index].newNeuron.widthNucleus,
  //         heightNucleus: syntheticNeuronList.isEmpty
  //             ? 0
  //             : syntheticNeuronList[index].newNeuron.heightNucleus,
  //       );
  //     });

  //     neuronActiveCircles = List<CustomPaint>.generate(neuronSize, (int idx) {
  //       return CustomPaint(
  //         painter: neuronActiveCirclesPainter[idx],
  //         willChange: false,
  //         isComplex: false,
  //       );
  //     });

  //     neuronInactiveCircles = List<CustomPaint>.generate(neuronSize, (int idx) {
  //       return CustomPaint(
  //         painter: neuronInactiveCirclesPainter[idx],
  //         willChange: false,
  //         isComplex: false,
  //       );
  //     });
  //   }

  //   // if (controller.nucleusList != null) {
  //   //   controller.nucleusList!.clear();
  //   // } else {
  //   //   controller.nucleusList = [];
  //   // }
  //   // int circleLen = protoNeuron.circles.length;
  //   // for (int i = 0; i < circleLen; i++) {
  //   //   SingleNeuron neuron = protoNeuron.circles[i];
  //   //   Nucleus nucleus = Nucleus(
  //   //     index: i,
  //   //     isSpiking: neuron.isSpiking,
  //   //     neuronActiveCircle: neuronActiveCircles[i],
  //   //     neuronInactiveCircle: neuronInactiveCircles[i],
  //   //     neuronSpikeFlag: neuronSpikeFlags[i],
  //   //     centerPos: neuron.centerPos,
  //   //     circleKey: neuronCircleKeys[i],
  //   //   );
  //   //   controller.nucleusList!.add(nucleus);
  //   // }
  //   WaveWidget.positionsBufView = positionsBufView;

  //   if (kIsWeb) {
  //   } else {
  //     // if (delay){
  //     //   Future.delayed(const Duration(milliseconds: 300), (){
  //     //   });
  //     // }else{
  //     //   nativec.changeNeuronSimulatorProcess(aBuf, bBuf, cBuf, dBuf, iBuf, wBuf,connectomeBuf,level, neuronSize, envelopeSize, bufferSize, 1);
  //     // }
  //   }
  }

  // END of SIMULATION SECTION

  static late InfiniteCanvasController controller;
  int menuIdx = 0;
  bool isCreatePoint = false;

  static int aiVisualTypes = 0;
  static int imageVisualTypes = 0;

  Map mapConnectome = {};
  static Map mapSensoryNeuron = {}; // vis prefs
  Map mapContactsNeuron = {};
  Map mapDistanceNeuron = {}; // dist prefs
  Map mapDistanceLimitNeuron = {}; // dist limit prefs
  Map mapSpeakerNeuron = {};
  Map mapMicrophoneNeuron = {};
  Map mapLedNeuron = {};
  Map mapLedNeuronPosition = {};
  static Map mapAreaSize = {}; // dist prefs

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
  List<InfiniteCanvasNode> listSensorArrow = [];
  List<String> listDefaultSensorLabel = [];
  ValueNotifier<int> tooltipValueChange = ValueNotifier(0);

  static var viewportKey = UniqueKey();
  InfiniteCanvasNode viewPortNode = InfiniteCanvasNode(
      key: viewportKey,
      allowMove: false,
      allowResize: false,
      // offset: const Offset(800, 600),
      offset: const Offset(0, 0),
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
    // offset: const Offset(220, 120),
    offset: const Offset(0, 0),

    // offset: const Offset(852.0 / 2, 150),
    size: const Size(20, 20),
    child: Container(width: 15, height: 15, color: Colors.transparent),
    isSensory: 1,
  );

  static InfiniteCanvasNode nodeLeftEyeSensor = InfiniteCanvasNode(
    key: UniqueKey(),
    value: 1,
    allowMove: false,
    allowResize: false,
    // @New Design
    // offset: const Offset(320, 150),
    // offset: const Offset(410, 100),
    offset: const Offset(0, 0),

    size: const Size(20, 20),
    child: Container(width: 15, height: 15, color: Colors.transparent),
    isSensory: 1,
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
    child: Container(width: 15, height: 15, color: Colors.transparent),
    isSensory: 1,
  );

  InfiniteCanvasNode nodeMicrophoneSensor = InfiniteCanvasNode(
    key: UniqueKey(),
    value: 3,
    allowMove: false,
    allowResize: false,
    // @New Design
    // offset: const Offset(267, 217),
    // offset: const Offset(600, 170),
    offset: const Offset(0, 0),
    size: const Size(0, 0),
    child: Container(width: 0, height: 0, color: Colors.transparent),
    isSensory: 1,
  );
  InfiniteCanvasNode nodeSpeakerSensor = InfiniteCanvasNode(
    key: UniqueKey(),
    value: 4,
    allowMove: false,
    allowResize: false,
    // @New Design
    // offset: const Offset(523, 217),
    // offset: const Offset(535, 495),
    offset: const Offset(0, 0),
    size: const Size(20, 20),
    child: Container(width: 15, height: 15, color: Colors.transparent),
    isSensory: 1,
  );

  InfiniteCanvasNode nodeLeftMotorForwardSensor = InfiniteCanvasNode(
    key: UniqueKey(),
    value: 5,
    allowMove: false,
    allowResize: false,
    // @New Design
    // offset: const Offset(243, 310),
    // offset: const Offset(173, 240),
    offset: const Offset(0, 0),
    size: const Size(20, 20),
    child: Container(width: 15, height: 15, color: Colors.transparent),
    isSensory: 1,
  );
  InfiniteCanvasNode nodeRightMotorForwardSensor = InfiniteCanvasNode(
    key: UniqueKey(),
    value: 6,
    allowMove: false,
    allowResize: false,
    // @New Design
    // offset: const Offset(547, 310),
    // offset: const Offset(610, 280),
    offset: const Offset(0, 0),
    size: const Size(20, 20),
    child: Container(width: 15, height: 15, color: Colors.transparent),
    isSensory: 1,
  );

  InfiniteCanvasNode nodeLeftMotorBackwardSensor = InfiniteCanvasNode(
    key: UniqueKey(),
    value: 7,
    allowMove: false,
    allowResize: false,
    // @New Design
    // offset: const Offset(240, 405),
    // offset: const Offset(170, 350),
    offset: const Offset(0, 0),
    size: const Size(20, 20),
    child: Container(width: 15, height: 15, color: Colors.transparent),
    isSensory: 1,
  );
  InfiniteCanvasNode nodeRightMotorBackwardSensor = InfiniteCanvasNode(
    key: UniqueKey(),
    value: 8,
    allowMove: false,
    allowResize: false,
    // @New Design
    // offset: const Offset(550, 405),
    // offset: const Offset(600, 390),
    offset: const Offset(0, 0),
    size: const Size(20, 20),
    child: Container(width: 15, height: 15, color: Colors.transparent),
    isSensory: 1,
  );

  InfiniteCanvasNode nodeSingleLed = InfiniteCanvasNode(
    key: UniqueKey(),
    value: 9,
    allowMove: false,
    allowResize: false,
    // offset: const Offset(470, 457),
    offset: const Offset(0, 0),
    size: const Size(20, 20),
    child: Container(width: 15, height: 15, color: Colors.transparent),
    isSensory: 1,
  );
  InfiniteCanvasNode nodeRedLed = InfiniteCanvasNode(
    key: UniqueKey(),
    value: 10,
    allowMove: false,
    allowResize: false,
    // offset: const Offset(320, 457),
    offset: const Offset(0, 0),
    size: const Size(20, 20),
    child: Container(width: 15, height: 15, color: Colors.transparent),
    isSensory: 1,
  );
  InfiniteCanvasNode nodeGreenLed = InfiniteCanvasNode(
    key: UniqueKey(),
    value: 11,
    allowMove: false,
    allowResize: false,
    // offset: const Offset(395, 437),
    offset: const Offset(0, 0),
    size: const Size(20, 20),
    // child: Container(width: 15, height: 15, color: const Color(0xFF18A953)),
    child: Container(width: 15, height: 15, color:  Colors.transparent),
    isSensory: 1,
  );
  InfiniteCanvasNode nodeBlueLed = InfiniteCanvasNode(
    key: UniqueKey(),
    value: 12,
    allowMove: false,
    allowResize: false,
    // offset: const Offset(470, 457),
    offset: const Offset(0, 0),
    size: const Size(20, 20),
    child: Container(width: 15, height: 15, color: Colors.transparent),
    isSensory: 1,
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

  double? prevInitialFrameGapWidth;
  double? prevInitialFrameGapHeight;
  double initialFrameGapWidth = 870.0;
  double initialFrameGapHeight = 600.0;
  double currentFrameGapWidth = 870.0;
  double currentFrameGapHeight = 600.0;

  double initialWindowWidth = 870.0;
  double initialWindowHeight = 600.0;
  Size initialMinimumSize = const Size(600, 600);

  double prevWindowWidth = 870.0;
  double prevWindowHeight = 600.0;
  double windowWidth = 870.0;
  double windowHeight = 600.0;

  double? prevImageWidth;
  double? prevImageHeight;
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
  void dispose() async {
    windowManager.removeListener(this);
    detector?.stop();
    _imageDetectorSubscription?.cancel();

    printDebug("DISPOSEEE");
    freeUsedMemory();
    tecAWeight.dispose();
    tecBWeight.dispose();
    tecCWeight.dispose();
    tecDWeight.dispose();
    tecFrequencyWeight.dispose();
    tecSynapticWeight.dispose();
    tecSynapticWeightR.dispose();
    tecSynapticWeightG.dispose();
    tecSynapticWeightB.dispose();
    tecTimeValue.dispose();
    tecBrainDescription.dispose();
    tecBrainName.dispose();
    await windowManager
        .setSize(Size(initialWindowWidth, initialWindowHeight))
        .then((value) {});



    if (neuronOnTouchSource != null) {
      await soloud?.disposeSource(neuronOnTouchSource!);
      neuronOnTouchHandle = null;
    }  
    if (neuronSpikesSource != null) {
      await soloud?.disposeSource(neuronSpikesSource!);
      neuronSpikesHandle = null;
    }  
    if (axonStretchSource != null) {
      await soloud?.disposeSource(axonStretchSource!);
      axonStretchHandle = null;
    }  

    if (objectPlacedSource != null) {
      await soloud?.disposeSource(objectPlacedSource!);  
      objectPlacedHandle = null;
    }
    if (buttonOnPressedSource != null) {
      await soloud?.disposeSource(buttonOnPressedSource!);
      buttonOnPressedHandle = null;
    }
    if (buttonPopSource != null) {
      await soloud?.disposeSource(buttonPopSource!);
      buttonPopHandle = null;
    }    
    if (eraseSource != null) {
      await soloud?.disposeSource(eraseSource!);  
      eraseHandle = null;
    }
    if (pageFlipSource != null) {
      await soloud?.disposeSource(pageFlipSource!);  
      pageFlipHandle = null;
    }
    super.dispose();

    // ignore: avoid_print
  }

  void freeUsedMemory() {
    // freeMemory(npsBuf);
    // freeMemory(neuronCircleBuf);
    // freeMemory(positionsBuf);
    // freeMemory(aBuf);
    // freeMemory(bBuf);
    // freeMemory(cBuf);
    // freeMemory(dBuf);
    // freeMemory(iBuf);
    // freeMemory(wBuf);
    // freeMemory(connectomeBuf);
    // freeMemory(motorCommandBuf);
    // freeMemory(visPrefsBuf);
    // freeMemory(visPrefsValsBuf);
    // freeMemory(Nativec.canvasBuffer1);
    // // freeMemory(nativec.canvasBuffer2);
    // freeMemory(mapNeuronTypeBuf);
    // freeMemory(mapDelayNeuronBuf);
    // freeMemory(mapRhytmicNeuronBuf);
    // freeMemory(mapCountingNeuronBuf);
  }

  Future<String> startWebSocket() async {
    // const String webSocketLink = 'ws://192.168.4.1:81/ws';
    const String webSocketLink = 'ws://192.168.4.1:80/ws';
    // if (!isIsolateWritePortInitialized) {
    if (webSocket == null) {
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
          isolateWritePort.send("INIT_WEBSOCKET");
          isIsolateWritePortInitialized = true;
          // Timer.periodic(const Duration(milliseconds: 300), (timer) {
          //   isolateWritePort.send("test from flutter");
          // });
        } else if (message == "RESTART") {
          isIsolateWritePortInitialized = false;
          printDebug("RESTart");
          try {
            // writePort.close();
            // webSocket.kill();
          } catch (err) {
            printDebug("err disconnected");
            printDebug(err);
          }

          Future.delayed(const Duration(milliseconds: 1000), () async {
            if (isPlayingMenu) {
              startWebSocket();
              mjpegComponent = Mjpeg(
                error: (context, error, stack) {
                  return const Text("\r\nNot connected\r\nto SpikerBot\r\nWiFi",
                      style: TextStyle(fontSize: 10, color: Colors.brown));
                },
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
            // writePort.close();
            // webSocket.kill();
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
              // writePort.close();
              // webSocket.kill();
            } catch (err) {
              printDebug("err disconnected");
              printDebug(err);
            }
          }

          try {
            if (kIsWeb) {
              // js.context.callMethod("stopThreadProcess", [0]);
            } else {
              // nativec.stopThreadProcess(0);
              isSimulatingBrain = false;
              printDebug("stopping thread finished");
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
          if (message.indexOf("V") >= 0) {
            strFirmwareVersion = message;
            return;
          }
          if (flagSerialDataLength > 0) {
            strSerialDataBuff = "";
            flagSerialDataLength = -1;
          }

          mutexDistance.protectWrite(() async {
            strSerialDataBuff += (message + ";");
            return "";
          });

          try {
            List<String> arr = message.split(",");
            distanceBufView[0] = int.parse(arr[2]).toDouble();
            int baseBottomBattery = int.parse(arr[3]) - 590;
            batteryPercent = (baseBottomBattery / 278 * 100).floor();
            if (batteryPercent > 100) {
              batteryPercent = 100;
            } else if (batteryPercent <= 0) {
              batteryPercent = 0;
            }
            String batteryPercentage = "${(batteryPercent).floor()}%";
            batteryVoltage = "${int.parse(arr[3]).toDouble()} ($batteryPercentage)";
            setState(() {});
          } catch (err) {
            printDebug("err websocket");
            // flutter: err websocket
            // flutter: 0,0,24
            // flutter: RangeError (index): Invalid value: Not in inclusive range 0..2: 3
            printDebug(message);
            printDebug(err);
          }
        }
      });
    } else {
      printDebug("REOPEN WEBSOCKET");
      isolateWritePort.send("INIT_WEBSOCKET");
      isIsolateWritePortInitialized = true;
    }
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
            // printDebug("results");
            // printDebug(results);
            aiStats = values['stats'];
            aiObjectsInfo.clear();
            if (results!.isNotEmpty) {
              aiStats?["Confidence Score"] =
                  '${results?[0].label} - ${results?[0].score}';
              // '${results?[0].label} - ${results?[0].score}';
              results?.forEach((res) {
                if (res.score > 0.6) {
                  aiObjectsInfo[res.label] = res;
                }
              });
            }

            //[Recognition(id: 0, label: banana, score: 0.7578125, location: Rect.fromLTRB(45.7, 89.0, 239.0, 241.5)), Recognition(id: 1, label: banana, score: 0.5390625, location: Rect.fromLTRB(150.9, 110.2, 234.4, 235.4)), Recognition(id: 2, label: banana, score: 0.5234375, location: Rect.fromLTRB(121.7, 98.1, 205.1, 238.1))]
          });
          // printDebug("AI Visual Input Cancel");

          for (int i = 0; i < aiTypeLength; i++) {
            visPrefsValsBufView[7 + i] = 0;
            visPrefsValsBufView[7 + i + rightEyeConstant] = 0;
            for (int jNeuron = normalNeuronStartIdx + 2;
                jNeuron < neuronSize + 2;
                jNeuron++) {
              visualInputBufView[7 + i + (jNeuron - 2) * VisualInputLength] = 0;
            }
          }

          if (results != null && results!.isNotEmpty) {
            int detectionLength = results!.length;
            // int detectionLength = 1;
            // for (int i = 0; i < 1; i++) {
            for (int i = 0; i < detectionLength; i++) {
              if (results![i].score < 0.6) continue;
              int foundIdx = cameraMenuTypes.indexOf(results![i].label.trim());
              // reset value
              // set new value
              isShowingLeftAiMenu = false;
              isShowingRightAiMenu = false;
              for (String key in mapSensoryNeuron.keys) {
                Recognition r = results![i];
                List<String> modes = mapAreaSize[key].split("_@_");
                bool flag = containImage(r.location, modes);
                // printDebug("containImage(r.location, modes)");
                // printDebug(flag);
                // printDebug(key);
                // printDebug(foundIdx);
                // printDebug(key.contains(nodeLeftEyeSensor.key.toString()));
                if (key.contains(nodeLeftEyeSensor.key.toString()) &&
                    flag &&
                    foundIdx >= 7) {
                  // check if the option set == TFLite result
                  if (mapSensoryNeuron[key] == foundIdx) {
                    visPrefsValsBufView[foundIdx] = results![i].score * 50;
                    for (int jNeuron = normalNeuronStartIdx + 2;
                        jNeuron < neuronSize + 2;
                        jNeuron++) {
                      // it is inside Camera Region/Zone
                      int jNeuronIdx = jNeuron - 2;
                      String nodeId = controller.nodes[jNeuron].id;
                      if (key.contains(nodeId)) {
                        printDebug("======Contain Image & contain node");
                        printDebug(key);
                        printDebug(nodeId);
                        printDebug(r.location);

                        visualInputBufView[
                                foundIdx + jNeuronIdx * VisualInputLength] =
                            results![i].score * 50;
                        printDebug("foundIdx + jNeuronIdx * VisualInputLength");
                        printDebug(foundIdx);
                        printDebug(jNeuronIdx * VisualInputLength);
                      }
                    }
                  }
                  isShowingLeftAiMenu = true;
                }
                // if (key.contains(nodeRightEyeSensor.key.toString()) &&
                //     containImage(r.location, 1)) {
                //   if (mapSensoryNeuron[key] == foundIdx) {
                //     visPrefsValsBufView[foundIdx + rightEyeConstant] =
                //         results![i].score * 50;
                //   }
                //   isShowingRightAiMenu = true;
                // }
              }
            }
          }
          debouncerAIClassification.run(() {
            // printDebug("AI Visual Input run");
            for (int i = 0; i < aiTypeLength; i++) {
              visPrefsValsBufView[7 + i] = 0;
              visPrefsValsBufView[7 + i + rightEyeConstant] = 0;
              for (int jNeuron = 0; jNeuron < neuronSize; jNeuron++) {
                visualInputBufView[7 + i + jNeuron * VisualInputLength] = 0;
              }
            }
            // printDebug(visPrefsValsBufView);
          });
        });
      });

      // Future.delayed(const Duration(milliseconds: 500), () {
      //   detector?.processFrame(bananaImage);
      // });
    });
  }

  @override
  void onWindowEvent(String eventName) {
    // printDebug('[WindowManager] onWindowEvent: $eventName');
  }

  @override
  void onWindowEnterFullScreen() {
    isInitialized = false;
    isResizingFlag = true;
    // repositionContactNeurons();
    // controller.dropTargets = (getDragTargets());
    // centerZoneOffset = Offset(currentImageWidth / 2 + neuronDrawSize,
    //     currentImageHeight / 3 + neuronDrawSize);
    // printDebug("Full Screen : centerZoneOffset");
    // printDebug(centerZoneOffset);
    setState(() {});
  }

  @override
  void onWindowLeaveFullScreen() {
    isInitialized = false;
    isResizingFlag = true;
    return;

    printDebug("Leave Full Screen");
    printDebug(MediaQuery.of(context).size.width);
    printDebug(MediaQuery.of(context).size.height);
    isInitialized = false;
    if (Platform.isWindows || Platform.isMacOS || kIsWeb) {
      // double tempWidth = 800;
      // double tempHeight = 600;
      // if (Platform.isWindows) {
      //   tempWidth = 870;
      //   tempHeight = 600;
      // }
      // windowManager.setSize(Size(tempWidth, tempHeight)).then((_) {
      // isPortrait = false;
      repositionContactNeurons();

      controller.dropTargets = (getDragTargets());
      // Future.delayed(const Duration(microseconds: 300), () {
      setState(() {});
      // });
    }
    // simulateClick(10, 10);
    setState(() {});
  }

  @override
  void onWindowUnmaximize() {
    isPortrait = false;
    repositionContactNeurons();

    controller.dropTargets = (getDragTargets());
    // Future.delayed(const Duration(microseconds: 300), () {
    setState(() {});
  }

  @override
  void onWindowMaximize() {
    // super.onWindowMaximize();
    printDebug("onWindowMaximize");
    repositionContactNeurons();
    controller.dropTargets = (getDragTargets());
    setState(() {});
  }

  // @override
  // void onWindowResize () {
  //   printDebug("onWindowResize");
  //   // get the current window size
  //   windowWidth = MediaQuery.of(context).size.width;
  //   windowHeight = MediaQuery.of(context).size.height;
  //   // calculate imageSize
  //   final Size containerSize =
  //       Size(windowWidth, windowHeight); // Replace with your container size
  //   // Size imageSize = const Size(600, 600); // Replace with your image size
  //   Size imageSize = initialMinimumSize; // Replace with your image size
  //   if (Platform.isIOS || Platform.isAndroid) {
  //     double minimumSize = min(windowHeight, windowWidth);
  //     imageSize = Size(minimumSize, minimumSize);
  //   }

  //   final fittedSizes = applyBoxFit(BoxFit.contain, imageSize, containerSize);
  //   // reposition nodes
  //   // double scaleX = windowWidth / prevWindowWidth;
  //   // double scaleY = windowHeight / prevWindowHeight;
  //   // printDebug("fittedSizes.destination.width");
  //   // printDebug(fittedSizes.destination.width);
  //   // printDebug("fittedSizes.destination.height");
  //   // printDebug(fittedSizes.destination.height);
  //   double scaleX = fittedSizes.destination.width / imageSize.width;
  //   double scaleY = fittedSizes.destination.height / imageSize.height;
  //   printDebug("Scale X");
  //   printDebug(scaleX);
  //   printDebug("Scale Y");
  //   printDebug(scaleY);

  //   viewPortNode.update(offset: Offset(windowWidth, windowHeight));
  //   controller.getNode(viewportKey)?.offset = Offset(windowWidth, windowHeight);
  //   // int idx = 0;

  //   constraintOffsetTopLeft = Offset(
  //       constraintOffsetBottomLeftRaw.dx, constraintOffsetBottomLeftRaw.dy);
  //   constraintOffsetTopRight =
  //       Offset(constraintOffsetTopRightRaw.dx, constraintOffsetTopRightRaw.dy);
  //   constraintOffsetBottomRight = Offset(
  //       constraintOffsetBottomRightRaw.dx, constraintOffsetBottomRightRaw.dy);
  //   constraintOffsetBottomLeft = Offset(
  //       constraintOffsetBottomLeftRaw.dx, constraintOffsetBottomLeftRaw.dy);

  //   constraintOffsetTopLeft = constraintOffsetTopLeft.scale(scaleX, scaleY);
  //   constraintOffsetTopRight = constraintOffsetTopRight.scale(scaleX, scaleY);
  //   constraintOffsetBottomRight =
  //       constraintOffsetBottomRight.scale(scaleX, scaleY);
  //   constraintOffsetBottomLeft =
  //       constraintOffsetBottomLeft.scale(scaleX, scaleY);

  //   constraintBrainLeft = constraintOffsetTopLeft.dx;
  //   constraintBrainRight = constraintOffsetTopRight.dx;
  //   constraintBrainTop = constraintOffsetTopLeft.dy;
  //   constraintBrainBottom = constraintOffsetBottomLeft.dy;
  //   int idx = 0;
  //   for (var element in controller.nodes) {
  //     if (idx > 1) {
  //       element.offset = element.offset.scale(scaleX, scaleY);
  //     }
  //     idx++;
  //   }
  //   currentImageWidth = windowWidth;
  //   currentImageHeight = windowHeight;
  // }

  @override
  void initState() {
    super.initState();
    soloud = SoLoud.instance;
    Future.delayed(const Duration(milliseconds: 1000), () async {

      await soloud?.init().then((_) async {
        await soloud?.loadAsset('assets/audio/NeuronOnTouch.mp3').then((src){ // 1
          neuronOnTouchSource = src;
        });
        await soloud?.loadAsset('assets/audio/NeuronSpikes.mp3').then((src){ // 2
          neuronSpikesSource = src;
        });
        await soloud?.loadAsset('assets/audio/AxonStretch.mp3').then((src){ // 3
          axonStretchSource = src;
          // if (leftToolBar != null) {
          //   leftToolBar.setSource(src);
          // }
        });

        await soloud?.loadAsset('assets/audio/ObjectPlaced.mp3').then((src){ // 4
          objectPlacedSource = src;
        });
        await soloud?.loadAsset('assets/audio/ButtonOnPress.mp3').then((src){ // 5
          buttonOnPressedSource = src;
        });

        await soloud?.loadAsset('assets/audio/ButtonPop.mp3').then((src){ // 6
          buttonPopSource = src;
        });
        await soloud?.loadAsset('assets/audio/Erase.mp3').then((src){ // 7
          eraseSource = src;
        });
        await soloud?.loadAsset('assets/audio/PageFlip.mp3').then((src){ // 8
          pageFlipSource = src;
        });

        // soloud.loadAsset('assets/audio/test.mp3').then((src){
        //   neuronOnTouchSource = src;
        // });

      });
    });

    windowManager.addListener(this);
    initImageDetector();

    if (Platform.isIOS || Platform.isAndroid) {
      neuronDrawSize = 17;
    }
    pMapStatus["isSavingBrain"] = 1;
    pMapStatus["currentFileName"] = "-";

    String capturePath = Platform.pathSeparator + "capture";
    String versionPath =
        "${Platform.pathSeparator}spikerbot${Platform.pathSeparator}version";
    getApplicationDocumentsDirectory().then((documentDirectory) async {
      captureDirectory = Directory("${documentDirectory.path}$capturePath");
      versionDirectory = Directory("${documentDirectory.path}$versionPath");
      captureDirectory = Directory("${documentDirectory.path}$capturePath");
      Directory spikerbotDirectory = Directory(
          "${documentDirectory.path}${Platform.pathSeparator}spikerbot");
      if (!spikerbotDirectory.existsSync()) spikerbotDirectory.createSync();

      if (!versionDirectory.existsSync()) {
        versionDirectory.createSync();
        File versionFile =
            File("$versionPath${Platform.pathSeparator}currentVersion.txt");
        if (!versionFile.existsSync()) {
          versionFile.createSync();
        }
      }
      if (!captureDirectory.existsSync()) {
        captureDirectory.createSync();
        List<String> arrLessonPlan = [
          // "BrainText1724733907587233@@@L1E1-Sensor@@@Sensory information can lead to action.txt",
          // "BrainText1724746973005942@@@L1E2-Follow Targets@@@Produce life-like goal-directed behaviors.txt",
          // "BrainText1724747399306156@@@L1E3-Moving Robot@@@Using spontaneous bursts neuron to perform 'random walks'.txt",
          // "BrainText1724748009573259@@@L1E4-Sees Cup@@@How brain is responding, and demonstrating object recognition.txt",
          // "BrainText1725503995473512@@@L2E3@@@WinnerTakeAll.txt",
        ];
        // String L1E1 =
        //     "BrainText1724733907587233@@@L1E1-Sensor@@@Sensory information can lead to action.txt";
        arrLessonPlan.forEach((savedFileName) async {
          String data =
              await rootBundle.loadString("assets/saved/$savedFileName");
          String textDirectoryPath =
              "${documentDirectory.path}${Platform.pathSeparator}spikerbot${Platform.pathSeparator}text${Platform.pathSeparator}";
          Directory textDir = Directory(textDirectoryPath);
          if (!textDir.existsSync()) {
            textDir.createSync();
          }
          File resultFile = File("$textDirectoryPath$savedFileName");
          if (!resultFile.existsSync()) {
            resultFile.writeAsStringSync(data);
          }
        });
      }
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
    printDebug("INIT STATEEE");
    try {
      initMemoryAllocation();
      initNativeC(true);
      // final ocsvlib = ocv.OpenCVBindings(ffi.DynamicLibrary.open(_getPath()));
      // testColorCV();
      printDebug("INIT STATEEE2");

      // Uint8List lowerB = ptrLowerB.asTypedList(3);
      // Uint8List upperB = ptrUpperB.asTypedList(3);

      // //RED
      // lowerB[0] = 0;
      // lowerB[1] = 43;
      // lowerB[2] = 46;
      // upperB[0] = 0;
      // upperB[1] = 255;
      // upperB[2] = 255;

      // // GREEN
      // lowerB[0] = 36;
      // lowerB[1] = 25;
      // lowerB[2] = 25;
      // upperB[0] = 86;
      // upperB[1] = 255;
      // upperB[2] = 255;

      // rootBundle.load("assets/bg/ObjectColorRange.jpeg").then((raw) async {
      //   Uint8List redBg = raw.buffer.asUint8List();
      //   try {
      //     // freeMemory(ptrFrame);
      //     // freeMemory(ptrMaskedFrame);
      //   } catch (err) {}

      //   printDebug(redBg.length);
      //   ptrFrame = allocate<ffi.Uint8>(
      //       count: redBg.length, sizeOfType: ffi.sizeOf<ffi.Uint8>());
      //   if (!isCheckingColor) {
      //     Future.delayed(const Duration(milliseconds: 300), () {});
      //   }
      // });
      // });
    } catch (err) {
      printDebug("err Memory Allocation");
      printDebug(err);
    }

    processor = ImagePreprocessor();
    processor.isRunning = true;
    mjpegComponent = Mjpeg(
      error: (context, error, stack) {
        return const Text("\r\nNot connected\r\nto SpikerBot\r\nWiFi",
            style: TextStyle(fontSize: 10, color: Colors.brown));
      },

      stream: httpdStream,
      // stream: "http://192.168.1.4:8081/",
      preprocessor: processor,
      width: 320 / 2,
      height: 240 / 2,
      // width: 320,
      // height: 240,

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
        // printDebug("redraw");
        // printDebug(Nativec.canvasBufferBytes1);
        waveRedraw.value = Random().nextInt(10000);
      }
      if (isPlayingMenu) {
        // for (int i = circleNeuronStartIndex - allNeuronStartIdx; i < neuronSize; i++) {
        // printDebug("neuronCircleBridge");
        // printDebug(neuronCircleBridge);
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
                printDebug(err);
              }
            }
          }
        } catch (err) {
          printDebug(err);
        }
        */
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // printDebug("BUILD WIDGET");
    if (packageInfo == null) {
      Future.delayed(const Duration(milliseconds: 10), () async {
        packageInfo = await PackageInfo.fromPlatform();
        await subscribeGeneralConfig();
      });
      prevScreenWidth = MediaQuery.of(context).size.width;
      prevScreenHeight = MediaQuery.of(context).size.height;
    }
    screenWidth = MediaQuery.of(context).size.width;
    screenHeight = MediaQuery.of(context).size.height;

    if (isPortrait == null) {
      isPortrait = MediaQuery.of(context).orientation == Orientation.portrait;
      isInitialized = false;
      isReorientation = true;
      prevConstrainedFlag = true;
      prevConstrainedPos = Offset.zero;
    } else {
      if (isPortrait == true) {
        // current screen is not portrait
        if (MediaQuery.of(context).orientation != Orientation.portrait) {
          controller.zoomReset();
          isPortrait = false;
          isInitialized = false;
          isReorientation = true;
          prevConstrainedFlag = true;
          prevConstrainedPos = Offset.zero;
        }
      } else if (isPortrait == false) {
        // current screen is not landscape
        if (MediaQuery.of(context).orientation != Orientation.landscape) {
          controller.zoomReset();

          isPortrait = true;
          isInitialized = false;
          isReorientation = true;
          prevConstrainedFlag = true;
          prevConstrainedPos = Offset.zero;
        }
      }
    }

    if (isInitialized) {
    } else {
      // default image size for platforms that has width more bigger than height
      initializeFrame();
    }

    // screenDensity = MediaQuery.of(context).devicePixelRatio;

    safePadding = MediaQuery.of(context).padding.right;
    // aspectRatio = MediaQuery.of(context).devicePixelRatio;
    // Future.delayed(const Duration(milliseconds: 2000), (){
    //   repositionSensoryNeuron();
    // });
    if (prevScreenWidth != screenWidth) {
      isResizingFlag = true;
      isInitialized = false;
    }
    if (prevScreenHeight != screenHeight) {
      isResizingFlag = true;
      isInitialized = false;
    }

    if (!isInitialized) {
      // && screenWidth > screenHeight
      printDebug("INIT CANVAS");
      if (!isControllerInitialized) {
        initCanvas();
        isControllerInitialized = true;
      }
      isInitialized = true;

      // RESIZE
      List<Offset> oldDifCamera = [];
      Offset oldDifCoreBrain = Offset.zero;
      Offset oldCoreBrainPos = Offset(brainPosition.dx, brainPosition.dy);
      Offset oldCameraNodePos =
          Offset(nodeLeftEyeSensor.offset.dx, nodeLeftEyeSensor.offset.dy);
      // Offset oldCameraNodePos = const Offset(0, 0);
      int len = controller.nodes.length;
      for (int i = normalNeuronStartIdx + 2; i < len; i++) {
        oldDifCamera.add(controller.nodes[i].offset - oldCameraNodePos);
        // printDebug("DISTANCE BETWEEN OLD NODE DISTANCE");
        // printDebug(oldCameraNodePos);
        // printDebug(controller.nodes[i].offset);
        // printDebug(controller.nodes[i].offset - oldCameraNodePos);
      }
      oldDifCoreBrain = oldCoreBrainPos - oldCameraNodePos;

      repositionContactNeurons();
      print("repositionContactNeurons");

      Offset newCameraNodePos =
          Offset(nodeLeftEyeSensor.offset.dx, nodeLeftEyeSensor.offset.dy);
      // Offset newCameraNodePos = const Offset(0, 0);

      len = controller.nodes.length;
      // Offset gapDifference = Offset(
      //     prevInitialFrameGapWidth! - currentFrameGapWidth,
      //     prevInitialFrameGapHeight! - currentFrameGapHeight);
      double scaleX = currentImageWidth / prevImageWidth!;
      double scaleY = currentImageHeight / prevImageHeight!;
      // double scaleX = screenWidth / prevScreenWidth;
      // double scaleY = screenHeight / prevScreenHeight;
      printDebug("ScaleX: $scaleX - ScaleY: $scaleY");
      tailNode.offset = const Offset(0, 0);
      if (Platform.isIOS || Platform.isAndroid) {
        int start = normalNeuronStartIdx + 2;
        for (int i = normalNeuronStartIdx + 2; i < len; i++) {
          int idx = i - start;
          Offset diff = newCameraNodePos + oldDifCamera[idx];
          // printDebug("DISTANCE BETWEEN NEW NODE DISTANCE");
          // printDebug("newCameraNodePos :$newCameraNodePos");
          // printDebug(oldDifCamera[idx]);
          // printDebug("diff: $diff");
          // // printDebug(gapDifference.scale(0.5, 0.5));
          // // diff = diff - gapDifference.scale(0.5, 0.5);
          // printDebug("diff: $diff");
          // printDebug(
          //     "$prevScreenWidth ${prevInitialFrameGapWidth!} - $currentFrameGapWidth");
          controller.nodes[i].offset = Offset(diff.dx, diff.dy);
        }
      } else {
        int start = normalNeuronStartIdx + 2;
        for (int i = start; i < len; i++) {
          int idx = i - start;
          Offset diff =
              newCameraNodePos + oldDifCamera[idx].scale(scaleX, scaleY);
          controller.nodes[i].offset = Offset(diff.dx, diff.dy);

          // controller.nodes[i].offset =
          //     controller.nodes[i].offset.scale(scaleX, scaleY);
        }
        if (isResizingFlag) {
          brainPosition =
              newCameraNodePos + oldDifCoreBrain.scale(scaleX, scaleY);
        }
        print("brainPosition");
        print(brainPosition);
        print(isResizingFlag);
        print(screenWidth);
        print(screenHeight);
        print("$newCameraNodePos + ${oldDifCoreBrain.scale(scaleX, scaleY)}");
      }

      centerZoneOffset = Offset(currentImageWidth / 2 + neuronDrawSize,
          currentImageHeight / 3 + neuronDrawSize);
      // printDebug("centerZoneOffset");
      // printDebug(centerZoneOffset);

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
    // if (isInitialized) {
    //   if (prevScreenWidth != screenWidth) {
    //     isResizingFlag = true;
    //   }
    //   if (prevScreenHeight != screenHeight) {
    //     isResizingFlag = true;
    //   }
    // }

    // }
    // STEVANUS :
    // remove this
    if (isResizingFlag) {
      centerZoneOffset = Offset(initialWindowWidth / 3 + neuronDrawSize,
          initialWindowHeight / 2 + neuronDrawSize);

      // initialWindowWidth = MediaQuery.of(context).size.width;
      // initialWindowHeight = MediaQuery.of(context).size.height;
      // double minimumSize = min(initialWindowWidth, initialWindowHeight);
      // initialMinimumSize = Size(minimumSize, minimumSize);

      viewPortNode.update(offset: Offset(screenWidth, screenHeight));
      controller.getNode(viewportKey)?.offset =
          Offset(screenWidth, screenHeight);
      // double scaleX = screenWidth / prevScreenWidth;
      // double scaleX = screenWidth / prevScreenWidth;
      // if (Platform.isIOS || Platform.isAndroid) {
      //   scaleX = 1;
      // }
      // double scaleY = screenHeight / prevScreenHeight;

      // constraintOffsetTopLeft = constraintOffsetTopLeft.scale(scaleX, scaleY);
      // constraintOffsetTopRight = constraintOffsetTopRight.scale(scaleX, scaleY);
      // constraintOffsetBottomRight =
      //     constraintOffsetBottomRight.scale(scaleX, scaleY);
      // constraintOffsetBottomLeft =
      //     constraintOffsetBottomLeft.scale(scaleX, scaleY);

      // constraintBrainLeft = constraintOffsetTopLeft.dx;
      // constraintBrainRight = constraintOffsetTopRight.dx;
      // constraintBrainTop = constraintOffsetTopLeft.dy;
      // constraintBrainBottom = constraintOffsetBottomLeft.dy;

      // Future.delayed(const Duration(milliseconds: 1000), () {
      repositionContactNeurons();
      currentFrameGapWidth =
          MediaQuery.of(context).size.width - currentImageWidth;
      currentFrameGapHeight =
          MediaQuery.of(context).size.height - currentImageHeight;
      // printDebug(
      //     "isResizingFlag ${MediaQuery.of(context).size.width} ${MediaQuery.of(context).size.height} :::: $initialFrameGapWidth - $initialFrameGapHeight @@@@@ $currentFrameGapWidth-$currentFrameGapHeight !!!!!");

      // int idx = 0;
      // for (var element in controller.nodes) {
      //   if (idx > 13) {
      //     element.offset = element.offset.scale(scaleX, scaleY);
      //   }
      //   idx++;
      // }
      isResizingFlag = false;
      if (isPlayingMenu) {
        List<Offset> pos = [];

        // Map<String, int> nodeKey = {};
        int idx = 0;
        for (InfiniteCanvasNode node in controller.nodes) {
          if (idx >= allNeuronStartIdx) {
            pos.add(node.offset);
            // nodeKey[node.key.toString()] = idx - allNeuronStartIdx;
            // nodeKey[idx] = node.key.toString();
          }
          idx++;
        }

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
        if (controller.isPlaying) {
          initializeNucleus();
        }
      }

      // controller.dropTargets.clear();
      controller.dropTargets = (getDragTargets());
      setState(() {});
      // });

      // printDebug("isResizingFlag");
      // printDebug(isResizingFlag);

      prevScreenWidth = screenWidth;
      prevScreenHeight = screenHeight;
      if (isDrawTail) {
        isDrawTail = false;
      }
    } else {
      if (isInitialized) {
        // Future.delayed(const Duration(milliseconds: 100), () {
        controller.dropTargets.clear();
        controller.dropTargets.addAll(getDragTargets());
        // });
        setState(() {});
      }
    }

    List<Widget> widgets = [];
    if (isPlayingMenu) {
      // for (int i = circleNeuronStartIndex - allNeuronStartIdx; i < neuronSize; i++) {
      // /* //CHANGED TO NUCLEUS
      for (int i = 0; i < normalNeuronStartIdx; i++) {
        SingleNeuron neuron = protoNeuron.circles[i];
        widgets.add(Positioned(
          top: neuron.centerPos.dy - 10,
          left: neuron.centerPos.dx - 10,
          child: SizedBox(
            key: neuronCircleKeys[i],
            // child: ValueListenableBuilder(
            //   valueListenable: neuronSpikeFlags[i],
            //   builder: ((context, value, child) {
            //     if (protoNeuron.circles[i].isSpiking == -1) {
            //       // return squareInactiveCircles[i];
            //       return const SizedBox();
            //     } else {
            //       return squareActiveCircles[i];
            //     }
            //   }),
            // ),
          ),
        ));
      }
      Offset pan = controller
          .getOffset()
          .scale(1 / controller.getScale(), 1 / controller.getScale());
      // printDebug("zpan");
      // printDebug(pan);
      for (int i = normalNeuronStartIdx; i < neuronSize; i++) {
        SingleNeuron neuron = protoNeuron.circles[i];
        widgets.add(Positioned(
          top: neuron.centerPos.dy - pan.dy,
          left: neuron.centerPos.dx - pan.dx,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () {
              // nativec.changeIdxSelected(i);
              controller.deselectAll();
              controller.select(controller.nodes[i + 2].key);

              isChartSelected = true;
            },
            child: SizedBox(
              width: neuronDrawSize,
              height: neuronDrawSize,
              // key: neuronCircleKeys[i],
              // child: ValueListenableBuilder(
              //   valueListenable: neuronSpikeFlags[i],
              //   builder: ((context, value, child) {
              //     if (protoNeuron.circles[i].isSpiking == -1) {
              //       return neuronInactiveCircles[i];
              //     } else {
              //       return neuronActiveCircles[i];
              //     }
              //   }),
              // ),
            ),
          ),
        ));
      }
      // */
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
                return Container(
                  color: const Color(0xFF1996FC),
                  width: screenWidth,
                  height: screenHeight,
                  child: SvgPicture.asset(
                      width: screenWidth,
                      height: screenHeight,
                      // scale: screenWidth/800,
                      fit: BoxFit.contain,
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
    double bottomChart = 100;
    double bottomPad = 0;
    if (Platform.isIOS) {
      bottomPad = 20;
    }
    double bottomBattery = 20;
    // @New Design
    // if (modeIdx == -1) {
    //   dragTargetWidgets = [];
    // }
    if (isPlayingMenu) {
      if (!isChartSelected) {
        // inlineWidgets.add(Positioned(
        //   bottom: 100,
        //   right: 17 + safePadding,
        //   child: ElevatedButton(
        //     style: ElevatedButton.styleFrom(
        //       minimumSize: const Size(56, 56),
        //       maximumSize: const Size(76, 76),
        //       elevation: 7,
        //       shape: RoundedRectangleBorder(
        //           borderRadius: BorderRadius.circular(10.0),
        //           side: const BorderSide(color: Colors.transparent)),
        //       padding: Platform.isMacOS || Platform.isWindows
        //           ? const EdgeInsets.symmetric(horizontal: 15, vertical: 22)
        //           : const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
        //     ),
        //     child: const Icon(Icons.stacked_line_chart_rounded,
        //         color: Colors.black),
        //     onPressed: () {
        //       isChartSelected = true;
        //       setState(() {});
        //     },
        //   ),
        // ));

        inlineWidgets.add(Positioned(
          bottom: 100,
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
        /*
        inlineWidgets.add(Positioned(
          // bottom: MediaQuery.of(context).size.height / 2 - 130,
          bottom: 20,
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
        ));*/
        // inlineWidgets.add(Positioned(
        //   bottom: MediaQuery.of(context).size.height / 2 - 130 + 50,
        //   right: 17 + safePadding,
        //   child: ElevatedButton(
        //     style: ElevatedButton.styleFrom(
        //       minimumSize: const Size(56, 56),
        //       // maximumSize: const Size(56, 56),
        //       elevation: 7,
        //       padding: Platform.isMacOS || Platform.isWindows
        //           ? const EdgeInsets.symmetric(horizontal: 15, vertical: 22)
        //           : const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
        //       backgroundColor: const Color(0xFF00ABFF),
        //       shape: RoundedRectangleBorder(
        //           borderRadius: BorderRadius.circular(10.0),
        //           side: const BorderSide(color: Colors.transparent)),
        //     ),
        //     child: const Icon(Icons.stacked_line_chart_rounded,
        //         color: Colors.black),
        //     onPressed: () {
        //       isChartSelected = false;
        //       setState(() {});
        //     },
        //   ),
        // ));
        inlineWidgets.add(Positioned(
          // bottom: MediaQuery.of(context).size.height / 2 - 110,
          bottom: 100,
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
                        tecTimeValue.text = sldTimeValue.floor().toString();
                        try {
                          InfiniteCanvasNode selected = controller.selection[0];
                          int neuronIdx = controller.nodes
                                  .map((e) => e.id)
                                  .toList()
                                  .indexOf(selected.id) -
                              2;
                          if (value == "Delay") {
                            isShowDelayTime = true;
                            sldTimeValue = 3000;
                            tecTimeValue.text = sldTimeValue.floor().toString();
                          } else if (value == "Custom") {
                            printDebug("dropDown change");
                            isShowDelayTime = false;
                            mapDelayNeuronList[neuronIdx] = -1;
                          } else {
                            isShowDelayTime = false;
                            mapDelayNeuronList[neuronIdx] = -1;
                            // sldTimeValue = 1000;
                          }

                          // nativec.changeIdxSelected(neuronIdx);
                          if (value == "Delay") {
                            mapDelayNeuronList[neuronIdx] =
                                sldTimeValue.floor();
                          }
                        } catch (err) {
                          printDebug("err 0");
                          printDebug(err);
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

                          if (value == "Excitatory") {
                            isTailType = "triangle";
                          } else {
                            isTailType = "circle";
                          }

                          if (value == "Excitatory") {
                            selected.isExcitatory = 1;
                          } else {
                            selected.isExcitatory = 0;
                          }

                          for (InfiniteCanvasEdge edge in controller.edges) {
                            if (edge.from.toString() == selected.id) {
                              final neuronFrom = findNeuronByKey(edge.from);
                              if (value == "Excitatory") {
                                neuronFrom.isExcitatory = 1;
                              } else {
                                neuronFrom.isExcitatory = 0;
                              }
                            }
                          }

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
                              child: Focus(
                                onFocusChange: (hasFocus) {
                                  if (!hasFocus) {
                                    submitWeightA(tecAWeight.text);
                                  }
                                },
                                child: TextField(
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true, signed: true),
                                  inputFormatters:
                                      neuronListingTextInputFormatter,
                                  maxLines: 1,
                                  controller: tecAWeight,
                                  onSubmitted: submitWeightA,
                                ),
                              ),
                            ),
                            Expanded(
                              child: SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  activeTrackColor: colorOrange,
                                  showValueIndicator: ShowValueIndicator.never,
                                  thumbColor: Colors.white,
                                  thumbShape: const RoundSliderThumbShape(
                                      enabledThumbRadius: 15),
                                  trackHeight: 15,
                                ),
                                child: Listener(
                                  onPointerDown: (details){
                                    printDebug("details");
                                    printDebug(details);
                                  },
                                  child: Slider(
                                    value: sldAWeight,
                                    min: 0,
                                    max: 0.15,
                                    divisions: 15,
                                    label: sldAWeight.round().toString(),
                                    onChangeStart: (value) async {
                                      if (buttonOnPressedSource != null) {
                                        buttonOnPressedHandle = await soloud?.play(buttonOnPressedSource!, looping: false);
                                      }
                                    },
                                    onChangeEnd: (value) async {
                                      if (buttonPopSource != null) {
                                        buttonOnPressedHandle = await soloud?.play(buttonPopSource!, looping: false);
                                      }
                                    },
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
                              child: Focus(
                                onFocusChange: (hasFocus) {
                                  if (!hasFocus) {
                                    submitWeightB(tecBWeight.text);
                                  }
                                },
                                child: TextField(
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true, signed: true),
                                  inputFormatters:
                                      neuronListingTextInputFormatter,
                                  maxLines: 1,
                                  controller: tecBWeight,
                                  onSubmitted: submitWeightB,
                                ),
                              ),
                            ),
                            Expanded(
                              child: SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  activeTrackColor: colorOrange,
                                  showValueIndicator: ShowValueIndicator.never,
                                  thumbColor: Colors.white,
                                  thumbShape: const RoundSliderThumbShape(
                                      enabledThumbRadius: 15),
                                  trackHeight: 15,
                                ),
                                child: Slider(
                                  value: sldBWeight,
                                  min: 0,
                                  max: 0.5,
                                  divisions: 100,
                                  label: sldBWeight.round().toString(),
                                  onChangeStart: (value) async {
                                    if (buttonOnPressedSource != null) {
                                      buttonOnPressedHandle = await soloud?.play(buttonOnPressedSource!, looping: false);
                                    }
                                  },
                                  onChangeEnd: (value) async {
                                    if (buttonPopSource != null) {
                                      buttonOnPressedHandle = await soloud?.play(buttonPopSource!, looping: false);
                                    }
                                  },
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
                              child: Focus(
                                onFocusChange: (hasFocus) {
                                  if (!hasFocus) {
                                    submitWeightC(tecCWeight.text);
                                  }
                                },
                                child: TextField(
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true, signed: true),
                                  inputFormatters:
                                      neuronListingTextInputFormatter,
                                  maxLines: 1,
                                  controller: tecCWeight,
                                  onSubmitted: submitWeightC,
                                ),
                              ),
                            ),
                            Expanded(
                              child: SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  activeTrackColor: colorOrange,
                                  showValueIndicator: ShowValueIndicator.never,
                                  thumbColor: Colors.white,
                                  thumbShape: const RoundSliderThumbShape(
                                      enabledThumbRadius: 15),
                                  trackHeight: 15,
                                ),
                                child: Slider(
                                  value: sldCWeight,
                                  min: -100,
                                  max: 0,
                                  divisions: 100,
                                  label: sldCWeight.round().toString(),
                                  onChangeStart: (value) async {
                                    if (buttonOnPressedSource != null) {
                                      buttonOnPressedHandle = await soloud?.play(buttonOnPressedSource!, looping: false);
                                    }
                                  },
                                  onChangeEnd: (value) async {
                                    if (buttonPopSource != null) {
                                      buttonOnPressedHandle = await soloud?.play(buttonPopSource!, looping: false);
                                    }
                                  },
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
                              child: Focus(
                                onFocusChange: (hasFocus) {
                                  if (!hasFocus) {
                                    submitWeightD(tecDWeight.text);
                                  }
                                },
                                child: TextField(
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true, signed: true),
                                  inputFormatters:
                                      neuronListingTextInputFormatter,
                                  maxLines: 1,
                                  controller: tecDWeight,
                                  onSubmitted: submitWeightD,
                                ),
                              ),
                            ),
                            Expanded(
                              child: SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  activeTrackColor: colorOrange,
                                  showValueIndicator: ShowValueIndicator.never,
                                  thumbColor: Colors.white,
                                  thumbShape: const RoundSliderThumbShape(
                                      enabledThumbRadius: 15),
                                  trackHeight: 15,
                                ),
                                child: Slider(
                                  value: sldDWeight,
                                  min: 0,
                                  max: 10,
                                  divisions: 10,
                                  label: sldDWeight.round().toString(),
                                  onChangeStart: (value) async {
                                    if (buttonOnPressedSource != null) {
                                      buttonOnPressedHandle = await soloud?.play(buttonOnPressedSource!, looping: false);
                                    }
                                  },
                                  onChangeEnd: (value) async {
                                    if (buttonPopSource != null) {
                                      buttonOnPressedHandle = await soloud?.play(buttonPopSource!, looping: false);
                                    }
                                  },
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
                              child: Focus(
                                onFocusChange: (hasFocus) {
                                  printDebug("hasFocus");
                                  printDebug(hasFocus);
                                  printDebug(tecTimeValue.text);
                                  if (!hasFocus) {
                                    submitDelayConnection(tecTimeValue.text);
                                  }
                                },
                                child: TextField(
                                  enabled: true,
                                  keyboardType: TextInputType.number,
                                  inputFormatters:
                                      whiteListingTextInputFormatter,
                                  maxLines: 1,
                                  controller: tecTimeValue,
                                  onSubmitted: submitDelayConnection,
                                ),
                              ),
                            ),
                            Expanded(
                              child: SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  activeTrackColor: colorOrange,
                                  showValueIndicator: ShowValueIndicator.never,
                                  thumbColor: Colors.white,
                                  thumbShape: const RoundSliderThumbShape(
                                      enabledThumbRadius: 15),
                                  trackHeight: 15,
                                ),
                                child: Slider(
                                  value: sldTimeValue,
                                  max: maxDelayTimeValue.toDouble(),
                                  min: minDelayTimeValue.toDouble(),
                                  divisions: 49,
                                  // label: maxDelayTimeValue.round().toString(),
                                  onChangeStart: (value) async {
                                    if (buttonOnPressedSource != null) {
                                      buttonOnPressedHandle = await soloud?.play(buttonOnPressedSource!, looping: false);
                                    }
                                  },
                                  onChangeEnd: (value) async {
                                    if (buttonPopSource != null) {
                                      buttonOnPressedHandle = await soloud?.play(buttonPopSource!, looping: false);
                                    }
                                  },

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
      List<ButtonStyle> cameraButtonStyles = cameraRegions.map((region) {
        return ElevatedButton.styleFrom(
          foregroundColor: selectedCameraPosition == region
              ? Colors.black
              : Colors.grey, // Adjust colors as needed
          backgroundColor: selectedCameraPosition == region
              ? const Color(0xFFF0AB91)
              : Colors.white,
        );
      }).toList();
      List<Color> cameraButtonBgColors = cameraRegions.map((region) {
        return 
          selectedCameraPosition == region
              ? const Color(0xFFF0AB91)
              : Colors.white;
      }).toList();
      List<Color> cameraButtonFgColors = cameraRegions.map((region) {
        return 
          selectedCameraPosition == region
              ? Colors.black
              : Colors.grey;
      }).toList();

      if (!isSelectingCameraTarget) {
        InfiniteCanvasNode selected =
            findNeuronByKey(controller.edgeSelected.to);
        int idx = neuronTypes.keys.toList().indexOf(selected.id);

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
                        padding: EdgeInsets.fromLTRB(0, 0, 0, 0),
                        child: Text(
                          "Select Camera Target and Area",
                          // activeCameraType,
                          textAlign: TextAlign.end,
                          style: TextStyle(
                            fontSize: 17,
                          ),
                        ),
                      ),
                      const Divider(height: 2),
                      Row(
                        children: [
                          Material(
                            elevation: 3,
                            borderRadius: BorderRadius.circular(20),
                            color: cameraButtonBgColors[0],
                            child: InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTapDown: (details) async {
                                if (buttonOnPressedSource != null) {
                                  buttonOnPressedHandle = await soloud?.play(buttonOnPressedSource!, looping: false);
                                }
                              },
                              onTapUp: (details) async {
                                if (buttonPopSource != null) {
                                  buttonOnPressedHandle = await soloud?.play(buttonPopSource!, looping: false);
                                }
                                selectedCameraPosition = "Left";
                                linkAreaSizeConnection(
                                    selectedCameraPosition:
                                        selectedCameraPosition);
                                setState(() {});
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
                                child: Center(child: Text("Left", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: cameraButtonFgColors[0]),)),
                              ),
                            ),
                          ),                          
                          // ElevatedButton(
                          //     style: cameraButtonStyles[0],
                          //     onPressed: () {
                          //     },
                          //     child: const Text("Left")),
                          const SizedBox(width: 10),
                          Material(
                            elevation: 3,
                            borderRadius: BorderRadius.circular(20),
                            color: cameraButtonBgColors[1],
                            child: InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTapDown: (details) async {
                                if (buttonOnPressedSource != null) {
                                  buttonOnPressedHandle = await soloud?.play(buttonOnPressedSource!, looping: false);
                                }
                              },
                              onTapUp: (details) async {
                                if (buttonPopSource != null) {
                                  buttonOnPressedHandle = await soloud?.play(buttonPopSource!, looping: false);
                                }
                                selectedCameraPosition = "Any";
                                linkAreaSizeConnection(
                                    selectedCameraPosition:
                                        selectedCameraPosition);
                                setState(() {});
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
                                child: Center(child: Text("Any", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: cameraButtonFgColors[1]),)),
                              ),
                            ),
                          ),
                          // ElevatedButton(
                          //     style: cameraButtonStyles[1],
                          //     onPressed: () {

                          //     },
                          //     child: const Text("Any")),
                          const SizedBox(width: 10),
                          Material(
                            elevation: 3,
                            borderRadius: BorderRadius.circular(20),
                            color: cameraButtonBgColors[2],
                            child: InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTapDown: (details) async {
                                if (buttonOnPressedSource != null) {
                                  buttonOnPressedHandle = await soloud?.play(buttonOnPressedSource!, looping: false);
                                }
                              },
                              onTapUp: (details) async {
                                if (buttonPopSource != null) {
                                  buttonOnPressedHandle = await soloud?.play(buttonPopSource!, looping: false);
                                }
                                selectedCameraPosition = "Right";
                                linkAreaSizeConnection(
                                    selectedCameraPosition:
                                        selectedCameraPosition);
                                setState(() {});
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
                                child: Center(child: Text("Right", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: cameraButtonFgColors[2]),)),
                              ),
                            ),
                          ),
                          // ElevatedButton(
                          //     style: cameraButtonStyles[2],
                          //     onPressed: () {
                          //       selectedCameraPosition = "Right";
                          //       linkAreaSizeConnection(
                          //           selectedCameraPosition:
                          //               selectedCameraPosition);
                          //       setState(() {});
                          //     },
                          //     child: const Text("Right")),
                          const SizedBox(width: 10),
                          Material(
                            elevation: 3,
                            borderRadius: BorderRadius.circular(20),
                            color: cameraButtonBgColors[3],
                            child: InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTapDown: (details) async {
                                if (buttonOnPressedSource != null) {
                                  buttonOnPressedHandle = await soloud?.play(buttonOnPressedSource!, looping: false);
                                }
                              },
                              onTapUp: (details) async {
                                if (buttonPopSource != null) {
                                  buttonOnPressedHandle = await soloud?.play(buttonPopSource!, looping: false);
                                }
                                selectedCameraPosition = "Custom";
                                linkAreaSizeConnection(
                                    selectedCameraPosition:
                                        selectedCameraPosition);
                                setState(() {});
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
                                child: Center(child: Text("Custom", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: cameraButtonFgColors[3]),)),
                              ),
                            ),
                          ),                          
                          // ElevatedButton(
                          //     style: cameraButtonStyles[3],
                          //     onPressed: () {
                          //       selectedCameraPosition = "Custom";
                          //       linkAreaSizeConnection(
                          //           selectedCameraPosition:
                          //               selectedCameraPosition);

                          //       setState(() {});
                          //     },
                          //     child: const Text("Custom")),
                        ],
                      ),
                      Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            SizedBox(
                              width: 170,
                              height: 135,
                              child: Column(
                                children: [
                                  const Text("Target",
                                      style: TextStyle(
                                        fontSize: 17,
                                        color: Colors.black,
                                      )),
                                  const SizedBox(height: 10),
                                  generateTargetWidgets({
                                    "icon": selectedEyeInfo["icon"],
                                    "label": selectedEyeInfo["label"],
                                    "idx": selectedEyeInfo["idx"]
                                  }, 0),
                                ],
                              ),
                            ),
                            SizedBox(
                              width: 180,
                              height: 135,
                              child: Column(
                                children: [
                                  const Text("Active Area",
                                      style: TextStyle(
                                        fontSize: 17,
                                        color: Colors.black,
                                      )),
                                  const SizedBox(
                                    height: 10,
                                  ),
                                  if (selectedCameraPosition == "Left") ...[
                                    generateCameraArea(
                                        true, false, false, false)
                                  ],
                                  if (selectedCameraPosition == "Right") ...[
                                    generateCameraArea(
                                        false, true, false, false)
                                  ],
                                  if (selectedCameraPosition == "Any") ...[
                                    generateCameraArea(
                                        false, false, true, false)
                                  ],
                                  if (selectedCameraPosition == "Custom") ...[
                                    generateCameraArea(
                                        false, false, false, true)
                                  ],
                                  // generateRightArea(),
                                ],
                              ),
                            ),
                          ]),
                      if (selectedCameraPosition == "Custom") ...[
                        // const Text("Active Area Size",
                        //     style: TextStyle(fontSize: 17)),
                        SizedBox(
                          // width: MediaQuery.of(context).size.width / 3,
                          width: 350,
                          child: Row(mainAxisSize: MainAxisSize.max, children: [
                            SizedBox(
                              width: 40,
                              height: 40,
                              child: TextField(
                                textAlign: TextAlign.center,
                                controller: txtAreaSizeMinController,
                                keyboardType: TextInputType.number,
                                inputFormatters: whiteListingTextInputFormatter,
                                maxLines: 1,
                                onSubmitted: (str) {
                                  // printDebug("123");
                                  if (str.trim() == "") {
                                    str = minDistanceSlider.toString();
                                  }

                                  if (double.tryParse(str) != null) {
                                    double val = double.parse(str);
                                    areaSizeMinLimitBufView[idx] = val.toInt();
                                    if (areaSizeMinLimitBufView[idx] >=
                                        maxAreaSizeSlider) {
                                      areaSizeMinLimitBufView[idx] =
                                          ((areaSizeMaxLimitBufView[idx] - 1) >
                                                      0
                                                  ? (areaSizeMaxLimitBufView[
                                                          idx] -
                                                      1)
                                                  : minAreaSizeSlider)
                                              .toInt();
                                    } else if (areaSizeMinLimitBufView[idx] <=
                                        0) {
                                      areaSizeMinLimitBufView[idx] =
                                          minAreaSizeSlider.toInt();
                                    } else if (areaSizeMinLimitBufView[idx] >=
                                        areaSizeMaxLimitBufView[idx]) {
                                      areaSizeMinLimitBufView[idx] =
                                          areaSizeMinLimitBufView[idx].toInt();
                                    }

                                    txtAreaSizeMinController.text =
                                        areaSizeMinLimitBufView[idx].toString();
                                  } else {
                                    str = minAreaSizeSlider.toString();
                                  }

                                  // linkDistanceConnection(distanceMenuType);
                                  linkAreaSizeConnection(
                                      selectedCameraPosition:
                                          selectedCameraPosition);
                                  setState(() {});
                                },
                              ),
                            ),
                            const SizedBox(
                              width: 3,
                            ),
                            SizedBox(
                              width: 260,
                              child: FlutterSlider(
                                values: [
                                  // 1,
                                  // 100
                                  areaSizeMinLimitBufView[idx].toDouble(),
                                  areaSizeMaxLimitBufView[idx].toDouble()
                                ],
                                rangeSlider: true,
                                min: minAreaSizeSlider,
                                max: maxAreaSizeSlider,
                                rightHandler: FlutterSliderHandler(
                                  child: const Icon(
                                    Icons.chevron_left,
                                    color: Colors.grey,
                                    size: 24,
                                  ),
                                ),
                                trackBar: FlutterSliderTrackBar(
                                  inactiveTrackBarHeight: 20,
                                  activeTrackBarHeight: 20,
                                  inactiveTrackBar: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    color: Colors.black12,
                                    border: Border.all(
                                        width: 3,
                                        color: const Color(0xFF1996FC)),
                                  ),
                                  activeTrackBar: BoxDecoration(
                                    borderRadius: BorderRadius.circular(4),
                                    color: colorOrange,
                                  ),
                                ),
                                onDragStarted: (a,b,c ) async {
                                  if (buttonOnPressedSource != null) {
                                    buttonOnPressedHandle = await soloud?.play(buttonOnPressedSource!, looping: false);
                                  }
                                },
                                onDragCompleted: (a,b,c ) async {
                                  if (buttonPopSource != null) {
                                    buttonOnPressedHandle = await soloud?.play(buttonPopSource!, looping: false);
                                  }
                                },
                                
                                onDragging:
                                    (handlerIndex, lowerValue, upperValue) {
                                  areaSizeMinLimitBufView[idx] =
                                      lowerValue.toInt();
                                  areaSizeMaxLimitBufView[idx] =
                                      upperValue.toInt();
                                  txtAreaSizeMinController.text =
                                      areaSizeMinLimitBufView[idx].toString();
                                  txtAreaSizeMaxController.text =
                                      areaSizeMaxLimitBufView[idx].toString();

                                  // linkDistanceConnection(distanceMenuType);
                                  linkAreaSizeConnection(
                                      selectedCameraPosition:
                                          selectedCameraPosition);
                                  setState(() {});
                                },
                              ),
                            ),
                            const SizedBox(
                              width: 3,
                            ),
                            SizedBox(
                              width: 40,
                              height: 40,
                              child: TextField(
                                textAlign: TextAlign.center,
                                controller: txtAreaSizeMaxController,
                                keyboardType: TextInputType.number,
                                inputFormatters: whiteListingTextInputFormatter,
                                maxLines: 1,
                                onSubmitted: (str) {
                                  if (str.trim() == "") {
                                    str = maxAreaSizeSlider.toString();
                                  }

                                  if (double.tryParse(str) != null) {
                                    double val = double.parse(str);
                                    areaSizeMaxLimitBufView[idx] = val.toInt();
                                    if (areaSizeMaxLimitBufView[idx] >=
                                        maxAreaSizeSlider) {
                                      areaSizeMaxLimitBufView[idx] =
                                          maxAreaSizeSlider.toInt();
                                    } else if (areaSizeMaxLimitBufView[idx] ==
                                        0) {
                                      areaSizeMaxLimitBufView[idx] =
                                          minAreaSizeSlider.toInt();
                                    } else if (areaSizeMaxLimitBufView[idx] <=
                                        areaSizeMinLimitBufView[idx]) {
                                      areaSizeMaxLimitBufView[idx] =
                                          maxAreaSizeSlider.toInt();
                                    }

                                    txtAreaSizeMaxController.text =
                                        areaSizeMaxLimitBufView[idx].toString();
                                  } else {
                                    str = maxAreaSizeSlider.toString();
                                  }
                                  printDebug("asd");
                                  // linkDistanceConnection(distanceMenuType);
                                  linkAreaSizeConnection(
                                      selectedCameraPosition:
                                          selectedCameraPosition);
                                  setState(() {});
                                },
                              ),
                            ),
                          ]),
                        ),
                      ],
                      // DropdownButton(
                      //   alignment: Alignment.centerRight,
                      //   style: const TextStyle(
                      //     fontSize: 17.0,
                      //     color: Colors.black,
                      //   ),
                      //   underline: Container(
                      //     height: 1,
                      //   ),
                      //   value: cameraMenuType,
                      //   items: dropdownCameraItems,
                      //   onChanged: (value) {
                      //     cameraMenuType = value;
                      //     linkSensoryConnection(cameraMenuType);
                      //     setState(() {});
                      //   },
                      // ),
                      isShowingInfo == 1 ?
                        Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.white, width: 2),
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
                                const SizedBox(
                                  width: 10,
                                  height: 10,
                                ),
                                const SizedBox(
                                  width: 300,
                                  child: Text(
                                    "NEURON SPIKES when target is in the orange active area of camera.",
                                    style: TextStyle(
                                      fontFamily: "BybHanddrawn",
                                    ),
                                    maxLines: 2,
                                  ),
                                ),
                              ],
                            )
                      :
                        const SizedBox(),

                      const SizedBox(
                        width: 10,
                        height: 10,
                      ),
                    ],
                  ),
                ),
              )),
        );
      } else {
        List<Widget> targetWidgets = [];
        int idx = 0;
        searchCameraTargetTextField = SearchTextField(
            hintText: "Search by name or emoji",
            controller: tecSearchCameraTarget,
            onChanged: (str) {
              searchCameraTarget = str;
              print("searchCameraTarget");
              print(searchCameraTarget);
              setState(() {});
            });

        for (String menuType in cameraMenuTypes) {
          if (!menuType.contains("(side)") &&
              ("color".contains(searchCameraTarget.toLowerCase()) ||
                  menuType.contains(searchCameraTarget.toLowerCase()) ||
                  searchCameraTarget == "")) {
            String menuLabel = menuType;
            if (menuType == "Red" ||
                menuType == "Green" ||
                menuType == "Blue") {
              menuType = "Color $menuType";
              print("menuType");
              print(menuType);
              targetWidgets.add(generateTargetWidgets(
                  {"icon": menuLabel, "label": menuType, "idx": "0"}, idx));
            } else if (lookup[menuType] != null) {
              if (searchCameraTarget.isNotEmpty &&
                  "color".contains(searchCameraTarget.toLowerCase())) {
                if (menuType.contains(searchCameraTarget)) {
                  menuLabel = lookup[menuType]!;
                  targetWidgets.add(generateTargetWidgets(
                      {"icon": menuLabel, "label": menuType, "idx": "0"}, idx));
                }
              } else {
                menuLabel = lookup[menuType]!;
                targetWidgets.add(generateTargetWidgets(
                    {"icon": menuLabel, "label": menuType, "idx": "0"}, idx));
              }
            }
            idx++;
          }
        }
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
                              padding: EdgeInsets.fromLTRB(0, 0, 22, 0),
                              child: Text(
                                "Select Camera Target",
                                // activeCameraType,
                                textAlign: TextAlign.end,
                                style: TextStyle(
                                  fontSize: 17,
                                ),
                              ),
                            ),
                            const Divider(height: 2),
                            SizedBox(
                              width: MediaQuery.of(context).size.width / 3,
                              height: 70,
                              child: searchCameraTargetTextField,
                            ),
                            const Divider(height: 2),
                            SizedBox(
                                width: MediaQuery.of(context).size.width / 3,
                                height: 200,
                                child: GridView.count(
                                  crossAxisCount: 3,
                                  children: targetWidgets,
                                ))
                          ])))),
        );
      }
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
                            height: 40,
                            child: TextField(
                              textAlign: TextAlign.center,
                              controller: txtDistanceMinController,
                              keyboardType: TextInputType.number,
                              inputFormatters: whiteListingTextInputFormatter,
                              maxLines: 1,
                              onSubmitted: (str) {
                                // printDebug("123");
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
                                  border: Border.all(
                                      width: 3, color: const Color(0xFF1996FC)),
                                ),
                                activeTrackBar: BoxDecoration(
                                    borderRadius: BorderRadius.circular(4),
                                    color: colorOrange),
                              ),
                              onDragStarted: (a,b,c ) async {
                                if (buttonOnPressedSource != null) {
                                  buttonOnPressedHandle = await soloud?.play(buttonOnPressedSource!, looping: false);
                                }
                              },
                              onDragCompleted: (a,b,c ) async {
                                if (buttonPopSource != null) {
                                  buttonOnPressedHandle = await soloud?.play(buttonPopSource!, looping: false);
                                }
                              },
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
                            height: 40,
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
                                printDebug("asd");
                                linkDistanceConnection(distanceMenuType);
                                setState(() {});
                              },
                            ),
                          ),
                        ]
                      ],
                    ),
                    isShowingInfo == 1 ?
                      Row(
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
                                child: Text(
                                  distanceSensorContent,
                                  style: const TextStyle(
                                    fontFamily: "BybHanddrawn",
                                  ),
                                  maxLines: 2,
                                ),
                              ),
                            ],
                          )
                      :
                      const SizedBox(),

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
                            child: Focus(
                              onFocusChange: (hasFocus) {
                                if (!hasFocus) {
                                  submitFrequencyConnection(
                                      tecFrequencyWeight.text);
                                }
                              },
                              child: TextField(
                                keyboardType: TextInputType.number,
                                inputFormatters: whiteListingTextInputFormatter,
                                maxLines: 1,
                                controller: tecFrequencyWeight,
                                onSubmitted: submitFrequencyConnection,
                              ),
                            ),
                          ),
                          Expanded(
                            child: SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                activeTrackColor: colorOrange,
                                showValueIndicator: ShowValueIndicator.never,
                                thumbColor: Colors.white,
                                thumbShape: const RoundSliderThumbShape(
                                    enabledThumbRadius: 15),
                                trackHeight: 15,
                              ),
                              child: Slider(
                                value: sldFrequencyWeight,
                                min: isSpeakerMenu ? 3 : 0,
                                max: isSpeakerMenu ? 4978 : 5000,
                                divisions: isSpeakerMenu ? 4978 : 5000,
                                label: sldFrequencyWeight.round().toString(),
                                onChangeStart: (v) async {
                                  if (buttonOnPressedSource != null) {
                                    buttonOnPressedHandle = await soloud?.play(buttonOnPressedSource!, looping: false);
                                  }
                                },
                                onChangeEnd: (v ) async {
                                  if (buttonPopSource != null) {
                                    buttonOnPressedHandle = await soloud?.play(buttonPopSource!, looping: false);
                                  }
                                },

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
                            child: Focus(
                              onFocusChange: (hasFocus) {
                                if (!hasFocus) {
                                  printDebug("synaptic on focusleave");
                                  submitSynapticConnection(
                                      tecSynapticWeight.text);
                                }
                              },
                              child: TextField(
                                keyboardType: TextInputType.number,
                                inputFormatters: whiteListingTextInputFormatter,
                                maxLines: 1,
                                controller: tecSynapticWeight,
                                onSubmitted: submitSynapticConnection,
                              ),
                            ),
                          ),
                          Expanded(
                            child: SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                activeTrackColor: colorOrange,
                                showValueIndicator: ShowValueIndicator.never,
                                thumbColor: Colors.white,
                                thumbShape: const RoundSliderThumbShape(
                                    enabledThumbRadius: 15),
                                trackHeight: 15,
                              ),
                              child: Slider(
                                value: sldSynapticWeight,
                                max: 100,
                                divisions: 100,
                                label: sldSynapticWeight.round().toString(),
                                onChangeStart: (val) async {
                                  if (buttonOnPressedSource != null) {
                                    buttonOnPressedHandle = await soloud?.play(buttonOnPressedSource!, looping: false);
                                  }
                                },
                                onChangeEnd: (val) async {
                                  if (buttonPopSource != null) {
                                    buttonOnPressedHandle = await soloud?.play(buttonPopSource!, looping: false);
                                  }
                                },
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
                            child: Focus(
                                onFocusChange: (hasFocus) {
                                  if (!hasFocus) {
                                    // submitLedConnection(tecSynapticWeightR.text);
                                    InfiniteCanvasEdge selectedEdge = controller.edgeSelected;
                                    InfiniteCanvasNode neuronFrom = findNeuronByKey(selectedEdge.from);
                                    submitLedAxon(tecSynapticWeightR.text, neuronFrom, nodeRedLed);
                                  }
                                },
                                child: TextField(
                                  keyboardType: TextInputType.number,
                                  inputFormatters:
                                      whiteListingTextInputFormatter,
                                  maxLines: 1,
                                  controller: tecSynapticWeightR,
                                  onSubmitted: (val){
                                    printDebug("val");
                                    printDebug(val);
                                    InfiniteCanvasEdge selectedEdge = controller.edgeSelected;
                                    InfiniteCanvasNode neuronFrom = findNeuronByKey(selectedEdge.from);
                                    submitLedAxon(val, neuronFrom, nodeRedLed);
                                  },
                                )),
                          ),
                          Expanded(
                            child: SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                // activeTrackColor: colorOrange,
                                activeTrackColor: Colors.red,
                                
                                thumbColor: Colors.white,
                                overlayShape: SliderComponentShape.noOverlay,
                                showValueIndicator: ShowValueIndicator.never,
                                thumbShape: const RoundSliderThumbShape(
                                    enabledThumbRadius: 10),
                                trackHeight: 10,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.only(top:10.0),
                                child: Slider(
                                  value: sldSynapticWeightR,
                                  max: 100,
                                  divisions: 100,
                                  label: sldSynapticWeightR.round().toString(),
                                  onChangeStart: (val) async {
                                    if (buttonOnPressedSource != null) {
                                      buttonOnPressedHandle = await soloud?.play(buttonOnPressedSource!, looping: false);
                                    }
                                  },
                                  onChangeEnd: (val) async {
                                    if (buttonPopSource != null) {
                                      buttonOnPressedHandle = await soloud?.play(buttonPopSource!, looping: false);
                                    }
                                  },
                                  onChanged: (double value) {
                                    try {
                                      sldSynapticWeightR = value.roundToDouble();
                                      tecSynapticWeightR.text = value.round().toString();
                                      InfiniteCanvasEdge selectedEdge = controller.edgeSelected;
                                      InfiniteCanvasNode neuronFrom = findNeuronByKey(selectedEdge.from);
                                      linkLedAxon(sldSynapticWeightR, neuronFrom, nodeRedLed);
                                
                                      setState(() {});
                                    } catch (err) {
                                      printDebug("err slider LED $err");
                                    }
                                
                                    setState(() {});
                                  },
                                ),
                              ),
                            ),
                          ),
                          Container(
                            width: 45,
                            margin: const EdgeInsets.only(top:10),
                            child: const Text("Red", textAlign: TextAlign.center,),
                          ),

                        ],
                      ),
                    ),
                    SizedBox(
                      width: MediaQuery.of(context).size.width / 4,
                      // height: MediaQuery.of(context).size.width / 4,
                      child: Row(
                        children: [
                          SizedBox(
                            width: 30,
                            height: 40,
                            child: Focus(
                                onFocusChange: (hasFocus) {
                                  if (!hasFocus) {
                                    InfiniteCanvasEdge selectedEdge = controller.edgeSelected;
                                    InfiniteCanvasNode neuronFrom = findNeuronByKey(selectedEdge.from);
                                    submitLedAxon(tecSynapticWeightG.text, neuronFrom, nodeGreenLed);
                                    // submitLedConnection(tecSynapticWeightG.text);
                                  }
                                },
                                child: TextField(
                                  keyboardType: TextInputType.number,
                                  inputFormatters:
                                      whiteListingTextInputFormatter,
                                  maxLines: 1,
                                  controller: tecSynapticWeightG,
                                  onSubmitted: (val){
                                    InfiniteCanvasEdge selectedEdge = controller.edgeSelected;
                                    InfiniteCanvasNode neuronFrom = findNeuronByKey(selectedEdge.from);
                                    submitLedAxon(val, neuronFrom, nodeGreenLed);
                                  },
                                )),
                          ),
                          Expanded(
                            child: SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                // activeTrackColor: colorOrange,
                                activeTrackColor: Colors.green,
                                thumbColor: Colors.white,
                                overlayShape: SliderComponentShape.noOverlay,
                                showValueIndicator: ShowValueIndicator.never,
                                thumbShape: const RoundSliderThumbShape(
                                    enabledThumbRadius: 10),
                                trackHeight: 10,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.only(top:10.0),
                                child: Slider(
                                  value: sldSynapticWeightG,
                                  max: 100,
                                  divisions: 100,
                                  label: sldSynapticWeightG.round().toString(),
                                  onChangeStart: (val) async {
                                    if (buttonOnPressedSource != null) {
                                      buttonOnPressedHandle = await soloud?.play(buttonOnPressedSource!, looping: false);
                                    }
                                  },
                                  onChangeEnd: (val) async {
                                    if (buttonPopSource != null) {
                                      buttonOnPressedHandle = await soloud?.play(buttonPopSource!, looping: false);
                                    }
                                  },
                                  onChanged: (double value) {
                                    try {
                                      sldSynapticWeightG = value.roundToDouble();
                                      tecSynapticWeightG.text =
                                          value.round().toString();
                                      InfiniteCanvasEdge selectedEdge = controller.edgeSelected;
                                      InfiniteCanvasNode neuronFrom = findNeuronByKey(selectedEdge.from);
                                      linkLedAxon(sldSynapticWeightG, neuronFrom, nodeGreenLed);
                                
                                      setState(() {});
                                    } catch (err) {
                                      printDebug("err slider");
                                    }
                                
                                    setState(() {});
                                  },
                                ),
                              ),
                            ),
                          ),
                          Container(
                            width: 45,
                            margin: const EdgeInsets.only(top:10),
                            child: const Text("Green", textAlign: TextAlign.center),
                          ),
                        
                        ],
                      ),
                    ),

                    SizedBox(
                      width: MediaQuery.of(context).size.width / 4,
                      // height: MediaQuery.of(context).size.width / 4,
                      child: Row(
                        children: [
                          SizedBox(
                            width: 30,
                            height: 40,
                            child: Focus(
                                onFocusChange: (hasFocus) {
                                  if (!hasFocus) {
                                    // submitLedConnection(tecSynapticWeightB.text);
                                    InfiniteCanvasEdge selectedEdge = controller.edgeSelected;
                                    InfiniteCanvasNode neuronFrom = findNeuronByKey(selectedEdge.from);
                                    submitLedAxon(tecSynapticWeightB.text, neuronFrom, nodeBlueLed);
                                  }
                                },
                                child: TextField(
                                  keyboardType: TextInputType.number,
                                  inputFormatters:
                                      whiteListingTextInputFormatter,
                                  maxLines: 1,
                                  controller: tecSynapticWeightB,
                                  onSubmitted: (val){
                                    InfiniteCanvasEdge selectedEdge = controller.edgeSelected;
                                    InfiniteCanvasNode neuronFrom = findNeuronByKey(selectedEdge.from);
                                    // submitLedAxon(val, selectedEdge.from, nodeBlueLed);
                                    submitLedAxon(val, neuronFrom, nodeBlueLed);
                                  },
                                )),
                          ),
                          Expanded(
                            child: SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                // activeTrackColor: colorOrange,
                                activeTrackColor: Colors.blue,
                                thumbColor: Colors.white,
                                overlayShape: SliderComponentShape.noOverlay,
                                showValueIndicator: ShowValueIndicator.never,
                                thumbShape: const RoundSliderThumbShape(
                                    enabledThumbRadius: 10),
                                trackHeight: 10,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.only(top:10.0),
                                child: Slider(
                                  value: sldSynapticWeightB,
                                  max: 100,
                                  divisions: 100,
                                  label: sldSynapticWeightB.round().toString(),
                                  onChangeStart: (val) async {
                                    if (buttonOnPressedSource != null) {
                                      buttonOnPressedHandle = await soloud?.play(buttonOnPressedSource!, looping: false);
                                    }
                                  },
                                  onChangeEnd: (val) async {
                                    if (buttonPopSource != null) {
                                      buttonOnPressedHandle = await soloud?.play(buttonPopSource!, looping: false);
                                    }
                                  },
                                  onChanged: (double value) {
                                    try {
                                      sldSynapticWeightB = value.roundToDouble();
                                      tecSynapticWeightB.text = value.round().toString();
                                      // linkLedConnection(sldSynapticWeightB);
                                      InfiniteCanvasEdge selectedEdge = controller.edgeSelected;
                                      InfiniteCanvasNode neuronFrom = findNeuronByKey(selectedEdge.from);
                                      linkLedAxon(sldSynapticWeightB, neuronFrom, nodeBlueLed);
                                
                                      setState(() {});
                                    } catch (err) {
                                      printDebug("err slider");
                                    }
                                
                                    setState(() {});
                                  },
                                ),
                              ),
                            ),
                          ),
                          Container(
                            width: 45,
                            margin: const EdgeInsets.only(top:10),
                            child: const Text("Blue", textAlign: TextAlign.center),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: MediaQuery.of(context).size.width / 4,
                      // height: MediaQuery.of(context).size.width / 4,
                      child: Row(
                        children: [

                          Form(
                      // key: formHexColorKey,
                            child: SizedBox(
                              width: MediaQuery.of(context).size.width / 10,
                              child: TextFormField(
                                textAlign: TextAlign.center,
                                maxLength: 6,
                                controller: tecHexColor,
                                decoration: const InputDecoration(
                                  prefixText: '\u200B#',
                                  hintText: "Hex Color Input",
                                  counterText: "",
                                ),
                                autovalidateMode: AutovalidateMode.always,
                                onChanged: (value) {
                                  bool isValid = true;
                                  if (value.isEmpty || value.length < 6) {
                                    isValid = false;
                                  } else {
                                    try{
                                      Map<String, int> color = hexToRgb("#$value");
                                    }catch(err) {
                                      isValid = false;
                                    }
                                  }
                                  if (isValid) {
                                    Map<String, int> color = hexToRgb("#${value!}");
                                    // printDebug("#$val , ${color["r"]},${color["g"]},${color["b"]}");
                                    sldSynapticWeightR = color["r"]!.toDouble() / 255 * 100;
                                    sldSynapticWeightG = color["g"]!.toDouble() / 255 * 100;
                                    sldSynapticWeightB = color["b"]!.toDouble() / 255 * 100;
                                    tecSynapticWeightR.text = sldSynapticWeightR.round().toString();
                                    tecSynapticWeightG.text = sldSynapticWeightG.round().toString();
                                    tecSynapticWeightB.text = sldSynapticWeightB.round().toString();
                                    // InfiniteCanvasNode neuronFrom = findNeuronByKey(controller.edgeSelected.from);
                                    // neuronFrom.syntheticNeuron.info = "INFO1";
                                    // print("neuronFrom.syntheticNeuron.neuronIdx");
                                    // print(neuronFrom.syntheticNeuron.neuronIdx);
                                    // printDebug("Colorized Neuron");
                                    // neuronFrom.syntheticNeuron.blackBrush = Paint()
                                    //   ..color = Color.fromARGB(255, color["r"]!, color["g"]!, color["b"]!)
                                    //   // ..color = Colors.yellow
                                    //   ..style = PaintingStyle.fill
                                    //   ..strokeWidth = 2;
                                    controller.edgeSelected.color = Color.fromARGB(255, color["r"]!, color["g"]!, color["b"]!);
                                    // neuronFrom.syntheticNeuron.recalculate(canvas)

                                    setState((){});

                                  }

                                  // Form.of(formHexColorKey).validate();
                                  // Form.of(primaryFocus!.context!).save();
                                },                          
                                validator: (value) {
                                  if (value == null || value.isEmpty || value.length < 6) {
                                    return 'Please enter valid hex color';
                                  } else {
                                    try{
                                      Map<String, int> color = hexToRgb("#$value");
                                    }catch(err) {
                                      return 'Please enter valid hex color';
                                    }
                                  }
                                  return null; // Return null if the input is valid
                                },
                                onSaved: (val){
                                }
                              ),
                            ),
                          ),
                          const Text("Hex Color Code"),
                        ]
                      )
                    ),
                    const Center(
                      child: Text("Active Lights"),
                    ),
                    Row(
                      children: [
                        Column(children: [
                          Checkbox(
                              activeColor: colorOrange,
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
                                        "${neuronFrom.id}_${nodeRedLed.id}"] =
                                    isActiveLeds.join();

                                setState(() {});
                              }),
                          const SizedBox(height: 25),
                          Checkbox(
                              activeColor: colorOrange,
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
                                        "${neuronFrom.id}_${nodeRedLed.id}"] =
                                    isActiveLeds.join();

                                setState(() {});
                              }),
                        ]),
                        const Text(
                          "🧠",
                          style: TextStyle(
                              fontFamily: "BybHanddrawn", fontSize: 27),
                        ),
                        Column(children: [
                          Checkbox(
                              activeColor: colorOrange,
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
                                        "${neuronFrom.id}_${nodeRedLed.id}"] =
                                    isActiveLeds.join();

                                setState(() {});
                              }),
                          const SizedBox(height: 25),
                          Checkbox(
                              activeColor: colorOrange,
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
                                        "${neuronFrom.id}_${nodeRedLed.id}"] =
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
        bottom: Platform.isIOS || Platform.isAndroid ? 105 : 15,
        left: 10,
        child: FloatingActionButton(
            focusColor: colorOrange,
            hoverColor: colorOrange,
            backgroundColor: colorOrange,
            shape: const CircleBorder(),
            hoverElevation: 1,
            elevation: 0,
            onPressed: () {
            },
            child: GestureDetector(
              onTapDown:(details) async {
                if (buttonOnPressedSource != null) {
                  buttonOnPressedHandle = await soloud?.play(buttonOnPressedSource!, looping: false);
                }
              },
              onTapUp:(details){
                if (isDrawTail) {
                  deleteNeuronCallback();
                  resetMouse();
                } else {
                  deleteEdgeCallback();
                  resetMouse();
                }
              },
              child: const Icon(
                size: 40,
                Icons.delete,
                color: Colors.black,
              ),
            )),
      ));
    }
    leftToolBar = LeftToolbar(
      key: rightToolbarKey,
      menuIdx: menuIdx,
      isPlaying: isPlayingMenu,
      callback: leftToolbarCallback);
    if (!isPlayingMenu) {
      if (leftToolBar != null) {
        toolbarMenu = Positioned(
          // right: 10 + safePadding,
          left: 0,
          top: 10,
          child: leftToolBar!,
        );
      } else {
        toolbarMenu = Positioned(
          // right: 10 + safePadding,
          left: 0,
          top: 10,
          child: Container(),
        );
      }
    }

    List<Widget> leftColorListWidget = [];
    // List<Widget> rightColorListWidget = [];
    List<Widget> leftAiListWidget = [];
    // List<Widget> rightAiListWidget = [];

    String aiLabelLeft = "";
    // String aiLabelRight = "";
    if (isInfoMenu) {
      // if (isShowingLeftAiMenu || isShowingRightAiMenu) {
      //   if (aiStats != null && aiStats!["Confidence Score"] != null) {
      //     String detectedObjectLabel =
      //         aiStats!["Confidence Score"]!.split("-")[0];
      //     if (isShowingLeftAiMenu) {
      //       aiLabelLeft = detectedObjectLabel;
      //     }
      //     // if (isShowingRightAiMenu) {
      //     //   aiLabelRight = detectedObjectLabel;
      //     // }
      //   }
      //   leftAiListWidget.add(Text(aiLabelLeft));
      //   // rightAiListWidget.add(Text(aiLabelRight));
      // } else {}
      // if (leftAiListWidget.isEmpty) {
      //   leftAiListWidget.add(const SizedBox(height: 20));
      // }

      if (isShowingLeftColorMenu || isShowingRightColorMenu) {
        // Row blueContainer = Row(
        //   children: [
        //     Container(
        //         width: 20,
        //         height: 20,
        //         decoration: const BoxDecoration(
        //           shape: BoxShape.circle,
        //           color: Colors.blue, // Replace with your desired color
        //         )),
        //     const Text("Blue"),
        //   ],
        // );
        // Row greenContainer = Row(
        //   children: [
        //     Container(
        //         width: 20,
        //         height: 20,
        //         decoration: const BoxDecoration(
        //           shape: BoxShape.circle,
        //           color: Colors.green, // Replace with your desired color
        //         )),
        //     const Text("Green"),
        //   ],
        // );
        // Row redContainer = Row(
        //   children: [
        //     Container(
        //         width: 20,
        //         height: 20,
        //         decoration: const BoxDecoration(
        //           shape: BoxShape.circle,
        //           color: Colors.red, // Replace with your desired color
        //         )),
        //     const Text("Red"),
        //   ],
        // );

        // int idx = 0;
        // List<bool> colorCameraPositionFlags = getCameraRegionFlag();
        // if (isShowingLeftColorMenu) {
        //   for (int i = 0; i < strLeftColorMenu.length; i++) {
        //     String c = strLeftColorMenu[i];
        //     int cameraPositionIdx =
        //         cameraRegions.indexOf(selectedCameraPosition);
        //     print("strLeftColorMenu");
        //     print(strLeftColorMenu);
        //     if (c == '1' &&
        //         colorPositionFlags[idx] &&
        //         colorCameraPositionFlags[i * 4 + cameraPositionIdx]) {
        //       if (idx == 0) {
        //         leftColorListWidget.add(blueContainer);
        //       }
        //       if (idx == 1) {
        //         leftColorListWidget.add(greenContainer);
        //       }
        //       if (idx == 2) {
        //         leftColorListWidget.add(redContainer);
        //       }
        //     }
        //     idx++;
        //   }
        // }
        // if (leftColorListWidget.isEmpty) {
        //   leftColorListWidget.add(const SizedBox(height: 20));
        // }
        // if (isShowingRightColorMenu) {
        //   idx = 0;
        //   rightColorListWidget.add(const SizedBox(width: 5));
        //   for (int i = 0; i < strRightColorMenu.length; i++) {
        //     String c = strRightColorMenu[i];
        //     int cameraPositionIdx =
        //         cameraRegions.indexOf(selectedCameraPosition);

        //     if (c == '1' &&
        //         colorPositionFlags[idx] &&
        //         colorCameraPositionFlags[i * 4 + cameraPositionIdx]) {
        //       if (idx == 0) {
        //         rightColorListWidget.add(blueContainer);
        //       } else if (idx == 1) {
        //         rightColorListWidget.add(greenContainer);
        //       } else if (idx == 2) {
        //         rightColorListWidget.add(redContainer);
        //       }
        //     }
        //     idx++;
        //   }
        // }
      }
    }

    if (!isPlayingMenu) {
      double iconWidth = Platform.isIOS || Platform.isAndroid ? 37 : 53;
      double iconHeight = Platform.isIOS || Platform.isAndroid ? 37 : 53;
      double iconBottom = Platform.isIOS || Platform.isAndroid ? 37 : 15;
      double iconInfoRight = Platform.isIOS || Platform.isAndroid ? 183 : 132;
      double iconSaveRight = Platform.isIOS || Platform.isAndroid ? 120 : 70;
      if (Platform.isAndroid) {
        iconBottom = 15;
        iconInfoRight = 140;
        iconSaveRight = 75;
      }
      bottomRightMenuWidgets = [];
      // bottomRightMenuWidgets.add(Positioned(
      //     bottom: iconBottom,
      //     // right: 220,
      //     right: iconInfoRight,
      //     child: ElevatedButton(
      //       onPressed: () {
      //         isShowingInfo = !isShowingInfo;
      //         printDebug("mapConnectome");
      //         printDebug(mapConnectome);
      //         setState(() {});
      //       },
      //       style: ElevatedButton.styleFrom(
      //         shape: const CircleBorder(),
      //         padding: const EdgeInsets.all(10),
      //         elevation: 5,
      //         shadowColor: Colors.grey.withOpacity(0.5),
      //       ),
      //       child: SvgPicture.asset(
      //         !isShowingInfo
      //             ? "assets/icons/InfoDisabled.svg"
      //             : "assets/icons/Info.svg",
      //         width: iconWidth,
      //         height: iconHeight,
      //       ),
      //     )));
      // bottomRightMenuWidgets.add(Positioned(
      //     bottom: 15,
      //     right: 150,
      //     child: ElevatedButton(
      //       onPressed: () {},
      //       style: ElevatedButton.styleFrom(
      //         shape: const CircleBorder(),
      //         padding: const EdgeInsets.all(10),
      //         elevation: 5,
      //         shadowColor: Colors.grey.withOpacity(0.5),
      //       ),
      //       child: SvgPicture.asset(
      //         "assets/icons/WifiFull.svg",
      //         width: 53,
      //         height: 53,
      //       ),
      //     )));
      // bottomRightMenuWidgets.add(Positioned(
      //     bottom: iconBottom,
      //     right: iconSaveRight,
      //     child: ElevatedButton(
      //       onPressed: () async {
      //         if (pMapStatus["currentFilename"] == "-") {
      //           isSavingBrain = 1;
      //           pMapStatus["isSavingBrain"] = isSavingBrain;
      //           pMapStatus["currentFileName"] = "-";
      //         } else {
      //           if (pMapStatus["currentFileName"] != "-") {}
      //           // isSavingBrain == 10 - Saved
      //           // isSavingBrain == 1 - Default
      //           // isSavingBrain == 2 - There is a change in the design
      //         }
      //         await showLoadBrainDialog(context, "Load Brain", selectSavedBrain,
      //             saveCurrentBrain, pMapStatus);
      //         Future.delayed(const Duration(milliseconds: 1200), () {
      //           // menuIdx = 0;
      //           rightToolbarKey = UniqueKey();
      //           rightToolbarCallback({"menuIdx": 0});
      //           setState(() {});
      //         });
      //       },
      //       style: ElevatedButton.styleFrom(
      //         shape: const CircleBorder(),
      //         padding: const EdgeInsets.all(10),
      //         elevation: 5,
      //         shadowColor: Colors.grey.withOpacity(0.5),
      //       ),
      //       child: SvgPicture.asset(
      //         "assets/icons/Save.svg",
      //         width: iconWidth,
      //         height: iconHeight,
      //       ),
      //     )));

      // bottomRightMenuWidgets.add(Positioned(
      //     bottom: 85,
      //     left: 0,
      //     child: ElevatedButton(
      //       onPressed: () {},
      //       style: ElevatedButton.styleFrom(
      //         shape: const CircleBorder(),
      //         padding: const EdgeInsets.all(10),
      //         elevation: 5,
      //         shadowColor: Colors.grey.withOpacity(0.5),
      //       ),
      //       child: SvgPicture.asset(
      //         "assets/icons/Undo.svg",
      //         width: 53,
      //         height: 53,
      //       ),
      //     )));
      // bottomRightMenuWidgets.add(Positioned(
      //     bottom: 15,
      //     left: 0,
      //     child: ElevatedButton(
      //       onPressed: () {},
      //       style: ElevatedButton.styleFrom(
      //         shape: const CircleBorder(),
      //         padding: const EdgeInsets.all(10),
      //         elevation: 5,
      //         shadowColor: Colors.grey.withOpacity(0.5),
      //       ),
      //       child: SvgPicture.asset(
      //         "assets/icons/Redo.svg",
      //         width: 53,
      //         height: 53,
      //       ),
      //     )));
    }

    List<Widget> aiPositionOverlays = [];
    for (int i = 7; i < cameraMenuTypes.length; i++) {
      if (!aiPositionFlags[i]) continue;

      String key = cameraMenuTypes[i];
      String aiIcon = lookup[key]!;
      if (aiObjectsInfo[key] != null) {
        Recognition recognition = aiObjectsInfo[key];
        // loop connection if it contains banana, or person per camera zone
        Positioned pos = Positioned(
          left: recognition.location.center.dx / 2 - 15,
          top: recognition.location.top / 2,
          child: Container(
            width: 25,
            height: 25,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withOpacity(0.5),
                  spreadRadius: 2,
                  blurRadius: 7,
                  offset: const Offset(0, 3), // changes position of shadow
                ),
              ],
            ),
            child: Text(aiIcon,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  fontFamily: "NotoEmoji",
                )),
          ),
        );
        aiPositionOverlays.add(pos);
        leftAiListWidget.add(Row(
          children: [
            Text(aiIcon,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  fontFamily: "NotoEmoji",
                )),
            Text(key),
          ],
        ));
      }
    }
    if (leftAiListWidget.isEmpty) {
      leftAiListWidget.add(const SizedBox(height: 20));
    }

    leftColorListWidget = [];
    Color overlayColor = const Color(0xFF1996FC);
    List<Widget> colorPositionOverlays = List<Widget>.generate(3, (index) {
      if (!colorPositionFlags[index]) return Container();

      // if selectedWidget inwardEdge doesnt have color
      // List<bool> colorCameraPositionFlags = getColorRegionFlag();
      if (index == 0 &&
          colorPositionFlags[index] &&
          ImagePreprocessor.centroids[0] > 0 &&
          ImagePreprocessor.centroids[1] > 0) {
        leftColorListWidget.add(blueContainer);
        overlayColor = const Color(0xFF1996FC);
      } else if (index == 1 &&
          colorPositionFlags[index] &&
          ImagePreprocessor.centroids[3] > 0 &&
          ImagePreprocessor.centroids[4] > 0) {
        leftColorListWidget.add(greenContainer);
        overlayColor = const Color(0xFF18A953);
      } else if (index == 2 &&
          colorPositionFlags[index] &&
          ImagePreprocessor.centroids[6] > 0 &&
          ImagePreprocessor.centroids[7] > 0) {
        leftColorListWidget.add(redContainer);
        overlayColor = Colors.red;
      }

      if (leftColorListWidget.isEmpty) {
        leftColorListWidget.add(const SizedBox(height: 20));
      }

      return Positioned(
        left: ImagePreprocessor.centroids[index * 3 + 0].toDouble() / 2,
        top: ImagePreprocessor.centroids[index * 3 + 1].toDouble() / 2,
        child: ImagePreprocessor.centroids[index * 3 + 0] == 0 &&
                ImagePreprocessor.centroids[index * 3 + 1] == 0
            ? Container()
            : Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: overlayColor, // Replace with your desired color
                ),

                // color: overlayColor,
              ),
      );
    });
    
    List<Widget> floatingButtons = [
      FloatingActionButton(
        shape: const CircleBorder(),
        hoverElevation: 1,
        elevation: 0,
        backgroundColor: isShowingInfo == 2 ? Colors.black : Theme.of(context).floatingActionButtonTheme.backgroundColor,
        onPressed: () async {
      
        },
        child: GestureDetector(
          onTapUp: (details) async {
            if (buttonPopSource != null) {
              buttonOnPressedHandle = await soloud?.play(buttonPopSource!, looping: false);
            }
            isShowingInfo = (isShowingInfo + 1) % 3;
            if (isShowingInfo == 2) {
              InfiniteCanvasEdge.isShowingInfo = true;
              InfiniteCanvasNode.isShowingInfo = true;
            }else {
              InfiniteCanvasEdge.isShowingInfo = false;
              InfiniteCanvasNode.isShowingInfo = false;
            }
            setState(() {});

          },
          onTapDown: (details) async {
            if (buttonOnPressedSource != null) {
              buttonOnPressedHandle = await soloud?.play(buttonOnPressedSource!, looping: false);
            }

          },
          child: SvgPicture.asset(
              isShowingInfo == 0
                  ? "assets/icons/InfoDisabled.svg" : isShowingInfo == 1 ? "assets/icons/Info.svg" : "assets/icons/InfoLabels.svg",
          ),
        ),
      ),
      if (!isSimulatingBrain) ...[
        const SizedBox(width: 10),
        FloatingActionButton(
          shape: const CircleBorder(),
          hoverElevation: 1,
          elevation: 0,

          onPressed: () {
            return;
            // if (pMapStatus["currentFilename"] == "-") {
            //   isSavingBrain = 1;
            //   pMapStatus["isSavingBrain"] = isSavingBrain;
            //   pMapStatus["currentFileName"] = "-";
            // } else {
            //   if (pMapStatus["currentFileName"] != "-") {}
            //   // isSavingBrain == 10 - Saved
            //   // isSavingBrain == 1 - Default
            //   // isSavingBrain == 2 - There is a change in the design
            // }
            
            // if (buttonOnPressedSource != null) {
            //   buttonOnPressedHandle = await soloud?.play(buttonOnPressedSource!, looping: false);
            // }

            // await showLoadBrainDialog(context, "Load Brain", selectSavedBrain,
            //     saveCurrentBrain, pMapStatus);
            // Future.delayed(const Duration(milliseconds: 1200), () {
            //   // menuIdx = 0;
            //   rightToolbarKey = UniqueKey();
            //   rightToolbarCallback({"menuIdx": 0});
            //   setState(() {});
            // });
          },
          // style: ElevatedButton.styleFrom(
          //   shape: const CircleBorder(),
          //   padding: const EdgeInsets.all(10),
          //   elevation: 5,
          //   shadowColor: Colors.grey.withOpacity(0.5),
          // ),
          child: GestureDetector(
            onTapUp: (details) async {
              if (buttonPopSource != null) {
                if (buttonPopHandle != null) {
                  soloud?.stop(buttonPopHandle!);
                }

                buttonPopHandle = await soloud?.play(buttonPopSource!, looping: false);
              }
              if (isPlayingMenu) return;

              await Future.delayed(const Duration(milliseconds: 100), (){});

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
              Future.delayed(const Duration(milliseconds: 1200), () async {
                // menuIdx = 0;
                rightToolbarKey = UniqueKey();
                rightToolbarCallback({"menuIdx": 0});
                setState(() {});
              });              
            },
            onTapDown: (details) async {
              // debouncerSave.run(() async {
                if (buttonOnPressedSource != null) {
                  if (buttonOnPressedHandle != null) {
                    soloud?.stop(buttonOnPressedHandle!);
                  }
                  buttonOnPressedHandle = await soloud?.play(buttonOnPressedSource!, paused: false);                  
                }
              // });

            },            
            child: SvgPicture.asset(
              "assets/icons/Save.svg",
              // width: iconWidth,
              // height: iconHeight,
            ),
          ),
        ),
      ],
      const SizedBox(width: 10),
      FloatingActionButton(
          shape: const CircleBorder(),
          hoverElevation: 1,
          elevation: 0,
          onPressed: () {

          },
          child: GestureDetector(
            onTapDown: (details) async {
              if (isPreventPlayClick) return;
              if (buttonOnPressedSource != null) {
                if (buttonOnPressedHandle != null) {
                  soloud?.stop(buttonOnPressedHandle!);
                }

                buttonOnPressedHandle = await soloud?.play(buttonOnPressedSource!, looping: false);
              }

            },
            onTapUp: (details) async {
              if (isPreventPlayClick) return;
              if (buttonPopSource != null) {
                if (buttonPopHandle != null) {
                  soloud?.stop(buttonPopHandle!);
                }

                buttonPopHandle = await soloud?.play(buttonPopSource!, looping: false);
              }

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
                debouncerNoResponse.cancel();
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
                  ),
          )),
    ];
    MainAxisAlignment floatingButtonsAlignment = MainAxisAlignment.end;
    if (Platform.isIOS || Platform.isAndroid) {
      // } else {
      floatingButtonsAlignment = MainAxisAlignment.start;
      floatingButtons = floatingButtons.reversed.toList();
      // floatingButtons.insert(
      //     0,
      //     const SizedBox(
      //       width: 25,
      //     ));
    }
    return Scaffold(
      floatingActionButton: Padding(
        padding: EdgeInsets.only(
            left: MediaQuery.of(context).size.height > 600 ? 25 : 75.0),
        child: Row(
          mainAxisAlignment: floatingButtonsAlignment,
          children: floatingButtons,
        ),
      ),
      body: Stack(
          children: [
        Positioned(
          left: 0,
          top: 0,
          child: mainBody,
        ),
        if (!isPlayingMenu) ...[toolbarMenu],
        if (isPlayingMenu) ...[
          Positioned(
            right: 25,
            top: 25,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(3.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    const SizedBox(height: 5),
                    const Text("Live Brain Mode",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 15)),
                    Row(
                      children: [
                        Container(
                            margin: const EdgeInsets.fromLTRB(2, 5, 2, 5),
                            child: Stack(
                              children: [
                                mjpegComponent,
                                ...colorPositionOverlays,
                                ...aiPositionOverlays,
                              ],
                            )),
                        Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.max,
                            children: [
                              const Text("Object Detection"),
                              ...leftAiListWidget,
                              const Text("Color Detection"),
                              if (isVisualDetection) ...[
                                Container(
                                  width: 105,
                                  margin: const EdgeInsets.only(right: 25),
                                  // color: Colors.yellow,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: leftColorListWidget,
                                    // children: [
                                    //   Text("ads"),
                                    // ],
                                  ),
                                )
                              ],
                            ])
                      ],
                    ),
                    // Expanded(
                    //   child: LayoutBuilder(
                    //     builder:
                    //         (BuildContext context, BoxConstraints constraints) {

                    Container(
                      margin: const EdgeInsets.all(3.0),
                      decoration: BoxDecoration(
                          border: Border.all(color: Colors.black)),
                      // color:Colors.red,
                      height: (Platform.isIOS || Platform.isAndroid) ? 90 : 150,
                      width: 300,
                      // child: isSelected?waveWidget : const SizedBox(),
                      child: waveWidget,
                    ),
                    if (isShowingInfo == 1) ...[
                      Row(
                        children: [
                          Container(
                            width: 25,
                            height: 25,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
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
                          const SizedBox(
                            width: 230,
                            child: Text(
                              "Tap a NEURON to see its electrical activity realtime",
                              style: TextStyle(
                                fontSize: 10,
                                fontFamily: "BybHanddrawn",
                              ),
                            ),
                          ),
                        ],
                      ),
                    ]
                    //     },
                    //   ),
                    // ),
                    // Positioned(
                    //   bottom: 0,
                    //   left: 0,
                    //   child: Container(
                    //     margin: const EdgeInsets.all(10.0),
                    //     decoration: BoxDecoration(
                    //         border: Border.all(color: Colors.black)),

                    //     // color:Colors.red,
                    //     height: (Platform.isIOS || Platform.isAndroid)
                    //         ? screenHeight / 2 - 90
                    //         : screenHeight / 2 - 150,
                    //     width: screenWidth - 20,
                    //     // child: isSelected?waveWidget : const SizedBox(),
                    //     child: waveWidget,
                    //   ),
                    // ),

                    // ClipRect(
                    //   clipper: EyeClipper(
                    //       isLeft: true, width: screenWidth, height: screenHeight),
                    //   child: mjpegComponent,
                    // ),
                  ],
                ),
              ),
            ),
          ),
          // Positioned(
          //   right: 50,
          //   top: 0,
          //   child: Column(
          //     children: [
          //       StreamBuilder<Uint8List>(
          //           stream: mainBloc.imageStream,
          //           builder: (context, snapshot) {
          //             // printDebug(snapshot.data);
          //             if (snapshot.data == null) return Container();
          //             return ClipRect(
          //               clipper: EyeClipper(
          //                   isLeft: false,
          //                   width: screenWidth,
          //                   height: screenHeight),
          //               child: Image.memory(
          //                 snapshot.data!,
          //                 gaplessPlayback: true,
          //                 // width: 320 / 2,
          //                 height: 240 / 2,
          //                 fit: BoxFit.fitHeight,
          //               ),
          //             );
          //           }),
          //       if (isShowingRightColorMenu || isShowingRightAiMenu) ...[
          //         Container(
          //             width: 105,
          //             margin: const EdgeInsets.only(left: 55),
          //             // color: Colors.yellow,
          //             child: Row(
          //               crossAxisAlignment: CrossAxisAlignment.end,
          //               mainAxisAlignment: MainAxisAlignment.end,
          //               children: rightColorListWidget,
          //               // children: [Text("asd")],
          //             )),
          //       ]
          //     ],
          //   ),
          // ),
        ],
        if (isPlayingMenu && isChartSelected) ...[
          // Positioned(
          //   bottom: 0,
          //   left: 0,
          //   child: Container(
          //     margin: const EdgeInsets.all(10.0),
          //     decoration:
          //         BoxDecoration(border: Border.all(color: Colors.black)),

          //     // color:Colors.red,
          //     height: (Platform.isIOS || Platform.isAndroid)
          //         ? screenHeight / 2 - 90
          //         : screenHeight / 2 - 150,
          //     width: screenWidth - 20,
          //     // child: isSelected?waveWidget : const SizedBox(),
          //     child: waveWidget,
          //   ),
          // ),
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
        if (aiStats != null && isInfoMenu) ...{
          // Positioned(
          //   left: 0,
          //   bottom: 0,
          //   child: SafeArea(
          //     child: SizedBox(
          //       width: screenWidth - 200,
          //       height: 200,
          //       child: Column(
          //         children: aiStats!.entries.map((e) {
          //           return StatsWidget(e.key, e.value);
          //         }).toList(),
          //       ),
          //     ),
          //   ),
          // )
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
            "${packageInfo?.version ?? ""} : ${packageInfo?.buildNumber ?? ""} \r\n$strFirmwareVersion",
          ),
        ),
        Center(
            child: Text(restartText,
                style: const TextStyle(fontSize: 20, color: Colors.red))),
      ]
            ..addAll(widgets)
            ..addAll(inlineWidgets)
          // ..addAll(arrCirclePositions)
          // ..addAll(bottomRightMenuWidgets),
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
    printDebug("connectionKeys");
    printDebug(controller.nodes.map((e) => e.id).toList());

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
          int idx = i;
          mapNeuronTypeBufView[idx] = neuronTypeIdx + inhibitor;
          if (neuronTypeIdx == CONFIG_DELAY_NEURON) {
            mapDelayNeuronBufView[idx] = mapDelayNeuronList[idx];
            // mapDelayNeuronBufView[i] = 3000;
          } else if (neuronTypeIdx == CONFIG_RHYTMIC_NEURON) {
            mapRhytmicNeuronBufView[idx] = mapRhytmicNeuronList[idx];
            // }
          } else if (neuronTypeIdx == CONFIG_COUNTING_NEURON) {
            mapCountingNeuronBufView[idx] = mapCountingNeuronList[idx];
          }
        }

        if (sign == 1) {
        } else {}
      }
      // printDebug("neuronFrom.value");
      // printDebug(neuronFrom.value);
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
              (sign * mapContactsNeuron[connectionKey].abs()).floorToDouble();
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
            printDebug("errorrr getting limit");
            printDebug(err);
          }
        }

        if (mapSpeakerNeuron.containsKey(connectionKey)) {
          neuronSpeakerBufView[ctr] = (mapSpeakerNeuron[connectionKey]).round();
        } else {
          neuronSpeakerBufView[ctr] = -1;
        }

        if (mapLedNeuron.containsKey(connectionKey)) {
          // printDebug("NODES");
          // printDebug("NODES");
          // printDebug(ctr);
          // printDebug((mapLedNeuron[connectionKey]).round());
          // printDebug(nodeBlueLed.id);
          // printDebug(nodeGreenLed.id);
          // printDebug("connectionKey");
          // printDebug(connectionKey);
          neuronLedBufView[ctr] = (mapLedNeuron[connectionKey]).round();
        } else {
          neuronLedBufView[ctr] = -1;
        }

        String ledConnectionKey = "${neuronFrom.id}_${nodeRedLed.id}";
        if (mapLedNeuronPosition.containsKey(ledConnectionKey)) {
          neuronLedPositionBufView[ctr] =
              mapLedNeuronPosition[ledConnectionKey] == null
                  ? 0
                  : int.parse((mapLedNeuronPosition[ledConnectionKey]), radix: 2)
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
              (sign * mapConnectome[connectionKey].abs()).floorToDouble();
        } else {
          connectomeBufView[ctr] = 0;
        }

        ctr++;
      }
    }
    printDebug("neuronContactsBufView");
    // printDebug(mapNeuronTypeBufView);
    // printDebug(mapConnectome);
    // printDebug(neuronContactsBufView);
    // printDebug(connectomeBufView);
    // printDebug(mapDistanceNeuron);
    // printDebug(mapDistanceLimitNeuron);
    // printDebug(distanceMinLimitBufView);
    // printDebug(distanceMaxLimitBufView);
    // printDebug(neuronSpeakerBufView);
    // printDebug(neuronLedBufView);
    // printDebug(neuronMicrophoneBufView);
    // printDebug(visPrefsBufView);
    printDebug("mapDelayNeuronBufView");
    printDebug(mapDelayNeuronBufView);
    printDebug("mapLedNeuron");
    printDebug(mapLedNeuron);
    printDebug("mapSensoryNeuron");
    printDebug(mapSensoryNeuron);
    printDebug("mapDistanceSensor");
    printDebug(mapDistanceNeuron);
    printDebug(visPrefsBufView);
  }

  void runSimulation() {
    printDebug("RUN SIMuLATION");
    printDebug("mapAreaSize");
    printDebug(mapAreaSize);
    colorPositionFlags[0] = false;
    colorPositionFlags[1] = false;
    colorPositionFlags[2] = false;
    aiPositionFlags.fillRange(0, aiPositionFlags.length, false);
    // neuronSize = controller.nodes.length;
    List<InfiniteCanvasEdge> outwardEdges =
        controller.edges.where((e) => e.from == nodeLeftEyeSensor.key).toList();
    for (InfiniteCanvasEdge outwardEdge in outwardEdges) {
      String key =
          "${outwardEdge.from.toString()}_${outwardEdge.to.toString()}";
      if (mapSensoryNeuron.containsKey(key)) {
        int val = mapSensoryNeuron[key];
        if (cameraMenuTypes[val] == "Red") {
          colorPositionFlags[2] = true;
        } else if (cameraMenuTypes[val] == "Green") {
          colorPositionFlags[1] = true;
        } else if (cameraMenuTypes[val] == "Blue") {
          colorPositionFlags[0] = true;
        } else if (val > 2) {
          aiPositionFlags[val] = true;
        }
      }
    }

    initNativeC(false);
    printDebug("neuronSize");
    printDebug(neuronSize);
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
    printDebug("nodeKey");
    printDebug(nodeKey);

    List<List<double>> connectomeMatrix = List<List<double>>.generate(
        neuronSize,
        (index) =>
            List<double>.generate(neuronSize, (index) => 0.0, growable: false),
        growable: false);
    for (InfiniteCanvasEdge edge in controller.edges) {
      // printDebug("edge.from");
      // printDebug(edge.from);
      // printDebug(edge.to);
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
    // printDebug("initializeNucleus()");
    initializeNucleus();

    // protoNeuron.setConnectome(neuronSize, connectomeMatrix);
    // printDebug("controller.nodes.map(((e) => e.id)).toList()");
    // printDebug(controller.nodes.map(((e) => e.id)).toList());
    populateMatrix();
    // printDebug("===> controller.nodes.map(((e) => e.id)).toList()");
    // printDebug(controller.nodes.map(((e) => e.id)).toList());
    // printDebug(mapContactsNeuron.keys);

    // Future.delayed(const Duration(seconds:1), (){
    printDebug("BUFZ");
    // printDebug(mapConnectome);
    // printDebug(aBufView);
    // printDebug(bBufView);
    // printDebug(cBufView);
    // printDebug(dBufView);
    // printDebug(visPrefsBufView);
    // printDebug(motorCommandBufView);
    // printDebug(neuronContactsBufView);
    printDebug(mapSpeakerNeuron);
    printDebug(neuronSpeakerBufView);
    printDebug(neuronLedBufView);
    printDebug(neuronLedPositionBufView);
    // printDebug(mapMicrophoneNeuron);
    // printDebug(neuronMicrophoneBufView);
    runNativeC();

    // Future.delayed(const Duration(milliseconds: 1000), () {
    //   // String str = 'd:131;d:231;d:331;d:431;d:531;d:631;'; // blue
    //   try {
    //     _DesignBrainPageState.isolateWritePort.send(stopMotorCmd + offLEDCmd);
    //     // _DesignBrainPageState.isolateWritePort.send(offLEDCmd);
    //   } catch (err) {
    //     printDebug("err sending command motor");
    //     printDebug(err);
    //   }
    // });
    // });
  }

  neuronTypeChangeCallback(neuronType) {
    if (controller.hasSelection) {
      InfiniteCanvasNode selected = controller.selection[0];
      printDebug("neuronType");
      printDebug(neuronType);
      // int idx = selected.value;
      // neuronTypes[idx] = neuronType;
      neuronTypes[selected.id] = neuronType;
      selected.label = neuronType;
      // int idx = neuronTypes.keys.toList().indexOf(selected.id);

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

  deleteNeuronCallback() async {
    if (controller.hasSelection) {
      isSynapseMenu = false;
      isMotorMenu = false;
      isMicrophoneMenu = false;
      isSpeakerMenu = false;
      isMicrophoneMenu = false;
      isLedMenu = false;
      isNeuronMenu = false;

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
        // if (mapLedNeuronPosition.containsKey(
        //     "${inwardEdge.from.toString()}_${inwardEdge.to.toString()}")) {
        //   mapLedNeuronPosition.remove(
        //       "${inwardEdge.from.toString()}_${inwardEdge.to.toString()}");
        // }
        if (mapLedNeuronPosition.containsKey(
            "${inwardEdge.from.toString()}_${nodeRedLed.id}")) {
          mapLedNeuronPosition.remove(
              "${inwardEdge.from.toString()}_${nodeRedLed.id}");
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
            "${outwardEdge.from.toString()}_${nodeRedLed.id}")) {
          mapLedNeuronPosition.remove(
              "${outwardEdge.from.toString()}_${nodeRedLed.id}");
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
      // printDebug("neuronTypes");
      // printDebug(neuronTypes);
      // printDebug(neuronTypes.keys);
      // printDebug(neuronTypes.values);

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
    if (eraseSource != null) {
      eraseHandle = await soloud?.play(eraseSource!);
    }
  }

  deleteEdgeCallback() async {
    isSynapseMenu = false;
    isMotorMenu = false;
    isMicrophoneMenu = false;
    isSpeakerMenu = false;
    isMicrophoneMenu = false;
    isLedMenu = false;
    isNeuronMenu = false;

    printDebug("deleteEdgeCallback");
    printDebug(controller.isSelectingEdge);
    if (controller.isSelectingEdge) {
      // var selectedEdge = controller.edges.where((element) => element.from == controller.edgeSelected.from && element.to == controller.edgeSelected.to).toList();
      int idx = controller.edges.indexOf(controller.edgeSelected);
      InfiniteCanvasEdge lastCreatedEdge = controller.edges[idx];
      String edgeKey =
          "${lastCreatedEdge.from.toString()}_${lastCreatedEdge.to.toString()}";
      if (mapSensoryNeuron.containsKey(edgeKey)) {
        mapSensoryNeuron.remove(edgeKey);
      }
      if (mapContactsNeuron.containsKey(edgeKey)) {
        mapContactsNeuron.remove(edgeKey);
      }
      printDebug("mapConnectome");
      printDebug(mapConnectome);
      if (mapConnectome.containsKey(edgeKey)) {
        mapConnectome.remove(edgeKey);
      }
      printDebug("mapConnectome result");
      printDebug(mapConnectome);
      printDebug(edgeKey);

      if (mapDistanceNeuron.containsKey(edgeKey)) {
        mapDistanceNeuron.remove(edgeKey);
      }
      if (mapDistanceLimitNeuron.containsKey(edgeKey)) {
        mapDistanceLimitNeuron.remove(edgeKey);
      }
      if (mapSpeakerNeuron.containsKey(edgeKey)) {
        mapSpeakerNeuron.remove(edgeKey);
      }
      if (mapMicrophoneNeuron.containsKey(edgeKey)) {
        mapMicrophoneNeuron.remove(edgeKey);
      }
      if (mapLedNeuron.containsKey(edgeKey)) {
        mapLedNeuron.remove(edgeKey);
      }

      String ledKey =
          "${lastCreatedEdge.from.toString()}_${nodeRedLed.id}";
      if (mapLedNeuronPosition.containsKey(ledKey)) {
        mapLedNeuronPosition.remove(ledKey);
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
      if (eraseSource != null) {
        eraseHandle = await soloud?.play(eraseSource!);
      }

      prevEdgesLength = controller.edges.length;
    }
  }

  prepareWidget(InfiniteCanvas canvas) {
    if (Platform.isFuchsia) {
      return canvas;
    } else {
      return Container(
        color: const Color(0xFF1996FC),
        width: screenWidth,
        height: screenHeight,
        child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: (details) {
              // printDebug("controller.isFoundEdge");
              // printDebug(controller.isFoundEdge);
              if (controller.isFoundEdge) {
                // printDebug("isSimulatingBrain");
                // printDebug(isSimulatingBrain);
                if (isSimulatingBrain) {
                  controller.isSelectingEdge = false;
                } else {
                  controller.isSelectingEdge = true;
                  controller.edgeSelected = controller.edgeFound;
                }
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
                    printDebug("err1");
                    printDebug(err);
                  }
                  setState(() {});
                }
              }
              // controller.notifyMousePosition();
            },
            onScaleEnd: (ScaleEndDetails details) {
              // printDebug( details.scaleVelocity );
            },
            onScaleUpdate: (details) {
              printDebug("details on scale update");
              printDebug(details);
              // details.scale
            },
            onDoubleTap: () {
              // printDebug("doubletap");
              // printDebug(controller.scale);
              if (isSimulatingBrain) return;

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
            child: canvas),
      );
    }
    // if ((Platform.isAndroid || Platform.isIOS) && isPanningCanvas) {
    //   return XGestureDetector(
    //     onMoveUpdate: (MoveEvent event) {
    //       printDebug("onMoveUpdate Press Move");
    //       // return;
    //       Offset offset = event.delta;
    //       if (offset.dx > 0) {
    //         // controller.panRight();
    //         Offset offset = const Offset(2, 0);
    //         controller.pan(offset);
    //       } else if (offset.dx < 0) {
    //         // controller.panLeft();
    //         Offset offset = const Offset(-2, 0);
    //         controller.pan(offset);
    //       }
    //       if (offset.dy > 0) {
    //         // controller.panDown();
    //         Offset offset = const Offset(0, 2);
    //         controller.pan(offset);
    //       } else if (offset.dy < 0) {
    //         Offset offset = const Offset(0, -2);
    //         controller.pan(offset);
    //       }
    //     },
    //     onScaleUpdate: (ScaleEvent event) {
    //       printDebug("prepare scaling");
    //       var temp = controller.scale * event.scale;
    //       printDebug(controller.minScale);
    //       printDebug(controller.maxScale);
    //       printDebug(controller.scale);
    //       if (temp < controller.maxScale && temp > controller.minScale) {
    //         if (temp > controller.scale) {
    //           controller.zoom(1.003);
    //         } else {
    //           controller.zoom(0.997);
    //         }
    //       }
    //     },
    //     child: canvas,
    //   );
    // } else {
    //   return canvas;
    // }
  }

  leftToolbarCallback(map) async {
    printDebug("modeIdx0");
    modeIdx = map["modeIdx"];
    controller.modeIdx = modeIdx;
    isBrainTargetOverlayTop = -1;
    containedIdx = -1;
    if (modeIdx != -1) {
      mapBg["activeBg"] = "assets/bg/BrainDrawings/BrainFullGrey.svg";
    } else {
      mapBg["activeBg"] = defaultBg;
    }
    printDebug("modeIdx");
    printDebug(modeIdx);
    // if (modeIdx == -1) {
    //   menuIdx = 0;
    // }
    prevConstrainedFlag = true;
    prevConstrainedPos = Offset.zero;
    setState(() {});
  }

  rightToolbarCallback(map) async {
    printDebug("map");
    printDebug(map);
    menuIdx = map["menuIdx"];
    MyApp.logAnalytic("menuClick", map);
    isCreatePoint = false;
    if (menuIdx == 0) {
      controller.isInteractable = true;
      controller.setCanvasMove(true);
      if (controller.hasSelection) {
        controller.spacePressed = false;
        allowMoveNodes();
      } else {
        double scales = controller.getScale();
        printDebug("scales");
        printDebug(scales);
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

    if (menuIdx == 1) {
      resetMouse();
      controller.deselectAll();
      clearUIMenu();
      // controller.setCanvasMove(false);
    } else if (menuIdx == 5) {
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
    } else if (menuIdx == 7) {
      controller.isSelectingEdge = controller.spacePressed = false;


      isPlayingMenu = !isPlayingMenu;
      countEyeSensorConnection();
      // isSelected = false;
      printDebug("MENU IDX 8");
      printDebug("BUF IDX 7");
      printDebug(isPlayingMenu);
      // printDebug(mapConnectome);

      controller.mouseDown = false;
      controller.setCanvasMove(false);
      controller.zoomReset();

      rawPos = [];
      for (InfiniteCanvasNode node in controller.nodes) {
        Offset position = controller.toLocal(node.offset);
        rawPos.add(position);
      }

      if (isPlayingMenu) {
        isCheckingColor = false;
        try {
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
        } catch (err) {}
        isSimulatingBrain = false;

        // initializeOpenCV();
        isIsolateWritePortInitialized = false;
        processor.clearMemory();
        try {
          processor = ImagePreprocessor();
          mjpegComponent = Mjpeg(
            error: (context, error, stack) {
              return const Text("\r\nNot connected\r\nto SpikerBot\r\nWiFi",
                  style: TextStyle(fontSize: 10, color: Colors.brown));
            },
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
          printDebug("exception : ");
          printDebug(exc);
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
          restartText = "";
          setState(() => {});
        });
      }

      if (isPlayingMenu) {
        controller.deselectAll();
        isPlayingMenu = false;
        isDrawTail = false;
        Future.delayed(const Duration(milliseconds: 1650), () {
          controller.zoomReset();
          // NEW UI
          if (isPortrait == false) {
            controller.pan(const Offset(-60, 0));
          }
          isPlayingMenu = true;
          runSimulation();
          controller.isPlaying = true;
          printDebug("initial Index");
          // nativec.changeIdxSelected(11);
          isChartSelected = true;

          try {
            // debouncerNoResponse.cancel();
            debouncerNoResponse.run(() {
              try {
                // double maxValue =
                    // Nativec.canvasBufferBytes1.reduce((a, b) => a + b);
                // if (maxValue == 0) {
                //   restartText = "Re-establishing connection";
                //   rightToolbarCallback({"menuIdx": 7});
                //   Future.delayed(const Duration(milliseconds: 4700), () {
                //     // menuIdx = 0;
                //     // controller.isInteractable = true;

                //     rightToolbarCallback({"menuIdx": 7});
                //     isEmergencyPause = true;
                //     setState(() {});
                //   });
                // } else {
                //   _DesignBrainPageState.isolateWritePort.send("v:");
                // }
              } catch (err) {
                printDebug("err debouncer");
              }
            });
          } catch (err) {
            printDebug("err debouncer no response");
            printDebug(err);
          }

          if (isIsolateWritePortInitialized) {
            aiStats = null;
            aiObjectsInfo = {};

            MyApp.logAnalytic("StartPlaying",
                {"timestamp": DateTime.now().millisecondsSinceEpoch});
          }
        });
      } else {
        printDebug("STOP THREAD PROCESS");
        if (kIsWeb) {
        } else {
          // nativec.stopThreadProcess(0);
        }
        controller.deselectAll();
        controller.setCanvasMove(true);
        controller.isPlaying = false;
        // isInfoMenu = false;
        MyApp.logAnalytic("StopPlaying",
            {"timestamp": DateTime.now().millisecondsSinceEpoch});
      }
      setState(() {});
    }
    // add nodes into canvas
  }

  void repositionSensoryNeuron() {
    double screenWidth = MediaQuery.of(context).size.width;
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

    nodeDistanceSensor.offset = middleScreenOffset;

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

    // Offset offsetBlue = ledGreenOffset + diff + verticalLedSpacer;
    // nodeBlueLed.offset = offsetBlue;
    nodeBlueLed.offset = Offset.zero;
  }

  void clearBridge() {
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
      ..strokeWidth = 2;
    Paint whiteBrush = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill
      ..strokeWidth = 2;

    int tailSize = 5;
    double tailTouchSize = 24;
    tailNode = InfiniteCanvasNode(
      value: -1,
      key: UniqueKey(),
      offset: const Offset(0, 0),
      size: Size(tailTouchSize, tailTouchSize),
      child: Builder(
        builder: (context) {
          return CustomPaint(
            painter: InlineCustomPainter(
              brush: tailColor,
              builder: (brush, canvas, rect) {
                // Draw triangle
                if (isDrawTail) {
                  if (neuronStyle == "Excitatory") {
                    Offset parentOffset =
                        Offset(rect.center.dx, rect.center.dy - gapTailY);
                    if (!isTailCreated) {
                      pathTail = Path();
                      int offset = 0;
                      Offset topTriangle = Offset(offset + rect.center.dx,
                          offset + rect.center.dy - tailSize);
                      Offset rightTriangle = Offset(
                          offset + rect.center.dx + tailSize * 2,
                          offset + rect.center.dy + tailSize * 2);
                      Offset leftTriangle = Offset(
                          offset + rect.center.dx - tailSize * 2,
                          offset + rect.center.dy + tailSize * 2);

                      pathTail.moveTo(topTriangle.dx, topTriangle.dy);
                      pathTail.lineTo(leftTriangle.dx, leftTriangle.dy);
                      pathTail.lineTo(rightTriangle.dx, rightTriangle.dy);

                      pathTail.close();
                      isTailCreated = true;
                    }

                    canvas.drawLine(rect.center, parentOffset, blackStroke);
                    canvas.drawPath(pathTail, blackStroke);
                    canvas.drawPath(pathTail, whiteBrush);

                    brush.color = tailColor.color;
                  } else if (neuronStyle == 'Inhibitory') {
                    Offset parentOffset =
                        Offset(rect.center.dx, rect.center.dy - gapTailY);
                    if (!isTailCreated) {
                      isTailCreated = true;
                    }
                    canvas.drawLine(rect.center.translate(0, -5),
                        parentOffset.translate(0, 7), blackStroke);

                    // canvas.drawPath(pathTail, brush);
                    canvas.drawCircle(rect.center, 5, blackStroke);

                    // brush.color = tailColor.color;
                  }
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
      value: 10,
      key: UniqueKey(),
      offset: const Offset(500, 170),
      size: const Size(20, 20),
      child: Builder(
        builder: (context) {
          return CustomPaint(
            painter: InlineCustomPainter(
              brush: neuronColor,
              builder: (brush, canvas, rect) {
                canvas.drawCircle(rect.center, rect.width / 2, brush);
              },
            ),
          );
        },
      ),
    );
    circleNode = InfiniteCanvasNode(
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

      nodeSingleLed,
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
      nodeSingleLed,
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
    nodeSingleLed.syntheticNeuron = syntheticNeuronList[9];
    nodeRedLed.syntheticNeuron = syntheticNeuronList[10];
    nodeGreenLed.syntheticNeuron = syntheticNeuronList[11];
    nodeBlueLed.syntheticNeuron = syntheticNeuronList[12];

    listDefaultSensorLabel = [
      "Distance Sensor",
      "Eye Sensor",
      "Right Eye",
      "Microphone",
      "Speaker",
      "Left Motor (Forward)",
      "Right Motor (Forward)",
      "Left Motor (Backward)",
      "Right Motor (Backward)",
      "Lights",
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
      nodeSingleLed,
      nodeRedLed,
      nodeGreenLed,
      nodeBlueLed,
    ];
    listSensorArrow = [
      nodeDistanceSensor,
      nodeLeftEyeSensor,
      nodeMicrophoneSensor,
    ];
    
    printDebug("Create Canvas Controller");
    printDebug(nodes);
    // neuronTypes["abc"] = "1";
    controller = InfiniteCanvasController(
      rawSyntheticNeuronList: rawSyntheticNeuronList,
      syntheticNeuronList: syntheticNeuronList,
      syntheticConnections: syntheticConnections,
      neuronTypes: neuronTypes,
      onLongPress: onLongPress,
      onDoubleTap: onDoubleTap,
      onDeleteCallback: onDeleteCallback,
      onAxonCreatedCallback: fillCreatedAxon,
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
    controller.restrictedToNeuronsKey = [
      nodeLeftEyeSensor.key,
      nodeRightEyeSensor.key,
      nodeMicrophoneSensor.key,
      nodeDistanceSensor.key,
    ];

    controller.restrictedFromNeuronsKey = [
      nodeLeftMotorForwardSensor.key,
      nodeLeftMotorBackwardSensor.key,
      nodeRightMotorForwardSensor.key,
      nodeRightMotorBackwardSensor.key,
      nodeSpeakerSensor.key,
    ];
    // New UI
    if (isPortrait == false) {
      controller.pan(const Offset(-60, 0));
    } // controller.zoom(0.97);
    // controller.minScale = 1;

    // if (Platform.isAndroid || Platform.isIOS) {
    //   repositionSensoryNeuron();
    // }

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

          printDebug('design brain start');
          printDebug(axonFromSelected);
          printDebug(controller.hasSelection);
          printDebug("------------------");
          if (!axonFromSelected && controller.hasSelection) {
            axonFromSelected = true;
            axonFrom = controller.selection[0].key;
            Future.delayed(const Duration(milliseconds: 100), () {
              controller.deselect(axonFrom);
            });

            // isCreatePoint = false;
            if (!axonToSelected && controller.hasSelection) {
              axonFromSelected = true;
              axonTo = controller.selection[0].key;

              printDebug('axon from = to');
              printDebug(axonFrom.toString());
              printDebug(axonTo.toString());
              if (axonFrom.toString() == axonTo.toString()) {
              } else {
                // if there is already the same edge from one node to another node, don't add
                bool isAddUniqueEdge = true;

                printDebug('axon to selected');
                if (isAddUniqueEdge) {
                  printDebug('axon unique to selected');
                  // addSyntheticConnection(axonFrom, axonTo);

                  controller.edges
                      .add(InfiniteCanvasEdge(from: axonFrom, to: axonTo));
                }
              }
            }

            axonFromSelected = false;
            axonToSelected = false;
            Future.delayed(const Duration(milliseconds: 100), () {
              // controller.deselect(axonFrom);
              controller.deselect(axonTo);
            });

            // isCreatePoint = false;
          } else {
            isCreatePoint = true;

            double scales = controller.getScale();
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

            // USER CLICKING THE PICTURE TO SHOW TRIANGLE TAIL
            printDebug("UserClicking picture to show tail");
            Offset localPosition = controller.toLocal(controller.mousePosition);
            int n = controller.dropTargets.length;
            Offset localOffsetGap = const Offset(0,0);
            bool isContain = false;
            bool flagIsContain = false;
            int sensoryIdx = -1;
            for (int i = 0; i < n; i++) {
              sensoryIdx = i;
              Map<String, dynamic> neuronInfo = dropTargetInformations[i];
              if (i == 2) {
                neuronInfo = dropTargetInformations[i+1];
              }
              if (i >= 7) {
                sensoryIdx = i + 1;
                neuronInfo = dropTargetInformations[i + 1];
              }
              Offset containOffset = localPosition.translate(
                  -((windowWidth / 2) +
                          neuronInfo["posXDiff"] * scaleMultiplier) +
                      localOffsetGap.dx,
                  -(neuronInfo["top"] * scaleMultiplier +
                          topInnerWindowSpace) +
                      localOffsetGap.dy);

              GeneralSensorPainter painter = (listPainters[i]);
              isContain = painter.path.contains(containOffset);
              if (isContain) {
                printDebug("isContainIMAGE: $i, $n");
                flagIsContain = true;
                if (i >= 7) {
                  InfiniteCanvasNode sensoryNode = sensoryNeurons[i + 1];
                  isDrawTail = true;
                  isTailCreated = false;
                  isDeleteMenu = false;
                  isTailType = "triangle";
                  neuronStyle = "Excitatory";
                  controller.select(sensoryNode.key);
                  
                } else {
                  InfiniteCanvasNode sensoryNode = sensoryNeurons[i];
                  isDrawTail = true;
                  isTailCreated = false;
                  isDeleteMenu = false;
                  isTailType = "triangle";
                  neuronStyle = "Excitatory";
                  controller.select(sensoryNode.key);
                }
                setState((){});
              }
            }
            if (controller.isFoundEdge) {
              soloud?.play(neuronOnTouchSource!).then((handle) {
                if (neuronOnTouchHandle != null) {
                  soloud?.stop(neuronOnTouchHandle!);
                }
                neuronOnTouchHandle = handle;
              });              
            }
            printDebug("isContainIMAGE $flagIsContain");

            // if (controller.restrictedToNeuronsKey !=null && controller.restrictedToNeuronsKey!.contains(temporaryEdge[1])) {
            //   printDebug("SELECTING  LINK");
            //   InfiniteCanvasNode selectedNode = findNeuronByKey(temporaryEdge[1]);
            //   selectedNode.child = Container(width: 15, height: 15, color: Colors.black);
            //   controller.select(temporaryEdge[1], true);
            //   setState((){});
            // }

          }
        } else if (menuIdx == 0 && controller.controlPressed) {
          Offset localPosition = controller.toLocal(controller.mousePosition);
          double mouseX = localPosition.dx;
          double mouseY = localPosition.dy;
          // printDebug("mouse:");
          // printDebug(mouseX);
          // printDebug(mouseY);
          int n = controller.dropTargets.length;
          Offset localOffsetGap = const Offset(0,0);
          bool isContain = false;
          bool flagIsContain = false;
          int nodeContainIdx = -1;
          int idx = -1;
          for (int i = 0; i < n; i++) {
            Map<String, dynamic> neuronInfo = dropTargetInformations[i];
            idx = i;
            if (i >= 2) {
              neuronInfo = dropTargetInformations[i ];
            }
            if (i >= 7) {
              neuronInfo = dropTargetInformations[i + 1];
              idx = i + 1;
            }
            Offset containOffset = localPosition.translate(
                -((windowWidth / 2) +
                        neuronInfo["posXDiff"] * scaleMultiplier) +
                    localOffsetGap.dx,
                -(neuronInfo["top"] * scaleMultiplier +
                        topInnerWindowSpace) +
                    localOffsetGap.dy);

            GeneralSensorPainter painter = (listPainters[i]);
            isContain = painter.path.contains(containOffset);
            // printDebug("containOffset $i");
            // printDebug(containOffset);
            // printDebug(neuronInfo["top"]);
            // printDebug(painter.calculatedPath);
            if (isContain) {
              flagIsContain = true;
              var selected = controller.selection[0];
                printDebug("isContain: $idx, $n, $isTemporaryEdge");
              if (isTemporaryEdge == -1 || isTemporaryEdge != idx) {
                isTemporaryEdge = idx;
                temporaryEdge.clear();
                temporaryEdge.add(selected.key);
                if (i>=7) {
                  temporaryEdge.add(sensoryNeurons[i+1].key);
                } else {
                  temporaryEdge.add(sensoryNeurons[i].key);
                }
                printDebug(temporaryEdge);

              }
              if (i>=7) {
                  nodeContainIdx = i + 1;
              } else {
                  nodeContainIdx = i;
              }

            } else {
              // printDebug("is Not Contain: $i, $n, $isTemporaryEdge");
            }
          }
          if (flagIsContain) {
            // printDebug("isContain $flagIsContain $nodeContainIdx");
            mapBg["activeBg"] = "assets/bg/BrainDrawings/BrainFullGrey.svg";
            if (nodeContainIdx != -1) {
              mapBg["activeComponent"] = activeComponents[nodeContainIdx];
              if (prevSoundIdx != nodeContainIdx) {
                prevSoundIdx = nodeContainIdx;
                soloud?.play(neuronOnTouchSource!).then((handle) {
                  if (neuronOnTouchHandle != null) {
                    soloud?.stop(neuronOnTouchHandle!);
                  }
                  neuronOnTouchHandle = handle;
                });
              }

              nodeContainIdx = -1;


            }
          } else {
            bool isHoveringNeuron = false;
            int len = controller.nodes.length;
            InfiniteCanvasNode? hoveringNode;
            for (int i = normalNeuronStartIdx + 2; i < len; i++) {
              InfiniteCanvasNode node = controller.nodes[i];
              if (controller.isHovered(node.key)) {
                isHoveringNeuron = true;
                hoveringNode = node;
              }
            }
            if (isHoveringNeuron) {
              // check if the neuron is inside temporary check variable
              // if it is inside temporary check variable, don't play the sound
              // if it doesn't contain temporary check variable, play the sound, and fill the temporary check variable
              if (prevSelectedNode != null && hoveringNode != null) {
                if (prevSelectedNode!.key != hoveringNode.key) {
                  String key = "${prevSelectedNode!.key}_${hoveringNode.key}";
                  if (!mapHoveringNeuron.containsKey(key)) {
                    mapHoveringNeuron.clear();
                    mapHoveringNeuron[key] = 1;
                    if (soloud != null && soloud!.isInitialized && neuronOnTouchSource !=null) {
                      if (neuronOnTouchHandle != null) {
                          soloud?.stop(neuronOnTouchHandle!);
                      }
                      soloud?.play(neuronOnTouchSource!).then((handle) {
                        neuronOnTouchHandle = handle;
                      });

                    }
                  }
                }

              }
            } else {
              mapHoveringNeuron.clear();              
            }

            isTemporaryEdge = -1;
            // printDebug("isNotContain ");
            nodeContainIdx = -1;
            temporaryEdge.clear();
            mapBg["activeBg"] = "assets/bg/BrainDrawings/BrainFullGrey.svg";
            mapBg["activeComponent"] = noActiveComponent;
          }
          debouncerActiveComponent.run((){
            setState((){});
          });
          // if (!isContain) {
          //   isTemporaryEdge = false;
          //   temporaryEdge.clear();
          // }

        } else if (menuIdx == 0 &&
            controller.hasSelection &&
            !controller.controlPressed) {
          mapHoveringNeuron.clear();              
          var selected = controller.selection[0];
          // printDebug("Controler pRessed");

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
          if (foundSelected) {
            tooltipValueChange.value = (Random().nextInt(10000));
            // setState((){});
            // Future.delayed(const Duration(milliseconds: 1000), () {
            debouncerTooltip.run(() {
              isTooltipOverlay = false;
              tooltipValueChange.value = (Random().nextInt(10000));
            });
          }

          if (selected == tailNode) {
            controller.deselectAll();
            controller.select(prevSelectedNeuron.key);
            controller.controlPressed = true;
            if (axonStretchSource != null) {
              isDraggingTail = true;
              if (isDraggingTail) {
                soloud?.play(axonStretchSource!, looping: true).then((handle) {
                  axonStretchHandle = handle;
                });
              }
            }
            
            clearUIMenu();
            setState(() => {});

            prevEdgesLength = controller.edges.length;
          } else {
            if (!isTooltipOverlay) {
              isDeleteMenu = true;
            } else {
              if (!listSensorArrow.contains(selected)) {
                return;
              }
            }
            // printDebug("prevSelectedOffsetNode");
            // printDebug(prevSelectedOffsetNode);
            // printDebug(selected.offset);
            // printDebug(prevSelectedNode);
            // printDebug(selected);
            if (prevSelectedOffsetNode == null && prevSelectedNode == null) {
              if (neuronOnTouchSource != null) {
                soloud?.play(neuronOnTouchSource!).then((handle) {
                  if (neuronOnTouchHandle != null) {
                    soloud?.stop(neuronOnTouchHandle!);
                  }
                  neuronOnTouchHandle = handle;
                });
              }
            } else
            if (prevSelectedOffsetNode != null && prevSelectedNode != null) {
              // MOVING NODE
              if (prevSelectedNode == selected && prevSelectedOffsetNode != selected.offset && isMovingNodeFirstTime) {
                isMovingNodeFirstTime = false;
                // Future.delayed( const Duration(milliseconds: 200), (){

                  soloud?.play(neuronSpikesSource!).then((handle) {
                    if (neuronSpikesHandle != null) {
                      soloud?.stop(neuronSpikesHandle!);
                    }
                    neuronSpikesHandle = handle;
                  });              
                // });
              }
            }
            prevSelectedNode = selected;
            prevSelectedOffsetNode = selected.offset;
            prevSelectedNeuron = selected;
            // printDebug(isDrawTail);
            isDrawTail = true;
            isDeleteMenu = true;
            if (neuronStyles[selected.id] == "Excitatory") {
              isTailType = "triangle";
            } else {
              isTailType = "circle";
            }

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
              String prevNeuronStyle = neuronStyle;
              neuronStyle = neuronStyles[selected.id] != null
                  ? neuronStyles[selected.id]!
                  : "Excitatory";
              if (prevNeuronStyle != neuronStyle) {
                isTailCreated = false;
              }


              try {
                int neuronIdx = controller.nodes
                        .map((e) => e.id)
                        .toList()
                        .indexOf(selected.id) -
                    2;

                // nativec.changeIdxSelected(neuronIdx);
                if (mapDelayNeuronList[neuronIdx] > 0) {
                  isShowDelayTime = true;
                  printDebug(tecTimeValue.text +
                      "_" +
                      mapDelayNeuronList[neuronIdx].toString());
                  if (tecTimeValue.text !=
                      mapDelayNeuronList[neuronIdx].toString()) {
                    tecTimeValue.text =
                        mapDelayNeuronList[neuronIdx].toString();
                  }
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
                printDebug("err init canvas");
                printDebug(err);
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
              int ordinateGap = 24;
              int diagonalGap = 18;
              arrPosConstraints = [
                posLocal.translate(
                    0, -ordinateGap * controller.getScale()), // middleTop
                posLocal.translate(
                    -ordinateGap * controller.getScale(), 0), // middleLeft
                posLocal.translate(
                    0, ordinateGap * controller.getScale()), // middleBottom
                posLocal.translate(
                    ordinateGap * controller.getScale(), 0), // middleRight

                posLocal.translate(-diagonalGap * controller.getScale(),
                    -diagonalGap * controller.getScale()), // topLeft
                posLocal.translate(diagonalGap * controller.getScale(),
                    -diagonalGap * controller.getScale()), // topRight
                posLocal.translate(-diagonalGap * controller.getScale(),
                    diagonalGap * controller.getScale()), // bottomLeft
                posLocal.translate(diagonalGap * controller.getScale(),
                    diagonalGap * controller.getScale()), // bottomRight
              ];
              if (Platform.isIOS || Platform.isAndroid) {
                // double diffMultiplierX = brainPosition.dx * scaleMultiplier -
                //     115 +
                //     leftInnerWindowSpace;
                // double diffMultiplierY = brainPosition.dy * scaleMultiplier;
                // double diffMultiplierTop = 0;
                // double diffMultiplierLeft = 0;
                // double diffMultiplierRight = 0;
                // double diffMultiplierBottom = 0;
                double multiplier = 2;
                double neuronDrawSize = 12;
                double gapLeft = neuronDrawSize * 4;
                double posDiagonal = neuronDrawSize * multiplier / 2;
                double posLeft = neuronDrawSize * multiplier / 2;
                double posRight = neuronDrawSize * (multiplier - 3.5);
                double posTop = neuronDrawSize * multiplier;
                double posBottom = neuronDrawSize * (multiplier + 0);

                arrPosConstraints = [
                  posLocal.translate(-gapLeft, -posTop), // Top
                  posLocal.translate(
                      -gapLeft - neuronDrawSize * multiplier, 0), // Left
                  posLocal.translate(-gapLeft, posBottom), // Bottom
                  posLocal.translate(posRight, 0), // Right


                  posLocal.translate(
                      -gapLeft - posLeft, -posTop / 2), // Top Left
                  posLocal.translate(
                      posRight - posDiagonal, -posTop / 2), // TopRight
                  posLocal.translate(-gapLeft - posLeft,
                      posBottom - posDiagonal), // Bottom Left

                  posLocal.translate(posRight - posDiagonal,
                      posBottom - posDiagonal), // BottomRight
                ];
              }

              bool flag = true;
              // double diffWidth = currentFrameGapWidth - initialFrameGapWidth;
              // double diffHeight = currentFrameGapHeight - initialFrameGapHeight;
              // diffWidth = diffWidth / 2;
              // diffHeight = diffHeight / 2;
              double diffWidth = brainPosition.dx;
              double diffHeight = brainPosition.dy;
              double coreBrainGapX = 0.95;
              double coreBrainGapY = 0.85;

              if (Platform.isIOS || Platform.isAndroid) {
                // print("diffWidth >< diffHeight");
                // print(diffWidth);
                // print(diffHeight);
                if (isPortrait == false) {
                  if (MediaQuery.of(context).size.height >= 600) {
                    diffWidth =
                        (windowWidth - currentImageWidth * coreBrainGapX) / 2;
                    diffHeight = (currentImageHeight * (1 - coreBrainGapY)) / 2;
                  } else {
                    coreBrainGapX = 1.1;
                    diffWidth =
                        (windowWidth - currentImageWidth * coreBrainGapX) / 2;
                    diffHeight = (currentImageHeight * (1 - coreBrainGapY)) / 2;
                  }
                } else {
                  // isPortrait
                  diffWidth =
                      (windowWidth - currentImageWidth * coreBrainGapX) / 2;
                  diffHeight =
                      (windowHeight - currentImageHeight * coreBrainGapY) / 2;
                  // print("diffWidth >< diffHeight");
                  // print("$windowWidth - ${currentImageWidth * coreBrainGapX}");
                  // print(
                  //     "$windowHeight - ${currentImageHeight * coreBrainGapY}");
                }
              }

              arrCirclePositions = [];
              double translatedDx = diffWidth;
              double translatedDy = diffHeight;

              for (Offset pos in arrPosConstraints) {
                // if (coreBrainPainter != null) {
                // double leftBrainPosition = windowWidth / 2 - 245 * scaleMultiplier;
                // Offset brainPosition = const Offset(190, 50);
                // double translatedDx = brainPosition.dx;
                // double translatedDy = brainPosition.dy;

                // print("diffWidth >< diffHeight");
                // print(diffWidth);
                // print(diffHeight);
                // print(windowWidth);
                // print(windowWidth);
                // print(currentImageWidth);
                double leftCirclePos = pos.dx;
                double topCirclePos = pos.dy;
                // if (Platform.isMacOS || Platform.isWindows || kIsWeb) {
                // printDebug("prevInitialFrameGapWidth");
                // printDebug("$windowWidth - $currentImageWidth");
                // printDebug(prevInitialFrameGapWidth);
                // printDebug(translatedDx);
                // if (Platform.isIOS || Platform.isAndroid) {
                //   leftCirclePos = prevInitialFrameGapWidth! / 2 + 0 + pos.dx;
                //   topCirclePos = prevInitialFrameGapHeight! / 2 + 0 + pos.dy;
                // }
                // }
                if (!coreBrainPainter.path
                    .contains(pos.translate(-translatedDx, -translatedDy))) {
                  print("pos.dx");
                  print(pos);
                  print(pos.translate(-translatedDx, -translatedDy));

                  arrCirclePositions.add(Positioned(
                    left: leftCirclePos,
                    top: topCirclePos,
                    // left: pos.dx,
                    // top: pos.dy,
                    child: Container(
                      color: Colors.purple,
                      width: 10,
                      height: 10,
                    ),
                  ));

                  // printDebug("Not Contained");
                  flag = false;
                } else {
                  arrCirclePositions.add(Positioned(
                    left: leftCirclePos,
                    top: topCirclePos,
                    // left: pos.dx,
                    // top: pos.dy,
                    child: Container(
                      color: Colors.red,
                      width: 10,
                      height: 10,
                    ),
                  ));
                }
                // }
              }
              if (!flag) {
                // selected.update(offset: Offset(435, 300));
                if (prevConstrainedPos == Offset.zero) {
                } else {
                  selected.update(offset: prevConstrainedPos);
                }
              }

              Offset offsetBrainPosition = brainPosition;
              // brainPosition.translate(-translatedDx, -translatedDy);
              // printDebug("offsetBrainPosition");
              // printDebug(offsetBrainPosition);
              arrCirclePositions.add(Positioned(
                top: offsetBrainPosition.dy,
                left: offsetBrainPosition.dx,
                // top: brainPosition.dy,
                // left: brainPosition.dx,
                child: CustomPaint(
                  painter: coreBrainPainter,
                ),
              ));
              prevConstrainedFlag = flag;
              // if (!coreBrainPainter.path.contains(pos))
              // sensorPolygonPaths[0]
              // CONSTRAINT RESTRICTIONS

              tailNode.update(
                  offset: Offset(selected.offset.dx + gapTailX,
                      selected.offset.dy + gapTailY));
            }
            controller.spacePressed = false;
            controller.setCanvasMove(false);
            allowMoveNodes();
          }
        } else if (menuIdx == 1 && !isCreatePoint && !controller.hasSelection) {
          // printDebug("MenuIdx");
          // printDebug(menuIdx);
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
          // printDebug("Create neuron1");
          // printDebug(prevMouseX);
          // printDebug(prevMouseY);
          // printDebug(mouseX);
          // printDebug(mouseY);

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

          aDesignArray[newNodeKey.toString()] = sldAWeight;
          bDesignArray[newNodeKey.toString()] = sldBWeight;
          cDesignArray[newNodeKey.toString()] = sldCWeight;
          dDesignArray[newNodeKey.toString()] = sldDWeight;

          SyntheticNeuron syntheticNeuron = SyntheticNeuron(
              isActive: false, isIO: false, circleRadius: neuronDrawSize / 2);
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
            MyApp.logAnalytic("CreateNeuron",
                {"timestamp": DateTime.now().millisecondsSinceEpoch});
          });
          // } else if (menuIdx == 2 && !isCreatePoint && controller.hasSelection) {
        } else if (!isCreatePoint && controller.hasSelection) {
        } else if (menuIdx == 6 && !controller.hasSelection) {
          printDebug("Zoom Reset");
          isChartSelected = false;
          // nativec.changeIdxSelected(-1);
          setState(() {});
        } else if (menuIdx == 6 && controller.hasSelection) {
          var selected = controller.selection[0];
          printDebug("selected.value");
          printDebug(selected.value);
          isChartSelected = false;

          int neuronIdx =
              controller.nodes.map((e) => e.id).toList().indexOf(selected.id) -
                  2;

          // nativec.changeIdxSelected(neuronIdx);
          redrawNeuronLine.value = Random().nextInt(100);
          setState(() {});
        }
      } else {
        mapHoveringNeuron.clear();        
        // printDebug("CREATING LINK0 $isTemporaryEdge");
        if (isTemporaryEdge > -1) {
          printDebug("Add LINK--0");
          printDebug(temporaryEdge);
          isTemporaryEdge = -1;
          if (temporaryEdge.length > 1) {
            printDebug("Add LINK");
            LocalKey nodeFrom = temporaryEdge[0];
            LocalKey nodeTo = temporaryEdge[1];
            controller.addLink(temporaryEdge[0], temporaryEdge[1]);
            temporaryEdge.clear();
            mapBg["activeBg"] = defaultBg;
            mapBg["activeComponent"] = noActiveComponent;


            if (controller.controlPressed) {
              // create link
              Future.delayed(const Duration(milliseconds: 100), () {
                printDebug("creating link0");

                // printDebug(controller.edges.isNotEmpty);
                if (controller.edges.isNotEmpty) {
                  // fillCreatedAxon(nodeFrom, nodeTo);
                  // setState(() {});
                  mapBg["activeBg"] = defaultBg;
                  mapBg["activeComponent"] = noActiveComponent;
                  controller.controlPressed = false;
                  setState(() {
                    
                  });                
                  MyApp.logAnalytic("CreateAxon",
                      {"timestamp": DateTime.now().millisecondsSinceEpoch});
                }else {
                  mapBg["activeBg"] = defaultBg;
                  mapBg["activeComponent"] = noActiveComponent;
                  setState(() {
                  });
                }
                controller.controlPressed = false;
                controller.deselectAll();

              });
              controller.controlPressed = false;
              controller.deselectAll();
              clearUIMenu();
              setState(() => {});
            }
          }
        }
        if (isDraggingTail) {
          soloud?.fadeVolume(axonStretchHandle!, 0, const Duration(milliseconds: 500));
          soloud?.scheduleStop(axonStretchHandle!, const Duration(milliseconds: 500));
          isDraggingTail = false;
        }
        mapBg["activeBg"] = defaultBg;
        mapBg["activeComponent"] = noActiveComponent;

        controller.controlPressed = false;

        isCreatePoint = false;
        tailNode.update(offset: tailNode.offset);

        // if (!isMovingNodeFirstTime) {
          isMovingNodeFirstTime = true;
          prevSelectedNode = null;
          prevSelectedOffsetNode = null;
          try{
            if (soloud != null && neuronSpikesHandle != null) {
              soloud?.fadeVolume(neuronSpikesHandle!, 0, const Duration(milliseconds: 500));
              soloud?.scheduleStop(neuronSpikesHandle!, const Duration(milliseconds: 500));
            }

          }catch(err) {
            printDebug("err so loud");
            printDebug(err);
          }
          
        // }


      }
    });

    initNeuronType();
  }

  InfiniteCanvasNode findNeuronByValue(val) {
    var list = controller.nodes.where((element) {
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

  InfiniteCanvasNode findNeuronById(id) {
    var list = controller.nodes
        .where((element) => element.id == id)
        .toList(growable: false);
    return list[0];
  }

  InfiniteCanvasNode findNeuronByKey(key) {
    var list = controller.nodes
        .where((element) => element.key == key)
        .toList(growable: false);
    return list[0];
  }

  void linkLedConnection(double vals) {
    String value = vals.toString();
    if (value.trim().isEmpty) return;
    double val = double.parse(value);
    if (val > 100) {
      val = 100;
    }

    final lastCreatedEdge = controller.edgeSelected;
    final neuronFrom = findNeuronByKey(lastCreatedEdge.from);
    final neuronTo = findNeuronByKey(lastCreatedEdge.to);
    mapLedNeuron["${neuronFrom.id}_${neuronTo.id}"] = val;
    controller.edgeSelected.connectionStrength = val;
    // updateSyntheticConnection(neuronFrom.key, neuronTo.key, val);
  }

  void linkLedAxon(double vals, InfiniteCanvasNode neuronFrom, InfiniteCanvasNode neuronTo) {
    String value = vals.toString();
    if (value.trim().isEmpty) return;
    double val = double.parse(value);
    if (val > 100) {
      val = 100;
    }

    try {
      mapLedNeuron["${neuronFrom.id}_${nodeRedLed.id}"] = double.parse(tecSynapticWeightR.text);
      mapLedNeuron["${neuronFrom.id}_${nodeGreenLed.id}"] = double.parse(tecSynapticWeightG.text);
      mapLedNeuron["${neuronFrom.id}_${nodeBlueLed.id}"] = double.parse(tecSynapticWeightB.text);

      double subtotal = max((mapLedNeuron["${neuronFrom.id}_${nodeRedLed.id}"] ?? 0),
        (mapLedNeuron["${neuronFrom.id}_${nodeGreenLed.id}"] ?? 0) );
      subtotal = max(subtotal,
        (mapLedNeuron["${neuronFrom.id}_${nodeBlueLed.id}"] ?? 0));

      int redColor = (mapLedNeuron["${neuronFrom.id}_${nodeRedLed.id}"] / 100 * 255).floor();
      int greenColor = (mapLedNeuron["${neuronFrom.id}_${nodeGreenLed.id}"] / 100 * 255).floor();
      int blueColor = (mapLedNeuron["${neuronFrom.id}_${nodeBlueLed.id}"] / 100 * 255).floor();
      String hexColor = rgbToHex(
        redColor, 
        greenColor, 
        blueColor);
      tecHexColor.text = hexColor;

      // controller.edgeSelected.connectionStrength = subtotal / 3;
      controller.edgeSelected.connectionStrength = subtotal;
      // neuronFrom.syntheticNeuron.blackBrush = Paint()
      //   ..color = Color.fromARGB(255, redColor, greenColor, blueColor)
      //   // ..color = Colors.yellow
      //   ..style = PaintingStyle.fill
      //   ..strokeWidth = 2;
      controller.edgeSelected.color = Color.fromARGB(255, redColor, greenColor, blueColor);

    }catch(err) {
      printDebug("err");
      printDebug(err);
    }
    // updateSyntheticConnection(neuronFrom.key, neuronTo.key, val);
  }

  void linkNeuronConnection(value) {
    // printDebug("neuron");
    // printDebug(value);
    if (value.trim().length == 0) return;
    double val = double.parse(value);
    if (val > 100) {
      val = 100;
    }
    final lastCreatedEdge = controller.edgeSelected;
    final neuronFrom = findNeuronByKey(lastCreatedEdge.from);
    final neuronTo = findNeuronByKey(lastCreatedEdge.to);

    // mapConnectome["${lastCreatedEdge.from}_${lastCreatedEdge.to}"] = val;
    printDebug("Link Neuron Connection");

    mapConnectome["${neuronFrom.id}_${neuronTo.id}"] = val;
    lastCreatedEdge.connectionStrength = val;
    lastCreatedEdge.label = val.floor().toString();
    // printDebug("${neuronFrom.id}_${neuronTo.id}");
  }

  void linkMotorConnection(value) {
    printDebug("motor");
    printDebug(value);
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
    lastCreatedEdge.connectionStrength = val;
    lastCreatedEdge.label = val.floor().toString();
  }

  void linkSensoryConnection(value) {
    printDebug("sensory");
    printDebug(value);
    final selectedEdge = controller.edgeSelected;
    final neuronFrom = findNeuronByKey(selectedEdge.from);
    final neuronTo = findNeuronByKey(selectedEdge.to);
    String neuronFromToLabel = "${neuronFrom.id}_${neuronTo.id}";
    selectedEdge.label = value;
    // mapSensoryNeuron["${lastCreatedEdge.from}_${lastCreatedEdge.to}"] = value;
    mapSensoryNeuron[neuronFromToLabel] = cameraMenuTypes.indexOf(value);
  }

  void linkAreaSizeConnection(
      {String? selectedCameraPosition,
      InfiniteCanvasNode? nodeFrom,
      InfiniteCanvasNode? nodeTo}) {
    String neuronFromToLabel = "";
    if (nodeFrom != null && nodeTo != null) {
      neuronFromToLabel = "${nodeFrom.id}_${nodeTo.id}";
    } else {
      final selectedEdge = controller.edgeSelected;
      final neuronFrom = findNeuronByKey(selectedEdge.from);
      final neuronTo = findNeuronByKey(selectedEdge.to);
      neuronFromToLabel = "${neuronFrom.id}_${neuronTo.id}";
    }

    if (selectedCameraPosition == "Custom") {
      mapAreaSize[neuronFromToLabel] =
          "${selectedCameraPosition}_@_${txtAreaSizeMinController.text}_@_${txtAreaSizeMaxController.text}";
    } else if (selectedCameraPosition == "Left") {
      mapAreaSize[neuronFromToLabel] = "${selectedCameraPosition}_@_1_@_200";
    } else if (selectedCameraPosition == "Right") {
      mapAreaSize[neuronFromToLabel] = "${selectedCameraPosition}_@_120_@_320";
    } else if (selectedCameraPosition == "Any") {
      mapAreaSize[neuronFromToLabel] = "${selectedCameraPosition}_@_1_@_320";
    }
    // printDebug("mapAreaSize LINK");
    // printDebug(mapAreaSize);
  }

  void linkDistanceConnection(value) {
    final lastCreatedEdge = controller.edgeSelected;
    final neuronFrom = findNeuronByKey(lastCreatedEdge.from);
    final neuronTo = findNeuronByKey(lastCreatedEdge.to);
    lastCreatedEdge.label = value;
    // mapDistanceNeuron["${lastCreatedEdge.from}_${lastCreatedEdge.to}"] = value;
    mapDistanceNeuron["${neuronFrom.id}_${neuronTo.id}"] =
        distanceMenuTypes.indexOf(value);
    printDebug("distanceMenu $distanceMenuType");
    printDebug(mapDistanceNeuron["${neuronFrom.id}_${neuronTo.id}"]);
    printDebug(distanceMinLimitBufView);
    printDebug(distanceMaxLimitBufView);
    int toIdx = neuronTypes.keys.toList().indexOf(neuronTo.id);
    // printDebug(neuronTypes);
    // printDebug(neuronTo);
    // printDebug(toIdx);

    mapDistanceLimitNeuron["${neuronFrom.id}_${neuronTo.id}"] =
        "${distanceMinLimitBufView[toIdx]}_@_${distanceMaxLimitBufView[toIdx]}";
  }

  void initNeuronType() {
    // neuronTypes = {};
    printDebug("init neuron tyep");
    neuronTypes.clear();
    neuronStyles.clear();
    aDesignArray.clear();
    bDesignArray.clear();
    cDesignArray.clear();
    dDesignArray.clear();

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
    // printDebug("longPress");
    // MyApp.analytics.logEvent(
    //   name: 'longpress',
    //   parameters: <String, dynamic>{
    //     'longpress': 'true',
    //   },
    // );
    // if (controller.hasSelection) {
    //   var selected = controller.selection[0];
    //   int neuronIdx =
    //       controller.nodes.map((e) => e.id).toList().indexOf(selected.id) - 2;
    //   // printDebug(neuronIdx);
    //   if (neuronIdx < normalNeuronStartIdx) {
    //     return;
    //   }
    //   isChartSelected = true;
    //   nativec.changeIdxSelected(neuronIdx);

    //   // String neuronType = neuronTypes[neuronIdx];
    //   String neuronType = neuronTypes[selected.id]!;
    //   neuronDialogBuilder(context, "Neuron ", (selected.id).toString(),
    //       neuronType, neuronTypeChangeCallback, deleteNeuronCallback);
    // } else if (controller.isSelectingEdge) {
    //   int isSensoryType = 0;

    //   final lastCreatedEdge = controller.edgeSelected;
    //   InfiniteCanvasNode neuronFrom = findNeuronByKey(lastCreatedEdge.from);
    //   InfiniteCanvasNode neuronTo = findNeuronByKey(lastCreatedEdge.to);
    //   // InfiniteCanvasNode neuronTo = findNeuronByKey(lastCreatedEdge.to);
    //   if (neuronFrom == nodeLeftEyeSensor || neuronFrom == nodeRightEyeSensor) {
    //     isSensoryType = 1;
    //   } else if (neuronTo == nodeLeftMotorBackwardSensor ||
    //       neuronTo == nodeRightMotorBackwardSensor ||
    //       neuronTo == nodeLeftMotorForwardSensor ||
    //       neuronTo == nodeRightMotorForwardSensor) {
    //     isSensoryType = 2;
    //   } else if (neuronFrom == nodeDistanceSensor) isSensoryType = 3;

    //   printDebug("isVisualSensory");
    //   printDebug(isSensoryType);
    //   Map<String, double> map = {
    //     // "connectomeContact": connectomeBufView[ neuronFrom.value * neuronSize + neuronTo.value],
    //     // "neuronContact": neuronContactsBufView[ neuronFrom.value * neuronSize + neuronTo.value],
    //     // "visualPref": visPrefsBufView[ neuronFrom.value * neuronSize + neuronTo.value].toDouble(),
    //     "connectomeContact":
    //         mapConnectome.containsKey("${neuronFrom.id}_${neuronTo.id}")
    //             ? mapConnectome["${neuronFrom.id}_${neuronTo.id}"]
    //             : 0,
    //     "neuronContact":
    //         mapContactsNeuron.containsKey("${neuronFrom.id}_${neuronTo.id}")
    //             ? mapContactsNeuron["${neuronFrom.id}_${neuronTo.id}"]
    //             : 0,
    //     "visualPref":
    //         mapSensoryNeuron.containsKey("${neuronFrom.id}_${neuronTo.id}")
    //             ? mapSensoryNeuron["${neuronFrom.id}_${neuronTo.id}"].toDouble()
    //             : -1.0,
    //     "distanceContact":
    //         mapDistanceNeuron.containsKey("${neuronFrom.id}_${neuronTo.id}")
    //             ? mapDistanceNeuron["${neuronFrom.id}_${neuronTo.id}"]
    //             : -1,
    //   };
    //   axonDialogBuilder(
    //       context,
    //       isSensoryType,
    //       "Edge",
    //       " ",
    //       map,
    //       neuronTypeChangeCallback,
    //       deleteEdgeCallback,
    //       linkSensoryConnection,
    //       linkMotorConnection,
    //       linkNeuronConnection,
    //       linkDistanceConnection);

    //   // axonDialogBuilder(context, isSensoryType, "Edge", " ",  neuronTypeChangeCallback,
    //   //     deleteEdgeCallback, linkSensoryConnection, linkMotorConnection, linkNeuronConnection);
    //   // axonDialogBuilder(
    //   //     context, isSensory, "Edge", " ", neuronTypeChangeCallback, deleteEdgeCallback);
    // }
  }

  void onDoubleTap() {
    if (isSimulatingBrain) return;
    if (controller.scale == 2.0) {
      controller.zoomReset();
      // controller.pan(const Offset(-60, 0));
      controller.scale = 1;
    } else {
      controller.zoomReset();
      controller.zoom(2.0);
      controller.scale = 2.0;
    }
    MyApp.logAnalytic("DoubleTap", {
      "scale": controller.scale,
    });
  }

  void updateFromSimulation(String message) async {
    if (isReceivingCalculation) {
      // printDebug("message");
      // printDebug(message);
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
      savedFileJson) async {
    // double savedRatio = savedFileJson["screenDensity"];
    // double curScale = savedRatio;
    // if (savedRatio >= MediaQuery.of(context).devicePixelRatio) {
    //   curScale = MediaQuery.of(context).devicePixelRatio;
    // }
    double curScale = 1;
    printDebug("curScale111");
    printDebug(curScale);
    SyntheticNeuron syntheticNeuron = SyntheticNeuron(
        // neuronKey: newNodeKey,
        isActive: false,
        isIO: false,
        circleRadius: neuronDrawSize / 2);
    Offset newNodeOffset = Offset(v["position"][0], v["position"][1]);
    if (Platform.isAndroid || Platform.isIOS) {
    }else {
      newNodeOffset = newNodeOffset.scale(curScale, curScale);
    }
    InfiniteCanvasNode tempNode = InfiniteCanvasNode(
      value: v["index"],
      key: nodeKey,
      offset: newNodeOffset,
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

      double centerX = syntheticNeuronJson["centerPos"][0].toDouble();
      double centerY = syntheticNeuronJson["centerPos"][1].toDouble();
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
            xSecondLevel: dendriteJson["xSecondLevel"].toDouble(),
            ySecondLevel: dendriteJson["ySecondLevel"].toDouble(),
            xTriangleFirstLevel: dendriteJson["xTriangleFirstLevel"].toDouble(),
            xTriangleSecondLevel: dendriteJson["xTriangleSecondLevel"].toDouble(),
            yTriangleFirstLevel: dendriteJson["yTriangleFirstLevel"].toDouble(),
            yTriangleSecondLevel: dendriteJson["yTriangleSecondLevel"].toDouble());

        syntheticNeuron.dendrites.add(tempDendrite);
        // dendrites.add(
      }
      printDebug("syntheticNeuronJson['dendrites'].length");
      printDebug(syntheticNeuronJson["dendrites"].length);
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
    printDebug("tempNode.key");
    printDebug(tempNode.id);
    controller.nodes.add(tempNode);
  }

  Future<String> saveCurrentBrain(String title, String description) async {
    // mainBloc.setLoading(1);
    ProgressDialog pd = ProgressDialog(context: context);
    pd.show(msg: 'Saving Brain...');
    printDebug("Save Current Brain");

    MyApp.logAnalytic("SaveFile",
        {"title": title, "timestamp": DateTime.now().millisecondsSinceEpoch});

    var nodesJson = [];
    for (InfiniteCanvasNode e in controller.nodes) {
      // printDebug("e.value == null");
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
        printDebug("e.offset");
        printDebug(e.offset);
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
    // printDebug("json.encode(rawSyntheticNeuronListJson)");
    // printDebug(json.encode(rawSyntheticNeuronListJson));

    // printDebug("strNodesJson");
    // printDebug(strNodesJson);

    String fileName = DateTime.now().microsecondsSinceEpoch.toString();
    Directory directory =
        (await getApplicationDocumentsDirectory()); //from path_provide package

    Directory txtDirectory = Directory(
        "${(await getApplicationDocumentsDirectory()).path}${Platform.pathSeparator}spikerbot${Platform.pathSeparator}text");

    if (!txtDirectory.existsSync()) txtDirectory.createSync();

    // printDebug(directory.path);
    String textPath =
        "${Platform.pathSeparator}spikerbot${Platform.pathSeparator}text";
    // String textPath = "";

    title = title.replaceAll(".", "|");
    description = description.replaceAll(".", "|");
    title = title.replaceAll("@", "#");
    description = description.replaceAll("@", "#");

    final File file = File(
        '${directory.path}$textPath${Platform.pathSeparator}BrainText$fileName@@@$title@@@$description.txt');

    controller.zoomReset();
    if (isPortrait == false) {
      controller.pan(const Offset(-60, 0));
    }
    ScreenshotController screenshotController = ScreenshotController();
    String imagePath = "";

    printDebug("mapLedNeuron");
    printDebug(mapLedNeuron);
    printDebug(nodeSingleLed.id);
    printDebug(nodeRedLed.id);
    printDebug(nodeGreenLed.id);
    printDebug(nodeBlueLed.id);

    await screenshotController
        .captureFromWidget(mainBody)
        .then((imageBytes) async {
      String strNodesJson = json.encode({
        "version": strFileVersion,
        "nodes": nodesJson,
        "edges": edgesJson,
        "neuronTypes": neuronTypes,
        "neuronStyles": neuronStyles,
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
        "mapAreaSize": mapAreaSize,
        "a": aBufView.toList(),
        "b": bBufView.toList(),
        "c": cBufView.toList(),
        "d": dBufView.toList(),
        "i": iBufView.toList(),
        "w": wBufView.toList(),
        "windowWidth": MediaQuery.of(context).size.width,
        "windowHeight": MediaQuery.of(context).size.height,
        "screenDensity": MediaQuery.of(context).devicePixelRatio,
        "screenshot": imageBytes,
      });

      // strNodesJson["image"] = imageBytes;
      await file.writeAsString(strNodesJson);
      pd.close();

      Future.delayed(const Duration(seconds: 1), () {
        rightToolbarCallback({"menuIdx": 0});
        setState(() {});
      });
      imagePath = file.path;

      // mainBloc.setLoading(0);
    });
    return imagePath;
  }

  void selectSavedBrain(String filename, {String? filePath}) async {
    MyApp.logAnalytic("LoadFile", {
      "filename": filename,
      "timestamp": DateTime.now().millisecondsSinceEpoch
    });
    String textPath =
        "${Platform.pathSeparator}spikerbot${Platform.pathSeparator}text";
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
        '${directory.path}$textPath${Platform.pathSeparator}$filename.txt');
    String savedFileText = await savedFile.readAsString();
    Map savedFileJson = json.decode(savedFileText);
    if (savedFileJson["version"] == null) {
      savedFileJson["nodes"].forEach((node) {
        // printDebug("node");
        // printDebug(node);
        // if (node["index"] >= 9 && node["index"] <= 11) {
        if (node["index"] >= 9) {
          node["index"]++;
        }
      });
      savedFileJson["nodes"].add(
        {
          "valKey": nodeSingleLed.id,
          "index": 9,
          "position": [
            0,
            0
          ],
          "color": [
            280,
            520
          ],
          "shape": "CustomPaint"
        },        
      );
      savedFileJson["neuronTypes"][nodeSingleLed.id] = "Quiet";
      savedFileJson["neuronStyles"][nodeSingleLed.id] = "Quiet";
      savedFileJson["a"].insert(9, 0.02);
      savedFileJson["b"].insert(9, 0.18);
      savedFileJson["c"].insert(9, -65);
      savedFileJson["d"].insert(9, 2);
      savedFileJson["i"].insert(9, 5);
      savedFileJson["w"].insert(9, 2);
      savedFileJson["mapDelayNeuron"].insert(9, -1);
      savedFileJson["mapRhytmicNeuron"].insert(9, -1);
      savedFileJson["mapCountingNeuron"].insert(9, -1);
      savedFileJson["rawSyntheticNeuron"].insert(9, savedFileJson["rawSyntheticNeuron"][0]);
    }

    // printDebug(json.encode(savedFileJson["nodes"]));

    // END OF READING FILE

    double tempWidth = MediaQuery.of(context).size.width;
    double tempHeight = MediaQuery.of(context).size.height;

    print("Sizing!!");
    print(savedFileJson["windowWidth"] != null);
    print(savedFileJson["windowHeight"] != null);
    try {
      if (savedFileJson["windowWidth"] != null) {
        double displayWidth = savedFileJson["windowWidth"].toDouble();
        double displayHeight = savedFileJson["windowHeight"].toDouble();
        // double displayWidth = savedFileJson["windowWidth"] *
        //     savedFileJson["screenDensity"] /
        //     MediaQuery.of(context).devicePixelRatio;
        // double displayHeight = savedFileJson["windowHeight"] *
        //     savedFileJson["screenDensity"] /
        //     MediaQuery.of(context).devicePixelRatio;
        // printDebug("change window size");
        print(displayWidth);
        print(displayHeight);

        if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
          await windowManager.setSize(Size(displayWidth, displayHeight));
        }
      }
    } catch (err) {
      printDebug("err2");
      printDebug(err);
    }

    await Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {});
    });
    // printDebug("change window size finished");

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
      // printDebug("v");
      // printDebug(v);
      String loadedNeuronKey = v["valKey"];
      if (v["index"] == -2 || v["index"] == -1) {
        printDebug("shadow neuron");
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
        // printDebug("rawSyntheticNeuronList.length 0");
        // printDebug(rawSyntheticNeuronList.length);
      } else if (v["index"] < normalNeuronStartIdx) {
        InfiniteCanvasNode neuron = findNeuronByValue(v["index"]);
        neuron.valKey = loadedNeuronKey;
        tempNeuronsKey.add(neuron.key);
        mapTranslateLoadKeys[neuron.valKey] = neuron.id;
        /*
        SyntheticNeuron synNeuron = SyntheticNeuron(
            isActive: false, isIO: true, circleRadius: neuronDrawSize / 2);
        // if (v["index"] == 0) {
        //   printDebug('v["index"]');
        //   printDebug(neuron.key.toString());
        //   printDebug(neuron.offset.dx);
        //   printDebug(neuron.offset.dy);
        // }
        synNeuron.node = controller.nodes[v["index"] + allNeuronStartIdx];
        synNeuron.setupDrawingNeuron();
        synNeuron.newNeuron.x = synNeuron.newNeuron.drawX + neuron.offset.dx;
        synNeuron.newNeuron.y = synNeuron.newNeuron.drawY + neuron.offset.dy;
        printDebug(
            "XSynFrom: ${synNeuron.newNeuron.drawX} _ ${synNeuron.newNeuron.x}");
        printDebug(
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
          */
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
    printDebug("Map translated Load Keys ${syntheticNeuronList.length}");

    mapConnectome = translateLoadedMap(
        savedFileJson["mapConnectome"], mapTranslateLoadKeys);

    List<dynamic> edgesJson = savedFileJson["edges"];
    Map<String, dynamic> tempMap = {};
    for (var v in edgesJson) {
      List<String> arr = v.toString().split("_#_");
      InfiniteCanvasNode nodeFrom = findNeuronByValueKey((arr[0]));
      InfiniteCanvasNode nodeTo = findNeuronByValueKey((arr[1]));

      InfiniteCanvasEdge edge = InfiniteCanvasEdge(
        from: nodeFrom.key,
        to: nodeTo.key,
      );
      if (nodeTo.id == nodeRedLed.id || nodeTo.id == nodeBlueLed.id || nodeTo.id == nodeGreenLed.id) {
        String targetKey = "${nodeFrom.id}_${nodeSingleLed.id}";
        if (tempMap[targetKey] == null) {
          edge = InfiniteCanvasEdge(
            from: nodeFrom.key,
            to: nodeSingleLed.key,
          );
          tempMap[targetKey] = 1;
        } else {
          continue;
        }
      }
      
      String connectionKey = "${nodeFrom.id}_${nodeTo.id}";
      edge.connectionStrength = mapConnectome[connectionKey] ?? 0;

      controller.edges.add(edge);
    }
    printDebug("Edges");

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
      printDebug("Distance Limit not found");
    }
    try {
      mapAreaSize = translateLoadedMap(
          savedFileJson["mapAreaSize"], mapTranslateLoadKeys);
    } catch (err) {
      printDebug("Distance Limit not found");
    }
    mapSpeakerNeuron = translateLoadedMap(
        savedFileJson["mapSpeakerNeuron"], mapTranslateLoadKeys);
    mapMicrophoneNeuron = translateLoadedMap(
        savedFileJson["mapMicrophoneNeuron"], mapTranslateLoadKeys);
    // printDebug("mapLedNeuron");
    // printDebug(savedFileJson["mapLedNeuron"]);
    mapLedNeuron =
        translateLoadedMap(savedFileJson["mapLedNeuron"], mapTranslateLoadKeys);
    // printDebug(mapLedNeuron);
    // printDebug("====mapLedNeuron");

    if (savedFileJson["version"] == null) {
      Map<String, dynamic> tempMapLedNeuronPosition = savedFileJson["mapLedNeuronPosition"] == null
          ? {}
          : translateLoadedMap(
              savedFileJson["mapLedNeuronPosition"], mapTranslateLoadKeys);
      mapLedNeuronPosition.clear();
      tempMapLedNeuronPosition.keys.toList().forEach((key) {
        List<String> arr = key.split("_");
        String targetKey = "${arr[0]}_${nodeRedLed.id}";
        mapLedNeuronPosition[targetKey] = tempMapLedNeuronPosition[key];
      });
    } else {
      mapLedNeuronPosition = savedFileJson["mapLedNeuronPosition"] == null
          ? {}
          : translateLoadedMap(
              savedFileJson["mapLedNeuronPosition"], mapTranslateLoadKeys);

    }
    
    printDebug("mapLedNeuronPosition");
    printDebug(savedFileJson["mapLedNeuronPosition"]);
    printDebug(mapLedNeuronPosition);

    // neuronTypes = List<String>.from(savedFileJson["neuronTypes"]);
    Map<String, String> tempNeuronTypes = translateLoadedNeuron(
        savedFileJson["neuronTypes"], mapTranslateLoadKeys);
    // printDebug("mapDistanceLimitNeuron");
    // printDebug(mapDistanceLimitNeuron);
    neuronTypes.clear();
    tempNeuronTypes.forEach((key, value) {
      neuronTypes[key] = value;
    });

    if (savedFileJson["neuronStyles"] != null) {
      neuronStyles = translateLoadedNeuron(
          savedFileJson["neuronStyles"], mapTranslateLoadKeys);
      for (String key in neuronStyles.keys) {
        InfiniteCanvasNode node = findNeuronById(key);
        if (neuronStyles[key] == "Inhibitory") {
          node.isExcitatory = 0;
        } else {
          node.isExcitatory = 1;
        }
      }
    }

    neuronSize = controller.nodes.length - 2;
    neuronsKey = List<UniqueKey>.from(tempNeuronsKey);

    initNativeC(true);
    // printDebug(savedFileJson["a"]);
    printDebug("mapContactsNeuron");
    printDebug(mapContactsNeuron);
    rawPos = [];
    for (InfiniteCanvasNode node in controller.nodes) {
      Offset position = controller.toLocal(node.offset);
      rawPos.add(position);
    }

    int nodeLength = controller.nodes.length;
    for (int neuronIdx = normalNeuronStartIdx + 2; neuronIdx < nodeLength; neuronIdx++) {
      String nodeKey = controller.nodes[neuronIdx].id;
      controller.nodes[neuronIdx].label = neuronTypes[nodeKey];
    }
    for (InfiniteCanvasEdge edge in controller.edges) {
      if ( nodeLeftEyeSensor.key == edge.from) {
        int sensoryIdx = mapSensoryNeuron["${edge.from}_${edge.to}"];
        edge.label = cameraMenuTypes[sensoryIdx];
      } else
      if ( nodeDistanceSensor.key == edge.from) {
        int sensoryIdx = mapDistanceNeuron["${edge.from}_${edge.to}"];
        edge.label = distanceMenuTypes[sensoryIdx];
      } else
      if ( nodeSpeakerSensor.key == edge.to) {
        String sensoryIdx = "${edge.from}_${edge.to}";
        edge.label = mapSpeakerNeuron[sensoryIdx].floor().toString();
      } else
      if ( nodeLeftMotorForwardSensor.key == edge.to || nodeLeftMotorBackwardSensor.key == edge.to) {
        String sensoryIdx = "${edge.from}_${edge.to}";
        edge.label = mapContactsNeuron[sensoryIdx].floor().toString();
      } else
      if ( nodeRightMotorForwardSensor.key == edge.to || nodeRightMotorBackwardSensor.key == edge.to) {
        String sensoryIdx = "${edge.from}_${edge.to}";
        edge.label = mapContactsNeuron[sensoryIdx].floor().toString();
      } else 
      if ( nodeSingleLed.key == edge.to ) {
        // printDebug("nodeSingleLed.key == edge.to");
        double subtotal = max(( (mapLedNeuron["${edge.from}_${nodeRedLed.id}"] ?? 0).toDouble() ?? 0),
          ( (mapLedNeuron["${edge.from}_${nodeGreenLed.id}"] ?? 0).toDouble() ?? 0) );
        subtotal = max(subtotal,
          ((mapLedNeuron["${edge.from}_${nodeBlueLed.id}"] ?? 0).toDouble() ?? 0));
        edge.connectionStrength = subtotal;

        InfiniteCanvasNode nodeFrom = findNeuronByKey(edge.from);
        int redColor = ( (mapLedNeuron["${nodeFrom.id}_${nodeRedLed.id}"] ?? 0) / 100 * 255).floor();
        int greenColor = ( (mapLedNeuron["${nodeFrom.id}_${nodeGreenLed.id}"] ?? 0) / 100 * 255).floor();
        int blueColor = ( (mapLedNeuron["${nodeFrom.id}_${nodeBlueLed.id}"]  ?? 0) / 100 * 255).floor();
        // nodeFrom.syntheticNeuron.blackBrush = Paint()
        //   ..color = Color.fromARGB(255, redColor, greenColor, blueColor)
        //   // ..color = Colors.yellow
        //   ..style = PaintingStyle.fill
        //   ..strokeWidth = 2;                        
        edge.color = Color.fromARGB(255, redColor, greenColor, blueColor);
        // COLORIZED NEURON
        
      } else
      {
        String sensoryIdx = "${edge.from}_${edge.to}";
        if (mapConnectome[sensoryIdx] != null ) {
          edge.label = mapConnectome[sensoryIdx].floor().toString();
        }
      }
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
    printDebug("neuronTypes.length");
    printDebug(neuronTypes.length);
    printDebug(aBufList.length);
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

      // printDebug("delayBufList");
      // printDebug(delayBufList);
      // printDebug(rhytmicBufList);
      // printDebug(countingBufList);
      // printDebug("delayBufList");
      // printDebug(delayBufList);
      // printDebug(rhytmicBufList);
      // printDebug(countingBufList);
      mapDelayNeuronList = List.generate(n, (index) => -1);
      mapRhytmicNeuronList = List.generate(n, (index) => -1);
      mapCountingNeuronList = List.generate(n, (index) => -1);
      for (int i = 0; i < n; i++) {
        mapDelayNeuronList[i] = delayBufList[i];
        mapRhytmicNeuronList[i] = rhytmicBufList[i];
        mapCountingNeuronList[i] = countingBufList[i];
      }
      printDebug(mapDelayNeuronBufView);
    } catch (err) {
      printDebug("err3");
      printDebug(err);
    }
    if (Platform.isIOS || Platform.isAndroid || kIsWeb) {
      silentRepositionNeurons(savedFileJson);
    }

    await Future.delayed(const Duration(milliseconds: 370), () async {
      try {
        if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
          await windowManager.setSize(Size(tempWidth, tempHeight));
        }
      } catch (err) {
        printDebug("windowmanager error");
        printDebug(err);
      }
    });

    // }
    // aDesignArray = List<double>.from(savedFileJson["a"]);
    // bDesignArray = List<double>.from(savedFileJson["b"]);
    // cDesignArray = List<int>.from(savedFileJson["c"]);
    // dDesignArray = List<int>.from(savedFileJson["d"]);
    // iBufView = Float64List.fromList(List<double>.from(savedFileJson["i"]));
    // wBufView = Float64List.fromList(List<double>.from(savedFileJson["w"]));

    // printDebug("Loaded Neuron Type : ");
    // printDebug(neuronTypes);
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

    // printDebug("scale");
    // printDebug(scale);
    // printDebug("circle");
    // printDebug(protoNeuron.circles.last.centerPos);

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

        // printDebug("pos");
        // printDebug(pos);

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

          // printDebug("--------" + idx.toString());
          // printDebug(controller.toLocal(node.offset));
          // printDebug(rawPosition);
          // printDebug(rawPosition - delta);
          // printDebug(rawDelta);

          // pos.add(Offset(position.dx, position.dy));
          // pos.add(node.offset);
        }
        // printDebug("======= controller.toLocal(node.offset) 1.5");
        // printDebug(pos.last);
        // printDebug(rawPos.last);

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
    printDebug("mapTranslateLoadKeys");
    printDebug(mapTranslateLoadKeys);
    targetMap?.forEach((key, value) {
      // printDebug("loaded Neuron");
      // printDebug(key);
      if (mapTranslateLoadKeys.containsKey(key)) {
        String translatedKey = mapTranslateLoadKeys[key]!;
        transformedMap[translatedKey] = value;
      } else {
        // printDebug("WRONGG key");
        // printDebug(key);
        // printDebug(value);
      }
    });
    return transformedMap;
  }

  Map<String, dynamic> translateLoadedMap(Map<String, dynamic> targetMap,
      Map<String, String> mapTranslateLoadKeys) {
    // printDebug("mapTranslateLoadKeys");
    // printDebug(mapTranslateLoadKeys);
    Map<String, dynamic> transformedMap = {};
    // print("mapTranslateLoadKeys");
    // print(mapTranslateLoadKeys);
    targetMap.forEach((key, value) {
      // printDebug("key");
      // printDebug(key);
      List<String> arr = key.split("_");

      try {
        String translatedKey0 = mapTranslateLoadKeys[arr[0]]!;
        String translatedKey1 = mapTranslateLoadKeys[arr[1]]!;
        String combineTranslatedKey = "${translatedKey0}_$translatedKey1";
        // printDebug(combineTranslatedKey);
        transformedMap[combineTranslatedKey] = value;
      } catch (err) {
        printDebug("arr[0]");
        printDebug(arr[0]);
      }
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
      InfiniteCanvasNode selected = findNeuronByKey(controller.edgeSelected.to);
      int neuronIdx = neuronTypes.keys.toList().indexOf(selected.id);

      // mapSensoryNeuron["${lastCreatedEdge.from}_${lastCreatedEdge.to}"] = value;
      // printDebug("nodeFrom.id_nodeTo.id");
      // printDebug("${nodeFrom.id}_${nodeTo.id}");
      // printDebug(mapSensoryNeuron["${nodeFrom.id}_${nodeTo.id}"]);
      String sensoryKey = "${nodeFrom.id}_${nodeTo.id}";
      if (mapSensoryNeuron[sensoryKey] != null) {
        cameraMenuType = cameraMenuTypes[mapSensoryNeuron[sensoryKey]];
        int idx = mapSensoryNeuron[sensoryKey];
        if (idx < 7) {
          selectedEyeInfo = {
            "icon": cameraMenuTypes[idx],
            "label": "Color ${cameraMenuTypes[idx]}",
            "idx": idx
          };
        } else {
          selectedEyeInfo = {
            "icon": lookup[cameraMenuTypes[idx]],
            "label": cameraMenuTypes[idx],
            "idx": idx
          };
        }
        selectedCameraRegion = mapAreaSize[sensoryKey];
        List<String> splitRegion = selectedCameraRegion.split("_@_");
        selectedCameraPosition = splitRegion[0];
        txtAreaSizeMinController.text = splitRegion[1];
        txtAreaSizeMaxController.text = splitRegion[2];
        areaSizeMinLimitBufView[neuronIdx] = int.parse(splitRegion[1]);
        areaSizeMaxLimitBufView[neuronIdx] = int.parse(splitRegion[2]);
        //  = "${selectedCameraPosition}_@_${txtAreaSizeMinController.text}_@_${txtAreaSizeMaxController.text}";
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
      printDebug("nodeRightMotorBackwardSensor");
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
    } else if (nodeTo == nodeSingleLed || nodeTo == nodeRedLed ||
        nodeTo == nodeGreenLed ||
        nodeTo == nodeBlueLed) {
      isLedMenu = true;
      // printDebug('mapLedNeuron["${nodeFrom.id}_${nodeTo.id}"]');
      // printDebug(mapLedNeuron["${nodeFrom.id}_${nodeTo.id}"]);

      sldSynapticWeightR = fillDefaultData(mapLedNeuron, "${nodeFrom.id}_${nodeRedLed.id}", tecSynapticWeightR);
      sldSynapticWeightG = fillDefaultData(mapLedNeuron, "${nodeFrom.id}_${nodeGreenLed.id}", tecSynapticWeightG);
      sldSynapticWeightB = fillDefaultData(mapLedNeuron, "${nodeFrom.id}_${nodeBlueLed.id}", tecSynapticWeightB);
      String hexColor = rgbToHex( (sldSynapticWeightR / 100 * 255).floor(), (sldSynapticWeightG / 100 * 255).floor(), (sldSynapticWeightB / 100 * 255).floor());
      tecHexColor.text = hexColor;

      printDebug('sldSynapticWeightR $sldSynapticWeightR');
      printDebug('sldSynapticWeightG $sldSynapticWeightG');
      printDebug('sldSynapticWeightB $sldSynapticWeightB');

      if (mapLedNeuronPosition["${nodeFrom.id}_${nodeRedLed.id}"] != null) {
        isActiveLeds[0] =
            mapLedNeuronPosition["${nodeFrom.id}_${nodeRedLed.id}"][0];
        isActiveLeds[1] =
            mapLedNeuronPosition["${nodeFrom.id}_${nodeRedLed.id}"][1];
        isActiveLeds[2] =
            mapLedNeuronPosition["${nodeFrom.id}_${nodeRedLed.id}"][2];
        isActiveLeds[3] =
            mapLedNeuronPosition["${nodeFrom.id}_${nodeRedLed.id}"][3];
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
    lastCreatedEdge.connectionStrength = ((val / 4978) * 100).toDouble();
    lastCreatedEdge.label = val.floor().toString();
    // printDebug("${neuronFrom.id}_${neuronTo.id}");
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
    lastCreatedEdge.connectionStrength = (val / 5000).ceil().toDouble();
    // printDebug("${neuronFrom.id}_${neuronTo.id}");
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
    // Future.delayed(const Duration(milliseconds: 500), () {
    setDataOnLeave();
    controller.isSelectingEdge = false;
    isSelectingCameraTarget = false;
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
    // });
  }

  void resizeIzhikevichParameters(int neuronSize) {
    // aBufView = aBuf.asTypedList(neuronSize);
    // bBufView = bBuf.asTypedList(neuronSize);
    // cBufView = cBuf.asTypedList(neuronSize);
    // dBufView = dBuf.asTypedList(neuronSize);
  }

  List<String> empty = [];
  double multiplierConstant = 0.78;
  double multiplierAdjusterConstant = 0.5;
  int robotMessageDelay = 75;
  List<int> infoStatusMax = [];
  List<List<int>> diodeStatusMax = [];
  List<int> periodicNeuronSpikingFlags = [];
  void processRobotMessages() {
    Future.delayed(Duration(milliseconds: robotMessageDelay), () {
      infoStatusMax = [0, 0, 0, 0, 0, 0, 0];
      // nodeBlueLed.offset = Offset.zero;
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
      // printDebug("processRobotMessages Delay");
      if (isPlayingMenu) {
        // printDebug("processRobotMessages");
        int nowTime = DateTime.now().millisecondsSinceEpoch;
        // printDebug("nowTime");
        // printDebug(nowTime);
        if (nowTime - previousBufferTime >= robotMessageDelay) {
          previousBufferTime = nowTime;
        } else {
          // processRobotMessages();
          // return;
        }

        try {
          List<String> commands = commandList.toList();
          // printDebug("commands.isNotEmpty");
          // printDebug(commands);

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
            // printDebug(commands.length);
            int len = commands.length;
            int leftValidValueCounter = 0;
            int rightValidValueCounter = 0;
            for (int i = 0; i < len; i++) {
              List<String> arr = commands[i].split(";");
              int n = arr.length;
              for (int j = 0; j < n; j++) {
                List<String> arrStr = arr[j].split(":");
                if (arrStr[0] == "l") {
                  int val = int.parse(arrStr[1]);
                  if (val.abs() >= 5) {
                    leftValidValueCounter++;
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
                    rightValidValueCounter++;
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
                  // printDebug("spikingFlags");
                  // printDebug(spikingFlags);
                  // printDebug(periodicNeuronSpikingFlags);

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
                  // printDebug("diodeSplit");
                  // printDebug(diodeSplit);
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
            // printDebug("diodeString");
            // printDebug(diodeString);
            // printDebug(leftSumValue);
            // printDebug(leftValidValueCounter);
            // printDebug(rightSumValue );
            // printDebug(rightValidValueCounter);
            // printDebug("infoStatusMax");
            // printDebug(infoStatusMax);

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
              if (leftSumValue == 0 && leftValidValueCounter == 0) {
                leftSumValue = 0;
              } else {
                leftSumValue = leftSumValue / leftValidValueCounter;
              }
              double calculatedValue = leftSumValue.sign *
                  ((leftSumValue.abs() - 250) * multiplierConstant + 250);
              // print("calculatedValue left");
              // print(calculatedValue);
              avgLeft = (calculatedValue).floor();
            }
            if (rightAttentionValue[0] == len) {
              avgRight = 0;
            } else {
              if (rightSumValue == 0 && rightValidValueCounter == 0) {
                rightSumValue = 0;
              } else {
                rightSumValue = rightSumValue / rightValidValueCounter;
              }
              
              double calculatedValue = rightSumValue.sign *
                  ((rightSumValue.abs() - 250) * multiplierConstant + 250);
              // print("calculatedValue right");
              // print(calculatedValue);
              avgRight = (calculatedValue).floor();
            }
            // printDebug("avgLeft");
            // printDebug(len);
            // printDebug(avgLeft);
            // printDebug(avgRight);
            // printDebug(validValueCounter);
            // printDebug("===============");
            // avgLeft = -60;
            // avgRight = 60;
            msg =
                "l:${avgLeft};r:${avgRight};s:${infoStatusMax[2]};$diodeString";
// */
            if (isIsolateWritePortInitialized) {
              // printDebug("msg");
              // printDebug(msg);
              // printDebug(infoStatusMax);
              // printDebug(periodicNeuronSpikingFlags);
              _DesignBrainPageState.isolateWritePort.send(msg);
            }

            try {
              for (int i = normalNeuronStartIdx; i < neuronSize; i++) {
                int neuronIndex = i;
                if (periodicNeuronSpikingFlags[i - normalNeuronStartIdx] == 1) {
                  if (controller.nucleusList != null &&
                      controller.nucleusList!.length > normalNeuronStartIdx) {
                    controller.nucleusList![neuronIndex].isSpiking = 1;
                  }
                  // protoNeuron.circles[neuronIndex].isSpiking = 1;
                  neuronSpikeFlags[neuronIndex].value = Random().nextInt(10000);
                  // printDebug("neuronSpikeFlags1");
                  // printDebug(controller.nucleusList!.length);
                  // printDebug(neuronSpikeFlags);
                } else {
                  try {
                    // protoNeuron.circles[neuronIndex].isSpiking = -1;
                    if (controller.nucleusList != null &&
                        controller.nucleusList!.length > normalNeuronStartIdx) {
                      controller.nucleusList![neuronIndex].isSpiking = -1;
                    }

                    neuronSpikeFlags[neuronIndex].value =
                        Random().nextInt(10000);
                    // printDebug("neuronSpikeFlags2");
                    // printDebug(neuronSpikeFlags);
                  } catch (err) {
                    printDebug("err neuronSpikeFlags2");
                    printDebug(err);
                  }
                }
              }
            } catch (err) {
              printDebug("err2");
              printDebug(err);
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
          printDebug("error Robot message");
          printDebug(err);
        }
      }
      commandList.clear();
      // printDebug("command list clear");

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
        if (key.contains(nodeLeftEyeSensor.id)) {
          isShowingLeftAiMenu = true;
          aiVisualTypes++;
        } else if (key.contains(nodeRightEyeSensor.id)) {
          isShowingRightAiMenu = true;
          aiVisualTypes++;
        }
      } else {
        if (key.contains(nodeLeftEyeSensor.id)) {
          isShowingLeftColorMenu = true;
          imageVisualTypes++;
        } else if (key.contains(nodeRightEyeSensor.id)) {
          isShowingRightColorMenu = true;
          imageVisualTypes++;
        }
      }
    }
  }

  void refillMapNeuronType() {
    mapNeuronTypeBufView.fillRange(0, neuronSize, -1);
  }

  bool containImage(Rect location, List<String> modes) {
    int xStart = int.parse(modes[1]);
    int xEnd = int.parse(modes[2]);
    printDebug("_____Contain Image location Method");
    printDebug(location);
    printDebug(modes);
    if (modes[0] == "Left") {
      if (location.center.dx < xEnd && location.center.dx >= xStart) {
        return true;
      } else {
        return false;
      }
    } else if (modes[0] == "Right") {
      if (location.center.dx > xStart && location.center.dx <= xEnd) {
        return true;
      } else {
        return false;
      }
    } else if (modes[0] == "Any") {
      // any
      return true;
    } else if (modes[0] == "Custom") {
      // custom
      if (location.center.dx >= xStart && location.center.dx <= xEnd) {
        return true;
      } else {
        return false;
      }
    }
    return false;
  }

  void updateSyntheticConnection(
      LocalKey from, LocalKey to, double sldSynapticWeight) {
    final lastCreatedEdge = controller.edgeSelected;
    if (neuronStyles[from.toString()] == "Inhibitory") {
      lastCreatedEdge.connectionStrength = sldSynapticWeight;
    } else {
      lastCreatedEdge.connectionStrength = sldSynapticWeight;
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
    "assets/bg/BrainDrawings/LEDBlack.svg",
  ];

  List<Map<String, dynamic>> dropTargetInformations = [
    {
      "left": 150.0,
      "top": 5.0,
      "offset": const Offset(300, 170),
      "size": const Size(95, 125),
      "zoneArea": [-1, -1],
      "xDiff": 20,
      "yDiff": 4,
      "posXDiff": -285,
      "posYDiff": 0,
    }, // distance
    {
      "left": 350.0,
      "top": 0.0,
      "offset": const Offset(310, 140),
      "size": const Size(175, 100),
      "zoneArea": [1, 0],
      "xDiff": 216,
      "yDiff": 5,
      "posXDiff": -85,
      "posYDiff": 0,
    }, // left eye sensor
    {
      "left": 0.0,
      "top": 0.0,
      "offset": const Offset(0, 0),
      "size": const Size(0, 0),
      "zoneArea": [0, 0],
      "xDiff": 0,
      "yDiff": 0,
      "posXDiff": 0,
      "posYDiff": 0,
    }, // right eye sensor
    {
      "left": 135.0,
      "top": 200.0,
      "offset": const Offset(240, 220),
      "size": const Size(65, 125),
      "zoneArea": [-1, 0],
      "xDiff": 0,
      "yDiff": 200,
      "posXDiff": -300,
      "posYDiff": 0,
    }, // left motor UP
    {
      "left": 655.0,
      "top": 200.0,
      "offset": const Offset(525, 240),
      "size": const Size(65, 125),
      "zoneArea": [1, 0],
      "xDiff": 521,
      "yDiff": 200,
      "posXDiff": 220,
      "posYDiff": 0,
    }, // right motor UP
    {
      "left": 135.0,
      "top": 320.0,
      "offset": const Offset(255, 370),
      "size": const Size(65, 125),
      "zoneArea": [-1, 1],
      "xDiff": 0,
      "yDiff": 322,
      "posXDiff": -300,
      "posYDiff": 0,
    }, // left motor Down
    {
      "left": 655.0,
      "top": 320.0,
      "offset": const Offset(525, 340),
      "size": const Size(65, 125),
      "zoneArea": [1, 1],
      "xDiff": 521,
      "yDiff": 323,
      "posXDiff": 220,
      "posYDiff": 0,
    }, // right motor Down
    {
      "left": 590.0,
      "top": 0.0,
      "offset": const Offset(470, 240),
      "size": const Size(130, 160),
      "zoneArea": [1, -1],
      "xDiff": 457,
      "yDiff": 7,
      "posXDiff": 155,
      "posYDiff": 0,
    }, // microphone
    {
      "left": 580.0,
      "top": 460.0,
      "offset": const Offset(470, 410),
      "size": const Size(145, 140),
      "zoneArea": [1, 1],
      "xDiff": 445,
      "yDiff": 466,
      "posXDiff": 145,
      "posYDiff": 0,
    }, // Speaker
    {
      "left": 0.0,
      "top": 480.0,
      "offset": const Offset(00, 00),
      "size": const Size(165, 110),
      "zoneArea": [-1, 1],
      "xDiff": 0,
      "yDiff": 485,
      "posXDiff": -300,
      "posYDiff": 0,
    }, // LED

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
    double minimumSize = initialMinimumSize.height;
    double widthRatio = currentImageWidth / minimumSize;
    double heightRatio = currentImageHeight / minimumSize;
    scaleMultiplier = min(widthRatio, heightRatio);
    // scaleMultiplier = 1.05;
    // printDebug("coreBrainPainter");
    // printDebug("topInnerWindowSpace");
    // printDebug(initialMinimumSize);
    // printDebug(leftInnerWindowSpace - 135);
    // printDebug(scaleMultiplier);
    // printDebug((leftInnerWindowSpace - 135) * scaleMultiplier);

    // 870/2 = 435 - 245 = 190 + brainDiff = ±245
    // 600/2 = 300
    // double leftBrainPosition = windowWidth / 2 - 245 * scaleMultiplier;
    double leftBrainPosition = windowWidth / 2 - 245 * scaleMultiplier;
    Size brainSizeMultiplier = brainSize * scaleMultiplier;

    coreBrainPainter = GeneralSensorPainter(
        polygonPath: sensorPolygonPaths[sensorPolygonPaths.length - 1],
        positionDiff: [
          brainDiff.width,
          brainDiff.height,
        ],
        multiplier: scaleMultiplier);
    InfiniteDropTarget brainTarget = InfiniteDropTarget(
      key: UniqueKey(),
      // offset: const Offset(200, 90),
      offset: Offset(brainPosition.dx, brainPosition.dy),
      size: brainSizeMultiplier,
      // color: Colors.green,
      child: Positioned(
        top: brainPosition.dy + topInnerWindowSpace,
        left: leftBrainPosition,
        // left: ((brainPosition.dx).floor() * scaleMultiplier +
        //     (leftInnerWindowSpace - 137) * scaleMultiplier),
        child: SizedBox(
          width: brainSizeMultiplier.width,
          height: brainSizeMultiplier.height,
          // color: Colors.green,
          child: DragTarget(
              // hitTestBehavior: HitTestBehavior.opaque,
              onMove: (dragDetail) async {
            Offset localAreaOffset = controller
                .toLocal(Offset(dragDetail.offset.dx, dragDetail.offset.dy));

            GeneralSensorPainter painter = (coreBrainPainter);
            Offset containOffset = localAreaOffset.translate(
                -leftBrainPosition + 45 / controller.getScale(),
                -brainPosition.dy * scaleMultiplier +
                    topInnerWindowSpace +
                    45 / controller.getScale());
            // -leftBrainPosition + 45 / controller.getScale(),
            // -brainPosition.dy * scaleMultiplier +
            //     topInnerWindowSpace +
            //     45 / controller.getScale());
            // localAreaOffset.translate(-painter.xDiff, -painter.yDiff);
            bool isContaining = painter.path.contains(containOffset);
            printDebug("------localAreaOffset core brain");
            printDebug(containOffset);
            printDebug(isContaining);
            if (isContaining) {
              brainContainedIdx = 0;

              if (mapBg["activeComponent"] == activeBrainComponent) {
              } else {
                mapBg["activeComponent"] = activeBrainComponent;
                // if (soloud !=null && soloud!.activeSounds.contains(neuronOnTouchSource)) {
                if (prevSoundIdx != -1) {
                  prevSoundIdx = -1;
                  await soloud?.play(neuronOnTouchSource!).then((handle) {
                    neuronOnTouchHandle = handle;
                  });
                }
                // }
                debouncerActiveArea.run(() {
                  setState(() {});
                });

                // Future.delayed(const Duration(milliseconds: 027), () {
                //   setState(() {});
                // });
              }
            } else {
              isBrainTargetOverlayTop = -1;
              brainContainedIdx = -1;

              if (mapBg["activeComponent"] == noActiveComponent) {
              } else {
                if (soloud !=null && neuronOnTouchHandle != null) {                
                  soloud?.stop(neuronOnTouchHandle!);
                }
                mapBg["activeComponent"] = noActiveComponent;
                debouncerActiveArea.run(() {
                  setState(() {});
                });
                // Future.delayed(const Duration(milliseconds: 027), () {
                //   setState(() {});
                // });
              }
            }
          }, onWillAcceptWithDetails: (dragDetail) {
            // printDebug("onWillAcceptWithDetails brain" +
            //     controller.toLocal(dragDetail.offset).toString());
            // mapBg["activeBg"] = greyBg;
            // mapBg["activeComponent"] = activeBrainComponent;
            debouncerActiveArea.run(() {
              setState(() {});
            });

            // Future.delayed(const Duration(milliseconds: 027), () {
            //   setState(() {});
            // });
            if (dragDetail.data as int < 2) {
              printDebug("containedIdx NOT containing brain");
              printDebug(brainContainedIdx);

              return true;
            } else {
              printDebug("return false");
              return false;
            }
          }, onAcceptWithDetails: (value) async {
            if (isPlayingMenu) return;
            clearUIMenu();
            if (brainContainedIdx != 0) return;

            // printDebug("onAcceptWithDetails" +
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

            // Size initialImageSize = const Size(600, 600);
            Size initialImageSize = initialMinimumSize;
            if (Platform.isIOS || Platform.isAndroid) {
              double minimumSize = min(windowHeight, windowWidth);
              initialImageSize = Size(minimumSize, minimumSize);
            }

            final fittedSizes =
                applyBoxFit(BoxFit.contain, initialImageSize, containerSize);

            Offset mouseOffset = controller
                .toLocal(Offset(value.offset.dx + 30, value.offset.dy + 35));

            // printDebug("canvasOffset.dx");
            // printDebug(value.offset.dx.toString() + " _ " + mouseOffset.dx.toString());
            SyntheticNeuron syntheticNeuron = SyntheticNeuron(
                isActive: false, isIO: false, circleRadius: neuronDrawSize / 2);
            InfiniteCanvasNode newNode = InfiniteCanvasNode(
              // CHANGE LABEL
              label: "Quiet",
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

            if (value.data == 0) {
              newNode.isExcitatory = 1;
            } else {
              newNode.isExcitatory = 0;
            }

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
            if (objectPlacedSource != null) {
              Future.delayed(const Duration(milliseconds: 100), () async {
                await soloud?.play(objectPlacedSource!);
              });
            }


            initNativeC(false);
            isBrainTargetOverlayTop = -1;
            containedIdx = -1;

            Future.delayed(const Duration(milliseconds: 100), () {
              controller.deselect(neuronsKey[neuronsKey.length - 1]);
              modeIdx = -1;
              controller.modeIdx = modeIdx;
              prevConstrainedPos = Offset.zero;
              setState(() {});
            });
          }, onLeave: (value) async {
            printDebug("On Leave Drag Target");
            mapBg["activeComponent"] = noActiveComponent;
            if (soloud !=null && neuronOnTouchHandle != null) {
              prevSoundIdx = -2;
              await soloud?.stop(neuronOnTouchHandle!);
            }

            // modeIdx = -1;
            debouncerActiveArea.run(() {
              setState(() {});
            });

            // Future.delayed(const Duration(milliseconds: 027), () {
            //   setState(() {});
            // });
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
      ),
    );
    List<InfiniteDropTarget> list = [];
    if (isBrainTargetOverlayTop == -1) {
      list.add(brainTarget);
    }
    int idx = 0;
    int len = sensoryNeurons.length;
    for (idx = 0; idx < len - 3; idx++) {
    // for (idx = 0; idx < len - 2; idx++) {
      if (idx == 7) continue;
      // for (idx = 0; idx < len - 4; idx++) {
      InfiniteCanvasNode neuron = sensoryNeurons[idx];
      Map<String, dynamic> neuronInfo = dropTargetInformations[idx];
      if (listPainters.length < len) {
        listPainters.add(GeneralSensorPainter(
            multiplier: scaleMultiplier,
            polygonPath: sensorPolygonPaths[idx],
            positionDiff: [
              neuronInfo["xDiff"].toDouble(),
              neuronInfo["yDiff"].toDouble()
            ]));
      } else {
        listPainters[idx] = (GeneralSensorPainter(
            multiplier: scaleMultiplier,
            polygonPath: sensorPolygonPaths[idx],
            positionDiff: [
              neuronInfo["xDiff"].toDouble(),
              neuronInfo["yDiff"].toDouble()
            ]));

        // listPainters[idx].calculatePolygon(
        //     sensorPolygonPaths[idx],
        //     [neuronInfo["xDiff"].toDouble(), neuronInfo["yDiff"].toDouble()],
        //     scaleMultiplier);
      }
      if (idx == 2) continue;
      int tempIdx = idx;

      list.add(
        InfiniteDropTarget(
            key: UniqueKey(),
            size: neuronInfo["size"],
            // size: Size(
            //   neuronInfo["size"].width * scaleMultiplier,
            //   neuronInfo["size"].height * scaleMultiplier,
            // ),
            // offset: const Offset(0, 0),
            offset: Offset(neuronInfo["left"], neuronInfo["top"]),
            child: Positioned(
              top: neuronInfo["top"] * scaleMultiplier + topInnerWindowSpace,
              left:
                  (windowWidth / 2) + neuronInfo["posXDiff"] * scaleMultiplier,
              // top: neuronInfo["top"],
              // left: neuronInfo["left"],
              child: SizedBox(
                // color: Colors.green.withOpacity(0.5),
                width: neuronInfo["size"].width * scaleMultiplier,
                height: neuronInfo["size"].height * scaleMultiplier,
                child: DragTarget(
                    // 45 is a recentered position of Draggable
                    hitTestBehavior: HitTestBehavior.translucent,
                    onMove: (dragDetail) async {
                      Offset localAreaOffset = controller.toLocal(
                          Offset(dragDetail.offset.dx, dragDetail.offset.dy));
                      // Offset localOffsetGap = Offset.zero;
                      Offset localOffsetGap = (Offset(
                          45 / controller.getScale(),
                          45 / controller.getScale()));

                      GeneralSensorPainter painter = (listPainters[tempIdx]);
                      Offset containOffset = localAreaOffset.translate(
                          -((windowWidth / 2) +
                                  neuronInfo["posXDiff"] * scaleMultiplier) +
                              localOffsetGap.dx,
                          -(neuronInfo["top"] * scaleMultiplier +
                                  topInnerWindowSpace) +
                              localOffsetGap.dy);

                      bool isContaining = painter.path.contains(containOffset);
                      isContainingLabel = isContaining;
                      // printDebug(
                      //     "------localAreaOffset sensor " + tempIdx.toString());
                      // printDebug(containOffset);
                      // printDebug(isContaining);
                      // printDebug(painter.calculatedPath);

                      if (isContaining) {
                        containedIdx = tempIdx;
                        printDebug("containedIdx containing sensor $tempIdx");
                        // printDebug(containedIdx);

                        if (mapBg["activeComponent"] ==
                            activeComponents[tempIdx]) {
                        } else {
                          mapBg["activeComponent"] = activeComponents[tempIdx];
                          // if (soloud !=null && soloud!.activeSounds.contains(neuronOnTouchSource)) {
                          // neuronOnTouchSource?.soundEvents.first.then((val) {
                            // printDebug("val");
                            // printDebug(val);
                            
                            if (prevSoundIdx != tempIdx) {
                              prevSoundIdx = tempIdx;
                              if (neuronOnTouchSource != null) {
                                await soloud?.play(neuronOnTouchSource!).then((handle) {
                                  if (neuronOnTouchHandle != null) {
                                    soloud?.stop(neuronOnTouchHandle!);
                                  }
                                  neuronOnTouchHandle = handle;
                                });
                              }
                            }
                            

                          // });



                          debouncerActiveArea.run(() {
                            setState(() {});
                          });

                          // Future.delayed(const Duration(milliseconds: 027), () {
                          //   setState(() {});
                          // });
                        }
                      } else {
                        isBrainTargetOverlayTop = 1;
                        containedIdx = -1;
                        printDebug(
                            "containedIdx NOT containing Overlay:$isBrainTargetOverlayTop Contained:$containedIdx");
                        // printDebug(containedIdx);
                        // printDebug(isBrainTargetOverlayTop);

                        if (mapBg["activeComponent"] == noActiveComponent) {

                          setState(() {});
                        } else {
                          mapBg["activeComponent"] = noActiveComponent;
                          if (soloud !=null && neuronOnTouchHandle != null) {
                            prevSoundIdx = -2;
                            await soloud?.stop(neuronOnTouchHandle!);
                          }
                          debouncerActiveArea.run(() {
                            setState(() {});
                          });

                          // Future.delayed(const Duration(milliseconds: 027), () {
                          //   setState(() {});
                          // });
                        }
                      }
                    },
                    onWillAcceptWithDetails: (dragDetail) {
                      printDebug("containedIdx");
                      printDebug(containedIdx);
                      printDebug(tempIdx);

                      if (dragDetail.data as int < 2) {
                        // printDebug("------Accept");
                        // printDebug(activeComponents[tempIdx]);
                        return true;
                      } else {
                        return false;
                      }
                    },
                    onAcceptWithDetails: (value) async {
                      if (isPlayingMenu) return;
                      clearUIMenu();
                      if (containedIdx != tempIdx) return;
                      // printDebug("------Accept");
                      // printDebug(value.data);
                      Offset neuronZonePosition = getUniqueZone(
                          centerZoneOffset, neuronInfo, scaleMultiplier);
                      mapBg["activeComponent"] = noActiveComponent;
                      mapBg["activeBg"] = defaultBg;

                      printDebug("onAcceptWithDetails" + value.data.toString());
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
                        label: "Quiet",
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

                      if (value.data == 0) {
                        newNode.isExcitatory = 1;
                      } else {
                        newNode.isExcitatory = 0;
                      }

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

                      if (objectPlacedSource != null) {
                        // await soloud?.play(objectPlacedSource!);
                        Future.delayed(const Duration(milliseconds: 100), () async {
                          await soloud?.play(objectPlacedSource!);
                        });

                      }

                      InfiniteCanvasNode nodeFrom = neuron;
                      InfiniteCanvasNode nodeTo = newNode;
                      if (tempIdx >= 3 && tempIdx <= 9) {
                        nodeFrom = newNode;
                        nodeTo = neuron;
                      }
                      InfiniteCanvasEdge edge = InfiniteCanvasEdge(
                        from: nodeFrom.key,
                        to: nodeTo.key,
                      );

                      printDebug("nodeTo");
                      printDebug(nodeTo.id);
                      printDebug(nodeSingleLed.id);

                      // /*
                      String connectionKey = "${nodeFrom.id}_${nodeTo.id}";
                      if (nodeFrom == nodeLeftEyeSensor ||
                          nodeFrom == nodeRightEyeSensor) {
                        edge.label = "Green";
                        mapSensoryNeuron["${nodeFrom.id}_${nodeTo.id}"] = 2;
                        linkAreaSizeConnection(
                            selectedCameraPosition: "Left",
                            nodeFrom: nodeFrom,
                            nodeTo: nodeTo);
                      } else if (nodeFrom == nodeDistanceSensor) {
                        // CHANGE because of Chris' workshop
                        print("DISTANCE SENSOR");
                        edge.label = "Medium";
                        mapDistanceNeuron["${nodeFrom.id}_${nodeTo.id}"] = 1;
                        mapDistanceLimitNeuron["${nodeFrom.id}_${nodeTo.id}"] =
                            "8_@_30";
                      } else if (nodeTo == nodeLeftMotorForwardSensor ||
                          nodeTo == nodeLeftMotorBackwardSensor ||
                          nodeTo == nodeRightMotorForwardSensor ||
                          nodeTo == nodeRightMotorBackwardSensor) {
                        mapContactsNeuron["${nodeFrom.id}_${nodeTo.id}"] = 25.0;
                        edge.label = "25";
                      } else if (nodeTo == nodeSpeakerSensor) {
                        mapSpeakerNeuron["${nodeFrom.id}_${nodeTo.id}"] = 440.0;
                        edge.label = "440";
                      } else if (nodeTo == nodeMicrophoneSensor) {
                        // isMicrophoneMenu
                        mapMicrophoneNeuron["${nodeFrom.id}_${nodeTo.id}"] =
                            40.0;
                      // } else if (nodeTo == nodeRedLed ||
                      //     nodeTo == nodeGreenLed ||
                      //     nodeTo == nodeBlueLed) {
                      } else if (nodeTo == nodeSingleLed) {
                        // mapLedNeuron["${nodeFrom.id}_${nodeSingleLed.id}"] = 50;
                        mapLedNeuron["${nodeFrom.id}_${nodeRedLed.id}"] = 50;
                        mapLedNeuron["${nodeFrom.id}_${nodeGreenLed.id}"] = 50;
                        mapLedNeuron["${nodeFrom.id}_${nodeBlueLed.id}"] = 50;

                        int redColor = (mapLedNeuron["${nodeFrom.id}_${nodeRedLed.id}"] / 100 * 255).floor();
                        int greenColor = (mapLedNeuron["${nodeFrom.id}_${nodeGreenLed.id}"] / 100 * 255).floor();
                        int blueColor = (mapLedNeuron["${nodeFrom.id}_${nodeBlueLed.id}"] / 100 * 255).floor();
                        // nodeFrom.syntheticNeuron.blackBrush = Paint()
                        //   ..color = Color.fromARGB(255, redColor, greenColor, blueColor)
                        //   // ..color = Colors.yellow
                        //   ..style = PaintingStyle.fill
                        //   ..strokeWidth = 2;                        
                        // mapLedNeuronPosition["${nodeFrom.id}_${nodeSingleLed.id}"] = "1111";
                        mapLedNeuronPosition["${nodeFrom.id}_${nodeRedLed.id}"] = "1111";
                        mapLedNeuronPosition["${nodeFrom.id}_${nodeGreenLed.id}"] = "1111";
                        mapLedNeuronPosition["${nodeFrom.id}_${nodeBlueLed.id}"] = "1111";
                        edge.connectionStrength = 50;
                        edge.color = Color.fromARGB(255, redColor, greenColor, blueColor);

                        // mapLedNeuron["${nodeFrom.id}_${nodeTo.id}"] = 50;
                        // mapLedNeuron["${nodeFrom.id}_${nodeTo.id}"] = 50;
                        // mapLedNeuronPosition["${nodeFrom.id}_${nodeTo.id}"] =
                        //     "1111";
                      } else {
                        // printDebug("Get Drag Targets");

                        mapConnectome["${nodeFrom.id}_${nodeTo.id}"] = 25.0;
                        edge.label = "25";
                        // lastCreatedEdge.connectionStrength = 25.0;
                      }
                      // */

                      // mapConnectome[connectionKey] = 50;
                      // edge.connectionStrength = 50;
                      controller.edges.add(edge);

                      initNativeC(false);
                      isBrainTargetOverlayTop = -1;
                      containedIdx = -1;

                      Future.delayed(const Duration(milliseconds: 100), () {
                        controller.deselect(neuronsKey[neuronsKey.length - 1]);
                        modeIdx = -1;
                        controller.modeIdx = modeIdx;
                        prevConstrainedPos = Offset.zero;
                        setState(() {});
                      });
                    },
                    onLeave: (value) {
                      printDebug("On Leave Drag Target2");
                      mapBg["activeComponent"] = noActiveComponent;
                      // setState(() {});
                      Future.delayed(const Duration(milliseconds: 217), () {
                        // printDebug("On Leave Drag Target delay finished");
                        setState(() {});
                      });
                    },
                    builder: (ctx, candidates, rejects) {
                      if (tempIdx == 7) return Container();

                      if (tempIdx >= listPainters.length) return Container();

                      // return Container(
                      //   width: neuronInfo["size"].width,
                      //   height: neuronInfo["size"].height,
                      //   color: Colors.green.withOpacity(0.2),
                      // );
                      // if (tempIdx == 8) {
                      //   return CustomPaint(
                      //     size: neuronInfo["size"], // Adjust size as needed
                      //     painter: listPainters[7],
                      //   );
                      // } else {
                      return CustomPaint(
                        size: neuronInfo["size"], // Adjust size as needed
                        painter: listPainters[tempIdx],
                      );
                      // }
                    }),
              ),
            )),
      );
    }
    if (isBrainTargetOverlayTop == 1) {
      printDebug("Brain Z INDEX TOP");
      list.add(brainTarget);
    }

    return list;
  }

  // the Neuron Positions/Distance Formula was hardcoded/measured in 600x600 environment
  // the most important is the initialMinimumSize
  void repositionContactNeurons() {
    windowWidth = MediaQuery.of(context).size.width;
    windowHeight = MediaQuery.of(context).size.height;

    // calculate imageSize
    final Size containerSize =
        Size(windowWidth, windowHeight); // Replace with your container size

    // Size initialImageSize = const Size(600, 600);
    Size initialImageSize = initialMinimumSize;
    printDebug("initialMinimumSize reposition");
    printDebug(initialMinimumSize);

    if (Platform.isIOS || Platform.isAndroid) {
      double minimumSize = min(windowHeight, windowWidth);
      initialImageSize = Size(minimumSize, minimumSize);
    }

    final fittedSizes =
        applyBoxFit(BoxFit.contain, initialImageSize, containerSize);
    if (prevImageWidth == null) {
      prevImageWidth = initialImageSize.width;
      prevImageHeight = initialImageSize.height;
    } else {
      prevImageWidth = currentImageWidth;
      prevImageHeight = currentImageHeight;
    }
    currentImageWidth = fittedSizes.destination.width;
    currentImageHeight = fittedSizes.destination.height;
    final Size imageSize = Size(
        currentImageWidth, currentImageHeight); // Replace with your image size
    centerZoneOffset = Offset(currentImageWidth / 2 + neuronDrawSize,
        currentImageHeight / 3 + neuronDrawSize);

    double leftSpace = (windowWidth - currentImageWidth) / 2;
    double topSpace = (windowHeight - currentImageHeight) / 2;
    // printDebug("windowWidthzzz");
    // printDebug(windowWidth);
    // printDebug(currentImageWidth);
    leftInnerWindowSpace = leftSpace;
    topInnerWindowSpace = topSpace;

    double minimumSize = initialMinimumSize.height;
    // double minimumSize = 600;
    // if (Platform.isIOS || Platform.isAndroid) {
    //   minimumSize = min(windowWidth, windowHeight);
    //   initialImageSize = Size(minimumSize, minimumSize);
    // }

    double widthRatio = currentImageWidth / minimumSize;
    double heightRatio = currentImageHeight / minimumSize;
    printDebug("widthRatio, heightRatio");
    printDebug(imageSize);
    printDebug(minimumSize);
    // if (widthRatio > 1) {
    //   widthRatio = minimumSize / currentImageWidth;
    //   heightRatio = minimumSize / currentImageHeight;
    // }
    // 395, 150
    // printDebug("topSpace");
    // printDebug(topSpace);
    // printDebug(topInnerWindowSpace);
    // printDebug(currentImageHeight);
    // printDebug(minimumSize);
    Offset centerOffset =
        Offset(windowWidth / 2 - 5, topSpace + (90 * heightRatio).ceil());
    nodeLeftEyeSensor.offset = centerOffset;

    // nodeDistanceSensor.offset = Offset(
    //     centerOffset.dx - (195 * widthRatio).ceil(),
    //     topSpace + 115 * heightRatio);
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

    // nodeRedLed.offset = Offset(
    //     nodeLeftMotorBackwardSensor.offset.dx + (30 * widthRatio).ceil(),
    //     nodeLeftMotorBackwardSensor.offset.dy + (60 * heightRatio).ceil());
    // nodeGreenLed.offset = Offset(
    //     nodeLeftMotorBackwardSensor.offset.dx + (60 * widthRatio).ceil(),
    //     nodeLeftMotorBackwardSensor.offset.dy + (80 * heightRatio).ceil());
    // nodeBlueLed.offset = Offset(
    //     nodeLeftMotorBackwardSensor.offset.dx + (90 * widthRatio).ceil(),
    //     nodeLeftMotorBackwardSensor.offset.dy + (110 * heightRatio).ceil());
    nodeRedLed.offset = Offset.zero;
    nodeGreenLed.offset = Offset.zero;
    nodeBlueLed.offset = Offset.zero;

    nodeSingleLed.offset = Offset(
        nodeLeftMotorBackwardSensor.offset.dx + (100 * widthRatio).ceil(),
        nodeLeftMotorBackwardSensor.offset.dy + (145 * heightRatio).ceil());

    // reposition because Alex request
    nodeDistanceSensor.offset = Offset(
        centerOffset.dx - (205 * widthRatio).ceil(),
        topSpace + 115 * heightRatio);

  }

  void onDeleteCallback() async {
    if (isDrawTail) {
      deleteNeuronCallback();
      resetMouse();
    } else {
      deleteEdgeCallback();
      resetMouse();
    }
    // if (eraseSource != null) {
    //   eraseHandle = await soloud?.play(eraseSource!);
    // }
  }
  void submitLedAxon(value, nodeFrom, nodeTo) {
    try {
      if (nodeTo.key == nodeRedLed.key) {
        if (value.trim() == "") value = "0";
        sldSynapticWeightR = double.parse(value);
        if (sldSynapticWeightR > 100) {
          sldSynapticWeightR = 100;
        } else if (sldSynapticWeightR < 0) {
          sldSynapticWeightR = 0;
        }
        tecSynapticWeightR.text = sldSynapticWeightR.floor().toString();
        sldSynapticWeightR = sldSynapticWeightR.roundToDouble();
        linkLedAxon(sldSynapticWeightR, nodeFrom, nodeTo);
        
      } else 
      if (nodeTo.key == nodeGreenLed.key) {
        if (value.trim() == "") value = "0";
        sldSynapticWeightG = double.parse(value);
        if (sldSynapticWeightG > 100) {
          sldSynapticWeightG = 100;
        } else if (sldSynapticWeightG < 0) {
          sldSynapticWeightG = 0;
        }
        tecSynapticWeightG.text = sldSynapticWeightG.floor().toString();
        sldSynapticWeightG = sldSynapticWeightG.roundToDouble();
        linkLedAxon(sldSynapticWeightG, nodeFrom, nodeTo);
      } else 
      if (nodeTo.key == nodeBlueLed.key) {
        if (value.trim() == "") value = "0";
        sldSynapticWeightB = double.parse(value);
        if (sldSynapticWeightB > 100) {
          sldSynapticWeightB = 100;
        } else if (sldSynapticWeightB < 0) {
          sldSynapticWeightB = 0;
        }
        tecSynapticWeightB.text = sldSynapticWeightB.floor().toString();
        sldSynapticWeightB = sldSynapticWeightB.roundToDouble();
        linkLedAxon(sldSynapticWeightB, nodeFrom, nodeTo);
      }
      setState(() {});
    } catch (err) {
      printDebug("err slider submit tf LED ");
    }    
  }

  // DEPRECATED in favor of submitLedAxon
  void submitLedConnection(value) {
    try {
      if (value.trim() == "") value = "0";
      sldSynapticWeight = double.parse(value);
      if (sldSynapticWeight > 100) {
        sldSynapticWeight = 100;
      } else if (sldSynapticWeight < 0) {
        sldSynapticWeight = 0;
      }
      tecSynapticWeight.text = sldSynapticWeight.floor().toString();
      sldSynapticWeight = sldSynapticWeight.roundToDouble();
      linkLedConnection(sldSynapticWeight);

      setState(() {});
    } catch (err) {
      printDebug("err slider tf");
    }
  }

  void submitSynapticConnection(String value) {
    printDebug("submitSynapticConnection");
    try {
      if (value.trim() == "") value = "0";
      sldSynapticWeight = double.parse(value);
      if (sldSynapticWeight > 100) {
        sldSynapticWeight = 100;
      } else if (sldSynapticWeight < 0) {
        sldSynapticWeight = 0;
      }
      sldSynapticWeight = sldSynapticWeight.roundToDouble();
      tecSynapticWeight.text = sldSynapticWeight.round().toString();
      if (isSynapseMenu) {
        linkNeuronConnection(sldSynapticWeight.toString());
      } else if (isMotorMenu) {
        linkMotorConnection(sldSynapticWeight.toString());
      }

      setState(() {});
    } catch (err) {}
  }

  void submitDelayConnection(String value) {
    try {
      if (value.trim() == "") value = "0";
      sldTimeValue = double.parse(value);
      if (sldTimeValue > maxDelayTimeValue) {
        sldTimeValue = 5000;
      } else if (sldTimeValue < 100) {
        sldTimeValue = 100;
      }
      sldTimeValue =
          ((sldTimeValue / 100).floor() * 100).floor().roundToDouble();
      tecTimeValue.text = sldTimeValue.floor().toString();
      // printDebug("SUBMIT DELAY CONNECTION");
      // printDebug(sldTimeValue);
      // printDebug(controller.singleSelection);
      if (controller.singleSelection != null) {
        InfiniteCanvasNode selected = controller.singleSelection!;
        int neuronIdx =
            controller.nodes.map((e) => e.id).toList().indexOf(selected.id) - 2;
        mapDelayNeuronList[neuronIdx] = sldTimeValue.floor();
      }
      controller.singleSelection = null;
      setState(() {});
    } catch (err) {
      printDebug("Error: Submit Delay Connection");
      printDebug(err);
    }
  }

  void submitFrequencyConnection(String value) {
    try {
      if (value.trim() == "") value = "0";
      sldFrequencyWeight = double.parse(value);
      if (sldFrequencyWeight > 4978) {
        sldFrequencyWeight = isSpeakerMenu ? 4978 : 5000;
      } else if (isSpeakerMenu) {
        if (sldFrequencyWeight < 3) {
          sldFrequencyWeight = 3;
        }
      } else {
        if (sldFrequencyWeight < 3) {
          sldFrequencyWeight = 0;
        }
      }

      sldFrequencyWeight = sldFrequencyWeight.roundToDouble();
      tecFrequencyWeight.text = sldFrequencyWeight.round().toString();

      if (isSpeakerMenu) {
        linkSpeakerConnection(sldFrequencyWeight.toString());
      } else if (isMicrophoneMenu) {
        linkMicrophoneConnection(sldFrequencyWeight.toString());
      }

      setState(() {});
    } catch (err) {
      printDebug("err connection");
    }
  }

  void submitWeightA(String value) {
    try {
      if (value.trim() == "") value = "0";
      sldAWeight = double.parse(value);
      if (sldAWeight > 0.15) {
        sldAWeight = 0.15;
      }
      if (sldAWeight < 0) {
        sldAWeight = 0;
      }
      tecAWeight.text = sldAWeight.toString();

      resizeIzhikevichParameters(neuronSize);
      if (controller.singleSelection != null) {
        InfiniteCanvasNode selected = controller.singleSelection!;
        int neuronIdx =
            controller.nodes.map((e) => e.id).toList().indexOf(selected.id) - 2;
        aDesignArray[selected.id] = sldAWeight;
        aBufView[neuronIdx] = sldAWeight;
      }

      // controller.singleSelection = null;

      setState(() {});
    } catch (err) {}
  }

  void submitWeightB(String value) {
    try {
      if (value.trim() == "") value = "0";
      sldBWeight = double.parse(value);
      if (sldBWeight > 0.5) {
        sldBWeight = 0.5;
      }
      if (sldBWeight < 0) {
        sldBWeight = 0;
      }
      tecBWeight.text = sldBWeight.toString();

      resizeIzhikevichParameters(neuronSize);
      printDebug("controller.singleSelection");
      printDebug(controller.singleSelection);
      if (controller.singleSelection != null) {
        InfiniteCanvasNode selected = controller.singleSelection!;
        int neuronIdx =
            controller.nodes.map((e) => e.id).toList().indexOf(selected.id) - 2;
        bDesignArray[selected.id] = sldBWeight;
        bBufView[neuronIdx] = sldBWeight;
      }

      // controller.singleSelection = null;

      setState(() {});
    } catch (err) {}
  }

  void submitWeightC(String value) {
    try {
      if (value.trim() == "") value = "0";
      sldCWeight = double.parse(value);
      if (sldCWeight > 0) {
        sldCWeight = 0;
      }
      if (sldCWeight < -100) {
        sldCWeight = -100;
      }

      sldCWeight = sldCWeight.roundToDouble();
      tecCWeight.text = sldCWeight.round().toString();
      resizeIzhikevichParameters(neuronSize);
      if (controller.singleSelection != null) {
        InfiniteCanvasNode selected = controller.singleSelection!;
        int neuronIdx =
            controller.nodes.map((e) => e.id).toList().indexOf(selected.id) - 2;
        cDesignArray[selected.id] = sldCWeight.floor();
        cBufView[neuronIdx] = sldCWeight.floor();
      }

      // controller.singleSelection = null;

      setState(() {});
    } catch (err) {}
  }

  void submitWeightD(String value) {
    try {
      if (value.trim() == "") value = "0";
      sldDWeight = double.parse(value);
      if (sldDWeight > 10) {
        sldDWeight = 10;
      }
      if (sldDWeight < 0) {
        sldDWeight = 0;
      }

      sldDWeight = sldDWeight.roundToDouble();
      tecDWeight.text = sldDWeight.round().toString();
      resizeIzhikevichParameters(neuronSize);
      if (controller.singleSelection != null) {
        InfiniteCanvasNode selected = controller.singleSelection!;
        int neuronIdx =
            controller.nodes.map((e) => e.id).toList().indexOf(selected.id) - 2;
        dDesignArray[selected.id] = sldDWeight.floor();
        dBufView[neuronIdx] = sldDWeight.floor();
      }

      // controller.singleSelection = null;

      setState(() {});
    } catch (err) {}
  }

  void setDataOnLeave() {
    // printDebug("setDataOnLeave");
    // printDebug(isNeuronMenu);
    // printDebug(isSynapseMenu);
    // printDebug(isCameraMenu);
    // printDebug(isDistanceMenu);
    // printDebug(isMotorMenu);
    // printDebug(isMicrophoneMenu);
    // printDebug(isSpeakerMenu);
    // printDebug(isLedMenu);

    if (isSynapseMenu || isMotorMenu) {
      submitSynapticConnection(tecSynapticWeight.text);
    } else if (isMicrophoneMenu || isSpeakerMenu) {
      submitFrequencyConnection(tecFrequencyWeight.text);
    } else if (isLedMenu) {
      // submitLedConnection(tecSynapticWeight.text);
      InfiniteCanvasEdge selectedEdge = controller.edgeSelected;
      InfiniteCanvasNode neuronFrom = findNeuronByKey(selectedEdge.from);

      submitLedAxon(tecSynapticWeightR.text, neuronFrom, nodeRedLed);
      submitLedAxon(tecSynapticWeightG.text, neuronFrom, nodeGreenLed);
      submitLedAxon(tecSynapticWeightB.text, neuronFrom, nodeBlueLed);
    } else if (isNeuronMenu) {
      if (neuronMenuType == "Delay") {
        // printDebug("delayConnection");
        printDebug(tecTimeValue.text);
        submitDelayConnection(tecTimeValue.text);
      } else {
        // REMOVE
        // printDebug("neuronMenuType");
        // printDebug(neuronMenuType);
        // printDebug(tecAWeight.text);
        // printDebug(tecBWeight.text);
        // printDebug(tecCWeight.text);
        // printDebug(tecDWeight.text);
        if (neuronMenuType == "Custom") {
          submitWeightA(tecAWeight.text);
          submitWeightB(tecBWeight.text);
          submitWeightC(tecCWeight.text);
          submitWeightD(tecDWeight.text);
        }
      }
    }
    // bool isSynapseMenu = false;
    // bool isCameraMenu = false;
    // bool isDistanceMenu = false;
    // bool isMotorMenu = false;
    // bool isMicrophoneMenu = false;
    // bool isSpeakerMenu = false;
    // bool isLedMenu = false;
    // isShowDelayTime = false;
  }

  String capitalize(str) {
    return "${str[0].toUpperCase()}${str.substring(1).toLowerCase()}";
  }

  Future<void> subscribeGeneralConfig() async {
    // printDebug("subscribeGeneralConfig");

    configListener = FirebaseFirestore.instance
        .doc("config/general")
        .snapshots()
        .listen((event) async {
      Map<String, dynamic>? data = event.data();
      if (data != null) {
        printDebug("data");
        printDebug(data);
        if (packageInfo != null) {
          String platform = "";
          if (Platform.isMacOS) {
            platform = "macos";
          } else if (Platform.isWindows) {
            platform = "windows";
          } else if (Platform.isIOS) {
            platform = "ios";
          } else if (Platform.isAndroid) {
            platform = "android";
          }

          String capitalizePlatform = capitalize(platform);

          String latestVersion = data["${platform}Version"] ?? "1";
          int latestVersionInt = int.parse(latestVersion.replaceAll(".", ""));
          String firmwareLatestVersion = data["firmwareVersion"];
          int firmwareLatestVersionInt =
              int.parse(firmwareLatestVersion.replaceAll(".", ""));

          int packageInfoVersionInt =
              int.parse(packageInfo!.version.replaceAll(".", ""));
          int? _firmwareVersionInt = int.tryParse(
              strFirmwareVersion.replaceAll("V", "").replaceAll(".", ""));
          if (_firmwareVersionInt != null) {
            firmwareVersionInt = _firmwareVersionInt;
          }
          printDebug(
              "${packageInfoVersionInt.toString()}_${latestVersionInt.toString()}");

          bool isReminding = false;
          //check if the user already choose to remind later or skip this version
          await getApplicationDocumentsDirectory()
              .then((documentDirectory) async {
            String versionPath =
                "${documentDirectory.path}${Platform.pathSeparator}spikerbot${Platform.pathSeparator}version";
            File resultFile =
                File("$versionPath${Platform.pathSeparator}currentVersion.txt");
            if (resultFile.existsSync()) {
              // if they already been asked
              var map = jsonDecode(resultFile.readAsStringSync());
              if (map["version"] != null) {
                int mapVersionInt = int.parse(map["version"]);
                printDebug("mapVersionInt");
                printDebug(mapVersionInt);
                printDebug(latestVersionInt);
                if (mapVersionInt != latestVersionInt) {
                  DateTime remindTime = DateTime.fromMillisecondsSinceEpoch(
                      int.parse(map["remindTime"]));
                  if (remindTime.millisecondsSinceEpoch <
                      DateTime.now().millisecondsSinceEpoch) {
                    isReminding = true;
                  }
                } else if (mapVersionInt == latestVersionInt) {
                  isReminding = false;
                }
              }
            } else {
              // if they havent been asked
              if (packageInfoVersionInt != latestVersionInt) {
                isReminding = true;
              } else {
                isReminding = false;
              }
            }
          });

          // prepare alert dialog
          List<Widget> content = [];
          if (packageInfoVersionInt < latestVersionInt) {
            content.add(const SizedBox(height: 10));
            content.add(InkWell(
              onTap: () => launchUrl(Uri.parse(data["${platform}UpdateLink"])),
              child: const Text(
                'Update Now',
                textAlign: TextAlign.center,
                style: TextStyle(
                    decoration: TextDecoration.underline,
                    color: const Color(0xFF1996FC)),
              ),
            ));
            content.add(const SizedBox(height: 30));
            // bool isForceUpdate = data["is${capitalizePlatform}ForceUpdate"];
            // if (!isForceUpdate) {}
          } else {
            printDebug("Updated");
          }
          if (firmwareVersionInt != 0 &&
              firmwareVersionInt < firmwareLatestVersionInt) {
            content.add(InkWell(
              onTap: () => launchUrl(Uri.parse(data["${platform}UpdateLink"])),
              child: const Text(
                'Update Firmware Now',
                textAlign: TextAlign.center,
                style: TextStyle(
                    decoration: TextDecoration.underline,
                    color: Color(0xFF1996FC)),
              ),
            ));
            content.add(const SizedBox(height: 30));
          } else {
            printDebug("Updated");
          }
          if (data["isInformation"]) {
            isReminding = true;
          }
          if (isReminding) {
            // showDialog with every force update record
            await versionDialogBuilder(
                latestVersionInt.toString(),
                context,
                data["${platform}UpdateTitle"] ?? "",
                data["${platform}UpdateDescription"] ?? "",
                content,
                data.containsKey("isInformation")
                    ? true
                    : data["is${capitalizePlatform}ForceUpdate"],
                data["isInformation"]);
          }
        }

        //"${packageInfo?.version ?? ""} : ${packageInfo?.buildNumber ?? ""}.2\r\n$strFirmwareVersion",
      }
    });
  }

  int zoneWidth = 500;
  int zoneHeight = 150;

  UniqueKey formHexColorKey = UniqueKey();  
  String strFileVersion = "1.0.1";
  
  AudioSource? neuronOnTouchSource;
  AudioSource? neuronSpikesSource;
  AudioSource? axonStretchSource;
  AudioSource? objectPlacedSource;
  AudioSource? buttonOnPressedSource;
  AudioSource? buttonPopSource;
  AudioSource? eraseSource;
  AudioSource? pageFlipSource;

  SoundHandle? neuronOnTouchHandle;
  SoundHandle? neuronSpikesHandle;
  SoundHandle? axonStretchHandle;
  SoundHandle? objectPlacedHandle;
  SoundHandle? buttonOnPressedHandle;
  SoundHandle? buttonPopHandle;
  SoundHandle? eraseHandle;
  SoundHandle? pageFlipHandle;
  
  SoLoud? soloud;
  
  int prevSoundIdx = -2;
  
  bool isDraggingTail = false;
  
  bool isMovingNodeFirstTime = true;
  
  LeftToolbar? leftToolBar;
  Offset getUniqueZone(centerZoneOffset, neuronInfo, scaleMultiplier) {
    int areaWidth = 0;
    int areaHeight = 0;
    Offset emptyArea = Offset.zero;
    final random = Random();
    for (int i = 1; i <= 10; i++) {
      for (int j = 1; j <= 10; j++) {
        for (int k = 0; k < 30; k++) {
          if (neuronInfo["zoneArea"][0] > 0) {
            areaWidth = (centerZoneOffset.dx / 2 * scaleMultiplier).floor();
          }
          if (neuronInfo["zoneArea"][1] > 0) {
            areaHeight = (centerZoneOffset.dy / 2 * scaleMultiplier).floor();
          }
          if (Platform.isIOS || Platform.isAndroid) {
            Offset centerScreenOffset =
                Offset(windowWidth / 2, windowHeight / 2);
            emptyArea = Offset(
                centerScreenOffset.dx + // center
                    neuronInfo["zoneArea"][0] * // zone classification
                        i *
                        zoneWidth *
                        scaleMultiplier /
                        3 +
                    random.nextInt(50) -
                    neuronInfo["zoneArea"][0] * 50,
                centerScreenOffset.dy +
                    neuronInfo["zoneArea"][1] *
                        j *
                        zoneHeight *
                        scaleMultiplier /
                        3 +
                    random.nextInt(20) +
                    0);
          } else {
            emptyArea = Offset(
                centerZoneOffset.dx + // center
                    areaWidth + // possible max area width
                    neuronInfo["zoneArea"][0] * // zone classification
                        i *
                        zoneWidth *
                        scaleMultiplier /
                        8 +
                    random.nextInt(50) -
                    neuronInfo["zoneArea"][0] * 50,
                centerZoneOffset.dy +
                    areaHeight +
                    neuronInfo["zoneArea"][1] *
                        j *
                        zoneHeight *
                        scaleMultiplier /
                        8 +
                    random.nextInt(20) +
                    0);
          }
          if (emptyArea.dx < brainPosition.dx * scaleMultiplier) {
            emptyArea = Offset(brainPosition.dx, emptyArea.dy);
          }
          if (emptyArea.dy <
              brainPosition.dy * scaleMultiplier + topInnerWindowSpace) {
            emptyArea = Offset(emptyArea.dx, brainPosition.dy);
          }

          if (emptyArea.dx >
              (brainPosition.dx + brainSize.width) * scaleMultiplier +
                  leftInnerWindowSpace) {
            emptyArea =
                Offset(brainPosition.dx + brainSize.width, emptyArea.dy);
          }
          if (emptyArea.dy >
              (brainPosition.dy + brainSize.height) * scaleMultiplier +
                  topInnerWindowSpace) {
            emptyArea =
                Offset(emptyArea.dx, brainPosition.dy + brainSize.height);
          }

          if (isEmptyArea(emptyArea)) {
            printDebug("!!emptyArea");
            printDebug(emptyArea);
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
    for (InfiniteCanvasNode node in controller.nodes) {
      Rect destNeuron = Rect.fromCenter(
          center: Offset(node.offset.dx, node.offset.dy),
          width: 15,
          height: 15);
      if (srcNeuron.overlaps(destNeuron)) {
        flag = false;
      }
    }
    return flag;
  }

  Widget generateTargetWidgets(Map<String, dynamic> mapDistanceInfo, int idx) {
    String distanceLabel = mapDistanceInfo["label"] ?? "";
    String distanceIcon = mapDistanceInfo["icon"] ?? "";
    Widget targetIcon;
    if (distanceIcon == "Red") {
      targetIcon = Container(
        margin: const EdgeInsets.all(15),
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.red,
        ),
      );
    } else if (distanceIcon == "Green") {
      targetIcon = Container(
        margin: const EdgeInsets.all(15),
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xFF18A953),
        ),
      );
    } else if (distanceIcon == "Blue") {
      targetIcon = Container(
        margin: const EdgeInsets.all(15),
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xFF1996FC),
        ),
      );
    } else {
      targetIcon = Text(distanceIcon,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 45,
            fontFamily: "NotoEmoji",
          ));
    }

    return GestureDetector(
      onTapDown: (details) async {
        if (buttonOnPressedSource != null) {
          buttonOnPressedHandle = await soloud?.play(buttonOnPressedSource!, looping: false);
        }
      },
      onTapUp: (details) async {
        if (buttonPopSource != null) {
          buttonOnPressedHandle = await soloud?.play(buttonPopSource!, looping: false);
        }

        isSelectingCameraTarget = !isSelectingCameraTarget;
        selectedEyeInfo["icon"] = mapDistanceInfo["icon"];
        selectedEyeInfo["label"] = mapDistanceInfo["label"];
        selectedEyeInfo["idx"] = idx.toString;

        cameraMenuType =
            (mapDistanceInfo["label"] as String).replaceAll("Color ", "");
        printDebug("isSelectingCameraTarget");
        printDebug(cameraMenuType);
        linkSensoryConnection(cameraMenuType);
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
                    color:
                        selectedDistanceIdx.toString() == mapDistanceInfo["idx"]
                            ? colorOrange
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
                  child: targetIcon,
                )),
            Positioned(
                left: 0,
                bottom: 0,
                child: Card(
                    // margin: const EdgeInsets.all(10),
                    child: SizedBox(
                        width: 80,
                        height: 30,
                        child: Center(
                          child: Text(
                            distanceLabel,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ))))
          ],
        ),
      ),
    );
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
        onTapDown: (details) async {
          if (buttonOnPressedSource != null) {
            try{
              buttonOnPressedHandle = await soloud?.play(buttonOnPressedSource!, looping: false);
            }catch(err) {
            }
          }
        },
        onTapUp: (details) async {
          if (buttonPopSource != null) {
            try{
              buttonPopHandle = await soloud?.play(buttonPopSource!, looping: false);
            }catch(err) {
              print("pop err");
              print(err);
            }
          }
          
          selectedDistanceIdx = index;
          switch (selectedDistanceIdx) {
            case 0:
              distanceMenuType = "Short";
              distanceMinLimitBufView[toIdx] = 1;
              distanceMaxLimitBufView[toIdx] = 8;
              distanceSensorContent =
                  "NEURON will SPIKE when on object is in front of the robot at 1 to 8 cm.";

              break;
            case 1:
              distanceMenuType = "Medium";
              distanceMinLimitBufView[toIdx] = 8;
              distanceMaxLimitBufView[toIdx] = 30;
              distanceSensorContent =
                  "NEURON will SPIKE when on object is in front of the robot at 8 to 30 cm.";

              break;
            case 2:
              distanceMenuType = "Long";
              distanceMinLimitBufView[toIdx] = 30;
              distanceMaxLimitBufView[toIdx] = 100;
              distanceSensorContent =
                  "NEURON will SPIKE when on object is in front of the robot at 30 to 100 cm distance.";

              break;
            case 3:
              distanceMenuType = "Custom";
              distanceMinLimitBufView[toIdx] = 35;
              distanceMaxLimitBufView[toIdx] = 65;
              txtDistanceMinController.text = "35";
              txtDistanceMaxController.text = "65";
              distanceSensorContent =
                  "NEURON will SPIKE when on object is in front of the robot at a set distance.";

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
                          ? colorOrange
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

  void simulateClick(double x, double y) async {
    GestureBinding.instance.handlePointerEvent(PointerDownEvent(
      position: Offset(x, y),
    )); //trigger button up,

    await Future.delayed(const Duration(milliseconds: 500));

    GestureBinding.instance.handlePointerEvent(PointerUpEvent(
      position: Offset(x, y),
    ));
  }

  generateCameraArea(bool isLeft, bool isRight, bool isAny, bool isCustom) {
    MainAxisAlignment ma = MainAxisAlignment.start;
    CrossAxisAlignment ca = CrossAxisAlignment.start;
    if (isRight) {
      ma = MainAxisAlignment.end;
      ca = CrossAxisAlignment.end;
    }
    double areaWidth = 100;
    if (isAny) {
      areaWidth = 160;
    }
    if (!isCustom) {
      return Container(
        width: 160 / 4 * 3.0,
        height: 120 / 4 * 3.0,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Colors.black,
        ),
        child: Row(
          mainAxisAlignment: ma,
          crossAxisAlignment: ca,
          children: [
            Container(
              width: areaWidth / 4 * 3.0,
              height: 120 / 4 * 3.0,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.all(
                  Radius.circular(10),
                ),
                color: Color(0XFFFD8164),
              ),
            )
          ],
        ),
      );
    } else {
      areaWidth = int.parse(txtAreaSizeMaxController.text).toDouble() -
          int.parse(txtAreaSizeMinController.text).toDouble();
      areaWidth /= 2;
      // if (areaWidth < 0) areaWidth = 0;
      areaWidth = areaWidth.ceilToDouble();
      // print("areaWidth");
      // print(areaWidth);
      // if (areaWidth < 30) areaWidth = 50;
      // if (areaWidth == 159) {
      //   areaWidth = 160;
      // }
      return Container(
        width: 160 / 4 * 3.0,
        height: 120 / 4 * 3.0,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Colors.black,
        ),
        child: Stack(
          children: [
            Positioned(
              left: int.parse(txtAreaSizeMinController.text).toDouble() /
                  2 /
                  4 *
                  3.0,
              child: Container(
                width: areaWidth / 4 * 3.0,
                height: 120 / 4 * 3.0,
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.all(
                    Radius.circular(10),
                  ),
                  color: Color(0XFFFD8164),
                ),
                // child: Text(areaWidth.toString()),
              ),
            )
          ],
        ),
      );
    }
  }

  void initializeFrame() {
    if (Platform.isWindows) {
      initialWindowWidth = 870;
      initialWindowHeight = 600;
      double minimumSize = min(initialWindowWidth, initialWindowHeight);
      initialMinimumSize = Size(minimumSize, minimumSize);
      viewPortNode.update(offset: Offset(screenWidth, screenHeight));
      if (prevInitialFrameGapWidth != null) {
        prevInitialFrameGapWidth = initialFrameGapWidth;
        prevInitialFrameGapHeight = initialFrameGapHeight;
      }
      initialFrameGapWidth = initialWindowWidth - initialMinimumSize.width;
      initialFrameGapHeight = initialWindowHeight - initialMinimumSize.height;
      if (prevInitialFrameGapWidth == null) {
        prevInitialFrameGapWidth = initialFrameGapWidth;
        prevInitialFrameGapHeight = initialFrameGapHeight;
      }

      currentFrameGapWidth = initialFrameGapWidth;
      currentFrameGapHeight = initialFrameGapHeight;
    } else if (Platform.isIOS || Platform.isAndroid) {
      initialWindowWidth = MediaQuery.of(context).size.width;
      if (isPortrait == true) {
        initialWindowWidth = MediaQuery.of(context).size.width;
        initialWindowHeight = MediaQuery.of(context).size.height;
        // if (MediaQuery.of(context).size.height >= 600) {
        //   initialWindowHeight = 600;
        //   print("initialWindowHeight >= 600");
        //   print(MediaQuery.of(context).size.height);
        //   print(MediaQuery.of(context).size.width);
        // } else {
        //   initialWindowHeight = MediaQuery.of(context).size.height;
        //   print("initialWindowHeight");
        // }
        // print(initialWindowHeight);
        // initialWindowHeight = 600;
      } else {
        initialWindowHeight = 600;
      }

      // if (MediaQuery.of(context).size.height > 600)
      {
        // initialWindowWidth = MediaQuery.of(context).size.width;
        // initialWindowHeight = MediaQuery.of(context).size.height;
        double minimumSize = min(initialWindowWidth, initialWindowHeight);
        Size initialMinSize = Size(minimumSize, minimumSize);
        printDebug("VIEWPORT UDPATE");
        viewPortNode.update(offset: Offset(screenWidth, screenHeight));
        if (prevInitialFrameGapWidth != null) {
          prevInitialFrameGapWidth = initialFrameGapWidth;
          prevInitialFrameGapHeight = initialFrameGapHeight;
        }
        initialFrameGapWidth = initialWindowWidth - initialMinSize.width;
        initialFrameGapHeight = initialWindowHeight - initialMinSize.height;
        if (prevInitialFrameGapWidth == null) {
          prevInitialFrameGapWidth = initialFrameGapWidth;
          prevInitialFrameGapHeight = initialFrameGapHeight;
        }
        currentFrameGapWidth = initialFrameGapWidth;
        currentFrameGapHeight = initialFrameGapHeight;
        // the Neuron Positions/Distance Formula was hardcoded/measured in 600x600 environment
        // the most important is the initialMinimumSize
        initialMinimumSize = const Size(600, 600);

        // Size initialImageSize = initialMinimumSize;
        // if (Platform.isIOS || Platform.isAndroid) {
        //   double minimumSize = min(MediaQuery.of(context).size.width,
        //       MediaQuery.of(context).size.height);
        //   // initialImageSize = Size(minimumSize, minimumSize);
        //   initialMinimumSize = Size(minimumSize, minimumSize);
        // }
        printDebug("initialMinimumSize1");
        printDebug(initialMinimumSize);

        // // initialWindowWidth = initialImageSize.width;
        // // initialWindowHeight = initialImageSize.height;
        // final Size containerSize = Size(MediaQuery.of(context).size.width,
        //     initialWindowHeight); // Replace with your container size

        // // // Size initialImageSize = const Size(600, 600);

        // final fittedSizes =
        //     applyBoxFit(BoxFit.contain, initialImageSize, containerSize);
        // initialMinimumSize = Size(
        //     fittedSizes.destination.width, fittedSizes.destination.height);
        // printDebug("initialMinimumSize2");
        // printDebug(initialMinimumSize);
        // // printDebug(initialWindowWidth);
        // // printDebug(initialWindowHeight);
        // initialWindowWidth = MediaQuery.of(context).size.width;
        // initialWindowHeight = MediaQuery.of(context).size.height;

        // initialFrameGapWidth = initialWindowWidth - initialMinimumSize.width;
        // initialFrameGapHeight =
        //     initialWindowHeight - initialMinimumSize.height;
        // currentFrameGapWidth = initialFrameGapWidth;
        // currentFrameGapHeight = initialFrameGapHeight;
      }
    } else {
      initialWindowWidth = MediaQuery.of(context).size.width;
      // initialWindowHeight = MediaQuery.of(context).size.height;
      initialWindowWidth = 870;
      initialWindowHeight = 600;

      double minimumSize = min(600, 600);
      initialMinimumSize = Size(minimumSize, minimumSize);
      viewPortNode.update(offset: Offset(screenWidth, screenHeight));
      if (prevInitialFrameGapWidth != null) {
        prevInitialFrameGapWidth = initialFrameGapWidth;
        prevInitialFrameGapHeight = initialFrameGapHeight;
      }
      initialFrameGapWidth = initialWindowWidth - initialMinimumSize.width;
      initialFrameGapHeight = initialWindowHeight - initialMinimumSize.height;
      if (prevInitialFrameGapWidth == null) {
        prevInitialFrameGapWidth = initialFrameGapWidth;
        prevInitialFrameGapHeight = initialFrameGapHeight;
      }

      currentFrameGapWidth = initialFrameGapWidth;
      currentFrameGapHeight = initialFrameGapHeight;
    }
  }

  void silentRepositionNeurons(Map savedFileJson) {
    // bool isFilePortrait = false;
    double displayWidth = savedFileJson["windowWidth"].toDouble();
    double displayHeight = savedFileJson["windowHeight"].toDouble();

    // isFilePortrait = false;
    // get current difference,
    List<dynamic> nodesJson = savedFileJson["nodes"];
    double cWindowWidth = MediaQuery.of(context).size.width;
    double cWindowHeight = MediaQuery.of(context).size.height;

    for (var v in nodesJson) {
      if (v["index"] == 1) {
        // Node Left eye Neuron
        // printDebug("silentReposisiontNeurons");
        List<Offset> oldDifCamera = [];
        Offset oldCameraNodePos = Offset(v["position"][0].toDouble() , v["position"][1].toDouble());
        // print("Window X Height : $cWindowWidth $cWindowHeight | PREVIOUS : $displayWidth $displayHeight | OFFSET: ${v["position"][0]} ${v["position"][1]}");
        // print("OFFSET RESULT : dx: ${oldCameraNodePos.dx} | dy: ${oldCameraNodePos.dy}");
        
        int start = normalNeuronStartIdx + 2;
        int len = controller.nodes.length;
        Offset newCameraNodePos =
            Offset(nodeLeftEyeSensor.offset.dx, nodeLeftEyeSensor.offset.dy);
        double maxWidth = -1;
        double maxHeight = -1;
        for (int i = start; i < len; i++) {
          // int idx = i - start;
          Offset oldDifCam = controller.nodes[i].offset - oldCameraNodePos;
          Offset diff = newCameraNodePos + oldDifCam;
          if (diff.dy > cWindowHeight - neuronDrawSize * 2) {
            maxHeight = max(maxHeight, diff.dy);
          } else
          if (diff.dx > cWindowWidth - neuronDrawSize * 2) {
            maxWidth = max(maxWidth, diff.dx);
          }
        }

        double scaleX = 1;
        double scaleY = 1;
        if (maxWidth != -1 ) {
          scaleX = (cWindowWidth - neuronDrawSize * 2) / (maxWidth - neuronDrawSize * 2);
          scaleX = scaleX / 1.5;
          scaleY = scaleY / 1.5;
        }
        if (maxHeight != -1 ) {
          scaleY = (cWindowHeight - neuronDrawSize * 2) / (maxHeight - neuronDrawSize * 2);
          scaleX = scaleX / 1.5;
          scaleY = scaleY / 1.5;
        }

        oldDifCamera.clear();
        for (int i = start; i < len; i++) {
          oldDifCamera.add( (controller.nodes[i].offset - oldCameraNodePos).scale(scaleX, scaleY) );
        }


        print("SCALE : $scaleX | $scaleY");
        for (int i = start; i < len; i++) {
          int idx = i - start;
          Offset diff = newCameraNodePos + oldDifCamera[idx];
          // diff = diff.scale(scaleX, scaleY) + Offset(30, 30);
          // if (diff.dy > cWindowHeight - neuronDrawSize * 2) {
          //   diff = Offset(diff.dx, cWindowHeight - neuronDrawSize * 2);
          // } else
          // if (diff.dx > cWindowWidth - neuronDrawSize * 2) {
          //   diff = Offset(cWindowWidth - neuronDrawSize * 2, diff.dy);
          // }
          controller.nodes[i].offset = Offset(diff.dx, diff.dy);
          // printDebug("controller.nodes[i].offset");
          // printDebug(controller.nodes[i].offset);
          // printDebug(len);
        }
        print('v["position000"]');

        break;
      }
    }


    nodeRedLed.offset = Offset.zero;
    nodeGreenLed.offset = Offset.zero;
    nodeBlueLed.offset = Offset.zero;
    prevScreenWidth = displayWidth;
    prevScreenHeight = displayHeight;
  }

  void initializeNucleus() {
    printDebug("Initialize Nucleus");
    if (controller.nucleusList != null) {
      controller.nucleusList!.clear();
    } else {
      controller.nucleusList = [];
    }
    Offset pan = controller
        .getOffset()
        .scale(1 / controller.getScale(), 1 / controller.getScale());
    int circleLen = protoNeuron.circles.length;
    for (int i = 0; i < circleLen; i++) {
      SingleNeuron neuron = protoNeuron.circles[i];
      Nucleus nucleus = Nucleus(
        index: i,
        isSpiking: neuron.isSpiking,
        neuronActiveCircle: neuronActiveCircles[i],
        neuronInactiveCircle: neuronInactiveCircles[i],
        neuronSpikeFlags: neuronSpikeFlags,
        centerPos: neuron.centerPos,
        circleKey: neuronCircleKeys[i],
      );
      controller.nucleusList!.add(nucleus);
    }
    // printDebug("circleLen");
    // printDebug(circleLen);
    // printDebug(neuronSpikeFlags.length);
    // printDebug(neuronCircleKeys.length);
    // printDebug(controller.nucleusList!.length);
    // printDebug("---------------");
  }
  
  void fillCreatedAxon(LocalKey nodeFrom, LocalKey nodeTo) {
    if (controller.edges.isNotEmpty) {
      printDebug("Fill Created Axon");
      InfiniteCanvasEdge? lastCreatedEdge;
      for (var edge in controller.edges) {
        if (edge.from == nodeFrom && edge.to == nodeTo) {
          lastCreatedEdge = edge;
        }
      }

      if (lastCreatedEdge == null) return;
      // printDebug("rawSyntheticNeuronList.length");
      // printDebug(rawSyntheticNeuronList.length);
      // rawSyntheticNeuronList.map((e) {
      //   // printDebug("e.neuronIdx");
      //   // printDebug(e.neuronIdx);
      // });

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

      List<InfiniteCanvasNode> restrictedToNeurons = [
        nodeLeftEyeSensor,
        nodeRightEyeSensor,
        nodeMicrophoneSensor,
        nodeDistanceSensor,
      ];

      List<InfiniteCanvasNode> restrictedFromNeurons = [
        nodeLeftMotorForwardSensor,
        nodeLeftMotorBackwardSensor,
        nodeRightMotorForwardSensor,
        nodeRightMotorBackwardSensor,
        nodeSpeakerSensor,
      ];
      printDebug("creating link");
      printDebug("creating linkaz");
      bool isConnected = false;
      if (neuronFrom.key == neuronTo.key) {
        // Future.delayed(const Duration(milliseconds: 50), () {
        controller.edges.remove(lastCreatedEdge);
        setState(() {});
        // });
        return;
      } else if (isDefaultRobotEdge >= 2) {
        controller.edges.remove(lastCreatedEdge);
      // WILL NOT HAPPEN
      // } else if (restrictedToNeurons.contains(neuronTo)) {
      //   controller.edges.remove(lastCreatedEdge);
      // } else if (restrictedFromNeurons.contains(neuronFrom)) {
      //   controller.edges.remove(lastCreatedEdge);               
      } else {
        if (neuronFrom == nodeLeftEyeSensor ||
            neuronFrom == nodeRightEyeSensor) {
          isConnected = false;
          mapSensoryNeuron["${neuronFrom.id}_${neuronTo.id}"] = 2;
          lastCreatedEdge.label = "Green";
          linkAreaSizeConnection(
              selectedCameraPosition: "Left",
              nodeFrom: neuronFrom,
              nodeTo: neuronTo);
          
        } else if (neuronFrom == nodeDistanceSensor) {
          isConnected = false;
          lastCreatedEdge.label = "Medium";
          mapDistanceNeuron["${neuronFrom.id}_${neuronTo.id}"] = 1;
          mapDistanceLimitNeuron["${neuronFrom.id}_${neuronTo.id}"] =
              "8_@_30";
        } else if (neuronTo == nodeLeftMotorForwardSensor ||
            neuronTo == nodeLeftMotorBackwardSensor ||
            neuronTo == nodeRightMotorForwardSensor ||
            neuronTo == nodeRightMotorBackwardSensor) {
          isConnected = true;
          mapContactsNeuron["${neuronFrom.id}_${neuronTo.id}"] = 25.0;
          lastCreatedEdge.label = "25";
        } else if (neuronTo == nodeSpeakerSensor) {
          isConnected = true;
          mapSpeakerNeuron["${neuronFrom.id}_${neuronTo.id}"] = 440.0;
          lastCreatedEdge.label = "440";
        } else if (neuronTo == nodeMicrophoneSensor) {
          // isMicrophoneMenu
          isConnected = true;
          mapMicrophoneNeuron["${neuronFrom.id}_${neuronTo.id}"] = 40.0;
        } else if (neuronTo.key == nodeSingleLed.key) {
          isConnected = true;
          printDebug("neuronTo nodeSingleLed.key");
          mapLedNeuron["${neuronFrom.id}_${nodeRedLed.id}"] = 50;
          mapLedNeuron["${neuronFrom.id}_${nodeGreenLed.id}"] = 50;
          mapLedNeuron["${neuronFrom.id}_${nodeBlueLed.id}"] = 50;

          int redColor = (mapLedNeuron["${neuronFrom.id}_${nodeRedLed.id}"] / 100 * 255).floor();
          int greenColor = (mapLedNeuron["${neuronFrom.id}_${nodeGreenLed.id}"] / 100 * 255).floor();
          int blueColor = (mapLedNeuron["${neuronFrom.id}_${nodeBlueLed.id}"] / 100 * 255).floor();
          // neuronFrom.syntheticNeuron.blackBrush = Paint()
          //   ..color = Color.fromARGB(255, redColor, greenColor, blueColor)
          //   // ..color = Colors.yellow
          //   ..style = PaintingStyle.fill
          //   ..strokeWidth = 2;
          mapLedNeuronPosition["${neuronFrom.id}_${nodeRedLed.id}"] = "1111";
          mapLedNeuronPosition["${neuronFrom.id}_${nodeGreenLed.id}"] = "1111";
          mapLedNeuronPosition["${neuronFrom.id}_${nodeBlueLed.id}"] = "1111";
          lastCreatedEdge.connectionStrength = 50;
          lastCreatedEdge.color = Color.fromARGB(255, redColor, greenColor, blueColor);
        // } else if (neuronTo == nodeRedLed ||
        //     neuronTo == nodeGreenLed ||
        //     neuronTo == nodeBlueLed) {
          // mapLedNeuron["${neuronFrom.id}_${neuron.id}"] = 50;
          // mapLedNeuronPosition["${neuronFrom.id}_${neuronTo.id}"] =
          //     "1111";
        } else {
          printDebug("init Canvas");
          isConnected = true;

          mapConnectome["${neuronFrom.id}_${neuronTo.id}"] = 25.0;
          lastCreatedEdge.connectionStrength = 25.0;
          lastCreatedEdge.label = "25";
        }
        printDebug("isConnected? $isConnected");
        if (isConnected) {
          if (objectPlacedSource != null) {
            // soloud?.play(objectPlacedSource!);
            Future.delayed(const Duration(milliseconds: 100), () async {
              await soloud?.play(objectPlacedSource!);
            });

          }
        }
        mapBg["activeBg"] = defaultBg;
        mapBg["activeComponent"] = noActiveComponent;
        setState(() {
          
        });                
      }

      setState(() {});
      MyApp.logAnalytic("CreateAxon",
          {"timestamp": DateTime.now().millisecondsSinceEpoch});
    }
  }
  // List<bool> getColorRegionFlag() {
  //   List<bool> cameraRegionFlag = [];

  //   for (int idx = 0; idx < 3; idx++) {
  //     double x = ImagePreprocessor.centroids[idx * 3 + 0].toDouble();
  //     double y = ImagePreprocessor.centroids[idx * 3 + 1].toDouble();
  //     bool flagContainLeftColor = containImage(
  //         Rect.fromCenter(center: Offset(x, y), width: 10, height: 10), false);
  //     bool flagContainRightColor = containImage(
  //         Rect.fromCenter(center: Offset(x, y), width: 10, height: 10), true);
  //     bool flagContainCustomColor = false;
  //     // bool flagContainCustomColor = containCustomZone(
  //     //     Rect.fromCenter(center: Offset(x, y), width: 10, height: 10),
  //     //     true);

  //     cameraRegionFlag.addAll([
  //       flagContainLeftColor,
  //       flagContainLeftColor || flagContainRightColor,
  //       flagContainRightColor,
  //       flagContainCustomColor
  //     ]);
  //   }
  //   return cameraRegionFlag;
  // }
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

  // static double centroidColorX = 0;
  // static double centroidColorY = 0;
  static List<int> centroids = [0, 0, 0, 0, 0, 0, 0, 0, 0];

  int normalNeuronStartIdx = 13;

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
    // printDebug(frame);
    // printDebug("process Frame");

    // printDebug("Receive Image DateTime");
    // printDebug(DateTime.now().microsecondsSinceEpoch);
    //send to isolate

    Uint8List frameData = Uint8List.fromList(frame);

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
        // checkColorCV(frameData).then((result) {
        //   String frameResult = result["result"].toRadixString(2);
        //   if (frameResult.length > 5) {
        //     _DesignBrainPageState.strLeftColorMenu =
        //         frameResult.substring(1, 4);
        //     _DesignBrainPageState.strRightColorMenu = frameResult.substring(4);
        //   }
        //   // print("centroids");
        //   // print(centroids);
        //   // print("centroidColorX");
        //   // print(centroidColorX);
        //   // print("centroidColorY");
        //   // print(centroidColorY);
        //   // print("--------------");
        //   centroids = result["centroids"];

        //   // check if centroids inside the camera Region
        //   for (int idx = 0; idx < 3; idx++) {
        //     double x = centroids[idx * 3 + 0].toDouble();
        //     double y = centroids[idx * 3 + 1].toDouble();
        //     double score = centroids[idx * 3 + 2].toDouble();
        //     Offset center = Offset(x, y);

        //     // this data structure was created because the robot had 2 eyes.
        //     for (int jNeuron = normalNeuronStartIdx + 2;
        //         jNeuron < _DesignBrainPageState.neuronSize + 2;
        //         jNeuron++) {
        //       int jNeuronIdx = jNeuron - 2;

        //       _DesignBrainPageState.visualInputBufView[idx * 2 +
        //           jNeuronIdx * _DesignBrainPageState.VisualInputLength] = 0;
        //     } // reset first
        //     for (String key in _DesignBrainPageState.mapSensoryNeuron.keys) {
        //       if (key.contains(
        //               _DesignBrainPageState.nodeLeftEyeSensor.key.toString()) &&
        //           _DesignBrainPageState.mapSensoryNeuron[key] == (idx * 2)) {
        //         List<String> modes =
        //             _DesignBrainPageState.mapAreaSize[key].split("_@_");

        //         // it is inside Camera Region/Zone
        //         // printDebug("====containImage");
        //         // printDebug(key);
        //         // printDebug(x);
        //         // printDebug(y);
        //         // printDebug(score);
        //         // printDebug(key.contains(
        //         //     _DesignBrainPageState.nodeLeftEyeSensor.key.toString()));
        //         // printDebug(
        //         //     "@@@RESULT ${containImage(Rect.fromCenter(center: center, width: 1, height: 1), modes)}");
        //         if (containImage(
        //             Rect.fromCenter(center: center, width: 1, height: 1),
        //             modes)) {
        //           for (int jNeuron = normalNeuronStartIdx + 2;
        //               jNeuron < _DesignBrainPageState.neuronSize + 2;
        //               jNeuron++) {
        //             InfiniteCanvasNode node =
        //                 _DesignBrainPageState.controller.nodes[jNeuron];
        //             // print("key");
        //             // print(_DesignBrainPageState.mapAreaSize);
        //             // print(_DesignBrainPageState.controller.nodes
        //             //     .map(
        //             //       (e) => e.key,
        //             //     )
        //             //     .toList()
        //             //     .getRange(normalNeuronStartIdx + 2,
        //             //         _DesignBrainPageState.neuronSize + 2));
        //             // print(normalNeuronStartIdx);
        //             // print(_DesignBrainPageState.neuronSize);
        //             int jNeuronIdx = jNeuron - 2;
        //             if (key.contains(node.id)) {
        //               if (score >= 69) {
        //                 int visualIndex = idx * 2 +
        //                     jNeuronIdx *
        //                         _DesignBrainPageState.VisualInputLength;
        //                 // printDebug("visualIndex ${_DesignBrainPageState.visualInputBufView.length}");
        //                 // printDebug(visualIndex);
        //                 // printDebug(
        //                 //     _DesignBrainPageState.visPrefsValsBufView[idx * 2]);
        //                 // printDebug("===========visualIndex");

        //                 _DesignBrainPageState.visualInputBufView[visualIndex] =
        //                     _DesignBrainPageState.visPrefsValsBufView[idx * 2];
        //               } else {
        //                 _DesignBrainPageState.visualInputBufView[idx * 2 +
        //                     jNeuronIdx *
        //                         _DesignBrainPageState.VisualInputLength] = 0;
        //               }
        //             } else {
        //               // USE THIS IF ONLY 1 LATEST NEURON TRIGGERED
        //               // _DesignBrainPageState.visualInputBufView[idx * 2 +
        //               //     jNeuronIdx *
        //               //         _DesignBrainPageState.VisualInputLength] = 0;
        //             }
        //           }
        //         }
        //       }
        //       // printDebug("_DesignBrainPageState.visualInputBufView");
        //       // printDebug(_DesignBrainPageState.visualInputBufView);
        //     }
        //   }

        //   isCheckingColor = false;
        // });
      }
    } else {
      if (!isJpegValid) {
        printDebug("isNotValidJPEG");
        return DesignBrainPage.prevFrame;
      } else {
        DesignBrainPage.prevFrame = frame;
      }
    }
    // return emptyFrame;

    mainBloc.drawImageNow(frameData);
    return frame;
  }

  bool containImage(Rect location, List<String> modes) {
    int xStart = int.parse(modes[1]);
    int xEnd = int.parse(modes[2]);
    // printDebug("location");
    // printDebug(location);
    // printDebug(modes);
    if (modes[0] == "Left") {
      if (location.center.dx < xEnd && location.center.dx >= xStart) {
        return true;
      } else {
        return false;
      }
    } else if (modes[0] == "Right") {
      if (location.center.dx > xStart && location.center.dx <= xEnd) {
        return true;
      } else {
        return false;
      }
    } else if (modes[0] == "Any") {
      // any
      return true;
    } else if (modes[0] == "Custom") {
      // custom
      if (location.center.dx >= xStart && location.center.dx <= xEnd) {
        return true;
      } else {
        return false;
      }
    }
    return false;
  }
}

void printDebug(s) {
  // print(s);
}
