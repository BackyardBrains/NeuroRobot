import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter_svg/flutter_svg.dart';
// import 'dart:convert';
import 'package:spikerbot/utils/ffi_imports.dart' as ffi;
import 'package:spikerbot/utils/platform_imports.dart';
import 'package:spikerbot/utils/isolate_imports.dart';
import 'dart:math';
import 'dart:typed_data';
// import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:animated_battery_gauge/battery_gauge.dart';
import 'package:another_xlider/another_xlider.dart';
import 'package:another_xlider/models/handler.dart';
import 'package:another_xlider/models/trackbar.dart';
import 'package:network_info_plus/network_info_plus.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:spikerbot/utils/ffi_package_imports.dart';
import 'package:fialogs/fialogs.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_mjpeg/flutter_mjpeg.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:spikerbot/utils/app_audio.dart';
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
import 'package:spikerbot/components/search_textfield.dart';
import 'package:spikerbot/dialogs/version_dialog.dart';
import 'package:spikerbot/components/drop_targets.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:infinite_canvas/src/presentation/widgets/nucleus.dart';
import 'package:spikerbot/components/arc_slider_widget.dart';
import 'package:spikerbot/utils/web_brain_storage.dart';
import '../components/embedded_neuron_plot_widget.dart';

import 'package:spikerbot/stubs/native_opencv_imports.dart' hide Rect;
import 'package:gamepads/gamepads.dart';
import 'package:spikerbot/stubs/nativec_imports.dart';
import 'package:spikerbot/stubs/web_sim_buffers_imports.dart';
import 'package:spikerbot/ai/models/recognition.dart';
import 'package:spikerbot/stubs/detector_service_imports.dart';
import 'package:spikerbot/ai/utils/StatsWidget.dart';
// import 'package:network_info_plus/network_info_plus.dart';
// import 'package:nativec/allocation.dart';
// import 'package:nativec/nativec.dart';
import 'package:spikerbot/bloc/bloc.dart';
import 'package:spikerbot/components/left_toolbar.dart';
import 'package:spikerbot/dialogs/load_brain.dart';
import 'package:spikerbot/dialogs/save_brain.dart';
import 'package:spikerbot/stubs/allocator_imports.dart';
import 'package:spikerbot/utils/Debouncers.dart';
import 'package:spikerbot/utils/brain_file_handler.dart';
import 'package:spikerbot/utils/brain_annotation.dart';
import 'package:spikerbot/components/radial_dial_widget.dart';
import 'package:spikerbot/utils/General.dart';
import 'package:spikerbot/utils/ProtoNeuron.dart';
import 'package:spikerbot/utils/Simulations.dart';
import 'package:spikerbot/utils/SingleCircle.dart';
import 'package:spikerbot/stubs/vision_imports.dart';
import 'package:spikerbot/utils/WaveWidget.dart';
import 'package:screenshot/screenshot.dart';
import 'package:sn_progress_dialog/progress_dialog.dart';
import 'package:url_launcher/url_launcher.dart';
// import 'package:opencv_ffi/opencv_ffi.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../components/context_menu_widget.dart';
import 'package:spikerbot/components/right_toolbar.dart';
import 'package:spikerbot/components/speaker_menu_widget.dart';
import 'package:spikerbot/components/color_wheel_widget.dart';
import 'package:spikerbot/components/byb_highlighted_text.dart';
import 'package:spikerbot/utils/window_manager_imports.dart';
import '../dialogs/info_dialog.dart';

// import 'package:path/path.dart' as p;
import 'package:spikerbot/utils/path_provider_imports.dart';

import '../dialogs/load_brain_new_ui.dart';
import '../main.dart';
import '../utils/ImageCapture.dart';
import '../utils/SingleSquare.dart';
import '../utils/WebSocket.dart';
import 'package:spikerbot/utils/web_websocket_imports.dart';
import 'package:spikerbot/components/live_tools_toolbar.dart';
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
bool isNeuronBehaviorExpanded = false;

final GlobalKey<EmbeddedNeuronPlotWidgetState> embeddedPlotKey = GlobalKey<EmbeddedNeuronPlotWidgetState>();

class _DesignBrainPageState extends State<DesignBrainPage> with WindowListener, TickerProviderStateMixin {
  static _DesignBrainPageState? instance;
  final GlobalKey _cameraBlockKey = GlobalKey();
  int _lastSentMotorLeft = 0;
  int _lastSentMotorRight = 0;
  String _lastSentDiodeString = "d:0,0,0,0;d:1,0,0,0;d:2,0,0,0;d:3,0,0,0;";
  Timer? _pauseRampDownTimer;
  late AnimationController _canvasAnimController;
  AnimationController? synapseFadeController;
  late Animation<Matrix4> _canvasAnimation;
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
    "dog": "🐕",
    "cat": "🐈",
    "tv": "📺",
    "mouse": "🐁",
    "keyboard": "⌨️",
    "scissors": "✂️",
    "donut": "🍩",
    "pizza": "🍕",
    "hot dog": "🌭",
    "car": "🚗",
    "motorcycle": "🏍️",
    "airplane": "✈️",
    "bus": "🚌",
    "train": "🚆",
    "truck": "🚚",
    "boat": "⛵",
    "traffic light": "🚥",
    "stop sign": "🛑",
    "bird": "🐦",
    "horse": "🐎",
    "sheep": "🐑",
    "cow": "🐄",
    "elephant": "🐘",
    "bear": "🐻",
    "zebra": "🦓",
    "giraffe": "🦒",
    "umbrella": "☔",
    "handbag": "👜",
    "tie": "👔",
    "suitcase": "🧳",
    "frisbee": "🥏",
    "skis": "🎿",
    "snowboard": "🏂",
    "sports ball": "⚽",
    "kite": "🪁",
    "baseball bat": "🏏",
    "baseball glove": "🧤",
    "skateboard": "🛹",
    "surfboard": "🏄",
    "tennis racket": "🎾",
    "wine glass": "🍷",
    "fork": "🍴",
    "knife": "🔪",
    "spoon": "🥄",
    "sandwich": "🥪",
    "broccoli": "🥦",
    "carrot": "🥕",
    "cake": "🎂",
    "bed": "🛏️",
    "dining table": "🍽️",
    "toilet": "🚽",
    "remote": "🎛️",
    "microwave": "🎛️",
    "oven": "🎛️",
    "toaster": "🍞",
    "sink": "🚰",
    "refrigerator": "🥶",
    "clock": "🕰️",
  };

  /// Results to draw bounding boxes
  static List<Recognition>? results;

  /// Realtime stats
  Map<String, dynamic>? aiStats;
  List<Recognition> aiObjectsInfo = [];

  // WEB SOCKET
  static Uint8List? debugCvImage;
  static Function()? onDebugUpdate;
  static late SendPort isolateWritePort;
  bool isIsolateWritePortInitialized = false;

  /// Route a command to the robot via the correct transport:
  /// - Web: WebSocketBridge (browser-native WebSocket)
  /// - Native: isolateWritePort (Isolate-based WebSocket)
  void sendToRobot(dynamic message) {
    if (kIsWeb) {
      webWsBridge?.send(message);
    } else {
      isolateWritePort.send(message);
    }
  }
  bool isReceivingCalculation = true;
  late ReceivePort writePort = ReceivePort();

  // SIMULATION SECTION
  // int neuronSize = 0; // REMOVED DUPLICATE
  // Track wave selection for Key updates
  int currentWaveNeuronIdx = -1;
  int currentWaveNeuronIdx2 = -1;
  double currentWaveZoom = 2.0;
  // Map<String, Offset> neuronPos = {};
  Map<String, String> neuronTypes = {};
  Map<String, String> neuronStyles = {};
  static const int motorCommandsLength = 6 * 2;
  static const int maxPosBuffer = 220;
  int epochs = 30;
  late List<SingleCircle> squareActiveCirclesPainter;
  late List<SingleCircle> squareInactiveCirclesPainter;
  late List<SingleCircle> neuronActiveCirclesPainter;
  late List<SingleCircle> neuronInactiveCirclesPainter;

  Nativec nativec = Nativec();

  bool isDeleteMenu = false;
  bool isNeuronMenu = false;
  bool isSynapseMenu = false;
  bool isCameraMenu = false;
  bool isDistanceMenu = false;
  bool isMotorMenu = false;
  bool isMicrophoneMenu = false;
  bool isSpeakerMenu = false;
  bool isLedMenu = false;

  double auxServoRestPosition = 0.0;  // Global resting position (-255 to +255)
  Map<String, double> mapAuxMotorPower = {};  // Per-neuron triggered value (-255 to +255)
  double auxMotorDecayPower = 0.0;
  int _auxDiagCounter = 0;

  Color colorOrange = const Color(0XFFFD8164);
  Color colorGreen = const Color(0xFF55EE55); // Standardized Green
  Color colorBlue = const Color(0xFF1996FC); // Standardized Blue
  Color colorRed = const Color(0xFFFF4444); // Standardized Red
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
    "Remote Control", //9
    "Motion",
    "Aux Motor",
    // "Rhytmic", //10
    // "Counting", //11
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
    "Remote Control",
    "Motion",
    "Aux Motor",
    // "Rhytmic",
    // "Counting", //11
  ];

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
    "dog",
    "cat",
    "tv",
    "mouse",
    "keyboard",
    "scissors",
    "donut",
    "pizza",
    "hot dog",
    "car",
    "motorcycle",
    "airplane",
    "bus",
    "train",
    "truck",
    "boat",
    "traffic light",
    "stop sign",
    "bird",
    "horse",
    "sheep",
    "cow",
    "elephant",
    "bear",
    "zebra",
    "giraffe",
    "umbrella",
    "handbag",
    "tie",
    "suitcase",
    "frisbee",
    "skis",
    "snowboard",
    "sports ball",
    "kite",
    "baseball bat",
    "baseball glove",
    "skateboard",
    "surfboard",
    "tennis racket",
    "wine glass",
    "fork",
    "knife",
    "spoon",
    "sandwich",
    "broccoli",
    "carrot",
    "cake",
    "bed",
    "dining table",
    "toilet",
    "remote",
    "microwave",
    "oven",
    "toaster",
    "sink",
    "refrigerator",
    "clock",
  ];
  late List<DropdownMenuItem> dropdownCameraItems;

  String distanceMenuType = "Short"; // V17: Default to Short (Near)
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

  DateTime? lastBatteryUpdate;
  bool isRobotConnected = false;
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
  late ffi.Pointer<ffi.Double> microphoneBuf;
  late ffi.Pointer<ffi.Int16> microphoneMinLimitBuf;
  late ffi.Pointer<ffi.Int16> microphoneMaxLimitBuf;
  late ffi.Pointer<ffi.Int16> microphoneTypeBuf;

  late ffi.Pointer<ffi.Int16> mapNeuronTypeBuf;
  late ffi.Pointer<ffi.Int16> mapDelayNeuronBuf;
  late ffi.Pointer<ffi.Int16> mapRhytmicNeuronBuf;
  late ffi.Pointer<ffi.Int16> mapCountingNeuronBuf;

  late ffi.Pointer<ffi.Int32> stateBuf;
  late ffi.Pointer<ffi.Double> visPrefsValsBuf;
  late ffi.Pointer<ffi.Uint8> motorCommandMessageBuf;

  late ffi.Pointer<ffi.Double> visualInputBuf;

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
  late Float64List microphoneBufView = Float64List(0);
  late Int16List microphoneMinLimitBufView = Int16List(0);
  late Int16List microphoneMaxLimitBufView = Int16List(0);
  late Int16List microphoneTypeBufView = Int16List(0);

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

  ProtoNeuron? protoNeuron;
  bool isChartSelected = false;
  int selectedIdx = 0;
  ValueNotifier<int> redrawNeuronLine = ValueNotifier(0);

  late Widget waveWidget;
  double waveZoom = 2.0; // Persist zoom level across rebuilds

  late Mjpeg mjpegComponent;

  bool isEmergencyPause = false;
  bool isDrawTail = false;
  bool isLoadingBrain = false; // Flag to prevent fillCreatedAxon from corrupting map during load
  bool isSettlingAfterLoad = false; // blocks unsaved tracking during post-load canvas settle
  int loadGeneration = 0; // monotonic load counter — prevents stale timers from clearing newer loads
  int prevEdgesLength = 0;
  Offset? prevSelectedOffsetNode;
  InfiniteCanvasNode? prevSelectedNode;
  InfiniteCanvasNode? prevSelectedNeuron;
  late InfiniteCanvasEdge prevSelectedEdge;
  bool isPrevSelectedEdge = false;

  late InfiniteCanvasNode tailNode;
  late InfiniteCanvasNode triangleNode;
  late InfiniteCanvasNode rectangleNode;
  late InfiniteCanvasNode circleNode;

  bool isPanningCanvas = false;

  // Paint Colors
  Paint circleColor = Paint()..color = const Color(0xFFFF4444); // Standardized Red
  Paint triangleColor = Paint()..color = const Color(0xFF55EE55); // Standardized Green
  Paint rectangleColor = Paint()..color = const Color(0xFF1996FC); // Standardized Blue

  Paint neuronColor = Paint()..color = Colors.grey;
  Paint tailColor = Paint()..color = const Color(0xFF55EE55); // Standardized Green

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
  WebSocketBridge? webWsBridge; // Web-only: browser-native WebSocket bridge

  bool isSimulationCallbackAttached = false;

  int StateLength = 20;
  int MotorMessageLength = 300;
  // int VisualPrefLength = 7 * 2;
  // int VisualPrefLength = 7 * 2;
  final rightEyeConstant = 73 + 7;
  int VisualPrefLength = 80 * 2;
  static int VisualInputLength = 80;

  late Widget mainBody;

  double prevTransformScale = 1;
  Debouncer debouncerActiveArea = Debouncer(milliseconds: 77);
  Debouncer debouncerSnapNeuron = Debouncer(milliseconds: 3);
  Debouncer debouncerAIClassification = Debouncer(milliseconds: 2000); // FIX: Extended to allow for TFLite inference latency without crashing currents
  Debouncer debouncerNoResponse = Debouncer(milliseconds: 3700);
  Debouncer debouncerTooltip = Debouncer(milliseconds: 1000);
  Debouncer debouncerSave = Debouncer(milliseconds: 1);
  Debouncer debouncerActiveComponent = Debouncer(milliseconds: 100);
  Debouncer debouncerHoveringNeuron = Debouncer(milliseconds: 400);
  Map<String, int> mapHoveringNeuron = {};
  // V23: Rotation Logic for Organic Neurons
  Map<LocalKey, double> mapNeuronRotation = {};

  List<Offset> rawPos = [];

  // String redLEDCmd = 'd:111;d:211;d:311;d:411;d:511;d:611;'; // red
  // String blueLEDCmd = 'd:131;d:231;d:331;d:431;d:531;d:631;'; // blue
  // String greenLEDCmd = 'd:121;d:221;d:321;d:421;d:521;d:621;;'; // green

  // String redLEDCmd = 'd:111;d:211;d:311;d:411;'; // red
  // String blueLEDCmd = 'd:131;d:231;d:331;d:431;'; // blue
  // String greenLEDCmd = 'd:121;d:221;d:321;d:421;'; // green
  String redLEDCmd = 'd:0,25,0,0;d:1,25,0,0;d:2,25,0,0;d:3,25,0,0;'; // red (capped to match firmware idle glow)
  String blueLEDCmd =
      'd:0,0,0,25;d:1,0,0,25;d:2,0,0,25;d:3,0,0,25;'; // blue (capped to match firmware idle glow)
  String greenLEDCmd =
      'd:0,0,25,0;d:1,0,25,0;d:2,0,25,0;d:3,0,25,0;'; // green (capped to match firmware idle glow)
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
  LeftToolbar? leftToolBar;
  LiveLeftToolbar? liveToolBar;      


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
  /// Annotations attached to the currently loaded brain.
  List<BrainAnnotation> brainAnnotations = [];
  /// Maps current-session node.id → stable annotation key (read from "annKey" in JSON).
  /// Used to make annotation recall stable across multiple save/reload cycles.
  Map<String, String> _nodeAnnotationKeys = {};
  /// True while the user is in annotation-selection mode.
  bool isAnnotationMode = false;
  /// Suppresses the unsaved-flag during the entire annotation session, including
  /// while the exit animation is running (cleared only in its onComplete).
  bool _suppressUnsavedDuringAnnotation = false;
  /// Baseline node/edge counts captured every time the brain reaches a definitively
  /// clean state (initial load, brain load, save).  The unsaved flag is only raised
  /// when the CURRENT counts differ from these baselines, which ensures that pure
  /// UI interactions (tap, pan, zoom, camera animation) never falsely mark the brain
  /// as dirty.
  int _baselineNodeCount = 0;
  int _baselineEdgeCount = 0;
  void _setCleanBaseline() {
    _baselineNodeCount = controller.nodes.length;
    _baselineEdgeCount = controller.edges.length;
    brainHasUnsavedChanges.value = false;
  }
  /// True when re-opening an existing annotation (edit/view mode vs. new-create mode).
  bool _isEditingAnnotation = false;
  /// Index into [brainAnnotations] of the annotation being viewed/edited (-1 = new).
  int _editingAnnotationIdx = -1;
  /// True when the user has explicitly tapped "Edit" in view mode — enables text
  /// editing and neuron re-selection.  False while just browsing annotations.
  bool _annotationEditEnabled = false;
  /// Text input while user is composing an annotation description.
  final TextEditingController _annotationDescController = TextEditingController();
  final ScrollController _annotationScrollController = ScrollController();
  /// Focus node for the annotation card (kept for potential future use).
  final FocusNode _annotationFocusNode = FocusNode();
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

  int aiTypeLength = 73;

  bool isShowDelayTime = false;
  int maxDelayTimeValue = 2500;
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

  // StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? configListener;

  String isTailType = "circle";

  int CONFIG_DELAY_NEURON = 6;
  int CONFIG_REMOTE_CONTROL_NEURON = 7;
  int CONFIG_RHYTMIC_NEURON = 8;
  int CONFIG_COUNTING_NEURON = 9;

  /// Maps neuron ID → bound key label string (e.g. "A", "Space", "Pad:1:ButtonA")
  Map<String, String> mapRemoteControlNeuron = {};

  /// Motion neuron: nodeId → selected input type ("Tap", "Tilt", or "Motion")
  Map<String, String> mapMotionNeuron = {};

  /// IMU sensor state — parsed from firmware "i:TMT" telemetry field
  bool imuTapActive = false;
  bool imuMotionActive = false;
  bool imuTiltActive = false;

  /// Tracks which keys (IDs) are currently pressed during simulation
  Set<String> _activeRemoteKeys = {};

  StreamSubscription<GamepadEvent>? _gamepadSubscription;

  /// Whether the Remote Control widget is in "listening" mode
  bool _isListeningForRemoteInput = false;

  /// On-screen Remote Trigger button pressed state (for unbound RC neurons)
  bool _remoteTriggerPressed = false;
  /// Test Input button pressed state (for visual feedback)
  bool _testInputPressed = false;

  /// Current bound key label for the selected neuron (UI state)
  String _remoteControlBoundKeyLabel = "";
  // Targeted notifier: only fires when an RC binding changes, avoiding
  // the full-canvas 60fps rebuild triggered by controller.notifyListeners().
  final ValueNotifier<int> _rcBindingVersion = ValueNotifier(0);

  /// Debug mode for input Inspection
  bool _isShowInputDebug = false;
  String _debugInputLog = "Press keys to see details...";

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

  // --- Brain Home Position: single source of truth for all coordinate layers ---
  // brainHomeX = screen-space left edge of scaled brain group
  // brainHomeY = screen-space top  edge of scaled brain group
  double brainHomeX = 0.0;
  double brainHomeY = 0.0;
  // Toolbar dimensions (used to carve out usable canvas area)
  static const double kToolbarWidth  = 70.0; // landscape left sidebar width
  static const double kToolbarHeight = 70.0; // portrait  bottom bar height

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

  double minMicrophoneSlider = 100;
  double maxMicrophoneSlider = 5000;
  TextEditingController txtMicrophoneMinController = TextEditingController(text: "400");
  TextEditingController txtMicrophoneMaxController = TextEditingController(text: "800");

  int isBrainTargetOverlayTop = -1;

  int containedIdx = -1;

  int brainContainedIdx = -1;

  Offset prevConstrainedPos = Offset.zero;
  bool prevConstrainedFlag = true;

  bool isContainingLabel = false;
  String distanceSensorContent =
      "NEURON will SPIKE when on object is in front of the robot at 1 to 8 cm.";

  double scaleMultiplier = 1.0;
  // Tracks the scaleMultiplier at which neurons were LAST repositioned.
  // Independent of scaleMultiplier (which getDragTargets() updates each frame),
  // so we can detect actual brain-scale changes since the last neuron rescale.
  double _prevNeuronRescaleScale = 0.0;

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
            color: const Color(0xFF1996FC), // Standardized Blue
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
            color: const Color(0xFF55EE55), // Standardized Green
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
            color: const Color(0xFFFF4444), // Standardized Red
          )),
      const Text("Red"),
    ],
  );

  // DEBUG OVERLAY STATE
  String uiDebugLog = "Debug Overlay Active\n";
  bool hasLoggedMatrixDebug = false;

  bool isSelectingCameraTarget = false;

  Map<String, dynamic> selectedEyeInfo = {
    "icon": "Green",
    "label": "Color Green",
    "idx": 2
  };
  String searchCameraTarget = "";
  bool isVisualDetection = true;

  List<bool> colorPositionFlags = [false, false, false];
  List<bool> aiPositionFlags = List<bool>.generate(80, (idx) => false);

  String selectedCameraRegion = "";

  bool isPlayingMode = false;
  List<Offset> arrPosConstraints = [];
  List<Widget> arrCirclePositions = [];
  // late StreamSubscription<ConnectivityResult> subscriptionWifi;

  bool? isPortrait;

  void runNativeC() {
    const level = 1;
    const envelopeSize = 200;
    const bufferSize = 2000;
    nativec.initialize();
    printDebug("motorCommandBufView.length");
    printDebug(neuronSize);
    
    // Force Stop first to clear any zombie state
    nativec.changeIsPlayingProcess(0);
    
    // printDebug(motorCommandBufView.length);
    // printDebug(visPrefsBufView);
    
    // Explicitly start the simulation loop
    nativec.changeIsPlayingProcess(1);
    
    // Web: pass typed lists to WASM stub via conditional import helper.
    // Native: helper returns false → fall through to FFI path.
    final didRunWeb = runWebSimulation(
      nativec,
      updateFromSimulation,
      aBufView, bBufView, cBufView, dBufView,
      iBufView, wBufView, connectomeBufView,
      level, neuronSize, envelopeSize, bufferSize,
      visPrefsBufView, motorCommandBufView, neuronContactsBufView,
      mapNeuronTypeBufView, mapDelayNeuronBufView,
      mapRhytmicNeuronBufView, mapCountingNeuronBufView,
    );
    
    if (!didRunWeb) {
      // Native: pass FFI pointers to C++ thread
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
    
    // Debug Timer Removed checked isPlayingMode (wrong flag)

  }

  void initMemoryAllocation() {
    npsBuf =
        allocate<ffi.Uint32>(count: 2, sizeOfType: ffi.sizeOf<ffi.Uint32>());
    neuronCircleBuf = allocate<ffi.Int16>(
        count: maxPosBuffer, sizeOfType: ffi.sizeOf<ffi.Int16>());
    positionsBuf = allocate<ffi.Int16>(
        count: maxPosBuffer, sizeOfType: ffi.sizeOf<ffi.Int16>());
    aBuf = allocate<ffi.Double>(
        count: maxPosBuffer, sizeOfType: ffi.sizeOf<ffi.Double>());
    bBuf = allocate<ffi.Double>(
        count: maxPosBuffer, sizeOfType: ffi.sizeOf<ffi.Double>());
    cBuf = allocate<ffi.Int16>(
        count: maxPosBuffer, sizeOfType: ffi.sizeOf<ffi.Int16>());
    dBuf = allocate<ffi.Int16>(
        count: maxPosBuffer, sizeOfType: ffi.sizeOf<ffi.Int16>());
    distanceMinLimitBuf = allocate<ffi.Int16>(
        count: maxPosBuffer, sizeOfType: ffi.sizeOf<ffi.Int16>());
    distanceMaxLimitBuf = allocate<ffi.Int16>(
        count: maxPosBuffer, sizeOfType: ffi.sizeOf<ffi.Int16>());
    microphoneBuf = allocate<ffi.Double>(
        count: maxPosBuffer, sizeOfType: ffi.sizeOf<ffi.Double>());
    microphoneMinLimitBuf = allocate<ffi.Int16>(
        count: maxPosBuffer, sizeOfType: ffi.sizeOf<ffi.Int16>());
    microphoneMaxLimitBuf = allocate<ffi.Int16>(
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
    visualInputBuf = allocate<ffi.Double>(
        count: maxPosBuffer * maxPosBuffer,
        sizeOfType: ffi.sizeOf<ffi.Double>());

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
    microphoneTypeBuf = allocate<ffi.Int16>(
        count: maxPosBuffer * maxPosBuffer,
        sizeOfType: ffi.sizeOf<ffi.Int16>());
    neuronLedBuf = allocate<ffi.Int16>(
        count: maxPosBuffer * maxPosBuffer,
        sizeOfType: ffi.sizeOf<ffi.Int16>());
    neuronLedPositionBuf = allocate<ffi.Int16>(
        count: maxPosBuffer * maxPosBuffer,
        sizeOfType: ffi.sizeOf<ffi.Int16>());

    distanceBuf = allocate<ffi.Double>(
        count: maxPosBuffer, sizeOfType: ffi.sizeOf<ffi.Double>());

    // up to 144 neurons
    if (!isInitialized) {
      // The original distanceMinLimitBuf and distanceMaxLimitBuf allocations were here.
      // They are now moved outside the if block and allocated with maxPosBuffer size.
      // areaSizeMinLimitBufView.fillRange(0, 100, 1);
      // areaSizeMaxLimitBufView.fillRange(0, 100, 320);
      // microphoneMinLimitBufView.fillRange(0, 100, 400);
      // microphoneMaxLimitBufView.fillRange(0, 100, 800);
    }

    motorCommandBuf = allocate<ffi.Double>(
        count: motorCommandsLength, sizeOfType: ffi.sizeOf<ffi.Double>());

    stateBuf = allocate<ffi.Int32>(
        count: StateLength, sizeOfType: ffi.sizeOf<ffi.Int>());
    motorCommandMessageBuf = allocate<ffi.Uint8>(
        count: MotorMessageLength, sizeOfType: ffi.sizeOf<ffi.Uint8>());
    printDebug("Init memory allocation");

    mapDelayNeuronList = List.generate(neuronSize, (index) => -1);
    mapRhytmicNeuronList = List.generate(neuronSize, (index) => -1);
    mapCountingNeuronList = List.generate(neuronSize, (index) => -1);
  }

  void initNativeC(bool isInitialized, {bool preserveParams = false}) {
    bufDistanceCount = neuronSize;
    bufPositionCount = neuronSize;
    bufDistanceLimitCount = neuronSize;
    double a = 0.02;
    double b = 0.18;
    int c = -65;
    int d = 2;
    double i = 5.0;
    double w = 2.0;

    // int neuronSizeType = neuronSize;
    if (kIsWeb) {
      nativec = Nativec(); // Web stub — no-op methods
      aBufView  = Float64List(neuronSize);
      bBufView  = Float64List(neuronSize);
      cBufView  = Int16List(neuronSize);
      dBufView  = Int16List(neuronSize);
      iBufView  = Float64List(neuronSize);
      wBufView  = Float64List(neuronSize);
      positionsBufView  = Int16List(neuronSize);
      WaveWidget.positionsBufView = positionsBufView; // Link for WaveWidget on web
      connectomeBufView  = Float64List(neuronSize * neuronSize);
      neuronCircleBridge = Int16List(neuronSize);
      npsBufView = Uint32List(2);
      distanceBufView = Float64List(neuronSize);
      distanceMinLimitBufView = Int16List(neuronSize);
      distanceMaxLimitBufView = Int16List(neuronSize);
      microphoneBufView = Float64List(neuronSize);
      microphoneMinLimitBufView = Int16List(neuronSize);
      microphoneMaxLimitBufView = Int16List(neuronSize);
      microphoneTypeBufView = Int16List(neuronSize);
      // Web-only: create ALL remaining buffer views that native gets from FFI pointers
      visPrefsBufView = Int16List(neuronSize * neuronSize);
      visPrefsValsBufView = Float64List(VisualPrefLength);
      motorCommandBufView = Float64List(motorCommandsLength);
      neuronContactsBufView = Float64List(neuronSize * neuronSize);
      neuronDistanceBufView = Int16List(neuronSize * neuronSize);
      neuronSpeakerBufView = Int16List(neuronSize * neuronSize);
      neuronMicrophoneBufView = Int16List(neuronSize * neuronSize);
      neuronLedBufView = Int16List(neuronSize * neuronSize);
      neuronLedPositionBufView = Int16List(neuronSize * neuronSize);
      mapNeuronTypeBufView = Int16List(neuronSize);
      mapDelayNeuronBufView = Int16List(neuronSize);
      mapRhytmicNeuronBufView = Int16List(neuronSize);
      mapCountingNeuronBufView = Int16List(neuronSize);
      visualInputBufView = Float64List(VisualInputLength * (neuronSize + 2));
      // Link ALL buffer refs to Nativec for WASM live sync (MUST be after allocations)
      Nativec.iBufViewRef = iBufView;
      Nativec.aBufViewRef = aBufView;
      Nativec.bBufViewRef = bBufView;
      Nativec.cBufViewRef = cBufView;
      Nativec.dBufViewRef = dBufView;
      Nativec.wBufViewRef = wBufView;
      Nativec.connectomeBufViewRef = connectomeBufView;
      Nativec.mapNeuronTypeBufViewRef = mapNeuronTypeBufView;
      Nativec.mapDelayNeuronBufViewRef = mapDelayNeuronBufView;
      Nativec.mapRhytmicNeuronBufViewRef = mapRhytmicNeuronBufView;
      Nativec.mapCountingNeuronBufViewRef = mapCountingNeuronBufView;
      Nativec.visPrefsBufViewRef = visPrefsBufView;
      Nativec.neuronContactsBufViewRef = neuronContactsBufView;
      // Link sensor buffers for live Dart→WASM sync (robot → simulation)
      Nativec.distanceBufViewRef = distanceBufView;
      Nativec.microphoneBufViewRef = microphoneBufView;
      Nativec.visualInputBufViewRef = visualInputBufView;
      // Link neuron preference maps (which neurons are distance/speaker/mic/LED)
      Nativec.neuronDistanceBufViewRef = neuronDistanceBufView;
      Nativec.neuronSpeakerBufViewRef = neuronSpeakerBufView;
      Nativec.neuronMicrophoneBufViewRef = neuronMicrophoneBufView;
      Nativec.neuronLedBufViewRef = neuronLedBufView;
      Nativec.neuronLedPositionBufViewRef = neuronLedPositionBufView;
      // Link sensor limit buffers
      Nativec.distanceMinLimitBufViewRef = distanceMinLimitBufView;
      Nativec.distanceMaxLimitBufViewRef = distanceMaxLimitBufView;
      Nativec.microphoneMinLimitBufViewRef = microphoneMinLimitBufView;
      Nativec.microphoneMaxLimitBufViewRef = microphoneMaxLimitBufView;
      Nativec.microphoneTypeBufViewRef = microphoneTypeBufView;
      // Allocate sensor WASM heap pointers (same as native passInput)
      // Use dynamic cast to bypass native FFI type checker (web stub accepts dynamic)
      (nativec as dynamic).passInput(
          distanceBufView,
          distanceMinLimitBufView,
          distanceMaxLimitBufView,
          microphoneBufView,
          microphoneMinLimitBufView,
          microphoneMaxLimitBufView,
          microphoneTypeBufView);
      // Register simulation callback for web (motor/speaker/LED output from WASM)
      nativec.simulationCallback(updateFromSimulation);
    } else {
      // printDebug("try to pass pointers");

      nativec = Nativec();
      nativec.passInput(
          distanceBuf,
          distanceMinLimitBuf,
          distanceMaxLimitBuf,
          microphoneBuf,
          microphoneMinLimitBuf,
          microphoneMaxLimitBuf,
          microphoneTypeBuf);
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
        visualInputBuf,
      );
      
      // CRITICAL FIX: Initialize NativeOpenCV with the same pointers to prevent crash
      NativeOpenCV ocv = NativeOpenCV();
      ocv.initializeOpenCV();
      ocv.passPreprocessPointers(
          stateBuf, visPrefsValsBuf, visPrefsBuf, neuronContactsBuf);
      // printDebug("try to pass nativec pointers");
      aBufView = aBuf.asTypedList(neuronSize);
      bBufView = bBuf.asTypedList(neuronSize);
      cBufView = cBuf.asTypedList(neuronSize);
      dBufView = dBuf.asTypedList(neuronSize);
      iBufView = iBuf.asTypedList(neuronSize);
      wBufView = wBuf.asTypedList(neuronSize);
      npsBufView = npsBuf.asTypedList(2);
      // printDebug("neuronSize neuronCircleBridge");
      // printDebug(neuronSize);
      neuronCircleBridge = neuronCircleBuf.asTypedList(neuronSize);
      printDebug(neuronCircleBridge.length);
      positionsBufView = positionsBuf.asTypedList(bufPositionCount);
      WaveWidget.positionsBufView = positionsBufView; // Link static for WaveWidget
      distanceBufView = distanceBuf.asTypedList(bufDistanceCount);
      distanceMinLimitBufView =
          distanceMinLimitBuf.asTypedList(bufDistanceLimitCount);
      distanceMaxLimitBufView =
          distanceMaxLimitBuf.asTypedList(bufDistanceLimitCount);
      microphoneBufView = microphoneBuf.asTypedList(bufDistanceCount);
      microphoneMinLimitBufView =
          microphoneMinLimitBuf.asTypedList(bufDistanceLimitCount);
      microphoneMaxLimitBufView =
          microphoneMaxLimitBuf.asTypedList(bufDistanceLimitCount);
      microphoneTypeBufView =
          microphoneTypeBuf.asTypedList(bufDistanceCount);
          
      if (!isInitialized) {
        // areaSizeMinLimitBufView was also using empty list? Investigating. 
        // For now, fix Microphone.
        if (neuronSize > 0) {
            microphoneMinLimitBufView.fillRange(0, neuronSize, 400);
            microphoneMaxLimitBufView.fillRange(0, neuronSize, 800);
        }
        
        // Also re-apply areaSize logic if it was broken, although user didn't report it.
        // Assuming areaSize views are assigned nearby.
        try {
           if (neuronSize > 0) {
               areaSizeMinLimitBufView.fillRange(0, neuronSize, 1);
               areaSizeMaxLimitBufView.fillRange(0, neuronSize, 320);
           }
        } catch (e) {
           printDebug("AreaSize init failed: $e");
        }
      }
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
      neuronMicrophoneBufView.fillRange(0, neuronSize * neuronSize, -1);
      neuronLedBufView = neuronLedBuf.asTypedList(neuronSize * neuronSize);
      neuronLedPositionBufView =
          neuronLedPositionBuf.asTypedList(neuronSize * neuronSize);

      mapNeuronTypeBufView = mapNeuronTypeBuf.asTypedList(neuronSize);
      mapDelayNeuronBufView = mapDelayNeuronBuf.asTypedList(neuronSize);
      mapRhytmicNeuronBufView = mapRhytmicNeuronBuf.asTypedList(neuronSize);
      mapCountingNeuronBufView = mapCountingNeuronBuf.asTypedList(neuronSize);

      visualInputBufView =
          visualInputBuf.asTypedList(VisualInputLength * (neuronSize + 2));

      // if (!isSimulationCallbackAttached) {
      //   isSimulationCallbackAttached = true;
      // if (isInitialized) {
        nativec.simulationCallback(updateFromSimulation);
      // }
      // }
    }

    if (!preserveParams) {
      // if (isInitialized) {
      // printDebug("isInitialized anandasd");
      aBufView.fillRange(0, neuronSize, a);
      bBufView.fillRange(0, neuronSize, b);
      cBufView.fillRange(0, neuronSize, c);
      dBufView.fillRange(0, neuronSize, d);
      iBufView.fillRange(0, neuronSize, i);
      wBufView.fillRange(0, neuronSize, w);
      // }
    }
    positionsBufView.fillRange(0, 1, 0);
    distanceBufView.fillRange(0, 1, 0);
    distanceMinLimitBufView.fillRange(0, bufDistanceLimitCount, 1);
    distanceMaxLimitBufView.fillRange(0, bufDistanceLimitCount, 8);
    microphoneBufView.fillRange(0, bufDistanceCount, 0);
    microphoneMinLimitBufView.fillRange(0, bufDistanceLimitCount, 1);
    microphoneMaxLimitBufView.fillRange(0, bufDistanceLimitCount, 100);
    microphoneTypeBufView.fillRange(0, bufDistanceCount, 0);
    // distanceLimitBufView[0] = 1;
    // distanceLimitBufView[1] = 8;

    connectomeBufView.fillRange(0, neuronSize * neuronSize, 0.0);
    visPrefsBufView.fillRange(0, neuronSize * neuronSize, -1);
    visPrefsValsBufView.fillRange(0, VisualPrefLength, 0);
    visualInputBufView.fillRange(0, VisualInputLength * neuronSize, 0); // V29 FIX: 0 not -1
    
    mapNeuronTypeBufView.fillRange(0, neuronSize, -1);
    mapDelayNeuronBufView.fillRange(0, neuronSize, -1);
    mapRhytmicNeuronBufView.fillRange(0, neuronSize, -1);
    mapCountingNeuronBufView.fillRange(0, neuronSize, -1);

    // Restore configured delay values from Dart list → native buffer.
    // initNativeC resets the buffer to -1, but delay neurons must have their
    // delay pre-loaded BEFORE the first spike arrives, otherwise the native
    // simulation reads -1 (no delay) and fires immediately on first activation.
    for (int i = 0; i < neuronSize && i < mapDelayNeuronList.length; i++) {
      if (mapDelayNeuronList[i] > 0 && i < mapDelayNeuronBufView.length) {
        mapDelayNeuronBufView[i] = mapDelayNeuronList[i];
      }
    }

    neuronContactsBufView.fillRange(0, neuronSize * neuronSize, 0);
    motorCommandBufView.fillRange(0, motorCommandsLength, 0.0);

    printDebug("neuronSize * neuronSize");
    printDebug(neuronSize * neuronSize);

    squareActiveCirclesPainter = List.generate(neuronSize, (index) {
        try {
          if (index < syntheticNeuronList.length) {
            return SingleCircle(
              isActive: true,
              isExcitatory: ((syntheticNeuronList[index].node?.isExcitatory ?? 1) == 1) ? 1 : 0,
              circleRadius: neuronDrawSize / 2,
              xNucleus: syntheticNeuronList[index].newNeuron.xNucleus,
              yNucleus: syntheticNeuronList[index].newNeuron.yNucleus,
              widthNucleus: syntheticNeuronList[index].newNeuron.widthNucleus,
              heightNucleus: syntheticNeuronList[index].newNeuron.heightNucleus,
            );
          }
        } catch (e) {
          // Fallthrough to default
          printDebug("Error generating squareActiveCirclesPainter for index $index: $e");
        }
        return SingleCircle(
            isActive: true,
            isExcitatory: 1, // Default
            circleRadius: neuronDrawSize / 2,
            xNucleus: neuronDrawSize / 2,
            yNucleus: neuronDrawSize / 2,
            widthNucleus: neuronDrawSize / 3,
            heightNucleus: neuronDrawSize / 3,
        );
    });

    squareInactiveCirclesPainter = List.generate(neuronSize, (index) {
        try {
             if (index < syntheticNeuronList.length) {
                return SingleCircle(
                isActive: false,
                isExcitatory: ((syntheticNeuronList[index].node?.isExcitatory ?? 1) == 1) ? 1 : 0,
                circleRadius: neuronDrawSize / 2,
                xNucleus: syntheticNeuronList[index].newNeuron.xNucleus,
                yNucleus: syntheticNeuronList[index].newNeuron.yNucleus,
                widthNucleus: syntheticNeuronList[index].newNeuron.widthNucleus,
                heightNucleus: syntheticNeuronList[index].newNeuron.heightNucleus,
                );
            }
        } catch (e) {
            // Fallthrough
            printDebug("Error generating squareInactiveCirclesPainter for index $index: $e");
        }
        return SingleCircle(
            isActive: false,
            isExcitatory: 1,
            circleRadius: neuronDrawSize / 2,
            xNucleus: neuronDrawSize / 2,
            yNucleus: neuronDrawSize / 2,
            widthNucleus: neuronDrawSize / 3,
            heightNucleus: neuronDrawSize / 3,
        );
    });

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

    printDebug("NEW NEUORN SPIKE FLAGS!!!");
    neuronSpikeFlags =
        List<ValueNotifier<int>>.generate(neuronSize, (_) => ValueNotifier(0));
    neuronCircleKeys = List<GlobalKey>.generate(neuronSize,
        (i) => GlobalKey(debugLabel: "neuronWidget${i.toString()}"));

    // if (!isInitialized) {
    if (!isInitialized) {
      // printDebug("IS Initialized");
      // printDebug(syntheticNeuronList.length);
      // printDebug(syntheticNeuronList.map((SyntheticNeuron e) {
      //   return "${e.newNeuron.xNucleus} - ${e.newNeuron.yNucleus} @ ${e.newNeuron.widthNucleus} : ${e.newNeuron.heightNucleus}";
      // }).toList());

       neuronActiveCirclesPainter =
         List.generate(neuronSize, (index) {
        try {
            if (index < syntheticNeuronList.length) {
                return SingleCircle(
                    isActive: true,
                    isExcitatory: syntheticNeuronList[index].node?.isExcitatory ?? 1,
                    circleRadius: neuronDrawSize / 2,
                    xNucleus: syntheticNeuronList[index].newNeuron.xNucleus,
                    yNucleus: syntheticNeuronList[index].newNeuron.yNucleus,
                    widthNucleus: syntheticNeuronList[index].newNeuron.widthNucleus,
                    heightNucleus: syntheticNeuronList[index].newNeuron.heightNucleus,
                );
            }
        } catch (e) {
            // Fallthrough
            printDebug("Error generating neuronActiveCirclesPainter for index $index: $e");
        }
        return SingleCircle(
            isActive: true, // Default active
            isExcitatory: 1, // Default Excitatory
            circleRadius: neuronDrawSize / 2,
            xNucleus: neuronDrawSize / 2, // Center of tile
            yNucleus: neuronDrawSize / 2, // Center of tile
            widthNucleus: neuronDrawSize / 3, // Reasonable default size
            heightNucleus: neuronDrawSize / 3, // Reasonable default size
        );
      });
      neuronInactiveCirclesPainter =
          List.generate(neuronSize, (index) {
        try {
            if (index < syntheticNeuronList.length) {
                return SingleCircle(
                isActive: false,
                    isExcitatory: syntheticNeuronList[index].node?.isExcitatory ?? 1,
                circleRadius: neuronDrawSize / 2,
                xNucleus: syntheticNeuronList[index].newNeuron.xNucleus,
                yNucleus: syntheticNeuronList[index].newNeuron.yNucleus,
                widthNucleus: syntheticNeuronList[index].newNeuron.widthNucleus,
                heightNucleus: syntheticNeuronList[index].newNeuron.heightNucleus,
                );
            }
        } catch (e) {
            // Fallthrough
            printDebug("Error generating neuronInactiveCirclesPainter for index $index: $e");
        }
        return SingleCircle(
            isActive: false, // Default inactive
            isExcitatory: 1,
            circleRadius: neuronDrawSize / 2,
            xNucleus: neuronDrawSize / 2,
            yNucleus: neuronDrawSize / 2,
            widthNucleus: neuronDrawSize / 3,
            heightNucleus: neuronDrawSize / 3,
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
    }

    // if (controller.nucleusList != null) {
    //   controller.nucleusList!.clear();
    // } else {
    //   controller.nucleusList = [];
    // }
    // int circleLen = protoNeuron.circles.length;
    // for (int i = 0; i < circleLen; i++) {
    //   SingleNeuron neuron = protoNeuron.circles[i];
    //   Nucleus nucleus = Nucleus(
    //     index: i,
    //     isSpiking: neuron.isSpiking,
    //     neuronActiveCircle: neuronActiveCircles[i],
    //     neuronInactiveCircle: neuronInactiveCircles[i],
    //     neuronSpikeFlag: neuronSpikeFlags[i],
    //     centerPos: neuron.centerPos,
    //     circleKey: neuronCircleKeys[i],
    //   );
    //   controller.nucleusList!.add(nucleus);
    // }
    // WaveWidget.positionsBufView = positionsBufView; // REMOVED

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

  static late InfiniteCanvasController controller;
  int menuIdx = 0;
  bool isCreatePoint = false;

  static int aiVisualTypes = 0;
  static int imageVisualTypes = 0;
  static int currentActiveColors = 0;

  Map mapConnectome = {};
  static Map mapSensoryNeuron = {}; // vis prefs
  Map mapContactsNeuron = {};
  Map mapDistanceNeuron = {}; // dist prefs
  Map mapDistanceLimitNeuron = {}; // dist limit prefs
  Map mapSpeakerNeuron = {};
  Map mapMicrophoneNeuron = {};
  Map mapMicrophoneTypeNeuron = {};
  Map mapMicrophoneLimitNeuron = {};
  Map mapLedNeuron = {};
  Map mapLedNeuronPosition = {};
  Map<String, String> mapLedHex = {};
  Map<String, String> mapLedBrightness = {};

  // LED Widget State
  String _robotLedActive = "1111";
  String _robotLedHex = "FD8164";
  String _robotLedBrightness = "1.00";
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
    size: const Size(20, 20),
    child: Container(width: 15, height: 15, color: Colors.transparent),
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
    child: Container(width: 15, height: 15, color: Colors.transparent),
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
  double safePaddingLeft = 0.0;
  double safePaddingTop = 0.0;
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
  bool isCameraExpanded = false;
  Future<void> _getWifiName() async {
    String? wifiNameStr;
    try {
      wifiNameStr = await _networkInfo.getWifiName();
    } catch (e) {
      wifiNameStr = null;
    }
    if (mounted) {
       // Remove quotes if present (iOS often returns "SSID")
       String cleanName = (wifiNameStr ?? "").replaceAll('"', '');
       // Check for "Spikerbot" or "SpikerBot" (case-insensitive)
       bool isSpikerbot = cleanName.toLowerCase().startsWith("spikerbot"); 
       
       // Check for Battery Heartbeat (last 1 second)
       bool isHeartbeatActive = lastBatteryUpdate != null && 
           DateTime.now().difference(lastBatteryUpdate!).inSeconds < 3; // Increased to 3s for iPad robustness

       // Update State variable for UI visibility (Battery Widget)
       if (isRobotConnected != isHeartbeatActive) {
           setState(() {
              isRobotConnected = isHeartbeatActive;
           });
       }

       String displayString = cleanName;
       
       // Priority Logic:
       // 1. If we have a valid Spikerbot SSID, show it.
       // 2. If no SSID but Robot Heartbeat is active, show "SpikerBot Connected!".
       // 3. Else, "No SpikerBot Detected." (only if NOT initially waiting? User said "not display until check").
       //    For now, standard logic:
       if (isSpikerbot) {
           displayString = cleanName;
       } else if (isHeartbeatActive) {
           displayString = "SpikerBot Connected!";
       } else {
           displayString = "No SpikerBot Detected.";
       }

       if (wifiName != displayString) {
           setState(() {
               wifiName = displayString;
           });
       }
    }
  }



  void _showRenameDialog() {
      TextEditingController renameController = TextEditingController();
      showDialog(
          barrierDismissible: false, // Prevent accidental closing (palm touches/flicker)
          context: context, 
          builder: (context) {
              return AlertDialog(
                  // Compact Padding for Landscape (iPhone Mini)
                  titlePadding: const EdgeInsets.fromLTRB(24, 15, 24, 0),
                  contentPadding: const EdgeInsets.fromLTRB(24, 10, 24, 0),
                  actionsPadding: const EdgeInsets.fromLTRB(0, 0, 0, 5),
                  insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  
                  actionsAlignment: MainAxisAlignment.center, 
                  title: const Text("Rename Spikerbot", textAlign: TextAlign.center),
                  content: SizedBox(
                      width: 250, 
                      child: SingleChildScrollView( // Allow scrolling on very small screens
                        child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                                const Text("When you rename Spikerbot, it will reboot for you to connect again with it's new name!", 
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 14), // Slightly smaller checks
                                ),
                                const SizedBox(height: 10), // Reduced gap
                                TextField(
                                    controller: renameController,
                                    autofocus: true,
                                    maxLength: 22, 
                                    decoration: const InputDecoration(
                                        border: OutlineInputBorder(),
                                        labelText: 'New Name',
                                        hintText: 'Enter name...',
                                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8), // Compact input
                                        isDense: true,
                                    ),
                                ),
                            ]
                        ),
                      ),
                  ),
                  actions: [
                      TextButton(
                          onPressed: () { Navigator.of(context).pop(); },
                          child: const Text("Cancel")
                      ),
                      TextButton(
                          onPressed: () { 
                              String newName = renameController.text.trim();
                              if (newName.isNotEmpty) {
                                  // Send Rename command
                                  try {
                                      sendToRobot("n:$newName;");
                                      
                                      // Stop Simulation & Robot (Rebooting)
                                      sendToRobot("m:0;0;"); // Stop motors
                                      isSimulatingBrain = false;
                                      isRobotConnected = false;
                                      isPlayingMenu = false; 
                                      isEmergencyPause = false; 
                                      controller.isPlaying = false; 
                                      
                                      // Reset Pin Placement (Cleanup like Stop)
                                      controller.deselectAll();
                                      isDrawTail = false;
                                      
                                      // CRITICAL FIX: Only clear the PINS (User Tools), NOT the Axons (Edges)!
                                      // Clearing edges wiped the brain anatomy. We only want to reset the probes.
                                      placedPins.clear();
                                      hoveringPinNeuronIdx = -1;
                                      
                                      // Animation: Smooth slide back to Design Center
                                      _animateCanvasToReset(false);
                                      currentWaveNeuronIdx = -1;
                                      currentWaveNeuronIdx2 = -1;
                                      
                                      // Reset Native Selections
                                      nativec.changeIdxSelected(-1); 
                                      nativec.changeIdxSelected2(-1);
                                      
                                      setState(() {});
                                      
                                      Navigator.of(context).pop();
                                      
                                      // Optional: Show "Rebooting" toast/snack?
                                      ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                              backgroundColor: const Color(0xFFFD8164), // BYB Orange
                                              content: Text(
                                                  "Renaming to $newName... Spikerbot is rebooting.",
                                                  textAlign: TextAlign.center,
                                                  style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)
                                              )
                                          )
                                      );
                                  } catch (e) {
                                      printDebug("Rename Error: $e");
                                  }
                              }
                          },
                          style: TextButton.styleFrom(foregroundColor: const Color(0xFFFD8164)), // BYB Signature Color
                          child: const Text("Rename!")
                      )
                  ]
              );
          }
      );
  }

  @override
  void dispose() async {
    BrainFileHandler.instance.unregisterCallback();
    synapseFadeController?.dispose();
    _rcBindingVersion.dispose();
    windowManager.removeListener(this);
    // Remove global scroll route to prevent leaks
    GestureBinding.instance.pointerRouter.removeGlobalRoute(_globalScrollRoute);
    detector?.stop();
    _imageDetectorSubscription?.cancel();

    printDebug("DISPOSEEE");
    try {
      processor.clearMemory();
    } catch (e) {}
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
    _annotationDescController.dispose();
    _annotationScrollController.dispose();
    _annotationFocusNode.dispose();
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
    _canvasAnimController.dispose();
    super.dispose();

    // ignore: avoid_print
  }

  void freeUsedMemory() {
  // CRITICAL FIX: Unregister pointers in C++ before freeing memory.
  // This prevents C++ from accessing freed memory (Use-After-Free) 
  // if a background thread/isolate is still processing a frame.
  initializeOpenCV(ffi.nullptr, ffi.nullptr, ffi.nullptr, ffi.nullptr);

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
  // CRITICAL FIX: Do NOT free these buffers.
  // The background video processing isolate (native_opencv) maintains pointers to these buffers
  // and may try to read/write them even after this page is disposed (race condition).
  // Freeing them causes a persistent crash (Use-After-Free). Leaking them is safe behavior here.
  // freeMemory(visPrefsBuf);
  // freeMemory(visPrefsValsBuf);
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

    // ── Web: use browser-native WebSocket (no Isolate available) ──
    if (kIsWeb) {
      if (webWsBridge == null) {
        webWsBridge = WebSocketBridge.instance(webSocketLink);
        webWsBridge!.onMessage((message) async {
          if (message == "RESTART") {
            isIsolateWritePortInitialized = false;
            printDebug("WEB_WS: RESTart");
            Future.delayed(const Duration(milliseconds: 1000), () async {
              if (isPlayingMenu) {
                // Re-init the bridge connection
                webWsBridge?.send("INIT_WEBSOCKET");
                isIsolateWritePortInitialized = true;
              }
            });
          } else if (message == "DISCONNECTED") {
            isIsolateWritePortInitialized = false;
            if (!isPlayingMenu) {
              controller.deselectAll();
              controller.setCanvasMove(true);
              // Only reset play/pause state when NOT actively simulating.
              // WASM simulation runs locally and doesn't require robot connection.
              isEmergencyPause = false;
            }
            Future.delayed(const Duration(milliseconds: 1000), () {
              rightToolbarKey = UniqueKey();
              if (mounted) setState(() {});
            });
            if (mounted) setState(() {});
          } else {
            // Sensor data from robot — same parsing as native path
            if (message is String) {
              try {
                if (message.startsWith("V")) {
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
                // Parse IMU field: " i:110" → tap=1, motion=1, tilt=0
                int imuIdx = message.indexOf(' i:');
                if (imuIdx != -1 && imuIdx + 5 < message.length) {
                  imuTapActive    = message[imuIdx + 3] == '1';
                  imuMotionActive = message[imuIdx + 4] == '1';
                  imuTiltActive   = message[imuIdx + 5] == '1';
                }
                if (message.startsWith("M:")) {
                  List<String> mArr = message.substring(2).replaceAll(";", "").split(",");
                  if (mArr.isNotEmpty) {
                    double micFreq = double.tryParse(mArr[0]) ?? 0.0;
                    double micVol = mArr.length > 1 ? double.tryParse(mArr[1]) ?? 0.0 : micFreq;
                    if (microphoneBufView.length >= 2) {
                      microphoneBufView[0] = micFreq;
                      microphoneBufView[1] = micVol;
                    }
                  }
                } else if (message.startsWith("D:")) {
                  String dStr = message.substring(2).replaceAll(";", "");
                  double distVal = double.tryParse(dStr) ?? 0.0;
                  if (distanceBufView.isNotEmpty) distanceBufView[0] = distVal;
                } else if (message.startsWith("B:")) {
                  String bStr = message.substring(2).replaceAll(";", "");
                  int rawADC = int.tryParse(bStr.trim()) ?? 0;
                  double voltage = (rawADC / 1023.0) * 3.3 * 2.0;
                  double rawPercent = ((voltage - 3.9) / (5.8 - 3.9)) * 100.0;
                  batteryPercent = rawPercent.floor();
                  lastBatteryUpdate = DateTime.now();
                  if (mounted && !isRobotConnected) _getWifiName();
                  if (batteryPercent > 100) batteryPercent = 100;
                  if (batteryPercent <= 0) batteryPercent = 0;
                  batteryVoltage = "$rawADC (${batteryPercent}%)";
                  if (mounted) setState(() {});
                } else {
                  List<String> arr = message.split(",");
                  if (arr.length > 3) {
                    try {
                      double distVal = double.parse(arr[2]);
                      double micVol = double.parse(arr[1]);
                      double micFreq = double.parse(arr[0]);
                      if (distanceBufView.isNotEmpty) distanceBufView[0] = distVal;
                      if (microphoneBufView.length >= 2) {
                        microphoneBufView[0] = micFreq;
                        microphoneBufView[1] = micVol;
                      }
                    } catch (e) {}
                    int rawADC = int.tryParse(arr[3].trim()) ?? 0;
                    double voltage = (rawADC / 1023.0) * 3.3 * 2.0;
                    double rawPercent = ((voltage - 3.9) / (5.8 - 3.9)) * 100.0;
                    batteryPercent = rawPercent.floor();
                    lastBatteryUpdate = DateTime.now();
                    if (mounted && !isRobotConnected) _getWifiName();
                    if (batteryPercent > 100) batteryPercent = 100;
                    if (batteryPercent <= 0) batteryPercent = 0;
                    batteryVoltage = "$rawADC (${batteryPercent}%)";
                    if (mounted) setState(() {});
                  }
                }
              } catch (err) {
                printDebug("WEB_WS: err parsing: $err");
              }
            }
          }
        });
        webWsBridge!.send("INIT_WEBSOCKET");
        isIsolateWritePortInitialized = true;
      } else {
        // Re-init existing bridge
        printDebug("WEB_WS: REOPEN WEBSOCKET");
        webWsBridge!.send("INIT_WEBSOCKET");
        isIsolateWritePortInitialized = true;
      }
      return "";
    }

    // ── Native: use Isolate-based WebSocket (original path) ──
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
                key: UniqueKey(), // Force hard UI rebuild
                error: (context, error, stack) {
                  return const Text("\r\nNot connected\r\nto SpikerBot\r\nWiFi",
                      style: TextStyle(fontSize: 10, color: Colors.brown));
                },
                stream: httpdStream,
                // stream: "http://192.168.1.4:8081/",
                preprocessor: processor,
                width: 320,
                height: 240,

                isLive: true,
                fit: BoxFit.fill,
                timeout: const Duration(seconds: 60),
              );
              if (mounted) setState(() {}); // Inform UI of new stream
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
              if (!isPlayingMenu) {
                  nativec.stopThreadProcess(0);
                  isSimulatingBrain = false;
                  printDebug("stopping thread finished");
              } else {
                  printDebug("Socket disconnected but simulation is LIVE. Leaving OpenCV engine running.");
              }
              
              // Pin cleanup: only clear background state, NOT placedPins
              // Pins persist across play/pause/design transitions (cleared on brain load/new)
              hoveringPinNeuronIdx = -1;
              mapBg["activeComponent"] = noActiveComponent;
              mapBg["activeBg"] = defaultBg;
              initializeNucleus();
            }
            controller.deselectAll();
            controller.setCanvasMove(true);
          } catch (err) {}

          Future.delayed(const Duration(milliseconds: 1000), () {
            // rightToolbarGlobalKey = GlobalKey();
            // rightToolbarCallback({"menuIdx": 0}); // Keep Menu Open
            rightToolbarKey = UniqueKey();
            setState(() {});
          });
          // clearUIMenu(); // Keep UI

          isEmergencyPause = false;
          // isPlayingMenu = false; // Keep Menu Open!
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

          // Parse IMU field: " i:110" → tap=1, motion=1, tilt=0
          int imuIdx = message.indexOf(' i:');
          if (imuIdx != -1 && imuIdx + 5 < message.length) {
            imuTapActive    = message[imuIdx + 3] == '1';
            imuMotionActive = message[imuIdx + 4] == '1';
            imuTiltActive   = message[imuIdx + 5] == '1';
          }

          try {
            // --- NEW PREFIX PROTOCOL ---
            if (message.startsWith("M:")) {
                List<String> mArr = message.substring(2).replaceAll(";", "").split(",");
                if (mArr.isNotEmpty) {
                    double micFreq = double.tryParse(mArr[0]) ?? 0.0;
                    double micVol = mArr.length > 1 ? double.tryParse(mArr[1]) ?? 0.0 : micFreq;
                    if (microphoneBufView.length >= 2) {
                        microphoneBufView[0] = micFreq;
                        microphoneBufView[1] = micVol;
                    }
                }
            } else if (message.startsWith("D:")) {
                String dStr = message.substring(2).replaceAll(";", "");
                double distVal = double.tryParse(dStr) ?? 0.0;
                if (distanceBufView.isNotEmpty) distanceBufView[0] = distVal;
            } else if (message.startsWith("B:")) {
                String bStr = message.substring(2).replaceAll(";", "");
                int rawADC = int.tryParse(bStr.trim()) ?? 0;
                
                double voltage = (rawADC / 1023.0) * 3.3 * 2.0;
                double rawPercent = ((voltage - 3.9) / (5.8 - 3.9)) * 100.0;
                batteryPercent = rawPercent.floor();
                lastBatteryUpdate = DateTime.now(); // Heartbeat
                
                if (mounted && !isRobotConnected) _getWifiName();
                if (batteryPercent > 100) batteryPercent = 100;
                if (batteryPercent <= 0) batteryPercent = 0;
                
                batteryVoltage = "$rawADC (${batteryPercent}%)";
                setState(() {});
            } 
            // --- LEGACY CSV PROTOCOL (Backward Compatibility) ---
            else {
              List<String> arr = message.split(",");
              if (arr.length > 3) {
                try {
                   double distVal = double.parse(arr[2]);
                   double micVol = double.parse(arr[1]);
                   double micFreq = double.parse(arr[0]);
                   
                   if (distanceBufView.isNotEmpty) distanceBufView[0] = distVal;
                   if (microphoneBufView.length >= 2) {
                       microphoneBufView[0] = micFreq;
                       microphoneBufView[1] = micVol;
                   }
                } catch (e) {
                   print("Error parsing distance/mic: $e");
                }

                int rawADC = int.tryParse(arr[3].trim()) ?? 0;
                double voltage = (rawADC / 1023.0) * 3.3 * 2.0;
                double rawPercent = ((voltage - 3.9) / (5.8 - 3.9)) * 100.0;
                batteryPercent = rawPercent.floor();
                lastBatteryUpdate = DateTime.now(); // Heartbeat
                
                if (mounted && !isRobotConnected) _getWifiName();
                if (batteryPercent > 100) batteryPercent = 100;
                if (batteryPercent <= 0) batteryPercent = 0;
                
                batteryVoltage = "$rawADC (${batteryPercent}%)";
                setState(() {});
              }
            }
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
                // IMPORTANT FIX:
                // Removed manual hardcoded thresholds (e.g., 0.3 or 0.4) because they structurally blocked 
                // the Native Engine's Ghost Frames (score * 0.5) causing Hysteresis to fail and jitter.
                // The native detector_service optimally controls dynamic luminance thresholds now.
                // We no longer artificially clamp scores here, allowing structural hysteresis to cleanly inject trace currents.
                aiObjectsInfo.add(res);
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
              // IMPORTANT FIX: Rely purely on Native Tracking thresholds natively modulated by luminance
              // instead of hard-dropping detections below a rigid limit, which previously killed Hysteresis.
              int foundIdx = cameraMenuTypes.indexOf(results![i].label.trim());
              // reset value
              // set new value
              isShowingLeftAiMenu = false;
              isShowingRightAiMenu = false;
              for (String key in mapSensoryNeuron.keys) {
                Recognition r = results![i];
                List<String> modes = mapAreaSize[key].split("_@_");
                bool flag = containRecognition(r, modes);
                // printDebug("containRecognition(r, modes)");
                // printDebug(flag);
                // printDebug(key);
                // printDebug(foundIdx);
                // printDebug(key.contains(nodeLeftEyeSensor.key.toString()));
                if (key.contains(nodeLeftEyeSensor.key.toString()) &&
                    flag &&
                    foundIdx >= 7) {
                  // check if the option set == TFLite result
                  if (mapSensoryNeuron[key] == foundIdx) {
                    // REMOVED GLOBAL ASSIGNMENT TO FIX SPATIAL CROSSTALK
                    // visPrefsValsBufView[foundIdx] = results![i].score * 50;
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

                        // IMPORTANT FIX: Replaced analog drop-off jitter.
                        // Instead of multiplying by dropping confidence scores (which cause stuttering ghost-frames),
                        // we provide a constant unbroken current of 50.0 identical to the Color Blob targets 
                        // as long as the TFLite native hysteresis box maintains the silhouette's presence inside the FOV.
                        visualInputBufView[
                                foundIdx + jNeuronIdx * VisualInputLength] =
                            50.0;
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
          // Removed debouncer zeroing logic completely as per user review. 
          // Neural TFLite activity is now purely driven by the data event frames matching the visual UI implicitly, 
          // ensuring absolute parity without arbitrary async timeouts breaking streams on slow ipads.
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

  int neuronMenuTypeIdx = 0;
  String wifiName = "WiFi: ..."; 
  final NetworkInfo _networkInfo = NetworkInfo();

  // Screenshot Controller (State Level)
  ScreenshotController screenshotController = ScreenshotController();

  void handleEmbeddedSpike() {
    if (controller.selection.isNotEmpty) {
      int neuronIdx = -1;
neuronIdx = controller.nodes.map((e) => e.id).toList().indexOf(controller.selection[0].id) - 2;
      if (neuronIdx >= 0 && neuronIdx < (controller.nucleusList?.length ?? 0)) {
        controller.nucleusList![neuronIdx].lastSpikeTime = DateTime.now().millisecondsSinceEpoch;
        neuronSpikeFlags[neuronIdx].value = DateTime.now().millisecondsSinceEpoch;
        // Repopulate cachedSynapses so ALL downstream synapse terminals blink,
        // then start the fade one frame later (after edge renderer has painted).
        controller.notifyListeners();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          synapseFadeController?.forward(from: 0.0);
        });
      }
    }
  }

  @override
  void initState() {
    instance = this;
    // Global route: fires before PointerSignalResolver, registers our scroll handler
    // FIRST so _firstRegisteredCallback ??= wins unconditionally over any overlay widget.
    // This guarantees 2-finger trackpad pan reaches the canvas regardless of what's shown.
    GestureBinding.instance.pointerRouter.addGlobalRoute(_globalScrollRoute);
    searchCameraTargetTextField = SearchTextField(
        hintText: "Search", // V16: Simplified Hint
        fillColor: Colors.white, // V16: White Background
        controller: tecSearchCameraTarget,
        onChanged: (str) {
          searchCameraTarget = str;
          if (mounted) setState(() {});
        });
    onDebugUpdate = () {
      if (mounted) setState(() {});
    };
    
    synapseFadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );
    synapseFadeController?.addListener(() {
       // Skip synapse repaint during camera animation — avoids CustomPainter
       // repaints mid-pan which interfere with smooth frame delivery.
       if (!controller.isAnimatingCamera) {
         controller.synapseFadeNotifier.value++;
       }
    });

    // Animation Controller for Canvas Fluidity
    _canvasAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000), // Fluid 1s transition
    );
    _canvasAnimController.addListener(() {
      if (controller.nodes.isNotEmpty) { // Safety check
         controller.transform.value = _canvasAnimation.value;
         // No notifyListeners() here — TransformationController already
         // notifies InteractiveViewer and schedules a display-sync repaint.
         // Calling notifyListeners() here caused 60fps full canvas rebuilds
         // (all axon Bezier paths) for the entire 1-second pan animation.
      }
    });
    // Safety net: if the .then() Future doesn't resolve (widget disposed
    // mid-animation), isAnimatingCamera would stay true forever and block
    // ALL canvas onUpdate setState calls. The statusListener is always called.
    _canvasAnimController.addStatusListener((status) {
      if (status == AnimationStatus.completed || status == AnimationStatus.dismissed) {
        if (controller.isAnimatingCamera && mounted) {
          controller.isAnimatingCamera = false;
          controller.notifyListeners();
        }
      }
    });
    processor = ImagePreprocessor();
    
    // WiFi Check Init
    _getWifiName();
    startWebSocket(); // Auto-connect to Spikerbot for heartbeat detection
    Timer.periodic(const Duration(seconds: 5), (timer) {
        _getWifiName();
    });
    
    // V25: Initialize Controller logic moved to build/init block to avoid LateInitializationError


    super.initState();
    BrainFileHandler.instance.registerCallback(selectSavedBrain);
    soloud = AppAudio.instance;
    Future.delayed(const Duration(milliseconds: 1000), () async {
      try {
      await soloud?.init();
        await soloud?.loadAsset('assets/audio/NeuronOnTouch.mp3').then((src) {
          // 1
          neuronOnTouchSource = src;
        });
        await soloud?.loadAsset('assets/audio/NeuronSpikes.mp3').then((src) {
          // 2
          neuronSpikesSource = src;
        });
        await soloud?.loadAsset('assets/audio/AxonStretch.mp3').then((src) {
          // 3
          axonStretchSource = src;
        });

        await soloud?.loadAsset('assets/audio/ObjectPlaced.mp3').then((src) {
          // 4
          objectPlacedSource = src;
        });
        await soloud?.loadAsset('assets/audio/ButtonOnPress.mp3').then((src) {
          // 5
          buttonOnPressedSource = src;
        });

        await soloud?.loadAsset('assets/audio/ButtonPop.mp3').then((src) {
          // 6
          buttonPopSource = src;
        });
        await soloud?.loadAsset('assets/audio/Erase.mp3').then((src) {
          // 7
          eraseSource = src;
        });
        await soloud?.loadAsset('assets/audio/PageFlip.mp3').then((src) {
          // 8
          pageFlipSource = src;
        });

      } catch (e) {
        print('AppAudio init error: $e');
        soloud = null;
      }
    });

    windowManager.addListener(this);
    initImageDetector();

    if (Platform.isIOS || Platform.isAndroid) {
      neuronDrawSize = 20;
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
      if (!kIsWeb) {
      initMemoryAllocation();
      }
      initNativeC(true);
      if (!kIsWeb) {
      initializeOpenCV(
          stateBuf, visPrefsValsBuf, visPrefsBuf, neuronContactsBuf);
      } else {
      // On web, vision_stub.dart initializes the color_detector.worker.js
      initializeOpenCV(null, null, null, null);
      }
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
      key: UniqueKey(), // Force hard UI rebuild
      error: (context, error, stack) {
        return const Text("\r\nNot connected\r\nto SpikerBot\r\nWiFi",
            style: TextStyle(fontSize: 10, color: Colors.brown));
      },

      stream: httpdStream,
      // stream: "http://192.168.1.4:8081/",
      preprocessor: processor,
      width: 320,
      height: 240,
      // width: 320,
      // height: 240,

      isLive: true,
      fit: BoxFit.fill,
      timeout: const Duration(seconds: 60),
    );

    // List<String> empty = [];
    // previousBufferTime = DateTime.now().millisecondsSinceEpoch;
    // Timer.periodic(const Duration(milliseconds: 20), (timer) async {
    // });
    previousBufferTime = DateTime.now().millisecondsSinceEpoch;
    processRobotMessages();

    Timer.periodic(const Duration(milliseconds: 16), (timer) {
      processRobotMessages();
      if (isChartSelected || currentWaveNeuronIdx != -1 || currentWaveNeuronIdx2 != -1) {
        // printDebug("redraw");
        // printDebug(Nativec.canvasBufferBytes1);
        waveRedraw.value = Random().nextInt(10000);
      }
      // V25: Removed the blind 60fps waveRedraw force-trigger.
      // The canvas will now strictly rely on processRobotMessages > periodicNeuronSpikingFlags
      // to only notify waveRedraw when actual physics neuron states visually change.
    });
  }

  void _animateCanvasToReset(bool centerHorizontal, {bool shiftDown = false, bool animate = true, VoidCallback? onComplete}) {
     Matrix4 currentMatrix = controller.transform.value;
     Matrix4 targetMatrix = Matrix4.identity(); // Scale 1.0, Origin 0,0

     double deltaX = 0.0;
     double deltaY = 0.0;

     bool isLandscapeMode = MediaQuery.of(context).orientation == Orientation.landscape;
     final double safeBottom = MediaQuery.of(context).padding.bottom;
     const double kIconSize = 70.0; // Neuron icon size (LeftToolbar child width/height)
     const double kGap      = 56.0; // Visual clearance from panel right/top edge

     // Brain bounding box at identity-transform (centered) in screen/canvas coords:
     //   left   = screenWidth/2  - 245 * scaleMultiplier   (brain polygon half-width = 245)
     //   bottom = screenHeight/2 + currentImageHeight/2
     final double brainLeft   = screenWidth  / 2.0 - 245.0 * scaleMultiplier;
     final double brainBottom = screenHeight / 2.0 + currentImageHeight / 2.0;

     if (isCameraExpanded) {
        // Expand Camera Mode: Route the brain smoothly to the PIP quadrant
        double targetScale = 0.45;
        targetMatrix.scale(targetScale, targetScale, 1.0);
        
        double scaledNucleusX = (screenWidth / 2.0) * targetScale;
        double scaledNucleusY = (screenHeight / 2.0) * targetScale;

        if (isLandscapeMode) {
            // Landscape: Push brain nucleus to the massive whitespace generated on the Right side 
            double rightOffset = MediaQuery.of(context).padding.right; 
            
            // Re-calculate the actual right edge of the card natively taking bottlenecks into account
            double maxCardW = screenWidth * 0.70;
            double maxCardH = screenHeight * 0.85;
            bool isPhone = MediaQuery.of(context).size.shortestSide < 600;
            double cameraW = maxCardW - 140;
            double cameraH = cameraW * 0.75;
            double uiOverheadHeight = isLandscapeMode ? 30.0 : 80.0;
            
            // Bottleneck test
            if ((cameraH * 1.6 + uiOverheadHeight) > maxCardH) {
                cameraH = (maxCardH - uiOverheadHeight) / 1.6;
                cameraW = cameraH * (4.0 / 3.0);
            }
            double finalCardWidth = cameraW + 148;
            
            double camLeft = isPhone ? (MediaQuery.of(context).padding.left + 85.0) : 90.0;
            double cameraPanelRightEdge = camLeft + finalCardWidth;
            
            double remainingWidth = (screenWidth - rightOffset) - cameraPanelRightEdge;
            double pipCenterX = cameraPanelRightEdge + (remainingWidth / 2.0) + (isPhone ? 0.0 : 20.0);

            // Dynamic logic cleanly centering brain with its exact visual margins mapped bounds
            if (isPhone) {
                targetScale = (remainingWidth - 10) / 490.0; 
                if (targetScale > 0.85) targetScale = 0.85; // Raised standard ceiling drastically
                if (targetScale < 0.10) targetScale = 0.10;
                scaledNucleusX = (screenWidth / 2.0) * targetScale;
                scaledNucleusY = (screenHeight / 2.0) * targetScale;
            } else if (remainingWidth < (490.0 * targetScale + 20)) {
                targetScale = (remainingWidth - 20) / 490.0;
                scaledNucleusX = (screenWidth / 2.0) * targetScale;
                scaledNucleusY = (screenHeight / 2.0) * targetScale;
            }

            double pipCenterY = screenHeight / 2.0; 
            
            deltaX = pipCenterX - scaledNucleusX;
            deltaY = pipCenterY - scaledNucleusY;
        } else {
            // Portrait: Center brain horizontally and drop its Top physically below the unexpanded widgets 
            bool isPhone = MediaQuery.of(context).size.shortestSide < 600;
            double paddingOverhead = (isPhone) ? 20.0 : 60.0; // Pushed right up underneath status bar! 
            double pipCenterX = screenWidth / 2.0; 
            double pipCenterY = MediaQuery.of(context).padding.top + (245.0 * targetScale) + paddingOverhead; 
            
            deltaX = pipCenterX - scaledNucleusX;
            deltaY = pipCenterY - scaledNucleusY;
        }
        
        // Unlock the strict design-mode zoom limits during camera expansion 
        // so the graphical SVGs can faithfully trace the deeply-scaled coordinate matrix!
        controller.minScale = isCameraExpanded ? 0.15 : 0.85;

        // Apply matrix transformation smoothly mapping to the delta vector
        targetMatrix = Matrix4.identity()
          ..translate(deltaX, deltaY)
          ..scale(targetScale, targetScale, 1.0);
          
     } else if (isLandscapeMode) {
       // Landscape: LeftToolbar is a LEFT vertical strip.
       //   Positioned(left: 0, top: 15 + safePaddingTop)
       //   width = kIconSize + safePaddingLeft  (see left_toolbar.dart)
       final double panelRight = kIconSize + safePaddingLeft;
       deltaX = (panelRight + kGap) - brainLeft;

       if (shiftDown) deltaY = 150.0;
     } else {
       // Portrait: LeftToolbar is a BOTTOM horizontal strip.
       //   panel content top = screenHeight - kIconSize - safeBottom
       // iOS: brain can sit much closer to the panel than other platforms.
       final double kPortraitGap = (Platform.isIOS || Platform.isAndroid) ? 8.0 : kGap;
       final double panelContentTop = screenHeight - kIconSize - safeBottom;
       deltaY = (panelContentTop - kPortraitGap) - brainBottom;
       if (deltaY < 0) deltaY = 0;
       if (shiftDown) deltaY += 150.0;
     }

     printDebug("[HomeReset] isCameraExpanded=$isCameraExpanded landscape=$isLandscapeMode brainLeft=$brainLeft brainBottom=$brainBottom "
                "scaleMultiplier=$scaleMultiplier currentImageHeight=$currentImageHeight "
                "screenW=$screenWidth screenH=$screenHeight safeBottom=$safeBottom "
                "deltaX=$deltaX deltaY=$deltaY");

     if (animate) {
       // Only apply the dynamic translate vector for regular modes (isCameraExpanded sets it explicitly earlier to avoid matrix skew!)
       if (!isCameraExpanded) {
           targetMatrix.translate(deltaX, deltaY, 0.0);
       }
       controller.isAnimatingCamera = true;
       // Pause synapse fade so its 60fps ticker doesn't compete with the
       // camera pan on iOS (where frame budget is tighter than macOS).
       // The fade restarts automatically on the next neuron spike.
       synapseFadeController?.stop();
       _canvasAnimation = Matrix4Tween(
         begin: currentMatrix,
         end: targetMatrix,
       ).animate(CurvedAnimation(parent: _canvasAnimController, curve: Curves.easeInOut));
       _canvasAnimController.forward(from: 0).then((_) {
         controller.isAnimatingCamera = false;
         // One-time notification after animation completes:
         // restores nucleus icons (which were hidden during animation)
         // and lets _onControllerChange pick up the state change.
         controller.notifyListeners();
         // Fire optional completion callback (e.g. starting simulation after
         // the camera has fully settled — avoids racing on slow hardware).
         onComplete?.call();
       });
     } else {
       controller.isAnimatingCamera = false;
       targetMatrix.translate(deltaX, deltaY, 0.0);
       controller.transform.value = targetMatrix;
       // WEB FIX: TransformationController.value= notifies InteractiveViewer
       // internally, but does NOT call our onUpdate() setState path.
       // Without this, the canvas widget tree never rebuilds on the first frame
       // (blue screen until click). Force a full rebuild here.
       controller.notifyListeners();
     }
  }

  Widget _buildBehaviorGroupHeader(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 0, top: 1),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade600,
          fontFamily: 'Roboto',
        ),
      ),
    );
  }

  Widget _buildBehaviorOption(String type, String iconPath, {bool isEmoji = false}) {
    bool isSelected = neuronMenuType == type;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () async {
          if (buttonPopSource != null) {
            buttonOnPressedHandle = await soloud?.play(buttonPopSource!, looping: false);
          }
          setState(() {
            neuronMenuType = type;
            isNeuronBehaviorExpanded = false; // Hide menu on select
          });
          if (!isLoadingBrain && !isSettlingAfterLoad) brainHasUnsavedChanges.value = true; // neuron behavior type changed
          neuronTypeChangeCallback(neuronMenuType);
          tecTimeValue.text = sldTimeValue.floor().toString();
          
          try {
            InfiniteCanvasNode selected = controller.selection[0];
            int neuronIdx = -1;
neuronIdx = controller.nodes.map((e) => e.id).toList().indexOf(selected.id) - 2;
            
            if (type == "Delay") {
              isShowDelayTime = true;
              sldTimeValue = 1000;
              tecTimeValue.text = sldTimeValue.floor().toString();
              mapDelayNeuronList[neuronIdx] = sldTimeValue.floor();
            } else if (type == "Custom") {
              isShowDelayTime = false;
              mapDelayNeuronList[neuronIdx] = -1;
            } else {
              isShowDelayTime = false;
              mapDelayNeuronList[neuronIdx] = -1;
            }
          } catch (err) {
            printDebug(err);
          }

          refreshNuclei();
          setState(() {});
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: isSelected ? colorOrange : Colors.transparent,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                height: 38,
                width: 38,
                child: isEmoji 
                    ? FittedBox(fit: BoxFit.contain, child: Text(iconPath, style: TextStyle(fontFamily: "NotoEmoji", color: isSelected ? Colors.white : Colors.black)))
                    : SvgPicture.asset(iconPath, colorFilter: ColorFilter.mode(isSelected ? Colors.white : Colors.black, BlendMode.srcIn)),
              ),
              const SizedBox(height: 0),
              Text(
                type,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  height: 1.1,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? Colors.white : Colors.grey[800],
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
          // rotation: let _animateCanvasToReset animate directly from current position to home
          // (no zoomReset() — that snaps to center causing visible center-flash on iOS)
          isPortrait = false;
          isInitialized = false;
          isReorientation = true;
          prevConstrainedFlag = true;
          prevConstrainedPos = Offset.zero;
        }
      } else if (isPortrait == false) {
        // current screen is not landscape
        if (MediaQuery.of(context).orientation != Orientation.landscape) {
          // rotation: let _animateCanvasToReset animate directly from current position to home
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
    safePaddingLeft = MediaQuery.of(context).padding.left;
    safePaddingTop = MediaQuery.of(context).padding.top;
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
        // FIX: Populate rawSyntheticNeuronList with IO sensors at startup.
        // Without this, the list starts empty on fresh launch (clearBridge is called
        // by loadBrain/New-File but NOT by initCanvas). User-placed neurons then land
        // at index 0 instead of index 13, causing the load fallback to go out-of-bounds
        // → null syntheticConfig → no dendrites on first neuron after fresh-boot save.
        clearBridge();
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
        // Desktop (macOS/Windows): repositionContactNeurons() already rescaled
        // neuron positions using the oldScaleMultiplier→scaleMultiplier ratio.
        // Running the scaleX/scaleY loop here too would double-scale and squish
        // neurons on fullscreen/maximize/resize transitions. Skip it.

        if (isResizingFlag) {
          brainPosition =
              newCameraNodePos + oldDifCoreBrain.scale(scaleX, scaleY);
        }
        // Fix 3: keep brainPosition.dx in sync with the SVG brain's screen-space left edge.
        // This prevents the core brain drop target from drifting relative to the SVG on resize.
        // NOTE: Only sync X here. The Y position is handled directly in getDragTargets()
        // using topInnerWindowSpace (= brainHomeY), matching how peripheral targets work.
        brainPosition = Offset(brainHomeX, brainPosition.dy);
        printDebug("brainPosition synced → $brainPosition (brainHomeX=$brainHomeX brainHomeY=$brainHomeY isResizing=$isResizingFlag)");
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          // This notify is purely for repaint/layout — preserve the current
          // unsaved state so it cannot spuriously mark the brain as dirty.
          final _savedUnsaved = brainHasUnsavedChanges.value;
          controller.notifyListeners();
          brainHasUnsavedChanges.value = _savedUnsaved;
        }
      });

      // Rotation / resize: animate to the new orientation's home position.
      if (isControllerInitialized) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _animateCanvasToReset(
            MediaQuery.of(context).orientation == Orientation.landscape,
            animate: isCameraExpanded, // Snap instantly — brain revealed already in place, unless Expanded where scaling demands continuous tweening offsets
          );
        });
      }

      centerZoneOffset = Offset(currentImageWidth / 2 + neuronDrawSize,
          currentImageHeight / 3 + neuronDrawSize);
      // printDebug("centerZoneOffset");
      // printDebug(centerZoneOffset);

      if (!kIsWeb) {
        WaveWidget.positionsBufView = positionsBufView;
      }
      if (currentWaveNeuronIdx == -1 && currentWaveNeuronIdx2 == -1) {
        waveWidget = Container(
            color: const Color(0xFF222222),
            child: const Center(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: Text(
                  "Drag a pin onto a neuron to see its activity realtime!",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: "Roboto",
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ));
      } else {
        waveWidget = WaveWidget(
            key: ValueKey("${currentWaveNeuronIdx}_$currentWaveNeuronIdx2"), // Force Rebuild on Change
            valueNotifier: waveRedraw,
            chartGain: chartGain,
            screenWidth: 300,
            screenHeight: 90,
            neuronIdx1: currentWaveNeuronIdx, // Pass Orange Pin Index
            neuronIdx2: currentWaveNeuronIdx2, // Pass Blue Pin Index
            initialVisibleSeconds: currentWaveZoom, // Persist Zoom
            onVisibleSecondsChanged: (seconds) {
              currentWaveZoom = seconds;
            },
            levelMedian: levelMedian);
      }
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
        protoNeuron!.generateCircle(
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
      try {
        for (int i = 0; i < normalNeuronStartIdx; i++) {
          // Dead loop: migrated to Nucleus widget framework
          // Kept empty to preserve structural parity if needed later
        }
      } catch (e) {
        // Suppress LateInitializationError while waiting 500ms for runSimulation()
      }
      // OFFSET FIX: Use Matrix Translation directly for robust Screen positioning
      var tVec = controller.matrix.getTranslation();
      double s = controller.getScale();
      
      // RESTORED Original Overlay Logic with Pin Features
      for (int i = normalNeuronStartIdx; i < neuronSize; i++) {
        // Use Node Offset directly to avoid ProtoNeuron drift
        Offset nodePos = controller.nodes[i + 2].offset;

        bool isPinned = placedPins.containsKey(i);
        
        // 1. Placed Pin (Visible if Pinned)
        if (isPinned) {
            int pinType = placedPins[i]!;
            widgets.add(Positioned(
               key: ValueKey("pin_placed_$i"),
               top: 0,
               left: 0,
               child: AnimatedBuilder(
                 animation: controller.transform,
                 builder: (context, child) {
                   var tVec = controller.matrix.getTranslation();
                   double s = controller.getScale();
                   // ALIGNMENT FIX: Dynamic Centering for Constant Size Pin
                   // node.offset is TOP-LEFT.
                   // Pin Layout Size: 64 (Radius 32).
                   // Neuron Size: 20*s (Radius 10*s).
                   // We align PinCenter to NeuronCenter.
                   // PinCenter = PinTopLeft + 32.
                   // NeuronCenter = NeuronTopLeft + 10*s.
                   // PinTopLeft = (nodePos * s) + tVec + (10 * s) - 32.
                   double topOffset = (nodePos.dy * s) + tVec.y + (10 * s) - 32;
                   double leftOffset = (nodePos.dx * s) + tVec.x + (10 * s) - 32;
                   
                   return Transform.translate(
                     offset: Offset(leftOffset, topOffset),
                     child: child,
                   );
                 },
                 child: IgnorePointer(
                     child: Transform.scale(
                       scale: 2.0, 
                       child: SvgPicture.asset(
                         (pinType == 10) ? "assets/icons/DragmenuPin1Placed.svg" : "assets/icons/DragmenuPin2Placed.svg",
                         width: 64, // Constant size
                       ),
                     )
                 )
               )
            ));
        }

        // 2. DragTarget (Visible & Interactive if NOT Pinned)
        if (!isPinned) {
           // V25 FEATURE: Dynamic DragTarget Hitbox Inflation for Live Pins
           // If a pin is actively held over this specific neuron, we bloat the hitbox by 60px 
           // to perfectly match the massive visual 1.5x expansion of the animated backend.
           // If no pin is hovering, we still give it a generous +40px magnetism to make dropping easy.
           bool isHovering = (hoveringPinNeuronIdx == i);
           double expansionDelta = isHovering ? 60.0 : 40.0;
           
           widgets.add(Positioned(
              key: ValueKey("live_dt_$i"),
              top: 0,
              left: 0,
              child: AnimatedBuilder(
                animation: controller.transform,
                builder: (context, child) {
                  var tVec = controller.matrix.getTranslation();
                  double s = controller.getScale();
                  // Apply Robust Math (Top-Left aligned) + Centered Expansion Offset
                  double topOffset = (nodePos.dy * s) + tVec.y - (expansionDelta / 2.0);
                  double leftOffset = (nodePos.dx * s) + tVec.x - (expansionDelta / 2.0);
                  
                  return Transform.translate(
                    offset: Offset(leftOffset, topOffset),
                    child: child,
                  );
                },
                child: GestureDetector(
                 behavior: HitTestBehavior.translucent,
                 onTap: () {
                     // Disable Tap Selection in Live Mode (User Request)
                     if (isPlayingMenu) return;

                     // ── Annotation Mode: tap-to-toggle neuron selection ──
                     if (isAnnotationMode) {
                       // Block selection changes in view-only mode
                       if (!_annotationEditEnabled) return;
                       if ((i + 2) < controller.nodes.length) {
                         final nodeKey = controller.nodes[i + 2].key.toString();
                         setState(() {
                           if (controller.annotationHighlightNodeKeys.contains(nodeKey)) {
                             controller.annotationHighlightNodeKeys.remove(nodeKey);
                           } else {
                             controller.annotationHighlightNodeKeys.add(nodeKey);
                           }
                         });
                         controller.notifyListeners(); // repaint canvas
                       }
                       return; // don't run normal design-mode logic
                     }

                     // Normal design-mode selection:
                     nativec.changeIdxSelected(i);
                     controller.deselectAll();
                     if ((i + 2) < controller.nodes.length) {
                         controller.setSelection({controller.nodes[i + 2].key});
                         isChartSelected = true;
                         setState(() {});
                     }
                 },
                 child: DragTarget(
                     hitTestBehavior: HitTestBehavior.translucent,
                     onWillAccept: (data) => (data is int && data >= 10),
                     onMove: (details) {
                         if (details.data is int && (details.data as int) >= 10) {
                             if (hoveringPinNeuronIdx != i) {
                                 setState(() {
                                    hoveringPinNeuronIdx = i;
                                    initializeNucleus(); // Trigger Scale Update
                                 });
                                 if (soloud != null && neuronOnTouchSource != null) {
                                    soloud?.play(neuronOnTouchSource!);
                                 }
                             }
                         }
                     },
                     onLeave: (_) {
                         if (hoveringPinNeuronIdx == i) {
                             setState(() {
                                hoveringPinNeuronIdx = -1;
                                mapBg["activeComponent"] = noActiveComponent;
                                initializeNucleus(); // Trigger Scale Reset
                             });
                         }
                     },
                     onAccept: (data) async {
                         print("DEBUG: DragTarget onAccept! Data: $data"); // DEBUG PRINT
                         
                         if (data is int && data >= 10) {
                             // Pin 1 Logic: Select for Plot
                             if (data == 10) {
                                 print("DEBUG: PIN 1 DROPPED on index $i");
                                 
                                 // Use Controller Selection to trigger existing robust listener
                                 // This matches 'Tap' behavior exactly (Orange Selection + Clean Plot Update)
                                 controller.deselectAll();
                                 if ((i + 2) < controller.nodes.length) {
                                     controller.setSelection({controller.nodes[i + 2].key});
                                     isChartSelected = true;
                                 }
                                 
                                 // nativec.changeIdxSelected(i); // Handled by listener
                                 // currentWaveNeuronIdx = i;     // Handled by listener
                             } else if (data == 11) {
                                  // Pin 2 (Blue) Logic
                                  print("DEBUG: PIN 2 DROPPED on index $i");
                                  nativec.changeIdxSelected2(i);
                                  currentWaveNeuronIdx2 = i;
                                  // Force Plot Rebuild
                                  waveWidget = WaveWidget(
                                      key: ValueKey("${currentWaveNeuronIdx}_$currentWaveNeuronIdx2"),
                                      valueNotifier: waveRedraw,
                                      chartGain: chartGain,
                                      screenWidth: 300,
                                      screenHeight: 90,
                                      neuronIdx1: currentWaveNeuronIdx,
                                      neuronIdx2: currentWaveNeuronIdx2,
                                      initialVisibleSeconds: currentWaveZoom,
                                      onVisibleSecondsChanged: (s) => currentWaveZoom = s,
                                      levelMedian: levelMedian);
                             }

                             setState(() {
                                 hoveringPinNeuronIdx = -1;
                                 placedPins.removeWhere((k, v) => v == (data as int));
                                 placedPins[i] = data;
                                 mapBg["activeComponent"] = noActiveComponent;
                                 mapBg["activeBg"] = defaultBg;
                                 initializeNucleus();
                             });
                             // Safety Reset delayed
                             Future.delayed(const Duration(milliseconds: 50), () {
                                if (mounted) {
                                   setState(() {
                                      mapBg["activeComponent"] = noActiveComponent;
                                      mapBg["activeBg"] = defaultBg;
                                      initializeNucleus(); // Safety Trigger
                                   });
                                }
                             });
                             
                             if (soloud != null && objectPlacedSource != null) {
                                soloud?.play(objectPlacedSource!);
                             }
                         }
                     },
                     builder: (_,__,___) => SizedBox(
                        width: (neuronDrawSize * s) + expansionDelta,
                        height: (neuronDrawSize * s) + expansionDelta
                     )
                 )
                )
              )
           ));
        }
      }
      // */
    }
    // mainBody = Text(
    //   // String.fromCharCode(0x1F48E),
    //   String.fromCharCode(0x1F9E0),
    //   style: const TextStyle(fontFamily: "BybHanddrawn"),
    // );
    mainBody = (!isInitialized)
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
                      mapBg["activeComponent"]!),
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
                      fit: BoxFit.contain,
                      mapBg["activeBg"]!),
                );
              },
              drawVisibleOnly: false,
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
        //   right: (Platform.isIOS && safePadding > 0 ? safePadding : 17 + safePadding),
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


      } else {
        /*
        inlineWidgets.add(Positioned(
          // bottom: MediaQuery.of(context).size.height / 2 - 130,
          bottom: 20,
          right: (Platform.isIOS && safePadding > 0 ? safePadding : 17 + safePadding),
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
        //   right: (Platform.isIOS && safePadding > 0 ? safePadding : 17 + safePadding),
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

      }
    }

    if (!isPlayingMenu && !isAnnotationMode && isNeuronMenu && controller.hasSelection) {
      inlineWidgets.add(
        Positioned(
            top: safePaddingTop,
            right: (Platform.isIOS && safePadding > 0 ? safePadding : 20 + safePadding),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 7, 8, 3),
                child: SizedBox(
                  width: 340,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.only(top: 0, bottom: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Text(
                            "Tune Neuron Behavior",
                            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            "Select how this neuron sends spikes:",
                            style: TextStyle(fontSize: 13, color: Colors.black),
                          ),
                          const SizedBox(height: 8),
                          if (!isNeuronBehaviorExpanded)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Material(
                                  elevation: 2,
                                  borderRadius: BorderRadius.circular(20),
                                  color: Colors.white,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(20),
                                    onTap: () async {
                                      if (buttonOnPressedSource != null) {
                                        buttonOnPressedHandle = await soloud?.play(
                                            buttonOnPressedSource!,
                                            looping: false);
                                      }
                                      setState(() {
                                        isNeuronBehaviorExpanded = true;
                                      });
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            neuronMenuType,
                                            style: const TextStyle(fontWeight: FontWeight.bold),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(width: 8),
                                          const Icon(
                                            Icons.arrow_drop_down,
                                            size: 20,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                 GestureDetector(
                                   onTapDown: (_) async {
                                     setState(() => _testInputPressed = true);
                                     embeddedPlotKey.currentState?.triggerInput();
                                     if (soloud != null && buttonOnPressedSource != null) {
                                       soloud?.play(buttonOnPressedSource!, looping: false);
                                     }
                                   },
                                   onTapUp: (_) async {
                                     setState(() => _testInputPressed = false);
                                     if (soloud != null && buttonPopSource != null) {
                                       soloud?.play(buttonPopSource!, looping: false);
                                     }
                                   },
                                   onTapCancel: () {
                                     setState(() => _testInputPressed = false);
                                   },
                                   child: AnimatedContainer(
                                     duration: const Duration(milliseconds: 80),
                                     padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                                     decoration: BoxDecoration(
                                       color: _testInputPressed
                                           ? const Color(0xFF0E7ACC)
                                           : const Color(0xFF1996FC),
                                       borderRadius: BorderRadius.circular(24),
                                     ),
                                     child: Row(
                                       mainAxisSize: MainAxisSize.min,
                                       children: [
                                         SvgPicture.asset('assets/icons/Bolt.svg', width: 16, height: 16, colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn)),
                                         SizedBox(width: 5),
                                         Text(!kIsWeb && Platform.isIOS ? 'Test' : 'Test Input', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                                       ],
                                     ),
                                   ),
                                 )
                              ],
                            ),
                          if (!isNeuronBehaviorExpanded) ...[
                            const SizedBox(height: 8),
                            Builder(builder: (context) {
                              String desc = "";
                              switch(neuronMenuType) {
                                case "Quiet": desc = "Only sends a single SPIKE whenever it receives enough input"; break;
                                case "Bursts when activated": desc = "Only sends a strong burst of SPIKES whenever it receives enough input."; break;
                                case "Occassionally active": desc = "Sends single SPIKES at random every so often without the need for input. Still SPIKES with input too!"; break;
                                case "Generates bursts": desc = "Sends giant bursts of SPIKES on and off at random, just like a random sensor input"; break;
                                case "Highly active": desc = "Sends constant SPIKES all the time without input. You can stop it with inhibitory SPIKES!"; break;
                                case "Delay": desc = "When it gets a strong enough input, this NEURON waits before sending SPIKES!"; break;
                                case "Remote Control": desc = "Waits for an input to SPIKE. Trigger it with neurons, or keypresses/buttons!"; break;
                                case "Custom": desc = "Adjust the parameters of the Izhikevich integrate and fire model directly!"; break;
                                case "Motion": desc = "Responds to TAP, TILT, or MOVEMENT detected by the robot's motion sensor!"; break;
                                case "Aux Motor": desc = "Advanced: Used for controlling auxiliary servos and expansion motors."; break;
                              }
                              if (isShowingInfo != 0) {
                                return Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      padding: const EdgeInsets.all(0),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 2),
                                        color: Colors.white,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.grey.withOpacity(0.5),
                                            spreadRadius: 0.3,
                                            blurRadius: 0.3,
                                            offset: const Offset(1, 1), 
                                          ),
                                        ],
                                      ),
                                      child: SvgPicture.asset("assets/icons/Info.svg"),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: BybHighlightedText(
                                        desc,
                                        fontSize: 16,
                                        maxLines: null,
                                      ),
                                    ),
                                  ],
                                );
                              } else {
                                return const SizedBox.shrink();
                              }
                            }),
                            const SizedBox(height: 12),
                            EmbeddedNeuronPlotWidget(
                              key: embeddedPlotKey,
                              neuronTypeLabel: neuronMenuType,
                              a: sldAWeight,
                              b: sldBWeight,
                              c: sldCWeight,
                              d: sldDWeight,
                              delayMs: sldTimeValue.round(),
                              boundKey: controller.selection.isNotEmpty ? mapRemoteControlNeuron[controller.selection.first.id] : null,
                              onSpike: handleEmbeddedSpike,
                            ),
                          ],
                          if (isNeuronBehaviorExpanded) ...[
                            const SizedBox(height: 2),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  _buildBehaviorGroupHeader("Needs an input to send spikes:"),
                                  GridView.count(
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    crossAxisCount: 4,
                                    mainAxisSpacing: 2,
                                    crossAxisSpacing: 2,
                                    childAspectRatio: 1.15,
                                    children: [
                                      _buildBehaviorOption("Quiet", "💤", isEmoji: true),
                                      _buildBehaviorOption("Bursts when activated", "⚡", isEmoji: true),
                                      _buildBehaviorOption("Delay", "🕧", isEmoji: true),
                                      _buildBehaviorOption("Remote Control", "assets/icons/remoteControlKeys/RemoteControl.svg"),
                                    ],
                                  ),
                                  const Divider(height: 1),
                                  _buildBehaviorGroupHeader("Sends spikes on its own without input:"),
                                  GridView.count(
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    crossAxisCount: 4,
                                    mainAxisSpacing: 2,
                                    crossAxisSpacing: 2,
                                    childAspectRatio: 1.15,
                                    children: [
                                      _buildBehaviorOption("Occassionally active", "✨", isEmoji: true),
                                      _buildBehaviorOption("Generates bursts", "⛈️", isEmoji: true),
                                      _buildBehaviorOption("Highly active", "🔥", isEmoji: true),
                                    ],
                                  ),
                                  const Divider(height: 1),
                                  _buildBehaviorGroupHeader("Advanced neurons:"),
                                  GridView.count(
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    crossAxisCount: 4,
                                    mainAxisSpacing: 2,
                                    crossAxisSpacing: 2,
                                    childAspectRatio: 1.15,
                                    children: [
                                      _buildBehaviorOption("Custom", "assets/icons/tune.svg"),
                                      _buildBehaviorOption("Motion", "🤖", isEmoji: true),
                                      _buildBehaviorOption("Aux Motor", "⚙️", isEmoji: true),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (neuronMenuType == "Custom") ...[
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0, bottom: 16.0, left: 8.0, right: 8.0),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                RadialDialWidget(
                                  title: "A value:",
                                  value: sldAWeight,
                                  min: 0,
                                  max: 0.15,
                                  dialSize: 65,
                                  widgetWidth: 125,
                                  startAngleOffset: pi,
                                  onChanged: (value) async {
                                    value = (value * 100).round() / 100;
                                    sldAWeight = value;
                                    tecAWeight.text = value.toString();
                                    resizeIzhikevichParameters(neuronSize);
                                    InfiniteCanvasNode selected = controller.selection[0];
                                    int neuronIdx = -1;
neuronIdx = controller.nodes.map((e) => e.id).toList().indexOf(selected.id) - 2;
                                    aDesignArray[selected.id] = sldAWeight;
                                    aBufView[neuronIdx] = sldAWeight;
                                    if (!isLoadingBrain && !isSettlingAfterLoad) brainHasUnsavedChanges.value = true;
                                    setState(() {});
                                  },
                                  onSubmitted: submitWeightA,
                                ),
                                RadialDialWidget(
                                  title: "B value:",
                                  value: sldBWeight,
                                  min: 0,
                                  max: 0.5,
                                  dialSize: 65,
                                  widgetWidth: 125,
                                  startAngleOffset: pi,
                                  onChanged: (value) async {
                                    value = (value * 100).round() / 100;
                                    sldBWeight = value;
                                    tecBWeight.text = value.toString();
                                    resizeIzhikevichParameters(neuronSize);
                                    InfiniteCanvasNode selected = controller.selection[0];
                                    int neuronIdx = -1;
neuronIdx = controller.nodes.map((e) => e.id).toList().indexOf(selected.id) - 2;
                                    bDesignArray[selected.id] = sldBWeight;
                                    bBufView[neuronIdx] = sldBWeight;
                                    if (!isLoadingBrain && !isSettlingAfterLoad) brainHasUnsavedChanges.value = true;
                                    setState(() {});
                                  },
                                  onSubmitted: submitWeightB,
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                RadialDialWidget(
                                  title: "C value:",
                                  value: sldCWeight,
                                  min: -80,
                                  max: -30,
                                  dialSize: 65,
                                  widgetWidth: 125,
                                  startAngleOffset: pi,
                                  onChanged: (value) async {
                                    value = value.roundToDouble();
                                    sldCWeight = value;
                                    tecCWeight.text = value.round().toString();
                                    resizeIzhikevichParameters(neuronSize);
                                    InfiniteCanvasNode selected = controller.selection[0];
                                    int neuronIdx = -1;
neuronIdx = controller.nodes.map((e) => e.id).toList().indexOf(selected.id) - 2;
                                    cDesignArray[selected.id] = sldCWeight.floor();
                                    cBufView[neuronIdx] = sldCWeight.floor();
                                    if (!isLoadingBrain && !isSettlingAfterLoad) brainHasUnsavedChanges.value = true;
                                    setState(() {});
                                  },
                                  onSubmitted: submitWeightC,
                                ),
                                RadialDialWidget(
                                  title: "D value:",
                                  value: sldDWeight,
                                  min: 0,
                                  max: 10,
                                  dialSize: 65,
                                  widgetWidth: 125,
                                  startAngleOffset: pi,
                                  onChanged: (value) async {
                                    value = value.roundToDouble();
                                    sldDWeight = value;
                                    tecDWeight.text = value.round().toString();
                                    resizeIzhikevichParameters(neuronSize);
                                    InfiniteCanvasNode selected = controller.selection[0];
                                    int neuronIdx = -1;
neuronIdx = controller.nodes.map((e) => e.id).toList().indexOf(selected.id) - 2;
                                    dDesignArray[selected.id] = sldDWeight.floor();
                                    dBufView[neuronIdx] = sldDWeight.floor();
                                    if (!isLoadingBrain && !isSettlingAfterLoad) brainHasUnsavedChanges.value = true;
                                    setState(() {});
                                  },
                                  onSubmitted: submitWeightD,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (isShowDelayTime) ...[
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0, bottom: 16.0),
                        child: Center(
                          child: RadialDialWidget(
                            title: "Delay Time:",
                            value: sldTimeValue,
                            min: minDelayTimeValue.toDouble(),
                            max: maxDelayTimeValue.toDouble(),
                            renderMin: 0,
                            isTimeFormatter: true,
                            dialSize: 84,
                            widgetWidth: 210,
                            onChanged: (value) async {
                              try {
                                sldTimeValue = ((value / 100).floor() * 100).floor().roundToDouble();
                                tecTimeValue.text = sldTimeValue.round().toString();

                                InfiniteCanvasNode selected = controller.selection[0];
                                int neuronIdx = -1;
neuronIdx = controller.nodes.map((e) => e.id).toList().indexOf(selected.id) - 2;

                                mapDelayNeuronList[neuronIdx] = sldTimeValue.floor();
                                if (neuronIdx < mapDelayNeuronBufView.length) {
                                    mapDelayNeuronBufView[neuronIdx] = sldTimeValue.floor();
                                }
                                if (neuronIdx >= 0 && neuronIdx < neuronSpikeFlags.length) {
                                  neuronSpikeFlags[neuronIdx].value = neuronSpikeFlags[neuronIdx].value == 0 ? 1 : 0;
                                }
                              } catch (err) {}
                              if (!isLoadingBrain && !isSettlingAfterLoad) brainHasUnsavedChanges.value = true; // delay time changed
                              setState(() {});
                            },
                          ),
                        ),
                      ),
                    ],
                    if (neuronMenuType == "Remote Control") ...[
                      Padding(
                        padding: const EdgeInsets.only(top: 16, bottom: 8),
                        child: Center(
                          child: Text(
                            "Select an input for remote control:",
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 0, bottom: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (_remoteControlBoundKeyLabel.isEmpty)
                                const Text("No input set", style: TextStyle(fontSize: 13, color: Colors.black, fontWeight: FontWeight.bold))
                            else 
                                const Text("Input set", style: TextStyle(fontSize: 13, color: Colors.black, fontWeight: FontWeight.bold)),
                            const SizedBox(width: 16),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _isListeningForRemoteInput
                                    ? Colors.yellow[700]
                                    : colorOrange,
                              ),
                              onPressed: () {
                                _toggleRemoteInputListening();
                              },
                              onLongPress: () {
                                _toggleInputDebug();
                              },
                              child: Text(
                                _isListeningForRemoteInput
                                    ? "Press any key..."
                                    : "Listen for input",
                                style: TextStyle(color: _isListeningForRemoteInput ? Colors.black : Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (neuronMenuType == "Motion") ...[
                      Padding(
                        padding: const EdgeInsets.only(top: 16, bottom: 8),
                        child: Center(
                          child: Text(
                            "Select a motion input:",
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 0, bottom: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildMotionRadio("Tap", "👆"),
                            const SizedBox(width: 12),
                            _buildMotionRadio("Tilt", "📐"),
                            const SizedBox(width: 12),
                            _buildMotionRadio("Motion", "🏃"),
                          ],
                        ),
                      ),
                    ],
                    if (neuronMenuType == "Aux Motor") ...[
                      // ── Slider 1: Triggered Speed / Angle ──
                      ClipRect(
                        clipBehavior: Clip.none,
                        child: Transform.translate(
                          offset: const Offset(0, -10),
                          child: Center(
                            child: SizedBox(
                              width: 240,
                              height: 105,
                              child: ArcSliderWidget(
                                title: "",
                                lowerTitle: null,
                                value: mapAuxMotorPower[controller.selection[0].id] ?? 255.0,
                                widgetWidth: 240.0,
                                min: -255,
                                max: 255,
                                isPercentageFormatter: false,
                                isDegreeFormatter: false,
                                onChanged: (value) async {
                                  if (!isLoadingBrain && !isSettlingAfterLoad) brainHasUnsavedChanges.value = true;
                                  mapAuxMotorPower[controller.selection[0].id] = value;
                                  setState(() {});
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                      Transform.translate(
                        offset: const Offset(0, -6),
                        child: const Center(
                          child: Text("Triggered Speed / Angle",
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ),
                      ),
                      // ── Slider 2: Resting Position (Global) ──
                      ClipRect(
                        clipBehavior: Clip.none,
                        child: Transform.translate(
                          offset: const Offset(0, -20),
                          child: Center(
                            child: SizedBox(
                              width: 240,
                              height: 105,
                              child: ArcSliderWidget(
                                title: "",
                                lowerTitle: null,
                                value: auxServoRestPosition,
                                widgetWidth: 240.0,
                                min: -255,
                                max: 255,
                                isPercentageFormatter: false,
                                isDegreeFormatter: false,
                                onChanged: (value) async {
                                  if (!isLoadingBrain && !isSettlingAfterLoad) brainHasUnsavedChanges.value = true;
                                  auxServoRestPosition = value;
                                  setState(() {});
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                      Transform.translate(
                        offset: const Offset(0, -16),
                        child: const Center(
                          child: Text("Resting Position (Global)",
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ),
                      ),
                    ],
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0, right: 8.0),
                      child: GestureDetector(
                        onTap: () {
                          bool isExcitatory = neuronStyle != "Excitatory";
                          String value = isExcitatory ? "Excitatory" : "Inhibitory";
                          neuronStyle = value;
                          if (neuronMenuType == "Custom") {
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
                              selected.isExcitatory = 1;
                            } else {
                              isTailType = "circle";
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
                          } catch (err) {}

                          if (!isLoadingBrain && !isSettlingAfterLoad) brainHasUnsavedChanges.value = true; // excitatory/inhibitory toggled
                          refreshNuclei();
                          setState(() {});
                        },
                        child: Row(
                          mainAxisAlignment: isShowingInfo != 0 ? MainAxisAlignment.spaceBetween : MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Builder(builder: (context) {
                              bool isExcitatoryState = neuronStyle == "Excitatory";
                              
                              Widget buildInner(Color symbolColor) {
                                if (neuronMenuType == "Delay") {
                                  const List<String> clockEmojis = ["🕧", "🕐", "🕜", "🕑", "🕝", "🕒", "🕞", "🕓", "🕟", "🕔", "🕠", "🕕", "🕡", "🕖", "🕢", "🕗", "🕣", "🕘", "🕤", "🕙", "🕥", "🕚", "🕦", "🕛", "🕧"];
                                  int delayMs = 100;
                                  try {
                                    if (controller.selection.isNotEmpty) {
                                      int delayNodeIdx = -1;
                                      for (int i = 0; i < controller.syntheticNeuronList.length; i++) {
                                        if (controller.syntheticNeuronList[i].node?.id == controller.selection[0].id) {
                                          delayNodeIdx = i;
                                          break;
                                        }
                                      }
                                      if (delayNodeIdx >= 0 && delayNodeIdx < mapDelayNeuronList.length) {
                                        delayMs = mapDelayNeuronList[delayNodeIdx];
                                      }
                                    }
                                  } catch (_) {}
                                  if (delayMs < 100) delayMs = 100;
                                  int clockIdx = ((delayMs - 100) ~/ 100).clamp(0, 24);
                                  return Transform.scale(
                                    scale: isExcitatoryState ? 1.15 : 1.25,
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: FittedBox(
                                        fit: BoxFit.contain,
                                        child: Text(
                                          clockEmojis[clockIdx],
                                          textAlign: TextAlign.center,
                                          style: TextStyle(fontFamily: "NotoEmoji", color: symbolColor),
                                        ),
                                      ),
                                    ),
                                  );
                                } else if (neuronMenuType == "Remote Control") {
                                  InfiniteCanvasNode? selectedNode;
                                  if (controller.selection.isNotEmpty) selectedNode = controller.selection[0];
                                  return RemoteControlKeycap(
                                    node: selectedNode,
                                    fallbackKeyName: (selectedNode != null ? mapRemoteControlNeuron[selectedNode.id] : "") ?? "",
                                    isExcitatory: isExcitatoryState,
                                    size: 24,
                                    transparentBackground: true,
                                    remoteControlMap: mapRemoteControlNeuron,
                                    overrideColor: symbolColor,
                                  );
                                } else {
                                  double baseW = 10;
                                  double baseH = 10;
                                  double dx = 16;
                                  double dy = 16;
                                  try {
                                    if (controller.selection.isNotEmpty) {
                                        int neuronIdx = -1;
neuronIdx = controller.nodes.map((e) => e.id).toList().indexOf(controller.selection[0].id) - 2;
                                        if (neuronIdx >= 0 && neuronIdx < controller.syntheticNeuronList.length) {
                                            var sn = controller.syntheticNeuronList[neuronIdx];
                                            double scale = 32 / neuronDrawSize;
                                            baseW = sn.newNeuron.widthNucleus * scale;
                                            baseH = sn.newNeuron.heightNucleus * scale;
                                            dx = sn.newNeuron.xNucleus * scale;
                                            dy = sn.newNeuron.yNucleus * scale;
                                        }
                                    }
                                  } catch (_) {}
                                  
                                  return Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      Positioned(
                                        left: dx - baseW/2,
                                        top: dy - baseH/2,
                                        width: baseW,
                                        height: baseH,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.all(Radius.elliptical(baseW, baseH)),
                                            color: symbolColor,
                                          ),
                                        ),
                                      )
                                    ]
                                  );
                                }
                              }

                              return Container(
                                width: 140,
                                height: 36,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(18),
                                  color: isExcitatoryState ? colorGreen : colorRed,
                                ),
                                child: Stack(
                                  children: [
                                    AnimatedPositioned(
                                      duration: const Duration(milliseconds: 200),
                                      curve: Curves.easeInOut,
                                      top: 0,
                                      bottom: 0,
                                      left: isExcitatoryState ? 12 : 44,
                                      child: Center(
                                        child: Text(
                                          neuronStyle,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: isExcitatoryState ? Colors.black : Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                    AnimatedPositioned(
                                      duration: const Duration(milliseconds: 200),
                                      curve: Curves.easeInOut,
                                      top: 2,
                                      left: isExcitatoryState ? 106 : 2,
                                      width: 32,
                                      height: 32,
                                      child: Stack(
                                        children: [
                                          Builder(
                                            builder: (context) {
                                                int selectedIdx = -1;
                                                if (controller.selection.isNotEmpty) {
                                                    selectedIdx = controller.nodes.indexWhere((e) => e.id == controller.selection[0].id) - 2;
                                                }
                                                if (selectedIdx >= 0 && selectedIdx < neuronSpikeFlags.length) {
                                                    return ValueListenableBuilder<int>(
                                                        valueListenable: neuronSpikeFlags[selectedIdx],
                                                        builder: (context, val, child) {
                                                            Color spikeColor = isExcitatoryState ? const Color(0xFF00FF00) : Colors.red;
                                                            Color baseSymbolColor = isExcitatoryState ? Colors.white : Colors.black;
                                                            
                                                            int lastSpike = 0;
                                                            if (controller.nucleusList != null && selectedIdx < controller.nucleusList!.length) {
                                                                lastSpike = controller.nucleusList![selectedIdx].lastSpikeTime;
                                                            }
                                                            
                                                            return TweenAnimationBuilder<Color?>(
                                                                key: ValueKey(lastSpike),
                                                                tween: ColorTween(begin: spikeColor, end: baseSymbolColor),
                                                                duration: const Duration(milliseconds: 750),
                                                                builder: (context, animColor, child) {
                                                                    return Container(
                                                                        width: 32, height: 32,
                                                                        decoration: BoxDecoration(shape: BoxShape.circle, color: isExcitatoryState ? Colors.black : Colors.white),
                                                                        child: buildInner(animColor ?? baseSymbolColor),
                                                                    );
                                                                }
                                                            );
                                                        }
                                                    );
                                                }
                                                return Container(
                                                    width: 32,
                                                    height: 32,
                                                    decoration: BoxDecoration(
                                                      shape: BoxShape.circle,
                                                      color: isExcitatoryState ? Colors.black : Colors.white,
                                                    ),
                                                    child: buildInner(isExcitatoryState ? Colors.white : Colors.black),
                                                );
                                            }
                                          ),
                                          if (!isExcitatoryState)
                                            Container(
                                              width: 32,
                                              height: 32,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                border: Border.all(color: Colors.black, width: 2),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),

                            if (isShowingInfo != 0) ...[
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  neuronStyle == "Excitatory" ? "Makes other neurons\nspike!" : "Makes other neurons\nstop spiking.",
                                  style: const TextStyle(
                                    fontFamily: "Roboto",
                                    fontSize: 14.5,
                                    color: Colors.black87,
                                    height: 1.2,
                                  ),
                                  maxLines: 2,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (isShowingInfo == 2) ...[
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4, right: 8),
                        child: Text(
                          "Neuron${controller.selection[0].id}",
                          textAlign: TextAlign.end,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ), // Column
              ), // SizedBox
            ), // Padding
          ), // Card
        ), // Positioned
      ); // inlineWidgets.add
    } else if (!isPlayingMenu && !isAnnotationMode && isCameraMenu && controller.isSelectingEdge) {
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
        return selectedCameraPosition == region
            ? const Color(0xFFF0AB91)
            : Colors.white;
      }).toList();
      List<Color> cameraButtonFgColors = cameraRegions.map((region) {
        return selectedCameraPosition == region ? Colors.black : Colors.grey;
      }).toList();

      if (!isSelectingCameraTarget) {
        InfiniteCanvasNode selected =
            findNeuronByKey(controller.edgeSelected!.to);
        int idx = neuronTypes.keys.toList().indexOf(selected.id);

        inlineWidgets.add(
          Positioned(
              right: (Platform.isIOS && safePadding > 0 ? safePadding : 20 + safePadding),
              top: safePaddingTop,
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
                      const SizedBox(height: 8),
                      isShowingInfo == 1
                          ? Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                    color: Colors.white,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.grey.withOpacity(0.5),
                                        spreadRadius: 0.3,
                                        blurRadius: 0.3,
                                        offset: const Offset(1, 1), 
                                      ),
                                    ],
                                  ),
                                  child: SvgPicture.asset("assets/icons/Info.svg"),
                                ),
                                const SizedBox(width: 10),
                                SizedBox(
                                  width: 300,
                                  child: Builder(builder: (context) {
                                    String targetRaw = selectedEyeInfo["label"] ?? "person";
                                    String prefix = targetRaw.toLowerCase().startsWith("color") ? "" : "a ";
                                    String tName = "$prefix$targetRaw";
                                    
                                    String t;
                                    if (selectedCameraPosition == "Left") {
                                       t = "NEURON will SPIKE when $tName is in the left half of the Spikerbot's vision.";
                                    } else if (selectedCameraPosition == "Right") {
                                       t = "NEURON will SPIKE when $tName is in the right half of the Spikerbot's vision.";
                                    } else if (selectedCameraPosition == "Custom") {
                                       t = "NEURON will SPIKE whenever Spikerbot sees $tName in the area of its field of view.";
                                    } else {
                                       t = "NEURON will SPIKE whenever Spikerbot sees $tName.";
                                    }
                                    return BybHighlightedText(
                                      t,
                                      fontSize: 16,
                                      maxLines: 3,
                                    );
                                  }),
                                ),
                              ],
                            )
                          : const SizedBox(),
                      const SizedBox(height: 8),

                      Builder(builder: (context) {
                          double minArea = areaSizeMinLimitBufView[idx].toDouble();
                          double maxArea = areaSizeMaxLimitBufView[idx].toDouble();
                          
                          if (selectedCameraPosition == "Left") {
                             minArea = 1; maxArea = 160; 
                          } else if (selectedCameraPosition == "Any") {
                             minArea = 1; maxArea = 320;
                          } else if (selectedCameraPosition == "Right") {
                             minArea = 161; maxArea = 320;
                          }

                          double fraction = (((minArea + maxArea) / 2) - 1) / 319.0;
                          double xNormal = fraction * 2 - 1; // -1 to 1
                          double yFraction = 0.35 + 0.25 * (xNormal * xNormal); // Shifted down 10px

                          return SizedBox(
                              width: 330,
                              height: selectedCameraPosition == "Custom" ? 240 : 190, // Dynamically expands the hit bounds so the slider is natively embedded and interactable!
                              child: Stack(
                                  alignment: Alignment.topCenter,
                                  clipBehavior: Clip.none, // Fix marker clipping on the bounds
                                  children: [
                                      Positioned(
                                          top: 0,
                                          child: SvgPicture.asset(
                                              "assets/icons/CameraBG.svg",
                                              width: 330,
                                              fit: BoxFit.fitWidth,
                                          )
                                      ),
                                      Positioned(
                                          top: 0,
                                          child: ClipRect(
                                              clipper: _CameraAreaProportionalClipper(minArea, maxArea),
                                              child: SvgPicture.asset(
                                                  "assets/icons/CameraSelection.svg",
                                                  width: 330,
                                                  fit: BoxFit.fitWidth,
                                              )
                                          )
                                      ),
                                      Positioned(
                                          left: 330 * fraction,
                                          top: 190 * yFraction,
                                          child: FractionalTranslation(
                                              translation: const Offset(-0.5, -0.5),
                                              child: Transform.scale(
                                                 scale: 1.0, // Made target larger
                                                 child: generateTargetWidgets({
                                                    "icon": selectedEyeInfo["icon"],
                                                    "label": selectedEyeInfo["label"],
                                                    "idx": selectedEyeInfo["idx"]
                                                 }, 0, isFloatingMarker: true)
                                              )
                                          )
                                      ),
                                      if (selectedCameraPosition == "Custom")
                                          Positioned(
                                              bottom: 0, // Reset to 0 (slides up exactly 15px seamlessly!)
                                              left: -15, // Provide identical 360px physical bounds to inherently match ArcSlider's internal painter geometry so the rotational center remains mathematically balanced
                                              right: -15,
                                              child: Align(
                                                  alignment: Alignment.bottomCenter,
                                                  child: Transform.scale(
                                                      scale: 0.92, // Scaled up slightly to fit perfectly
                                                      alignment: Alignment.bottomCenter, // Keeps the bottom anchored natively
                                                      child: ArcSliderWidget(
                                                          min: minAreaSizeSlider,
                                                          max: maxAreaSizeSlider,
                                                          lowerValue: areaSizeMinLimitBufView[idx].toDouble(),
                                                          upperValue: areaSizeMaxLimitBufView[idx].toDouble(),
                                                          isRange: true,
                                                          isDegreeFormatter: true, // Mathematically Maps 0-320 onto -80° to 80° for the user's perception!
                                                          unitSuffix: "",
                                                          onRangeChanged: (lower, upper) async {
                                                              areaSizeMinLimitBufView[idx] = lower.toInt();
                                                              areaSizeMaxLimitBufView[idx] = upper.toInt();
                                                              if (!isLoadingBrain && !isSettlingAfterLoad) brainHasUnsavedChanges.value = true; // camera area size changed
                                                              linkAreaSizeConnection(selectedCameraPosition: selectedCameraPosition);
                                                              setState(() {});
                                                          },
                                                      )
                                                     ) // Close Transform.scale
                                              ) // Close Align
                                          )
                                  ]
                              )
                          );
                      }),
                      
                      const SizedBox(height: 2), // Clean buffer spacing, minimized to reduce gap

                      SizedBox(
                          width: 340,
                          height: 100, // Reduced from 115 by 15px to cleanly pull up the lower card bound
                          child: Stack(
                              alignment: Alignment.bottomCenter,
                              clipBehavior: Clip.none,
                              children: [
                                  Positioned(
                                      bottom: -3, // Raised up exactly to true 0 visual padding edge
                                      child: SvgPicture.asset("assets/icons/RobotPOV.svg", width: 220)
                                  ),
                                  Positioned(
                                      left: 0,
                                      bottom: 10,
                                      child: Material(
                                          elevation: 3,
                                          borderRadius: BorderRadius.circular(20),
                                          color: cameraButtonBgColors[0],
                                          child: InkWell(
                                              borderRadius: BorderRadius.circular(20),
                                              onTapDown: (details) async { if (buttonOnPressedSource != null) soloud?.play(buttonOnPressedSource!, looping: false); },
                                              onTapUp: (details) async {
                                                if (buttonPopSource != null) soloud?.play(buttonPopSource!, looping: false);
                                                if (!isLoadingBrain && !isSettlingAfterLoad) brainHasUnsavedChanges.value = true; // camera area position changed
                                                selectedCameraPosition = "Left";
                                                linkAreaSizeConnection(selectedCameraPosition: selectedCameraPosition);
                                                setState(() {});
                                              },
                                              child: Padding(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6), // Slimmer width bounds
                                                  child: Center(child: Text("Left", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: cameraButtonFgColors[0]))),
                                              ),
                                          ),
                                      )
                                  ),
                                  Positioned(
                                      left: 20, 
                                      top: 10, // Adjusted 15px up to perfectly match the shrunken height bound dynamics!
                                      child: Material(
                                          elevation: 3,
                                          borderRadius: BorderRadius.circular(20),
                                          color: cameraButtonBgColors[1],
                                          child: InkWell(
                                              borderRadius: BorderRadius.circular(20),
                                              onTapDown: (details) async { if (buttonOnPressedSource != null) soloud?.play(buttonOnPressedSource!, looping: false); },
                                              onTapUp: (details) async {
                                                if (buttonPopSource != null) soloud?.play(buttonPopSource!, looping: false);
                                                if (!isLoadingBrain && !isSettlingAfterLoad) brainHasUnsavedChanges.value = true; // camera area position changed
                                                selectedCameraPosition = "Any";
                                                linkAreaSizeConnection(selectedCameraPosition: selectedCameraPosition);
                                                setState(() {});
                                              },
                                              child: Padding(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                                  child: Center(child: Text("Anywhere", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: cameraButtonFgColors[1]))),
                                              ),
                                          ),
                                      )
                                  ),
                                  Positioned(
                                      right: 20,
                                      top: 10, 
                                      child: Material(
                                          elevation: 3,
                                          borderRadius: BorderRadius.circular(20),
                                          color: cameraButtonBgColors[3],
                                          child: InkWell(
                                              borderRadius: BorderRadius.circular(20),
                                              onTapDown: (details) async { if (buttonOnPressedSource != null) soloud?.play(buttonOnPressedSource!, looping: false); },
                                              onTapUp: (details) async {
                                                if (buttonPopSource != null) soloud?.play(buttonPopSource!, looping: false);
                                                if (!isLoadingBrain && !isSettlingAfterLoad) brainHasUnsavedChanges.value = true; // camera area position changed
                                                selectedCameraPosition = "Custom";
                                                linkAreaSizeConnection(selectedCameraPosition: selectedCameraPosition);
                                                setState(() {});
                                              },
                                              child: Padding(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                                  child: Center(child: Text("Custom", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: cameraButtonFgColors[3]))),
                                              ),
                                          ),
                                      )
                                  ),
                                  Positioned(
                                      right: 0,
                                      bottom: 10,
                                      child: Material(
                                          elevation: 3,
                                          borderRadius: BorderRadius.circular(20),
                                          color: cameraButtonBgColors[2],
                                          child: InkWell(
                                              borderRadius: BorderRadius.circular(20),
                                              onTapDown: (details) async { if (buttonOnPressedSource != null) soloud?.play(buttonOnPressedSource!, looping: false); },
                                              onTapUp: (details) async {
                                                if (buttonPopSource != null) soloud?.play(buttonPopSource!, looping: false);
                                                if (!isLoadingBrain && !isSettlingAfterLoad) brainHasUnsavedChanges.value = true; // camera area position changed
                                                selectedCameraPosition = "Right";
                                                linkAreaSizeConnection(selectedCameraPosition: selectedCameraPosition);
                                                setState(() {});
                                              },
                                              child: Padding(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                                  child: Center(child: Text("Right", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: cameraButtonFgColors[2]))),
                                              ),
                                          ),
                                      )
                                  ),
                              ]
                          )
                      ),
                    ],
                  ),
                ),
              )),
        );
      } else {
        List<Widget> targetWidgets = [];
        int idx = 0;

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
              right: (Platform.isIOS && safePadding > 0 ? safePadding : 20 + safePadding),
              top: safePaddingTop,
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
                            // V19: Removed Divider
                            SizedBox(
                              width: 450, // V8: Wider grid
                              height: 300, // V8: Taller grid
                              child: GridView.count(
                                padding: EdgeInsets.zero, // V19: Remove Padding
                                crossAxisCount: 4, // V8: 4 Columns
                                children: targetWidgets,
                                ))
                          ])))),
        );
      }
    } else if (!isPlayingMenu && !isAnnotationMode && isDistanceMenu && controller.isSelectingEdge) {
      List<Map<String, String>> listDistanceInfo = [
        {"icon": "🛑", "label": "Near", "idx": "0"},
        {"icon": "⚠️", "label": "Medium", "idx": "1"},
        {"icon": "🏁", "label": "Far", "idx": "2"},
        {"icon": "📏", "label": "Custom", "idx": "3"},
      ];
      InfiniteCanvasNode selected = findNeuronByKey(controller.edgeSelected!.to);
      int idx = neuronTypes.keys.toList().indexOf(selected.id);
      List<Widget> distanceToolboxWidgets =
          generateDistanceToolboxWidgets(listDistanceInfo, idx);

      // Verify fonts?
      // printDebug("Font Family: ${GoogleFonts.inconsolata().fontFamily}");

      // dropdownDistanceItems
      inlineWidgets.add(
        Positioned(
            right: (Platform.isIOS && safePadding > 0 ? safePadding : 20 + safePadding),
            top: safePaddingTop,
            child: Card(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 7, 8, 3),
                    child: SizedBox(
                      width: 380, // V13: Locked Width
                      child: Column(
                        mainAxisSize: MainAxisSize.max,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                    const Padding(
                      padding: EdgeInsets.fromLTRB(22, 0, 22, 0),
                      child: Text(
                        "Select a Distance for Spiking",
                        textAlign: TextAlign.center,
                        textScaleFactor: 1.0, // V20: Lock OS Accessibility Scale
                        style: TextStyle(
                          fontSize: 17,
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly, 
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: distanceToolboxWidgets,
                    ),
                    const SizedBox(height: 4),
                    isShowingInfo == 1
                        ? Row(
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
                                          1, 1), 
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
                                child: BybHighlightedText(
                                  distanceSensorContent,
                                  maxLines: 3,
                                ),
                              ),
                            ],
                          )
                        : const SizedBox(),
                    const SizedBox(height: 8),

                    // RULER GRAPHICS
                    Builder(builder: (context) {
                       double minD = distanceMinLimitBufView[idx].toDouble();
                       double maxD = distanceMaxLimitBufView[idx].toDouble();
                       
                       // For non-custom modes, we need to manually map back the preset ranges visually.
                       // Looking at linkDistanceConnection, Short is typically ~1->8, Medium ~10->25, Far ~40->130
                       // We just pull straight from the buffer view which is kept updated by the UI/buttons.
                       
                       return SizedBox(
                           width: 340, // Scale it to fit nicely in the 380 container
                           child: Stack(
                               alignment: Alignment.center,
                               children: [
                                  ClipRect(
                                      clipper: _DistanceRulerProportionalClipper(minD, maxD),
                                      child: SvgPicture.asset(
                                          "assets/icons/RobotRulerFill.svg",
                                          width: 340,
                                          fit: BoxFit.fitWidth,
                                      )
                                  ),
                                  SvgPicture.asset(
                                      "assets/icons/RobotRuler.svg",
                                      width: 340,
                                      fit: BoxFit.fitWidth,
                                  ),
                               ]
                           )
                       );
                    }),
                    
                    if (selectedDistanceIdx == 3) ...[
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                            ArcSliderWidget(
                              min: minDistanceSlider,
                              max: maxDistanceSlider,
                              lowerValue: distanceMinLimitBufView[idx].toDouble(),
                              upperValue: distanceMaxLimitBufView[idx].toDouble(),
                              isRange: true,
                              unitSuffix: "cm",
                              activeColor: colorOrange,
                              onRangeChanged: (lower, upper) async {
                                distanceMinLimitBufView[idx] = lower.toInt();
                                distanceMaxLimitBufView[idx] = upper.toInt();
                                if (!isLoadingBrain && !isSettlingAfterLoad) brainHasUnsavedChanges.value = true; // distance custom range changed
                                linkDistanceConnection(distanceMenuType);
                                setState(() {});
                              },
                            ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 10),
                  ],
                ),
              ), 
            ), 
          ),
        ),
      );
    } else if (!isPlayingMenu && !isAnnotationMode && isMicrophoneMenu && controller.isSelectingEdge) {
      try {
      int idx = -1;
      try {
        InfiniteCanvasNode node = findNeuronByKey(controller.edgeSelected!.to);
        idx = neuronTypes.keys.toList().indexOf(node.id);
      } catch (e) {
        // Fallback or handle error
      }
      
      double safeMin = 0;       // C note default
      double safeMax = 0;
      int currentMicMode = 2; // 0=Freq, 1=Vol, 2=Tone — default Tone

      // Dynamic Slider variables
      double currentMinSlider = 0;
      double currentMaxSlider = 24;
      double currentDefMin = 0;   // C note
      double currentDefMax = 0;
      
      if (idx != -1) {
          InfiniteCanvasNode node = findNeuronByKey(controller.edgeSelected!.to);
          String key = "${nodeMicrophoneSensor.id}_${node.id}";
          
          // Persistence: Mode
          if (mapMicrophoneTypeNeuron.containsKey(key)) {
             currentMicMode = mapMicrophoneTypeNeuron[key];
          }
          
          // Safety write
          if (microphoneTypeBufView.isNotEmpty && idx < microphoneTypeBufView.length) {
              microphoneTypeBufView[idx] = currentMicMode;
          }

          // Configure Mode-specific Ranges
          if (currentMicMode == 1) { // Volume
              currentMinSlider = 0;
              currentMaxSlider = 32767;
              currentDefMin = 800;
              currentDefMax = 2000;
          } else if (currentMicMode == 2) { // Tone
               currentMinSlider = 0;
               currentMaxSlider = 24; // Allow small values for notes
               currentDefMin = 0;     // Default C
               currentDefMax = 0; 
          } else { // Frequency (Default 0)
              currentMinSlider = 100;
              currentMaxSlider = 5000;
              currentDefMin = 400;
              currentDefMax = 800; 
          }

          // Persistence: Limit
          if (mapMicrophoneLimitNeuron.containsKey(key)) {
             try {
               String temp = mapMicrophoneLimitNeuron[key];
               List<String> arr = temp.split("_@_");
               safeMin = double.parse(arr[0]);
               safeMax = double.parse(arr[1]);
               
               if (microphoneMinLimitBufView.isNotEmpty && idx < microphoneMinLimitBufView.length) {
                   microphoneMinLimitBufView[idx] = safeMin.toInt();
                   microphoneMaxLimitBufView[idx] = safeMax.toInt();
               }
             } catch (e) {
               safeMin = currentDefMin;
               safeMax = currentDefMax;
             }
          } else {
              if (microphoneMinLimitBufView.isNotEmpty && idx < microphoneMinLimitBufView.length) {
                  safeMin = microphoneMinLimitBufView[idx].toDouble();
                  safeMax = microphoneMaxLimitBufView[idx].toDouble();
              } else {
                  safeMin = currentDefMin;
                  safeMax = currentDefMax;
              }
              
              // Validate and fix degenerate ranges
              if (safeMin < currentMinSlider || safeMax < currentMinSlider || safeMin >= safeMax || safeMax > currentMaxSlider) {
                 safeMin = currentDefMin;
                 safeMax = currentDefMax;
                 if (microphoneMinLimitBufView.isNotEmpty && idx < microphoneMinLimitBufView.length) {
                     microphoneMinLimitBufView[idx] = safeMin.toInt();
                     microphoneMaxLimitBufView[idx] = safeMax.toInt();
                 }
              }
          }
          
          // Clamp to Mode Bounds
          if (safeMin < currentMinSlider) safeMin = currentMinSlider;
          if (safeMin > currentMaxSlider) safeMin = currentMaxSlider;
          if (safeMax < currentMinSlider) safeMax = currentMinSlider;
          if (safeMax > currentMaxSlider) safeMax = currentMaxSlider;
          if (safeMin > safeMax) safeMin = safeMax - 1; 
          // Only enforce gap if NOT mode 2 (Tone)
          if (currentMicMode != 2 && safeMin >= safeMax) safeMin = safeMax - 10;
             
          // Force Text Sync
          if (txtMicrophoneMinController.text != safeMin.toInt().toString()) {
             txtMicrophoneMinController.text = safeMin.toInt().toString();
          }
           if (txtMicrophoneMaxController.text != safeMax.toInt().toString()) {
             txtMicrophoneMaxController.text = safeMax.toInt().toString();
          }
      }

      // Info Logic
      String micInfoText = "";
      if (currentMicMode == 2) micInfoText = "NEURON will SPIKE when it hears a note in the selected key";
      else if (currentMicMode == 1) micInfoText = "NEURON will SPIKE whenever the volume is within the set range";
      else micInfoText = "NEURON will SPIKE when the loudest noise is within the set frequencies in HERTZ";

      List<Map<String, dynamic>> listMicInfo = [
        {"icon": "🎹", "label": "Tone", "mode": 2},
        {"icon": "🔊", "label": "Volume", "mode": 1},
        {"icon": "〰️", "label": "Frequency", "mode": 0},
      ];

      List<Widget> micToolboxWidgets = listMicInfo.map((info) {
        String label = info["label"];
        String icon = info["icon"];
        int modeValue = info["mode"];
        bool isActive = (currentMicMode == modeValue);

        return GestureDetector(
          onTapDown: (details) async {
            if (buttonOnPressedSource != null) {
              try {
                buttonOnPressedHandle =
                    await soloud?.play(buttonOnPressedSource!, looping: false);
              } catch (err) {}
            }
          },
          onTapUp: (details) async {
            if (buttonPopSource != null) {
              try {
                buttonPopHandle =
                    await soloud?.play(buttonPopSource!, looping: false);
              } catch (err) {
                 // ignore
              }
            }
            
            if (idx != -1) {
                currentMicMode = modeValue;
                if (microphoneTypeBufView.isNotEmpty && idx < microphoneTypeBufView.length) {
                    microphoneTypeBufView[idx] = currentMicMode;
                }

                InfiniteCanvasNode node = findNeuronByKey(controller.edgeSelected!.to);
                String key = "${nodeMicrophoneSensor.id}_${node.id}";
                mapMicrophoneTypeNeuron[key] = currentMicMode;
                
                // Update Ranges for new mode defaults immediately
                if (currentMicMode == 1) { // Vol
                    currentDefMin = 800; currentDefMax = 2000;
                } else if (currentMicMode == 2) { // Tone
                    currentDefMin = 0; currentDefMax = 0;
                } else { // Freq
                    currentDefMin = 400; currentDefMax = 800;
                }
                
                // RESET slider to defaults for the new mode to avoid confusion/out-of-bounds
                if (microphoneMinLimitBufView.isNotEmpty && idx < microphoneMinLimitBufView.length) {
                    microphoneMinLimitBufView[idx] = currentDefMin.toInt();
                    microphoneMaxLimitBufView[idx] = currentDefMax.toInt();
                }
                mapMicrophoneLimitNeuron[key] = "${currentDefMin.toInt()}_@_${currentDefMax.toInt()}";
                controller.mapMicrophoneLimitNeuron[key] = mapMicrophoneLimitNeuron[key];

                txtMicrophoneMinController.text = currentDefMin.toInt().toString();
                txtMicrophoneMaxController.text = currentDefMax.toInt().toString();
                
                if (!isLoadingBrain && !isSettlingAfterLoad) brainHasUnsavedChanges.value = true; // sensor property changed
                linkMicrophoneConnection();
                if (!isLoadingBrain && !isSettlingAfterLoad) brainHasUnsavedChanges.value = true; // microphone mode changed

                setState((){});
            }
          },
          child: SizedBox(
            width: 110, // V9: Wider
            height: 100,
            child: Stack(
                    clipBehavior: Clip.none, // V9: Allow overflow
                    children: [
                      Align(
                          alignment: Alignment.topCenter, // V9: Perfect Centering
                          child: Container(
                            width: 70,
                            height: 70,
                            margin: const EdgeInsets.only(top: 0), // Remove left margin
                            decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        color: isActive
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
                      child: Center(
                        child: Text(icon,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 40, // Increased size
                            fontFamily: "NotoEmoji",
                            height: 1.2, // Tweak line height for vertical centering
                          ),
                        ),
                      ),
                    ),
                  ),
                Positioned(
                    left: 0,
                    right: 0,
                    top: 62, // V10: 8px Overlap
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minWidth: 80),
                        child: Card(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                              child: Text(
                                label,
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                              ),
                        ),
                      ),
                    ),
                   ),
                  ),
              ],
            ),
          ),
        );
      }).toList();

      inlineWidgets.add(
        Positioned(
                right: (Platform.isIOS && safePadding > 0 ? safePadding : 20 + safePadding),
                top: safePaddingTop,
                child: Card(
                  clipBehavior: Clip.antiAlias,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 7, 8, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          "Microphone Inputs for Spiking",
                          style: TextStyle(
                            fontSize: 17,
                          ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: micToolboxWidgets,
                    ),
                    const SizedBox(
                      width: 10,
                      height: 10,
                    ),
                    
                    // INFO SECTION
                    if (isShowingInfo == 1)
                      GestureDetector(
                        onTap: () {
                          // Allow user to dismiss this specific info
                          isShowingInfo = 0;
                          setState(() {});
                        },
                        child: SizedBox(
                          width: 360, // Force Info section to match standardized card width
                          child: Row(
                            // mainAxisAlignment: MainAxisAlignment.center, // Removed to allow start alignment
                            crossAxisAlignment: CrossAxisAlignment.center, // Vertically center icon and text
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
                                            1, 1), 
                                      ),
                                    ],
                                  ),
                                  child: SvgPicture.asset("assets/icons/Info.svg"),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: BybHighlightedText(
                                    micInfoText,
                                    maxLines: 3,
                                    textAlign: TextAlign.left,
                                  ),
                                ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 5), // Added padding below Info
                    const Divider(height: 8),
                    if (currentMicMode == 2) ...[
                        // TONE KEYBOARD
                        Padding(
                          padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                          child:
                        Container(
                            height: 150, 
                            width: 360,  // Standardized 360 width for larger keys
                            // padding: const EdgeInsets.symmetric(horizontal: 10), // Removed padding
                            child: LayoutBuilder(
                                builder: (context, constraints) {
                                    // 7 White keys
                                    double whiteKeyWidth = (constraints.maxWidth - 2) / 7; // Adjust for 2px overlap on last key
                                    double blackKeyWidth = whiteKeyWidth * 0.7;
                                    double height = constraints.maxHeight;

                                    // Mapping: C=0, C#=1, D=2, ... B=11
                                    // White keys: 0, 2, 4, 5, 7, 9, 11 (Indices in octave)
                                    // Black keys: 1, 3, 6, 8, 10
                                    
                                    // We will store the selected note index in minLimit for simplicity, or specific frequency.
                                    // For now, let's use 0-11.
                                    List<String> noteNames = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"];
                                    int currentNote = safeMin.toInt();
                                    // If values are huge (default 400), reset/clamp for display?
                                    if (currentNote > 100) currentNote = 0; 
                                    
                                    // Note Frequencies (approx C4-B4)
                                    // C4: 261, C#4: 277, D4: 293, D#4: 311, E4: 329, F4: 349, F#4: 370, G4: 392, G#4: 415, A4: 440, A#4: 466, B4: 493.
                                    // Actually, let's just stick to 0-11 index if the C++ side can handle it, 
                                    // OR map to generic bins. 
                                    // Let's assume indices 0-12 for now as 'Tone' param.
                                    
                                    Function(int) onKeyTap = (int noteIndex) async {
                                        if (buttonPopSource != null) {
                                          try {
                                              await soloud?.play(buttonPopSource!, looping: false);
                                          } catch (e) {
                                              // ignore
                                          }
                                        }
                                        if (idx != -1) {
                                            if (microphoneMinLimitBufView.isNotEmpty && idx < microphoneMinLimitBufView.length) {
                                                microphoneMinLimitBufView[idx] = noteIndex;
                                                microphoneMaxLimitBufView[idx] = noteIndex; // Point value
                                            }
                                            // Update UI locals
                                            safeMin = noteIndex.toDouble();
                                            safeMax = noteIndex.toDouble();
                                            
                                            // Update Map
                                            if (controller.edgeSelected != null) {
                                                InfiniteCanvasNode node = findNeuronByKey(controller.edgeSelected!.to);
                                                String key = "${nodeMicrophoneSensor.id}_${node.id}";
                                                mapMicrophoneLimitNeuron[key] = "${noteIndex}_@_${noteIndex}";
                                                controller.mapMicrophoneLimitNeuron[key] = mapMicrophoneLimitNeuron[key];
                                            }
                                            if (!isLoadingBrain && !isSettlingAfterLoad) brainHasUnsavedChanges.value = true; // sensor property changed
                                            linkMicrophoneConnection();
                                            setState((){});
                                        }
                                    };

                                    List<Widget> keys = [];
                                    
                                    // White Keys Data
                                    List<int> whiteNotes = [0, 2, 4, 5, 7, 9, 11];
                                    for (int i = 0; i < 7; i++) {
                                        int noteVal = whiteNotes[i];
                                        bool isSelected = (currentNote == noteVal);
                                        keys.add(Positioned(
                                            left: i * whiteKeyWidth,
                                            top: 0,
                                            width: whiteKeyWidth + 2, // Overlap border width (2px)
                                            height: height,
                                            child: GestureDetector(
                                                onTapDown: (d) async {
                                                   if (buttonOnPressedSource != null) {
                                                      try {
                                                          await soloud?.play(buttonOnPressedSource!, looping: false);
                                                      } catch (e) {}
                                                   }
                                                },
                                                onTap: () => onKeyTap(noteVal),
                                                child: Container(
                                                    decoration: BoxDecoration(
                                                        color: isSelected ? colorOrange : Colors.white,
                                                        border: Border.all(color: Colors.black, width: 2), // Reduce border width slightly if keys are tight? 
                                                        // Previous was 4. 2 might be cleaner. user said "closer to width".
                                                        borderRadius: const BorderRadius.only(
                                                            bottomLeft: Radius.circular(5),
                                                            bottomRight: Radius.circular(5)
                                                        )
                                                    ),
                                                    child: isShowingInfo == 2 ? Center(
                                                        child: Container(
                                                          margin: const EdgeInsets.only(top: 100), // Position towards bottom
                                                          child: Text(noteNames[noteVal],
                                                            style: const TextStyle(
                                                                color: Colors.black,
                                                                fontFamily: "BybHanddrawn",
                                                                fontSize: 18,
                                                                decoration: TextDecoration.none
                                                            )
                                                          ),
                                                        )
                                                    ) : null,
                                                ),
                                            )
                                        ));
                                    }

                                    // Black Keys Data
                                    // C# (between 0-1), D# (1-2), F# (3-4), G# (4-5), A# (5-6)
                                    // Indices relative to white keys
                                    Map<int, int> blackNoteMap = {
                                        0: 1, // C#
                                        1: 3, // D#
                                        3: 6, // F#
                                        4: 8, // G#
                                        5: 10 // A#
                                    };
                                    
                                    blackNoteMap.forEach((whiteIndex, noteVal) {
                                        bool isSelected = (currentNote == noteVal);
                                        keys.add(Positioned(
                                            left: (whiteIndex * whiteKeyWidth) + (whiteKeyWidth * 0.65), // Centered on boundary
                                            top: 0,
                                            width: blackKeyWidth,
                                            height: height * 0.6,
                                            child: GestureDetector(
                                                onTapDown: (d) async {
                                                   if (buttonOnPressedSource != null) {
                                                      try {
                                                          await soloud?.play(buttonOnPressedSource!, looping: false);
                                                      } catch (e) {}
                                                   }
                                                },
                                                onTap: () => onKeyTap(noteVal),
                                                child: Container(
                                                    decoration: BoxDecoration(
                                                        color: isSelected ? colorOrange : Colors.black,
                                                        border: Border.all(color: Colors.black, width: 2),
                                                        borderRadius: const BorderRadius.only(
                                                            bottomLeft: Radius.circular(3),
                                                            bottomRight: Radius.circular(3)
                                                        )
                                                    ),
                                                    child: isShowingInfo == 2 ? Center(
                                                        child: Container(
                                                          margin: const EdgeInsets.only(top: 40), // Position towards bottom of black key
                                                          child: Text(noteNames[noteVal],
                                                            style: TextStyle(
                                                                color: isSelected ? Colors.black : Colors.white,
                                                                fontFamily: "BybHanddrawn",
                                                                fontSize: 14, // Smaller for black keys
                                                                decoration: TextDecoration.none
                                                            )
                                                          ),
                                                        )
                                                    ) : null,
                                                ),
                                            )
                                        ));
                                    });

                                    return Stack(
                                        children: keys,
                                    );
                                }
                            )
                        )
                        ),
                    ] else ...[
                    // SLIDERS (For Vol and Freq) — replaced with ArcSliderWidget
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (currentMicMode == 1)
                          // ── VOLUME ─────────────────────────────────────────────
                          // Display 0–100 %; internally maps non-linearly to 0–32767 raw units.
                          Builder(builder: (context) {
                            double volToPercent(double vol) {
                              if (vol <= 500) return vol / 500 * 25;
                              if (vol <= 5000) return 25 + ((vol - 500) / 4500) * 50;
                              return 75 + ((vol - 5000) / 27767) * 25;
                            }
                            int percentToVol(double percent) {
                              if (percent <= 25) return (percent / 25 * 500).round();
                              if (percent <= 75) return (500 + ((percent - 25) / 50) * 4500).round();
                              return (5000 + ((percent - 75) / 25) * 27767).round();
                            }

                            return ArcSliderWidget(
                              key: const ValueKey('mic_vol_arc'),
                              min: 0,
                              max: 100,
                              lowerValue: volToPercent(safeMin.toDouble()).clamp(0, 100).roundToDouble(),
                              upperValue: volToPercent(safeMax.toDouble()).clamp(0, 100).roundToDouble(),
                              isRange: true,
                              isPercentageFormatter: true,
                              activeColor: colorOrange,
                              title: "Volume",
                              lowerTitle: "Min",
                              upperTitle: "Max",
                              onRangeChanged: (lower, upper) {
                                if (idx == -1) return;
                                int rawMin = percentToVol(lower).clamp(0, 32767);
                                int rawMax = percentToVol(upper).clamp(0, 32767);
                                if (rawMin >= rawMax) rawMin = (rawMax - 1).clamp(0, 32767);
                                
                                if (microphoneMinLimitBufView.isNotEmpty &&
                                    idx < microphoneMinLimitBufView.length) {
                                  microphoneMinLimitBufView[idx] = rawMin;
                                  microphoneMaxLimitBufView[idx] = rawMax;
                                }
                                if (controller.edgeSelected != null) {
                                  InfiniteCanvasNode node =
                                      findNeuronByKey(controller.edgeSelected!.to);
                                  String k = "${nodeMicrophoneSensor.id}_${node.id}";
                                  mapMicrophoneLimitNeuron[k] = "${rawMin}_@_${rawMax}";
                                  controller.mapMicrophoneLimitNeuron[k] =
                                      mapMicrophoneLimitNeuron[k];
                                }
                                txtMicrophoneMinController.text = rawMin.toString();
                                txtMicrophoneMaxController.text = rawMax.toString();
                                if (!isLoadingBrain && !isSettlingAfterLoad) brainHasUnsavedChanges.value = true; // sensor property changed
                                linkMicrophoneConnection();
                                setState(() {});
                              },
                            );
                          })
                        else
                          // ── FREQUENCY ──────────────────────────────────────────
                          // Display raw Hz (100–5000), snapped to nearest 10 Hz.
                          ArcSliderWidget(
                            key: const ValueKey('mic_freq_arc'),
                            min: 100,
                            max: 5000,
                            lowerValue: (((safeMin / 10).round() * 10)
                                    .clamp(100, 5000))
                                .toDouble(),
                            upperValue: (((safeMax / 10).round() * 10)
                                    .clamp(100, 5000))
                                .toDouble(),
                            isRange: true,
                            unitSuffix: "Hz",
                            activeColor: colorOrange,
                            title: "Frequency",
                            lowerTitle: "Min",
                            upperTitle: "Max",
                            isLogarithmic: true,
                            onRangeChanged: (lower, upper) {
                              if (idx == -1) return;
                              // Snap both handles to nearest 10 Hz
                              int snappedMin = ((lower / 10).round() * 10)
                                  .clamp(100, 5000);
                              int snappedMax = ((upper / 10).round() * 10)
                                  .clamp(100, 5000);
                              if (snappedMin >= snappedMax)
                                snappedMin = (snappedMax - 10).clamp(100, 5000);
                              if (microphoneMinLimitBufView.isNotEmpty &&
                                  idx < microphoneMinLimitBufView.length) {
                                microphoneMinLimitBufView[idx] = snappedMin;
                                microphoneMaxLimitBufView[idx] = snappedMax;
                              }
                              if (controller.edgeSelected != null) {
                                InfiniteCanvasNode node =
                                    findNeuronByKey(controller.edgeSelected!.to);
                                String k = "${nodeMicrophoneSensor.id}_${node.id}";
                                mapMicrophoneLimitNeuron[k] =
                                    "${snappedMin}_@_${snappedMax}";
                                controller.mapMicrophoneLimitNeuron[k] =
                                    mapMicrophoneLimitNeuron[k];
                              }
                              txtMicrophoneMinController.text = snappedMin.toString();
                              txtMicrophoneMaxController.text = snappedMax.toString();
                              if (!isLoadingBrain && !isSettlingAfterLoad) brainHasUnsavedChanges.value = true; // sensor property changed
                              linkMicrophoneConnection();
                              setState(() {});
                            },
                          ),
                      ],
                    ),
                    ], // Close else block
                    // VISUALIZATION PANEL (Vol/Freq only) ─────────────────────────────
                    if (currentMicMode != 2) ...[
                      const SizedBox(height: 4),
                      Transform.translate(
                        offset: const Offset(-8, 3), // align with card bottom-left corner
                        child: SizedBox(
                          width: 376,  // full card width (360 content + 2*8 padding)
                          height: 91,  // 88 + 3 for bottom alignment
                          child: Stack(
                            clipBehavior: Clip.hardEdge,
                            children: [
                              // RobotEars SVG: 175% larger, bleeds past left edge
                              Positioned(
                                left: -30,
                                bottom: -8,
                                child: SizedBox(
                                  width: 193,
                                  height: 154,
                                  child: SvgPicture.asset(
                                    'assets/icons/RobotEars.svg',
                                    fit: BoxFit.contain,
                                    alignment: Alignment.bottomLeft,
                                  ),
                                ),
                              ),
                              // Frequency waves or volume emojis on the right
                              Positioned(
                                left: 152,
                                right: 0,
                                top: 0,
                                bottom: 0,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 6),
                                  child: currentMicMode == 1
                                    // VOLUME: only show active zone emojis
                                    ? Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          if ((safeMin / 2000 * 100) < 25)
                                            Text('🤫',
                                              style: TextStyle(fontSize: 51,
                                                fontFamily: 'NotoEmoji',
                                                decoration: TextDecoration.none)),
                                          if ((safeMin / 2000 * 100) < 75 &&
                                              (safeMax / 2000 * 100) > 25)
                                            Text('🗣',
                                              style: TextStyle(fontSize: 51,
                                                fontFamily: 'NotoEmoji',
                                                decoration: TextDecoration.none)),
                                          if ((safeMax / 2000 * 100) > 75)
                                            Text('📣',
                                              style: TextStyle(fontSize: 51,
                                                fontFamily: 'NotoEmoji',
                                                decoration: TextDecoration.none)),
                                        ],
                                      )
                                    // FREQUENCY: sine wave painter
                                    : CustomPaint(
                                        size: const Size(double.infinity, 76),
                                        painter: MicFrequencyWavePainter(
                                          showLow:  safeMin < 250,
                                          showMid:  safeMin < 4000 && safeMax > 250,
                                          showHigh: safeMax > 4000,
                                        ),
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    ],
                  ),
                ),
              ),
              ));
      } catch (e) {
          printDebug("Error building Mic Menu: $e");
      }
    } else if (!isPlayingMenu && !isAnnotationMode &&
        (isSpeakerMenu) &&
        controller.isSelectingEdge) {
      inlineWidgets.add(
        Positioned(
            right: (Platform.isIOS && safePadding > 0 ? safePadding : 20 + safePadding),
            top: safePaddingTop,
            child: SpeakerMenuWidget(
              currentFrequency: sldFrequencyWeight,
              soloud: soloud,
              buttonOnPressedSource: buttonOnPressedSource,
              buttonPopSource: buttonPopSource,
              infoState: isShowingInfo, // V12: Pass int state
              onFrequencyChanged: (double val) {
                sldFrequencyWeight = val;
                tecFrequencyWeight.text = val.round().toString();
                if (!isLoadingBrain && !isSettlingAfterLoad) brainHasUnsavedChanges.value = true; // speaker frequency changed
                linkSpeakerConnection(val.toString());
                setState(() {});
              },
            )),
      );
    } else if (!isPlayingMenu && !isAnnotationMode &&
        (isMotorMenu || isSynapseMenu) &&
        controller.isSelectingEdge) {
      inlineWidgets.add(
        Positioned(
            top: safePaddingTop,
            right: (Platform.isIOS && safePadding > 0 ? safePadding : 20 + safePadding),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 7, 8, 3),
                child: SizedBox(
                  width: 300,
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                    Builder(builder: (context) {
                      bool isMulti = controller.multiEdgeSelection.length > 1;
                      bool isUniform = true;
                      double weightValue = sldSynapticWeight;
                      
                      if (isMulti) {
                          if (controller.multiEdgeSelection.isNotEmpty) {
                              double first = controller.multiEdgeSelection.first.connectionStrength;
                              isUniform = controller.multiEdgeSelection.every((e) => e.connectionStrength == first);
                              if (isUniform) {
                                weightValue = first;
                              } else {
                                weightValue = 50; 
                              }
                          }
                      }

                      bool isMixed = isMulti && !isUniform;

                      bool isExcitatory = true;
                      bool isMotorTarget = false;
                      String motorWheel = "";
                      String motorAction = "";
                      String motorTitle = "";

                      if (controller.multiEdgeSelection.isNotEmpty) {
                          var edge = controller.multiEdgeSelection.first;
                          var nFrom = findNeuronByKeySafe(edge.from);
                          if (nFrom != null && neuronStyles[nFrom.id] == 'Inhibitory') {
                              isExcitatory = false;
                          }
                          
                          if (!isMulti) {
                              var nTo = findNeuronByKeySafe(edge.to);
                              if (nTo != null) {
                                  if (nTo.value == 5) {
                                      isMotorTarget = true;
                                      motorWheel = "Left";
                                      motorAction = "forward";
                                      motorTitle = isExcitatory ? "Left Wheel Forward Speed" : "Left Wheel Front Brake Strength";
                                  } else if (nTo.value == 6) {
                                      isMotorTarget = true;
                                      motorWheel = "Right";
                                      motorAction = "forward";
                                      motorTitle = isExcitatory ? "Right Wheel Forward Speed" : "Right Wheel Front Brake Strength";
                                  } else if (nTo.value == 7) {
                                      isMotorTarget = true;
                                      motorWheel = "Left";
                                      motorAction = "reverse";
                                      motorTitle = isExcitatory ? "Left Wheel Reverse Speed" : "Left Wheel Rear Brake Strength";
                                  } else if (nTo.value == 8) {
                                      isMotorTarget = true;
                                      motorWheel = "Right";
                                      motorAction = "reverse";
                                      motorTitle = isExcitatory ? "Right Wheel Reverse Speed" : "Right Wheel Rear Brake Strength";
                                  }
                              }
                          }
                      }

                      String mainTitleStr = isMulti ? "Set Many Synaptic Weights" : (isMotorTarget ? motorTitle : "Set Synaptic Weight");
                      String dialTitleStr = isMotorTarget ? (isExcitatory ? "Motor speed:" : "Braking Force:") : "Signal strength:";

                      String getDynamicSynapticText(double w, bool excitatory, bool isMotor, String wheel, String action) {
                          int wStr = w.round();
                          if (isMotor) {
                              if (wStr == 0) {
                                  if (!excitatory) {
                                      String actionCap = action == "forward" ? "Forward" : "Reverse";
                                      return "$wheel wheel will not stop moving $actionCap when it gets a SPIKE.";
                                  }
                                  return "$wheel wheel will not move when it gets a SPIKE.";
                              }
                              
                              if (excitatory) {
                                  String spd = "";
                                  if (wStr <= 24) spd = " slowly";
                                  else if (wStr <= 60) spd = "";
                                  else spd = " fast";
                                  
                                  return "$wheel wheel will move $action$spd when it gets a SPIKE.";
                              } else {
                                  String prob = "";
                                  if (wStr <= 10) prob = "may not";
                                  else if (wStr <= 50) prob = "will likely";
                                  else if (wStr <= 99) prob = "will";
                                  else prob = "always will";
                                  
                                  String actionCap = action == "forward" ? "Forward" : "Reverse";
                                  return "$wheel wheel $prob stop moving $actionCap when it gets a SPIKE.";
                              }
                          } else {
                              if (wStr == 0) {
                                  if (excitatory) {
                                      return "The parent NEURON will not make the next NEURON SPIKE.";
                                  } else {
                                      return "The parent NEURON will not make the next NEURON stop SPIKING.";
                                  }
                              }

                              String freq = "";
                              if (wStr == 100) {
                                  freq = "always.";
                              } else if (wStr >= 50) {
                                  freq = "most of the time.";
                              } else if (wStr >= 25) {
                                  freq = "usually.";
                              } else if (wStr >= 1) {
                                  freq = "with help from other NEURONS.";
                              }

                              if (excitatory) {
                                  return "The parent NEURON will make the next NEURON SPIKE $freq";
                              } else {
                                  return "The parent NEURON will make the next NEURON stop SPIKING $freq";
                              }
                          }
                      }

                      String dynamicInfoText = getDynamicSynapticText(weightValue, isExcitatory, isMotorTarget, motorWheel, motorAction);

                      return Column(
                        children: [
                          Center(
                            child: Text(mainTitleStr,
                                style: const TextStyle(fontSize: 17)),
                          ),
                          if (isMotorTarget)
                            Transform.translate(
                              offset: const Offset(0, 5),
                              child: MotorAnimatedWidget(
                                  value: weightValue,
                                  wheel: motorWheel,
                                  action: motorAction,
                                  isExcitatory: isExcitatory,
                                  isMixed: isMixed,
                                onChanged: (value) async {
                                  if (!isLoadingBrain && !isSettlingAfterLoad) brainHasUnsavedChanges.value = true; // weight/property changed
                                  try {
                                      if (isMulti) {
                                          controller.synapticWeight = value;
                                          tecSynapticWeight.text = value.round().toString();
                                          for (var edge in controller.multiEdgeSelection) {
                                              try {
                                                  var nFrom = findNeuronByKeySafe(edge.from);
                                                  var nTo = findNeuronByKeySafe(edge.to);
                                                  if (nFrom != null && nTo != null) {
                                                      String key = "${nFrom.id}_${nTo.id}";
                                                      String label = (nTo.label ?? "").toUpperCase();
                                                      edge.connectionStrength = value;
                                                      edge.label = value.round().toString();
                                                      if (label.contains("MOTOR") || (nTo.value >= 5 && nTo.value <= 8)) {
                                                          mapContactsNeuron[key] = value;
                                                          updateLiveConnectionBuffer(nFrom, nTo, value, "motor");
                                                      } else {
                                                          mapConnectome[key] = value;
                                                          updateLiveConnectionBuffer(nFrom, nTo, value, "connectome");
                                                      }
                                                  }
                                              } catch (e) {
                                                  printDebug("Error syncing multi-edge: $e");
                                              }
                                          }
                                          setState((){});
                                      } else {
                                          sldSynapticWeight = value.roundToDouble();
                                          tecSynapticWeight.text = value.round().toString();
                                          if (isSynapseMenu) linkNeuronConnection(sldSynapticWeight.toString());
                                          else if (isMotorMenu) linkMotorConnection(sldSynapticWeight.toString());
                                          controller.notifyListeners(); // repaint canvas: update axon thickness
                                          setState(() {});
                                      }
                                  } catch (err) {}
                                },
                            ),
                          )
                          else
                             ArcSliderWidget(
                                title: dialTitleStr,
                                lowerTitle: null,
                                value: weightValue,
                                widgetWidth: 300.0,
                                min: 0,
                                max: 100,
                                isPercentageFormatter: true,
                                isMixedState: isMixed,
                                onChanged: (value) async {
                                  if (isSpeakerMenu || isLedMenu) return;
                                  if (!isSpeakerMenu && !isLedMenu && !isLoadingBrain && !isSettlingAfterLoad) brainHasUnsavedChanges.value = true;

                                  try {
                                      if (isMulti) {
                                          controller.synapticWeight = value;
                                          tecSynapticWeight.text = value.round().toString();
                                          
                                          for (var edge in controller.multiEdgeSelection) {
                                              try {
                                                  var nFrom = findNeuronByKeySafe(edge.from);
                                                  var nTo = findNeuronByKeySafe(edge.to);
                                                  if (nFrom != null && nTo != null) {
                                                      String key = "${nFrom.id}_${nTo.id}";
                                                      String label = (nTo.label ?? "").toUpperCase();

                                                      edge.connectionStrength = value;
                                                      edge.label = value.round().toString();

                                                      if (label.contains("MOTOR") || (nTo.value >= 5 && nTo.value <= 8)) {
                                                          mapContactsNeuron[key] = value;
                                                          updateLiveConnectionBuffer(nFrom, nTo, value, "motor");
                                                      } else {
                                                          mapConnectome[key] = value;
                                                          updateLiveConnectionBuffer(nFrom, nTo, value, "connectome");
                                                      }
                                                  }
                                              } catch (e) {
                                                  printDebug("Error syncing multi-edge: $e");
                                              }
                                          }
                                          setState((){});
                                      } else {
                                          sldSynapticWeight = value.roundToDouble();
                                          tecSynapticWeight.text = value.round().toString();

                                          if (isSynapseMenu) {
                                              linkNeuronConnection(sldSynapticWeight.toString());
                                          } else if (isMotorMenu) {
                                              linkMotorConnection(sldSynapticWeight.toString());
                                          }
                                          setState(() {});
                                          controller.notifyListeners(); // repaint canvas: update axon thickness
                                      }
                                  } catch (err) {}
                                },
                              ),
                      if (isShowingInfo == 0) const SizedBox(height: 16),
                      if (isShowingInfo != 0) ...[
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              padding: const EdgeInsets.all(0),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                                color: Colors.white,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.5),
                                    spreadRadius: 0.3,
                                    blurRadius: 0.3,
                                    offset: const Offset(1, 1), 
                                  ),
                                ],
                              ),
                              child: SvgPicture.asset("assets/icons/Info.svg"),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: BybHighlightedText(
                                dynamicInfoText,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  );
                }),
              ],
            ),
          ),
        ),
      )),
    );
    } else if (!isPlayingMenu && !isAnnotationMode &&
        (isLedMenu) &&
        controller.isSelectingEdge) {
      inlineWidgets.add(
        Positioned(
            top: safePaddingTop,
            right: (Platform.isIOS && safePadding > 0 ? safePadding : 20 + safePadding),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 7, 8, 3),
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Center(
                      child: Text("Select Lights and Color to Display",
                          style: TextStyle(fontSize: 17)),
                    ),
                    const SizedBox(height: 10),
                    const Divider(height: 2),
                    // V23: Unified LED Control Widget
                    SizedBox(
                      width: 360,
                      child: LEDControlWidget(
                        activeLights: _robotLedActive,
                        initialHex: _robotLedHex,
                        initialBrightness: _robotLedBrightness,
                        infoState: isShowingInfo,
                        onLightToggled: (index) {
                          List<String> chars = _robotLedActive.split('');
                          chars[index] = chars[index] == "1" ? "0" : "1";
                          _robotLedActive = chars.join('');
                          if (!isLoadingBrain && !isSettlingAfterLoad) brainHasUnsavedChanges.value = true; // LED light toggled
                          _updateLedAddress();
                        },
                        onColorChanged: (hex, brit) {
                          if (!isLoadingBrain && !isSettlingAfterLoad) brainHasUnsavedChanges.value = true; // LED color/brightness changed
                          _updateLedColor(hex, brit);
                          // Live update: repaint the selected LED axon immediately
                          if (controller.isSelectingEdge) {
                            double brightness = double.tryParse(brit) ?? 1.0;
                            double strength = brightness * 100.0;
                            Color ledColor = Color(int.parse("0xFF$hex")).withOpacity(brightness);
                            var edge = controller.edgeSelected!;
                            if (edge.to == nodeSingleLed.key || 
                                edge.to == nodeRedLed.key || 
                                edge.to == nodeGreenLed.key || 
                                edge.to == nodeBlueLed.key) {
                              edge.connectionStrength = strength;
                              edge.color = ledColor;
                              edge.isLedEdge = true;
                              // Invalidate the edge renderer's cached picture so
                              // the gradient repaints with the new color + thickness.
                              controller.notifyListeners();
                            }
                          }
                        },
                        onInteractionStart: () async {
                          if (buttonOnPressedSource != null) {
                            await soloud?.play(buttonOnPressedSource!);
                          }
                        },
                        onInteractionEnd: () async {
                          if (buttonPopSource != null) {
                            await soloud?.play(buttonPopSource!);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            )),
      );
    }

    if (!isPlayingMenu && isDeleteMenu) {
      Offset screenPos = Offset.zero;
      Offset? clusterTopCenter;

      if (controller.selection.isNotEmpty) {
        // Node Selected: Hover explicitly above the top center using True matrix scale
        var selectedNode = controller.selection.first;
        Offset topCenter = selectedNode.offset + Offset(neuronDrawSize / 2, -20 / controller.getScale());
        screenPos = MatrixUtils.transformPoint(controller.transform.value, topCenter);
      } else if (controller.isSelectingEdge && (controller.multiEdgeSelection.isNotEmpty || controller.edgeSelected != null)) {
        // Edge/Trunk Selected: Position menu precisely over the connection geometry
        Set<InfiniteCanvasEdge> edgesToConsider = controller.multiEdgeSelection.isNotEmpty ? controller.multiEdgeSelection : {controller.edgeSelected!};

        if (edgesToConsider.isNotEmpty) {
            // V25 FEATURE: Axon Context Menu Position Tuning (User Request)
            // Anchor both X and Y directly above the HIGHEST reaching endpoint in the 
            // entire selected cluster, so the menu floats cleanly above everything.
            
            double highestY = double.infinity;
            double targetXForHighestY = 0;
            
            double minX = double.infinity;
            double maxX = -double.infinity;
            
            // Re-evaluate all edges and their endpoints (Sources and Targets)
            for (var edge in edgesToConsider) {
                // Check Source Node
                InfiniteCanvasNode? nFrom = findNeuronByKeySafe(edge.from);
                if (nFrom != null) {
                    double sourceY = nFrom.offset.dy;
                    if (sourceY < highestY) {
                         highestY = sourceY;
                         targetXForHighestY = nFrom.offset.dx + (neuronDrawSize / 2.0);
                    }
                    if (nFrom.offset.dx < minX) minX = nFrom.offset.dx;
                    if (nFrom.offset.dx > maxX) maxX = nFrom.offset.dx;
                }
                
                // Check Target Node
                InfiniteCanvasNode? nTo = findNeuronByKeySafe(edge.to);
                if (nTo != null) {
                   double targetY = nTo.offset.dy;
                   if (targetY < highestY) {
                        highestY = targetY;
                        targetXForHighestY = nTo.offset.dx + (neuronDrawSize / 2.0);
                   }
                   if (nTo.offset.dx < minX) minX = nTo.offset.dx;
                   if (nTo.offset.dx > maxX) maxX = nTo.offset.dx;
                }
            }
            
            if (highestY != double.infinity && targetXForHighestY != 0) {
                // 25% way to the center of the bounding box
                double centerX = minX + (maxX - minX) / 2.0 + (neuronDrawSize / 2.0);
                double finalX = targetXForHighestY + (centerX - targetXForHighestY) * 0.25;
                
                // Shift down an extra 5 pixels so the menu hovers cleanly over the highest point instead of floating 10px too high
                clusterTopCenter = Offset(finalX, highestY + (5 / controller.getScale()));
            }
        }
        
        // clusterTopCenter calculation complete above
      }

      // V25 FEATURE: Wrap the Context Menu in an AnimatedBuilder tied to the Camera Transform.
      // This forces the Menu to continuously recalculate its pixel rendering relative to the 
      // underlying Node/Axon whenever the user scrubs the Background!
      bool isHardwarePeripheral = controller.selection.isNotEmpty && controller.selection.first.isSensory == 1;
      
      if (!isAnnotationMode && (clusterTopCenter != null || (controller.selection.isNotEmpty && !isHardwarePeripheral))) {
        inlineWidgets.insert(0, Positioned(
          top: 0,
          left: 0,
          child: AnimatedBuilder(
            animation: controller.transform,
            builder: (context, child) {
              Offset currentScreenPos = Offset.zero;
              
              if (controller.selection.isNotEmpty) {
                  var sNode = controller.selection.first;
                  Offset topC = sNode.offset + Offset(neuronDrawSize / 2, -20 / controller.getScale());
                  currentScreenPos = MatrixUtils.transformPoint(controller.transform.value, topC);
              } else if (clusterTopCenter != null) {
                  currentScreenPos = MatrixUtils.transformPoint(controller.transform.value, clusterTopCenter!);
              }
              
              if (currentScreenPos == Offset.zero) return const SizedBox();

              return Transform.translate(
                offset: currentScreenPos,
                child: FractionalTranslation(
                  translation: const Offset(-0.5, -1.0), // Shift up by its full height and center horizontally
                  child: ContextMenuWidget(
                        isShowingInfo: isShowingInfo != 0,
              onPressSound: () {
                if (buttonOnPressedSource != null) soloud?.play(buttonOnPressedSource!, looping: false);
              },
              isCloneVisible: controller.selection.isNotEmpty, // Only allow neuron cloning
              onClonePressed: () {
                if (controller.selection.isNotEmpty) {
                  var baseNode = controller.selection.first;
                  
                  // Calculate vector towards the central brain drop target
                  Offset canvasCenter = Offset(brainPosition.dx + 245, brainPosition.dy + 240);
                  double dx = canvasCenter.dx - baseNode.offset.dx;
                  double dy = canvasCenter.dy - baseNode.offset.dy;
                  double dist = sqrt(dx * dx + dy * dy);
                  double targetRadius = neuronDrawSize + 25.0; // Distance to next clone
                  
                  Offset cloneOffset;
                  if (dist > 1.0) {
                      // Move clone along vector pointing towards the center + slight jitter
                      cloneOffset = baseNode.offset + Offset(
                          (dx / dist) * targetRadius + (Random().nextInt(30) - 15),
                          (dy / dist) * targetRadius + (Random().nextInt(30) - 15)
                      );
                  } else {
                      // Fallback if exactly at center
                      cloneOffset = Offset(
                        baseNode.offset.dx + targetRadius + (Random().nextInt(30) - 15), 
                        baseNode.offset.dy + (Random().nextInt(30) - 15)
                      );
                  }
                  
                  neuronSize++; // Increment expected payload buffer size like a drag drop

                  UniqueKey newNodeKey = UniqueKey();
                  neuronsKey.add(newNodeKey);
                  String newId = newNodeKey.toString();
                  
                  // Initialize maps with default exactly like onAcceptWithDetails
                  mapDelayNeuronList.add(-1);
                  mapRhytmicNeuronList.add(-1);
                  mapCountingNeuronList.add(-1);

                  // Extract base data indices to safely copy the specialized maps by traversing the synthetic array
                  int baseIdx = -1;
                  for (int i = 0; i < syntheticNeuronList.length; i++) {
                    if (syntheticNeuronList[i].node?.id == baseNode.id) {
                      baseIdx = i;
                      break;
                    }
                  }
                  if (baseIdx >= 0 && baseIdx < mapDelayNeuronList.length - 1) { // -1 because we just added a new element
                      mapDelayNeuronList[mapDelayNeuronList.length - 1] = mapDelayNeuronList[baseIdx];
                      mapRhytmicNeuronList[mapRhytmicNeuronList.length - 1] = mapRhytmicNeuronList[baseIdx];
                      mapCountingNeuronList[mapCountingNeuronList.length - 1] = mapCountingNeuronList[baseIdx];
                  }

                  // Copy standard parameters
                  neuronTypes[newId] = neuronTypes[baseNode.id] ?? "Quiet";
                  
                  // Ensure the actively cached UI variables perfectly reflect the cloned values.
                  if (neuronTypes[newId] == "Delay") {
                      isShowDelayTime = true;
                      sldTimeValue = mapDelayNeuronList[mapDelayNeuronList.length - 1] > 0
                          ? mapDelayNeuronList[mapDelayNeuronList.length - 1].toDouble()
                          : 1000.0;
                      tecTimeValue.text = sldTimeValue.round().toString();
                  }
                  
                  neuronStyles[newId] = neuronStyles[baseNode.id] ?? "Excitatory";
                  aDesignArray[newId] = aDesignArray[baseNode.id] ?? 0.02;
                  bDesignArray[newId] = bDesignArray[baseNode.id] ?? 0.2;
                  bDesignArray[newId] = bDesignArray[baseNode.id] ?? 0.2;
                  cDesignArray[newId] = cDesignArray[baseNode.id] ?? -65.0;
                  dDesignArray[newId] = dDesignArray[baseNode.id] ?? 8.0;

                  if (mapRemoteControlNeuron.containsKey(baseNode.id)) {
                      mapRemoteControlNeuron[newId] = mapRemoteControlNeuron[baseNode.id]!;
                  }
                  if (mapMotionNeuron.containsKey(baseNode.id)) {
                      mapMotionNeuron[newId] = mapMotionNeuron[baseNode.id]!;
                  }

                  SyntheticNeuron syntheticNeuron = SyntheticNeuron(
                      isActive: false, isIO: false, circleRadius: neuronDrawSize / 2);
                  
                  InfiniteCanvasNode cloneNode = InfiniteCanvasNode(
                    key: newNodeKey,
                    label: baseNode.label,
                    value: neuronSize - 1,
                    allowMove: false,
                    allowResize: false,
                    offset: cloneOffset,
                    size: Size(neuronDrawSize, neuronDrawSize),
                    child: CustomPaint(
                      isComplex: !kIsWeb,
                      willChange: !kIsWeb,
                      painter: syntheticNeuron,
                    ),
                  );
                  
                  cloneNode.isExcitatory = baseNode.isExcitatory;
                  cloneNode.syntheticNeuron = syntheticNeuron;
                  syntheticNeuron.node = cloneNode;
                  syntheticNeuron.setupDrawingNeuron();
                  syntheticNeuronList.add(syntheticNeuron);
                  
                  SyntheticNeuron rawSyntheticNeuron = SyntheticNeuron(
                      isActive: false, isIO: false, circleRadius: neuronDrawSize / 2);
                  rawSyntheticNeuron.node = cloneNode;
                  rawSyntheticNeuron.copyDrawingNeuron(syntheticNeuron);
                  rawSyntheticNeuronList.add(rawSyntheticNeuron);
                  syntheticNeuron.rawSyntheticNeuron = rawSyntheticNeuron;

                  controller.add(cloneNode);
                  // Force canvas offset refresh
                  controller.nodes.last.offset = cloneOffset; 
                  
                  // CRITICAL FIX: Base sizes must match immediately BEFORE Native C starts
                  // so the engine preallocates accurate memory bounds for the new clone mappings
                  neuronSize = controller.nodes.length - allNeuronStartIdx;
                  
                  // Initialize Native C engine immediately matching new DragDrop
                  initNativeC(false);

                  // Keep original selected for multi-cloning
                  // Only re-sync the backend Engine with the new sizes
                  populateMatrix();
                  refreshNuclei();
                  
                  if (objectPlacedSource != null) {
                    Future.delayed(const Duration(milliseconds: 50), () async {
                      await soloud?.play(objectPlacedSource!);
                    });
                  }

                  populateMatrix();
                  refreshNuclei();
                  
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) setState(() {});
                    controller.notifyListeners();
                  });
                }
              },
              onDeletePressed: () {
                if (controller.selection.isNotEmpty) {
                  deleteNeuronCallback();
                  resetMouse();
                } else if (controller.isSelectingEdge) {
                  deleteEdgeCallback();
                  resetMouse();
                }
              },
            ),       // closes ContextMenuWidget
      ),             // closes FractionalTranslation
    );               // closes Transform.translate
      })));
    }
    }

    // ── Annotation Mode Panel ─────────────────────────────────────────────────
    if (isAnnotationMode) {
      final bool   _annIsLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
      final double annCardWidth = _annIsLandscape
          ? 300.0
          : (screenWidth - 40 - safePadding).clamp(300.0, 420.0);
      final int annTextMinLines = _annIsLandscape ? 3 : 2;
      final int annTextMaxLines = _annIsLandscape ? 7 : 6;

      // Helper — builds a tap button with icon row and label
      Widget _annBtn({
        required String label,
        Widget? icon,
        String? emoji,
        String? emojiFont,   // optional font for monochrome emoji (e.g. 'NotoEmoji')
        double emojiSize = 14,
        required Color bg,
        required Color fg,
        double height = 38,
        VoidCallback? onTap,
      }) {
        return GestureDetector(
          onTap: onTap,
          child: Container(
            height: height,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (emoji != null) Text(emoji, style: TextStyle(
                  fontSize: emojiSize, color: fg,
                  fontFamily: emojiFont,
                )),
                if (emoji != null) const SizedBox(width: 5),
                if (icon != null) icon,
                if (icon != null) const SizedBox(width: 5),
                Text(label, style: TextStyle(
                  color: fg, fontWeight: FontWeight.w600, fontSize: 13,
                  fontFamily: 'Roboto',
                )),
              ],
            ),
          ),
        );
      }

      // ── Nav button helpers ────────────────────────────────────────────────
      bool _hasPrev = _editingAnnotationIdx > 0;
      bool _hasNext = _editingAnnotationIdx < brainAnnotations.length - 1;

      Widget _navBtn({required String label, required bool active, required VoidCallback? onTap, bool isCenter = false, IconData? iconBefore, IconData? iconAfter}) {
        return GestureDetector(
          onTap: active ? onTap : null,
          child: Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            constraints: isCenter ? null : const BoxConstraints(minWidth: 72),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: active ? const Color(0xFFFD8164) : const Color(0xFFE8E8E8),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (iconBefore != null) Icon(iconBefore, size: 14, color: active ? Colors.white : Colors.grey.shade700),
                if (iconBefore != null) const SizedBox(width: 4),
                Text(label, style: TextStyle(
                  color: active ? Colors.white : Colors.grey.shade700,
                  fontWeight: FontWeight.w600, fontSize: 12,
                )),
                if (iconAfter != null) const SizedBox(width: 4),
                if (iconAfter != null) Icon(iconAfter, size: 14, color: active ? Colors.white : Colors.grey.shade700),
              ],
            ),
          ),
        );
      }

      inlineWidgets.add(Positioned(
        top: safePaddingTop,
        right: (Platform.isIOS && safePadding > 0 ? safePadding : 20 + safePadding),
        child: SizedBox(
          width: annCardWidth,
          // Focus widget captures arrow keys for prev/next navigation.
          // Returns KeyEventResult.handled for arrow keys so macOS does not
          // play a system alert when no other widget would consume them.
          child: Focus(
            focusNode: _annotationFocusNode,
            autofocus: _isEditingAnnotation,
            onKeyEvent: (node, event) {
              if (event is! KeyDownEvent) return KeyEventResult.ignored;
              if (_annotationEditEnabled) return KeyEventResult.ignored; // let text field handle
              final k = event.logicalKey;
              if (k == LogicalKeyboardKey.arrowLeft || k == LogicalKeyboardKey.arrowUp) {
                if (_hasPrev) _viewAnnotation(
                    brainAnnotations[_editingAnnotationIdx - 1],
                    _editingAnnotationIdx - 1);
                return KeyEventResult.handled; // always consume to silence macOS alert
              } else if (k == LogicalKeyboardKey.arrowRight || k == LogicalKeyboardKey.arrowDown) {
                if (_hasNext) _viewAnnotation(
                    brainAnnotations[_editingAnnotationIdx + 1],
                    _editingAnnotationIdx + 1);
                return KeyEventResult.handled;
              }
              return KeyEventResult.ignored;
            },
            child: Card(
                  elevation: 6,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // ── Title row: [X close] [title text] [spacer] ─────
                        Row(
                          children: [
                            GestureDetector(
                              onTap: _exitAnnotationMode,
                              behavior: HitTestBehavior.opaque,
                              child: Container(
                                width: 34, height: 34,
                                alignment: Alignment.center,
                                child: const Icon(Icons.close, size: 24, color: Colors.black),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                _isEditingAnnotation
                                    ? 'Annotation ${_editingAnnotationIdx + 1} of ${brainAnnotations.length}'
                                    : 'New Annotation',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.w800,
                                  fontFamily: 'Roboto', color: Colors.black87,
                                ),
                              ),
                            ),
                            const SizedBox(width: 34), // mirrors X button width for centering
                          ],
                        ),
                        const SizedBox(height: 8),

                        // ── VIEWING/EDITING an existing annotation ─────────
                        if (_isEditingAnnotation) ...[
                          // Nav row: [Prev] [Edit/Cancel] [Next] — all equal width
                          Row(children: [
                            Expanded(child: _navBtn(
                              label: 'Prev',
                              iconBefore: Icons.arrow_back_ios,
                              active: !_annotationEditEnabled && _hasPrev,
                              onTap: _hasPrev ? () => _viewAnnotation(
                                  brainAnnotations[_editingAnnotationIdx - 1],
                                  _editingAnnotationIdx - 1) : null,
                            )),
                            const SizedBox(width: 6),
                            Expanded(child: _annotationEditEnabled
                              ? _annBtn(
                                  label: 'Cancel',
                                  height: 36,
                                  onTap: () {
                                    final orig = brainAnnotations[_editingAnnotationIdx];
                                    _annotationDescController.text = orig.description;
                                    setState(() => _annotationEditEnabled = false);
                                    controller.annotationEditEnabled = false;
                                    _annotationFocusNode.requestFocus();
                                  },
                                  bg: Colors.grey.shade200, fg: Colors.black87,
                                )
                              : _annBtn(
                                  label: 'Edit',
                                  icon: const Icon(Icons.edit, size: 18, color: Colors.black87),
                                  height: 36,
                                  onTap: () {
                                    setState(() => _annotationEditEnabled = true);
                                    controller.annotationEditEnabled = true;
                                    // Jump to top so the user sees start of text in edit mode
                                    WidgetsBinding.instance.addPostFrameCallback((_) {
                                      if (_annotationScrollController.hasClients) {
                                        _annotationScrollController.jumpTo(0);
                                      }
                                    });
                                  },
                                  bg: Colors.white,
                                  fg: Colors.black87,
                                ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(child: _navBtn(
                              label: 'Next',
                              iconAfter: Icons.arrow_forward_ios,
                              active: !_annotationEditEnabled && _hasNext,
                              onTap: _hasNext ? () => _viewAnnotation(
                                  brainAnnotations[_editingAnnotationIdx + 1],
                                  _editingAnnotationIdx + 1) : null,
                            )),
                          ]),
                          const SizedBox(height: 10),
                        ] else ...[
                          // ── NEW ANNOTATION sub-header ───────────────────
                          const Text(
                            'Select neurons & synapses to annotate',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w700,
                              fontFamily: 'Roboto', color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],

                        // ── Description field (full card width) ─────────────
                        // VIEW mode: Scrollbar > SingleChildScrollView > SelectableText.
                        //   • Exactly ONE scrollbar track (no TextField internal one).
                        //   • Responds natively to scroll wheel and trackpad.
                        //   • ConstrainedBox caps height to match the maxLines height so
                        //     the card doesn't grow unbounded on long descriptions.
                        // EDIT mode: Listener forwards PointerScrollEvent → scrollController
                        //   so wheel/trackpad work while typing. TextField draws its own
                        //   single scroll indicator only when the content overflows.
                        if (!_annotationEditEnabled) ...[
                          Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8F1FA),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.only(top: 10, bottom: 10, right: 4),
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                maxHeight: annTextMaxLines * 22.0,
                              ),
                              child: MediaQuery.removePadding(
                                context: context,
                                removeRight: true,
                                removeLeft: true,
                                child: RawScrollbar(
                                  controller: _annotationScrollController,
                                  thumbVisibility: true,
                                  thumbColor: Colors.black38,
                                  radius: const Radius.circular(4),
                                  thickness: 4,
                                  child: SingleChildScrollView(
                                    controller: _annotationScrollController,
                                    child: Padding(
                                      padding: const EdgeInsets.only(left: 12, right: 12),
                                      child: SelectableText(
                                        _annotationDescController.text,
                                        style: const TextStyle(fontSize: 14, color: Colors.black87),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ] else ...[
                          Listener(
                            onPointerSignal: (event) {
                              if (event is PointerScrollEvent &&
                                  _annotationScrollController.hasClients) {
                                final double delta = event.scrollDelta.dy;
                                final double target = (_annotationScrollController.offset + delta)
                                    .clamp(0.0, _annotationScrollController.position.maxScrollExtent);
                                _annotationScrollController.jumpTo(target);
                              }
                            },
                            child: TextField(
                              controller: _annotationDescController,
                              scrollController: _annotationScrollController,
                              maxLines: annTextMaxLines,
                              minLines: annTextMinLines,
                              textInputAction: TextInputAction.done,
                              keyboardType: TextInputType.text,
                              textCapitalization: TextCapitalization.sentences,
                              decoration: InputDecoration(
                                hintText: 'Describe what the selected items do...',
                                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide.none),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
                              ),
                              style: const TextStyle(fontSize: 14, color: Colors.black87),
                            ),
                          ),
                        ],
                        const SizedBox(height: 10),

                        // ════════════════════════════════════════════════════
                        // NEW ANNOTATION — Cancel + Save Annotation
                        // ════════════════════════════════════════════════════
                        if (!_isEditingAnnotation) Row(children: [
                          Expanded(child: _annBtn(
                            label: 'Cancel', onTap: _exitAnnotationMode,
                            bg: Colors.grey.shade200, fg: Colors.black87,
                          )),
                          const SizedBox(width: 10),
                          Expanded(child: _annBtn(
                            label: 'Save Annotation', onTap: _saveAnnotation,
                            bg: const Color(0xFFFD8164), fg: Colors.white,
                          )),
                        ]),

                        // ════════════════════════════════════════════════════
                        // EDIT-ENABLED — Save Changes + Delete
                        // ════════════════════════════════════════════════════
                        if (_isEditingAnnotation && _annotationEditEnabled) Row(children: [
                          Expanded(child: _annBtn(
                            label: 'Save Changes',
                            onTap: _saveAnnotation,
                            bg: const Color(0xFFFD8164), fg: Colors.white,
                          )),
                          const SizedBox(width: 10),
                          Expanded(child: _annBtn(
                            label: 'Delete',
                            icon: SvgPicture.asset('assets/icons/Delete.svg',
                                width: 32, height: 32,
                                colorFilter: const ColorFilter.mode(
                                    Color(0xFFE96565), BlendMode.srcIn)),
                            onTap: _deleteEditingAnnotation,
                            bg: const Color(0xFFE96565).withOpacity(0.10),
                            fg: const Color(0xFFE96565),
                          )),
                        ]),
                      ],
                    ),
                  ),
                ),
          ),
        ),
      ));
    }


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

    // ... (rest of the build method setup) ...

    // Replaces the existing logic for left toolbar creation
    
    bool isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    if (isPlayingMenu) {
      liveToolBar = LiveLeftToolbar(
        key: rightToolbarKey, // Reusing key logic if applicable, or new key
        menuIdx: modeIdx, // Assuming modeIdx tracks selection
        isPlaying: isPlayingMenu,
        callback: leftToolbarCallback, // Reuse callback
        leftPadding: isLandscape ? safePaddingLeft : MediaQuery.of(context).padding.bottom,
        isLandscape: isLandscape,
      );
      leftToolBar = null; // Ensure only one is active
    } else {
      leftToolBar = LeftToolbar(
        key: rightToolbarGlobalKey,
        menuIdx: menuIdx,
        isPlaying: isPlayingMenu,
        callback: leftToolbarCallback,
        leftPadding: isLandscape ? safePaddingLeft : MediaQuery.of(context).padding.bottom,
        isLandscape: isLandscape,
      );
      liveToolBar = null;
    }

    // The unified layout handles Toolbar injection now

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
    // Iterate through all detected objects
    // Refactored Consolidated List & BYB Orange Logic
    leftAiListWidget = [];
    Set<String> uniqueTargets = {}; // Dedup set
    
    // 1. AI Objects Loop
    for (var recognition in aiObjectsInfo) {
      String key = recognition.label;
      // Skip if this object type isn't enabled in the menu (active flag check)
      int typeIndex = cameraMenuTypes.indexOf(key);
      if (typeIndex == -1 || !aiPositionFlags[typeIndex]) continue;

      // Add to set for later listing
      uniqueTargets.add(key);

      String aiIcon = lookup[key] ?? "?";
      
      // Dynamically calculate actual camera dimensions for perfect 1:1 overlay tracking
      bool isTabletDevice = MediaQuery.of(context).size.shortestSide >= 600;
      bool isPhonePort = !isTabletDevice && isCameraExpanded && !(MediaQuery.of(context).orientation == Orientation.landscape);
      bool useLandUI = (MediaQuery.of(context).orientation == Orientation.landscape) || isTabletDevice;
      double currentMaxWidth = MediaQuery.of(context).size.width * ((MediaQuery.of(context).orientation == Orientation.landscape) ? 0.70 : (isTabletDevice ? 0.90 : 0.95));
      double pipCamW = (Platform.isIOS || Platform.isAndroid) ? 200 : 213;
      double currentCamW = (useLandUI && isCameraExpanded) ? (currentMaxWidth - 140) : (isCameraExpanded ? currentMaxWidth : pipCamW); 
      double currentCamH = currentCamW * 0.75;
      if (!(MediaQuery.of(context).orientation == Orientation.landscape) && isCameraExpanded && !isPhonePort) {
          currentCamH *= 0.90;
          currentCamW *= 0.90;
      }
      
      // The TFLite engine stretches the 320x240 image into a 320x320 tensor.
      // Consequently, bounding box dy values are returned normalized dynamically to a 0-320 range vertically!
      double scaleX = currentCamW / 320.0;
      double scaleY = currentCamH / 320.0;
      
      // Center 25x25 overlay exactly on the native resolution coordinate point
      double rX = recognition.location.center.dx * scaleX - 12.5;
      double rY = recognition.location.center.dy * scaleY - 12.5; 

      aiPositionOverlays.add(Positioned(
        left: rX,
        top: rY,
        child: Container(
            width: 25,
            height: 25,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              color: Colors.white,
              boxShadow: [
                 // Standard Shadow (matches FAB/Play buttons)
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: const Offset(0, 2), 
                ),
              ],
            ),
            child: Align(
                alignment: Alignment.center,
                child: Padding(
                    padding: const EdgeInsets.only(bottom: 2), 
                    child: Text(aiIcon, textAlign: TextAlign.center, style: const TextStyle(fontSize: 15, fontFamily: "NotoEmoji"))
                )
            )
        )
      ));
    }

    // 2. Colors Loop
    leftColorListWidget = []; // Unused but cleared for safety
    List<Widget> colorPositionOverlays = []; 
    
    for (int index = 0; index < 3; index++) {
      if (!colorPositionFlags[index]) continue;
      if ((_DesignBrainPageState.currentActiveColors & (1 << index)) == 0) continue;

      Color overlayColor = Colors.transparent; 
      String colorLabel = "";

      if (index == 0) { overlayColor = const Color(0xFF1996FC); colorLabel = "Blue"; }
      else if (index == 1) { overlayColor = const Color(0xFF55EE55); colorLabel = "Green"; }
      else if (index == 2) { overlayColor = const Color(0xFFFF4444); colorLabel = "Red"; }

      bool colorFound = false;
      for (int k = 0; k < 5; k++) {
        int baseIdx = (index * 5 + k) * 5;
        if (baseIdx + 4 >= ImagePreprocessor.centroids.length) break;
        
        if (ImagePreprocessor.centroids[baseIdx + 2] >= 12) {
             colorFound = true;
             // Dynamically calculate actual camera dimensions for perfect 1:1 overlay tracking
             bool isTabletDevice = MediaQuery.of(context).size.shortestSide >= 600;
             bool isPhonePort = !isTabletDevice && isCameraExpanded && !(MediaQuery.of(context).orientation == Orientation.landscape);
             bool useLandUI = (MediaQuery.of(context).orientation == Orientation.landscape) || isTabletDevice;
             double currentMaxWidth = MediaQuery.of(context).size.width * ((MediaQuery.of(context).orientation == Orientation.landscape) ? 0.70 : (isTabletDevice ? 0.90 : 0.95));
             double pipCamW = (Platform.isIOS || Platform.isAndroid) ? 200 : 213;
             double currentCamW = (useLandUI && isCameraExpanded) ? (currentMaxWidth - 140) : (isCameraExpanded ? currentMaxWidth : pipCamW); 
             double currentCamH = currentCamW * 0.75;
             if (!(MediaQuery.of(context).orientation == Orientation.landscape) && isCameraExpanded && !isPhonePort) {
                 currentCamH *= 0.90;
                 currentCamW *= 0.90;
             }
             double scaleX = currentCamW / 320.0;
             double scaleY = currentCamH / 240.0;
             
             // 10x10 circle, offset by exactly -5 to hit true geometric center
             double rX = ImagePreprocessor.centroids[baseIdx].toDouble() * scaleX - 5.0;
             double rY = ImagePreprocessor.centroids[baseIdx + 1].toDouble() * scaleY - 5.0;
             
             colorPositionOverlays.add(Positioned(
                left: rX,
                top: rY,
                child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: overlayColor,
                    ),
                  )
             ));
        }
      }
      if (colorFound) {
          uniqueTargets.add(colorLabel);
      }
    }

    // 3. Build Unified List
    if (uniqueTargets.isNotEmpty) {
        for (String target in uniqueTargets) {
             Widget icon = const SizedBox();
             if (target == "Blue") {
                 icon = Container(width: 15, height: 15, decoration: const BoxDecoration(color: Color(0xFF1996FC), shape: BoxShape.circle));
             } else if (target == "Green") {
                 icon = Container(width: 15, height: 15, decoration: const BoxDecoration(color: Color(0xFF55EE55), shape: BoxShape.circle));
             } else if (target == "Red") {
                 icon = Container(width: 15, height: 15, decoration: const BoxDecoration(color: Color(0xFFFF4444), shape: BoxShape.circle));
             } else {
                 String aiIcon = lookup[target] ?? "?";
                 // Use NotoEmoji as requested
                 icon = SizedBox(width: 20, height: 20, child: Center(child: Text(aiIcon, style: const TextStyle(fontSize: 14, fontFamily: "NotoEmoji"))));
             }
             
            leftAiListWidget.add(Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    icon,
                    const SizedBox(width: 4),
                    Text(target, style: const TextStyle(fontFamily: "NotoEmoji")),
                  ],
                )
            ));
        }
    } else {
       leftAiListWidget.add(const SizedBox(height: 20));
    }

    List<Widget> floatingButtons = [
      if (controller.isPlaying && _hasUnboundRemoteNeurons && (MediaQuery.of(context).size.shortestSide < 600 && (Platform.isIOS || Platform.isAndroid))) 
        FloatingActionButton(
          shape: const CircleBorder(),
          hoverElevation: 1,
          elevation: 0,
          backgroundColor: const Color(0xFFFD8164),
          onPressed: () async {},
          child: GestureDetector(
            onTapDown: (_) async {
              if (buttonOnPressedSource != null) {
                buttonOnPressedHandle = await soloud?.play(buttonOnPressedSource!, looping: false);
              }
              setState(() => _remoteTriggerPressed = true);
              _updateRemoteControlNeurons();
            },
            onTapUp: (_) async {
              if (buttonPopSource != null) {
                buttonOnPressedHandle = await soloud?.play(buttonPopSource!, looping: false);
              }
              setState(() => _remoteTriggerPressed = false);
              Future.delayed(const Duration(milliseconds: 16), _updateRemoteControlNeurons);
            },
            onTapCancel: () {
              setState(() => _remoteTriggerPressed = false);
              Future.delayed(const Duration(milliseconds: 16), _updateRemoteControlNeurons);
            },
            child: Opacity(
              opacity: _remoteTriggerPressed ? 0.7 : 1.0,
              child: SvgPicture.asset(
                "assets/icons/remoteControlKeys/RemoteControl.svg",
                colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
              ),
            ),
          ),
        ),
      FloatingActionButton(
        shape: const CircleBorder(),
        hoverElevation: 1,
        elevation: 0,
        backgroundColor: isShowingInfo == 2
            ? Colors.black
            : Theme.of(context).floatingActionButtonTheme.backgroundColor,
        onPressed: () async {},
        child: GestureDetector(
          onTapUp: (details) async {
            if (buttonPopSource != null) {
              buttonOnPressedHandle =
                  await soloud?.play(buttonPopSource!, looping: false);
            }
            isShowingInfo = (isShowingInfo == 1) ? 0 : 1;
            if (isShowingInfo == 2) {
              InfiniteCanvasEdge.isShowingInfo = true;
              InfiniteCanvasNode.isShowingInfo = true;
            } else {
              InfiniteCanvasEdge.isShowingInfo = false;
              InfiniteCanvasNode.isShowingInfo = false;
            }
            setState(() {});
          },
          onTapDown: (details) async {
            if (buttonOnPressedSource != null) {
              buttonOnPressedHandle =
                  await soloud?.play(buttonOnPressedSource!, looping: false);
            }
          },
          child: SvgPicture.asset(
            isShowingInfo == 0
                ? "assets/icons/InfoDisabled.svg"
                : isShowingInfo == 1
                    ? "assets/icons/Info.svg"
                    : "assets/icons/InfoLabels.svg",
          ),
        ),
      ),
      if (!isSimulatingBrain) ...[
        FloatingActionButton(
          shape: const CircleBorder(),
          hoverElevation: 1,
          elevation: 0,

          onPressed: () {
            return;
          },
          child: GestureDetector(
            onTapUp: (details) async {
              if (buttonPopSource != null) {
                if (buttonPopHandle != null) {
                  soloud?.stop(buttonPopHandle!);
                }

                buttonPopHandle =
                    await soloud?.play(buttonPopSource!, looping: false);
              }
              if (isPlayingMenu) return;

              await Future.delayed(const Duration(milliseconds: 100), () {});

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

              if (isAnnotationMode) _exitAnnotationMode();
              currentBrainAnnotations = brainAnnotations;
              onAddAnnotationRequested = _enterAnnotationMode;
              onAnnotationsModified = () { setState(() { brainHasUnsavedChanges.value = true; }); };
              onAnnotationViewRequested = (ann, idx) { _viewAnnotation(ann, idx); };
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
                buttonOnPressedHandle =
                    await soloud?.play(buttonOnPressedSource!, looping: false);
              }
              // });
            },
            child: SvgPicture.asset(
              "assets/icons/LabNotebook.svg",
            ),
          ),
        ),
      ],
      FloatingActionButton(
          shape: const CircleBorder(),
          hoverElevation: 1,
          elevation: 0,
          onPressed: () {},
          child: GestureDetector(
            onTapDown: (details) async {
              if (isPreventPlayClick) return;
              if (buttonOnPressedSource != null) {
                if (buttonOnPressedHandle != null) {
                  soloud?.stop(buttonOnPressedHandle!);
                }

                buttonOnPressedHandle =
                    await soloud?.play(buttonOnPressedSource!, looping: false);
              }
            },
            onTapUp: (details) async {
              if (isPreventPlayClick) return;
              if (buttonPopSource != null) {
                if (buttonPopHandle != null) {
                  soloud?.stop(buttonPopHandle!);
                }

                buttonPopHandle =
                    await soloud?.play(buttonPopSource!, looping: false);
              }

              isEmergencyPause = !isEmergencyPause;
              if (!isEmergencyPause) {
                rightToolbarCallback({"menuIdx": 7});
                Future.delayed(const Duration(milliseconds: 100), () {
                  menuIdx = 0;
                  controller.isInteractable = true;

                  // Restore wave plot from persisted pins
                  if (placedPins.isNotEmpty) {
                    // Find orange pin (type 10) and blue pin (type 11)
                    int restoredIdx1 = -1;
                    int restoredIdx2 = -1;
                    placedPins.forEach((neuronIdx, pinType) {
                      if (pinType == 10) restoredIdx1 = neuronIdx;
                      if (pinType == 11) restoredIdx2 = neuronIdx;
                    });

                    // Re-register with native side
                    if (restoredIdx1 != -1) {
                      nativec.changeIdxSelected(restoredIdx1);
                      currentWaveNeuronIdx = restoredIdx1;
                    }
                    if (restoredIdx2 != -1) {
                      nativec.changeIdxSelected2(restoredIdx2);
                      currentWaveNeuronIdx2 = restoredIdx2;
                    }

                    // Rebuild wave widget if any pin exists
                    if (restoredIdx1 != -1 || restoredIdx2 != -1) {
                      waveWidget = WaveWidget(
                        key: ValueKey("${currentWaveNeuronIdx}_$currentWaveNeuronIdx2"),
                        valueNotifier: waveRedraw,
                        chartGain: chartGain,
                        levelMedian: levelMedian,
                        screenWidth: screenWidth,
                        screenHeight: screenHeight,
                        neuronIdx1: currentWaveNeuronIdx,
                        neuronIdx2: currentWaveNeuronIdx2,
                        initialVisibleSeconds: currentWaveZoom,
                        onVisibleSecondsChanged: (s) => currentWaveZoom = s,
                      );
                    }
                  }

                  setState(() {});
                });
              } else {
                rightToolbarCallback({"menuIdx": 7});
                debouncerNoResponse.cancel();
                controller.isInteractable = true;

                // Pins persist across pause — only clear the hovering indicator
                hoveringPinNeuronIdx = -1;
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
    List<Widget> baseWidgets = [
      Positioned(
        left: 0,
        top: 0,
        bottom: 0, 
        right: 0,
        child: Screenshot(
          controller: screenshotController,
          child: mainBody,
        ),
      ),
    ];
    widgets.insertAll(0, baseWidgets);
    widgets.insertAll(1, inlineWidgets);

    // ── EXPANDING LIVE CAMERA WIDGET (Must render BEFORE UI overlays) ── //
    if (isPlayingMenu) {
      bool isTablet = MediaQuery.of(context).size.shortestSide >= 600;
      bool isiPhoneExpandedPortrait = !isTablet && isCameraExpanded && !isLandscape;
      bool useLandscapeUI = isLandscape || isTablet;

      double pipCamWidth = (Platform.isIOS || Platform.isAndroid) ? 200 : 213;
      double pipCamHeight = (Platform.isIOS || Platform.isAndroid) ? 150 : 160;
      
      // Card width scaling logic decoupled between Landscape and Portrait
      double portraitMaxCardWidth = isTablet ? 0.90 : 0.95;
      double maxCardWidth = MediaQuery.of(context).size.width * (isLandscape ? 0.70 : portraitMaxCardWidth);
      double maxCardHeight = MediaQuery.of(context).size.height * (isLandscape ? 0.85 : 0.88);

      double cameraWidth = (useLandscapeUI && isCameraExpanded) ? (maxCardWidth - 140) : (isCameraExpanded ? maxCardWidth : pipCamWidth); 
      double cameraHeight = cameraWidth * 0.75; // Lock camera stream to 4:3
      
      // Proportional 10% global viewport reduction for Expanded Portrait
      if (!isLandscape && isCameraExpanded && !isiPhoneExpandedPortrait) {
          cameraHeight *= 0.90;
          cameraWidth *= 0.90;
      }
      
      // Vertical space buffer for titles, padding, and UI wrap
      double uiOverheadHeight = useLandscapeUI ? 30.0 : 80.0;
      
      // Prevent vertical overflow by shifting the bottleneck if necessary
      if (isCameraExpanded && (cameraHeight * 1.6 + uiOverheadHeight) > maxCardHeight) {
          cameraHeight = (maxCardHeight - uiOverheadHeight) / 1.6;
          cameraWidth = cameraHeight * (4.0 / 3.0);
      }
      
      double waveHeightTarget = isiPhoneExpandedPortrait ? 150.0 : cameraHeight * 0.6; // Scale plot dynamically
      
      // Add + 16 for internal paddings for expanded frame 
      double expandedWidth = useLandscapeUI ? (cameraWidth + 148) : (cameraWidth + 16);
      // Ensure bottom landscape elements mathematically mirror the upper elements 
      double syncTargetWidth = pipCamWidth + 130;
      
      // Calculate dynamic three-column width for unexpanded Tablet Portrait layout (Tight bounds matching for perfectly symmetrical side padding mappings)
      double unexpandedWidth = (!isLandscape && isTablet) ? (pipCamWidth + syncTargetWidth + 194) : 
                               (!isLandscape && !isTablet) ? MediaQuery.of(context).size.width - 8 : 
                               (syncTargetWidth + 16);
      double expandedHeight = cameraHeight + waveHeightTarget + uiOverheadHeight + 16;
      
      double unexpandedLeft = (!isLandscape) 
          ? (MediaQuery.of(context).size.width - unexpandedWidth) / 2
          : MediaQuery.of(context).size.width - safePadding - unexpandedWidth;
      
      widgets.add(AnimatedPositioned(
        duration: const Duration(milliseconds: 1000),
                              curve: Curves.easeInOut,
        // Always bind exclusively to `left` when toggling! Swapping anchor points (left <-> right) instantly breaks the Tween layout trajectory natively.
        left: isCameraExpanded ? (isLandscape ? (isTablet ? 90.0 : MediaQuery.of(context).padding.left + 85.0) : (MediaQuery.of(context).size.width - expandedWidth) / 2) : (unexpandedLeft < 0 ? 0 : unexpandedLeft),
        top: isCameraExpanded ? (isLandscape ? MediaQuery.of(context).padding.top : MediaQuery.of(context).size.height - expandedHeight - (isiPhoneExpandedPortrait ? 170 : 145)) : MediaQuery.of(context).padding.top,
        width: isCameraExpanded ? expandedWidth : unexpandedWidth, 
        child: Card(
          clipBehavior: Clip.hardEdge,
          elevation: isCameraExpanded ? 12 : 4,
          margin: const EdgeInsets.all(4.0),
          child: Padding(
            padding: const EdgeInsets.all(3.0),
              child: Stack(
              alignment: Alignment.topRight, 
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 1000),
                              curve: Curves.easeInOut,
                  width: isCameraExpanded ? expandedWidth - 14 : unexpandedWidth - 14, 
                  child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    // --- UNIVERSAL TITLE BAR AND BATTERY ---
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 1000),
                              curve: Curves.easeInOut,
                      width: isCameraExpanded ? expandedWidth - 14 : unexpandedWidth - 14,
                      height: 24, 
                      padding: const EdgeInsets.only(left: 2),
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                              Row(
                                children: [
                                  if (!wifiName.contains("No SpikerBot Detected"))
                                    GestureDetector(
                                        onTap: _showRenameDialog,
                                        child: SizedBox(
                                          width: 40, height: 24, 
                                          child: OverflowBox(
                                            maxHeight: 40, maxWidth: 40,
                                            child: Container(
                                                width: 40, height: 40, alignment: Alignment.center, padding: const EdgeInsets.only(right: 5),
                                                child: const Icon(Icons.edit, size: 24, color: Colors.black87)
                                            ),
                                          ),
                                        )
                                    ),
                                  Text(wifiName, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold)),
                                ]
                              ),
                              Row(
                                children: [
                                   if (isRobotConnected) ...[
                                       Container(
                                          width: 32, height: 18,
                                          decoration: BoxDecoration(border: Border.all(color: Colors.black, width: 2), borderRadius: BorderRadius.circular(3)),
                                          padding: const EdgeInsets.all(2),
                                          child: Align(
                                              alignment: Alignment.centerLeft,
                                              child: Container(width: 24 * (batteryPercent/100.0), color: batteryPercent <= 25 ? Colors.red : Colors.black)
                                          )
                                       ),
                                       Container(width: 2, height: 6, color: Colors.black),
                                       const SizedBox(width: 4),
                                       Text("$batteryPercent%", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                       const SizedBox(width: 8),
                                   ],
                                   AnimatedBuilder(
                                     animation: _canvasAnimController,
                                     builder: (context, child) {
                                       bool isAnim = _canvasAnimController.isAnimating;
                                       return AnimatedOpacity(
                                         duration: const Duration(milliseconds: 150),
                                         opacity: isAnim ? 0.0 : 1.0,
                                         child: IgnorePointer(
                                           ignoring: isAnim,
                                           child: GestureDetector(
                                              onTap: () {
                                                 setState(() { isCameraExpanded = !isCameraExpanded; });
                                                 _animateCanvasToReset(true, animate: true);
                                              },
                                              child: Icon(isCameraExpanded ? Icons.close_fullscreen : Icons.open_in_full, size: 20, color: Colors.black87)
                                           ),
                                         ),
                                       );
                                     }
                                   ),
                                   const SizedBox(width: 4),
                                ],
                              ),
                          ]
                      ),
                    ),
                    const SizedBox(height: 2), 
                    
                    // --- DYNAMIC CONTENT GRID ---
                    Builder(builder: (context) {
                        Widget waveBlock = AnimatedContainer(
                          duration: const Duration(milliseconds: 1000),
                              curve: Curves.easeInOut,
                          clipBehavior: Clip.hardEdge,
                          margin: const EdgeInsets.all(3.0),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          height: isCameraExpanded 
                               ? waveHeightTarget 
                               : ((Platform.isIOS || Platform.isAndroid) ? 150 : 160),
                          width: isCameraExpanded 
                               ? expandedWidth 
                               : (!isLandscape && !isTablet) ? unexpandedWidth - 14 : syncTargetWidth - 6,
                          child: waveWidget,
                        );

                        // The remote trigger block was extracted into a universal Floating layout element natively spanning both modes.
                        Widget remoteTriggerBlock = const SizedBox();

                        Widget cameraBlock = Column(
                          key: _cameraBlockKey,
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AnimatedContainer(
                            duration: const Duration(milliseconds: 1000),
                              curve: Curves.easeInOut,
                            // Scale the actual camera stream up exponentially (Strict 4:3 preservation)
                            width: isCameraExpanded ? cameraWidth : pipCamWidth,
                            height: isCameraExpanded ? cameraHeight : pipCamHeight,
                            margin: const EdgeInsets.fromLTRB(2, 0, 2, 1), 
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  mjpegComponent,
                                  if (debugCvImage != null && isShowingInfo == 1)
                                    Positioned.fill(
                                      child: Opacity(
                                        opacity: 1.0,
                                        child: Container(
                                          child: Image.memory(
                                            debugCvImage!,
                                            gaplessPlayback: true,
                                            fit: BoxFit.fill,
                                          ),
                                        ),
                                      ),
                                    ),
                                  if (debugCvImage != null && isShowingInfo == 1)
                                    Positioned.fill(
                                      child: CustomPaint(
                                        painter: ObjectHighlightPainter(
                                          results: results,
                                          activeLabels: () {
                                            Set<String> labels = {};
                                            List<String> aiLabels = ["person", "backpack", "bottle", "cup", "bowl", "banana", "apple", "orange", "chair", "couch", "potted plant", "laptop", "cell phone", "book", "vase", "dog", "cat", "tv", "mouse", "keyboard", "scissors", "donut", "pizza", "hot dog", "car", "motorcycle", "airplane", "bus", "train", "truck", "boat", "traffic light", "stop sign", "bird", "horse", "sheep", "cow", "elephant", "bear", "zebra", "giraffe", "umbrella", "handbag", "tie", "suitcase", "frisbee", "skis", "snowboard", "sports ball", "kite", "baseball bat", "baseball glove", "skateboard", "surfboard", "tennis racket", "wine glass", "fork", "knife", "spoon", "sandwich", "broccoli", "carrot", "cake", "bed", "dining table", "toilet", "remote", "microwave", "oven", "toaster", "sink", "refrigerator", "clock"];
                                            for (var val in mapSensoryNeuron.values) {
                                              if (val is int && val >= 7 && val < 7 + aiLabels.length) {
                                                labels.add(aiLabels[val - 7]);
                                              }
                                            }
                                            return labels;
                                          }()
                                        ),
                                      ),
                                    ),
                                  if (isShowingInfo == 1)
                                    Positioned.fill(
                                        child: IgnorePointer(
                                      child: Container(
                                        decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            border: Border.all(
                                                color: Colors.black, width: 3)),
                                        ),
                                      ),
                                    ),

                                  ...colorPositionOverlays,
                                  ...aiPositionOverlays,
                                ],
                              ),
                              ),
                             ),
                             if (isShowingInfo == 1)
                             ..._DesignBrainPageState.mapSensoryNeuron.entries.map((entry) {
                                 String key = entry.key;
                                 int val = entry.value; 
                                 String? areaMode = _DesignBrainPageState.mapAreaSize[key];
                                 if (areaMode == null) return const SizedBox();
                                 
                                 List<String> modes = areaMode.split("_@_");
                                 if (modes.isEmpty) return const SizedBox();
                                 
                                 double start = 0;
                                 double end = 0;
                                 
                                 double currentCamWidth = isCameraExpanded ? cameraWidth : pipCamWidth;
                                 double scaleX = currentCamWidth / 320.0;
                                 
                                 if (modes[0] == "Left" || modes[0] == "Right" || modes[0] == "Custom") {
                                     int p1 = int.parse(modes[1]);
                                     int p2 = int.parse(modes[2]);
                                     start = (p1 < p2 ? p1 : p2).toDouble();
                                     end = (p1 < p2 ? p2 : p1).toDouble();
                                 } else if (modes[0] == "Any") {
                                     start = 0;
                                     end = 320;
                                 } else {
                                     return const SizedBox();
                                 }
                                 
                                 Color barColor = const Color(0xFFFD8164);
                                 if (val == 0) barColor = Colors.blue; 
                                 if (val == 2) barColor = Colors.green; 
                                 if (val == 4) barColor = Colors.red;

                                 return AnimatedContainer(
                                     duration: const Duration(milliseconds: 1000),
                              curve: Curves.easeInOut,
                                     width: currentCamWidth,
                                     height: 4,
                                     margin: const EdgeInsets.fromLTRB(2, 1, 2, 0), 
                                     alignment: Alignment.centerLeft,
                                     child: AnimatedContainer(
                                         duration: const Duration(milliseconds: 1000),
                              curve: Curves.easeInOut,
                                         margin: EdgeInsets.only(left: start * scaleX),
                                         width: (end - start) * scaleX,
                                         height: 4,
                                         color: barColor.withOpacity(0.8),
                                     ),
                                 );
                             }).toList(),
                           ],
                        );

                        Widget aiTargetsBlock = AnimatedContainer(
                            duration: const Duration(milliseconds: 1000),
                            curve: Curves.easeInOut,
                            width: isiPhoneExpandedPortrait ? expandedWidth - 14 : isCameraExpanded ? (useLandscapeUI ? 120 : expandedWidth) : (!isLandscape && !isTablet ? null : 124),
                            padding: isiPhoneExpandedPortrait ? const EdgeInsets.only(top: 8.0, bottom: 8.0) : const EdgeInsets.only(left: 0.0),
                            child: isiPhoneExpandedPortrait ? Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                    const Text("Visual\nTargets:", style: TextStyle(fontWeight: FontWeight.bold, height: 1.2)),
                                    const SizedBox(width: 12),
                                    Expanded(
                                        child: Wrap(
                                            spacing: 12.0,
                                            runSpacing: 0.0,
                                            children: leftAiListWidget.where((w) => w.runtimeType != SizedBox).map((w) {
                                                if (w is Padding && w.child is Row) {
                                                    Row row = w.child as Row;
                                                    return Row(
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: row.children,
                                                    );
                                                }
                                                return w;
                                            }).toList(),
                                        )
                                    )
                                ]
                            ) : Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (!useLandscapeUI && isCameraExpanded) const SizedBox(height: 5),
                                  const Text("Visual Targets:", softWrap: false, overflow: TextOverflow.visible, style: TextStyle(fontWeight: FontWeight.bold)),
                                  ...leftAiListWidget,
                                ]
                            )
                        );
                        
                        // Execute custom Row placement if Tablet Portrait Unexpanded
                        if (!isLandscape && isTablet && !isCameraExpanded) {
                            return Padding(
                              padding: const EdgeInsets.only(left: 6.0, right: 26.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                    Column(
                                        mainAxisAlignment: MainAxisAlignment.start,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                            cameraBlock,
                                        ]
                                    ),
                                    const SizedBox(width: 16),
                                    Column(
                                        mainAxisAlignment: MainAxisAlignment.start,
                                        children: [
                                            aiTargetsBlock,
                                        ]
                                    ),
                                    const SizedBox(width: 16),
                                    Column(
                                        mainAxisAlignment: MainAxisAlignment.start,
                                        children: [
                                            waveBlock,
                                            remoteTriggerBlock
                                        ]
                                    ),
                                ]
                              ),
                            );
                        }
                        
                        // Otherwise (Landscape, iPhone, or Expanded Mode), cleanly Wrap
                        return Wrap(
                          alignment: (!isLandscape && !isTablet) ? WrapAlignment.center : WrapAlignment.start,
                          crossAxisAlignment: WrapCrossAlignment.start, 
                          direction: Axis.horizontal,
                          children: [
                             if (!isLandscape && !isTablet && !isCameraExpanded)
                               SizedBox(
                                 width: unexpandedWidth - 14,
                                 child: Stack(
                                   children: [
                                      SizedBox(width: unexpandedWidth - 14, child: Center(child: cameraBlock)),
                                      Positioned(left: ((unexpandedWidth - 14) / 2) + 113, top: 0, child: aiTargetsBlock),
                                   ]
                                 )
                               )
                             else if (isiPhoneExpandedPortrait) ...[
                               cameraBlock,
                               aiTargetsBlock,
                             ] else ...[
                               SingleChildScrollView(
                                 scrollDirection: Axis.horizontal,
                                 physics: const NeverScrollableScrollPhysics(),
                                 child: Row(
                                   mainAxisSize: MainAxisSize.min,
                                   crossAxisAlignment: CrossAxisAlignment.start,
                                   children: [
                                     cameraBlock,
                                     if (useLandscapeUI) SizedBox(width: isCameraExpanded ? 8 : ((unexpandedWidth - 14) - (pipCamWidth + 4) - 124 > 0 ? (unexpandedWidth - 14) - (pipCamWidth + 4) - 124 : 0)),
                                     aiTargetsBlock,
                                   ]
                                 )
                               )
                             ],
                             waveBlock,
                             remoteTriggerBlock,
                          ],
                        );
                    }),
                    if (isShowingInfo == 1) ...[
                      Row(
                        children: [
                          Container(
                            width: 25,
                            height: 25,
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
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: BybHighlightedText(
                                "Drag pins onto different neurons to compare!",
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                )),
              ],
            ),
          ),
        ),
      ));
      
      // Floating Remote Trigger for Expanded Landscape/Portrait Modes (and forced identically for Unexpanded Tablet layouts)
      if ((isTablet || Platform.isMacOS || Platform.isWindows || Platform.isLinux) && controller.isPlaying && _hasUnboundRemoteNeurons) {
          double triggerWidth = isLandscape ? (unexpandedWidth - 60) : 240;
          widgets.add(AnimatedPositioned(
              duration: const Duration(milliseconds: 1000),
                              curve: Curves.easeInOut,
              right: isLandscape ? 50.0 + safePadding : null,
              left: isLandscape ? null : (MediaQuery.of(context).size.width - triggerWidth) / 2,
              bottom: isLandscape ? 20.0 + MediaQuery.of(context).padding.bottom : 20.0 + MediaQuery.of(context).padding.bottom,
              width: triggerWidth,
              height: 48,
              child: GestureDetector(
                onTapDown: (_) {
                  setState(() => _remoteTriggerPressed = true);
                  _updateRemoteControlNeurons(); 
                  if (soloud != null && buttonOnPressedSource != null) soloud?.play(buttonOnPressedSource!, looping: false);
                },
                onTapUp: (_) {
                  setState(() => _remoteTriggerPressed = false);
                  Future.delayed(const Duration(milliseconds: 16), _updateRemoteControlNeurons);
                  if (soloud != null && buttonPopSource != null) soloud?.play(buttonPopSource!, looping: false);
                },
                onTapCancel: () {
                  setState(() => _remoteTriggerPressed = false);
                  Future.delayed(const Duration(milliseconds: 16), _updateRemoteControlNeurons);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 80),
                  decoration: BoxDecoration(
                    color: _remoteTriggerPressed
                        ? const Color(0xFFE56A4F) // slightly darker orange
                        : const Color(0xFFFD8164), // signature orange
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 6,
                          offset: Offset(0, 3),
                        )
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SvgPicture.asset('assets/icons/Bolt.svg', width: 20, height: 20, colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn)),
                      SizedBox(width: 6),
                      Text(
                        'Remote Control Trigger',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          fontFamily: 'Roboto',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ));
      }
    }
    // ── Orientation-Responsive Disjoint Controls (Drag Menu + Buttons) ── //
    if (isLandscape) {
      widgets.add(Positioned(
        left: 0,
        top: 15 + safePaddingTop,
        child: IntrinsicWidth(
          child: (isPlayingMenu && liveToolBar != null) ? liveToolBar! : (leftToolBar ?? const SizedBox()),
        )
      ));
      widgets.add(Positioned(
        // In landscape, only add horizontal safe padding (Not notch + home bar)
        left: 15 + safePaddingLeft, 
        bottom: 15 + MediaQuery.of(context).padding.bottom,
        child: IntrinsicWidth(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var b in floatingButtons) 
                Padding(
                  padding: EdgeInsets.only(top: b == floatingButtons.first ? 0 : 15), 
                  child: b
                ),
            ]
          )
        )
      ));
    } else {
      widgets.add(Positioned(
        left: 15 + safePaddingLeft + MediaQuery.of(context).padding.bottom,
        bottom: 0, // Anchored literally to the bottom pixel
        child: IntrinsicHeight(
          child: (isPlayingMenu && liveToolBar != null) ? liveToolBar! : (leftToolBar ?? const SizedBox()),
        )
      ));
      widgets.add(Positioned(
        // Inject bottom padding value into right margin so the X and Y spacing looks identical onscreen
        right: 15 + MediaQuery.of(context).padding.right + MediaQuery.of(context).padding.bottom,
        bottom: 15 + MediaQuery.of(context).padding.bottom,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var b in floatingButtons) 
                Padding(
                  padding: EdgeInsets.only(left: b == floatingButtons.first ? 0 : 15), 
                  child: b
                ),
            ]
          )
        )
      ));
    }
    
    // Fallback trailing elements
    if (_isShowInputDebug) {
        widgets.add(Positioned(
            right: (Platform.isIOS && safePadding > 0 ? safePadding : 20 + safePadding),
            bottom: 100,
            width: 400,
            height: 300,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.9),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Input Debugger",
                          style: TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.close,
                            color: Colors.white, size: 20),
                        onPressed: _toggleInputDebug,
                      ),
                    ],
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Text(_debugInputLog,
                          style: const TextStyle(
                              color: Colors.greenAccent,
                              fontFamily: "monospace",
                              fontSize: 11)),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text("Press keys to see Logical/Physical IDs",
                      style: TextStyle(color: Colors.grey, fontSize: 10)),
                ],
              ),
            ),
        ));
    }
    
    widgets.add(ValueListenableBuilder(
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
        })));
        
    // Insert near the back of the Z-order so menus can draw over it
    widgets.insert(1, Positioned(
      right: 5,
      top: MediaQuery.of(context).padding.top + 5, // Safe Top for Version Text
      child: Text(
        style: const TextStyle(fontSize: 7, color: Colors.grey),
        "v${packageInfo?.version ?? ""} \r\n$strFirmwareVersion",
      ),
    ));
    
    widgets.add(Center(
        child: Text(restartText,
            style: const TextStyle(fontSize: 20, color: Colors.red))));

    return Scaffold(
      backgroundColor: const Color(0xFF1996FC), // Match canvas blue to prevent grey Material3 surface bleed-through during CanvasKit recomposites
      body: Stack(
        children: widgets
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

  void recreateBufferViews() {
    // Re-create views with current neuronSize to ensure we can access all neurons
    // We use a slightly larger size or exact size. 
    // Since initNativeC uses neuronSize, let's match that logic but safer.
    
    // Safety check
    if (neuronSize > maxPosBuffer) return;

    // We need to re-assign the Views that are used by updateLiveConnectionBuffer
    // The underlying Buffers (ffi pointers) are fixed size (maxPosBuffer), so this is just a Dart view update.
    
    // 1D Arrays
    mapNeuronTypeBufView = mapNeuronTypeBuf.asTypedList(maxPosBuffer);
    mapDelayNeuronBufView = mapDelayNeuronBuf.asTypedList(maxPosBuffer);
    mapRhytmicNeuronBufView = mapRhytmicNeuronBuf.asTypedList(maxPosBuffer);
    mapCountingNeuronBufView = mapCountingNeuronBuf.asTypedList(maxPosBuffer);
    
    aBufView = aBuf.asTypedList(maxPosBuffer);
    bBufView = bBuf.asTypedList(maxPosBuffer);
    cBufView = cBuf.asTypedList(maxPosBuffer);
    dBufView = dBuf.asTypedList(maxPosBuffer);
    iBufView = iBuf.asTypedList(maxPosBuffer);
    wBufView = wBuf.asTypedList(maxPosBuffer);
    
    // 2D Matrices (flattened)
    // We use maxPosBuffer * maxPosBuffer to strictly match the allocation and avoid "RangeError".
    // This allows access to any index even if neuronSize effectively shrinks/grows.
    int matrixSize = maxPosBuffer * maxPosBuffer;
    
    connectomeBufView = connectomeBuf.asTypedList(matrixSize);
    neuronContactsBufView = neuronContactsBuf.asTypedList(matrixSize);
    neuronLedBufView = neuronLedBuf.asTypedList(matrixSize);
    
    // Other matrices used in simulation...
    neuronDistanceBufView = neuronDistanceBuf.asTypedList(matrixSize);
    neuronSpeakerBufView = neuronSpeakerBuf.asTypedList(matrixSize);
    neuronMicrophoneBufView = neuronMicrophoneBuf.asTypedList(matrixSize);
  }

  void populateMotorMatrix() {
    printDebug("populateMotorMatrix: Forcing motor values into buffer from mapContactsNeuron...");
    if (neuronContactsBufView.isEmpty || neuronSize <= 0) return;

    // Iterate using the same indexing as populateMatrix and the C++ engine:
    // buffer index = fromIdx * neuronSize + toIdx
    for (int i = 0; i < neuronSize; i++) {
      InfiniteCanvasNode neuronFrom = controller.nodes[i + allNeuronStartIdx];
      int sign = 1;
      if (neuronStyles.containsKey(neuronFrom.id) && neuronStyles[neuronFrom.id] == "Inhibitory") {
        sign = -1;
      }
      for (int j = 0; j < neuronSize; j++) {
        InfiniteCanvasNode neuronTo = controller.nodes[j + allNeuronStartIdx];
        String connectionKey = "${neuronFrom.id}_${neuronTo.id}";
        if (mapContactsNeuron.containsKey(connectionKey)) {
          int bufferIdx = i * neuronSize + j;
          double val = (sign * mapContactsNeuron[connectionKey].abs()).floorToDouble();
          String fromType = neuronTypes[neuronFrom.id] ?? "";
          if (fromType == "Aux Motor" && j >= 3 && j <= 6) { // LeftFwd=3, RightFwd=4, LeftBwd=5, RightBwd=6
              val = 0;
          }
          neuronContactsBufView[bufferIdx] = val;
          printDebug("DEBUG_LOAD_MOTOR: $connectionKey -> Buffer[$bufferIdx] (Col $j). Val: $val (Map: ${mapContactsNeuron[connectionKey]})");
        }
      }
    }
  }

  /// DEBUG: Dump motor columns (3,4,5,6) from neuronContactsBufView for all neuron rows.
  /// Uses print() directly (not printDebug) so it works in release builds.
  void _dumpMotorBufferColumns(String label) {
    if (neuronContactsBufView.isEmpty || neuronSize <= 0) {
      print("MOTOR_DUMP[$label]: Buffer empty or neuronSize=$neuronSize");
      return;
    }
    print("MOTOR_DUMP[$label]: neuronSize=$neuronSize, bufLen=${neuronContactsBufView.length}");
    print("MOTOR_DUMP[$label]: mapContactsNeuron keys: ${mapContactsNeuron.keys.toList()}");
    print("MOTOR_DUMP[$label]: mapContactsNeuron values: ${mapContactsNeuron.values.toList()}");
    for (int row = 0; row < neuronSize && row < 30; row++) {
      String rowLabel = (row < controller.nodes.length - allNeuronStartIdx) 
          ? controller.nodes[row + allNeuronStartIdx].id
          : "?";
      List<String> motorVals = [];
      for (int col = 3; col <= 6 && col < neuronSize; col++) {
        int idx = row * neuronSize + col;
        if (idx < neuronContactsBufView.length) {
          String colLabel = (col < controller.nodes.length - allNeuronStartIdx)
              ? controller.nodes[col + allNeuronStartIdx].id
              : "?";
          motorVals.add("col$col($colLabel)=${neuronContactsBufView[idx]}");
        }
      }
      if (motorVals.any((v) => !v.endsWith("=0.0") && !v.endsWith("=0"))) {
        print("MOTOR_DUMP[$label]: Row $row ($rowLabel): ${motorVals.join(', ')}");
      }
    }
  }

  void _ensureDartListsSized() {
    while (neuronSpikeFlags.length < neuronSize) {
      neuronSpikeFlags.add(ValueNotifier(0));
      neuronCircleKeys.add(GlobalKey(debugLabel: "neuronWidget${neuronSpikeFlags.length - 1}"));

      var activePainter = SingleCircle(
        isActive: true, isExcitatory: 1, circleRadius: neuronDrawSize / 2,
        xNucleus: neuronDrawSize / 2, yNucleus: neuronDrawSize / 2, widthNucleus: neuronDrawSize / 3, heightNucleus: neuronDrawSize / 3,
      );
      var inactivePainter = SingleCircle(
        isActive: false, isExcitatory: 1, circleRadius: neuronDrawSize / 2,
        xNucleus: neuronDrawSize / 2, yNucleus: neuronDrawSize / 2, widthNucleus: neuronDrawSize / 3, heightNucleus: neuronDrawSize / 3,
      );

      neuronActiveCirclesPainter.add(activePainter);
      neuronInactiveCirclesPainter.add(inactivePainter);
      neuronActiveCircles.add(CustomPaint(painter: activePainter, willChange: false, isComplex: false));
      neuronInactiveCircles.add(CustomPaint(painter: inactivePainter, willChange: false, isComplex: false));

      squareActiveCirclesPainter.add(activePainter);
      squareInactiveCirclesPainter.add(inactivePainter);
      squareActiveCircles.add(CustomPaint(painter: activePainter, willChange: false, isComplex: false));
      squareInactiveCircles.add(CustomPaint(painter: inactivePainter, willChange: false, isComplex: false));
    }
  }

  void populateMatrix() {
    // Ensure views are valid for current data size
    // CRITICAL: recreateBufferViews uses .asTypedList() on FFI pointers
    // which don't exist on web. Web buffer views are plain TypedLists
    // created in initNativeC and don't need recreation.
    if (!kIsWeb) recreateBufferViews();
    _ensureDartListsSized();

    // populate connectome, neuroncontacts, and visual preferences
    int ctr = 0;
    // printDebug("connectionKeys $neuronSize");
    // printDebug(controller.nodes.map((e) => e.id).toList());
    
    // Clear buffer to prevent garbage values (e.g. 1 = Occassionally Active)
    mapNeuronTypeBufView.fillRange(0, mapNeuronTypeBufView.length, 0);
    // iOS fix: native allocator may not zero memory between runs.
    // Stale non-zero values in LED bufs cause C++ to misclassify non-LED axons
    // as LED-connected (led_pos_buf > 0 → treats as LED). Zero them first.
    if (neuronLedBufView.isNotEmpty) {
      neuronLedBufView.fillRange(0, neuronLedBufView.length, -1);
    }
    if (neuronLedPositionBufView.isNotEmpty) {
      neuronLedPositionBufView.fillRange(0, neuronLedPositionBufView.length, -1);
    }

    for (int i = 0; i < neuronSize; i++) {
      // LocalKey neuronFromKey = findNeuronByValue(i).key;
      // InfiniteCanvasNode neuronFrom = findNeuronByValue(i);
      // bool isRhytmicNeuron = false;
      InfiniteCanvasNode neuronFrom = controller.nodes[i + 2];

      int sign = 1;
      int inhibitor = 0;
      if (neuronStyles.containsKey(neuronFrom.id)) {
        if (neuronStyles[neuronFrom.id] == "Inhibitory") {
          sign = -1;
          inhibitor = 1000;
        }
      }
      // DEBUG: Trace inhibitory encoding for each neuron
      String? _dbgType = neuronTypes.containsKey(neuronFrom.id) ? neuronTypes[neuronFrom.id] : "null";
      String? _dbgStyle = neuronStyles.containsKey(neuronFrom.id) ? neuronStyles[neuronFrom.id] : "null";
      print('POP_MTX[$i]: id=${neuronFrom.id} type=$_dbgType style=$_dbgStyle sign=$sign inhibitor=$inhibitor');

      if (neuronSize >= 2) {
        String? neuronType = neuronTypes[neuronFrom.id];
        if (neuronType != null) {
          int neuronTypeIdx = neuronTypesLabel.indexOf(neuronType);
          int idx = i;
          
          // Fix: Map Remote Control to Quiet (0) for C++ simulation physics
          // This ensures standard spike propagation while Dart handles input current.
          int simTypeIdx = neuronTypeIdx;
          if (neuronType == "Remote Control" || neuronType == "Motion" || neuronType == "Aux Motor") {
              simTypeIdx = 0; // Quiet
          }
          
          mapNeuronTypeBufView[idx] = simTypeIdx + inhibitor;
          if (neuronTypeIdx == CONFIG_DELAY_NEURON) {
            mapDelayNeuronBufView[idx] = mapDelayNeuronList[idx];
          } else if (neuronTypeIdx == CONFIG_RHYTMIC_NEURON) {
            mapRhytmicNeuronBufView[idx] = mapRhytmicNeuronList[idx];
          } else if (neuronTypeIdx == CONFIG_COUNTING_NEURON) {
            mapCountingNeuronBufView[idx] = mapCountingNeuronList[idx];
          }
          
          // THE SIMPLE FIX: Set a/b/c/d/i based on neuronType
          // This is exactly what neuronTypeChangeCallback does when user manually resets type
          // Now design mode types -> simulation params, in ONE place
          switch (neuronType) {
            case "Quiet":
              aBufView[i] = 0.02; bBufView[i] = 0.1; cBufView[i] = -65; dBufView[i] = 2; iBufView[i] = 0.0;
              break;
            case "Occassionally active":
              aBufView[i] = 0.02; bBufView[i] = 0.17; cBufView[i] = -65; dBufView[i] = 2; iBufView[i] = 5.0;
              break;
            case "Highly active":
              aBufView[i] = 0.02; bBufView[i] = 0.24; cBufView[i] = -65; dBufView[i] = 2; iBufView[i] = 15.0;
              break;
            case "Generates bursts":
              aBufView[i] = 0.02; bBufView[i] = 0.17; cBufView[i] = -20; dBufView[i] = 2; iBufView[i] = 5.0;
              break;
            case "Bursts when activated":
              aBufView[i] = 0.02; bBufView[i] = 0.1; cBufView[i] = -37; dBufView[i] = 2; iBufView[i] = 0.0;
              break;
            case "Delay": 
              aBufView[i] = 0.02; bBufView[i] = 0.1; cBufView[i] = -37; dBufView[i] = 2; iBufView[i] = 0.0;
              break;
            case "Remote Control":
              aBufView[i] = 0.02; bBufView[i] = 0.1; cBufView[i] = -65; dBufView[i] = 2; iBufView[i] = 0.0;
              break;
            case "Motion":
              aBufView[i] = 0.02; bBufView[i] = 0.1; cBufView[i] = -65; dBufView[i] = 2; iBufView[i] = 0.0;
              break;
            case "Aux Motor":
              aBufView[i] = 0.02; bBufView[i] = 0.1; cBufView[i] = -65; dBufView[i] = 2; iBufView[i] = 0.0;
              break;
            // Custom and special types (Delay, etc.) keep their loaded values from iDesignArray
            default:
              // For Custom/Delay/etc: try to use DesignArray values if available, else fallback to standard defaults
              aBufView[i] = aDesignArray.containsKey(neuronFrom.id) ? aDesignArray[neuronFrom.id] : 0.02;
              bBufView[i] = bDesignArray.containsKey(neuronFrom.id) ? bDesignArray[neuronFrom.id] : 0.2;
              cBufView[i] = cDesignArray.containsKey(neuronFrom.id) ? cDesignArray[neuronFrom.id].round() : -65;
              dBufView[i] = dDesignArray.containsKey(neuronFrom.id) ? dDesignArray[neuronFrom.id].round() : 8;
              iBufView[i] = 5.0;
              break;
          }
        }

        if (sign == 1) {
        } else {}
      }

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
          double val = (sign * mapContactsNeuron[connectionKey].abs()).floorToDouble();
          String fromType = neuronTypes[neuronFrom.id] ?? "";
          if (fromType == "Aux Motor" && j >= 3 && j <= 6) { // LeftFwd=3, RightFwd=4, LeftBwd=5, RightBwd=6
              val = 0;
          }
          neuronContactsBufView[ctr] = val;
          printDebug("DEBUG: populateMatrix FOUND Motor Key: $connectionKey = ${mapContactsNeuron[connectionKey]}");
        } else {
          // printDebug("DEBUG: populateMatrix MISSING Motor Key: $connectionKey"); 
          neuronContactsBufView[ctr] = 0;
        }

        if (mapDistanceNeuron.containsKey(connectionKey)) {
          // printDebug("mapDistanceNeuron : $connectionKey --- $ctr : ${mapDistanceNeuron[connectionKey]}");
          neuronDistanceBufView[ctr] =
              (mapDistanceNeuron[connectionKey]).floor();
        } else {
          neuronDistanceBufView[ctr] = -1;
        }

        if (neuronFrom.id == nodeDistanceSensor.id) {
          try {
            int idx = neuronTypes.keys.toList().indexOf(neuronTo.id);
            if (mapDistanceLimitNeuron.containsKey(connectionKey)) {
              // printDebug("DISTANCE KEYS, $ctr");
              // // printDebug(neuronTypes.keys);
              // printDebug(nodeSingleLed.id);
              // printDebug(neuronFrom.id);
              // printDebug(neuronTo.id);
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
            // printDebug("distanceMaxLimitBufView");
            // printDebug(distanceMaxLimitBufView);
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
                  : int.parse((mapLedNeuronPosition[ledConnectionKey]),
                          radix: 2)
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
          print('POP_MTX_CONN: from=$i to=$j key=$connectionKey sign=$sign raw=${mapConnectome[connectionKey]} buf=${connectomeBufView[ctr]}');
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
    printDebug("mapNeuronTypes");
    // String str = "";
    // for (String s in neuronTypes.keys.toList()) {
    //   str = "$str, $s";
    // }
    // String strController = "";
    // for (var node in controller.nodes) {
    //   strController = "$strController, ${node.id}";
    // }

    // printDebug(str);
    // printDebug(strController);
    printDebug(nodeSingleLed.id);
    // printDebug("mapDistanceLimitNeuron");
    // printDebug(neuronDistanceBufView);
    // printDebug(mapDistanceLimitNeuron);
    // printDebug(distanceMinLimitBufView);
    // printDebug(distanceMaxLimitBufView);

    // WEB: Sync all Dart buffers → WASM heap after every populateMatrix call
    if (kIsWeb) {
      Nativec.syncBuffersToWasm();
    }
  }

  void runSimulation() {
    print('WEB_DBG: runSimulation() ENTERED');
    
    try {
    printDebug('RUN SIMuLATION');
    
    // CRITICAL: Set simulation flag immediately so Input System knows we are live
    isSimulatingBrain = true;
    
    hasLoggedMatrixDebug = false; // Reset matrix debug flag
    
    printDebug("mapAreaSize");
    printDebug(mapAreaSize);
    colorPositionFlags[0] = false;
    colorPositionFlags[1] = false;
    colorPositionFlags[2] = false;
    aiPositionFlags.fillRange(0, aiPositionFlags.length, false);
    neuronSize = controller.nodes.length - allNeuronStartIdx;
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
    // Definitive LED gradient fix: clear edge.color on every edge that does NOT
    // connect to a known LED output. Regardless of how a stale color got onto a
    // non-LED axon (save-file entry, setDataOnLeave fallback, async timing, etc.),
    // this reset on every Play press ensures only actual LED edges show the gradient.
    {
      final ledKeys = {
        nodeSingleLed.key, nodeRedLed.key, nodeGreenLed.key, nodeBlueLed.key
      };
      for (final edge in controller.edges) {
        if (!ledKeys.contains(edge.to)) {
          if (edge.color != null) edge.color = null;
          edge.isLedEdge = false;
        }
      }
    }

    initNativeC(false);
    print('WEB_DBG: initNativeC done');

    // Ensure we are listening for gamepads/remote input
    _updateGamepadSubscription();
    
    // CRITICAL FIX: Ensure buffers are synced with Maps before starting simulation
    // This fixes the "Off-By-One" / "Two Times" update lag where the engine used stale data.
    
    // CRITICAL FIX: Ensure buffers are synced with Maps before starting simulation
    // This fixes the "Off-By-One" / "Two Times" update lag where the engine used stale data.
    
    // REVERTED: Moving runNativeC here caused instability ("Weirdness").
    // We will call it at the end as before, but re-apply parameters AFTER it returns.
    // runNativeC();

    print('WEB_DBG: calling first populateMatrix');
    populateMatrix();
    print('WEB_DBG: first populateMatrix done');
    _dumpMotorBufferColumns("SIM_START_AFTER_POPULATE");
    
    printDebug("neuronSize");
    printDebug(neuronSize);
    // List<Offset> pos = [];
    // List<String> orderedNeuronTypes = [];

    // Map<int,String> nodeKey = {};
    // Map<String, int> nodeKey = {};
    // int idx = 0;
    // for (InfiniteCanvasNode node in controller.nodes) {
    //   if (idx >= allNeuronStartIdx) {
    //     pos.add(node.offset);
    //     // CRITICAL FIX: Build ordered list of types matching the nodes
    //     orderedNeuronTypes.add(neuronTypes[node.id] ?? "Quiet");
    //     nodeKey[node.key.toString()] = idx - allNeuronStartIdx;
    //     // nodeKey[idx] = node.key.toString();
    //   }
    //   idx++;
    // }
    
    // REVERT Manual construction. Use Full Pos for setCirclesZoom.
    // This aligns initialization with Pan/Zoom logic which is known to work.
    List<Offset> fullPos = [];
    Map<String, int> nodeKey = {};
    int idx = 0;
    for (InfiniteCanvasNode node in controller.nodes) {
        fullPos.add(node.offset);
        if (idx >= allNeuronStartIdx) {
            nodeKey[node.key.toString()] = idx - allNeuronStartIdx;
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
      if (nodeKey.containsKey(edge.from.toString()) && nodeKey.containsKey(edge.to.toString())) {
          int fromIdx = nodeKey[edge.from.toString()]!; // - allNeuronStartIdx;
          int toIdx = nodeKey[edge.to.toString()]!; // - allNeuronStartIdx;
          connectomeMatrix[fromIdx][toIdx] = Random().nextDouble() * 3;
      }
    }
    // final vals = neuronTypes.values;
    // Fix Parameter Scrambling: Use ordered nodes
    // int index = 0;
    // neuronTypes.forEach((key, item) {
    int scrmIndex = 0;
    for (int i = 0; i < controller.nodes.length; i++) {
       // Skip system nodes if necessary (allNeuronStartIdx typically 2)
       if (i >= allNeuronStartIdx) {
          // CRITICAL FIX: Use node.id (Stable UUID) for parameter lookup.
          // Previous code used node.key.toString() which changes on reload/instantiation,
          // causing lookup failure -> defaults -> "Acting weird".
          String safeKey = controller.nodes[i].id; 
          
          aBufView[scrmIndex] = aDesignArray[safeKey] ?? 0.02;
          bBufView[scrmIndex] = bDesignArray[safeKey] ?? 0.2;
          cBufView[scrmIndex] = (cDesignArray[safeKey] ?? -65.0).round();
          dBufView[scrmIndex] = (dDesignArray[safeKey] ?? 8.0).round();
          iBufView[scrmIndex] = 5.0; 
          
          scrmIndex++;
       }
    }
    //   index++;
    // });  index++;
    // });

    // Safer approach:
    int mIdx = 0;
    for (InfiniteCanvasNode node in controller.nodes) {
         if (mIdx >= allNeuronStartIdx) { // Assuming allNeuronStartIdx = 2
             int neuronIndex = mIdx - allNeuronStartIdx;
             String micKey = "${nodeMicrophoneSensor.id}_${node.key.toString()}";
             if (mapMicrophoneNeuron.containsKey(micKey)) {
                  neuronMicrophoneBufView[neuronIndex] = mapMicrophoneNeuron[micKey]!.toInt();
             } else {
                  neuronMicrophoneBufView[neuronIndex] = -1;
             }
         }
         mIdx++;
    }

    // Restore Delay Neuron Buffer from List (as initNativeC clears it)
    for (int i = 0; i < neuronSize; i++) {
        if (i < mapDelayNeuronList.length) {
            mapDelayNeuronBufView[i] = mapDelayNeuronList[i];
        }
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
    printDebug("neuronSize::$neuronSize : ${neuronTypes.keys.length}");
    
    // DEBUG LOGS BEFORE SETCIRCLESZOOM
    if (controller.nodes.length > allNeuronStartIdx) {
       String firstId = controller.nodes[allNeuronStartIdx].id;
       String firstKey = controller.nodes[allNeuronStartIdx].key.toString();
       printDebug("RUNSIM CHECK: FirstNode ID=$firstId Key=$firstKey");
       printDebug("RUNSIM CHECK: neuronTypes has ID? ${neuronTypes.containsKey(firstId)}");
       printDebug("RUNSIM CHECK: neuronTypes has Key? ${neuronTypes.containsKey(firstKey)}");
       printDebug("RUNSIM CHECK: aBufView[0] before Zoom = ${aBufView[0]}");
    }
    
    // CRITICAL FIX: Use setCirclesZoom instead of manual generateCircle.
    // This matches the Pan/Zoom logic exactly, which the user confirms works.
    setCirclesZoom(controller.scale, fullPos);
    
    // protoNeuron.generateCircle(
    //     neuronSize, pos, orderedNeuronTypes);
    // printDebug("initializeNucleus()");
     initializeNucleus();

    // protoNeuron.setConnectome(neuronSize, connectomeMatrix);
    // printDebug("controller.nodes.map(((e) => e.id)).toList()");
    // printDebug(controller.nodes.map(((e) => e.id)).toList());
    
    // SAFE POPULATE MATRIX
    print('WEB_DBG: calling second populateMatrix');
    try {
        printDebug("Calling populateMatrix()...");
        populateMatrix();
        populateMotorMatrix(); // Safety net: re-apply motor contacts after full matrix populate
        printDebug("populateMatrix() Success.");
    } catch (e, stackTrace) {
        printDebug("CRITICAL ERROR in populateMatrix(): $e");
        printDebug(stackTrace);
    }

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

    // FINAL SAFETY: Force motor buffer from map one last time right before C++ starts
    populateMotorMatrix();

    // DEBUG: Verify motor buffer contents at simulation start
    printDebug("=== MOTOR BUFFER CHECK (pre-runNativeC) ===");
    printDebug("mapContactsNeuron: $mapContactsNeuron");
    printDebug("neuronSize: $neuronSize");
    for (int row = 0; row < neuronSize; row++) {
      for (int col = 3; col <= 6; col++) { // Motor columns only
        if (col < neuronSize) {
          int idx = row * neuronSize + col;
          double val = neuronContactsBufView[idx];
          if (val != 0) {
            printDebug("  buf[$row][$col] (idx=$idx) = $val");
          }
        }
      }
    }
    printDebug("=== END MOTOR BUFFER CHECK ===");

    print('WEB_DBG: calling runNativeC');
    runNativeC(); 
    print('WEB_DBG: runNativeC done');
    // CRITICAL FIX: Re-apply parameters AFTER Native Engine Start/Reset.
    // Native engine initialization seems to zero/reset buffers.
    // Re-calling setCirclesZoom ensures valid parameters trigger on the very first tick.
    printDebug("Re-Applying setCirclesZoom after runNativeC...");
    setCirclesZoom(controller.scale, fullPos);
    
    linkMicrophoneConnection();
    
    // Start Remote Control Listener
    // Start Remote Control Listener
    HardwareKeyboard.instance.addHandler(_onSimulationKeyEvent);
    _updateGamepadSubscription();
    _activeRemoteKeys.clear();

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
    } catch (e, stackTrace) {
      print('WEB_DBG: runSimulation() CRASHED: $e');
      print('WEB_DBG: STACK: $stackTrace');
    }
    print('WEB_DBG: runSimulation() EXITED');
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

      // Use defaults if not specified
      double valA = 0.02;
      double valB = 0.2;
      double valC = -65.0;
      double valD = 8.0;
      double valI = 5.0;

      switch (neuronType) {
        case "Quiet":
          valA = 0.02; valB = 0.1; valC = -65; valD = 2; valI = 0.0;
          break;
        case "Occassionally active":
          valA = 0.02; valB = 0.17; valC = -65; valD = 2; valI = 5.0;
          break;
        case "Highly active":
          valA = 0.02; valB = 0.2; valC = -65; valD = 2; valI = 15.0;
          break;
        case "Generates bursts":
          valA = 0.02; valB = 0.17; valC = -20; valD = 2; valI = 5.0; // Fixed Burst math to match Native C++ initialization
          break;
        case "Bursts when activated":
        case "Delay": 
          valA = 0.02; valB = 0.1; valC = -37; valD = 2; valI = 0.0;
          break;
        case "Dopaminergic":
          valA = 0.02; valB = 0.1; valC = -65; valD = 2; valI = 5.0;
          break;
        case "Striatal":
           valA = 0.02; valB = 0.1; valC = -65; valD = 2; valI = 5.0;
          break;
        case "Remote Control":
        case "Motion":
          valA = 0.02; valB = 0.1; valC = -65; valD = 2; valI = 0.0;
          break;
        default: // Custom or others
          if (aDesignArray.containsKey(selected.id)) valA = aDesignArray[selected.id]!;
          if (bDesignArray.containsKey(selected.id)) valB = bDesignArray[selected.id]!;
          if (cDesignArray.containsKey(selected.id)) valC = cDesignArray[selected.id]!.toDouble();
          if (dDesignArray.containsKey(selected.id)) valD = dDesignArray[selected.id]!.toDouble();
          break;
      }

      // V25 FEATURE: Dynamically update the slider state UI variables so the Embedded Plot 
      // instantly visualizes the mathematically accurate curve instead of stale Default traits!
      sldAWeight = valA;
      sldBWeight = valB;
      sldCWeight = valC;
      sldDWeight = valD;
      
      tecAWeight.text = sldAWeight.toString();
      tecBWeight.text = sldBWeight.toString();
      tecCWeight.text = sldCWeight.toString();
      tecDWeight.text = sldDWeight.toString();

      // CRITICAL FIX: Use controller.nodes order to match populateMatrix indexing
      // OLD: int idx = neuronTypes.keys.toList().indexOf(selected.id);  // WRONG ORDER!
      int idx = -1;
idx = controller.nodes.map((e) => e.id).toList().indexOf(selected.id) - 2;
      if (idx >= 0 && idx < neuronSize) {
         aBufView[idx] = valA;
         bBufView[idx] = valB;
         cBufView[idx] = valC.round();
         dBufView[idx] = valD.round();
         iBufView[idx] = valI;
         
         // Update Design Arrays so populateMatrix uses them later
         // CRITICAL: Use selected.id (not key.toString()) to match populateMatrix lookup
         aDesignArray[selected.id] = valA;
         bDesignArray[selected.id] = valB;
         cDesignArray[selected.id] = valC;
         dDesignArray[selected.id] = valD;
         
         // Update UI Sliders
         sldAWeight = valA; tecAWeight.text = valA.toString();
         sldBWeight = valB; tecBWeight.text = valB.toString();
         sldCWeight = valC; tecCWeight.text = valC.toString();
          sldDWeight = valD; tecDWeight.text = valD.toString();
       }
    }
    // Trigger rebuild so node widgets (RC icon, Delay clock) update immediately
    setState(() {});
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

      // Clear pins for deleted neuron (find index in user-neuron space)
      int deletedUserIdx = controller.nodes.indexOf(selected) - allNeuronStartIdx;
      if (deletedUserIdx >= 0) {
        // Remove the pin for the deleted neuron
        placedPins.remove(deletedUserIdx);
        if (currentWaveNeuronIdx == deletedUserIdx) {
          nativec.changeIdxSelected(-1);
          currentWaveNeuronIdx = -1;
        }
        if (currentWaveNeuronIdx2 == deletedUserIdx) {
          nativec.changeIdxSelected2(-1);
          currentWaveNeuronIdx2 = -1;
        }
        // Shift down all pin indices above the deleted neuron
        final Map<int, int> remapped = {};
        placedPins.forEach((idx, pinType) {
          if (idx > deletedUserIdx) {
            remapped[idx - 1] = pinType;
          } else {
            remapped[idx] = pinType;
          }
        });
        placedPins = remapped;
        // Also remap wave neuron indices
        if (currentWaveNeuronIdx > deletedUserIdx) currentWaveNeuronIdx--;
        if (currentWaveNeuronIdx2 > deletedUserIdx) currentWaveNeuronIdx2--;
      }
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
        if (mapLedNeuronPosition
            .containsKey("${inwardEdge.from.toString()}_${nodeRedLed.id}")) {
          mapLedNeuronPosition
              .remove("${inwardEdge.from.toString()}_${nodeRedLed.id}");
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
        if (outwardEdge.to == nodeSingleLed.key) {
            String redKey = "${outwardEdge.from.toString()}_${nodeRedLed.id}";
            String greenKey = "${outwardEdge.from.toString()}_${nodeGreenLed.id}";
            String blueKey = "${outwardEdge.from.toString()}_${nodeBlueLed.id}";
            
            if (mapLedNeuron.containsKey(redKey)) mapLedNeuron.remove(redKey);
            if (mapLedNeuron.containsKey(greenKey)) mapLedNeuron.remove(greenKey);
            if (mapLedNeuron.containsKey(blueKey)) mapLedNeuron.remove(blueKey);
            
            if (mapLedNeuronPosition.containsKey(redKey)) mapLedNeuronPosition.remove(redKey);
            if (mapLedNeuronPosition.containsKey(greenKey)) mapLedNeuronPosition.remove(greenKey);
            if (mapLedNeuronPosition.containsKey(blueKey)) mapLedNeuronPosition.remove(blueKey);
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

      try {
        int deleteIdx = -1;
        for (int i = 0; i < syntheticNeuronList.length; i++) {
          if (syntheticNeuronList[i].node?.id == selected.id) {
            deleteIdx = i;
            break;
          }
        }
        
        if (deleteIdx != -1) {
            mapDelayNeuronList.removeAt(deleteIdx);
            syntheticNeuronList.removeAt(deleteIdx);
            rawSyntheticNeuronList.removeAt(deleteIdx);
        } else {
             printDebug("CRITICAL: Neuron ID ${selected.id} not found in syntheticNeuronList during deletion!");
        }

        neuronTypes.remove(selected.id);
        neuronStyles.remove(selected.id);
        if (!isLoadingBrain && !isSettlingAfterLoad) brainHasUnsavedChanges.value = true; // RC binding removed
        mapRemoteControlNeuron.remove(selected.id);
        mapMotionNeuron.remove(selected.id);
        aDesignArray.remove(selected.id);
        bDesignArray.remove(selected.id);
        cDesignArray.remove(selected.id);
        dDesignArray.remove(selected.id);
      } catch (e) {
        printDebug("Error removing neuron data: $e");
      }

      // remove, still preserve order of the hashmap data.
      // printDebug("neuronTypes");
      // printDebug(neuronTypes.keys);
      // printDebug(neuronTypes.values);

      controller.deleteSelection();
      
      // CRITICAL FIX: Safer neuronSize update and sync with C++
      neuronSize = controller.nodes.length - allNeuronStartIdx;
      populateMatrix();
      
      isDrawTail = false;
      isDeleteMenu = false;

      controller.deselectAll();
      // controller.setSelection({prevSelectedNeuron.key});
      controller.controlPressed = false;
      controller.controlPressed = false;
      clearUIMenu();
      // Update RC Icons
      initializeNucleus();
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
      
      List<InfiniteCanvasEdge> edgesToDelete = controller.multiEdgeSelection.isNotEmpty 
          ? controller.multiEdgeSelection.toList() 
          : (controller.edgeSelected != null ? [controller.edgeSelected!] : []);

      for (var edgeToDelete in edgesToDelete) {
          int idx = controller.edges.indexOf(edgeToDelete);
          if (idx == -1) continue;
          
          InfiniteCanvasEdge lastCreatedEdge = controller.edges[idx];
          String edgeKey = "${lastCreatedEdge.from.toString()}_${lastCreatedEdge.to.toString()}";
          
          if (mapSensoryNeuron.containsKey(edgeKey)) mapSensoryNeuron.remove(edgeKey);
          if (mapContactsNeuron.containsKey(edgeKey)) mapContactsNeuron.remove(edgeKey);
          if (mapConnectome.containsKey(edgeKey)) mapConnectome.remove(edgeKey);
          if (mapDistanceNeuron.containsKey(edgeKey)) mapDistanceNeuron.remove(edgeKey);
          if (mapDistanceLimitNeuron.containsKey(edgeKey)) mapDistanceLimitNeuron.remove(edgeKey);
          if (mapSpeakerNeuron.containsKey(edgeKey)) mapSpeakerNeuron.remove(edgeKey);
          if (mapMicrophoneNeuron.containsKey(edgeKey)) mapMicrophoneNeuron.remove(edgeKey);
          if (mapLedNeuron.containsKey(edgeKey)) mapLedNeuron.remove(edgeKey);

          if (lastCreatedEdge.to == nodeSingleLed.key) {
            String redKey = "${lastCreatedEdge.from.toString()}_${nodeRedLed.id}";
            String greenKey = "${lastCreatedEdge.from.toString()}_${nodeGreenLed.id}";
            String blueKey = "${lastCreatedEdge.from.toString()}_${nodeBlueLed.id}";
            
            if (mapLedNeuron.containsKey(redKey)) mapLedNeuron.remove(redKey);
            if (mapLedNeuron.containsKey(greenKey)) mapLedNeuron.remove(greenKey);
            if (mapLedNeuron.containsKey(blueKey)) mapLedNeuron.remove(blueKey);
            
            if (mapLedNeuronPosition.containsKey(redKey)) mapLedNeuronPosition.remove(redKey);
            if (mapLedNeuronPosition.containsKey(greenKey)) mapLedNeuronPosition.remove(greenKey);
            if (mapLedNeuronPosition.containsKey(blueKey)) mapLedNeuronPosition.remove(blueKey);
          }

          controller.edges.removeAt(idx);
      }

      controller.isFoundEdge = false;
      controller.isSelectingEdge = false;
      controller.multiEdgeSelection.clear(); // V25: Clear the Multi-selection cache to prevent garbage

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
            behavior: HitTestBehavior.translucent, // was opaque — opaque won the gesture arena blocking InteractiveViewer from receiving trackpad pan/zoom events
            onTapUp: (details) async {
              // Annotation mode handles all selection inside checkSelection (pre-notify).
              // Do NOT let this design-mode handler restore isSelectingEdge/edgeSelected on finger-up.
              if (isAnnotationMode) return;
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
            // onDoubleTap pruned per user request to disable snap zooming
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
    
    // V25 FEATURE: Link Live Pin Selection to +30px Node Inflation Radius
    controller.isDraggingPin = (modeIdx != null && modeIdx >= 10);
    
    isBrainTargetOverlayTop = -1;
    containedIdx = -1;
    if (modeIdx != -1) {
      mapBg["activeBg"] = greyBg;
      // Selecting a neuron type to place dismisses the annotation viewer,
      // since the user is switching to placement mode.
      if (isAnnotationMode) _exitAnnotationMode();
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

      if (isAnnotationMode) _exitAnnotationMode();
      currentBrainAnnotations = brainAnnotations;
      onAddAnnotationRequested = _enterAnnotationMode;
      onAnnotationsModified = () { setState(() { brainHasUnsavedChanges.value = true; }); };
      onAnnotationViewRequested = (ann, idx) { _viewAnnotation(ann, idx); };
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
      if (!kIsWeb) controller.setCanvasMove(false);
      // controller.zoomReset();
      // controller.pan(const Offset(-60, 0));

      // save
      // save neurons : position, index, color, shape, size
      // save edges : from node Id, to node Id
      // save as json.
      await saveBrainInfoDialog(context, saveCurrentBrain);
    } else if (menuIdx == 7) {
      controller.isSelectingEdge = controller.spacePressed = false;

      if (isAnnotationMode) _exitAnnotationMode();
      isPlayingMenu = !isPlayingMenu;
      countEyeSensorConnection();
      // isSelected = false;
      printDebug("MENU IDX 8");
      printDebug("BUF IDX 7");
      printDebug(isPlayingMenu);
      // printDebug(mapConnectome);

      controller.setCanvasMove(false);

      if (!isPlayingMenu && isCameraExpanded) {
          isCameraExpanded = false;
          _animateCanvasToReset(true, shiftDown: _hasUnboundRemoteNeurons, animate: true);
      } else if (isPlayingMenu) {
          _animateCanvasToReset(false, animate: true);
      }
      
      rawPos = [];
      for (InfiniteCanvasNode node in controller.nodes) {
        Offset position = controller.toLocal(node.offset);
        rawPos.add(position);
      }

      if (isPlayingMenu) {
        isCheckingColor = false;
        try {
          isPreventPlayClick = true;
          _pauseRampDownTimer?.cancel();

          startWebSocket();
          // Fade from connected-green to black so simulation takes over from darkness
          Future.delayed(const Duration(milliseconds: 300), () {
            try {
              sendToRobot(offLEDCmd);
            } catch (_) {}
          });
          Future.delayed(const Duration(milliseconds: 1000), () { // Reduced from 2770 for snappy UI
            isSimulatingBrain = true;
            isPreventPlayClick = false;
            setState(() => {});
          });
        } catch (ex) {}
      } else {
        controller.isPlaying = false;
        try {
          // Asynchronously ramp down the last known physical telemetry (motor thrust and diode brightness)
          // over ~500ms to securely halt the robot without an abrupt mechanical jerk, while avoiding table falls.
          _pauseRampDownTimer?.cancel();
          int fadeStep = 0;
          double currentLeft = _lastSentMotorLeft.toDouble();
          double currentRight = _lastSentMotorRight.toDouble();
          
          _pauseRampDownTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
              fadeStep++;
              // 10 steps @ 50ms = 500ms total fade time.
              if (fadeStep >= 10) {
              if (isIsolateWritePortInitialized) {
                  sendToRobot(stopMotorCmd + greenLEDCmd);
                  try {
                    sendToRobot("DISCONNECT");
                  } catch (err) {}
              }
                  
                  // Restore offline camera UI elements AFTER the fade out finishes communicating
                  isIsolateWritePortInitialized = false;
                  processor.clearMemory();
                  try {
                    processor = ImagePreprocessor();
                    mjpegComponent = Mjpeg(
                      key: UniqueKey(), // Force hard UI rebuild
                      error: (context, error, stack) {
                        return const Text("\r\nNot connected\r\nto SpikerBot\r\nWiFi",
                            style: TextStyle(fontSize: 10, color: Colors.brown));
                      },
                      stream: httpdStream,
                      preprocessor: processor,
                      width: 320,
                      height: 240,
                      isLive: true,
                      fit: BoxFit.fill,
                      timeout: const Duration(seconds: 60),
                    );
                  } catch (exc) {
                    printDebug("exception mjpeg: ");
                    printDebug(exc);
                  }
                  
                  timer.cancel();
              } else {
                  currentLeft *= 0.6;
                  currentRight *= 0.6; // ~40% decay per tick
                  
                  String decayingDiode = "";
                  if (_lastSentDiodeString.isNotEmpty && _lastSentDiodeString.contains("d:")) {
                      List<String> dSplit = _lastSentDiodeString.split(";");
                      for (String dCommand in dSplit) {
                          if (dCommand.startsWith("d:")) {
                              List<String> rgbSplit = dCommand.substring(2).split(",");
                              if (rgbSplit.length == 4) {
                                  int c = int.parse(rgbSplit[0]);
                                  int startR = int.parse(rgbSplit[1]);
                                  int startG = int.parse(rgbSplit[2]);
                                  int startB = int.parse(rgbSplit[3]);
                                  double progress = fadeStep / 10.0;
                                  int r = (startR + (0 - startR) * progress).floor();
                                  int g = (startG + (25 - startG) * progress).floor(); // Match firmware idle glow
                                  int b = (startB + (0 - startB) * progress).floor();
                                  decayingDiode += "d:$c,$r,$g,$b;";
                              }
                          }
                      }
                  } else {
                      decayingDiode = "d:0,0,0,0;d:1,0,0,0;d:2,0,0,0;d:3,0,0,0;";
                  }
                  
                  sendToRobot("l:${currentLeft.floor()};r:${currentRight.floor()};s:0;$decayingDiode");
              }
          });
        } catch (err) {}
        isSimulatingBrain = false;
        
        // Stop Remote Control Listener
        HardwareKeyboard.instance.removeHandler(_onSimulationKeyEvent);

        _updateGamepadSubscription(); // Ensure cancel since isSimulatingBrain=false
        _activeRemoteKeys.clear();

        if (!kIsWeb) {
          initializeOpenCV(
              stateBuf, visPrefsValsBuf, visPrefsBuf, neuronContactsBuf);
        } else {
          initializeOpenCV(null, null, null, null);
        }

        isPreventPlayClick = true;
        // isIsolateWritePortInitialized handled manually inside timer above or timeout


        Future.delayed(const Duration(milliseconds: 300), () {
          // rightToolbarGlobalKey = GlobalKey();
          rightToolbarKey = UniqueKey();
          setState(() {});
        });
        Future.delayed(const Duration(milliseconds: 1000), () { // Reduced from 4000 for snappy UI
          isPreventPlayClick = false;
          restartText = "";
          setState(() => {});
        });
      }

      if (isPlayingMenu) {
        controller.deselectAll();
        isDrawTail = false;
        
        // Start simulation AFTER the camera animation fully completes.
        // Previously a fixed 1050ms Future.delayed raced the 1000ms animation
        // on slow hardware (iOS), causing stutter. The onComplete callback fires
        // only when _canvasAnimController.forward() resolves — platform-agnostic.
        _animateCanvasToReset(
          isPortrait == false,
          animate: true,
          onComplete: () {
            runSimulation();
            controller.positionDirty = true; // refresh cachedSynapses positions without re-routing dendrites (no snap)
            controller.isPlaying = true;
          currentWaveZoom = 2.0; // Reset Zoom on Start
          printDebug("initial Index");
          printDebug("initial Index");

          // Restore pins from previous session if they exist, otherwise start blank
          if (placedPins.isNotEmpty) {
            // Find orange pin (type 10) and blue pin (type 11) from persisted state
            int restoredIdx1 = -1;
            int restoredIdx2 = -1;
            placedPins.forEach((neuronIdx, pinType) {
              if (pinType == 10) restoredIdx1 = neuronIdx;
              if (pinType == 11) restoredIdx2 = neuronIdx;
            });

            currentWaveNeuronIdx = restoredIdx1;
            currentWaveNeuronIdx2 = restoredIdx2;
            nativec.changeIdxSelected(restoredIdx1);
            nativec.changeIdxSelected2(restoredIdx2);

            if (restoredIdx1 != -1 || restoredIdx2 != -1) {
              waveWidget = WaveWidget(
                key: ValueKey("${currentWaveNeuronIdx}_$currentWaveNeuronIdx2"),
                valueNotifier: waveRedraw,
                chartGain: chartGain,
                levelMedian: levelMedian,
                screenWidth: screenWidth,
                screenHeight: screenHeight,
                neuronIdx1: currentWaveNeuronIdx,
                neuronIdx2: currentWaveNeuronIdx2,
                initialVisibleSeconds: currentWaveZoom,
                onVisibleSecondsChanged: (s) => currentWaveZoom = s,
              );
            } else {
              waveWidget = Container(
                  color: const Color(0xFF222222),
                  child: const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Text(
                        "Drag a pin onto a neuron to see its activity realtime!",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: "Roboto",
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ));
            }
          } else {
            // No persisted pins — start with hidden plot (original behavior)
            nativec.changeIdxSelected(-1);
            nativec.changeIdxSelected2(-1);
            currentWaveNeuronIdx = -1;
            currentWaveNeuronIdx2 = -1;
            waveWidget = Container(
                color: const Color(0xFF222222),
                child: const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Text(
                      "Drag a pin onto a neuron to see its activity realtime!",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: "Roboto",
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ));
          }
          isChartSelected = false; // Was true, now false until Pin Drop

          try {
            // debouncerNoResponse.cancel();
            debouncerNoResponse.run(() {
              try {
                // FIXED: Bypass legacy buffer check since we start with NO selection (-1).
                // Old logic checked if buffer was empty (maxValue == 0), but it IS empty now by design.
                // We assume connection is fine and proceed.
                sendToRobot("v:");
                
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
            aiObjectsInfo = [];

            MyApp.logAnalytic("StartPlaying",
                {"timestamp": DateTime.now().millisecondsSinceEpoch});
            if (mounted) setState(() {}); // Ensure UI updates!
          }
        });
      } else {
        printDebug("STOP THREAD PROCESS");
        // Stop simulation engine on ALL platforms (including web WASM)
        nativec.stopThreadProcess(0);
        controller.deselectAll();
        
        // V25: Slide smoothly back to Home Position when Paused
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (isPortrait == false) {
             _animateCanvasToReset(true, animate: true); 
          } else {
             _animateCanvasToReset(false, animate: true);
          }
        });
        
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

    Offset offsetLMF = Offset(screenWidth / 2 - 12 - 2 * screenHeight / 8 - 25,
        nodeLeftMotorForwardSensor.offset.dy);
    nodeLeftMotorForwardSensor.offset = offsetLMF;

    Offset offsetLMB = Offset(screenWidth / 2 - 12 - 2 * screenHeight / 8 - 58,
        nodeLeftMotorBackwardSensor.offset.dy);
    nodeLeftMotorBackwardSensor.offset = offsetLMB;

    Offset diffRight = Offset(screenHeight / 8, 0);
    Offset offsetRight = middleScreenOffset + diffRight;
    nodeRightEyeSensor.offset = offsetRight;

    Offset offsetSpeaker = Offset(
        screenWidth / 2 - 12 + platformAdjuster + 1.725 * screenHeight / 8,
        nodeSpeakerSensor.offset.dy + 6.0);
    nodeSpeakerSensor.offset = offsetSpeaker;

    Offset offsetRMF = Offset(
        screenWidth / 2 - 12 + platformAdjuster + 2 * screenHeight / 8 + 16,
        nodeRightMotorForwardSensor.offset.dy);
    nodeRightMotorForwardSensor.offset = offsetRMF;

    Offset offsetRMB = Offset(
        screenWidth / 2 - 12 + platformAdjuster + 2 * screenHeight / 8 + 39,
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
        Offset(middleScreenOffset.dx, nodeGreenLed.offset.dy + 1.0);
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
    mapLedHex = {};
    mapLedBrightness = {};
    mapSensoryNeuron = {};
    mapSpeakerNeuron = {};

    // SYNC TO CONTROLLER (Critical for persistence after clear)
    controller.mapContactsNeuron = {};
    controller.mapMicrophoneNeuron = {};
    controller.mapMicrophoneTypeNeuron = {};
    controller.mapMicrophoneLimitNeuron = {};
    controller.mapConnectome = {};
    controller.mapDistanceNeuron = {};
    controller.mapLedNeuron = {};
    controller.mapSensoryNeuron = {};
    controller.mapSpeakerNeuron = {};
    
    neuronSize = normalNeuronStartIdx;
    syntheticNeuronList.clear();
    rawSyntheticNeuronList.clear();

    // V25 FIX: Clear stale selection references during Brain wipe to prevent UI menu collapses 
    // when tapping the very first new neuron on a blank canvas.
    prevSelectedNode = null;
    prevSelectedOffsetNode = null;
    prevSelectedNeuron = null;

    for (InfiniteCanvasNode node in sensoryNeurons) {
      bool isOutputNode = [
        nodeLeftMotorForwardSensor,
        nodeRightMotorForwardSensor,
        nodeLeftMotorBackwardSensor,
        nodeRightMotorBackwardSensor,
        nodeSpeakerSensor,
        nodeSingleLed,
        nodeRedLed,
        nodeGreenLed,
        nodeBlueLed,
      ].contains(node);

      SyntheticNeuron synNeuron = SyntheticNeuron(
          isActive: false, isIO: true, circleRadius: neuronDrawSize / 2);
      synNeuron.node = node;
      synNeuron.setupDrawingNeuron(isOutput: isOutputNode);
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
          int activeIdx = -1;
          if (controller.selection.isNotEmpty && isDrawTail) {
              activeIdx = controller.nodes.indexWhere((e) => e.id == controller.selection.first.id) - 2;
          }

          Widget buildTail(Color fillColor) {
              return CustomPaint(
                painter: InlineCustomPainter(
                  brush: tailColor,
                  builder: (brush, canvas, rect) {
                    // Draw triangle (Excitatory) or circle (Inhibitory)
                    if (isDrawTail) {
                      // Orange highlight (drawn first, behind)
                      Paint orangeHighlight = Paint()
                        ..color = const Color(0xFFFD8164) // Signature Orange
                        ..style = PaintingStyle.stroke
                        ..strokeWidth = 10 // Thicker for highlight effect
                        ..strokeCap = StrokeCap.round // Rounded line ends
                        ..strokeJoin = StrokeJoin.round; // Rounded corners on path
                      // White fill for the shape
                      Paint whiteFill = Paint()
                        ..color = fillColor
                        ..style = PaintingStyle.fill;
                      
                      Paint blackStroke = Paint()
                        ..color = Colors.black
                        ..style = PaintingStyle.stroke
                        ..strokeWidth = 2; // Re-declare locally to ensure scope

                      if (neuronStyle == "Excitatory") {
                        Offset parentOffset =
                            Offset(rect.center.dx, rect.center.dy - gapTailY);
                        if (!isTailCreated) {
                          pathTail = Path();
                          int offset = 0;
                          Offset topTriangle = Offset(offset + rect.center.dx,
                              offset + rect.center.dy - tailSize);
                          Offset rightTriangle = Offset(
                              offset + rect.center.dx + tailSize * 1.5,
                              offset + rect.center.dy + tailSize);
                          Offset leftTriangle = Offset(
                              offset + rect.center.dx - tailSize * 1.5,
                              offset + rect.center.dy + tailSize);

                          pathTail.moveTo(topTriangle.dx, topTriangle.dy);
                          pathTail.lineTo(leftTriangle.dx, leftTriangle.dy);
                          pathTail.lineTo(rightTriangle.dx, rightTriangle.dy);

                          pathTail.close();
                          isTailCreated = true;
                        }

                        // Draw order: orange highlight (behind) -> white fill -> black stroke (on top)
                        canvas.drawLine(rect.center, parentOffset, orangeHighlight);
                        canvas.drawPath(pathTail, orangeHighlight);
                        
                        canvas.drawLine(rect.center, parentOffset, blackStroke);
                        canvas.drawPath(pathTail, whiteFill);
                        canvas.drawPath(pathTail, blackStroke);

                        brush.color = tailColor.color;
                      } else if (neuronStyle == 'Inhibitory') {
                        Offset parentOffset =
                            Offset(rect.center.dx, rect.center.dy - gapTailY);
                        if (!isTailCreated) {
                          isTailCreated = true;
                        }
                        int inhibitorySize = 6;
                        // Draw order: orange highlight (behind) -> white fill -> black stroke (on top)
                        canvas.drawLine(rect.center.translate(0, -inhibitorySize.toDouble()),
                            parentOffset.translate(0, 7), orangeHighlight);
                        canvas.drawCircle(rect.center, inhibitorySize + 2, orangeHighlight);
                        
                        canvas.drawLine(rect.center.translate(0, -inhibitorySize.toDouble()),
                            parentOffset.translate(0, 7), blackStroke);
                        canvas.drawCircle(rect.center, inhibitorySize.toDouble(), whiteFill);
                        canvas.drawCircle(rect.center, inhibitorySize.toDouble(), blackStroke);
                      }
                    }
                  },
                ),
              );
          }

          if (activeIdx < 0 || activeIdx >= neuronSpikeFlags.length) {
              return buildTail(Colors.white);
          }

          return ValueListenableBuilder<int>(
              valueListenable: neuronSpikeFlags[activeIdx],
              builder: (context, val, child) {
                  return TweenAnimationBuilder<Color?>(
                      key: ValueKey(val),
                      tween: ColorTween(
                           begin: (neuronStyle == "Excitatory") ? const Color(0xFF00FF00) : Colors.red,
                           end: Colors.white,
                      ),
                      duration: const Duration(milliseconds: 750),
                      builder: (context, animColor, child) {
                          return buildTail(animColor ?? Colors.white);
                      }
                  );
              }
          );
        },
      ),
    );
    rectangleNode = InfiniteCanvasNode(
      value: 9,
      key: UniqueKey(),
      // label: 'Rectangle',

      offset: const Offset(500, 300),
      size: const Size(20, 20),
      child: Builder(
        builder: (context) {
          return CustomPaint(
            isComplex: !kIsWeb,
            willChange: !kIsWeb,
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
      offset: const Offset(520, 430),
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
      // V25 FEATURE: Structured Output Dendrites
      bool isOutputNode = [
        nodeLeftMotorForwardSensor,
        nodeRightMotorForwardSensor,
        nodeLeftMotorBackwardSensor,
        nodeRightMotorBackwardSensor,
        nodeSpeakerSensor,
        nodeSingleLed,
        nodeRedLed,
        nodeGreenLed,
        nodeBlueLed,
      ].contains(node);

      SyntheticNeuron synNeuron = SyntheticNeuron(
          isActive: false, isIO: true, circleRadius: neuronDrawSize / 2);
      synNeuron.node = node;
      synNeuron.setupDrawingNeuron(isOutput: isOutputNode);
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


    controller = InfiniteCanvasController(
      rawSyntheticNeuronList: rawSyntheticNeuronList,
      syntheticNeuronList: syntheticNeuronList,
      syntheticConnections: syntheticConnections,
      neuronTypes: neuronTypes,
      onLongPress: onLongPress,
      onDoubleTap: () {}, // Pruned logic but required parameter
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
    // V25: Link Config Maps to Controller for Renderer Access
    controller.mapSensoryNeuron = mapSensoryNeuron;
    controller.mapDistanceNeuron = mapDistanceNeuron;
    controller.mapMicrophoneTypeNeuron = mapMicrophoneTypeNeuron;
    controller.mapSpeakerNeuron = mapSpeakerNeuron;
    controller.waveRedraw = waveRedraw; // V25: Bind 60fps simulation pulse to renderer

    controller.zoomReset();
    // V25: Synchronous reset avoids "center snap" visual glitch on initial render
    // By placing it in a Post Frame Callback, we guarantee InteractiveViewer is mounted first!
    WidgetsBinding.instance.addPostFrameCallback((_) {
        _animateCanvasToReset(
          MediaQuery.of(context).orientation == Orientation.landscape,
          animate: false,
          onComplete: () {
            _setCleanBaseline(); // captures blank-brain node/edge counts as baseline
            isSettlingAfterLoad = false;
          },
        );
        _setCleanBaseline(); // immediate baseline capture for safety
    });
    
    controller.maxScale = 2.7;
    controller.scale = 1;
    controller.minScale = 0.85;
    controller.restrictedToNeuronsKey = [
      nodeLeftEyeSensor.key,
      nodeRightEyeSensor.key,
      nodeMicrophoneSensor.key,
      nodeDistanceSensor.key,
    ];

    // V25: Initialize Controller logic for Sensor Trunk Exclusion (SAFE LOCATION)
    controller.isSensorNode = (node) {
      if (node == nodeLeftEyeSensor || 
          node == nodeRightEyeSensor || 
          node == nodeMicrophoneSensor || 
          node == nodeDistanceSensor) {
          return true;
      }
      return false;
    };

    controller.restrictedFromNeuronsKey = [
      nodeLeftMotorForwardSensor.key,
      nodeLeftMotorBackwardSensor.key,
      nodeRightMotorForwardSensor.key,
      nodeRightMotorBackwardSensor.key,
      nodeSpeakerSensor.key,
      nodeSingleLed.key,
      nodeRedLed.key,
      nodeGreenLed.key,
      nodeBlueLed.key,
    ];


    // V25: Proactive Boundary Constraint inside controller
    controller.boundaryConstraint = (node, newOffset) {
        if (coreBrainPainter == null) return newOffset;
        
        // Exclude sensory nodes? Wait, sensors aren't usually dragged this way, 
        // but if they are, they shouldn't be constrained by the core brain boundary.
        // If node type is sensory, allow it to drag anywhere or follow its own rules.
        String nodeLabel = (node.label ?? "").toUpperCase();
        if (node.isSensory == 1 || nodeLabel.contains("EYE") || nodeLabel.contains("CAMERA") || nodeLabel.contains("MIC") || nodeLabel.contains("DISTANCE") || nodeLabel.contains("MOTOR") || nodeLabel.contains("LED")) {
             return newOffset;
        }

        Offset posLocal = newOffset;
        int ordinateGap = 24;
        int diagonalGap = 18;
        
        List<Offset> arrPosConstraints = [
          posLocal.translate(0, -ordinateGap.toDouble()),
          posLocal.translate(-ordinateGap.toDouble(), 0),
          posLocal.translate(0, ordinateGap.toDouble()),
          posLocal.translate(ordinateGap.toDouble(), 0),

          posLocal.translate(-diagonalGap.toDouble(), -diagonalGap.toDouble()),
          posLocal.translate(diagonalGap.toDouble(), -diagonalGap.toDouble()),
          posLocal.translate(-diagonalGap.toDouble(), diagonalGap.toDouble()),
          posLocal.translate(diagonalGap.toDouble(), diagonalGap.toDouble()),
        ];

        if (Platform.isIOS || Platform.isAndroid) {
            double multiplier = 2;
            double neuronDrawSize = 12;
            double gapLeft = neuronDrawSize * 4;
            double posDiagonal = neuronDrawSize * multiplier / 2;
            double posLeft = neuronDrawSize * multiplier / 2;
            double posRight = neuronDrawSize * (multiplier - 3.5);
            double posTop = neuronDrawSize * multiplier;
            double posBottom = neuronDrawSize * (multiplier + 0);

            arrPosConstraints = [
              posLocal.translate(-gapLeft, -posTop), 
              posLocal.translate(-gapLeft - neuronDrawSize * multiplier, 0), 
              posLocal.translate(-gapLeft, posBottom), 
              posLocal.translate(posRight, 0), 

              posLocal.translate(-gapLeft - posLeft, -posTop / 2), 
              posLocal.translate(posRight - posDiagonal, -posTop / 2), 
              posLocal.translate(-gapLeft - posLeft, posBottom - posDiagonal), 
              posLocal.translate(posRight - posDiagonal, posBottom - posDiagonal),
            ];
        }

        // Use the same reference frame as the DragTarget drop zone in
        // getDragTargets(). The DragTarget is positioned at:
        //   X: brainHomeX (= leftBrainPosition)
        //   Y: brainDiff.height * scaleMultiplier + topInnerWindowSpace
        // Previously used brainPosition.dy which drifts during resize
        // because only brainPosition.dx is synced to brainHomeX (line 3420).
        double diffWidth = brainHomeX;
        double diffHeight = brainDiff.height * scaleMultiplier + topInnerWindowSpace;
        double coreBrainGapX = 0.95;
        double coreBrainGapY = 0.85;

        if (Platform.isIOS || Platform.isAndroid) {
          if (isPortrait == false) {
            if (MediaQuery.of(context).size.height >= 600) {
              diffWidth = (windowWidth - currentImageWidth * coreBrainGapX) / 2;
              diffHeight = (currentImageHeight * (1 - coreBrainGapY)) / 2;
            } else {
              coreBrainGapX = 1.1;
              diffWidth = (windowWidth - currentImageWidth * coreBrainGapX) / 2;
              diffHeight = (currentImageHeight * (1 - coreBrainGapY)) / 2;
            }
          } else {
            diffWidth = (windowWidth - currentImageWidth * coreBrainGapX) / 2;
            diffHeight = (windowHeight - currentImageHeight * coreBrainGapY) / 2;
          }
        }

        double translatedDx = diffWidth;
        double translatedDy = diffHeight;
        
        bool flag = true;
        for (Offset checkPos in arrPosConstraints) {
            if (!coreBrainPainter.path.contains(checkPos.translate(-translatedDx, -translatedDy))) {
               flag = false;
               break;
            }
        }
        
        if (flag) {
            return newOffset; // Valid move
        } else {
            // Invalid move, block it
            return node.offset;
        }
    };
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
    
    controller.addListener(() async {

         // ── Annotation Mode: node intercept ──────────────────────────────────────
         // Edge toggling is handled inside controller.checkSelection (pre-notify),
         // so the listener only needs to intercept node (neuron) selections.
         if (isAnnotationMode && controller.selection.isNotEmpty) {
           // Capture selection BEFORE deselectAll clears it
           final List<InfiniteCanvasNode> selected = controller.selection.toList();
           controller.deselectAll(); // clear immediately so no design-mode widget reacts
           if (!_annotationEditEnabled) return; // view-only: block selection changes
           for (final node in selected) {
             // Only toggle actual neurons (not tail at value==-1, not sensors)
             if (node.isSensory == 0 && node.value != -1) {
               final nodeKey = node.key.toString();
               if (controller.annotationHighlightNodeKeys.contains(nodeKey)) {
                 controller.annotationHighlightNodeKeys.remove(nodeKey);
               } else {
                 controller.annotationHighlightNodeKeys.add(nodeKey);
               }
             }
           }
           controller.notifyListeners(); // repaint orange circles
           return;
         }

         // Mark brain as unsaved whenever canvas changes in design mode (skip during loading)
         if (isLoadingBrain || isSettlingAfterLoad || dialogIsSaving) {
           brainHasUnsavedChanges.value = false; // actively clear during load/settle/save
         } else if (!isPlayingMenu && !controller.isInAnnotationMode && !isAnnotationMode && !_suppressUnsavedDuringAnnotation) {
           // Only mark unsaved when graph structure or a node position actually
           // changed from the last clean baseline (set at init, load and save).
           //   _graphChanged  → neuron/edge added or removed
           //   positionDirty  → moveSelection() ran this frame (node was dragged)
           // Tap / pan / zoom / camera animations never set positionDirty and
           // never change counts, so they can never falsely dirty the brain.
           final bool _graphChanged =
               controller.nodes.length != _baselineNodeCount ||
               controller.edges.length != _baselineEdgeCount;
           if (_graphChanged || controller.positionDirty) {
             brainHasUnsavedChanges.value = true;
           }
         }
         // Auto-sync neuronSize to prevent stale simulation state
         if (controller.nodes.isNotEmpty) {
             int currentSize = controller.nodes.length - allNeuronStartIdx;
             if (currentSize < 0) currentSize = 0;
             if (neuronSize != currentSize) {
                 neuronSize = currentSize; // Keep static var in sync
             }
         }
    });

    // RESTORED: Play Mode Selection Listener (Matches neurorobot_fresh behavior)
    // This ensures that tapping a neuron in Live/Play mode updates the oscilloscope.
    controller.addListener(() async {
         // Auto-sync neuronSize to prevent stale simulation state
         if (controller.nodes.isNotEmpty) {
             int currentSize = controller.nodes.length - allNeuronStartIdx;
             if (currentSize < 0) currentSize = 0;
             if (neuronSize != currentSize) {
                 neuronSize = currentSize; // Keep static var in sync
             }
         }

         // Only process wave/pin logic during active simulation
         if (!isPlayingMenu) return;

         if (controller.selection.isNotEmpty) {
            var selected = controller.selection[0];
            // Calculate ID logic mirrored from Line 7770
            int neuronIdx = -1;
neuronIdx = controller.nodes.map((e) => e.id).toList().indexOf(selected.id) - 2;
            
            if (neuronIdx >= 0) {
                 int currentKeyIdx = -999;
                 if (waveWidget.key is ValueKey<String>) { // Check for the combined key
                    String keyString = (waveWidget.key as ValueKey<String>).value;
                    List<String> parts = keyString.split('_');
                    if (parts.isNotEmpty) {
                        currentKeyIdx = int.tryParse(parts[0]) ?? -999;
                    }
                 }
                 
                 if (currentKeyIdx != neuronIdx) { 
                      nativec.changeIdxSelected(neuronIdx);
                      currentWaveNeuronIdx = neuronIdx; // Update the state variable
                      
                      // Wait for C++ Thread
                      await Future.delayed(const Duration(milliseconds: 32));
                      
                      // Reset WaveWidget (Pre-Fill)
                      waveWidget = WaveWidget(
                        key: ValueKey("${currentWaveNeuronIdx}_$currentWaveNeuronIdx2"), 
                        valueNotifier: waveRedraw, 
                        chartGain: chartGain,
                        levelMedian: levelMedian,
                        screenWidth: screenWidth, 
                        screenHeight: screenHeight,
                        neuronIdx1: currentWaveNeuronIdx,
                        neuronIdx2: currentWaveNeuronIdx2,
                        initialVisibleSeconds: currentWaveZoom,
                        onVisibleSecondsChanged: (s) => currentWaveZoom = s,
                      );
                      setState(() {});
                 }
            }

         // Check if Pin 1 (Orange) was removed
         if (currentWaveNeuronIdx != -1) {
            bool stillExists = false;
            placedPins.forEach((key, value) {
               if (value == 10 && key == currentWaveNeuronIdx) stillExists = true;
            });
            if (!stillExists) {
                 printDebug("Pin 1 cleared: neuron $currentWaveNeuronIdx no longer pinned");
                 nativec.changeIdxSelected(-1);
                 currentWaveNeuronIdx = -1;
            }
         }

         // Check if Pin 2 (Blue) was removed
         if (currentWaveNeuronIdx2 != -1) {
            bool stillExists = false;
            placedPins.forEach((key, value) {
               if (value == 11 && key == currentWaveNeuronIdx2) stillExists = true;
            });
            if (!stillExists) {
                 printDebug("Pin 2 cleared: neuron $currentWaveNeuronIdx2 no longer pinned");
                 nativec.changeIdxSelected2(-1);
                 currentWaveNeuronIdx2 = -1;
            }
         }

         // Update Widget Visibility
         if (currentWaveNeuronIdx == -1 && currentWaveNeuronIdx2 == -1) {
             printDebug("All Pins Removed: Hiding Plot");
             waveWidget = Container(
                 color: const Color(0xFF222222),
                 child: const Center(
                   child: Padding(
                     padding: EdgeInsets.all(20.0),
                     child: Text(
                       "Drag a pin onto a neuron to see its activity realtime!",
                       textAlign: TextAlign.center,
                       style: TextStyle(
                         fontFamily: "Roboto",
                         color: Colors.white,
                         fontSize: 16,
                         fontWeight: FontWeight.w400,
                       ),
                     ),
                   ),
                 ));
             setState(() {});
         } else {
             // Rebuild WaveWidget with new state
             waveWidget = WaveWidget(
                key: ValueKey("${currentWaveNeuronIdx}_$currentWaveNeuronIdx2"),
                valueNotifier: waveRedraw,
                chartGain: chartGain,
                screenWidth: 300,
                screenHeight: 90,
                neuronIdx1: currentWaveNeuronIdx,
                neuronIdx2: currentWaveNeuronIdx2,
                initialVisibleSeconds: currentWaveZoom,
                onVisibleSecondsChanged: (s) => currentWaveZoom = s,
                levelMedian: levelMedian);
             setState(() {});
         }
    }
    });

    controller.addListener(() async {
      if (isPlayingMenu) {
        return;
      }
      
      // V25: Safety Reset - prevents stuck state if drag is cancelled
      // V25: Use Fade Out to match original behavior (User Request)
      if (!controller.mouseDown && isDraggingTail) {
          controller.controlPressed = false;
          isDraggingTail = false;
          if (axonStretchHandle != null) {
               soloud?.fadeVolume(axonStretchHandle!, 0, const Duration(milliseconds: 500));
               soloud?.scheduleStop(axonStretchHandle!, const Duration(milliseconds: 500));
               axonStretchHandle = null;
          }
      }
      
      // V25: Sync isDrawTail with selection. If nothing selected, tail must be gone.
      if (!controller.hasSelection) {
          isDrawTail = false;
      }

      // V25: Toggle tail node size to prevent accidental tapping when hidden
      // Refined: Also hide if dragging (User Request: "should vanish" during drag)
      if (isDrawTail && !isDraggingTail && !controller.controlPressed) {
          if (tailNode.size == Size.zero) {
             tailNode.update(size: const Size(24, 24));
          }
      } else {
          if (tailNode.size != Size.zero) {
              tailNode.update(size: Size.zero);
          }
      }

      if (controller.mouseDown) {
        // V25: Call selectEdgeMenuType on RISING EDGE or when switching to a DIFFERENT edge.
        bool edgeChanged = controller.isSelectingEdge && controller.edgeSelected != _previousSelectedEdge;
        if (controller.isSelectingEdge && (!wasSelectingEdge || edgeChanged)) {
           selectEdgeMenuType();
           // Force update to show menu
           setState(() {});
           // V25: Play sound on edge selection (User Request)
           if (neuronOnTouchSource != null) {
              soloud?.play(neuronOnTouchSource!);
           }
        }
        _previousSelectedEdge = controller.edgeSelected;
        wasSelectingEdge = controller.isSelectingEdge;
        
        if (menuIdx == 0 && !controller.hasSelection && !controller.isSelectingEdge) {
          clearUIMenu();

          setState(() => {});

          printDebug('design brain start');
          printDebug(axonFromSelected);
          printDebug(controller.hasSelection);
          printDebug("------------------");
          /* V25: DISABLED TO FIX GHOST SELECTION BUG
          if (!axonFromSelected && controller.hasSelection && !controller.isSelectingEdge) {
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
          } */ 
          if (!controller.isSelectingEdge) {
            isCreatePoint = true;

            double scales = controller.getScale();
            if (scales == 1) {
              // controller.zoomReset();
              // On native, disable canvas move at default zoom (IV handles pan internally).
              // On web, NEVER disable — our custom Listener pan handler depends on canvasMoveEnabled=true.
              if (!kIsWeb) controller.setCanvasMove(false);
              controller.spacePressed = false;
              disallowMoveNodes();
            } else {
              // V25: Only enable pan if NOT dragging an axon (controlPressed) or connection (linkStart)
              if (!controller.controlPressed && controller.linkStart == null) {
                controller.setCanvasMove(true);
                controller.spacePressed = true;
              }
              disallowMoveNodes();
            }

            // USER CLICKING THE PICTURE TO SHOW TRIANGLE TAIL
            printDebug("UserClicking picture to show tail");
            Offset localPosition = controller.toLocal(controller.mousePosition);
            int n = controller.dropTargets.length;
            Offset localOffsetGap = const Offset(0, 0);
            bool isContain = false;
            bool flagIsContain = false;
            int sensoryIdx = -1;
            for (int i = 0; i < n; i++) {
              sensoryIdx = i;
              Map<String, dynamic> neuronInfo = dropTargetInformations[i];
              // if (i == 2) {
              //   // neuronInfo = dropTargetInformations[i + 1];
              // }
              if (i >= 13) continue; // Safety break
              // if (i >= 8) continue; // Exclude outputs (Speaker 8, LED 9) from "Tap to Tail" -- WAIT, we want to drag FROM inputs.
              
              // We need to differentiate between "Tap to Tail" (Sensors -> Neuron) and "Drop to Target" (Neuron -> Actuators)
              // But this loop handles the "Tap to Tail" initiation.
              
              // Use brainCenterX (orientation-aware) for consistent hit-test with drop targets
              double brainCenterX = brainHomeX + 245 * scaleMultiplier;
              Offset containOffset = localPosition.translate(
                  -(brainCenterX +
                          neuronInfo["posXDiff"] * scaleMultiplier) +
                      localOffsetGap.dx,
                  -(neuronInfo["top"] * scaleMultiplier + topInnerWindowSpace) +
                      localOffsetGap.dy);

              GeneralSensorPainter painter = (listPainters[i]);
              isContain = painter.path.contains(containOffset);
              if (isContain) {
                printDebug("isContainIMAGE: $i, $n");
                flagIsContain = true;
                // if (i >= 7) {
                //   InfiniteCanvasNode sensoryNode = sensoryNeurons[i + 1];
                //   isDrawTail = true;
                //   isTailCreated = false;
                //   isDeleteMenu = false;
                //   isTailType = "triangle";
                //   neuronStyle = "Excitatory";
                //   controller.setSelection({sensoryNode.key});
                // } else {
                  InfiniteCanvasNode sensoryNode = sensoryNeurons[i];
                  
                  // Only allow drawing connection tail from INPUT sensors (0:Dist, 1:LeftEye, 2:RightEye, 7:Mic)
                  bool isInputSensor = [0, 1, 2, 7].contains(i);
                  isDrawTail = isInputSensor;
                  
                  if (isInputSensor) {
                    isTailCreated = false;
                    isDeleteMenu = false;
                    isTailType = "triangle";
                    neuronStyle = "Excitatory";
                    controller.setSelection({sensoryNode.key});
                  } else {
                    // V25 FEATURE: Do not "select" output components to prevent nucleus growth/sounds.
                    // Just cleanly dismiss any active menus and only show their tooltip.
                    // CRITICAL: Only call deselectAll() if something is actually selected.
                    // deselectAll() fires notifyListeners() which re-enters THIS listener.
                    // Since output sensors are rejected by checkSelection (isOutput=true),
                    // hasSelection is already false, causing infinite re-entry → stack overflow.
                    if (controller.hasSelection) controller.deselectAll();
                    int labelIdx = listDefaultSensor.indexOf(sensoryNode);
                    if (labelIdx != -1) {
                      final screenPos = MatrixUtils.transformPoint(controller.matrix, sensoryNode.offset);
                      tooltipOverlayX = screenPos.dx;
                      tooltipOverlayY = screenPos.dy;
                      tooltipOverlayMessage = listDefaultSensorLabel[labelIdx];
                      isTooltipOverlay = true;
                      tooltipValueChange.value = (Random().nextInt(10000));
                      debouncerTooltip.run(() {
                        isTooltipOverlay = false;
                        tooltipValueChange.value = (Random().nextInt(10000));
                      });
                    }
                  }
                // }
                setState(() {});
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
            //   controller.setSelection({temporaryEdge[1]}, true);
            //   setState((){});
            // }
          }
        } else if (menuIdx == 0 && controller.controlPressed) {
          RenderBox box = context.findRenderObject() as RenderBox;
          // WEB: mousePosition is already in local (viewport) coordinates.
          // Native: mousePosition is global, so convert via globalToLocal.
          Offset viewportPoint = kIsWeb
              ? controller.mousePosition
              : box.globalToLocal(controller.mousePosition);
          Offset localPosition = controller.toLocal(viewportPoint);
          double mouseX = localPosition.dx;
          double mouseY = localPosition.dy;
          // printDebug("mouse:");
          // printDebug(mouseX);
          // printDebug(mouseY);
          int n = controller.dropTargets.length;
          Offset localOffsetGap = const Offset(0, 0);
          bool isContain = false;
          bool flagIsContain = false;
          int nodeContainIdx = -1;
          int idx = -1;
          for (int i = 0; i < n; i++) {
            Map<String, dynamic> neuronInfo = dropTargetInformations[i];
            idx = i;
            // if (i >= 2) {
            //   neuronInfo = dropTargetInformations[i];
            // Use brainCenterX (orientation-aware) for consistent hit-test with drop targets
            double brainCenterX = brainHomeX + 245 * scaleMultiplier;
            Offset containOffset = localPosition.translate(
                -(brainCenterX +
                        neuronInfo["posXDiff"] * scaleMultiplier) +
                    localOffsetGap.dx,
                -(neuronInfo["top"] * scaleMultiplier +
                    topInnerWindowSpace) +
                    localOffsetGap.dy);

            GeneralSensorPainter painter = (listPainters[i]);
            // V25: Fuzzy hit test (check center + small radius) to improve connection reliability
            double hitMargin = 25.0 / controller.getScale();
            isContain = painter.path.contains(containOffset) ||
                        painter.path.contains(containOffset + Offset(hitMargin, hitMargin)) ||
                        painter.path.contains(containOffset + Offset(-hitMargin, -hitMargin)) ||
                        painter.path.contains(containOffset + Offset(hitMargin, -hitMargin)) ||
                        painter.path.contains(containOffset + Offset(-hitMargin, hitMargin));
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
                // if (i >= 7) {
                //   temporaryEdge.add(sensoryNeurons[i + 1].key);
                // } else {
                  temporaryEdge.add(sensoryNeurons[i].key);
                // }
                printDebug(temporaryEdge);
              }
              // if (i >= 7) {
              //   nodeContainIdx = i + 1;
              // } else {
                nodeContainIdx = i;
              // }
            } else {
              // printDebug("is Not Contain: $i, $n, $isTemporaryEdge");
            }
          }
          if (flagIsContain) {
            // printDebug("isContain $flagIsContain $nodeContainIdx");
            mapBg["activeBg"] = greyBg;
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
                    if (soloud != null &&
                        soloud!.isInitialized &&
                        neuronOnTouchSource != null) {
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
            mapBg["activeBg"] = greyBg;
            mapBg["activeComponent"] = noActiveComponent;
          }
          debouncerActiveComponent.run(() {
            setState(() {});
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
              final screenPos = MatrixUtils.transformPoint(controller.matrix, selected.offset);
              tooltipOverlayX = screenPos.dx;
              tooltipOverlayY = screenPos.dy;
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

          if (selected == tailNode && prevSelectedNeuron != null) {
            controller.deselectAll();
            controller.setSelection({prevSelectedNeuron!.key});
            controller.controlPressed = true;
            controller.setCanvasMove(false); // V25: Disable panning during tail drag
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
            if (!foundSelected) {
              // Only run tooltip-dismiss logic if we did NOT just activate a sensor tooltip above.
              // Without this guard, output sensors (speaker, motor, LED) would have their
              // tooltip set to true at line 10783 then immediately dismissed here.
              if (!isTooltipOverlay) {
                isDeleteMenu = true;
              } else {
                if (!listSensorArrow.contains(selected)) {
                  // V25 BUGFIX: If we tap a regular neuron while the sensor tooltip is up, 
                  // dismiss the tooltip immediately and DO NOT return, so the neuron gets selected on the first tap.
                  isTooltipOverlay = false;
                  isDeleteMenu = true;
                }
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
            } else if (prevSelectedOffsetNode != null &&
                prevSelectedNode != null) {
              // MOVING NODE
              if (prevSelectedNode == selected &&
                  prevSelectedOffsetNode != selected.offset &&
                  isMovingNodeFirstTime) {
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
            if (prevSelectedNode?.id != selected.id) {
              isNeuronBehaviorExpanded = false;
            }
            prevSelectedNode = selected;
            prevSelectedOffsetNode = selected.offset;
            prevSelectedNeuron = selected;
            
            // V25 FEATURE: Only allow connection tails from valid inputs. Outputs cannot originate connections.
            bool allowTail = true;
            if (listDefaultSensor.contains(selected)) {
               // Only Input Sensors can have a tail drawn FROM them
               if (selected == nodeDistanceSensor || 
                   selected == nodeLeftEyeSensor || 
                   selected == nodeRightEyeSensor || 
                   selected == nodeMicrophoneSensor) {
                   allowTail = true;
               } else {
                   allowTail = false;
               }
            }
            
            isDrawTail = allowTail;
            isDeleteMenu = true;
            if (neuronStyles[selected.id] == "Excitatory") {
              isTailType = "triangle";
            } else {
              isTailType = "circle";
            }

            if (listDefaultSensor.contains(selected)) {
              setState(() {});
            } else {
              // Immediate repaint so clone/delete tooltip appears without delay.
              // The full neuron menu + wave widget setState follows after await below.
              setState(() {});
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

                // Fix RangeError: Ensure list is large enough (Hotfix for size mismatch)
                if (neuronIdx >= mapDelayNeuronList.length) {
                    printDebug("Fixing Delay List Size Mismatch: ${mapDelayNeuronList.length} -> ${neuronSize}");
                    // Resize to match actual neuronSize or at least cover this index
                    int newSize = max(neuronSize, neuronIdx + 1);
                    var newList = List<int>.generate(newSize, (i) {
                         if (i < mapDelayNeuronList.length) return mapDelayNeuronList[i];
                         return -1;
                    });
                    mapDelayNeuronList = newList;
                }
                
                // Fix Missing Slider: Check Type, not just List Value
                if (neuronMenuType == "Delay") {
                  isShowDelayTime = true;
                  // Auto-init to valid value if invalid (-1 or 0)
                  if (mapDelayNeuronList[neuronIdx] <= 0) {
                     mapDelayNeuronList[neuronIdx] = minDelayTimeValue.toInt();
                  }
                  
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
                  // sldTimeValue = minDelayTimeValue.toDouble();
                }

                // Load bound key label for Remote Control neurons
                if (neuronMenuType == "Remote Control") {
                  _remoteControlBoundKeyLabel = mapRemoteControlNeuron[selected.id] ?? "";
                } else {
                  _remoteControlBoundKeyLabel = "";
                  _isListeningForRemoteInput = false;
                }

                if (neuronMenuType != "Custom") {
                    double valA = 0.02; double valB = 0.1; double valC = -65; double valD = 2;
                    switch (neuronMenuType) {
                        case "Quiet":
                          valA = 0.02; valB = 0.1; valC = -65; valD = 2;
                          break;
                        case "Occassionally active":
                          valA = 0.02; valB = 0.17; valC = -65; valD = 2;
                          break;
                        case "Highly active":
                          valA = 0.02; valB = 0.24; valC = -65; valD = 2;
                          break;
                        case "Generates bursts":
                          valA = 0.02; valB = 0.17; valC = -20; valD = 2;
                          break;
                        case "Bursts when activated":
                        case "Delay": 
                          valA = 0.02; valB = 0.1; valC = -37; valD = 2;
                          break;
                        case "Remote Control":
                        case "Motion":
                          valA = 0.02; valB = 0.1; valC = -65; valD = 2;
                          break;
                    }
                    aDesignArray[selected.id] = valA;
                    bDesignArray[selected.id] = valB;
                    cDesignArray[selected.id] = valC;
                    dDesignArray[selected.id] = valD;
                }

                sldAWeight = aDesignArray[selected.id] ?? 0.02;
                sldBWeight = bDesignArray[selected.id] ?? 0.1;
                sldCWeight = (cDesignArray[selected.id] ?? -65).floorToDouble();
                sldDWeight = (dDesignArray[selected.id] ?? 2).floorToDouble();

                tecAWeight.text = sldAWeight.toString();
                tecBWeight.text = sldBWeight.toString();
                tecCWeight.text = sldCWeight.round().toString();
                tecDWeight.text = sldDWeight.round().toString();

              } catch (err) {
                printDebug("err init canvas");
                printDebug(err);
              }

              // Immediate repaint so tooltip + neuron menu appear without delay.
              setState(() => {});

              // Deferred: Wait for C++ thread, then update wave widget (non-blocking).
              try {
                int deferredIdx = controller.nodes
                        .map((e) => e.id)
                        .toList()
                        .indexOf(selected.id) -
                    2;
                Future.delayed(const Duration(milliseconds: 32), () {
                  if (!mounted) return;
                  nativec.changeIdxSelected(deferredIdx);
                  waveWidget = WaveWidget(
                    key: ValueKey(deferredIdx),
                    valueNotifier: waveRedraw,
                    chartGain: chartGain,
                    levelMedian: levelMedian,
                    screenWidth: screenWidth,
                    screenHeight: screenHeight,
                    neuronIdx1: currentWaveNeuronIdx,
                    neuronIdx2: currentWaveNeuronIdx2,
                    initialVisibleSeconds: currentWaveZoom,
                    onVisibleSecondsChanged: (s) => currentWaveZoom = s,
                  );
                  setState(() => {});
                });
              } catch (err) {
                printDebug("err deferred wave init: $err");
              }
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
                //                 // printDebug("$windowWidth - $currentImageWidth");
                // printDebug(prevInitialFrameGapWidth);
                // printDebug(translatedDx);
                // if (Platform.isIOS || Platform.isAndroid) {
                //   leftCirclePos = prevInitialFrameGapWidth! / 2 + 0 + pos.dx;
                //   topCirclePos = prevInitialFrameGapHeight! / 2 + 0 + pos.dy;
                // }
                // }
                if (!coreBrainPainter.path
                    .contains(pos.translate(-translatedDx, -translatedDy))) {


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
                  // V25 Disable retroactive bounding to fix flicker
                  // selected.update(offset: prevConstrainedPos);
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
            if (!kIsWeb) controller.setCanvasMove(false);
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
              isComplex: !kIsWeb,
              willChange: !kIsWeb,
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
          refreshNuclei();

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

          int neuronIdx = -1;
neuronIdx = controller.nodes.map((e) => e.id).toList().indexOf(selected.id) - 2;

          nativec.changeIdxSelected(neuronIdx);
          redrawNeuronLine.value = Random().nextInt(100);
          
          // Wait for C++ Thread to update canvasBuffer with new neuron history
          // (Sim runs at 1000Hz, this is plenty of time)
          // Wait for C++ Thread to update canvasBuffer with new neuron history
          await Future.delayed(const Duration(milliseconds: 32));
          
          // Force Clean Slate for WaveWidget
          waveWidget = WaveWidget(
            key: ValueKey(neuronIdx), 
            valueNotifier: waveRedraw, 
            chartGain: chartGain,
            levelMedian: levelMedian,
            screenWidth: screenWidth, 
            screenHeight: screenHeight,
            initialVisibleSeconds: waveZoom,
            onVisibleSecondsChanged: (val) { waveZoom = val; }
          );
          
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
                  setState(() {});
                  MyApp.logAnalytic("CreateAxon",
                      {"timestamp": DateTime.now().millisecondsSinceEpoch});
                } else {
                  mapBg["activeBg"] = defaultBg;
                  mapBg["activeComponent"] = noActiveComponent;
                  setState(() {});
                }
                controller.controlPressed = false;
                controller.deselectAll();
              });
              controller.controlPressed = false;
              controller.deselectAll();
              clearUIMenu();
              setState(() {});
            }
          }
        }
        if (isDraggingTail) {
          soloud?.fadeVolume(
              axonStretchHandle!, 0, const Duration(milliseconds: 500));
          soloud?.scheduleStop(
              axonStretchHandle!, const Duration(milliseconds: 500));
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
        try {
          if (soloud != null && neuronSpikesHandle != null) {
            soloud?.fadeVolume(
                neuronSpikesHandle!, 0, const Duration(milliseconds: 500));
            soloud?.scheduleStop(
                neuronSpikesHandle!, const Duration(milliseconds: 500));
          }
        } catch (err) {
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
        
    // V25: Debugging crash - if not found, log it and return first to crash (preserving behavior for valid flows)
    // or better, throw explicit error.
    if (list.isEmpty) {
        printDebug("CRITICAL ERROR: findNeuronByKey failed for key $key");
        // We can't return null because return type is non-nullable. 
        // Returning a dummy or throwing is the only option without refactoring everything.
        // For now, let's keep it throwing but add a Safe version.
        throw Exception("Neuron not found: $key");
    }
    return list[0];
  }

  InfiniteCanvasNode? findNeuronByKeySafe(key) {
    var list = controller.nodes
        .where((element) => element.key == key)
        .toList(growable: false);
    if (list.isEmpty) return null;
    return list[0];
  }

  void linkLedConnection(double vals) {
    String value = vals.toString();
    if (value.trim().isEmpty) return;
    double val = double.parse(value);
    if (val > 100) {
      val = 100;
    }

    final lastCreatedEdge = controller.edgeSelected!;
    final neuronFrom = findNeuronByKey(lastCreatedEdge.from);
    final neuronTo = findNeuronByKey(lastCreatedEdge.to);
    mapLedNeuron["${neuronFrom.id}_${neuronTo.id}"] = val;
    controller.edgeSelected!.connectionStrength = val;
    // updateSyntheticConnection(neuronFrom.key, neuronTo.key, val);
  }

  void linkLedAxon(
      double vals, InfiniteCanvasNode neuronFrom, InfiniteCanvasNode neuronTo) {
    String value = vals.toString();
    if (value.trim().isEmpty) return;
    double val = double.parse(value);
    if (val > 100) {
      val = 100;
    }

    try {
      mapLedNeuron["${neuronFrom.id}_${nodeRedLed.id}"] =
          double.parse(tecSynapticWeightR.text);
      mapLedNeuron["${neuronFrom.id}_${nodeGreenLed.id}"] =
          double.parse(tecSynapticWeightG.text);
      mapLedNeuron["${neuronFrom.id}_${nodeBlueLed.id}"] =
          double.parse(tecSynapticWeightB.text);

      double subtotal = max(
          (mapLedNeuron["${neuronFrom.id}_${nodeRedLed.id}"] ?? 0),
          (mapLedNeuron["${neuronFrom.id}_${nodeGreenLed.id}"] ?? 0));
      subtotal = max(
          subtotal, (mapLedNeuron["${neuronFrom.id}_${nodeBlueLed.id}"] ?? 0));

      int redColor =
          (mapLedNeuron["${neuronFrom.id}_${nodeRedLed.id}"] / 100 * 255)
              .floor();
      int greenColor =
          (mapLedNeuron["${neuronFrom.id}_${nodeGreenLed.id}"] / 100 * 255)
              .floor();
      int blueColor =
          (mapLedNeuron["${neuronFrom.id}_${nodeBlueLed.id}"] / 100 * 255)
              .floor();
      String hexColor = rgbToHex(redColor, greenColor, blueColor);
      tecHexColor.text = hexColor;

      // controller.edgeSelected.connectionStrength = subtotal / 3;
      controller.edgeSelected!.connectionStrength = subtotal;
      // neuronFrom.syntheticNeuron.blackBrush = Paint()
      //   ..color = Color.fromARGB(255, redColor, greenColor, blueColor)
      //   // ..color = Colors.yellow
      //   ..style = PaintingStyle.fill
      //   ..strokeWidth = 2;
      // controller.edgeSelected.color =
      //     Color.fromARGB(255, redColor, greenColor, blueColor);
      controller.edgeSelected!.color = Colors.transparent;
    } catch (err) {
      printDebug("err");
      printDebug(err);
    }
    // updateSyntheticConnection(neuronFrom.key, neuronTo.key, val);
  }

  // V23: LED Widget Color Callback
  void _updateLedColor(String hex, String brightness) {
    _robotLedHex = hex;
    _robotLedBrightness = brightness;
    
    if (controller.isSelectingEdge) {
      InfiniteCanvasEdge edge = controller.edgeSelected!;
      InfiniteCanvasNode neuronFrom = findNeuronByKey(edge.from);
      InfiniteCanvasNode neuronTo = findNeuronByKey(edge.to);
      String key = "${neuronFrom.id}_${neuronTo.id}";
      
      Color c = Color(int.parse("0xFF$hex"));
      double b = double.tryParse(brightness) ?? 1.0;
      
      // Linear brightness: widget sends 0.01-1.0 directly as LED output strength
      double trueStrength = b.clamp(0.01, 1.0);
      
      // Write scaled weights (0-100) to mapLedNeuron for simulation (ALWAYS needed)
      mapLedNeuron["${neuronFrom.id}_${nodeRedLed.id}"] = (c.red.toDouble() / 255 * 100) * trueStrength;
      mapLedNeuron["${neuronFrom.id}_${nodeGreenLed.id}"] = (c.green.toDouble() / 255 * 100) * trueStrength;
      mapLedNeuron["${neuronFrom.id}_${nodeBlueLed.id}"] = (c.blue.toDouble() / 255 * 100) * trueStrength;

      // V25: Only set color on LED edges - prevents pollution to non-LED axons
      bool isLedEdge = edge.to == nodeSingleLed.key || 
                       edge.to == nodeRedLed.key || 
                       edge.to == nodeGreenLed.key || 
                       edge.to == nodeBlueLed.key;
      
      if (isLedEdge) {
        mapLedHex[key] = hex;
        mapLedBrightness[key] = brightness;
        // Visual Appearance of Axon
        edge.color = c.withOpacity(trueStrength > 0.1 ? trueStrength : 0.1); 
        edge.isLedEdge = true;
        edge.connectionStrength = trueStrength * 100.0;
        if (edge.connectionStrength < 1.0) edge.connectionStrength = 1.0;
      }
      
      // V23: Update sinapticValue in synapse structure for real-time axon thickness
      try {
        int fromIdx = controller.syntheticNeuronList.indexWhere((s) => s.node?.key == edge.from);
        int toIdx = controller.syntheticNeuronList.indexWhere((s) => s.node?.key == edge.to);
        if (fromIdx >= 0 && toIdx >= 0 && toIdx < controller.syntheticNeuronList.length) {
          var neuronTo = controller.syntheticNeuronList[toIdx].newNeuron;
          for (var dendrite in neuronTo.dendrites) {
            for (var synapse in dendrite.sinapseFirstLevel) {
              if (synapse.presinapticNeuronIndex == fromIdx) {
                synapse.sinapticValue = edge.connectionStrength / 2;
              }
            }
            for (var synapse in dendrite.sinapseSecondLevel) {
              if (synapse.presinapticNeuronIndex == fromIdx) {
                synapse.sinapticValue = edge.connectionStrength / 2;
              }
            }
          }
        }
      } catch (e) {
        printDebug("_updateLedColor synapse update error: $e");
      }
    }
    _updateLedAddress();
  }

  // V23: LED Widget Address/Position Callback
  void _updateLedAddress() {
    if (controller.isSelectingEdge) {
      InfiniteCanvasEdge edge = controller.edgeSelected!;
      InfiniteCanvasNode neuronFrom = findNeuronByKey(edge.from);
      mapLedNeuronPosition["${neuronFrom.id}_${nodeRedLed.id}"] = _robotLedActive;
      mapLedNeuronPosition["${neuronFrom.id}_${nodeGreenLed.id}"] = _robotLedActive;
      mapLedNeuronPosition["${neuronFrom.id}_${nodeBlueLed.id}"] = _robotLedActive;
      setState(() {});
    }
  }

  void linkNeuronConnection(value) {
    // printDebug("neuron");
    // printDebug(value);
    if (value.trim().length == 0) return;
    double val = double.parse(value);
    if (val > 100) {
      val = 100;
    }
    final lastCreatedEdge = controller.edgeSelected!;
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
    // print("DEBUG: linkMotorConnection called with: $value"); // TRACE CALL
    // uiDebugLog = "LINK_MOT: $value\n" + uiDebugLog;
    if (value.trim().isEmpty) return;
    double val = double.parse(value);
    if (val > 100) {
      val = 100;
    }

    final lastCreatedEdge = controller.edgeSelected!;
    final neuronFrom = findNeuronByKey(lastCreatedEdge.from);
    final neuronTo = findNeuronByKey(lastCreatedEdge.to);

    // mapContactsNeuron["${lastCreatedEdge.from}_${lastCreatedEdge.to}"] = val;
    String motorKey = "${neuronFrom.id}_${neuronTo.id}";
    mapContactsNeuron[motorKey] = val;
    controller.mapContactsNeuron = Map.from(mapContactsNeuron); // SYNC TO CONTROLLER (Critical for persistence)
    printDebug("DEBUG: linkMotorConnection Updated Key: $motorKey = $val");
    uiDebugLog = "Mot: $motorKey -> ${val.toStringAsFixed(1)}\n" + uiDebugLog; // Prepend for visibility
    
    lastCreatedEdge.connectionStrength = val;
    lastCreatedEdge.label = val.floor().toString();
    

    
    // CRITICAL FIX: Update live buffer immediately using correct indices (populateMatrix skips motors!)
    updateLiveConnectionBuffer(neuronFrom, neuronTo, val, "motor");
  }

  void linkSensoryConnection(value) {
    printDebug("sensory");
    printDebug(value);
    final selectedEdge = controller.edgeSelected!;
    final neuronFrom = findNeuronByKey(selectedEdge.from);
    final neuronTo = findNeuronByKey(selectedEdge.to);
    String neuronFromToLabel = "${neuronFrom.id}_${neuronTo.id}";
    selectedEdge.label = lookup[value] ?? value;
    // mapSensoryNeuron["${lastCreatedEdge.from}_${lastCreatedEdge.to}"] = value;
    if (!isLoadingBrain && !isSettlingAfterLoad) brainHasUnsavedChanges.value = true; // camera detection type changed
    mapSensoryNeuron[neuronFromToLabel] = cameraMenuTypes.indexOf(value);
    controller.mapSensoryNeuron = Map.from(mapSensoryNeuron); // SYNC TO CONTROLLER
  }

  void linkAreaSizeConnection(
      {String? selectedCameraPosition,
      InfiniteCanvasNode? nodeFrom,
      InfiniteCanvasNode? nodeTo}) {
    String neuronFromToLabel = "";
    int neuronIdx = -1;
    if (nodeFrom != null && nodeTo != null) {
      neuronFromToLabel = "${nodeFrom.id}_${nodeTo.id}";
      neuronIdx = neuronTypes.keys.toList().indexOf(nodeTo.id);
    } else {
      final selectedEdge = controller.edgeSelected!;
      final neuronFrom = findNeuronByKey(selectedEdge.from);
      final neuronTo = findNeuronByKey(selectedEdge.to);
      neuronFromToLabel = "${neuronFrom.id}_${neuronTo.id}";
      neuronIdx = neuronTypes.keys.toList().indexOf(neuronTo.id);
    }

    if (neuronIdx == -1) return;

    if (selectedCameraPosition == "Custom") {
      mapAreaSize[neuronFromToLabel] =
          "${selectedCameraPosition}_@_${areaSizeMinLimitBufView[neuronIdx]}_@_${areaSizeMaxLimitBufView[neuronIdx]}";
    } else if (selectedCameraPosition == "Left") {
      mapAreaSize[neuronFromToLabel] = "${selectedCameraPosition}_@_1_@_160";
    } else if (selectedCameraPosition == "Right") {
      mapAreaSize[neuronFromToLabel] = "${selectedCameraPosition}_@_161_@_320";
    } else if (selectedCameraPosition == "Any") {
      mapAreaSize[neuronFromToLabel] = "${selectedCameraPosition}_@_1_@_320";
    }
  }

  void linkDistanceConnection(value) {
    final lastCreatedEdge = controller.edgeSelected!;
    final neuronFrom = findNeuronByKey(lastCreatedEdge.from);
    final neuronTo = findNeuronByKey(lastCreatedEdge.to);
    lastCreatedEdge.label = value;
    // mapDistanceNeuron["${lastCreatedEdge.from}_${lastCreatedEdge.to}"] = value;
    mapDistanceNeuron["${neuronFrom.id}_${neuronTo.id}"] =
        distanceMenuTypes.indexOf(value);
    controller.mapDistanceNeuron = Map.from(mapDistanceNeuron); // SYNC TO CONTROLLER
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

  void linkMicrophoneConnection() {
    // 0 = active, -1 = inactive
    for (int i = 0; i < neuronSize; i++) {
        neuronMicrophoneBufView[i] = -1;
    }
    
    for (InfiniteCanvasEdge edge in controller.edges) {
       InfiniteCanvasNode nodeFrom = findNeuronByKey(edge.from);
       if (nodeFrom.id == nodeMicrophoneSensor.id) {
          try {
            InfiniteCanvasNode node = findNeuronByKey(edge.to);
            int idx = neuronTypes.keys.toList().indexOf(node.id);
            if (idx == -1) {
                printDebug("Error: Node ID ${node.id} not found in neuronTypes");
                continue;
            }
            neuronMicrophoneBufView[idx] = 50;

            String key = "${nodeMicrophoneSensor.id}_${node.id}";
            printDebug("MicLink: Node $idx (${node.id}) Key: $key");
            
            // Check TYPE
            int currentMicMode = 2; // Default Tone
            if (mapMicrophoneTypeNeuron.containsKey(key)) {
                currentMicMode = mapMicrophoneTypeNeuron[key];
                printDebug("  Found Type: $currentMicMode");
            } else {
                printDebug("  Type NOT found in map. Keys: ${mapMicrophoneTypeNeuron.keys.take(3)}...");
            }
            microphoneTypeBufView[idx] = currentMicMode;

            // Check LIMITS
            if (mapMicrophoneLimitNeuron.containsKey(key)) {
                printDebug("  Found Limits: ${mapMicrophoneLimitNeuron[key]}");
                try {
                   String temp = mapMicrophoneLimitNeuron[key];
                   List<String> arr = temp.split("_@_");
                   microphoneMinLimitBufView[idx] = double.parse(arr[0]).toInt();
                   microphoneMaxLimitBufView[idx] = double.parse(arr[1]).toInt();
                } catch(e) { printDebug("  Error parsing limits: $e"); }
            } else {
                 printDebug("  Limits NOT found in map.");
            }

            if (!mapMicrophoneLimitNeuron.containsKey(key)) { // New connection: always init defaults
                 // Defaults
                 if (currentMicMode == 2) { // Tone
                    microphoneMinLimitBufView[idx] = 0;
                    microphoneMaxLimitBufView[idx] = 0;
                 } else if (currentMicMode == 1) { // Vol
                    microphoneMinLimitBufView[idx] = 800;
                    microphoneMaxLimitBufView[idx] = 2000;
                 } else { // Freq
                    microphoneMinLimitBufView[idx] = 400;
                    microphoneMaxLimitBufView[idx] = 800;
                 }
                mapMicrophoneLimitNeuron[key] = "${microphoneMinLimitBufView[idx]}_@_${microphoneMaxLimitBufView[idx]}"; 
                controller.mapMicrophoneLimitNeuron[key] = mapMicrophoneLimitNeuron[key]; 
            }
            
            // Set Edge Label
            if (currentMicMode == 2) { // Tone
                List<String> noteNames = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"];
                int noteIndex = microphoneMinLimitBufView[idx].clamp(0, 11);
                edge.label = noteNames[noteIndex];
            } else if (currentMicMode == 1) {
                edge.label = "Volume";
            } else {
                edge.label = "Frequency"; 
            }
            
            // SYNC TO CONTROLLER for Icon Rendering
            controller.mapMicrophoneTypeNeuron[key] = currentMicMode;
            controller.mapMicrophoneLimitNeuron[key] = "${microphoneMinLimitBufView[idx]}_@_${microphoneMaxLimitBufView[idx]}";
            controller.mapMicrophoneNeuron[key] = neuronMicrophoneBufView[idx];

            printDebug("LINKED MIC to Neuron $idx (Key: ${node.id}) Mode: $currentMicMode Label: ${edge.label}");
         } catch (e) {
            printDebug("Error linkMicrophoneConnection $e");
         }
      }
    }
    // printDebug("Mic Link Complete. Total Edges: ${controller.edges.length}");
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
    //       controller.nodes.indexWhere((e) => e.id == selected.id) - 2;
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

  // onDoubleTap pruned from Controller

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

  String populateNode(v, nodeKey, nIdx, Map<String, dynamic> syntheticNeuronJson,
      savedFileJson) {
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

    Offset newNodeOffset =
        Offset(v["position"][0].toDouble(), v["position"][1].toDouble());
    if (Platform.isAndroid || Platform.isIOS) {
    } else {
      newNodeOffset = newNodeOffset.scale(curScale, curScale);
    }
    InfiniteCanvasNode tempNode = InfiniteCanvasNode(
      value: nIdx, // CRITICAL FIX: Use packed index 'nIdx', NOT raw 'v["index"]' which may be duplicated/skipped
      key: nodeKey,
      offset: newNodeOffset,
      size: Size(neuronDrawSize, neuronDrawSize),
      allowResize: false,
      isSensory: (v["index"] != null && v["index"] < 13) ? 1 : 0, // V25: Restore Sensory Flag for Loaded Sensors
      child: Builder(
        builder: (context) {
          return CustomPaint(
            isComplex: !kIsWeb,
            willChange: false,
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
    _nodeAnnotationKeys[tempNode.id] = (v["annKey"] as String?) ?? tempNode.valKey;
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
            xTriangleSecondLevel:
                dendriteJson["xTriangleSecondLevel"].toDouble(),
            yTriangleFirstLevel: dendriteJson["yTriangleFirstLevel"].toDouble(),
            yTriangleSecondLevel:
                dendriteJson["yTriangleSecondLevel"].toDouble());

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
      rawSyntheticNeuronList.add(rawSyntheticNeuron);
      syntheticNeuron.rawSyntheticNeuron = rawSyntheticNeuron;

      rawSyntheticNeuronList.add(rawSyntheticNeuron);
    }
    printDebug("tempNode.key");
    printDebug(tempNode.id);
    controller.nodes.add(tempNode);
    return tempNode.id;
  }

  /// Crops the screenshot to a square centered on the brain artwork.
  /// [tx] and [ty] are the translation applied by _animateCanvasToReset — the brain center in
  /// the screenshot is at (imgW/2 + tx, imgH/2 + ty), not necessarily at the image center.
  Future<Uint8List> _cropScreenshotToBrainSquare(Uint8List src, {double tx = 0, double ty = 0}) async {
    try {
      final codec = await ui.instantiateImageCodec(src);
      final srcImg = (await codec.getNextFrame()).image;
      final double imgW = srcImg.width.toDouble();
      final double imgH = srcImg.height.toDouble();

      // The brain background fills the full scene space; its center in the screenshot is:
      final double cx = imgW / 2 + tx;
      final double cy = imgH / 2 + ty;

      // Use the shorter image dimension as the square side
      final double side = min(imgW, imgH);
      final double cropX = (cx - side / 2).clamp(0.0, imgW - side);
      final double cropY = (cy - side / 2).clamp(0.0, imgH - side);

      final rec = ui.PictureRecorder();
      ui.Canvas(rec).drawImageRect(
        srcImg,
        Rect.fromLTWH(cropX, cropY, side, side),
        Rect.fromLTWH(0, 0, side, side),
        ui.Paint(),
      );
      final cropped = await rec.endRecording().toImage(side.toInt(), side.toInt());
      final bd = await cropped.toByteData(format: ui.ImageByteFormat.png);
      srcImg.dispose();
      cropped.dispose();
      return bd?.buffer.asUint8List() ?? src;
    } catch (e) {
      printDebug('Screenshot crop error: $e');
      return src;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  //  ANNOTATION MODE HELPERS
  // ═══════════════════════════════════════════════════════════════

  void _enterAnnotationMode() {
    controller.lockNodeDragging = true;
    controller.isInAnnotationMode = true;
    controller.clearAnnotationHighlights();
    controller.annotationEditEnabled = true;
    _annotationDescController.clear();
    _isEditingAnnotation = false;
    _editingAnnotationIdx = -1;
    _annotationEditEnabled = true; // new annotations are immediately editable
    setState(() { isAnnotationMode = true; });
  }

  void _exitAnnotationMode() {
    // Capture unsaved state before exiting — the home animation's final
    // notifyListeners() fires after isInAnnotationMode is cleared, which
    // would falsely mark the brain as unsaved. Restore the correct state
    // in onComplete, which runs immediately after that notify.
    final bool _hadUnsaved = brainHasUnsavedChanges.value;
    controller.lockNodeDragging = false;
    controller.isInAnnotationMode = false;
    controller.clearAnnotationHighlights();
    controller.annotationEditEnabled = false;
    _annotationDescController.clear();
    _isEditingAnnotation = false;
    _editingAnnotationIdx = -1;
    _annotationEditEnabled = false;
    setState(() { isAnnotationMode = false; });
    // Animate the brain back to the home position, same as play/pause/load.
    _animateCanvasToReset(true, onComplete: () {
      // Restore exact unsaved state (home-animation notify fired above).
      brainHasUnsavedChanges.value = _hadUnsaved;
      // Only NOW lift the suppression — the exit animation's notifyListeners()
      // has already fired and been neutralised by the line above.
      _suppressUnsavedDuringAnnotation = false;
    });
  }

  // ── Phase 3: Thumbnail — real viewport screenshot cropped to selection ────
  //
  // Uses screenshotController to capture the live-rendered canvas (showing
  // real SyntheticNeuron graphics), then crops to the screen-space bounding
  // box of the selected nodes / axon path extents.

  Future<Uint8List> _captureAnnotationThumbnail() async {
    try {
      const int thumbSize = 256;

      // ── 1. Snapshot the current viewport ─────────────────────────────────
      final Uint8List? raw = await screenshotController.capture(pixelRatio: 2.0);
      if (raw == null) return Uint8List(0);

      // ── 2. Compute screen-space bounding box of selected elements ─────────
      // The transform matrix maps local canvas coords → screen pixels:
      //   screenX = m[0]*lx + m[4]*ly + m[12]
      //   screenY = m[1]*lx + m[5]*ly + m[13]
      final Matrix4 m = controller.transform.value;
      final double sx = m.storage[0];  // scale x
      final double sy = m.storage[5];  // scale y
      final double tx = m.storage[12]; // translate x
      final double ty = m.storage[13]; // translate y

      double minX = double.infinity,  minY = double.infinity;
      double maxX = double.negativeInfinity, maxY = double.negativeInfinity;

      void _expandScreen(Offset local, double rLocal) {
        // local radius → screen radius
        final double rSc = rLocal * sx.abs();
        final double scX = sx * local.dx + tx;
        final double scY = sy * local.dy + ty;
        if (scX - rSc < minX) minX = scX - rSc;
        if (scX + rSc > maxX) maxX = scX + rSc;
        if (scY - rSc < minY) minY = scY - rSc;
        if (scY + rSc > maxY) maxY = scY + rSc;
      }

      // Selected nodes (use node.size for an accurate radius)
      for (final key in controller.annotationHighlightNodeKeys) {
        try {
          final node = controller.nodes.firstWhere((n) => n.key.toString() == key);
          final r = max(node.size.width, node.size.height) / 2;
          _expandScreen(node.offset, r);
        } catch (_) {}
      }
      // Axon path screen extents (transform the path bounds into screen space)
      for (final edge in controller.annotationHighlightEdges) {
        final fromStr = edge.from.toString();
        final toStr   = edge.to.toString();
        void _checkPath(Path? p) {
          if (p == null) return;
          final b = p.getBounds();
          // Transform all four corners
          for (final lx in [b.left, b.right]) {
            for (final ly in [b.top, b.bottom]) {
              final scX = sx * lx + tx;
              final scY = sy * ly + ty;
              if (scX < minX) minX = scX;
              if (scX > maxX) maxX = scX;
              if (scY < minY) minY = scY;
              if (scY > maxY) maxY = scY;
            }
          }
        }
        _checkPath(controller.axonPathMap['${fromStr}_$toStr']);
        final trunkPrefix = '${fromStr}_trunk_';
        for (final e in controller.axonPathMap.entries) {
          if (e.key.startsWith(trunkPrefix)) _checkPath(e.value);
        }
      }

      if (!minX.isFinite) return Uint8List(0);

      // ── 3. Centered square crop with minimum size ──────────────────────────
      // Dendrites/synapses extend well beyond node.size, so use a large fixed
      // margin plus a minimum crop size to prevent single-neuron over-zoom.
      final double cX = (minX + maxX) / 2;
      final double cY = (minY + maxY) / 2;
      const double kExtraMarginPx = 80.0;   // extra screen-px margin around selection
      const double kMinCropPx     = 160.0;  // min crop width/height on screen
      final double halfSq = max(
        max((maxX - minX), (maxY - minY)) / 2.0 + kExtraMarginPx,
        kMinCropPx / 2.0,
      );

      // Decode screenshot (pixelRatio 2 → multiply screen coords by 2)
      const double pr = 2.0;
      final codec  = await ui.instantiateImageCodec(raw);
      final srcImg = (await codec.getNextFrame()).image;
      final double imgW = srcImg.width.toDouble();
      final double imgH = srcImg.height.toDouble();

      final double halfSqPx = halfSq * pr;
      final double cXpx     = cX * pr;
      final double cYpx     = cY * pr;
      // Clamp crop to image bounds while keeping it centered
      final double cropSz = (halfSqPx * 2).clamp(1.0, min(imgW, imgH));
      final double cropX  = (cXpx - halfSqPx).clamp(0.0, imgW - cropSz);
      final double cropY  = (cYpx - halfSqPx).clamp(0.0, imgH - cropSz);
      final double cropW  = cropSz;
      final double cropH  = cropSz;

      final rec      = ui.PictureRecorder();
      final bgCanvas = ui.Canvas(rec);
      // Off-white background (visible if crop is partially out of bounds)
      bgCanvas.drawRect(
          Rect.fromLTWH(0, 0, thumbSize.toDouble(), thumbSize.toDouble()),
          Paint()..color = const Color(0xFFF8F8F8));
      bgCanvas.drawImageRect(
        srcImg,
        Rect.fromLTWH(cropX, cropY, cropW, cropH),
        Rect.fromLTWH(0, 0, thumbSize.toDouble(), thumbSize.toDouble()),
        ui.Paint()..filterQuality = FilterQuality.high,
      );
      final thumb = await rec.endRecording().toImage(thumbSize, thumbSize);
      final bd    = await thumb.toByteData(format: ui.ImageByteFormat.png);
      srcImg.dispose();
      thumb.dispose();
      return bd?.buffer.asUint8List() ?? Uint8List(0);
    } catch (e) {
      printDebug('Annotation thumbnail error: $e');
      return Uint8List(0);
    }
  }
  // ── Save / Edit / Delete ──────────────────────────────────────────────────

  /// Serialise the current annotation selection into a [BrainAnnotation].
  /// In edit mode, overwrites the existing annotation in-place.
  /// In new mode, appends to [brainAnnotations].
  Future<void> _saveAnnotation() async {
    // ── Build stable neuron keys (valKey survives save/reload; fall back to
    //    current key.toString() for nodes that haven't been saved yet) ────────
    final neuronKeys = <String>[];
    for (final currentKeyStr in controller.annotationHighlightNodeKeys) {
      try {
        final node = controller.nodes
            .firstWhere((n) => n.key.toString() == currentKeyStr);
        neuronKeys.add(_nodeAnnotationKeys[node.id] ?? (node.valKey.isNotEmpty ? node.valKey : currentKeyStr));
      } catch (_) {
        neuronKeys.add(currentKeyStr);
      }
    }

    // ── Build stable edge strings "fromValKey_#_toValKey" ──────────────────
    final edgeStrs = <String>[];
    for (final edge in controller.annotationHighlightEdges) {
      try {
        final nFrom = findNeuronByKey(edge.from);
        final nTo   = findNeuronByKey(edge.to);
        
        final fk = _nodeAnnotationKeys[nFrom.id] ?? (nFrom.valKey.isNotEmpty ? nFrom.valKey : edge.from.toString());
        final tk = _nodeAnnotationKeys[nTo.id]   ?? (nTo.valKey.isNotEmpty   ? nTo.valKey   : edge.to.toString());
        
        edgeStrs.add('${fk}_#_${tk}');
      } catch (_) {
        edgeStrs.add('${edge.from}_#_${edge.to}');
      }
    }

    final desc = _annotationDescController.text.trim();
    if (neuronKeys.isEmpty && edgeStrs.isEmpty) {
      _exitAnnotationMode();
      return;
    }

    final Uint8List thumb = await _captureAnnotationThumbnail();
    final bool wasEditing = _isEditingAnnotation;

    final annotation = BrainAnnotation(
      id: wasEditing && _editingAnnotationIdx >= 0
          ? brainAnnotations[_editingAnnotationIdx].id
          : DateTime.now().millisecondsSinceEpoch.toString(),
      neuronKeys: neuronKeys,
      edgeStrings: edgeStrs,
      description: desc.isEmpty ? 'No description' : desc,
      thumbnail: thumb,
    );
    setState(() {
      if (wasEditing && _editingAnnotationIdx >= 0 && _editingAnnotationIdx < brainAnnotations.length) {
        brainAnnotations[_editingAnnotationIdx] = annotation;
      } else {
        brainAnnotations.add(annotation);
      }
    });
    brainHasUnsavedChanges.value = true;
    _exitAnnotationMode();

    // After saving, reopen the brain dialog at the Current Brain tab so the
    // user can see the new annotation card and quickly add another.
    await _openAnnotationListDialog();
  }

  /// Re-opens the Load Brain dialog (Current Brain tab) after saving an annotation.
  Future<void> _openAnnotationListDialog() async {
    if (!mounted) return;
    currentBrainAnnotations = brainAnnotations;
    onAddAnnotationRequested = _enterAnnotationMode;
    onAnnotationsModified = () { setState(() { brainHasUnsavedChanges.value = true; }); };
    onAnnotationViewRequested = (ann, idx) { _viewAnnotation(ann, idx); };
    // pMapStatus['isSavingBrain'] kept as-is (preserves dialog's '10=saved' state for overwrite)
    // pMapStatus['currentFileName'] kept as-is (preserves full path set during selectSavedBrain)
    await showLoadBrainDialog(context, 'Load Brain', selectSavedBrain,
        saveCurrentBrain, pMapStatus);
  }

  /// Deletes the annotation currently being viewed and exits.
  void _deleteEditingAnnotation() {
    if (_editingAnnotationIdx >= 0 && _editingAnnotationIdx < brainAnnotations.length) {
      setState(() { brainAnnotations.removeAt(_editingAnnotationIdx); });
      brainHasUnsavedChanges.value = true;
    }
    _exitAnnotationMode();
  }

  // ── Phase 5: View / Navigate ──────────────────────────────────────────────

  /// Opens the annotation overlay in view/edit mode for the given annotation.
  /// Reconstructs highlights from stored keys and smoothly animates the canvas.
  void _viewAnnotation(BrainAnnotation ann, int idx) {
    // Suppress the unsaved-changes listener for the entire annotation session.
    // Set synchronously here — before any animation or setState — so every
    // subsequent notifyListeners() (camera fly-in, deselectAll re-entrancy,
    // etc.) is already guarded.
    _suppressUnsavedDuringAnnotation = true;
    // ── Reconstruct node highlights via valKey translation ───────────────────
    // Stored keys are valKey strings (old-session hash). Translate each to
    // the current-session key string (which the renderer uses for lookup).
    controller.annotationHighlightNodeKeys.clear();
    for (final storedKey in ann.neuronKeys) {
      try {
        final node = controller.nodes.firstWhere((n) =>
            (_nodeAnnotationKeys[n.id] ?? n.valKey) == storedKey || n.valKey == storedKey || n.key.toString() == storedKey);
        controller.annotationHighlightNodeKeys.add(node.key.toString());
      } catch (_) {}
    }

    // ── Reconstruct edge highlights via valKey → live edge lookup ───────────
    controller.annotationHighlightEdges.clear();
    for (final edgeStr in ann.edgeStrings) {
      final parts = edgeStr.split('_#_');
      if (parts.length == 2) {
        try {
          final nodeFrom = controller.nodes.firstWhere((n) =>
              (_nodeAnnotationKeys[n.id] ?? n.valKey) == parts[0] || n.valKey == parts[0] || n.key.toString() == parts[0]);
          final nodeTo = controller.nodes.firstWhere((n) =>
              (_nodeAnnotationKeys[n.id] ?? n.valKey) == parts[1] || n.valKey == parts[1] || n.key.toString() == parts[1]);
          final edge = controller.edges.firstWhere((e) =>
              e.from == nodeFrom.key && e.to == nodeTo.key);
          controller.annotationHighlightEdges.add(edge);
        } catch (_) {}
      }
    }

    // ── Animate to bounding box ──────────────────────────────────────────────
    _animateCanvasToAnnotation(ann);

    // ── Enter view overlay (read-only by default) ───────────────────────────
    _annotationDescController.text = ann.description;
    // Reset scroll to top whenever a new annotation is loaded (navigate prev/next
    // always starts reading from the beginning, not mid-text from a prior annotation).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_annotationScrollController.hasClients) {
        _annotationScrollController.jumpTo(0);
      }
    });
    controller.lockNodeDragging = true;
    controller.isInAnnotationMode = true;
    controller.notifyListeners(); // repaint highlights immediately
    setState(() {
      isAnnotationMode = true;
      _isEditingAnnotation = true;
      _editingAnnotationIdx = idx;
      _annotationEditEnabled = false; // start in view-only mode
      controller.annotationEditEnabled = false;
    });
    // Register key handler after the frame is fully built to avoid
    // interfering with the paint/highlight repaint triggered by notifyListeners().
    // Re-request focus so arrow-key navigation works immediately.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _annotationFocusNode.requestFocus();
    });
  }

  /// Animated lerp to neatly frame the annotation's selection bounding box.
  /// Viewport safe-zone is computed per-orientation so the selection fills the
  /// usable space between the left toolbar and the annotation card (landscape)
  /// or between the annotation card and the drag menu (portrait).
  void _animateCanvasToAnnotation(BrainAnnotation ann) {
    // ── Gather canvas-local positions via valKey translation ────────────────
    final List<Offset> positions = [];

    // Finds a node by stored key (which is valKey if saved to brain, or current
    // key.toString() if in the same unsaved session).
    InfiniteCanvasNode? _findByStoredKey(String storedKey) {
      try {
        return controller.nodes.firstWhere((n) =>
            (_nodeAnnotationKeys[n.id] ?? n.valKey) == storedKey ||
            n.valKey == storedKey || n.key.toString() == storedKey);
      } catch (_) { return null; }
    }

    for (final key in ann.neuronKeys) {
      final node = _findByStoredKey(key);
      if (node != null) positions.add(node.offset);
    }
    for (final edgeStr in ann.edgeStrings) {
      final parts = edgeStr.split('_#_');
      if (parts.length == 2) {
        for (final k in parts) {
          final node = _findByStoredKey(k);
          if (node != null) positions.add(node.offset);
        }
      }
    }
    if (positions.isEmpty) return;

    double minX = positions.map((p) => p.dx).reduce(min);
    double maxX = positions.map((p) => p.dx).reduce(max);
    double minY = positions.map((p) => p.dy).reduce(min);
    double maxY = positions.map((p) => p.dy).reduce(max);

    // Buffer so neuron rings / axon tips don't clip at the boundary
    const double nodePad = 90.0;
    minX -= nodePad; minY -= nodePad; maxX += nodePad; maxY += nodePad;

    final double bboxW = maxX - minX;
    final double bboxH = maxY - minY;
    if (bboxW <= 0 || bboxH <= 0) return;

    // ── Compute orientation-aware viewport safe zone ──────────────────────────
    // Constants that mirror those in _animateCanvasToReset
    const double kIconSize   = 70.0;
    const double kGapInner   = 16.0;   // breathing room from each panel edge
    final bool   isLscp      = MediaQuery.of(context).orientation == Orientation.landscape;
    final double safeBot     = MediaQuery.of(context).padding.bottom;
    final double vpW         = screenWidth;
    final double vpH         = screenHeight;

    // Annotation card dimensions (must match the overlay widget above)
    final double annCardW    = isLscp ? 300.0 : (vpW - 40 - safePadding).clamp(300.0, 420.0);
    // Estimated card height: ~210px new mode / ~265px edit mode; use 270 as safe upper bound
    const double annCardH    = 270.0;

    double safeLeft, safeRight, safeTop, safeBottom;

    if (isLscp) {
      // Landscape: selection lives in the centre strip between the left toolbar
      // and the annotation card (which is top-right).
      final double leftPanelRightEdge  = kIconSize + safePaddingLeft;
      final double annCardLeftEdge     = vpW - ((Platform.isIOS && safePadding > 0 ? safePadding : 20 + safePadding)) - annCardW;
      safeLeft   = leftPanelRightEdge + kGapInner;
      safeRight  = annCardLeftEdge    - kGapInner;
      safeTop    = safePaddingTop     + kGapInner;
      safeBottom = vpH                - kGapInner;
    } else {
      // Portrait: selection lives in the vertical strip between the bottom of
      // the annotation card and the top of the bottom drag menu.
      final double annCardBottom = (20 + safePaddingTop) + annCardH;
      final double dragMenuTop   = vpH - kIconSize - safeBot;
      safeLeft   = kGapInner;
      safeRight  = vpW - kGapInner;
      safeTop    = annCardBottom + kGapInner;
      safeBottom = dragMenuTop   - kGapInner;
    }

    final double safeW = (safeRight  - safeLeft).clamp(80.0, vpW);
    final double safeH = (safeBottom - safeTop ).clamp(80.0, vpH);

    // ── Compute transform so bbox fills the safe zone precisely ──────────────
    // Remove the previous arbitrary 2x multiplier so components don't bleed out.
    // Clamp to a reasonable max scale (1.25) so single neurons don't blow up massive.
    final double newScale = min(safeW / bboxW, safeH / bboxH)
        .clamp(controller.minScale, 2.5);

    // Centre of the safe zone in viewport (screen) coordinates
    final double vpCX = (safeLeft + safeRight)  / 2;
    final double vpCY = (safeTop  + safeBottom)  / 2;

    // Centre of the selection bbox in local canvas coordinates
    final double bboxCX = (minX + maxX) / 2;
    final double bboxCY = (minY + maxY) / 2;

    // Matrix: screen = scale*local + translate
    // → tx = vpCX - scale*bboxCX,  ty = vpCY - scale*bboxCY
    final double tx = vpCX - newScale * bboxCX;
    final double ty = vpCY - newScale * bboxCY;

    final Matrix4 target = Matrix4.identity()
      ..scale(newScale, newScale)
      ..setEntry(0, 3, tx)
      ..setEntry(1, 3, ty);

    // ── Animated lerp using shared _canvasAnimController ────────────────────
    final Matrix4 current = controller.transform.value.clone();
    controller.isAnimatingCamera = true;
    synapseFadeController?.stop();
    _canvasAnimation = Matrix4Tween(begin: current, end: target)
        .animate(CurvedAnimation(
            parent: _canvasAnimController,
            curve: Curves.easeInOut));
    _canvasAnimController.duration = const Duration(milliseconds: 700);
    _canvasAnimController.forward(from: 0).then((_) {
      controller.isAnimatingCamera = false;
      controller.scale = newScale;
      controller.notifyListeners();
    });
  }

  Future<String> saveCurrentBrain(String title, String description) async {
    // mainBloc.setLoading(1);
    ProgressDialog pd = ProgressDialog(context: context);
    pd.show(msg: 'Saving Brain...');
    printDebug("Save Current Brain");

    MyApp.logAnalytic("SaveFile",
        {"title": title, "timestamp": DateTime.now().millisecondsSinceEpoch});


    // 0. Capture State for Restoration
    Matrix4 prevMatrix = controller.transform.value.clone();
    double prevScale = controller.scale;
    
    try {
        var nodesJson = [];
        for (InfiniteCanvasNode e in controller.nodes) {
          // printDebug("e.value == null");
          if (e.value == -2) {
            nodesJson.add({
              "valKey": e.key.toString(),
              "annKey": _nodeAnnotationKeys[e.id] ?? (e.valKey.isNotEmpty ? e.valKey : e.key.toString()),
              "index": e.value,
              "position": [e.offset.dx, e.offset.dy],
              "color": [e.offset.dx, e.offset.dy],
              "shape": "SizedBox",
            });
          } else if (e.value == -1) {
            nodesJson.add({
              "valKey": e.key.toString(),
              "annKey": _nodeAnnotationKeys[e.id] ?? (e.valKey.isNotEmpty ? e.valKey : e.key.toString()),
              "index": e.value,
              "position": [e.offset.dx, e.offset.dy],
              "color": [e.offset.dx, e.offset.dy],
              "shape": "CustomPainter"
            });
          } else if (e.value < normalNeuronStartIdx) {
            nodesJson.add({
              "valKey": e.key.toString(),
              "annKey": _nodeAnnotationKeys[e.id] ?? (e.valKey.isNotEmpty ? e.valKey : e.key.toString()),
              "index": e.value,
              "position": [e.offset.dx, e.offset.dy],
              "color": [e.offset.dx, e.offset.dy],
              "shape": "CustomPaint"
            });
          } else {
            nodesJson.add({
              "valKey": e.key.toString(),
              "annKey": _nodeAnnotationKeys[e.id] ?? (e.valKey.isNotEmpty ? e.valKey : e.key.toString()),
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
          // if (to != nodeSingleLed) {
          edgesJson.add("${from.id}_#_${to.id}");
          // }
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
              "yFirstLevel": dendrite.yFirstLevel,
              "ySecondLevel": dendrite.ySecondLevel,
              "yTriangleFirstLevel": dendrite.yTriangleFirstLevel,
              "yTriangleSecondLevel": dendrite.yTriangleSecondLevel,
            });
          }
    
          rawSyntheticNeuronListJson.add({
            // "activeColor": syntheticNeuron.activeColor.toString(),
            "arrowSize": syntheticNeuron.arrowSize,
            "xNucleus": idxSyntheticNeuron < syntheticNeuronList.length
                ? syntheticNeuronList[idxSyntheticNeuron].newNeuron.xNucleus
                : syntheticNeuron.centerPos.dx,
            "yNucleus": idxSyntheticNeuron < syntheticNeuronList.length
                ? syntheticNeuronList[idxSyntheticNeuron].newNeuron.yNucleus
                : syntheticNeuron.centerPos.dy,
            "widthNucleus": idxSyntheticNeuron < syntheticNeuronList.length
                ? syntheticNeuronList[idxSyntheticNeuron].newNeuron.widthNucleus
                : 30.0,
            "heightNucleus": idxSyntheticNeuron < syntheticNeuronList.length
                ? syntheticNeuronList[idxSyntheticNeuron].newNeuron.heightNucleus
                : 30.0,
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
    
        // Strip OS-illegal characters from the filename title
        title = title.replaceAll(RegExp(r'[\\/:*?"<>|@]'), "_");

        // We decouple the description from the internal filename to prevent length/character crashes.
        // It's still stored natively inside `info` within the actual JSON file payload.
        // We use an underscore `_` as a placeholder to keep legacy substring parsing logic intact.
        final File file = File(
            '${directory.path}$textPath${Platform.pathSeparator}$title@@@_@@@$fileName.brain');
    
        controller.zoomReset();
        if (isPortrait == false) {
          controller.pan(const Offset(-60, 0));
        }
        // Use Global Controller
        // ScreenshotController screenshotController = ScreenshotController(); 
        String imagePath = "";
    
        printDebug("mapLedNeuron");
        printDebug(mapLedNeuron);
        // printDebug(nodeSingleLed.id);

        Uint8List? imageBytes;
        try {
            // Snap to home so the brain is centered in the screenshot.
            final Matrix4 savedTransform = controller.transform.value.clone();
            _animateCanvasToReset(false, animate: false);
            // Read the applied translation so we know exactly where the brain center is in the screenshot.
            // In landscape mode deltaX ≠ 0 (brain shifted right of left toolbar).
            // Matrix4.storage[12] = tx, [13] = ty (column-major 4×4).
            final double resetTx = controller.transform.value.storage[12];
            final double resetTy = controller.transform.value.storage[13];
            // Wait for the canvas to finish rendering at the reset position (≈2 frames at 60fps).
            await Future.delayed(const Duration(milliseconds: 50));
            imageBytes = await screenshotController.capture(pixelRatio: 1.0);
            // Restore the user's original transform
            controller.transform.value = savedTransform;
            // Crop centered on the actual brain position, not the screenshot center.
            if (imageBytes != null) {
              imageBytes = await _cropScreenshotToBrainSquare(imageBytes!, tx: resetTx, ty: resetTy);
            }
        } catch (e) {
            printDebug("SCREENSHOT ERROR: $e");
            imageBytes = null; // Proceed with save even if screenshot fails
        }
        
        // Block to process save (captureFromWidget removed)
          print("💾 SAVE: encoding JSON...");
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
            "mapMicrophoneTypeNeuron": mapMicrophoneTypeNeuron,
            "mapMicrophoneLimitNeuron": mapMicrophoneLimitNeuron,
            "mapLedNeuron": mapLedNeuron,
            "mapLedNeuronPosition": mapLedNeuronPosition,
            "mapLedHex": mapLedHex,
            "mapLedBrightness": mapLedBrightness,
            "mapRemoteControlNeuron": mapRemoteControlNeuron,
            "mapMotionNeuron": mapMotionNeuron,
            "rawSyntheticNeuron": rawSyntheticNeuronListJson,
            "mapDelayNeuron": mapDelayNeuronList,
            "mapRhytmicNeuron": mapRhytmicNeuronList,
            "mapCountingNeuron": mapCountingNeuronList,
            "auxServoRestPosition": auxServoRestPosition,
            "mapAuxMotorPower": mapAuxMotorPower..forEach((k, v) { print("💾 SAVE mapAuxMotorPower[$k] = $v"); }),
            "mapAreaSize": mapAreaSize,
            "a": controller.nodes.map((e) => aDesignArray[e.id] ?? 0.02).toList(),
            "b": controller.nodes.map((e) => bDesignArray[e.id] ?? 0.2).toList(),
            "c": controller.nodes.map((e) => cDesignArray[e.id] ?? -65.0).toList(),
            "d": controller.nodes.map((e) => dDesignArray[e.id] ?? 2.0).toList(),
            "w": controller.nodes.map((e) => (e.value!=-1 && e.value!=-2 && e.value < maxPosBuffer && e.value < wBufView.length ? wBufView[e.value] : 2.0)).toList(),
            "windowWidth": MediaQuery.of(context).size.width,
            "windowHeight": MediaQuery.of(context).size.height,
            "screenDensity": MediaQuery.of(context).devicePixelRatio,
            "screenshot": imageBytes != null ? base64Encode(imageBytes!) : "", // base64 JPEG for compact storage
            "annotations": BrainAnnotation.listToJson(brainAnnotations),
            "info": {
              "title": title,
              "description": description,
              "author": "User", 
              "version": strFileVersion,
              "timestamp": DateTime.now().toIso8601String()
            }
          });
    
          print("💾 SAVE: JSON encoded OK (${strNodesJson.length} chars)");
          if (kIsWeb) {
            // Web: Save to IndexedDB instead of filesystem
            String webFilename = '$title@@@_@@@$fileName.brain';
            await WebBrainStorage.instance.saveBrain(webFilename, strNodesJson, title, description);
            imagePath = webFilename;
          } else {
            await file.writeAsString(strNodesJson);
            imagePath = file.path;
          }
          print("💾 SAVE: file written to $imagePath");
        
        return imagePath;
        
    } catch (e, stack) {
        print("⚠️ SAVE ERROR: $e");
        print(stack);
        return "";
    } finally {
        // ALWAYS Restore state and close dialog
        // CRITICAL: Wrap EACH step in try-catch so one failure doesn't stop the others.
        
        // 1. Restore Controller State
        try {
            controller.transform.value = prevMatrix;
            controller.scale = prevScale;
        } catch (e) { printDebug("Restore Controller Error: $e"); }
        
        // 2. Close Progress Dialog (Fix Grey Screen)
        try {
            pd.close();
        } catch (e) { printDebug("Close Dialog Error: $e"); }

        // Brain successfully persisted — reset baseline so tapping after save
        // does not immediately re-raise the unsaved flag.
        try { _setCleanBaseline(); } catch (_) {}
        
        // 3. Restore Menu (Fix Missing UI)
        try {
            rightToolbarCallback({"menuIdx": 0});
        } catch (e) { printDebug("Restore Menu Error: $e"); }
        
        // 4. Restore Icons (Fix Disappearing RC Icon)
        try {
            initializeNucleus();
        } catch (e) { printDebug("Restore Icons Error: $e"); }
        
        // 5. Refresh UI
        Future.delayed(Duration.zero, () {
             if (mounted) setState(() {});
        });
    }
  }

  void selectSavedBrain(String filename, {String? filePath}) async {
    // MUST be set BEFORE any await — prevents the controller listener from
    // re-setting brainHasUnsavedChanges.value = true during load operations
    loadGeneration++;
    final myLoadGen = loadGeneration;
    isLoadingBrain = true;
    isSettlingAfterLoad = true;
    _nodeAnnotationKeys = {}; // clear stale annotation key map for new brain
    brainHasUnsavedChanges.value = false;

    MyApp.logAnalytic("LoadFile", {
      "filename": filename,
      "timestamp": DateTime.now().millisecondsSinceEpoch
    });
    
    // V23: Play page flip sound when loading brain
    if (pageFlipSource != null) {
      await soloud?.play(pageFlipSource!);
    }
    
    String textPath =
        "${Platform.pathSeparator}spikerbot${Platform.pathSeparator}text";
    controller.deselectAll();
    clearUIMenu();

    // Clear pins when loading a new/different brain — pins are session-only
    placedPins.clear();
    hoveringPinNeuronIdx = -1;
    currentWaveNeuronIdx = -1;
    currentWaveNeuronIdx2 = -1;
    nativec.changeIdxSelected(-1);
    nativec.changeIdxSelected2(-1);

    uiDebugLog = "Debug Overlay Active\nLoad: $filename\n";

    if (filename == "") return;

    // isLoadingBrain already set at top; guarded against race with page-flip sound await 
    try {
    controller.zoomReset();
    controller.edges.clear();
    int len = controller.nodes.length;
    neuronTypes.clear();
    printDebug("DEBUG: selectSavedBrain START - nodes.length: $len, normalNeuronStartIdx: $normalNeuronStartIdx");
    if (len > 6) printDebug("DEBUG: Node 6 (Speaker?) ID before clear: ${controller.nodes[6].id}");
    
    for (int i = normalNeuronStartIdx + 2; i < len; i++) {
      controller.nodes.removeLast();
    }
    printDebug("DEBUG: After clear - nodes.length: ${controller.nodes.length}");
    if (controller.nodes.length > 6) printDebug("DEBUG: Node 6 (Speaker?) ID after clear: ${controller.nodes[6].id}");
    
    clearBridge();

    if (filename == "-1") {
      brainAnnotations = []; // fresh brain has no annotations
      // V25: ZERO-FRAME SNAP FOR NEW BRAINS (Forced synchronous layout calculate)
      WidgetsBinding.instance.addPostFrameCallback((_) {
          _animateCanvasToReset(MediaQuery.of(context).orientation == Orientation.landscape, animate: false);
      });
      
      // Force repaint
      controller.notifyListeners();
      return;
    }

    // if selectedFilename is not default and not the same then we need to delete the old file
    if (selectedFileName != "-" && selectedFileName != filename) {
      // delete the old file
    }
    selectedFileName = filename;
    pMapStatus["currentFileName"] = filePath ?? "";

    final Directory directory = await getApplicationDocumentsDirectory();
  File savedFile;
  if (filePath != null && filePath.isNotEmpty) {
    savedFile = File(filePath);
  } else {
    savedFile = File(
        '${directory.path}$textPath${Platform.pathSeparator}$filename.brain');
  }
    String savedFileText = "";
    if (kIsWeb) {
      // Web: read from asset bundle for examples, or from IndexedDB for user brains
      try {
        if (filePath != null && filePath.startsWith('assets/')) {
          savedFileText = await rootBundle.loadString(filePath);
        } else if (filePath != null && filePath.isNotEmpty) {
          // User-saved brain — load from IndexedDB using filePath as the key
          String? idbContent = await WebBrainStorage.instance.loadBrain(filePath);
          if (idbContent != null && idbContent.isNotEmpty) {
            savedFileText = idbContent;
          } else {
            // Fallback: try as example brain
            savedFileText = await rootBundle.loadString('assets/example brains/$filename.brain');
          }
        } else {
          savedFileText = await rootBundle.loadString('assets/example brains/$filename.brain');
        }
      } catch (_) {
        try {
          savedFileText = await rootBundle.loadString('assets/example brains/$filename');
        } catch (_) {
          print("Web: Could not load brain '$filename'");
        }
      }
    } else if (savedFile.existsSync()) {
      savedFileText = await savedFile.readAsString();
    } else {
      File savedFileTxt = File(
          '${directory.path}$textPath${Platform.pathSeparator}$filename.txt');
      savedFileText = await savedFileTxt.readAsString();
    }

    Map savedFileJson = json.decode(savedFileText);
    // Load annotations (absent in old files → returns []):
    brainAnnotations = BrainAnnotation.listFromJson(savedFileJson);
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
          "position": [0, 0],
          "color": [280, 520],
          "shape": "CustomPaint"
        },
      );
      // savedFileJson["neuronTypes"][nodeSingleLed.id] = "Quiet";
      // savedFileJson["neuronStyles"][nodeSingleLed.id] = "Quiet";
      savedFileJson["a"].insert(9, 0.02);
      savedFileJson["b"].insert(9, 0.18);
      savedFileJson["c"].insert(9, -65);
      savedFileJson["d"].insert(9, 2);
      savedFileJson["i"].insert(9, 5);
      savedFileJson["w"].insert(9, 2);
      savedFileJson["mapDelayNeuron"].insert(9, -1);
      savedFileJson["mapRhytmicNeuron"].insert(9, -1);
      savedFileJson["mapCountingNeuron"].insert(9, -1);
      savedFileJson["rawSyntheticNeuron"]
          .insert(9, savedFileJson["rawSyntheticNeuron"][0]);
    }

    // printDebug(json.encode(savedFileJson["nodes"]));

    // END OF READING FILE

    double tempWidth = MediaQuery.of(context).size.width;
    double tempHeight = MediaQuery.of(context).size.height;

    print("Sizing!!");
    print(savedFileJson["windowWidth"] != null);
    print(savedFileJson["windowHeight"] != null);
    // macOS: Do NOT resize to saved size — we now use silentRepositionNeurons() to
    // mathematically remap neurons to the current window (no jarring resize jump).
    // Only resize on Windows where window management behaves differently.
    try {
      if (savedFileJson["windowWidth"] != null) {
        double displayWidth = savedFileJson["windowWidth"].toDouble();
        double displayHeight = savedFileJson["windowHeight"].toDouble();
        if (Platform.isWindows || Platform.isLinux) {
          // On Windows/Linux: resize to saved size (legacy behaviour)
          await windowManager.setSize(Size(displayWidth, displayHeight));
        }
        // macOS: stay at current window size, silentRepositionNeurons handles layout
      }
    } catch (err) {
      printDebug("err2");
      printDebug(err);
    }

    // Removed rigid 500ms Thread-yielding delay. 
    // Yielding the thread *after* clearing nodes forces the Render engine to draw an empty canvas.
    // Keeping it synchronous prevents frame-flicker.
    // printDebug("change window size finished");

    // printDebug("change window size finished");
    
    List<dynamic> nodesJson = savedFileJson["nodes"];

    // ---------------------------------------------------------------------------------------
    // CRITICAL FIX: Pre-identify System Nodes (Speaker, Mic) from Maps to handle Scrambled IDs
    // If a loaded brain has Speaker at index 20 (instead of 4), we must find it and force-map it.
    // ---------------------------------------------------------------------------------------
    Map<String, InfiniteCanvasNode> forcedSystemNodeMap = {};

    try {
      if (savedFileJson["mapSpeakerNeuron"] != null) {
        Map<String, dynamic> m = savedFileJson["mapSpeakerNeuron"];
        if (m.isNotEmpty) {
           String firstKey = m.keys.first;
           List<String> parts = firstKey.split("_");
           if (parts.length > 1) {
             String fileSpeakerId = parts[1];
             if (firstKey.contains("_node_")) {
                int lastNodeIdx = firstKey.lastIndexOf("_node_");
                fileSpeakerId = firstKey.substring(lastNodeIdx + 1);
             }
             printDebug("DEBUG: Identified File Speaker ID: $fileSpeakerId");
             forcedSystemNodeMap[fileSpeakerId] = nodeSpeakerSensor;
             uiDebugLog += "ForceMap: Spk $fileSpeakerId -> Sys4\n";
           }
        }
      }
      
      if (savedFileJson["mapMicrophoneNeuron"] != null) {
        Map<String, dynamic> m = savedFileJson["mapMicrophoneNeuron"];
        if (m.isNotEmpty) {
           String firstKey = m.keys.first;
           // Mic is Source (FROM)
           List<String> parts = firstKey.split("_");
           String fileMicId = parts[0];
           if (firstKey.contains("_node_")) {
              int lastNodeIdx = firstKey.lastIndexOf("_node_");
              fileMicId = firstKey.substring(0, lastNodeIdx);
           }
           printDebug("DEBUG: Identified File Mic ID: $fileMicId");
           forcedSystemNodeMap[fileMicId] = nodeMicrophoneSensor;
           uiDebugLog += "ForceMap: Mic $fileMicId -> Sys3\n";
        }
      }
    } catch (e) {
      printDebug("Error pre-identifying system nodes: $e");
      uiDebugLog += "ForceMap Error: $e\n";
    }
    
    // ---------------------------------------------------------------------------------------
    // CRITICAL FIX: Bind parameters to nodes BEFORE sorting to prevent index mismatch.
    // The 'nodes' list and 'a,b,c...' lists in the file are parallel (1:1) in the file order.
    // If we sort 'nodes' without sorting parameters correspondingly, we assign wrong params.
    // ---------------------------------------------------------------------------------------
    
    List<dynamic> rawA = savedFileJson["a"] ?? [];
    List<dynamic> rawB = savedFileJson["b"] ?? [];
    List<dynamic> rawC = savedFileJson["c"] ?? [];
    List<dynamic> rawD = savedFileJson["d"] ?? [];
    List<dynamic> rawI = savedFileJson["i"] ?? [];
    List<dynamic> rawW = savedFileJson["w"] ?? []; 

    List<Map<String, dynamic>> enrichedNodes = [];
    for (int k = 0; k < nodesJson.length; k++) {
        Map<String, dynamic> nodeData = nodesJson[k];
        // Safely attach parameters if available
        nodeData["_param_a"] = (k < rawA.length) ? rawA[k] : 0.02;
        nodeData["_param_b"] = (k < rawB.length) ? rawB[k] : 0.2;
        nodeData["_param_c"] = (k < rawC.length) ? rawC[k] : -65.0;
        nodeData["_param_d"] = (k < rawD.length) ? rawD[k] : 2.0;
        nodeData["_param_i"] = (k < rawI.length) ? rawI[k] : 0.0;
        nodeData["_param_w"] = (k < rawW.length) ? rawW[k] : 2.0;
        
        enrichedNodes.add(nodeData);
    }

    // Sort the ENRICHED nodes by index. Now parameters travel with the node.
    enrichedNodes.sort((a, b) => (a["index"] as int).compareTo(b["index"] as int));
    
    // Replace the raw list with our enriched list for the subsequent loop
    nodesJson = enrichedNodes;
    
    // List<String> tempNeuronTypes =
    //     List.generate(neuronTypes.length, (index) => neuronTypes[index]);
    List<LocalKey> tempNeuronsKey = [];

    Map<String, String> mapTranslateLoadKeys = {};
    // List<ValueKey> tempNeuronsKey =
    //     List.generate(neuronsKey.length, (index) => ValueKey(neuronsKey[index].toString()));
    var rawSyntheticNeuronListJson = savedFileJson["rawSyntheticNeuron"];
    
    // Create a lookup map for synthetic neuron configs by their stored neuronIdx to handle potential list order mismatch
    Map<int, dynamic> syntheticConfigMap = {};
    if (rawSyntheticNeuronListJson != null) {
      for (var item in rawSyntheticNeuronListJson) {
         if (item["neuronIdx"] != null) {
           syntheticConfigMap[item["neuronIdx"]] = item;
         }
      }
    }
    
    int nIdx = 0;

    // bool isPreMic = savedFileJson["mapMicrophoneNeuron"] == null;
    bool isPreMic = false;
    printDebug("Checking Legacy Brain Status...");
    if (savedFileJson["mapMicrophoneNeuron"] == null) {
      isPreMic = true;
      printDebug("Legacy: mapMicrophoneNeuron is null");
    } else if (savedFileJson["neuronTypes"] != null) {
      // Check if node_7 is "Speaker" (Legacy) which implies shift needed
      if (savedFileJson["neuronTypes"]["node_7"] == "Speaker") {
        isPreMic = true;
        printDebug("Legacy: node_7 is Speaker");
      } else {
         printDebug("Modern: node_7 is ${savedFileJson["neuronTypes"]["node_7"]}");
      }
    }
    printDebug("isPreMic detected: $isPreMic");

    for (var v in nodesJson) {
      // printDebug("v");
      // printDebug(v);
      String loadedNeuronKey = v["valKey"];
      int effectiveIndex = v["index"];

      // Shift index for Pre-Microphone files (Mic inserted at index 7)
      if (isPreMic && effectiveIndex >= 7) {
        effectiveIndex++;
      }

      if (v["index"] == -2 || v["index"] == -1) {
        printDebug("shadow neuron");
        InfiniteCanvasNode neuron = findNeuronByValue(v["index"]);
        neuron.valKey = loadedNeuronKey;
        // Shadow nodes typically shouldn't be in tempNeuronsKey as they don't have simulation parameters
        // tempNeuronsKey.add(neuron.key); 
        mapTranslateLoadKeys[neuron.valKey] = neuron.id;
        _nodeAnnotationKeys[neuron.id] = (v["annKey"] as String?) ?? loadedNeuronKey;

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
        // } else if ( (savedFileJson["version"] != null && v["index"] < normalNeuronStartIdx) || (savedFileJson["version"] == null && v["index"] < normalNeuronStartIdx - 1)  ) {
        // normalNeuronStartIdx has been increased by injecting into savedFileJson
      } else if (effectiveIndex < normalNeuronStartIdx || forcedSystemNodeMap.containsKey(loadedNeuronKey)) {
        int designatedIdx = effectiveIndex;
        InfiniteCanvasNode neuron;
        
        // CRITICAL FIX: Use forced map if available, otherwise search by index
        if (forcedSystemNodeMap.containsKey(loadedNeuronKey)) {
           neuron = forcedSystemNodeMap[loadedNeuronKey]!;
           printDebug("DEBUG: Force-mapping Loaded Node $loadedNeuronKey (Index $effectiveIndex) to System Node ${neuron.id} (Value ${neuron.value})");
        } else {
           neuron = findNeuronByValue(designatedIdx);
        }

        neuron.valKey = loadedNeuronKey;
        tempNeuronsKey.add(neuron.key);
        mapTranslateLoadKeys[neuron.valKey] = neuron.id;
        _nodeAnnotationKeys[neuron.id] = (v["annKey"] as String?) ?? loadedNeuronKey;
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
        
        // Use lookup by effectiveIndex (or fall back to list index if needed, but lookup is safer)
        var syntheticConfig = syntheticConfigMap[effectiveIndex];
        if (syntheticConfig == null && rawSyntheticNeuronListJson != null && nIdx < rawSyntheticNeuronListJson.length) {
           // Fallback to nIdx if strictly missing in map but present in list (legacy?)
           // But since we sorted nodesJson, nIdx matches the sorted order. 
           // If rawSyntheticNeuronListJson is also just a list without IDs in old files, we might need to assume 1:1 match with sorted nodes?
           // Actually, if it's old file, it might just rely on index.
           syntheticConfig = rawSyntheticNeuronListJson[nIdx];
        }

        String newNodeId = populateNode(
            v, nodeKey, nIdx, syntheticConfig, savedFileJson);
        mapTranslateLoadKeys[loadedNeuronKey] = newNodeId;
        _nodeAnnotationKeys[newNodeId] = (v["annKey"] as String?) ?? loadedNeuronKey;
        
        // CRITICAL FIX: Map inferred ID to support mapConnectome/mapSensoryNeuron keys
        // Saved brains often use "node_{index}" as ID in maps, but "valKey" in nodesJson.
        mapTranslateLoadKeys["node_${v['index']}"] = newNodeId;
        
        // CRITICAL FIX: Support raw index keys (e.g. "0", "1") used in legacy neuronTypes map
        mapTranslateLoadKeys["${v['index']}"] = newNodeId;
        
        // CRITICAL FIX: Populate Parameter Arrays IMMEDIATELY
        // Previously, parameters were read but discarded, causing runSimulation to use defaults.
        // We use the ID as key, which MUST MATCH runSimulation lookup.
        if (v.containsKey("_param_a")) {
            aDesignArray[newNodeId] = (v["_param_a"] as num).toDouble();
            bDesignArray[newNodeId] = (v["_param_b"] as num).toDouble();
            cDesignArray[newNodeId] = (v["_param_c"] as num).toDouble();
            dDesignArray[newNodeId] = (v["_param_d"] as num).toDouble();
        }

        nIdx++;
      }
    }
    printDebug("Map translated Load Keys ${syntheticNeuronList.length}");

    mapConnectome = translateLoadedMap(
        savedFileJson["mapConnectome"], mapTranslateLoadKeys);

    mapSensoryNeuron = translateLoadedMap(
        savedFileJson["mapSensoryNeuron"], mapTranslateLoadKeys);
    mapContactsNeuron = translateLoadedMap(
        savedFileJson["mapContactsNeuron"], mapTranslateLoadKeys);
    printDebug("DEBUG: mapContactsNeuron Keys: ${mapContactsNeuron.keys.toList()}");
    printDebug("DEBUG: mapTranslateLoadKeys: $mapTranslateLoadKeys");
    mapDistanceNeuron = translateLoadedMap(
        savedFileJson["mapDistanceNeuron"], mapTranslateLoadKeys);
    try {
      mapDistanceLimitNeuron = translateLoadedMap(
        savedFileJson["mapDistanceLimitNeuron"], mapTranslateLoadKeys);
    } catch(e) {}

    List<dynamic> edgesJson = savedFileJson["edges"];
    Map<String, dynamic> tempMap = {};
    printDebug("DEBUG EDGES: edgesJson has ${edgesJson.length} entries");
    printDebug("DEBUG EDGES: controller.nodes count: ${controller.nodes.length}");
    // Log all valKeys for debugging
    for (var n in controller.nodes) {
      printDebug("DEBUG EDGES: node id=${n.id} valKey=${n.valKey} key=${n.key}");
    }
    int edgeSuccessCount = 0;
    int edgeFailCount = 0;
    for (var v in edgesJson) {
      try {
      List<String> arr = v.toString().split("_#_");
      InfiniteCanvasNode nodeFrom = findNeuronByValueKey((arr[0]));
      InfiniteCanvasNode nodeTo = findNeuronByValueKey((arr[1]));

      // LEGACY SENSOR REMAPPING
      if (isPreMic) {
        if (nodeFrom.id == "node_4") {
          printDebug("Remapping Legacy Mic (node_4) to nodeMicrophoneSensor");
          
          String oldKey = "${nodeFrom.id}_${nodeTo.id}";
          // Try to find strength in legacy maps
          double strength = 0;
          if (mapSensoryNeuron.containsKey(oldKey)) {
             strength = mapSensoryNeuron[oldKey] ?? 0;
          } else if (mapConnectome.containsKey(oldKey)) {
             strength = mapConnectome[oldKey] ?? 0;
          }
          
          nodeFrom = nodeMicrophoneSensor;
          String newKey = "${nodeFrom.id}_${nodeTo.id}";
          
          // Migrate to new map
          mapMicrophoneNeuron[newKey] = strength;
          printDebug("Migrated strength $strength from $oldKey to $newKey");
        }
      }

      InfiniteCanvasEdge edge = InfiniteCanvasEdge(
        from: nodeFrom.key,
        to: nodeTo.key,
      );
      if (nodeTo.id == nodeRedLed.id ||
          nodeTo.id == nodeBlueLed.id ||
          nodeTo.id == nodeGreenLed.id) {
        String targetKey = "${nodeFrom.id}_${nodeSingleLed.id}";
        // tempMap : merging all leds into one SingleLed
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
      
      // V25: Comprehensive Connection Strength Lookup (Fixes "Thin Axons" on load)
      double strength = 0;
      if (mapConnectome.containsKey(connectionKey)) {
        strength = mapConnectome[connectionKey]?.toDouble() ?? 0;
      } else if (mapContactsNeuron.containsKey(connectionKey)) {
        strength = mapContactsNeuron[connectionKey]?.toDouble() ?? 0;
      } else if (mapSpeakerNeuron.containsKey(connectionKey)) {
        strength = mapSpeakerNeuron[connectionKey]?.toDouble() ?? 0;
      } else if (mapMicrophoneNeuron.containsKey(connectionKey)) {
        strength = mapMicrophoneNeuron[connectionKey]?.toDouble() ?? 0;
      } else if (mapLedNeuron.containsKey(connectionKey)) {
        strength = mapLedNeuron[connectionKey]?.toDouble() ?? 0;
      }
      // If still 0, check if it's a legacy sensor connection that might have a default value
      if (strength == 0) {
         // Some sensors might default to higher values if not mapped?
         // For now, respect the map (0 implies user set it to 0 or it's default)
      }
      edge.connectionStrength = strength;

      // V25: Explicit LED Color Restoration (Fixes "Color Loss" / "Color Spread")
      // Only apply if the target is actually an LED (prevents map pollution from affecting regular axons)
      bool isLedTarget = nodeTo.id == nodeSingleLed.id || 
                         nodeTo.id == nodeRedLed.id || 
                         nodeTo.id == nodeGreenLed.id || 
                         nodeTo.id == nodeBlueLed.id ||
                         (nodeTo.label ?? "").toLowerCase().contains("led");

      if (isLedTarget && mapLedHex.containsKey(connectionKey)) {
        String hex = mapLedHex[connectionKey]!;
        if (hex.isNotEmpty) {
          try {
            double opacity = 1.0;
            if (mapLedBrightness.containsKey(connectionKey)) {
               opacity = double.tryParse(mapLedBrightness[connectionKey]!) ?? 1.0;
            }
            edge.color = Color(int.parse("0xFF$hex")).withOpacity(opacity);
          } catch (e) {
            printDebug("Error parsing LED color on load: $e");
          }
        }
      }

      controller.edges.add(edge);
      edgeSuccessCount++;
      } catch (e) {
        edgeFailCount++;
        printDebug("DEBUG EDGES: FAILED edge '$v' — $e");
      }
    }
    printDebug("DEBUG EDGES: $edgeSuccessCount succeeded, $edgeFailCount failed, controller.edges.length=${controller.edges.length}");

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
    mapMicrophoneTypeNeuron = translateLoadedMap(
        savedFileJson["mapMicrophoneTypeNeuron"], mapTranslateLoadKeys);
    try {
      mapMicrophoneLimitNeuron = translateLoadedMap(
          savedFileJson["mapMicrophoneLimitNeuron"], mapTranslateLoadKeys);
    } catch (err) {
      printDebug("Mic Limit not found");
    }
    // printDebug("mapLedNeuron");
    // printDebug(savedFileJson["mapLedNeuron"]);
    
    // SYNC TO CONTROLLER for Icon Rendering (Fixes missing icons on load)
    controller.mapContactsNeuron = Map.from(mapContactsNeuron); // FIX: Was missing! Motor weights not synced to controller after load
    controller.mapMicrophoneNeuron = Map.from(mapMicrophoneNeuron);
    controller.mapMicrophoneTypeNeuron = Map.from(mapMicrophoneTypeNeuron);
    controller.mapMicrophoneLimitNeuron = Map.from(mapMicrophoneLimitNeuron);
    controller.mapSpeakerNeuron = Map.from(mapSpeakerNeuron);
    controller.mapSensoryNeuron = Map.from(mapSensoryNeuron);
    controller.mapDistanceNeuron = Map.from(mapDistanceNeuron);

    // Load Remote Control bindings
    if (savedFileJson["mapRemoteControlNeuron"] != null) {
      mapRemoteControlNeuron = translateLoadedNeuron(
          savedFileJson["mapRemoteControlNeuron"], mapTranslateLoadKeys);
    } else {
      mapRemoteControlNeuron = {};
    }

    // Load Motion neuron bindings (Tap/Tilt/Motion)
    if (savedFileJson["mapMotionNeuron"] != null) {
      mapMotionNeuron = translateLoadedNeuron(
          savedFileJson["mapMotionNeuron"], mapTranslateLoadKeys);
    } else {
      mapMotionNeuron = {};
    }

    // Load and translate mapAuxMotorPower keys from old save-file IDs to new node IDs
    if (savedFileJson["mapAuxMotorPower"] != null) {
      Map<String, double> rawAuxPower = Map<String, double>.from(
        savedFileJson["mapAuxMotorPower"].map((key, value) => MapEntry(key, value.toDouble()))
      );
      mapAuxMotorPower = {};
      rawAuxPower.forEach((oldKey, value) {
        if (mapTranslateLoadKeys.containsKey(oldKey)) {
          mapAuxMotorPower[mapTranslateLoadKeys[oldKey]!] = value;
        } else {
          print("⚠️ mapAuxMotorPower: no translation for key '$oldKey', dropping");
        }
      });
      print("💾 mapAuxMotorPower loaded: $mapAuxMotorPower");
    }

    mapLedNeuron =
        translateLoadedMap(savedFileJson["mapLedNeuron"], mapTranslateLoadKeys);
    // printDebug(mapLedNeuron);
    // printDebug("====mapLedNeuron");

    if (savedFileJson["version"] == null) {
      Map<String, dynamic> tempMapLedNeuronPosition =
          savedFileJson["mapLedNeuronPosition"] == null
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

    // V23: Load new LED color/brightness maps
    mapLedHex = (savedFileJson["mapLedHex"] as Map<String, dynamic>?)
        ?.map((k, v) => MapEntry(k, v.toString())) ?? {};
    mapLedBrightness = (savedFileJson["mapLedBrightness"] as Map<String, dynamic>?)
        ?.map((k, v) => MapEntry(k, v.toString())) ?? {};
    // Translate keys if needed (for older save files this won't exist, so no translation needed)
    if (savedFileJson["mapLedHex"] != null) {
      mapLedHex = translateLoadedMap(savedFileJson["mapLedHex"], mapTranslateLoadKeys)
          .map((k, v) => MapEntry(k.toString(), v.toString()));
    }
    if (savedFileJson["mapLedBrightness"] != null) {
      mapLedBrightness = translateLoadedMap(savedFileJson["mapLedBrightness"], mapTranslateLoadKeys)
          .map((k, v) => MapEntry(k.toString(), v.toString()));
    }

    // neuronTypes = List<String>.from(savedFileJson["neuronTypes"]);
    Map<String, String> tempNeuronTypes = translateLoadedNeuron(
        savedFileJson["neuronTypes"], mapTranslateLoadKeys,
        migrateTypes: true);
    // printDebug("mapDistanceLimitNeuron");
    // printDebug(mapDistanceLimitNeuron);
    neuronTypes.clear();
    int neuronTypeIdx = 0;
    tempNeuronTypes.forEach((key, value) {
      if (neuronTypeIdx == 9 && savedFileJson["version"] == null) {
        neuronTypes[nodeSingleLed.id] = "Quiet";
        neuronTypes[key] = value;
      } else {
        neuronTypes[key] = value;
      }
      neuronTypeIdx++;
    });

    if (savedFileJson["neuronStyles"] != null) {
      Map<String, String> tempNeuronStyles = translateLoadedNeuron(
          savedFileJson["neuronStyles"], mapTranslateLoadKeys);
      neuronStyles.clear();
    int neuronStyleIdx = 0;
      tempNeuronStyles.forEach((key, value) {
        if (neuronStyleIdx == 9 && savedFileJson["version"] == null) {
          neuronStyles[nodeSingleLed.id] = "Excitatory";
          neuronStyles[key] = value;
        } else {
          neuronStyles[key] = value;
        }
        InfiniteCanvasNode node = findNeuronById(key);
        if (neuronStyles[key] == "Inhibitory") {
          node.isExcitatory = 0;
        } else {
          node.isExcitatory = 1;
        }
        neuronStyleIdx++;
      });
    }

    // FIX: Load Remote Control Map
    if (savedFileJson["mapRemoteControlNeuron"] != null) {
      mapRemoteControlNeuron = translateLoadedNeuron(
          savedFileJson["mapRemoteControlNeuron"], mapTranslateLoadKeys);
    }

    // FIX: Load Motion Neuron Map
    if (savedFileJson["mapMotionNeuron"] != null) {
      mapMotionNeuron = translateLoadedNeuron(
          savedFileJson["mapMotionNeuron"], mapTranslateLoadKeys);
    }

    neuronSize = controller.nodes.length - 2;
    neuronsKey = List<UniqueKey>.from(tempNeuronsKey);

    if (!kIsWeb) {
      initNativeC(true, preserveParams: true);
      _dumpMotorBufferColumns("LOAD_1_AFTER_INITNATIVEC");
    }
    // printDebug(savedFileJson["a"]);
    printDebug("mapContactsNeuron");
    printDebug(mapContactsNeuron);
    rawPos = [];
    for (InfiniteCanvasNode node in controller.nodes) {
      Offset position = controller.toLocal(node.offset);
      rawPos.add(position);
    }

    int nodeLength = controller.nodes.length;
    for (int neuronIdx = normalNeuronStartIdx + 2;
        neuronIdx < nodeLength;
        neuronIdx++) {
      String nodeKey = controller.nodes[neuronIdx].id;
      controller.nodes[neuronIdx].label = neuronTypes[nodeKey];
      // Show bound key label on Remote Control neurons
      if (neuronTypes[nodeKey] == "Remote Control" && mapRemoteControlNeuron.containsKey(nodeKey)) {
        controller.nodes[neuronIdx].label = "🎮 ${mapRemoteControlNeuron[nodeKey]}";
      }
      // Motion neurons get their labels cleared (emoji rendered in nucleus)
      if (neuronTypes[nodeKey] == "Motion") {
        controller.nodes[neuronIdx].label = "";
      }
    }
    // Purge stale mapLedHex / mapLedBrightness entries before re-applying edge colors.
    // If the user deleted an LED connection and saved, the old entry may still be in
    // the save file (cleanup was missed). On re-load, that stale entry causes the wrong
    // axon to get LED gradient coloring. Only keep entries that match an actual LED edge.
    {
      final Set<String> validLedKeys = {};
      for (final edge in controller.edges) {
        if (edge.to == nodeSingleLed.key || edge.to == nodeRedLed.key ||
            edge.to == nodeGreenLed.key || edge.to == nodeBlueLed.key) {
          final fromNode = controller.nodes.cast<InfiniteCanvasNode?>().firstWhere(
              (n) => n?.key == edge.from, orElse: () => null);
          if (fromNode != null) {
            validLedKeys.add("${fromNode.id}_${nodeSingleLed.id}");
            validLedKeys.add("${fromNode.id}_${nodeRedLed.id}");
            validLedKeys.add("${fromNode.id}_${nodeGreenLed.id}");
            validLedKeys.add("${fromNode.id}_${nodeBlueLed.id}");
          }
        }
      }
      mapLedHex.removeWhere((k, _) => !validLedKeys.contains(k));
      mapLedBrightness.removeWhere((k, _) => !validLedKeys.contains(k));
    }
    for (InfiniteCanvasEdge edge in controller.edges) {
      InfiniteCanvasNode eFrom = findNeuronByKey(edge.from);
      if ( nodeMicrophoneSensor.id == eFrom.id) {
         // Prevent overwrite of label
         continue;
      } else if ( nodeLeftEyeSensor.key == edge.from) {
        int sensoryIdx = mapSensoryNeuron["${edge.from}_${edge.to}"];
        String type = cameraMenuTypes[sensoryIdx];
        edge.label = lookup[type] ?? type;
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
        // V23: Use new hex/brightness maps if available, else fall back to R/G/B
        String connectionKey = "${edge.from}_${nodeSingleLed.id}";
        
        if (mapLedHex.containsKey(connectionKey)) {
          // New format: use hex and brightness
          String hex = mapLedHex[connectionKey] ?? "FD8164";
          double brightness = double.tryParse(mapLedBrightness[connectionKey] ?? "1.00") ?? 1.0;
          Color c = Color(int.parse("0xFF$hex"));
          edge.color = c.withOpacity(brightness);
          edge.isLedEdge = true;
          edge.connectionStrength = brightness * 100.0;
          if (edge.connectionStrength < 1.0) edge.connectionStrength = 1.0;
        } else {
          // Legacy format: compute from R/G/B values
          double redValue = mapLedNeuron.containsKey("${edge.from}_${nodeRedLed.id}") ? mapLedNeuron["${edge.from}_${nodeRedLed.id}"].toDouble() : 0;
          double greenValue = mapLedNeuron.containsKey("${edge.from}_${nodeGreenLed.id}") ? mapLedNeuron["${edge.from}_${nodeGreenLed.id}"].toDouble() : 0;
          double blueValue = mapLedNeuron.containsKey("${edge.from}_${nodeBlueLed.id}") ? mapLedNeuron["${edge.from}_${nodeBlueLed.id}"].toDouble() : 0;
          double subtotal = max(redValue, greenValue);
          subtotal = max(subtotal, blueValue);
          edge.connectionStrength = subtotal;
          
          int redColor = (redValue / 100 * 255).floor();
          int greenColor = (greenValue / 100 * 255).floor();
          int blueColor = (blueValue / 100 * 255).floor();
          // Only apply LED color when at least one channel is non-zero.
          // All-zero means no actual LED connection: clear any stale color
          // that might have been left from a previous run (iOS intermittent gradient bug).
          if (redColor > 0 || greenColor > 0 || blueColor > 0) {
            edge.color = Color.fromARGB(255, redColor, greenColor, blueColor);
          } else {
            edge.color = null;
          }
        }
      } else
      {
        String sensoryIdx = "${edge.from}_${edge.to}";
        edge.label = mapConnectome[sensoryIdx].floor().toString();
      }
    }


    // aBufView = Float64List.fromList(savedFileJson["a"].map((v)=>v as double).toList());
    // aBufView = Float64List.fromList(savedFileJson["a"].map((v)=>v as double).toList());
    
    linkMicrophoneConnection();
    // SAFE PARSE OF BUFFERS — writes to BufView arrays (valid on ALL platforms)
    {
    try {
        if (savedFileJson["a"] == null) throw Exception("Missing 'a' parameter list");
        
        Float64List aBufList =
            Float64List.fromList(List<double>.from(savedFileJson["a"]));
        Float64List bBufList =
            Float64List.fromList(List<double>.from(savedFileJson["b"]));
        Int16List cBufList = Int16List.fromList(List<int>.from(savedFileJson["c"]));
        Int16List dBufList = Int16List.fromList(List<int>.from(savedFileJson["d"]));
        Float64List iBufList =
            Float64List.fromList(List<double>.from(savedFileJson["i"]));
        Float64List wBufList =
            Float64List.fromList(List<double>.from(savedFileJson["w"]));
    
        List<String> neuronKeys = neuronTypes.keys.toList();
        printDebug("neuronTypes.length");
        printDebug(neuronTypes.length);
        printDebug(aBufList.length);
        // CRITICAL FIX: Use tempNeuronsKey length, NOT neuronTypes.keys.length
        // tempNeuronsKey is populated in SORTED order (matching controller.nodes order)
        // neuronTypes.keys is in FILE order (insertion order during load), which differs
        int n = tempNeuronsKey.length;
        aDesignArray = {};
        bDesignArray = {};
        cDesignArray = {};
        dDesignArray = {};
        // Fix Parameter Scrambling: Use ordered keys AND enriched parameters from nodesJson
        for (int i = 0; i < n; i++) {
          String key;               // For DesignArray (must match populateMatrix: node.id format)
          String valKeyForLookup;   // For nodesJson lookup (valKey from file)
          double valA, valB, valC, valD, valI, valW;
          
          if (i < tempNeuronsKey.length) {
             var k = tempNeuronsKey[i];
             
             // CRITICAL: Resolve the actual node to get the clean ID
             InfiniteCanvasNode? node = findNeuronByKey(k);
             if (node != null) {
                 key = node.id;         // Use clean ID (matches populateMatrix)
                 valKeyForLookup = node.valKey ?? key; // Use valKey if available for json lookup
             } else {
                 key = k.toString();    // Fallback (will likely fail but prevents crash)
                 valKeyForLookup = key;
             }
             
             // Find the enriched node data using valKey
             var matchingNode = nodesJson.firstWhere((e) => e["valKey"] == valKeyForLookup, orElse: () => null);
             
             if (matchingNode != null) {
                 valA = (matchingNode["_param_a"] ?? 0.02).toDouble();
                 valB = (matchingNode["_param_b"] ?? 0.2).toDouble();
                 valC = (matchingNode["_param_c"] ?? -65.0).toDouble();
                 valD = (matchingNode["_param_d"] ?? 2.0).toDouble();
                 valI = (matchingNode["_param_i"] ?? 0.0).toDouble();
                 valW = (matchingNode["_param_w"] ?? 0.0).toDouble();
             } else {
                 // Fallback to defaults if node not found in json (should not happen)
                 valA = 0.02; valB = 0.2; valC = -65; valD = 2; valI = 0; valW = 2.0;
             }
          } else {
             // Fallback if tempNeuronsKey is incomplete
             if(i < neuronKeys.length) key = neuronKeys[i];
             else key = "unknown";
             valA = 0.02; valB = 0.2; valC = -65; valD = 2; valI = 0; valW = 2.0;
          }

          aDesignArray[key] = valA;
          bDesignArray[key] = valB;
          cDesignArray[key] = valC;
          dDesignArray[key] = valD;
          
          // SYNC PARAMS TO C++
          aBufView[i] = valA;
          bBufView[i] = valB;
          cBufView[i] = valC.round();
          dBufView[i] = valD.round();
          iBufView[i] = valI;
          wBufView[i] = valW;
          
          // Sync Microphone Persistence
          String micKey = "${nodeMicrophoneSensor.id}_$key";
          if (mapMicrophoneTypeNeuron.containsKey(micKey)) {
             microphoneTypeBufView[i] = mapMicrophoneTypeNeuron[micKey];
          } else {
             microphoneTypeBufView[i] = 0;
          }
          
          // CRITICAL MISSING SYNC: Microphone Connection Strength
          if (mapMicrophoneNeuron.containsKey(micKey)) {
             neuronMicrophoneBufView[i] = mapMicrophoneNeuron[micKey].toInt();
          } else {
             neuronMicrophoneBufView[i] = -1;
          }
          
          if (mapMicrophoneLimitNeuron.containsKey(micKey)) {
             try {
                 List<String> arr = mapMicrophoneLimitNeuron[micKey].split("_@_");
                 microphoneMinLimitBufView[i] = int.parse(arr[0]);
                 microphoneMaxLimitBufView[i] = int.parse(arr[1]);
             } catch (e) {}
          }
        }
        
        // Final pass: Re-assert types to ensure simulation matches labels
        // CRITICAL: Must iterate controller.nodes[i + 2] EXACTLY like populateMatrix does!
        // Previous approach using tempNeuronsKey[i] was wrong: tempNeuronsKey order != controller.nodes order
        for (int i = 0; i < neuronSize; i++) {
             // Get node EXACTLY like populateMatrix does
             if (i + 2 >= controller.nodes.length) continue;
             InfiniteCanvasNode neuronFrom = controller.nodes[i + 2];
             
             String type = neuronTypes[neuronFrom.id] ?? "Quiet";
             
             double fixA = -999;
             double fixB = -999;
             double fixC = -999;
             double fixD = -999;
             double fixI = -999;
             
             // Re-apply defaults for standard types to guarantee sync using VERIFIED map
             if (type == "Quiet") {
                 fixA = 0.02; fixB = 0.1; fixC = -65; fixD = 2; fixI = 0.0;
             } else if (type == "Occassionally active") {
                 fixA = 0.02; fixB = 0.17; fixC = -65; fixD = 2; fixI = 5.0;
             } else if (type == "Highly active") {
                 fixA = 0.02; fixB = 0.24; fixC = -65; fixD = 2; fixI = 15.0;
             } else if (type == "Generates bursts") {
                 fixA = 0.02; fixB = 0.17; fixC = -20; fixD = 2; fixI = 5.0;
             } else if (type == "Bursts when activated" || type == "Delay") {
                 fixA = 0.02; fixB = 0.1; fixC = -37; fixD = 2; fixI = 0.0;
             } else if (type == "Remote Control" || type == "Motion") {
                 fixA = 0.02; fixB = 0.1; fixC = -65; fixD = 2; fixI = 0.0;
             }
             
             if (type == "Custom") {
                 iBufView[i] = 5.0; // Explicitly ensure Custom gets 5.0 base current
             }
             
             // If we found a standard type, apply the fix to BOTH Buffer and DesignArray
             if (fixA != -999) {
                 aBufView[i] = fixA;
                 bBufView[i] = fixB;
                 cBufView[i] = fixC.round();
                 dBufView[i] = fixD.round();
                 iBufView[i] = fixI;
                 
                 // Also update DesignArray using neuronFrom.id (matches populateMatrix lookup)
                 aDesignArray[neuronFrom.id] = fixA;
                 bDesignArray[neuronFrom.id] = fixB;
                 cDesignArray[neuronFrom.id] = fixC;
                 dDesignArray[neuronFrom.id] = fixD;
             }
        }
    } catch (e, stack) {
        printDebug("CRITICAL ERROR LOADING PARAMS: $e");
        printDebug(stack);
    }

    try {
      printDebug("PARSING DELAY LIST...");
      List<int> safeIntList(dynamic input) {
         if (input == null) return [];
         if (input is List) {
           return input.map((e) => (e ?? -1).toInt()).toList().cast<int>();
         }
         return [];
      }

      printDebug("DEBUG LOAD: mapDelayNeuron Found? ${savedFileJson.containsKey("mapDelayNeuron")}");
      printDebug("DEBUG LOAD: neuronSize: $neuronSize");
      List<int> rawDelay = safeIntList(savedFileJson["mapDelayNeuron"]);
      printDebug("DEBUG LOAD: Raw Delay List Size: ${rawDelay.length}");
      printDebug("DEBUG LOAD: Raw Delay List Content: $rawDelay");
      
      List<int> rawRhytmic = safeIntList(savedFileJson["mapRhytmicNeuron"]);
      List<int> rawCounting = safeIntList(savedFileJson["mapCountingNeuron"]);

      mapDelayNeuronList = List.generate(neuronSize, (index) => -1);
      mapRhytmicNeuronList = List.generate(neuronSize, (index) => -1);
      // Load unified aux servo settings (new format)
      if (savedFileJson["auxServoRestPosition"] != null) {
        auxServoRestPosition = savedFileJson["auxServoRestPosition"].toDouble();
      } else if (savedFileJson["auxServoRestAngle"] != null) {
        // Legacy: convert old rest angle (0-180) to new range (-255 to +255)
        double oldAngle = savedFileJson["auxServoRestAngle"].toDouble();
        auxServoRestPosition = ((oldAngle / 180.0) * 510.0 - 255.0);
      }
      // mapAuxMotorPower already loaded and key-translated earlier (line ~13896)

      mapCountingNeuronList = List.generate(neuronSize, (index) => -1);

      for (int i = 0; i < neuronSize; i++) {
        if (i < rawDelay.length) {
             mapDelayNeuronList[i] = rawDelay[i];
        }
        if (i < rawRhytmic.length) {
             mapRhytmicNeuronList[i] = rawRhytmic[i];
        }
        if (i < rawCounting.length) {
             mapCountingNeuronList[i] = rawCounting[i];
        }
      }

      // SANITIZE LEGACY VALUES
      for (int i = 0; i < neuronSize; i++) {
        // String key = neuronKeys[i]; // WRONG: UniqueKey cannot lookup in Map<String, String>
        if (i + 2 < controller.nodes.length) {
             String key = controller.nodes[i + 2].id; // CORRECT: Use String ID from node
             String? type = neuronTypes[key];
             
             // Fix Delay Neurons
             if (type == "Delay") {
               if (mapDelayNeuronList[i] <= 0) {
                 printDebug("Sanitizing Delay Neuron at $i ($key): Setting to $minDelayTimeValue");
                 mapDelayNeuronList[i] = minDelayTimeValue;
               }
             }
        }
      }
      
      // SYNC TO C++ BUFFERS
      // Ensure the simulation engine actually sees these values
      if (mapDelayNeuronBufView.isNotEmpty && neuronSize <= mapDelayNeuronBufView.length) {
         for (int i = 0; i < neuronSize; i++) {
             mapDelayNeuronBufView[i] = mapDelayNeuronList[i];
             mapRhytmicNeuronBufView[i] = mapRhytmicNeuronList[i];
             mapCountingNeuronBufView[i] = mapCountingNeuronList[i];
         }
      }

      printDebug(mapDelayNeuronBufView);
    } catch (err) {
      printDebug("err3");
      printDebug(err);
    }
    } // end SAFE PARSE OF BUFFERS
    // On ALL platforms: use silentRepositionNeurons to mathematically remap loaded neuron
    // positions to the current screen size. This avoids the macOS double-window-resize dance
    // (resize to saved size → rebuild → resize back → rebuild) which caused two jarring
    // visual jumps and intermediate incorrect positioning.
    silentRepositionNeurons(savedFileJson);
    
    // CRITICAL FIX: Update neuronSize so buffer updates work immediately
    neuronSize = controller.nodes.length - allNeuronStartIdx;
    
    // CRITICAL FIX: Sync Connectome and Sensors to C++ Engine
    populateMatrix();

    // Reset rendering clock precisely so the UI Thread computes all initialized loaded edges instantaneously!
    // V25: refreshRetainer was deleted as geometric caching is now natively intercepted
    // InfiniteCanvasEdgeRenderer.refreshRetainer = 0;

    // macOS: the second resize (back to original size) is no longer needed because
    // we no longer resize to the saved size at load time.
    if (Platform.isWindows || Platform.isLinux) {
      await Future.delayed(const Duration(milliseconds: 370), () async {
        try {
          await windowManager.setSize(Size(tempWidth, tempHeight));
        } catch (err) {
          printDebug("windowmanager error: $err");
        }
      });
    }

    } catch (e, stackTrace) {
      printDebug("CRITICAL ERROR loading brain: $e");
      printDebug(stackTrace);
      // uiDebugLog = "Load Error: $e\n" + uiDebugLog; // Removed for release
    } finally {
      // Ensure specific flags are reset even if error occurs
      // isSettlingAfterLoad already set at top; isLoadingBrain releases now
      isLoadingBrain = false;
      brainHasUnsavedChanges.value = false; // brain just loaded — nothing unsaved yet (baseline set after animation)
      
      printDebug("DEBUG: selectSavedBrain FINISHED. isLoadingBrain reset to false.");
      
      // V25 FEATURE: ZERO-FRAME SNAP
      WidgetsBinding.instance.addPostFrameCallback((_) {
          _animateCanvasToReset(
            MediaQuery.of(context).orientation == Orientation.landscape,
            animate: true,
            onComplete: () {
              // Animation finished — brain is in final position, now safe to set baseline.
              // _setCleanBaseline() captures the exact loaded node/edge counts so that
              // any subsequent tap/pan that fires notifyListeners() (without changing
              // the structure) will NOT mark the brain as unsaved.
              if (loadGeneration == myLoadGen) {
                _setCleanBaseline(); // captures loaded brain structure as the new baseline
                isSettlingAfterLoad = false;
              }
              // CRITICAL FIX: Rebuild Nucleus widgets AFTER the camera animation.
              // initializeNucleus() may have run during the animation, but its
              // notifyListeners() was swallowed by the isAnimatingCamera guard.
              // This ensures RC/Delay icons render on first brain load.
              try {
                initializeNucleus();
              } catch(e) {}
            },
          );
      });

      // Translate loaded neurons from their saved (center-based) positions to
      // the current orientation-aware brainHome position. Saved files encode
      // neuron offsets relative to the old centered brain (windowWidth/2), but
      // in landscape brainHomeX = 101 (left-aligned to drag menu). Without this
      // call the neurons appear at screen center while brain SVG is at brainHomeX.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          repositionContactNeurons();
          setState(() {}); // Rebuild so neurons render at new positions
        }
      });

      // CRITICAL FIX: Initialize Nuclei (RC Symbols) and Sync Buffers after load
      // Consolidating redundant Futures into a single post-frame callback to prevent GlobalKey race conditions
      Future.delayed(const Duration(milliseconds: 150), () {
          // CRITICAL: Set dirty flag FIRST so edges render even if native init fails (web)
          try {
             controller.syntheticConnectionsDirty = true;
             controller.notifyListeners();
             if (mounted) setState(() {});
          } catch(e) {
             printDebug("Error in selectSavedBrain notify: $e");
          }

          // 1. Re-sync simulation buffers (Native only)
          try {
             populateMatrix();
          } catch(e) {
             printDebug("Error in populateMatrix: $e");
          }

          // 2. Re-Initialize ProtoNeuron with NEW neuronSize
          try {
             if (neuronSize > 0) {
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
                   connectomeBufView: connectomeBufView
                 );
                 
                 // 3. Populate Circles (visuals) and Parameters (behavior)
                 List<Offset> loadPos = [];
                 for (InfiniteCanvasNode node in controller.nodes) {
                     loadPos.add(node.offset);
                 }
                 setCirclesZoom(controller.scale, loadPos);
             }
          } catch(e) {
             printDebug("Error in ProtoNeuron/setCirclesZoom: $e");
          }

          // 4. ALWAYS create Nucleus widgets — even if ProtoNeuron failed
          // CRITICAL FIX: On first brain load, neuronSpikeFlags and neuronCircleKeys
          // are empty because they're only populated in initNativeC() (called by Play).
          // Without them, initializeNucleus() silently fails (index out of bounds).
          // Ensure they're sized to neuronSize before creating Nucleus widgets.
          if (neuronSpikeFlags.length < neuronSize) {
              neuronSpikeFlags = List<ValueNotifier<int>>.generate(
                  neuronSize, (_) => ValueNotifier(0));
          }
          if (neuronCircleKeys.length < neuronSize) {
              neuronCircleKeys = List<GlobalKey>.generate(
                  neuronSize, (i) => GlobalKey(debugLabel: "neuronWidget${i.toString()}"));
          }
          try {
             initializeNucleus();
          } catch(e, st) {
             print("Error in initializeNucleus: $e");
             print("$st");
          }
      });
    }

    // FIX: Sync mapContactsNeuron from edge.connectionStrength for motor edges.
    // During edge creation, connectionStrength is correctly set via priority lookup
    // (mapConnectome first, then mapContactsNeuron). But mapContactsNeuron may have
    // stale/default values. populateMotorMatrix reads ONLY from mapContactsNeuron,
    // so we must sync it from the authoritative edge.connectionStrength.
    for (var edge in controller.edges) {
      InfiniteCanvasNode? fromNode, toNode;
      try {
        fromNode = controller.nodes.firstWhere((n) => n.key == edge.from);
        toNode = controller.nodes.firstWhere((n) => n.key == edge.to);
      } catch (_) { continue; }
      if (toNode == nodeLeftMotorForwardSensor ||
          toNode == nodeLeftMotorBackwardSensor ||
          toNode == nodeRightMotorForwardSensor ||
          toNode == nodeRightMotorBackwardSensor) {
        String key = "${fromNode.id}_${toNode.id}";
        double edgeVal = edge.connectionStrength;
        if (mapContactsNeuron[key] != edgeVal) {
          print("MOTOR_FIX: Syncing mapContactsNeuron[$key] from ${mapContactsNeuron[key]} -> $edgeVal (from edge.connectionStrength)");
          mapContactsNeuron[key] = edgeVal;
        }
      }
    }

    // FINAL SAFETY NET: Force full matrix refresh after load is complete.
    neuronSize = controller.nodes.length - allNeuronStartIdx;
    populateMatrix();       // Refresh Brain-Brain connections
    populateMotorMatrix();  // Refresh Brain-Motor connections (Critical!)
    _dumpMotorBufferColumns("LOAD_2_AFTER_FINAL_POPULATE");

    printDebug("=== BRAIN LOAD COMPLETE ===");
    printDebug("mapContactsNeuron after load: $mapContactsNeuron");
    printDebug("neuronSize after load: $neuronSize");

    // aDesignArray = List<double>.from(savedFileJson["a"]);
    // bDesignArray = List<double>.from(savedFileJson["b"]);
    // cDesignArray = List<int>.from(savedFileJson["c"]);
    // dDesignArray = List<int>.from(savedFileJson["d"]);
    // iBufView = Float64List.fromList(List<double>.from(savedFileJson["i"]));
    // wBufView = Float64List.fromList(List<double>.from(savedFileJson["w"]));

    // LEGACY TYPE MIGRATION
    // LEGACY TYPE MIGRATION
    neuronTypes.forEach((key, value) {
      if (value == "Inhibitory") {
        printDebug("Migrating Legacy Type $value to Quiet+Inhibitory for $key");
        neuronTypes[key] = "Quiet";
        neuronStyles[key] = "Inhibitory";
      } else if (value == "Excitatory") {
        printDebug("Migrating Legacy Type $value to Quiet+Excitatory for $key");
        neuronTypes[key] = "Quiet";
        neuronStyles[key] = "Excitatory";
      }
    });

    // SYNC STYLES TO NODES (Fix Visuals)
    for (var node in controller.nodes) {
      if (neuronStyles[node.id] == "Inhibitory") {
        node.isExcitatory = 0;
      } else if (neuronStyles[node.id] == "Excitatory") {
        node.isExcitatory = 1;
      }
    }
    
    if (Navigator.canPop(context)) {
        Navigator.pop(context);
    }
  }

  void setCirclesZoom(double scale, List<Offset> pos) {
    if (protoNeuron == null) return; // Not yet initialized
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

    // CRITICAL FIX: Build ORDERED list of types from controller.nodes to match pos list.
    // protoNeuron.generateCircle expects types to match positions index-for-index.
    // neuronTypes.values.toList() is UNORDERED and causes mismatch/scrambling.
    List<String> orderedTypes = [];
    int nodeIdx = 0;
    for (InfiniteCanvasNode node in controller.nodes) {
         if (nodeIdx >= allNeuronStartIdx) {
             // Robust Lookup: Try ID first, then Key String. Map usage is inconsistent.
             String? typeID = neuronTypes[node.id];
             String? typeKey = neuronTypes[node.key.toString()];
             String type = typeID ?? typeKey ?? "Quiet";
             
             // DEBUG LOG
             // printDebug("Node[$nodeIdx] ID:${node.id} Key:${node.key.toString()} -> Type: $type (Matches ID? ${typeID!=null} Key? ${typeKey!=null})");
             
             orderedTypes.add(type);
         }
         nodeIdx++;
    }
    
    printDebug("OrderedTypes (Len: ${orderedTypes.length}): $orderedTypes");

    // Fallback if list construction fails or mismatches (shouldn't happen with logic above)
    if (orderedTypes.length != neuronSize) {
        printDebug("WARNING: orderedTypes length mismatch in setCirclesZoom. expected $neuronSize got ${orderedTypes.length}");
        // Fallback to old behavior but warn
        protoNeuron!.generateCircle(neuronSize, pos, neuronTypes.values.toList()); 
    } else {
        protoNeuron!.generateCircle(neuronSize, pos, orderedTypes);
    }
    
    len = protoNeuron!.circles.length;
    for (int i = 0; i < len; i++) {
      SingleNeuron circle = protoNeuron!.circles[i];
      circle.centerPos = pos[allNeuronStartIdx + i];
    }
    
    // FORCE UPDATE
    if (protoNeuron!.circles.isNotEmpty) {
        // Log first circle param to verify
        // printDebug("Circle[0] Buf Check: A=${aBufView[0]} C=${cBufView[0]} D=${dBufView[0]}");
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
    // Skip during camera animation — setting controller.scale + running debounced
    // setCirclesZoom every 16ms competes with the smooth 1-second pan animation.
    if (controller.isAnimatingCamera) return;
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
    }
  }

  Map<String, String> translateLoadedNeuron(Map<String, dynamic> targetMap,
      Map<String, String> mapTranslateLoadKeys,
      {bool migrateTypes = false}) {
    Map<String, String> transformedMap = {};
    printDebug("mapTranslateLoadKeys");
    printDebug(mapTranslateLoadKeys);
    if (targetMap == null) return {};

    targetMap.forEach((key, value) {
      if (mapTranslateLoadKeys.containsKey(key)) {
        String translatedKey = mapTranslateLoadKeys[key]!;
        // Migration: Map legacy types to 'Quiet'
        // STRICT CHECK needed.
        String strValue = value.toString().trim();
        printDebug("Reviewing Type: $key -> $strValue");

        if (migrateTypes &&
            (strValue == "Excitatory" ||
                strValue == "Inhibitory" ||
                strValue == "Positive" ||
                strValue == "Negative")) {
          printDebug("  -> Migrating to Quiet");
          transformedMap[translatedKey] = "Quiet";
        } else {
          printDebug("  -> Keeping As Is");
          transformedMap[translatedKey] = strValue;
        }
      } else {
         printDebug("Skipping Unknown Key in Type Map: $key");
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

  // _globalScrollRoute: TRACKPAD PAN ONLY.
  // Mouse scroll zoom is handled exclusively by the deep Listener inside the
  // InteractiveViewer builder in canvas.dart — putting it here too caused
  // double-transform per scroll tick (zoom + translation applied twice).
  void _globalScrollRoute(PointerEvent event) {
    if (event is! PointerScrollEvent) return;
    if (!isInitialized) return;
    if (event.kind != PointerDeviceKind.trackpad) return; // Mouse zoom handled by deep Listener in canvas.dart
    if (WaveWidget.isMouseOver) return; // Let WaveWidget handle scroll when hovering the plot
    GestureBinding.instance.pointerSignalResolver.register(event, (PointerSignalEvent e) {
      if (e is! PointerScrollEvent) return;
      if (e.kind != PointerDeviceKind.trackpad) return;
      // Trackpad 2-finger swipe → pan the canvas (translate in scene/canvas coordinates).
      final double scale = controller.getScale();
      final Matrix4 matrix = controller.transform.value.clone();
      matrix.translate(-e.scrollDelta.dx / scale, -e.scrollDelta.dy / scale);
      controller.transform.value = matrix;
    });
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

    InfiniteCanvasNode? nodeFrom = findNeuronByKeySafe(controller.edgeSelected!.from);
    InfiniteCanvasNode? nodeTo = findNeuronByKeySafe(controller.edgeSelected!.to);
    
    // V25: Safety Check
    if (nodeFrom == null || nodeTo == null) {
        printDebug("Error: selectEdgeMenuType - Source or Target node not found for edge selection.");
        // If we can't find the nodes, we can't show the menu.
        // To prevent "Visual Break" (UI Shift), we must deselect the bad edge.
        controller.deselectAll(); 
        clearUIMenu();
        return;
    }

    if (nodeFrom == nodeLeftEyeSensor || nodeFrom.id == nodeRightEyeSensor.id) {
      isCameraMenu = true;
      activeCameraType = nodeFrom == nodeLeftEyeSensor ? "Left Eye Visual Trigger" : "Right Eye Visual Trigger";
      InfiniteCanvasNode selected = findNeuronByKey(controller.edgeSelected!.to);
      int neuronIdx = neuronTypes.keys.toList().indexOf(selected.id);
      if (neuronIdx == -1) {
          printDebug("Error: Node ID ${selected.id} not found in neuronTypes");
          return;
      }

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
      } else {
        selectedEyeInfo = {
            "icon": cameraMenuTypes[0],
            "label": "Color ${cameraMenuTypes[0]}",
            "idx": 0
        };
      }

      var selectedCameraRegion = mapAreaSize[sensoryKey];
      if (selectedCameraRegion != null) {
        List<String> splitRegion = selectedCameraRegion.split("_@_");
        selectedCameraPosition = splitRegion[0];
        txtAreaSizeMinController.text = splitRegion[1];
        txtAreaSizeMaxController.text = splitRegion[2];
        areaSizeMinLimitBufView[neuronIdx] = int.parse(splitRegion[1]);
        areaSizeMaxLimitBufView[neuronIdx] = int.parse(splitRegion[2]);
      } else {
        selectedCameraPosition = "Any";
        txtAreaSizeMinController.text = "1";
        txtAreaSizeMaxController.text = "320";
        areaSizeMinLimitBufView[neuronIdx] = 1;
        areaSizeMaxLimitBufView[neuronIdx] = 320;
      }
    } else if (nodeFrom.id == nodeDistanceSensor.id) {
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
    } else if (nodeTo.value == 5 || // Left Motor Forward
               nodeTo.value == 6 || // Right Motor Forward
               nodeTo.value == 7 || // Left Motor Backward
               nodeTo.value == 8) { // Right Motor Backward
      printDebug("nodeRightMotorBackwardSensor");
      isMotorMenu = true;
      
      // edge.connectionStrength is the source of truth (set correctly from maps during load at line ~10999).
      // We read from the edge AND sync to mapContactsNeuron to ensure simulation uses the correct value.
      // (fillCreatedAxon callback overwrites mapContactsNeuron to 25 during edge creation, so the map can be stale.)
      // print("DEBUG: selectEdgeMenuType (MOTOR) - Reading edge.connectionStrength: ${controller.edgeSelected!.connectionStrength}"); // TRACE READ
      // uiDebugLog = "SEL_MOT Read: ${controller.edgeSelected!.connectionStrength}\n" + uiDebugLog;
      sldSynapticWeight = controller.edgeSelected!.connectionStrength;
      tecSynapticWeight.text = sldSynapticWeight.round().toString();
      
      // Sync map FROM edge (repairs any overwrite by fillCreatedAxon)
      // print("DEBUG: selectEdgeMenuType (MOTOR) - Writing to mapContactsNeuron: $sldSynapticWeight"); // TRACE WRITE
      // uiDebugLog = "SEL_MOT Write: $sldSynapticWeight\n" + uiDebugLog;
      mapContactsNeuron["${nodeFrom.id}_${nodeTo.id}"] = sldSynapticWeight;
      
      // Also update buffer immediately so simulation is correct even before slider move
      updateLiveConnectionBuffer(nodeFrom, nodeTo, sldSynapticWeight, "motor");
      _dumpMotorBufferColumns("EDGE_SELECT_AFTER_UPDATE");
    } else if (nodeTo.value == 4) { // Speaker Sensor
      isSpeakerMenu = true;
      if (mapSpeakerNeuron["${nodeFrom.id}_${nodeTo.id}"] != null) {
        sldFrequencyWeight =
            mapSpeakerNeuron["${nodeFrom.id}_${nodeTo.id}"].roundToDouble();
        tecFrequencyWeight.text = sldFrequencyWeight.round().toString();
      }
    } else if (nodeFrom.value == 3) { // Microphone Sensor
      isMicrophoneMenu = true;
      // isMicrophoneMenu
      InfiniteCanvasNode nodeN = findNeuronByKey(nodeTo.id);
      int neuronIdx = neuronTypes.keys.toList().indexOf(nodeN.id);

      if (neuronIdx != -1) {
          if (microphoneMinLimitBufView.isEmpty || microphoneMaxLimitBufView.isEmpty || microphoneTypeBufView.isEmpty) {
             printDebug("Warning: Mic Buffers not init yet");
             isMicrophoneMenu = false; // FORCE FALSE to prevent UI build crash
             return;
          }
          int minVal = microphoneMinLimitBufView[neuronIdx];
          int maxVal = microphoneMaxLimitBufView[neuronIdx];
          
          String key = "${nodeFrom.id}_${nodeTo.id}";
          if (mapMicrophoneLimitNeuron.containsKey(key)) {
             try {
                String temp = mapMicrophoneLimitNeuron[key];
                List<String> arr = temp.split("_@_");
                minVal = int.parse(arr[0]);
                maxVal = int.parse(arr[1]);
                microphoneMinLimitBufView[neuronIdx] = minVal;
                microphoneMaxLimitBufView[neuronIdx] = maxVal;
             } catch (e) {
                // error parsing
             }
          }
          
          // Validate and fix degenerate or default-clamped ranges (e.g. 100-100)
          if (minVal < 100 || maxVal < 100 || minVal >= maxVal) {
              minVal = 400;
              maxVal = 800;
              microphoneMinLimitBufView[neuronIdx] = 400;
              microphoneMaxLimitBufView[neuronIdx] = 800;
          }
          
          txtMicrophoneMinController.text = minVal.toString();
          txtMicrophoneMaxController.text = maxVal.toString();
      }
    } else if (nodeTo == nodeSingleLed ||
        nodeTo == nodeRedLed ||
        nodeTo == nodeGreenLed ||
        nodeTo == nodeBlueLed) {
      isLedMenu = true;
      // printDebug('mapLedNeuron["${nodeFrom.id}_${nodeTo.id}"]');
      // printDebug(mapLedNeuron["${nodeFrom.id}_${nodeTo.id}"]);

      sldSynapticWeightR = fillDefaultData(
          mapLedNeuron, "${nodeFrom.id}_${nodeRedLed.id}", tecSynapticWeightR);
      sldSynapticWeightG = fillDefaultData(mapLedNeuron,
          "${nodeFrom.id}_${nodeGreenLed.id}", tecSynapticWeightG);
      sldSynapticWeightB = fillDefaultData(
          mapLedNeuron, "${nodeFrom.id}_${nodeBlueLed.id}", tecSynapticWeightB);
      String hexColor = rgbToHex(
          (sldSynapticWeightR / 100 * 255).floor(),
          (sldSynapticWeightG / 100 * 255).floor(),
          (sldSynapticWeightB / 100 * 255).floor());
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
      
      // V23: Restore NEW LED widget state from maps
      String activeKey = "${nodeFrom.id}_${nodeRedLed.id}";
      if (mapLedNeuronPosition[activeKey] != null) {
        _robotLedActive = mapLedNeuronPosition[activeKey] ?? "1111";
      } else {
        _robotLedActive = "1111";
      }
      
      // Restore hex and brightness from new maps
      String connectionKey = "${nodeFrom.id}_${nodeTo.id}";
      if (mapLedHex.containsKey(connectionKey)) {
        _robotLedHex = mapLedHex[connectionKey] ?? "FD8164";
        _robotLedBrightness = mapLedBrightness[connectionKey] ?? "0.50";
      } else {
        // Fallback: reverse-engineer hex + brightness from R/G/B mapLedNeuron values
        // This ensures white at 50% shows as FFFFFF@0.50, not 7F7F7F@1.00
        double maxCh = max(sldSynapticWeightR, max(sldSynapticWeightG, sldSynapticWeightB));
        if (maxCh > 0) {
          _robotLedBrightness = (maxCh / 100.0).toStringAsFixed(2);
          int rNorm = ((sldSynapticWeightR / maxCh) * 255).floor();
          int gNorm = ((sldSynapticWeightG / maxCh) * 255).floor();
          int bNorm = ((sldSynapticWeightB / maxCh) * 255).floor();
          _robotLedHex = rgbToHex(rNorm, gNorm, bNorm).toUpperCase();
        } else {
          _robotLedHex = "FFFFFF";
          _robotLedBrightness = "0.50";
        }
        // Persist to maps so subsequent visits use the hex/brightness pathway
        mapLedHex[connectionKey] = _robotLedHex;
        mapLedBrightness[connectionKey] = _robotLedBrightness;
      }
      
      printDebug("Loaded LED State: Hex=$_robotLedHex, Bri=$_robotLedBrightness, Mask=$_robotLedActive");
    } else {
      isSynapseMenu = true;
      
      // edge.connectionStrength is always the source of truth.
      // Sync to mapConnectome to keep simulation consistent.
      sldSynapticWeight = controller.edgeSelected!.connectionStrength;
      tecSynapticWeight.text = sldSynapticWeight.round().toString();
      mapConnectome["${nodeFrom.id}_${nodeTo.id}"] = sldSynapticWeight;
      
      // Update buffer immediately
      updateLiveConnectionBuffer(nodeFrom, nodeTo, sldSynapticWeight, "connectome");
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

    final lastCreatedEdge = controller.edgeSelected!;
    final neuronFrom = findNeuronByKey(lastCreatedEdge.from);
    final neuronTo = findNeuronByKey(lastCreatedEdge.to);
    // mapConnectome["${lastCreatedEdge.from}_${lastCreatedEdge.to}"] = val;
    String speakerKey = "${neuronFrom.id}_${neuronTo.id}";
    mapSpeakerNeuron[speakerKey] = val;
    controller.mapSpeakerNeuron = Map.from(mapSpeakerNeuron); // SYNC TO CONTROLLER
    printDebug("DEBUG: linkSpeakerConnection Updated Key: $speakerKey = $val");
    uiDebugLog = "Spk: $speakerKey -> ${val.toStringAsFixed(1)}\n" + uiDebugLog; // Prepend
    
    lastCreatedEdge.connectionStrength = ((val / 4978) * 100).toDouble();
    lastCreatedEdge.label = val.floor().toString();
    // printDebug("${neuronFrom.id}_${neuronTo.id}");
    
    // CRITICAL FIX: Update live buffer immediately during slider drag
    // This prevents the "stale data" bug where speakers used old frequency values
    updateLiveConnectionBuffer(neuronFrom, neuronTo, val, "speaker");
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
    isNeuronBehaviorExpanded = false;
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
    aBufView = aBuf.asTypedList(neuronSize);
    bBufView = bBuf.asTypedList(neuronSize);
    cBufView = cBuf.asTypedList(neuronSize);
    dBufView = dBuf.asTypedList(neuronSize);
  }

  List<String> empty = [];
  double multiplierConstant = 0.78;
  double multiplierAdjusterConstant = 0.5;
  int robotMessageDelay = 16; // Boosted to ~60 FPS (16ms) for extreme biological synchronization.
  // Pre-allocated with fixed capacity — cleared in-place each cycle to avoid GC pressure.
  List<int> infoStatusMax = List<int>.filled(7, 0, growable: false);
  List<List<int>> diodeStatusMax = List.generate(4, (_) => List<int>.filled(3, 0));
  List<int> periodicNeuronSpikingFlags = [];
  List<double> dartLedCapacitor = []; // V44 FIX: Absolute hardware decay tracker
  
  double motorLeftDecayPower = 0.0;
  double motorRightDecayPower = 0.0;
  
  // Speaker command hold — ensures spike-triggered speaker commands persist
  // for enough frames to guarantee websocket delivery
  int _speakerHoldValue = 0;
  int _speakerHoldFrames = 0;
  static const int _speakerHoldDuration = 5; // ~80ms at 60fps
  
  void processRobotMessages() {
      infoStatusMax.fillRange(0, infoStatusMax.length, 0);
      
      // V44 FIX: Clear buffer for pure Dart-side hardware summation regeneration
      for (final row in diodeStatusMax) {
          row[0] = 0; row[1] = 0; row[2] = 0;
      }
      
      // Resize periodicNeuronSpikingFlags only if neuronSize changed; otherwise fill.
      final int flagCount = neuronSize - normalNeuronStartIdx;
      if (periodicNeuronSpikingFlags.length != flagCount) {
        periodicNeuronSpikingFlags = List<int>.filled(flagCount, 0, growable: true);
      } else {
        periodicNeuronSpikingFlags.fillRange(0, flagCount, 0);
      }
      int diodeCounter = 0;
      double leftSumForwardValue = 0;
      double leftSumBackwardValue = 0;
      double rightSumForwardValue = 0;
      double rightSumBackwardValue = 0;
      int leftValidForwardCounter = 0;
      int leftValidBackwardCounter = 0;
      int rightValidForwardCounter = 0;
      int rightValidBackwardCounter = 0;
      // printDebug("processRobotMessages Delay");
      if (isPlayingMenu) {
        // Inject current into Motion neurons based on live IMU sensor state
        _updateMotionNeurons();
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
            for (int i = 0; i < len; i++) {
              List<String> arr = commands[i].split(";");
              int n = arr.length;
              for (int j = 0; j < n; j++) {
                List<String> arrStr = arr[j].split(":");
                if (arrStr[0] == "lf") {
                  int val = int.parse(arrStr[1]);
                  if (val != 0) { leftValidForwardCounter++; leftSumForwardValue += val; }
                } else if (arrStr[0] == "lb") {
                  int val = int.parse(arrStr[1]);
                  if (val != 0) { leftValidBackwardCounter++; leftSumBackwardValue += val; }
                } else if (arrStr[0] == "rf") {
                  int val = int.parse(arrStr[1]);
                  if (val != 0) { rightValidForwardCounter++; rightSumForwardValue += val; }
                } else if (arrStr[0] == "rb") {
                  int val = int.parse(arrStr[1]);
                  if (val != 0) { rightValidBackwardCounter++; rightSumBackwardValue += val; }
                } else if (arrStr[0] == "s") {
                  infoStatusMax[2] =
                      max(infoStatusMax[2], int.parse(arrStr[1]));
                } else if (arrStr[0] == "n") {
                  List<String> spikingFlags = arrStr[1].split("|");
                  // printDebug("spikingFlags");
                  // printDebug(spikingFlags);
                  // printDebug(periodicNeuronSpikingFlags);

                  for (int k = 0; k < spikingFlags.length; k++) {
                    if (spikingFlags[k].isEmpty) continue; // CRITICAL: Prevent FormatException on empty str
                    if (k >= periodicNeuronSpikingFlags.length) continue; // Boundary safety check
                    periodicNeuronSpikingFlags[k] = max(
                        periodicNeuronSpikingFlags[k],
                        int.parse(spikingFlags[k]));
                  }
                } // Note: Completely removed `d:` parsing. C++ LED strings are now ignored to prevent phase flickering.
              }
            }
            // Reconstruct motor message moved outside `if (commands.isNotEmpty)` to ensure decay translates to hardware!
            // printDebug("diodeString");
            // printDebug(diodeString);
            // printDebug(leftSumValue);
            // printDebug(leftValidValueCounter);
            // printDebug(rightSumValue );
            // printDebug(rightValidValueCounter);
            // printDebug("infoStatusMax");
            // printDebug(infoStatusMax);

            int flagSize = periodicNeuronSpikingFlags.length;
            if (dartLedCapacitor.length != flagSize) {
                dartLedCapacitor = List<double>.filled(flagSize, 0.0, growable: true);
            }

            // V44 FIX: Seamless 60FPS UI-side individual capacitor decay and RGB summation!
            // No dropouts from out-of-sync C++ 30ms native polling.
            for (int i = 0; i < flagSize; i++) {
                if (periodicNeuronSpikingFlags[i] == 1) {
                    dartLedCapacitor[i] = 1.0;
                } else {
                    dartLedCapacitor[i] *= 0.90; // Smooth 16ms UI decay (~50ms visual tail)
                    if (dartLedCapacitor[i] < 0.01) dartLedCapacitor[i] = 0.0;
                }
            }

            // Construct diode status entirely from local UI configuration constraints:
            for (int c = 0; c < 4; c++) {
                double sumR = 0;
                double sumG = 0;
                double sumB = 0;
                for (int i = 0; i < flagSize; i++) {
                    double cap = dartLedCapacitor[i];
                    if (cap > 0.0) {
                        int nodeIndex = i + normalNeuronStartIdx + 2; // +2 to account for tailNode and viewPortNode
                        if (nodeIndex >= controller.nodes.length) continue; // Safety bounds
                        var n = controller.nodes[nodeIndex];
                        
                        String redKey = "${n.id}_${nodeRedLed.id}";
                        String greenKey = "${n.id}_${nodeGreenLed.id}";
                        String blueKey = "${n.id}_${nodeBlueLed.id}";
                        
                        String posStr = mapLedNeuronPosition[redKey] ?? "0000";
                        if (c < posStr.length && posStr[c] == '1') {
                            double rW = mapLedNeuron[redKey] != null ? mapLedNeuron[redKey].toDouble() : 0.0;
                            double gW = mapLedNeuron[greenKey] != null ? mapLedNeuron[greenKey].toDouble() : 0.0;
                            double bW = mapLedNeuron[blueKey] != null ? mapLedNeuron[blueKey].toDouble() : 0.0;
                            
                            sumR += (rW * 2.55 * cap);
                            sumG += (gW * 2.55 * cap);
                            sumB += (bW * 2.55 * cap);
                        }
                    }
                }
                diodeStatusMax[c][0] = min(255, sumR.round());
                diodeStatusMax[c][1] = min(255, sumG.round());
                diodeStatusMax[c][2] = min(255, sumB.round());
            }

            String diodeString = "";
            for (int c = 0; c < 4; c++) {
              // [l:0, r:0, s:0, n:0|0|1, d:0,0,0,127, d:1,0,0,127, d:2,0,0,127, d:3,0,0,127, ]
              diodeString =
                  "${diodeString}d:$c,${diodeStatusMax[c][0]},${diodeStatusMax[c][1]},${diodeStatusMax[c][2]};";
            }
            _lastSentDiodeString = diodeString;

            int avgLeft = 0;
            int avgRight = 0;
            String msg = "";

            // Average only over commands that actually carried a non-zero directional value.
            // This matches the legacy build's leftSumValue/leftValidValueCounter approach and
            // prevents sparse motor spikes from being diluted by the total command count.
            double lfFinal = leftValidForwardCounter  > 0 ? leftSumForwardValue  / leftValidForwardCounter  : 0;
            double lbFinal = leftValidBackwardCounter > 0 ? leftSumBackwardValue / leftValidBackwardCounter : 0;
            double rfFinal = rightValidForwardCounter > 0 ? rightSumForwardValue / rightValidForwardCounter : 0;
            double rbFinal = rightValidBackwardCounter> 0 ? rightSumBackwardValue/ rightValidBackwardCounter : 0;

            // A biologically accurate motor neuron can only pull (excite) or relax (be inhibited).
            // It cannot actively fire the antagonist muscle. Therefore, we clamp negative directional pools to 0
            // so inhibitory signals act purely as brakes/suppressors, not reverse thrusters.
            if (lfFinal < 0) lfFinal = 0;
            if (lbFinal < 0) lbFinal = 0;
            if (rfFinal < 0) rfFinal = 0;
            if (rbFinal < 0) rbFinal = 0;

            // Difference the opposing muscle groups into a physical vector for each wheel
            // Swap left forward/backward per custom hardware wiring:
            double rawLeft = lfFinal - lbFinal; 
            double rawRight = rbFinal - rfFinal;

            // Apply pure 1:1 raw thrust:
            // 25% input = 25 motor speed output. 
            // 100% input = 100 motor speed output.
            // Spikes stack linearly (50 + 50 = 100).
            double applyRawThrust(double inputRaw) {
              if (inputRaw == 0) return 0;
              double sign = inputRaw < 0 ? -1.0 : 1.0;
              double absolute = inputRaw.abs();
              
              // Direct 1:1 mapping. No doubling, no curves.
              double powerMap = absolute; 
              
              // Absolute safety bounds so we don't break the ESP32 firmware 
              // (which typically caps mathematically at 255 before failing)
              if (powerMap > 255.0) powerMap = 255.0; 
              
              return sign * powerMap;
            }

            // DO NOT cap inputs to 100! 
            // Allow rawLeft/rawRight to naturally stack past 100 if the user 
            // connects enough excitatory neurons (e.g. 100 + 100 = 200 thrust!)
            
            // Apply 1:1 Thrust
            if (rawLeft.abs() > 5) {
                avgLeft = applyRawThrust(rawLeft).floor();
            } else {
                avgLeft = 0;
            }
            
            if (rawRight.abs() > 5) {
                avgRight = applyRawThrust(rawRight).floor();
            } else {
                avgRight = 0;
            }
            
            // --- MOTOR CAPACITOR / MUSCLE DECAY ---
            // Simulates biological muscle relaxation. 
            // A sharp voltage spike instantly contracts the muscle (overriding decay),
            // but when the spike drops, the muscle slowly relaxes over time instead of snapping to 0.
            if (avgLeft.abs() > motorLeftDecayPower.abs() || (avgLeft.sign != motorLeftDecayPower.sign && avgLeft != 0)) {
               motorLeftDecayPower = avgLeft.toDouble();
            } else {
               motorLeftDecayPower *= 0.90; // Decay by 10% each 16ms frame
               if (motorLeftDecayPower.abs() < 15.0) motorLeftDecayPower = 0; // Cut-off dead-zone motor whine
            }

            if (avgRight.abs() > motorRightDecayPower.abs() || (avgRight.sign != motorRightDecayPower.sign && avgRight != 0)) {
               motorRightDecayPower = avgRight.toDouble();
            } else {
               motorRightDecayPower *= 0.90;
               if (motorRightDecayPower.abs() < 15.0) motorRightDecayPower = 0;
            }

            avgLeft = motorLeftDecayPower.floor();
            avgRight = motorRightDecayPower.floor();

            // --- SPEAKER HOLD ---
            // Speaker commands are instantaneous spikes (1 frame). Hold them for
            // _speakerHoldDuration frames to guarantee websocket delivery.
            int speakerFreq = infoStatusMax[2];
            if (speakerFreq > 0) {
              // New spike — capture and start hold
              _speakerHoldValue = speakerFreq;
              _speakerHoldFrames = _speakerHoldDuration;
            } else if (_speakerHoldFrames > 0) {
              // Still holding previous spike
              speakerFreq = _speakerHoldValue;
              _speakerHoldFrames--;
            }

            // --- AUX MOTOR (SERVO) ---
            // Works exactly like L/R motor system nodes: when a source neuron
            // spikes and has a connection TO an Aux Motor neuron, that neuron's
            // configured power activates the aux servo. The Aux Motor neuron
            // itself does NOT need to spike — it's a passive motor target.
            double auxSum = 0.0;
            int auxCount = 0;

            // Step 1: Check if any Aux Motor neuron itself is spiking
            // The aux motor neuron integrates its inputs via Izhikevich model
            // (excitatory inputs push toward spiking, inhibitory suppress it).
            // Only when the aux motor neuron ITSELF spikes does it command the servo.
            for (int i = 0; i < flagSize; i++) {
                if (periodicNeuronSpikingFlags[i] == 1) {
                    int nodeIndex = i + normalNeuronStartIdx + 2;
                    if (nodeIndex < controller.nodes.length) {
                        String nodeId = controller.nodes[nodeIndex].id;
                        String nType = neuronTypes[nodeId] ?? "";
                        if (nType == "Aux Motor") {
                            double power = mapAuxMotorPower[nodeId] ?? 255.0;
                            auxSum += power;
                            auxCount++;
                        }
                    }
                }
            }

            // UNIFIED AUX SERVO: Decay toward triggered value or resting position
            if (auxCount > 0) {
                // Triggered: move toward the commanded value
                auxMotorDecayPower = auxMotorDecayPower + (auxSum / auxCount - auxMotorDecayPower) * 0.15;
            } else {
                // Not triggered: decay toward resting position
                auxMotorDecayPower = auxMotorDecayPower + (auxServoRestPosition - auxMotorDecayPower) * 0.10;
                if ((auxMotorDecayPower - auxServoRestPosition).abs() < 2.0) auxMotorDecayPower = auxServoRestPosition;
            }

            int finalAuxCommand = auxMotorDecayPower.clamp(-255.0, 255.0).round();

            // Swap Left/Right mapping physically applied to the robot per custom hardware wiring
            msg =
                "l:${avgRight};r:${avgLeft};s:${speakerFreq};a:${finalAuxCommand};$diodeString";
// */
            if (isIsolateWritePortInitialized && isPlayingMenu) {
              _auxDiagCounter++;
              _lastSentMotorRight = avgLeft;
              _lastSentMotorLeft = avgRight;
              _lastSentDiodeString = diodeString;
              // Force TCP flush by exceeding the default MTU (Maximum Transmission Unit) with safe whitespace
              String paddedMsg = msg.padRight(1450, ' ');
              sendToRobot(paddedMsg);
            }

            try {
              // V33: Dynamic Sensor Spike Tracking for proper interactive fading
              if (!controller.isAnimatingCamera && controller.nucleusList != null) {
                  // Distance Sensor Spikes
                  if (distanceBufView.isNotEmpty && controller.mapDistanceNeuron.isNotEmpty) {
                      double dVal = distanceBufView[0];
                      for (String key in controller.mapDistanceNeuron.keys) {
                          bool passed = false;
                          if (mapDistanceLimitNeuron.containsKey(key)) {
                              String temp = mapDistanceLimitNeuron[key];
                              List<String> arr = temp.split("_@_");
                              int minL = int.parse(arr[0]);
                              int maxL = int.parse(arr[1]);
                              if (dVal >= minL && dVal < maxL) passed = true;
                          } else {
                              if (dVal >= 1 && dVal < 8) passed = true;
                          }
                          if (passed) {
                              List<String> split = key.split('_');
                              if (split.length >= 2) flashEdge(split[0], split[1]);
                          }
                      }
                  }
                  
                  // Microphone Sensor Spikes
                  if (microphoneBufView.isNotEmpty && controller.mapMicrophoneNeuron.isNotEmpty) {
                      for (String key in controller.mapMicrophoneNeuron.keys) {
                          bool passed = false;
                          int mType = controller.mapMicrophoneTypeNeuron[key]?.toInt() ?? 0;
                          double mVal = (mType == 1) ? (microphoneBufView.length > 1 ? microphoneBufView[1] : microphoneBufView[0]) : microphoneBufView[0];
                          
                          if (mType == 2) {
                              if (mapMicrophoneLimitNeuron.containsKey(key)) {
                                  String temp = mapMicrophoneLimitNeuron[key];
                                  int noteIndex = int.tryParse(temp.split("_@_").first) ?? 0;
                                  if (noteIndex < 0) noteIndex = 0;
                                  if (noteIndex > 11) noteIndex = 11;
                                  
                                  const List<List<List<double>>> toneRanges = [
                                    [ [127.089, 134.646], [254.178, 269.292], [508.355, 538.584], [1016.71, 1077.17], [2033.42, 2154.33] ],
                                    [ [134.646, 142.652], [269.292, 285.305], [538.584, 570.609], [1077.17, 1141.22], [2154.33, 2282.44] ],
                                    [ [142.652, 151.135], [285.305, 302.270], [570.609, 604.540], [1141.22, 1209.08], [2282.44, 2418.16] ],
                                    [ [151.135, 160.122], [302.270, 320.244], [604.540, 640.487], [1209.08, 1280.97], [2418.16, 2561.95] ],
                                    [ [160.122, 169.643], [320.244, 339.286], [640.487, 678.573], [1280.97, 1357.15], [2561.95, 2714.29] ],
                                    [ [169.643, 179.731], [339.286, 359.461], [678.573, 718.923], [1357.15, 1437.85], [2714.29, 2875.69] ],
                                    [ [179.731, 190.418], [359.461, 380.836], [718.923, 761.672], [1437.85, 1523.34], [2875.69, 3046.69] ],
                                    [ [190.418, 201.741], [380.836, 403.482], [761.672, 806.964], [1523.34, 1613.93], [3046.69, 3227.85] ],
                                    [ [201.741, 213.737], [403.482, 427.474], [806.964, 854.948], [1613.93, 1709.90], [3227.85, 3419.79] ],
                                    [ [213.737, 226.446], [427.474, 452.893], [854.948, 905.786], [1709.90, 1811.57], [3419.79, 3623.14] ],
                                    [ [226.446, 239.912], [452.893, 479.823], [905.786, 959.647], [1811.57, 1919.29], [3623.14, 3838.59] ],
                                    [ [239.912, 254.178], [479.823, 508.355], [959.647, 1016.710], [1919.29, 2033.42], [3838.59, 4066.84] ]
                                  ];
                                  
                                  for (int oct = 0; oct < 5; oct++) {
                                      if (mVal >= toneRanges[noteIndex][oct][0] && mVal < toneRanges[noteIndex][oct][1]) {
                                          passed = true;
                                          break;
                                      }
                                  }
                              }
                          } else {
                              if (mapMicrophoneLimitNeuron.containsKey(key)) {
                                  String temp = mapMicrophoneLimitNeuron[key];
                                  List<String> arr = temp.split("_@_");
                                  int minL = int.parse(arr[0]);
                                  int maxL = int.parse(arr[1]);
                                  if (mVal >= minL && mVal < maxL) passed = true;
                              } else {
                                  // Default for speech/volume
                                  if (mType == 1 && mVal >= 200 && mVal < 1000) passed = true;
                                  if (mType == 0 && mVal >= 400 && mVal < 800) passed = true;
                              }
                          }
                          if (passed) {
                              List<String> split = key.split('_');
                              if (split.length >= 2) flashEdge(split[0], split[1]);
                          }
                      }
                  }
                  
                  // Camera Sensor Spikes
                  if (visualInputBufView.isNotEmpty && controller.mapSensoryNeuron.isNotEmpty) {
                      for (String key in controller.mapSensoryNeuron.keys) {
                          bool isLeftEye = key.contains(nodeLeftEyeSensor.id);
                          bool isRightEye = key.contains(nodeRightEyeSensor.id);
                          if (isLeftEye || isRightEye) {
                              int colorIdx = controller.mapSensoryNeuron[key];
                              List<String> split = key.split('_');
                              if (split.length < 2) continue;
                              
                              int jNeuron = controller.nodes.indexWhere((n) => n.id == split[1]);
                              if (jNeuron >= 0) {
                                  int jNeuronIdx = jNeuron - 2;
                                  int vIdx = colorIdx + jNeuronIdx * VisualInputLength;
                                  if (vIdx >= 0 && vIdx < visualInputBufView.length) {
                                      if (visualInputBufView[vIdx] > 0) {
                                           flashEdge(split[0], split[1]);
                                      }
                                  }
                              }
                          }
                      }
                  }
              }

              for (int i = normalNeuronStartIdx; i < neuronSize; i++) {
                int neuronIndex = i;
                bool hasNucleus = controller.nucleusList != null && controller.nucleusList!.length > neuronIndex;
                int currentSpikeState = hasNucleus ? controller.nucleusList![neuronIndex].isSpiking : -1;

                if (periodicNeuronSpikingFlags[i - normalNeuronStartIdx] == 1) {
                  if (currentSpikeState != 1) {
                      if (hasNucleus) {
                        controller.nucleusList![neuronIndex].isSpiking = 1;
                        controller.nucleusList![neuronIndex].lastSpikeTime = DateTime.now().millisecondsSinceEpoch;
                      }
                      // Skip visual blink trigger during camera animation — keeps pan smooth.
                      if (!controller.isAnimatingCamera) {
                        neuronSpikeFlags[neuronIndex].value = Random().nextInt(10000);
                      }
                      // waveRedraw.value = Random().nextInt(10000);
                  } else {
                      // Continuous firing fix: rhythmic blink for high-frequency neurons.
                      // Skip during camera animation to keep the pan framerate-perfect.
                      if (hasNucleus && !controller.isAnimatingCamera) {
                         int diff = DateTime.now().millisecondsSinceEpoch - controller.nucleusList![neuronIndex].lastSpikeTime;
                         if (diff > 33) { // 30 FPS rhythmic pump
                             controller.nucleusList![neuronIndex].lastSpikeTime = DateTime.now().millisecondsSinceEpoch;
                             // Also fire neuronSpikeFlags so AnimatedBuilder in Nucleus triggers
                             // the TweenAnimationBuilder restart (nucleus color blink).
                             // Previously the 16ms _clockTick handled this implicitly.
                             if (!controller.isAnimatingCamera) {
                                 neuronSpikeFlags[neuronIndex].value = Random().nextInt(10000);
                             }
                         }
                      }
                  }
                } else {
                  if (currentSpikeState != -1) { 
                      if (hasNucleus) {
                        controller.nucleusList![neuronIndex].isSpiking = -1;
                      }
                      neuronSpikeFlags[neuronIndex].value = Random().nextInt(10000);
                      // waveRedraw.value = Random().nextInt(10000);
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
                sendToRobot(lastTwenty.join());
              }
            } else {
              if (isIsolateWritePortInitialized &&
                  isSimulatingBrain &&
                  isPlayingMenu) {
                sendToRobot(commands.join());
              }
            }
            */
          } else {
            if (isCheckingColor) {
              if (isIsolateWritePortInitialized) {
                sendToRobot("c");
              }
            } else if (isIsolateWritePortInitialized && isPlayingMenu) {
              // Zero-command keepalive ONLY FOR MOTORS: continuous rotation servo needs 
              // periodic commands to hold its position. Without this, a brief simulation lull stops the servo.
              // Fix: DO NOT wipe out LEDs (d:0,0,0,0) here; let Native simulation dictate when LEDs turn off to fix visual flicker.
              String keepalive = "l:0;r:0;s:0;a:0;$_lastSentDiodeString";
              String paddedKeepalive = keepalive.padRight(1450, ' ');
              sendToRobot(paddedKeepalive);
            }
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

  }

  // Triggered dynamically from ProcessRobotMessages or ImagePreprocessor
  static void flashSensorSpike(InfiniteCanvasNode sensorNode) {
    if (instance == null || controller.nucleusList == null) return;
    int fromIdx = controller.syntheticNeuronList.indexWhere((e) => e.node.key.toString() == sensorNode.key.toString());
    if (fromIdx >= 0 && fromIdx < controller.nucleusList!.length) {
        controller.nucleusList![fromIdx].isSpiking = 1;
        controller.nucleusList![fromIdx].lastSpikeTime = DateTime.now().millisecondsSinceEpoch;
        instance!.neuronSpikeFlags[fromIdx].value = Random().nextInt(10000);
        instance!.synapseFadeController?.forward(from: 0.0);
    }
  }

  static void flashEdge(String fromId, String toId) {
    if (instance == null) return;
    bool found = false;
    for (var edge in controller.edges) {
        if (edge.from.toString().contains(fromId) && edge.to.toString().contains(toId)) {
            edge.lastSpikeTime = DateTime.now().millisecondsSinceEpoch;
            found = true;
        }
    }
    if (found) {
        instance!.synapseFadeController?.forward(from: 0.0);
    }
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

  bool containRecognition(Recognition r, List<String> modes) {
    if (modes[0] == "Any") return true;

    if (r.maskGrid != null && r.maskWidth != null && r.maskHeight != null) {
      double xStart = 0;
      double xEnd = 0;
      try {
        double p1 = double.parse(modes[1]);
        double p2 = double.parse(modes[2]);
        xStart = p1 < p2 ? p1 : p2;
        xEnd = p1 < p2 ? p2 : p1;
      } catch (_) {
        return true;
      }

      double dx = r.location.width / r.maskWidth!;

      for (int y = 0; y < r.maskHeight!; y++) {
        for (int x = 0; x < r.maskWidth!; x++) {
          if (r.maskGrid![y * r.maskWidth! + x]) {
             double globalPx = r.location.left + (x * dx);
             if (globalPx >= xStart && globalPx <= xEnd) {
                 return true;
             }
          }
        }
      }
      return false;
    }
    return containImage(r.location, modes);
  }

  bool containImage(Rect location, List<String> modes) {
    int p1 = int.parse(modes[1]);
    int p2 = int.parse(modes[2]);
    int xStart = p1 < p2 ? p1 : p2;
    int xEnd = p1 < p2 ? p2 : p1;

    // Check for HORIZONTAL INTERSECTION/OVERLAP
    // Instead of checking if the center is strictly inside, we check if the object's box overlaps the zone.
    // Overlap condition: (Rect.Right > Zone.Left) AND (Rect.Left < Zone.Right)
    
    // "Left", "Right", "Custom" all basically define an X-range [xStart, xEnd].
    // We treat them uniformly here.
    if (modes[0] == "Left" || modes[0] == "Right" || modes[0] == "Custom") {
        if (location.right > xStart && location.left < xEnd) {
            return true;
        } else {
            return false;
        }
    } else if (modes[0] == "Any") {
      // any
      return true;
    }
    return false;
  }

  void updateSyntheticConnection(
      LocalKey from, LocalKey to, double sldSynapticWeight) {
    final lastCreatedEdge = controller.edgeSelected!;
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
  
  // V25: State tracking for edge selection sound
  bool wasSelectingEdge = false;
  InfiniteCanvasEdge? _previousSelectedEdge;

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

    // Brain position uses brainHomeX (orientation-aware, excludes toolbar).
    // brainCenterX = left-edge + half the scaled brain natural width (245 = 490/2).
    double leftBrainPosition = brainHomeX;
    double brainCenterX      = brainHomeX + 245 * scaleMultiplier;
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
        // Brain polygon starts at y=brainDiff.height (55) in the 600x600 local space.
        // Canvas position = localY * scale + brainHomeY, matching peripheral targets.
        top: brainDiff.height * scaleMultiplier + topInnerWindowSpace,
        left: leftBrainPosition,
        // left: ((brainPosition.dx).floor() * scaleMultiplier +
        //     (leftInnerWindowSpace - 137) * scaleMultiplier),
        child: SizedBox(
          width: brainSizeMultiplier.width,
          height: brainSizeMultiplier.height,
          // color: Colors.green,
          child: DragTarget(
              hitTestBehavior: HitTestBehavior.translucent, // pass scroll events through to InteractiveViewer
              
              onMove: (dragDetail) async {
            if (dragDetail.data as int >= 10) return; // Ignore Live Tool Pins for Brain Target
            RenderBox box = context.findRenderObject() as RenderBox;
            Offset localOffset = box.globalToLocal(dragDetail.offset);
            Offset localAreaOffset = controller
                .toLocal(Offset(localOffset.dx, localOffset.dy));

            GeneralSensorPainter painter = (coreBrainPainter);
            Offset containOffset = localAreaOffset.translate(
                -leftBrainPosition + 45 / controller.getScale(),
                -(brainDiff.height * scaleMultiplier + topInnerWindowSpace) +
                    45 / controller.getScale());
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
                if (soloud != null && neuronOnTouchHandle != null) {
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
            if (dragDetail.data is int && (dragDetail.data as int) >= 10) return false;
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
            // CRITICAL FIX: Safer neuronSize update and sync with C++
            // neuronSize++; // Old logic
            // Add neuron first? No, DragTarget adds it via controller logic later or here?
            // This block handles DATA. Controller logic adds visual node separately?
            // Wait. DragTarget adds to `neuronsKey` list.
            // Where is the visual node added?
            // It seems DragTarget handles logic, but controller update happens... where?
            // Let's assume standard flow.
            neuronSize++; // Maintain this for now as it matches existing logic flow
            
            // populateMatrix() will be called at end of this block?
            // No, need to call it explicitly after node is fully added.

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

            // value.offset = feedback widget TL (dragAnchorStrategy returns Offset(45,45),
            // meaning feedback center is under finger).
            RenderBox box = context.findRenderObject() as RenderBox;
            final double half = neuronDrawSize / 2;
            final double canvasScale = controller.getScale();
            
            // Detect FittedBox using the PHYSICAL window size, not
            // MediaQuery.size (which is already inflated by FittedBox's spoofed
            // MediaQuery). View.of(context) gives the real device pixels.
            final ui.FlutterView view = View.of(context);
            final double physicalShortestSide = 
                (view.physicalSize / view.devicePixelRatio).shortestSide;
            final bool isFittedBoxActive = kIsWeb && physicalShortestSide < 600;
            
            // Standard path: globalToLocal converts value.offset to page-local
            // coords, toLocal converts to canvas coords, then add the 45px
            // drag anchor offset.
            Offset localOffset = box.globalToLocal(value.offset);
            Offset feedbackTLScene = controller.toLocal(localOffset);
            
            Offset fingerScene;
            if (isFittedBoxActive) {
              // Under FittedBox (1.33x inflation), the dragAnchorStrategy
              // returns 45px in inflated-local space. Flutter's Draggable
              // converts it to global via localToGlobal (÷1.33 = ~33.8px).
              // But value.offset was computed with the 33.8px global anchor.
              // After globalToLocal (×1.33), we get feedbackTL = finger - 45.
              // The 45 correction then exactly cancels — BUT the FittedBox
              // alignment transform introduces a small additional shift equal
              // to neuronDrawSize/2. Compensate:
              final double dragCorrection = (45.0 + half) / canvasScale;
              fingerScene = feedbackTLScene + Offset(dragCorrection, dragCorrection);
            } else {
              final double dragCorrection = 45.0 / canvasScale;
              fingerScene = feedbackTLScene + Offset(dragCorrection, dragCorrection);
            }

            SyntheticNeuron syntheticNeuron = SyntheticNeuron(
                isActive: false, isIO: false, circleRadius: neuronDrawSize / 2);
            InfiniteCanvasNode newNode = InfiniteCanvasNode(
              label: "Quiet",
              key: neuronsKey[neuronsKey.length - 1],
              value: neuronSize - 1,
              allowMove: false,
              allowResize: false,
              // Center node on finger: feedbackTL + correction = finger, minus half
              offset: Offset(fingerScene.dx - half, fingerScene.dy - half),
              size: Size(neuronDrawSize, neuronDrawSize),
              child: CustomPaint(
                isComplex: !kIsWeb,
                willChange: false,
                painter: syntheticNeuron,
              ),
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

            // CRITICAL FIX: Populate data for new neuron
            neuronSize = controller.nodes.length - allNeuronStartIdx;
            populateMatrix();
            refreshNuclei();

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
            if (soloud != null && neuronOnTouchHandle != null) {
              prevSoundIdx = -2;
              soloud?.stop(neuronOnTouchHandle!);
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
    for (idx = 0; idx < 10; idx++) {
      // for (idx = 0; idx < len - 2; idx++) {
      // if (idx == 7) continue;
      // for (idx = 0; idx < len - 4; idx++) {
      InfiniteCanvasNode neuron = sensoryNeurons[idx];
      Map<String, dynamic> neuronInfo = dropTargetInformations[idx];

      double iosWidthScale = 1.0;
      if (Platform.isIOS || Platform.isAndroid) {
          if (MediaQuery.of(context).size.shortestSide < 600) {
              iosWidthScale = 1 / 1.25; // Reverses the `FittedBox` inflation found in main.dart
          }
      }

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
            size: Size(
              neuronInfo["size"].width * scaleMultiplier,
              neuronInfo["size"].height * scaleMultiplier,
            ),
            // offset: const Offset(0, 0),
            offset: Offset(neuronInfo["left"], neuronInfo["top"]),
            child: Positioned(
              top: neuronInfo["top"] * scaleMultiplier + topInnerWindowSpace,
              left:
                  brainCenterX + neuronInfo["posXDiff"] * scaleMultiplier,
              // top: neuronInfo["top"],
              // left: neuronInfo["left"],
              child: SizedBox(
                width: neuronInfo["size"].width * scaleMultiplier,
                height: neuronInfo["size"].height * scaleMultiplier,
                child: DragTarget(
                    // 45 is a recentered position of Draggable
                    hitTestBehavior: HitTestBehavior.translucent,
                    
                    onMove: (dragDetail) async {
                      if (dragDetail.data as int >= 10) return; // Ignore Live Tool Pins for Peripherals
                          RenderBox box = context.findRenderObject() as RenderBox;
                          Offset localOffset = box.globalToLocal(dragDetail.offset);
                          Offset localAreaOffset = controller.toLocal(
                              Offset(localOffset.dx, localOffset.dy));
                          
                          Offset localOffsetGap = Offset(
                              45 / controller.getScale(),
                              45 / controller.getScale());

                          GeneralSensorPainter painter = (listPainters[tempIdx]);
                          Offset containOffset = localAreaOffset.translate(
                              -(brainCenterX +
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
                              await soloud
                                  ?.play(neuronOnTouchSource!)
                                  .then((handle) {
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
                          if (soloud != null && neuronOnTouchHandle != null) {
                            prevSoundIdx = -2;
                            soloud?.stop(neuronOnTouchHandle!);
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
                        if (dragDetail.data is int && (dragDetail.data as int) >= 10) return false;
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
                          isComplex: !kIsWeb,
                          willChange: !kIsWeb,
                          painter: syntheticNeuron,
                        ),
                        // child: Container(width: 0,height:0, color:Colors.green),
                      );
                      newNode.syntheticNeuron = syntheticNeuron;
                      syntheticNeuron.node = newNode;
                      syntheticNeuron.setupDrawingNeuron();
                      syntheticNeuronList.add(syntheticNeuron);
            mapDelayNeuronList.add(-1);
            mapRhytmicNeuronList.add(-1);
            mapCountingNeuronList.add(-1);

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
                        Future.delayed(const Duration(milliseconds: 100),
                            () async {
                          await soloud?.play(objectPlacedSource!);
                        });
                      }

                      InfiniteCanvasNode nodeFrom = neuron;
                      InfiniteCanvasNode nodeTo = newNode;
                      if ((tempIdx >= 3 && tempIdx <= 9) && tempIdx != 7) {
                        nodeFrom = newNode;
                        nodeTo = neuron;
                      }
                      
                      if (tempIdx == 7) {
                          // Update connection flags immediately
                          Future.delayed(const Duration(milliseconds: 100), () {
                              linkMicrophoneConnection();
                          });
                      }
                      InfiniteCanvasEdge edge = InfiniteCanvasEdge(
                        from: nodeFrom.key,
                        to: nodeTo.key,
                      );

                      // printDebug("nodeTo");
                      // printDebug(nodeTo.id);
                      // printDebug(nodeSingleLed.id);

                      // /*
                      String connectionKey = "${nodeFrom.id}_${nodeTo.id}";
                      String connectionKeyRaw = "${nodeFrom.key}_${nodeTo.key}"; // Robust sync key

                      if (nodeFrom == nodeLeftEyeSensor ||
                          nodeFrom == nodeRightEyeSensor) {
                        edge.label = "Green";
                        mapSensoryNeuron[connectionKey] = 2;
                        // SYNC TO CONTROLLER
                        controller.mapSensoryNeuron[connectionKey] = 2;
                        controller.mapSensoryNeuron[connectionKeyRaw] = 2;
                        controller.mapSensoryNeuron = Map.from(controller.mapSensoryNeuron);
                        
                        linkAreaSizeConnection(
                            selectedCameraPosition: "Left",
                            nodeFrom: nodeFrom,
                            nodeTo: nodeTo);
                      } else if (nodeFrom == nodeDistanceSensor) {
                        // CHANGE because of Chris' workshop
                        print("DISTANCE SENSOR");
                        edge.label = "Short"; // V19: Default Short (Near)
                        mapDistanceNeuron[connectionKey] = 0; // V19: Default Near (0)
                        
                        // SYNC TO CONTROLLER (Non-destructive)
                        controller.mapDistanceNeuron[connectionKey] = 0;
                        controller.mapDistanceNeuron[connectionKeyRaw] = 0;
                        controller.mapDistanceNeuron = Map.from(controller.mapDistanceNeuron);
                        
                        mapDistanceLimitNeuron[connectionKey] =
                            "1_@_8"; // V19: Default Near Range
                      } else if (nodeTo == nodeLeftMotorForwardSensor ||
                          nodeTo == nodeLeftMotorBackwardSensor ||
                          nodeTo == nodeRightMotorForwardSensor ||
                          nodeTo == nodeRightMotorBackwardSensor) {
                        mapContactsNeuron[connectionKey] = 25.0;
                        // SYNC TO CONTROLLER
                        controller.mapContactsNeuron[connectionKey] = 25.0;
                        controller.mapContactsNeuron = Map.from(controller.mapContactsNeuron);

                        edge.connectionStrength = 25.0;
                        edge.label = "25";
                      } else if (nodeTo == nodeSpeakerSensor) {
                        mapSpeakerNeuron[connectionKey] = 440.0;
                        // SYNC TO CONTROLLER
                        controller.mapSpeakerNeuron[connectionKey] = 440.0;
                        controller.mapSpeakerNeuron[connectionKeyRaw] = 440.0;
                        controller.mapSpeakerNeuron = Map.from(controller.mapSpeakerNeuron);
                        
                        edge.label = "440";
                      } else if (nodeTo == nodeMicrophoneSensor) {
                        // isMicrophoneMenu
                        mapMicrophoneNeuron[connectionKey] = 40.0;
                        // SYNC TO CONTROLLER
                        controller.mapMicrophoneNeuron[connectionKey] = 40.0;
                        controller.mapMicrophoneNeuron[connectionKeyRaw] = 40.0;
                        controller.mapMicrophoneNeuron = Map.from(controller.mapMicrophoneNeuron);
                        
                        // } else if (nodeTo == nodeRedLed ||
                        //     nodeTo == nodeGreenLed ||
                        //     nodeTo == nodeBlueLed) {
                      } else if (nodeTo == nodeSingleLed) {
                        // mapLedNeuron["${nodeFrom.id}_${nodeSingleLed.id}"] = 50;
                        mapLedNeuron["${nodeFrom.id}_${nodeRedLed.id}"] = 50;
                        mapLedNeuron["${nodeFrom.id}_${nodeGreenLed.id}"] = 22;
                        mapLedNeuron["${nodeFrom.id}_${nodeBlueLed.id}"] = 13;
                        
                        // SYNC TO CONTROLLER
                        controller.mapLedNeuron["${nodeFrom.id}_${nodeRedLed.id}"] = 50;
                        controller.mapLedNeuron["${nodeFrom.id}_${nodeGreenLed.id}"] = 22;
                        controller.mapLedNeuron["${nodeFrom.id}_${nodeBlueLed.id}"] = 13;
                        controller.mapLedNeuron = Map.from(controller.mapLedNeuron);

                        int redColor =
                            (mapLedNeuron["${nodeFrom.id}_${nodeRedLed.id}"] /
                                    100 *
                                    255)
                                .floor();
                        int greenColor =
                            (mapLedNeuron["${nodeFrom.id}_${nodeGreenLed.id}"] /
                                    100 *
                                    255)
                                .floor();
                        int blueColor =
                            (mapLedNeuron["${nodeFrom.id}_${nodeBlueLed.id}"] /
                                    100 *
                                    255)
                                .floor();
                        // nodeFrom.syntheticNeuron.blackBrush = Paint()
                        //   ..color = Color.fromARGB(255, redColor, greenColor, blueColor)
                        //   // ..color = Colors.yellow
                        //   ..style = PaintingStyle.fill
                        //   ..strokeWidth = 2;
                        // mapLedNeuronPosition["${nodeFrom.id}_${nodeSingleLed.id}"] = "1111";
                        mapLedNeuronPosition[
                            "${nodeFrom.id}_${nodeRedLed.id}"] = "1111";
                        mapLedNeuronPosition[
                            "${nodeFrom.id}_${nodeGreenLed.id}"] = "1111";
                        mapLedNeuronPosition[
                            "${nodeFrom.id}_${nodeBlueLed.id}"] = "1111";
                        edge.connectionStrength = 50;
                        edge.color = const Color(0xFFFD8164).withOpacity(0.50); // BYB orange at 50% brightness
                        edge.isLedEdge = true;

                        // Initialize hex/brightness maps so color widget opens correctly
                        String ledKey = "${nodeFrom.id}_${nodeSingleLed.id}";
                        mapLedHex[ledKey] = "FD8164";
                        mapLedBrightness[ledKey] = "0.50";

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
                      // FIX: direct edges.add() bypasses addLink() which normally sets
                      // syntheticConnectionsDirty=true and calls notifyListeners().
                      // Without these the edge renderer never knows to rebuild, so the
                      // axon is invisible until the next unrelated interaction.
                      controller.syntheticConnectionsDirty = true;
                      controller.notifyListeners();

                      initNativeC(false);

                      // FIX: Re-populate matrix after initNativeC zeroed buffers
                      neuronSize = controller.nodes.length - allNeuronStartIdx;
                      populateMatrix();

                      isBrainTargetOverlayTop = -1;
                      containedIdx = -1;

                      // FINAL SYNC PASS to ensure NativeC didn't wipe state and Renderer catches it
                      String syncKeyRaw = "${nodeFrom.key}_${nodeTo.key}";
                      String syncKeyId = "${nodeFrom.id}_${nodeTo.id}";
                      if (nodeTo == nodeSpeakerSensor) {
                          controller.mapSpeakerNeuron[syncKeyRaw] = 440.0;
                          controller.mapSpeakerNeuron[syncKeyId] = 440.0;
                      } else if (nodeTo == nodeMicrophoneSensor) {
                          controller.mapMicrophoneNeuron[syncKeyRaw] = 40.0;
                          controller.mapMicrophoneNeuron[syncKeyId] = 40.0;
                      } else if (nodeFrom == nodeDistanceSensor) {
                          controller.mapDistanceNeuron[syncKeyRaw] = 0;
                          controller.mapDistanceNeuron[syncKeyId] = 0;
                      } else if (nodeFrom == nodeLeftEyeSensor || nodeFrom == nodeRightEyeSensor) {
                          controller.mapSensoryNeuron[syncKeyRaw] = 2;
                          controller.mapSensoryNeuron[syncKeyId] = 2;
                      }
                      
                      // Force map reference refresh to trigger stateless widget rebuild detection if needed
                      // (Though map content update is usually enough if reference is stable)
                      
                      controller.deselect(neuronsKey[neuronsKey.length - 1]);
                      modeIdx = -1;
                      controller.modeIdx = modeIdx;
                      prevConstrainedPos = Offset.zero;

                      setState(() {});
                      
                      // Future.delayed(const Duration(milliseconds: 100), () {
                      //   controller.deselect(neuronsKey[neuronsKey.length - 1]);
                      //   modeIdx = -1;
                      //   controller.modeIdx = modeIdx;
                      //   prevConstrainedPos = Offset.zero;
                      //   setState(() {});
                      // });
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
                      // if (tempIdx == 7) return Container();

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
                      return CustomPaint(
                        size: Size(
                          neuronInfo["size"].width * scaleMultiplier,
                          neuronInfo["size"].height * scaleMultiplier,
                        ),
                        painter: listPainters[tempIdx],
                      );
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

    // Capture old eye-sensor position BEFORE updating any sensor positions.
    // Used as anchor for proportional neuron rescaling below: 
    //   newPos = newAnchor + (oldPos - oldAnchor) * scaleRatio
    final Offset oldEyeSensorAnchor = nodeLeftEyeSensor.offset;

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

    double minimumSize = initialMinimumSize.height; // = 600 (brain authored in 600×600 space)

    double widthRatio  = currentImageWidth  / minimumSize;
    double heightRatio = currentImageHeight / minimumSize;
    // Capture old scale BEFORE updating so we can compute the neuron rescale ratio
    final double oldScaleMultiplier = scaleMultiplier;
    // Update the global scaleMultiplier NOW so everything below uses the fresh value.
    // Previously, scaleMultiplier was only updated in getDragTargets(), causing:
    //   - brainCanvasCenterX to use the stale value (misaligned sensor positions)
    //   - neuron rescaling condition to be always false (oldScaleMultiplier == scaleMultiplier)
    scaleMultiplier = min(widthRatio, heightRatio);

    // --- Brain Home Position ---
    // All canvas elements (SVG, nodes, drag targets) use centered coordinates.
    // Orientation-aware home position is applied via canvas VIEW TRANSFORM in
    // _animateCanvasToReset (deltaX/deltaY pan), keeping everything aligned.
    brainHomeX = windowWidth  / 2 - 245 * scaleMultiplier;
    brainHomeY = (windowHeight - currentImageHeight) / 2;

    // Keep legacy names in sync for drop-target / hit-test callers
    leftInnerWindowSpace = brainHomeX;
    topInnerWindowSpace  = brainHomeY;


    centerZoneOffset = Offset(currentImageWidth / 2 + neuronDrawSize,
        currentImageHeight / 3 + neuronDrawSize);

    printDebug("widthRatio, heightRatio: $widthRatio, $heightRatio  scale=$scaleMultiplier  brainHomeX=$brainHomeX");
    // 245 is half the brain's natural width (490px authoring space).
    // brainHomeX is the screen-space (= canvas-space at scale=1) left edge of the scaled brain.
    // So brainCanvasCenterX is where the brain center sits in canvas coordinates.
    double brainCanvasCenterX = brainHomeX + 245 * scaleMultiplier - 5;
    Offset centerOffset = Offset(brainCanvasCenterX, brainHomeY + (90 * scaleMultiplier).ceil());

    nodeLeftEyeSensor.offset = centerOffset;

    nodeDistanceSensor.offset = Offset(
        centerOffset.dx - (195 * scaleMultiplier).ceil(),
        brainHomeY + 115 * scaleMultiplier);

    nodeMicrophoneSensor.offset = Offset(
        centerOffset.dx + (210 * scaleMultiplier).ceil(),
        centerOffset.dy + (50 * scaleMultiplier).ceil());

    nodeLeftMotorForwardSensor.offset = Offset(
        centerOffset.dx - (225 * scaleMultiplier).ceil(),
        centerOffset.dy + (165 * scaleMultiplier).ceil());

    nodeLeftMotorBackwardSensor.offset = Offset(
        centerOffset.dx - (238 * scaleMultiplier).ceil(),
        centerOffset.dy + (285 * scaleMultiplier).ceil());

    nodeRightMotorForwardSensor.offset = Offset(
        centerOffset.dx + (216 * scaleMultiplier).ceil(),
        centerOffset.dy + (167 * scaleMultiplier).ceil());

    nodeRightMotorBackwardSensor.offset = Offset(
        centerOffset.dx + (224 * scaleMultiplier).ceil(),
        centerOffset.dy + (287 * scaleMultiplier).ceil());

    nodeSpeakerSensor.offset = Offset(
        centerOffset.dx + (140 * scaleMultiplier).ceil(),
        centerOffset.dy + (406 * scaleMultiplier).ceil());

    nodeRedLed.offset = Offset.zero;
    nodeGreenLed.offset = Offset.zero;
    nodeBlueLed.offset = Offset.zero;

    nodeSingleLed.offset = Offset(
        centerOffset.dx - (150 * scaleMultiplier).ceil(),
        centerOffset.dy + (426 * scaleMultiplier).ceil());

    // Final reposition of distance sensor
    nodeDistanceSensor.offset = Offset(
        centerOffset.dx - (205 * scaleMultiplier).ceil(),
        brainHomeY + 115 * scaleMultiplier);

    // --- Rescale/translate user neurons to track brain center ---
    // Must run when: (a) brain SIZE changed (scaleMultiplier ratio), OR
    //               (b) brain POSITION changed (e.g. X-only resize moves brainHomeX
    //                   without changing scaleMultiplier when height is the limiting dim).
    // Formula: newPos = newAnchor + (oldPos - oldAnchor) * scaleRatio
    //   scaleRatio=1 → pure translation (handles X-only resize case)
    final double scaleRatio = _prevNeuronRescaleScale > 0
        ? scaleMultiplier / _prevNeuronRescaleScale
        : 1.0;
    final Offset translation = centerOffset - oldEyeSensorAnchor;
    if (isInitialized && (translation != Offset.zero || scaleRatio != 1.0)) {
      final int nodeCount = controller.nodes.length;
      for (int i = normalNeuronStartIdx + 2; i < nodeCount; i++) {
        final Offset oldPos = controller.nodes[i].offset;
        // Direct assignment bypasses allowMove=false guard in .update(offset:)
        controller.nodes[i].offset =
            centerOffset + (oldPos - oldEyeSensorAnchor) * scaleRatio;
      }
      _prevNeuronRescaleScale = scaleMultiplier;
      controller.notifyListeners();
    } else if (_prevNeuronRescaleScale == 0.0) {
      _prevNeuronRescaleScale = scaleMultiplier;
    }
  }

  // Helper to update live buffers immediately (simulating real-time parameter change)
  void updateLiveConnectionBuffer(InfiniteCanvasNode nodeFrom, InfiniteCanvasNode nodeTo, double value, String type) {
       // Only run if buffers are initialized and sizes match
       if (neuronContactsBufView.isEmpty) return;
       
       try {
           // Calculate indices based on current controller state
           // Matches populateMatrix logic: node index in controller.nodes - allNeuronStartIdx
           int fromIdx = controller.nodes.indexOf(nodeFrom) - allNeuronStartIdx;
           int toIdx = controller.nodes.indexOf(nodeTo) - allNeuronStartIdx;
           
           if (fromIdx >= 0 && toIdx >= 0 && fromIdx < neuronSize && toIdx < neuronSize) {
               int bufferIdx = fromIdx * neuronSize + toIdx;
               
               // Determine sign (Inhibitory vs Excitatory)
               int sign = 1;
               if (neuronStyles.containsKey(nodeFrom.id) && neuronStyles[nodeFrom.id] == "Inhibitory") {
                   sign = -1;
               }

                if (type == "motor") {
                    neuronContactsBufView[bufferIdx] = (sign * value.abs()).floorToDouble();
                    printDebug("LIVE_DEBUG: Motor Update. Val=$value. indices: From=$fromIdx To=$toIdx. BufferIdx=$bufferIdx. NeuronSize=$neuronSize.");
                } else if (type == "speaker") {
                   neuronSpeakerBufView[bufferIdx] = value.round();
                   printDebug("LIVE UPDATE SPEAKER: bufIdx=$bufferIdx val=$value (from=$fromIdx to=$toIdx)");
               } else if (type == "connectome") {
                   connectomeBufView[bufferIdx] = (sign * value.abs()).floorToDouble();
               } else if (type.contains("led")) {
                   neuronLedBufView[bufferIdx] = value.round();
               }
           } else {
               printDebug("LIVE UPDATE FAILED: Invalid Indices. From: $fromIdx, To: $toIdx, Size: $neuronSize");
           }
       } catch (e) {
           printDebug("Error updating live buffer: $e");
       }
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
        updateLiveConnectionBuffer(nodeFrom, nodeTo, sldSynapticWeightR, "red_led");
      } else if (nodeTo.key == nodeGreenLed.key) {
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
        updateLiveConnectionBuffer(nodeFrom, nodeTo, sldSynapticWeightG, "green_led");
      } else if (nodeTo.key == nodeBlueLed.key) {
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
        updateLiveConnectionBuffer(nodeFrom, nodeTo, sldSynapticWeightB, "blue_led");
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
      if (!isLoadingBrain && !isSettlingAfterLoad) brainHasUnsavedChanges.value = true; // LED property submitted
      linkLedConnection(sldSynapticWeight);

      setState(() {});
    } catch (err) {
      printDebug("err slider tf");
    }
  }

  void submitSynapticConnection(String value) {
    // V23: Synapse connection update
    if (value.trim().isEmpty) return;
    double val = double.tryParse(value) ?? 0;
    if (val > 100) val = 100;
    if (val < 0) val = 0;
    
    sldSynapticWeight = val.roundToDouble();
    tecSynapticWeight.text = val.round().toString();
    
    // Apply to currently selected edge
    if (controller.isSelectingEdge) {
      var edge = controller.edgeSelected!;
      edge.connectionStrength = val;
      edge.label = val.floor().toString();
      
      final neuronFrom = findNeuronByKey(edge.from);
      final neuronTo = findNeuronByKey(edge.to);
      
      if (isSynapseMenu) {
        mapConnectome["${neuronFrom.id}_${neuronTo.id}"] = val;
      } else if (isMotorMenu) {
        mapContactsNeuron["${neuronFrom.id}_${neuronTo.id}"] = val;
        updateLiveConnectionBuffer(neuronFrom, neuronTo, val, "motor");
      }
      
      // Force update of the live buffer for Synapse as well
      if (isSynapseMenu) {
         updateLiveConnectionBuffer(neuronFrom, neuronTo, val, "connectome");
      }
    }
    setState(() {});
  }

  void submitDelayConnection(String value) {
    try {
      if (value.trim() == "") value = "0";
      sldTimeValue = double.parse(value);
      if (sldTimeValue > maxDelayTimeValue) {
        sldTimeValue = maxDelayTimeValue.toDouble();
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
        int neuronIdx = -1;
neuronIdx = controller.nodes.map((e) => e.id).toList().indexOf(selected.id) - 2;
        mapDelayNeuronList[neuronIdx] = sldTimeValue.floor();
        
        // SYNC TO C++ BUFFER (LIVE UPDATE)
        if (neuronIdx < mapDelayNeuronBufView.length) {
            mapDelayNeuronBufView[neuronIdx] = sldTimeValue.floor();
        }
      }
      controller.singleSelection = null;
      if (!isLoadingBrain && !isSettlingAfterLoad) brainHasUnsavedChanges.value = true; // delay time text submitted
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
        if (!isLoadingBrain && !isSettlingAfterLoad) brainHasUnsavedChanges.value = true; // speaker frequency text submitted
        linkSpeakerConnection(sldFrequencyWeight.toString());
      } else if (isMicrophoneMenu) {
        if (!isLoadingBrain && !isSettlingAfterLoad) brainHasUnsavedChanges.value = true; // sensor property changed
        linkMicrophoneConnection();
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
        int neuronIdx = -1;
neuronIdx = controller.nodes.map((e) => e.id).toList().indexOf(selected.id) - 2;
        aDesignArray[selected.id] = sldAWeight;
        aBufView[neuronIdx] = sldAWeight;
      }

      // controller.singleSelection = null;

      if (!isLoadingBrain && !isSettlingAfterLoad) brainHasUnsavedChanges.value = true; // Izhikevich A text submitted
      if (!isLoadingBrain && !isSettlingAfterLoad) brainHasUnsavedChanges.value = true; // Izhikevich B text submitted
      if (!isLoadingBrain && !isSettlingAfterLoad) brainHasUnsavedChanges.value = true; // Izhikevich C text submitted
      if (!isLoadingBrain && !isSettlingAfterLoad) brainHasUnsavedChanges.value = true; // Izhikevich D text submitted
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
        int neuronIdx = -1;
neuronIdx = controller.nodes.map((e) => e.id).toList().indexOf(selected.id) - 2;
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
      if (sldCWeight > -30) {
        sldCWeight = -30;
      }
      if (sldCWeight < -80) {
        sldCWeight = -80;
      }

      sldCWeight = sldCWeight.roundToDouble();
      tecCWeight.text = sldCWeight.round().toString();
      resizeIzhikevichParameters(neuronSize);
      if (controller.singleSelection != null) {
        InfiniteCanvasNode selected = controller.singleSelection!;
        int neuronIdx = -1;
neuronIdx = controller.nodes.map((e) => e.id).toList().indexOf(selected.id) - 2;
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
        int neuronIdx = -1;
neuronIdx = controller.nodes.map((e) => e.id).toList().indexOf(selected.id) - 2;
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
      // V23: Use new widget state instead of old text controllers
      // The _updateLedColor callback already writes to mapLedNeuron, mapLedHex, mapLedBrightness
      // Just ensure the edge color is set correctly before leaving
      try {
        InfiniteCanvasEdge selectedEdge = controller.edgeSelected!;
        InfiniteCanvasNode neuronFrom = findNeuronByKey(selectedEdge.from);
        InfiniteCanvasNode neuronTo = findNeuronByKey(selectedEdge.to);
        String connectionKey = "${neuronFrom.id}_${neuronTo.id}";
        
        // Read from new maps (which were updated by _updateLedColor)
        String hex = mapLedHex[connectionKey] ?? _robotLedHex;
        double brightness = double.tryParse(mapLedBrightness[connectionKey] ?? _robotLedBrightness) ?? 1.0;
        
        Color c = Color(int.parse("0xFF$hex"));
        selectedEdge.color = c.withOpacity(brightness);
        selectedEdge.connectionStrength = brightness * 100.0;
        if (selectedEdge.connectionStrength < 1.0) selectedEdge.connectionStrength = 1.0;
        
        printDebug("setDataOnLeave LED: Hex=$hex, Bri=$brightness");
      } catch (e) {
        printDebug("setDataOnLeave LED error: $e");
      }
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

  // --- Remote Control Methods ---

  String _getKeyName(KeyEvent event) {
    if (event.logicalKey == LogicalKeyboardKey.arrowUp) return "Arrow Up";
    if (event.logicalKey == LogicalKeyboardKey.arrowDown) return "Arrow Down";
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) return "Arrow Left";
    if (event.logicalKey == LogicalKeyboardKey.arrowRight) return "Arrow Right";

    String? label = event.logicalKey.keyLabel;
    
    // Fallback?
    if (label == " ") return "Space";
    
    return label;
  }

  String _getGamepadKeyName(GamepadEvent event) {
    // Axis events always get a direction suffix.
    // Some controllers (especially on iOS) report D-pad as KeyType.button but
    // with key names containing "axis" (e.g. "dpad - xAxis") and values +1/0/-1.
    // Detect these and also give them direction suffixes so left vs right bind distinctly.
    bool isAxisLike = event.type == KeyType.analog ||
        event.key.toLowerCase().contains("axis");

    if (isAxisLike && event.value.abs() > 0.3) {
      String direction = event.value > 0 ? "+" : "-";
      return "Pad:${event.gamepadId}:${event.key}:$direction";
    }
    // Fallback: plain button negative-value directional (e.g. some older MFi controllers)
    if (event.type == KeyType.button && event.value < -0.3) {
      return "Pad:${event.gamepadId}:${event.key}:-";
    }
    return "Pad:${event.gamepadId}:${event.key}";
  }

  void _updateGamepadSubscription() {
    bool needed = _isListeningForRemoteInput || isSimulatingBrain || _isShowInputDebug;
    if (needed) {
      if (_gamepadSubscription == null) {
        _gamepadSubscription = Gamepads.events.listen(_onGamepadEvent);
      }
    } else {
      _gamepadSubscription?.cancel();
      _gamepadSubscription = null;
    }
  }

  /// Builds a single Motion neuron radio option (Tap / Tilt / Motion)
  Widget _buildMotionRadio(String label, String emoji) {
    if (controller.selection.isEmpty) return const SizedBox.shrink();
    String nodeId = controller.selection[0].id;
    String current = mapMotionNeuron[nodeId] ?? "Tap";
    bool isSelected = current == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          mapMotionNeuron[nodeId] = label;
          brainHasUnsavedChanges.value = true;
          // Update canvas label
          controller.selection[0].label = "";
          controller.notifyListeners();
        });
        _rcBindingVersion.value++; // reuse to trigger nucleus repaint
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? colorOrange : Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? colorOrange : Colors.grey[400]!,
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: TextStyle(
              fontSize: 20,
              fontFamily: "NotoEmoji",
              color: isSelected ? Colors.white : Colors.black,
            )),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.white : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleRemoteInputListening() {
    setState(() {
      _isListeningForRemoteInput = !_isListeningForRemoteInput;
    });

    if (_isListeningForRemoteInput) {
      HardwareKeyboard.instance.addHandler(_onRemoteKeyBound);
    } else {
      HardwareKeyboard.instance.removeHandler(_onRemoteKeyBound);
    }
    _updateGamepadSubscription();
  }

  void _onGamepadEvent(GamepadEvent event) {
      // 1. Debug Log
      if (_isShowInputDebug) {
         String typeStr = event.type.toString().split('.').last;
         String info = "Pad:${event.gamepadId} | $typeStr | ${event.key} | val:${event.value}\n";
         setState(() {
            _debugInputLog = info + _debugInputLog;
            if (_debugInputLog.length > 1000) _debugInputLog = _debugInputLog.substring(0, 1000);
         });
      }

      // 2. Binding Logic
      if (_isListeningForRemoteInput) {
          bool isButtonPress = event.type == KeyType.button && event.value.abs() > 0.5;
          // Axis press: analog exceeds threshold
          bool isAxisPress  = event.type == KeyType.analog && (event.value > 0.5 || event.value < -0.5);

          if (isButtonPress) {
               // BUTTON: highest priority — key name already carries direction
               // (e.g. "l.joystick.left" vs "l.joystick.right"). Lock immediately.
               _isListeningForRemoteInput = false;
               String keyName = _getGamepadKeyName(event);
               if (_isShowInputDebug) {
                 setState(() {
                   _debugInputLog = "✅ BOUND(btn): '$keyName'\n" + _debugInputLog;
                 });
               }
               _bindRemoteControlKey(keyName);
          } else if (isAxisPress) {
               // ANALOG: on iOS the xAxis fires with an unsigned positive value for
               // BOTH left and right (absolute magnitude). Defer binding by one
               // event-loop cycle so any directional button events in the same batch
               // can preempt and bind the correct direction-named key instead.
               String keyName = _getGamepadKeyName(event);
               if (_isShowInputDebug) {
                 setState(() {
                   _debugInputLog = "⏳ AXIS-defer: '$keyName' val=${event.value}\n" + _debugInputLog;
                 });
               }
               Future.delayed(Duration.zero, () {
                   if (_isListeningForRemoteInput) {
                       _isListeningForRemoteInput = false;
                       if (_isShowInputDebug) {
                         setState(() {
                           _debugInputLog = "✅ BOUND(axis): '$keyName'\n" + _debugInputLog;
                         });
                       }
                       _bindRemoteControlKey(keyName);
                   }
               });
          }
      }

      // 3. Simulation Logic
      if (isSimulatingBrain) {
            String keyName = _getGamepadKeyName(event); // Includes direction for axis/negative button
            bool isPressed = false;
            
            // Check for press magnitude
            if (event.value.abs() > 0.5) {
                // If it's a directional input (ends with + or -), check direction match
                if (keyName.endsWith("+")) isPressed = event.value > 0.5;
                else if (keyName.endsWith("-")) isPressed = event.value < -0.5;
                else isPressed = true; // Standard button positive press
            }

            // Handle release (value -> 0)
            if (event.value.abs() <= 0.5) {
                 // Always strip any + or - we might have (just in case) to get the true base root
                 String base = keyName.endsWith("+") || keyName.endsWith("-") 
                     ? keyName.substring(0, keyName.length - 2) 
                     : keyName;
                 
                 // When the joystick or button centers (0), completely purge all directional variants
                 _activeRemoteKeys.remove("$base:+");
                 _activeRemoteKeys.remove("$base:-");
                 _activeRemoteKeys.remove(base);
            } else {
                 if (isPressed) {
                     _activeRemoteKeys.add(keyName);
                     // If we instantly slam from +1.0 to -1.0, we skip the 0 release block above.
                     // Ensure the opposite direction is removed from the active keys.
                     if (keyName.endsWith("+")) {
                         _activeRemoteKeys.remove("${keyName.substring(0, keyName.length - 1)}-");
                     } else if (keyName.endsWith("-")) {
                         _activeRemoteKeys.remove("${keyName.substring(0, keyName.length - 1)}+");
                     }
                 } else {
                     _activeRemoteKeys.remove(keyName);
                 }
            }
            _updateRemoteControlNeurons();
      }
  }

  void _bindRemoteControlKey(String keyLabel) {
      InfiniteCanvasNode? selected = controller.selection.isNotEmpty ? controller.selection[0] : null;
      if (selected != null) {
        // IMPORTANT: set synchronously BEFORE setState to prevent rapid overshoot
        // events from calling _bindRemoteControlKey again with the wrong direction
        // (setState only schedules the flag update for the next frame).
        _isListeningForRemoteInput = false;
        if (!isLoadingBrain && !isSettlingAfterLoad) brainHasUnsavedChanges.value = true; // RC key binding changed
        mapRemoteControlNeuron[selected.id] = keyLabel;
        setState(() {
          _remoteControlBoundKeyLabel = keyLabel;
          // Trigger redraw
          selected.label = "🎮 $keyLabel";
          // Immediately notify canvas to repaint RC icon
          controller.notifyListeners();
        });
        // Bump the targeted notifier so the RC icon ListenableBuilder rebuilds
        // without firing on every synapseFade tick.
        _rcBindingVersion.value++;
        
        // Cleanup listeners
        HardwareKeyboard.instance.removeHandler(_onRemoteKeyBound);
        _updateGamepadSubscription();
        
        // Force immediate visual update to show Keycap
        Future.delayed(Duration.zero, () {
           // ensure simulation running logic sees it
           // populateMatrix(); // Maybe needed if key binding affects sim params?
           
           // Ensure UI Rebuild (Nucleus needs notification)
           if (mounted) setState(() {});
        });
      }
  }

  bool _onRemoteKeyBound(KeyEvent event) {
    if (event is KeyDownEvent) {
      if (_isShowInputDebug) {
           String keyName = event.physicalKey.debugName ?? "Unknown";
           int usage = event.physicalKey.usbHidUsage;
           String info = "Key: $keyName | HID: 0x${usage.toRadixString(16)}\n";
           setState(() {
              _debugInputLog = info + _debugInputLog;
              if (_debugInputLog.length > 1000) _debugInputLog = _debugInputLog.substring(0, 1000);
           });
      }

      // Ignore valid-but-generic HID usage 0x70000 (keyboard page, id 0)
      // which iOS generates for some gamepad buttons.
      if (event.physicalKey.usbHidUsage == 0x00070000) return false;

      // Allow binding of any other key (including N64 controller keys which act as keyboard)
      String keyLabel = _getKeyName(event);
      _bindRemoteControlKey(keyLabel);
      return true; // Handled
    }
    return false;
  }

  /// True when at least one Remote Control neuron in the brain has no key binding.
  bool get _hasUnboundRemoteNeurons {
    for (int i = 0; i < neuronSize; i++) {
      if (i + 2 >= controller.nodes.length) continue;
      InfiniteCanvasNode node = controller.nodes[i + 2];
      if (neuronTypes[node.id] == "Remote Control") {
        String? key = mapRemoteControlNeuron[node.id];
        if (key == null || key.isEmpty) return true;
      }
    }
    return false;
  }

  void _updateRemoteControlNeurons() {
     for (int i = 0; i < neuronSize; i++) {
        if (i + 2 >= controller.nodes.length) continue;
        InfiniteCanvasNode node = controller.nodes[i + 2];
        
        String? type = neuronTypes[node.id];
        if (type == "Remote Control") {
            String? boundKey = mapRemoteControlNeuron[node.id];
            if (boundKey != null && boundKey.isNotEmpty) {
                bool isPressed = _activeRemoteKeys.contains(boundKey);
                if (isPressed) {
                    // printDebug("Injecting 50.0 to RC $i ($boundKey)"); 
                    iBufView[i] = 50.0; // Inject current (Increased to 50 for reliability)
                } else {
                    iBufView[i] = 0.0; // Reset
                }
            } else {
                // Unbound RC neuron: driven by on-screen Remote Trigger button
                iBufView[i] = _remoteTriggerPressed ? 50.0 : 0.0;
            }
        }
    }
  }

  /// Injects current into Motion neurons based on live IMU sensor state.
  /// Called every simulation tick from processRobotMessages.
  void _updateMotionNeurons() {
    for (int i = 0; i < neuronSize; i++) {
      if (i + 2 >= controller.nodes.length) continue;
      InfiniteCanvasNode node = controller.nodes[i + 2];
      String? type = neuronTypes[node.id];
      if (type == "Motion") {
        String motionType = mapMotionNeuron[node.id] ?? "Tap";
        bool isTriggered = false;
        if (motionType == "Tap") {
          isTriggered = imuTapActive;
        } else if (motionType == "Tilt") {
          isTriggered = imuTiltActive;
        } else if (motionType == "Motion") {
          isTriggered = imuMotionActive;
        }
        iBufView[i] = isTriggered ? 50.0 : 0.0;
      }
    }
  }

  bool _onSimulationKeyEvent(KeyEvent event) {
    // Ignore generic HID usage 0x70000
    if (event.physicalKey.usbHidUsage == 0x00070000) return false;

    // If user is typing in a text field, let it handle the key.
    // On web/desktop, primaryFocus.context.widget may be a Focus wrapper,
    // not EditableText directly. Check both the widget itself AND ancestors.
    final focusNode = FocusManager.instance.primaryFocus;
    if (focusNode?.context != null) {
      if (focusNode!.context!.widget is EditableText) return false;
      final editableText = focusNode.context!.findAncestorWidgetOfExactType<EditableText>();
      if (editableText != null) return false;
    }

    // If we are NOT running the full simulation, do not aggressively steal keys.
    // This allows local Focus nodes (like the Embedded Plotter) to consume them.
    if (!isSimulatingBrain) return false;
    
    // Debug Log to diagnose why keys fail without debugger
    // printDebug("SimKey: ${_getKeyName(event.physicalKey)}");

    String keyName = _getKeyName(event);
    bool handled = true; // Consume event to prevent MacOS beep
    
    if (event is KeyDownEvent) {
       if (_activeRemoteKeys.add(keyName)) {
           _updateRemoteControlNeurons();
       }
    } else if (event is KeyUpEvent) {
       if (_activeRemoteKeys.remove(keyName)) {
           _updateRemoteControlNeurons();
       }
    }

    return handled;
  }

  void _toggleInputDebug() {
    setState(() {
      _isShowInputDebug = !_isShowInputDebug;
      if (_isShowInputDebug) {
        HardwareKeyboard.instance.addHandler(_onDebugKeyEvent);
      } else {
        HardwareKeyboard.instance.removeHandler(_onDebugKeyEvent);
        _debugInputLog = "Press keys to see details...";
      }
    });
    _updateGamepadSubscription();
    if (_isShowInputDebug) _listGamepads();
  }

  Future<void> _listGamepads() async {
    try {
      final gamepads = await Gamepads.list();
      String info = "Connected Gamepads:\n";
      for (final gp in gamepads) {
        info += "- ID: ${gp.id} | Name: ${gp.name}\n";
      }
      if (gamepads.isEmpty) info += "None found.\n";
      info += "--------------------------------\n";
      
      setState(() {
         _debugInputLog = info + _debugInputLog;
      });
    } catch (e) {
      setState(() {
         _debugInputLog = "Error listing gamepads: $e\n$_debugInputLog";
      });
    }
  }

  bool _onDebugKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent || event is KeyRepeatEvent) {
      String info = "Event: ${event.runtimeType}\n"
          "Logic: ${event.logicalKey.keyLabel} (ID: ${event.logicalKey.keyId})\n"
          "Phys: ${event.physicalKey.debugName} (ID: 0x${event.physicalKey.usbHidUsage.toRadixString(16)})\n"
          "Char: ${event.character}\n"
          "--------------------------------\n";
      setState(() {
        _debugInputLog = info + _debugInputLog;
        if (_debugInputLog.length > 1000) {
            _debugInputLog = _debugInputLog.substring(0, 1000);
        }
      });
    }
    return false; // Don't consume
  }


  String capitalize(str) {
    return "${str[0].toUpperCase()}${str.substring(1).toLowerCase()}";
  }

  Future<void> subscribeGeneralConfig() async {
    // printDebug("subscribeGeneralConfig");

    // configListener = FirebaseFirestore.instance
    //     .doc("config/general")
    //     .snapshots()
    //     .listen((event) async {
      /* Map<String, dynamic>? data = event.data();
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
    }); */
  }

  int zoneWidth = 500;
  int zoneHeight = 150;

  UniqueKey formHexColorKey = UniqueKey();
  String strFileVersion = "1.0.1";

  // ── Sound sources & handles (dynamic: AudioSource on native, WebAudioSource on web) ──
  dynamic neuronOnTouchSource;
  dynamic neuronSpikesSource;
  dynamic axonStretchSource;
  dynamic objectPlacedSource;
  dynamic buttonOnPressedSource;
  dynamic buttonPopSource;
  dynamic eraseSource;
  dynamic pageFlipSource;

  dynamic neuronOnTouchHandle;
  dynamic neuronSpikesHandle;
  dynamic axonStretchHandle;
  dynamic objectPlacedHandle;
  dynamic buttonOnPressedHandle;
  dynamic buttonPopHandle;
  dynamic eraseHandle;
  dynamic pageFlipHandle;

  AppAudio? soloud;

  int prevSoundIdx = -2;

  bool isDraggingTail = false;

  bool isMovingNodeFirstTime = true;
  
  int hoveringPinNeuronIdx = -1;
  Map<int, int> placedPins = {};
  ValueNotifier<int> hoveringValidNeuronNotifier = ValueNotifier<int>(-1);

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
          // X bounds: use brainHomeX (left edge) and brainHomeX + scaled brain width (right edge).
          // Previously used brainPosition.dx (static 190px authoring value) which is wrong
          // in portrait/different-size windows where brainHomeX is the true screen-space left edge.
          final double brainLeft  = brainHomeX;
          final double brainRight = brainHomeX + brainSize.width * scaleMultiplier;
          if (emptyArea.dx < brainLeft) {
            emptyArea = Offset(brainLeft + neuronDrawSize, emptyArea.dy);
          }
          if (emptyArea.dy <
              brainPosition.dy * scaleMultiplier + topInnerWindowSpace) {
            emptyArea = Offset(emptyArea.dx, brainPosition.dy + neuronDrawSize);
          }

          if (emptyArea.dx > brainRight) {
            emptyArea = Offset(brainRight - neuronDrawSize, emptyArea.dy);
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

  Widget generateTargetWidgets(Map<String, dynamic> mapDistanceInfo, int idx, {bool isFloatingMarker = false}) {
    String distanceLabel = mapDistanceInfo["label"] ?? "";
    String distanceIcon = mapDistanceInfo["icon"] ?? "";
    Widget targetIcon;
    if (distanceIcon == "Red") {
      targetIcon = Container(
        margin: const EdgeInsets.all(15),
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xFFFF4444), // Standardized Red
        ),
      );
    } else if (distanceIcon == "Green") {
      targetIcon = Container(
        margin: const EdgeInsets.all(15),
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xFF55EE55), // Standardized Green
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
          buttonOnPressedHandle =
              await soloud?.play(buttonOnPressedSource!, looping: false);
        }
      },
      onTapUp: (details) async {
        if (buttonPopSource != null) {
          buttonOnPressedHandle =
              await soloud?.play(buttonPopSource!, looping: false);
        }

        isSelectingCameraTarget = !isSelectingCameraTarget;
        selectedEyeInfo["icon"] = mapDistanceInfo["icon"];
        selectedEyeInfo["label"] = mapDistanceInfo["label"];
        selectedEyeInfo["idx"] = idx.toString();

        cameraMenuType =
            (mapDistanceInfo["label"] as String).replaceAll("Color ", "");
        printDebug("isSelectingCameraTarget");
        printDebug(cameraMenuType);
        linkSensoryConnection(cameraMenuType);
        setState(() {});
      },
      child: SizedBox(
        width: 110, // V9: Wider
        height: 100,
        child: Stack(
          clipBehavior: Clip.none, // V9: Allow overflow
          children: [
            Align(
                alignment: Alignment.topCenter, // V9: Perfect Centering
                child: Container(
                  width: 70,
                  height: 70,
                  margin: const EdgeInsets.only(top: 0), // Remove left margin
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    color:
                        (!isFloatingMarker && selectedEyeInfo["label"] == mapDistanceInfo["label"]) // V16: Corret selection logic
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
                right: 0,
                top: 62, // V10: 8px Overlap
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: 80),
                    child: Card(
                      // margin: const EdgeInsets.all(10),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                        child: Text(
                          distanceLabel,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                      ),
                  )))
                )
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
        behavior: HitTestBehavior.opaque, // Force touches to register on the entire 80x100 transparent layout box naturally!
        onTapDown: (details) async {
          if (buttonOnPressedSource != null) {
            try {
              buttonOnPressedHandle =
                  await soloud?.play(buttonOnPressedSource!, looping: false);
            } catch (err) {}
          }
        },
        onTapUp: (details) async {
          if (buttonPopSource != null) {
            try {
              buttonPopHandle =
                  await soloud?.play(buttonPopSource!, looping: false);
            } catch (err) {
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
          if (!isLoadingBrain && !isSettlingAfterLoad) brainHasUnsavedChanges.value = true; // distance zone changed
          linkDistanceConnection(distanceMenuType);
          setState(() {});
        },
        child: SizedBox(
          width: 80, // V12: Compact Width 80
          height: 100,
          child: Stack(
            clipBehavior: Clip.none, // V9: Allow overflow
            children: [
              Align(
                  alignment: Alignment.topCenter, // V9: Perfect Centering
                  child: Container(
                    width: 60, // V12: Compact Icon 60
                    height: 60,
                    margin: const EdgeInsets.only(top: 0), // Remove left margin
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
                        textScaleFactor: 1.0, // V20: Lock OS Accessibility Scale
                        style: const TextStyle(
                          fontSize: 38, // V12: Scaled Font
                          fontFamily: "NotoEmoji",
                        ),
                      ),
                    ),
                ),
              Positioned(
                  left: 0,
                  right: 0,
                  top: 52, // V12: 8px Overlap on 60px circle
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minWidth: 80),
                      child: Card(
                        // margin: const EdgeInsets.all(10),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                          child: Text(
                            distanceLabel,
                            textAlign: TextAlign.center,
                            textScaleFactor: 1.0, // V20: Lock OS Accessibility Scale
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
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
    double areaWidth = 80; // V23: Updated to 80 (50% of 160 scale) for split view
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
      // macOS / web / other desktop: use real screen dimensions, not a hardcoded 870×600.
      // initialMinimumSize stays Size(600,600) — the natural brain authoring space.
      // initialWindowWidth/Height are only used for gap math.
      initialWindowWidth  = MediaQuery.of(context).size.width;
      initialWindowHeight = MediaQuery.of(context).size.height;

      double minimumSize = min(600.0, 600.0); // brain authored at 600×600
      initialMinimumSize = Size(minimumSize, minimumSize);
      viewPortNode.update(offset: Offset(screenWidth, screenHeight));
      if (prevInitialFrameGapWidth != null) {
        prevInitialFrameGapWidth  = initialFrameGapWidth;
        prevInitialFrameGapHeight = initialFrameGapHeight;
      }
      initialFrameGapWidth  = initialWindowWidth  - initialMinimumSize.width;
      initialFrameGapHeight = initialWindowHeight - initialMinimumSize.height;
      if (prevInitialFrameGapWidth == null) {
        prevInitialFrameGapWidth  = initialFrameGapWidth;
        prevInitialFrameGapHeight = initialFrameGapHeight;
      }

      currentFrameGapWidth  = initialFrameGapWidth;
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
    
    // The core brain scales to fit the shortest side of the screen (1:1 ratio)
    // To prevent neurons from spilling out of the brain in portrait, we limit max bounds to the brain area.
    double brainDisplaySize = min(cWindowWidth, cWindowHeight);

    for (var v in nodesJson) {
      if (v["index"] == 1) {
        List<Offset> oldDifCamera = [];
        Offset oldCameraNodePos =
            Offset(v["position"][0].toDouble(), v["position"][1].toDouble());
        print("Window X Height : $cWindowWidth $cWindowHeight | PREVIOUS : $displayWidth $displayHeight | OFFSET: ${v["position"][0]} ${v["position"][1]}");

        int start = normalNeuronStartIdx + 2;
        int len = controller.nodes.length;
        // Anchor: use the BRAIN CENTER for X (windowWidth/2), eye-sensor Y for vertical.
        // The eye sensor X = windowWidth/2 - 5, which moves with window width, NOT brain scale.
        // Using it as X anchor would contaminate the scale calculation.
        Offset oldBrainCenter = Offset(displayWidth / 2.0, oldCameraNodePos.dy);
        Offset newBrainCenter = Offset(cWindowWidth / 2.0, nodeLeftEyeSensor.offset.dy);

        // --- Correct uniform scale formula ---
        // Brain scale at save time: S_old = min(savedW, savedH) / 600
        // Brain scale right now:    S_new = currentImageHeight / 600
        //   (currentImageHeight comes from applyBoxFit(BoxFit.contain, 600×600, screenSize))
        // uniformScale = S_new / S_old = currentImageHeight / min(savedW, savedH)
        //
        // NOTE: The camera node's X position tracks windowWidth/2 (not brain scale),
        // so deriving scale from camera-node ratios is incorrect — Y ratio alone would
        // work but the dimension-ratio formula is more robust and simpler.
        double savedMinDimension = max(1.0, min(displayWidth, displayHeight));
        double uniformScale = currentImageHeight / savedMinDimension;

        print("LOAD SCALE: $uniformScale  old=$oldBrainCenter  new=$newBrainCenter");

        oldDifCamera.clear();
        for (int i = start; i < len; i++) {
          // Scale relative to brain center (not eye sensor, which drifts with window width)
          oldDifCamera.add((controller.nodes[i].offset - oldBrainCenter)
              .scale(uniformScale, uniformScale));
        }

        for (int i = start; i < len; i++) {
          int idx = i - start;
          Offset diff = newBrainCenter + oldDifCamera[idx];
          controller.nodes[i].offset = Offset(diff.dx, diff.dy);
        }
        print('silentReposition: ${len - start} nodes, scale=$uniformScale, oldCenter=$oldBrainCenter, newCenter=$newBrainCenter error=${newBrainCenter - oldBrainCenter}');

        break;
      }
    }

    nodeRedLed.offset = Offset.zero;
    nodeGreenLed.offset = Offset.zero;
    nodeBlueLed.offset = Offset.zero;
    prevScreenWidth = displayWidth;
    prevScreenHeight = displayHeight;
  }

  /// Rebuilds protoNeuron.circles and Nucleus widgets from current node state.
  /// Call after neuron creation or any change that requires Nucleus widget refresh.
  void refreshNuclei() {
    // Ensure protoNeuron exists (it's 'late' and only created on first Play or brain load)
    try {
      // ignore: unnecessary_null_comparison
      if (protoNeuron == null) {
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
          connectomeBufView: connectomeBufView,
        );
      }
    } catch (e) {
      // late variable not initialized — create it now
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
        connectomeBufView: connectomeBufView,
      );
    }

    List<Offset> fullPos = [];
    for (InfiniteCanvasNode node in controller.nodes) {
        fullPos.add(node.offset);
    }
    setCirclesZoom(controller.scale, fullPos);
    initializeNucleus();
  }

  void initializeNucleus() {
    printDebug("Initialize Nucleus");
    if (controller.nucleusList != null) {
      controller.nucleusList!.clear();
    } else {
      controller.nucleusList = [];
    }
    
    // Safety check for controller nodes
    if (controller.nodes.isEmpty) return;

    // Safe check for protoNeuron: it's a nullable class field that can't be
    // promoted by null-checks in Dart < 3.2 (field promotion unavailable).
    // Capture into a local variable so the null-check promotes correctly.
    int circleLen = 0;
    final pn = protoNeuron; // local capture for null promotion
    if (pn != null) {
      circleLen = pn.circles.length;
    }
    
    printDebug("initializeNucleus START. Node Count: ${controller.nodes.length} Proto Circles: $circleLen maxUserNodes: ${controller.nodes.length - allNeuronStartIdx}");
    
    controller.nucleusList = [];

    // We use allNeuronStartIdx (2) because ProtoNeuron includes Motors/Peripherals, not just User Neurons (13).
    int maxUserNodes = controller.nodes.length - allNeuronStartIdx; 
    
    // FIX: ALWAYS iterate over ALL user nodes, not just protoNeuron.circles.length.
    // protoNeuron.circles may be empty (before first Play), or may have fewer entries
    // than actual user nodes (brain loaded with more neurons than initial neuronSize).
    // The loop body uses circles[i] data when available (for nucleus position/spike
    // state) and falls back to node.offset + defaults otherwise.
    // This ensures RC keycaps and Delay emojis render for ALL neurons from the start.
    circleLen = maxUserNodes;

    // Safety: ensure neuronSpikeFlags and neuronCircleKeys are large enough
    while (neuronSpikeFlags.length < circleLen) {
      neuronSpikeFlags.add(ValueNotifier(0));
    }
    while (neuronCircleKeys.length < circleLen) {
      neuronCircleKeys.add(GlobalKey(debugLabel: "neuronWidget${neuronCircleKeys.length}"));
    }

    for (int i = 0; i < circleLen; i++) {
        // Safety Break
        // Use allNeuronStartIdx (2) to match ProtoNeuron structure.
        int nodeIdx = i + allNeuronStartIdx; 
        if (nodeIdx >= controller.nodes.length) break;

      // Safe access: use circles[i] if available, otherwise use defaults
      SingleNeuron? neuron;
      if (pn != null && i < pn.circles.length) {
        neuron = pn.circles[i];
      }
      
      // Scaling Logic (Pinned / Hover)
      double scale = 1.0;
      if (hoveringPinNeuronIdx == i) {
         if (!placedPins.containsKey(i)) {
             scale = 1.65; 
         }
      }
      
      if (scale > 1.0) {
          printDebug("Applying Scale $scale to $i");
      }
      
      // Update Node Body Helper (Only for User Neurons, not Peripherals)
      // This prevents "Full Neurons" appearing on Motors/Sensors
      // CRITICAL FIX: Also prevent "Pile of Neurons" at (0,0) by checking Offset.zero
      // If a User Node is at (0,0), it's a Ghost/Shadow node and should NOT be rendered.
      bool isGhostNode = (nodeIdx >= normalNeuronStartIdx && controller.nodes[nodeIdx].offset == Offset.zero);
      
      if (nodeIdx >= normalNeuronStartIdx && !isGhostNode) { 
        if (nodeIdx < controller.nodes.length) {
          try {
            var node = controller.nodes[nodeIdx];
            node.child = Transform.scale(
              scale: scale,
              child: CustomPaint(
                isComplex: !kIsWeb,
                willChange: false,
                painter: node.syntheticNeuron,
              ),
            );
          } catch (e) {}
        }
      }

      // Restore Nucleus Offset
      // Use controller node offset for stable position (Fixes Stray Nuclei if Proto is desynced)
      InfiniteCanvasNode n = controller.nodes[nodeIdx];
      Offset nucleusPos = n.offset;
      
      // Clear label for RC and Delay
      String type = neuronTypes[n.id] ?? "";
      if (type == "Remote Control" || type == "Delay" || type == "Motion" || type == "Aux Motor") {
          n.label = "";
      }

      double xN = neuronDrawSize / 2;
      double yN = neuronDrawSize / 2;
      double wN = neuronDrawSize / 3;
      double hN = neuronDrawSize / 3;
      int isExc = 1;

      if (i < controller.syntheticNeuronList.length) {
         var sn = controller.syntheticNeuronList[i];
         isExc = sn.node?.isExcitatory ?? 1;
         xN = sn.newNeuron.xNucleus;
         yN = sn.newNeuron.yNucleus;
         wN = sn.newNeuron.widthNucleus;
         hN = sn.newNeuron.heightNucleus;
      } else {
         // Fallback: syntheticNeuronList not populated yet (before first Play).
         // Use neuronStyles map (populated during brain load) to get excitatory state.
         isExc = (neuronStyles[n.id] == "Inhibitory") ? 0 : 1;
      }

      Color activeC = (isExc == 1) ? const Color(0xFF00FF00) : Colors.red;
      Color inactiveC = (isExc == 1) ? Colors.white : Colors.black;
      
      // Fix: Peripherals (Sensors/Motors) should NOT have a visible Nucleus overlay.
      // User reported "Blinking on Inputs/Outputs" and "Pile of Neurons" as bugs.
      // We set BOTH colors to Transparent to hide them completely while maintaining the Index Mapping.
      // PLUS: Hide any User Node that is at (0,0) (Ghost/Shadow Nodes) to fix the "Pile".
      if (nodeIdx < normalNeuronStartIdx || n.offset == Offset.zero) {
          activeC = Colors.transparent;
          inactiveC = Colors.transparent;
      }
      
      // Both design and live mode use white as the resting color → consistent green→white blink
      // (previously design mode overrode to transparent, making the fade look different)

      // Regular neurons use the repaint-only fast path (circleParams).
      // RC/Delay types need widget trees and use childBuilder fallback.
      bool useRepaintPath = (type != "Remote Control" && type != "Delay" && type != "Motion" && type != "Aux Motor"
          && nodeIdx >= normalNeuronStartIdx && n.offset != Offset.zero);

      Nucleus nucleus = Nucleus(
        flagIndex: i, 
        nodeKey: n.key, 
        isSpiking: neuron?.isSpiking ?? -1,
        activeColor: activeC,
        inactiveColor: inactiveC,
        controller: controller,
        circleParams: useRepaintPath ? NucleusCircleParams(
          isExcitatory: isExc,
          circleRadius: neuronDrawSize / 2,
          xNucleus: xN, yNucleus: yN,
          widthNucleus: wN, heightNucleus: hN,
        ) : null,
        childBuilder: (ctx, color, node) {
             String currentType = neuronTypes[node.id] ?? "";
             
             bool isSelected = false;
             if (!isSimulatingBrain && controller.selection.isNotEmpty) {
                 isSelected = controller.selection.any((n) => n.id == node.id);
             }
             double selectionScale = isSelected ? 1.5 : 1.0; 
                 
             if (currentType == "Remote Control") {
                 double rcSize = (neuronDrawSize * 0.9) * selectionScale;
                 double containerSize = neuronDrawSize * 0.9 * selectionScale;
                 
                 // ValueListenableBuilder fires only when _rcBindingVersion changes
                 // (i.e. when a binding is accepted), NOT on every controller.notifyListeners()
                 // call — avoiding 60fps rebuilds during the synapseFade animation.
                 return ValueListenableBuilder<int>(
                     valueListenable: _rcBindingVersion,
                     builder: (ctx, _, __) {
                         String boundKey = mapRemoteControlNeuron[node.id] ?? "";
                         return Center(
                             child: Stack(
                                 alignment: Alignment.center,
                                 children: [
                                     Container(
                                         width: containerSize,
                                         height: containerSize,
                                         decoration: BoxDecoration(
                                             color: (isExc == 1) ? Colors.black : Colors.white,
                                             shape: BoxShape.circle,
                                         ),
                                     ),
                                     RemoteControlKeycap(
                                        node: node, 
                                        fallbackKeyName: boundKey, 
                                        isExcitatory: isExc == 1, 
                                        size: rcSize, 
                                        transparentBackground: true,
                                        overrideColor: color ?? ((isExc == 1) ? Colors.white : Colors.black), 
                                        remoteControlMap: mapRemoteControlNeuron,
                                     ),
                                 ]
                             )
                         );
                     },
                 );
             } else if (currentType == "Delay") {
                // Base sizes (without selection scale) — Transform.scale handles selection uniformly
                double circleSize = neuronDrawSize * 0.9;
                double emojiDisplaySize = neuronDrawSize * ((isExc == 1) ? 1.25 : 1.45);
                Color baseTextColor = (isExc == 1) ? Colors.white : Colors.black;
                Color textColor = color ?? baseTextColor;

                // 25 clock emojis mapped 1:1 to 100ms steps (100-2500ms)
                // 100ms=12:30, 200ms=1:00, ... 2400ms=12:00, 2500ms wraps to 12:30
                const List<String> clockEmojis = [
                    "🕧", // 100ms  = 12:30
                    "🕐", // 200ms  = 1:00
                    "🕜", // 300ms  = 1:30
                    "🕑", // 400ms  = 2:00
                    "🕝", // 500ms  = 2:30
                    "🕒", // 600ms  = 3:00
                    "🕞", // 700ms  = 3:30
                    "🕓", // 800ms  = 4:00
                    "🕟", // 900ms  = 4:30
                    "🕔", // 1000ms = 5:00
                    "🕠", // 1100ms = 5:30
                    "🕕", // 1200ms = 6:00
                    "🕡", // 1300ms = 6:30
                    "🕖", // 1400ms = 7:00
                    "🕢", // 1500ms = 7:30
                    "🕗", // 1600ms = 8:00
                    "🕣", // 1700ms = 8:30
                    "🕘", // 1800ms = 9:00
                    "🕤", // 1900ms = 9:30
                    "🕙", // 2000ms = 10:00
                    "🕥", // 2100ms = 10:30
                    "🕚", // 2200ms = 11:00
                    "🕦", // 2300ms = 11:30
                    "🕛", // 2400ms = 12:00
                    "🕧", // 2500ms = 12:30 (wraps)
                ];
                int delayNodeIdx = -1;
                for (int i = 0; i < syntheticNeuronList.length; i++) {
                  if (syntheticNeuronList[i].node?.id == node.id) {
                    delayNodeIdx = i;
                    break;
                  }
                }
                int delayMs = (delayNodeIdx >= 0 && delayNodeIdx < mapDelayNeuronList.length)
                    ? mapDelayNeuronList[delayNodeIdx] : 100;
                if (delayMs < 100) delayMs = 100;
                int clockIdx = ((delayMs - 100) ~/ 100).clamp(0, 24);
                String clockEmoji = clockEmojis[clockIdx];

                double overflowMax = emojiDisplaySize > circleSize ? emojiDisplaySize : circleSize;

                return SizedBox(
                   width: neuronDrawSize,
                   height: neuronDrawSize,
                   child: OverflowBox(
                       maxWidth: overflowMax * selectionScale,
                       maxHeight: overflowMax * selectionScale,
                       alignment: Alignment.center,
                       child: Transform.scale(
                           scale: selectionScale,
                           child: Stack(
                               alignment: Alignment.center,
                               children: [
                                   Container(
                                       width: circleSize,
                                       height: circleSize,
                                       decoration: BoxDecoration(
                                           color: (isExc == 1) ? Colors.black : Colors.white,
                                           shape: BoxShape.circle,
                                       ),
                                   ),
                                   SizedBox(
                                       width: emojiDisplaySize,
                                       height: emojiDisplaySize,
                                       child: FittedBox(
                                           fit: BoxFit.contain,
                                           child: Text(
                                               clockEmoji,
                                               textAlign: TextAlign.center,
                                               style: TextStyle(
                                                   fontFamily: "NotoEmoji",
                                                   color: color ?? ((isExc == 1) ? Colors.white : Colors.black),
                                               ),
                                           ),
                                       ),
                                   ),
                               ],
                           ),
                       ),
                   ),
                );
             } else if (currentType == "Motion") {
                 double circleSize = neuronDrawSize * 0.9;
                 double emojiDisplaySize = neuronDrawSize * ((isExc == 1) ? 1.25 : 1.45);
                 Color baseTextColor = (isExc == 1) ? Colors.white : Colors.black;
                 double overflowMax = emojiDisplaySize > circleSize ? emojiDisplaySize : circleSize;
                 
                 // Use ValueListenableBuilder so nucleus repaints when radio selection changes
                 return ValueListenableBuilder<int>(
                     valueListenable: _rcBindingVersion,
                     builder: (ctx, _, __) {
                         String motionType = mapMotionNeuron[node.id] ?? "Tap";
                         String emoji;
                         switch (motionType) {
                           case "Tilt": emoji = "📐"; break;
                           case "Motion": emoji = "🏃"; break;
                           default: emoji = "👆"; break; // Tap
                         }
                         return SizedBox(
                            width: neuronDrawSize,
                            height: neuronDrawSize,
                            child: OverflowBox(
                                maxWidth: overflowMax * selectionScale,
                                maxHeight: overflowMax * selectionScale,
                                alignment: Alignment.center,
                                child: Transform.scale(
                                    scale: selectionScale,
                                    child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                            Container(
                                                width: circleSize,
                                                height: circleSize,
                                                decoration: BoxDecoration(
                                                    color: (isExc == 1) ? Colors.black : Colors.white,
                                                    shape: BoxShape.circle,
                                                ),
                                            ),
                                            SizedBox(
                                                width: emojiDisplaySize,
                                                height: emojiDisplaySize,
                                                child: FittedBox(
                                                    fit: BoxFit.contain,
                                                    child: Text(
                                                        emoji,
                                                        textAlign: TextAlign.center,
                                                        style: TextStyle(
                                                            fontFamily: "NotoEmoji",
                                                            color: color ?? baseTextColor,
                                                        ),
                                                    ),
                                                ),
                                            ),
                                        ],
                                    ),
                                ),
                            ),
                         );
                     },
                 );
              } else if (currentType == "Aux Motor") {
                 double circleSize = neuronDrawSize * 0.9;
                 double emojiDisplaySize = neuronDrawSize * ((isExc == 1) ? 1.25 : 1.45);
                 Color baseTextColor = (isExc == 1) ? Colors.white : Colors.black;
                 String emoji = "⚙️";
                 double overflowMax = emojiDisplaySize > circleSize ? emojiDisplaySize : circleSize;
                 
                 return SizedBox(
                    width: neuronDrawSize,
                    height: neuronDrawSize,
                    child: OverflowBox(
                        maxWidth: overflowMax * selectionScale,
                        maxHeight: overflowMax * selectionScale,
                        alignment: Alignment.center,
                        child: Transform.scale(
                            scale: selectionScale,
                            child: Stack(
                                alignment: Alignment.center,
                                children: [
                                    Container(
                                        width: circleSize,
                                        height: circleSize,
                                        decoration: BoxDecoration(
                                            color: (isExc == 1) ? Colors.black : Colors.white,
                                            shape: BoxShape.circle,
                                        ),
                                    ),
                                    SizedBox(
                                        width: emojiDisplaySize,
                                        height: emojiDisplaySize,
                                        child: FittedBox(
                                            fit: BoxFit.contain,
                                            child: Text(
                                                emoji,
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                    fontFamily: "NotoEmoji",
                                                    color: color ?? baseTextColor,
                                                ),
                                            ),
                                        ),
                                    ),
                                ],
                            ),
                        ),
                    ),
                 );
             }

            return Transform.scale(
                scale: selectionScale,
                child: CustomPaint(
                    painter: SingleCircle(
                         isActive: true, 
                         isExcitatory: isExc,
                         circleRadius: neuronDrawSize / 2, 
                         xNucleus: xN,
                         yNucleus: yN,
                         widthNucleus: wN,
                         heightNucleus: hN,
                         overrideColor: color
                    ),
                    willChange: false,
                ),
            );
        },
        neuronSpikeFlags: neuronSpikeFlags,
        centerPos: nucleusPos,
        circleKey: neuronCircleKeys[i],
        size: neuronDrawSize,
        scale: scale,
      );
      
      controller.nucleusList!.add(nucleus);
    }
    // printDebug("circleLen");
    // printDebug(circleLen);
    // printDebug(neuronSpikeFlags.length);
    // printDebug(neuronCircleKeys.length);
    // printDebug(controller.nucleusList!.length);
    // printDebug("---------------");
    
    // Force update of InfiniteCanvas to render Nuclei immediately
    // Force update of InfiniteCanvas to render Nuclei immediately
    // usage: Safe notify
    Future.delayed(Duration.zero, () {
       try {
          controller.notifyListeners();
          if (mounted) setState(() {});
       } catch(e) {}
    });
    // WEB FIX: CanvasKit may defer custom font rendering (NotoEmoji) on the
    // first frame, causing RC/Delay icons to be invisible until a repaint.
    // A second delayed rebuild after 500ms ensures icons appear after font load.
    if (kIsWeb) {
      Future.delayed(const Duration(milliseconds: 500), () {
        try {
          if (mounted) {
            controller.notifyListeners();
            setState(() {});
          }
        } catch(e) {}
      });
    }
  }

  void fillCreatedAxon(LocalKey nodeFrom, LocalKey nodeTo) {
    if (isLoadingBrain) return; // Do not overwrite map during brain loading!
    
    if (controller.edges.isNotEmpty) {
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

      InfiniteCanvasNode neuronFrom = findNeuronByKey(lastCreatedEdge.from);
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
          // ROBUST SYNC: Add both ID-based and Key-based entries to controller
          String keyId = "${neuronFrom.id}_${neuronTo.id}";
          String keyRaw = "${neuronFrom.key}_${neuronTo.key}";
          controller.mapSensoryNeuron[keyId] = 2;
          controller.mapSensoryNeuron[keyRaw] = 2;
          // controller.mapSensoryNeuron = Map.from(mapSensoryNeuron); // Redundant if we set keys directly above, but keeps local map sync
          controller.mapSensoryNeuron = Map.from(controller.mapSensoryNeuron); // Force refresh
          lastCreatedEdge.label = "Green";
          linkAreaSizeConnection(
              selectedCameraPosition: "Left",
              nodeFrom: neuronFrom,
              nodeTo: neuronTo);
        } else if (neuronFrom == nodeDistanceSensor) {
          isConnected = false;
          lastCreatedEdge.label = "Short"; // V18: Default to Short
          mapDistanceNeuron["${neuronFrom.id}_${neuronTo.id}"] = 0; // V18: Default Near (0)
          String keyId = "${neuronFrom.id}_${neuronTo.id}";
          String keyRaw = "${neuronFrom.key}_${neuronTo.key}";
          controller.mapDistanceNeuron[keyId] = 0;
          controller.mapDistanceNeuron[keyRaw] = 0;
          controller.mapDistanceNeuron = Map.from(controller.mapDistanceNeuron); // Force refresh
          controller.mapDistanceNeuron = mapDistanceNeuron; // SYNC TO CONTROLLER
          mapDistanceLimitNeuron["${neuronFrom.id}_${neuronTo.id}"] = "1_@_8"; // V18: Default Near Range
        } else if (neuronTo == nodeLeftMotorForwardSensor ||
            neuronTo == nodeLeftMotorBackwardSensor ||
            neuronTo == nodeRightMotorForwardSensor ||
            neuronTo == nodeRightMotorBackwardSensor) {
          isConnected = true;
          // Only set default if not already set (preserves loaded brains)
          String key = "${neuronFrom.id}_${neuronTo.id}";
          if (!mapContactsNeuron.containsKey(key) || mapContactsNeuron[key] == 0) {
             mapContactsNeuron[key] = 25.0;
          }
          // Always sync edge.connectionStrength from the map (source of truth)
          lastCreatedEdge.connectionStrength = (mapContactsNeuron[key] as num).toDouble();
          lastCreatedEdge.label = (mapContactsNeuron[key] as num).floor().toString();
        } else if (neuronTo == nodeSpeakerSensor) {
          isConnected = true;
          mapSpeakerNeuron["${neuronFrom.id}_${neuronTo.id}"] = 440.0;
          String keyId = "${neuronFrom.id}_${neuronTo.id}";
          String keyRaw = "${neuronFrom.key}_${neuronTo.key}";
          controller.mapSpeakerNeuron[keyId] = 440.0;
          controller.mapSpeakerNeuron[keyRaw] = 440.0;
          controller.mapSpeakerNeuron = Map.from(controller.mapSpeakerNeuron); // Force refresh
          lastCreatedEdge.label = "440";
        } else if (neuronTo == nodeMicrophoneSensor) {
          // isMicrophoneMenu
          isConnected = true;
          mapMicrophoneNeuron["${neuronFrom.id}_${neuronTo.id}"] = 40.0;
        } else if (neuronTo.key == nodeSingleLed.key) {
          isConnected = true;
          printDebug("neuronTo nodeSingleLed.key");
          mapLedNeuron["${neuronFrom.id}_${nodeRedLed.id}"] = 50;
          mapLedNeuron["${neuronFrom.id}_${nodeGreenLed.id}"] = 22;
          mapLedNeuron["${neuronFrom.id}_${nodeBlueLed.id}"] = 13;

          int redColor =
              (mapLedNeuron["${neuronFrom.id}_${nodeRedLed.id}"] / 100 * 255)
                  .floor();
          int greenColor =
              (mapLedNeuron["${neuronFrom.id}_${nodeGreenLed.id}"] / 100 * 255)
                  .floor();
          int blueColor =
              (mapLedNeuron["${neuronFrom.id}_${nodeBlueLed.id}"] / 100 * 255)
                  .floor();
          // neuronFrom.syntheticNeuron.blackBrush = Paint()
          //   ..color = Color.fromARGB(255, redColor, greenColor, blueColor)
          //   // ..color = Colors.yellow
          //   ..style = PaintingStyle.fill
          //   ..strokeWidth = 2;
          mapLedNeuronPosition["${neuronFrom.id}_${nodeRedLed.id}"] = "1111";
          mapLedNeuronPosition["${neuronFrom.id}_${nodeGreenLed.id}"] = "1111";
          mapLedNeuronPosition["${neuronFrom.id}_${nodeBlueLed.id}"] = "1111";
          
          // V23: Initialize NEW LED widget maps with BYB orange default
          String connectionKey = "${neuronFrom.id}_${neuronTo.id}";
          mapLedHex[connectionKey] = "FD8164"; // BYB orange
          mapLedBrightness[connectionKey] = "0.50";
          _robotLedActive = "1111";
          _robotLedHex = "FD8164";
          _robotLedBrightness = "0.50";
          
          // Update edge color to match BYB orange default
          lastCreatedEdge.connectionStrength = 50;
          lastCreatedEdge.color = const Color(0xFFFD8164).withOpacity(0.50); // BYB orange at 50% brightness
          lastCreatedEdge.isLedEdge = true;
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
          updateLiveConnectionBuffer(neuronFrom, neuronTo, 25.0, "connectome");

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
        setState(() {});
      }

      setState(() {});
      MyApp.logAnalytic(
          "CreateAxon", {"timestamp": DateTime.now().millisecondsSinceEpoch});
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

class ObjectHighlightPainter extends CustomPainter {
  final List<Recognition>? results;
  final Set<String> activeLabels;

  ObjectHighlightPainter({this.results, required this.activeLabels});

  @override
  void paint(Canvas canvas, Size size) {
    if (results == null || results!.isEmpty) return;

    // Scale from 320x240 logic to the current canvas physical size
    double scaleX = size.width / 320.0;
    double scaleY = size.height / 240.0;

    for (var r in results!) {
      if (!activeLabels.contains(r.label)) continue;

      Rect rect = Rect.fromLTRB(
          r.location.left * scaleX,
          r.location.top * scaleY,
          r.location.right * scaleX,
          r.location.bottom * scaleY);

      Paint paint = Paint()
        ..blendMode = BlendMode.multiply
        ..color = const Color.fromARGB(255, 253, 129, 100).withOpacity(0.85);

      if (r.label == "person") {
        paint.color = const Color.fromARGB(255, 253, 129, 100);
      } else if (r.label == "banana" || r.label == "orange" || r.label == "apple") {
        paint.color = const Color.fromARGB(255, 85, 238, 85);
      }

      if (r.maskGrid != null && r.maskWidth != null && r.maskHeight != null) {
        // Row-run approach: merge contiguous active mask pixels into single
        // rects per row. Eliminates the grid/overlap artifacts caused by
        // drawRawPoints + BlendMode.multiply on macOS Skia.
        int mw = r.maskWidth!;
        int mh = r.maskHeight!;
        
        // Check for any active pixels
        bool hasActive = false;
        for (int i = 0; i < r.maskGrid!.length; i++) {
           if (r.maskGrid![i]) { hasActive = true; break; }
        }
        
        if (hasActive) {
           // Synchronous row-run rendering: draw contiguous active pixels as
           double dx = rect.width / mw;
           double dy = rect.height / mh;
           
           Paint fillPaint = Paint()
              ..color = paint.color
              ..blendMode = paint.blendMode
              ..style = PaintingStyle.fill;
           
           for (int y = 0; y < mh; y++) {
             int rowStart = y * mw;
             int runStart = -1;
             for (int x = 0; x <= mw; x++) {
               bool active = (x < mw) && r.maskGrid![rowStart + x];
               if (active && runStart < 0) {
                 runStart = x;
               } else if (!active && runStart >= 0) {
                 // Draw the run as a single rect (no overlap, no gaps)
                 canvas.drawRect(
                   Rect.fromLTWH(
                     rect.left + runStart * dx,
                     rect.top + y * dy,
                     (x - runStart) * dx,
                     dy,
                   ),
                   fillPaint,
                 );
                 runStart = -1;
               }
             }
           }
        }
      } else {
        // Fallback: draw rounded rect
        canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(10)), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant ObjectHighlightPainter oldDelegate) {
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

  // static double centroidColorY = 0;
  // Expanded to 75 (3 colors * 5 blobs * 5 values: x, y, score, w, h)
  static List<int> centroids = List<int>.filled(75, 0);

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
      // Always run checkColorCV to ensure Sketch Mode (debug image) updates 
      // and that centroids are zeroed out if no targets are active.
      // The native layer handles optimization by skipping detection if activeColors == 0.
      if (true) {
        isCheckingColor = true;

        Float32List? boundingBoxes;
        int activeColors = 0;
        Set<String> activeAiLabels = {};
        
        // Define AI labels mapping (indices 7+) matching cameraMenuTypes
        List<String> aiLabels = [
            "person", "backpack", "bottle", "cup", "bowl", "banana", "apple", 
            "orange", "chair", "couch", "potted plant", "laptop", "cell phone", 
            "book", "vase", "dog", "cat", "tv", "mouse", "keyboard", "scissors", "donut", "pizza", "hot dog",
            "car", "motorcycle", "airplane", "bus", "train", "truck", "boat", "traffic light", "stop sign", "bird", "horse", "sheep", "cow", "elephant", "bear", "zebra", "giraffe", "umbrella", "handbag", "tie", "suitcase", "frisbee", "skis", "snowboard", "sports ball", "kite", "baseball bat", "baseball glove", "skateboard", "surfboard", "tennis racket", "wine glass", "fork", "knife", "spoon", "sandwich", "broccoli", "carrot", "cake", "bed", "dining table", "toilet", "remote", "microwave", "oven", "toaster", "sink", "refrigerator", "clock"
        ];
        
        // Iterate mapSensoryNeuron to find active color and AI targets
        for (var val in _DesignBrainPageState.mapSensoryNeuron.values) {
            if (val is int) {
                if (val == 0 || val == 1) activeColors |= 1; // Blue
                else if (val == 2 || val == 3) activeColors |= 2; // Green
                else if (val == 4 || val == 5) activeColors |= 4; // Red
                else if (val >= 7) {
                    int aiIndex = val - 7;
                    if (aiIndex >= 0 && aiIndex < aiLabels.length) {
                        activeAiLabels.add(aiLabels[aiIndex]);
                    }
                }
            }
        }
        


        // Calculate AI detections active state to keep native tracking dormant if needed
        if (_DesignBrainPageState.results != null) {
          for (var r in _DesignBrainPageState.results!) {
              if (activeAiLabels.contains(r.label)) {
                  // No redundant manual threshold checks here!
                  // We natively dynamically optimize thresholds locally straight inside the tracking C engine.
                  
                  // NOTE: WE NO LONGER SEND BOUNDING BOXES TO C++!
                  // By leaving `boundingBoxes` as null/empty, we bypass C++ drawing its legacy 
                  // basic tracking bounding boxes, so the Dart `ObjectHighlightPainter` takes precedence
                  // via `findColorInImage_opencv` doing nothing for boxes!
              }
          }
        }

        checkColorCV(frameData, boundingBoxes, activeColors).then((result) {
          _DesignBrainPageState.currentActiveColors = activeColors;
          if (activeColors != 0) {
             printDebug("NativeCV: actCols=$activeColors, Map=${_DesignBrainPageState.mapSensoryNeuron}");
             printDebug("NativeCV Centroids: ${result['centroids']}");
          }
          // Only update the cached overlay when we have a NEW processed frame.
          // Never clear it — the overlay should always be visible.
          if (result["debugImage"] != null && (result["debugImage"] as Uint8List).isNotEmpty) {
            _DesignBrainPageState.debugCvImage = result["debugImage"];
          }
          _DesignBrainPageState.onDebugUpdate?.call();
          String frameResult = result["result"].toRadixString(2);
          if (frameResult.length > 5) {
            _DesignBrainPageState.strLeftColorMenu =
                frameResult.substring(1, 4);
            _DesignBrainPageState.strRightColorMenu = frameResult.substring(4);
          }
          // Sync the global static list with the latest result so UI and Logic see the same data.
          if (result["centroids"] is List<int>) {
             List<int> newCentroids = result["centroids"];
             // Ensure size match
             if (newCentroids.length == ImagePreprocessor.centroids.length) {
                 ImagePreprocessor.centroids.setAll(0, newCentroids);
             }
          }
          
          // Use the global list for logic, guaranteed to be same as UI.
          centroids = ImagePreprocessor.centroids;

          // check if centroids inside the camera Region
          // check if centroids inside the camera Region
          // Refactored for Multi-Blob (5 blobs per color)
          
          for (int idx = 0; idx < 3; idx++) {
            
            // 1. Reset visual inputs for this color channel (across all neurons) BEFORE processing blobs
            // This ensures we start clean for this frame.
            for (int jNeuron = normalNeuronStartIdx + 2;
                jNeuron < _DesignBrainPageState.neuronSize + 2;
                jNeuron++) {
              int jNeuronIdx = jNeuron - 2;
              _DesignBrainPageState.visualInputBufView[idx * 2 +
                  jNeuronIdx * _DesignBrainPageState.VisualInputLength] = 0;
            }

            // 2. Accumulate scores from ALL blobs — matches native C++ vis_pref_vals logic
            double totalScore = 0;
            double totalLeftScore = 0;
            double totalRightScore = 0;
            
            for (int k = 0; k < 5; k++) {
                int baseBufIdx = (idx * 5 + k) * 5;
                if (baseBufIdx + 4 >= centroids.length) break;

                double bScore = centroids[baseBufIdx + 2].toDouble();
                if (bScore < 10) continue;
                
                double cx = centroids[baseBufIdx + 0].toDouble();
                
                // Accumulate scores exactly like native C++ (lines 557-562 of native_opencv.cpp)
                double leftWeight = 1.0 / (1.0 + exp(-10.0 * (((228.0 - cx) / 227.0) - 0.85)));
                double rightWeight = 1.0 / (1.0 + exp(-10.0 * ((cx / 227.0) - 0.85)));
                
                totalScore += bScore;
                totalLeftScore += (leftWeight * bScore);
                totalRightScore += (rightWeight * bScore);
            }
            
            // 3. Clamp accumulated scores to match distance/mic sensor range (0-50)
            // Raw pixel areas from OpenCV can be hundreds-to-thousands; without clamping,
            // color blobs inject 10-100x more current than distance (binary 0 or 50),
            // causing the oscilloscope trace to clip unrealistically.
            totalScore = totalScore.clamp(0, 50);
            totalLeftScore = totalLeftScore.clamp(0, 50);
            totalRightScore = totalRightScore.clamp(0, 50);

            // 4. Write clamped scores to visPrefsValsBufView — identical to native passPreprocessPointers
            _DesignBrainPageState.visPrefsValsBufView[idx * 2] = totalScore;
            _DesignBrainPageState.visPrefsValsBufView[idx * 2 + 1] = totalLeftScore; // or totalRightScore based on icam

            // 4. Check blobs against area detection zones and trigger neurons
            for (int k = 0; k < 5; k++) {
                int baseBufIdx = (idx * 5 + k) * 5;
                if (baseBufIdx + 4 >= centroids.length) break;

                double score = centroids[baseBufIdx + 2].toDouble();
                if (score < 10) continue;
                
                double x = centroids[baseBufIdx + 0].toDouble();
                double y = centroids[baseBufIdx + 1].toDouble();
                double w = centroids[baseBufIdx + 3].toDouble();
                double h = centroids[baseBufIdx + 4].toDouble();
                if (w < 1) w = 1;
                if (h < 1) h = 1;

                Offset center = Offset(x, y);

                for (String key in _DesignBrainPageState.mapSensoryNeuron.keys) {
                bool isLeftEye = key.contains(_DesignBrainPageState.nodeLeftEyeSensor.key.toString());
                bool isRightEye = _DesignBrainPageState.instance != null && key.contains(_DesignBrainPageState.instance!.nodeRightEyeSensor.key.toString());
                
                if ((isLeftEye || isRightEye) && _DesignBrainPageState.mapSensoryNeuron[key] == (idx * 2)) {
                    
                    String? areaMode = _DesignBrainPageState.mapAreaSize[key];
                    if (areaMode == null) {
                        continue; 
                    }

                    List<String> modes = areaMode.split("_@_");
                    
                    bool iscontained = containImage(
                        Rect.fromCenter(center: center, width: w, height: h),
                        modes);
                    
                    if (iscontained) {
                        for (int jNeuron = normalNeuronStartIdx + 2;
                            jNeuron < _DesignBrainPageState.neuronSize + 2;
                            jNeuron++) {
                            InfiniteCanvasNode node =
                                _DesignBrainPageState.controller.nodes[jNeuron];
                            int jNeuronIdx = jNeuron - 2;
                            if (key.contains(node.id)) {
                                int visualIndex = idx * 2 +
                                    jNeuronIdx *
                                        _DesignBrainPageState.VisualInputLength;
                                // Use accumulated score from visPrefsValsBufView (matches native exactly)
                                _DesignBrainPageState.visualInputBufView[visualIndex] =
                                    _DesignBrainPageState.visPrefsValsBufView[idx * 2];
                            }
                        }
                    }
                }
                }
            }
          }

          isCheckingColor = false;
        }).catchError((e) {
             printDebug("Error in checkColorCV: $e");
             isCheckingColor = false;
        });
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

  bool containRecognition(Recognition r, List<String> modes) {
    if (modes[0] == "Any") return true;

    if (r.maskGrid != null && r.maskWidth != null && r.maskHeight != null) {
      double xStart = 0;
      double xEnd = 0;
      try {
        double p1 = double.parse(modes[1]);
        double p2 = double.parse(modes[2]);
        xStart = p1 < p2 ? p1 : p2;
        xEnd = p1 < p2 ? p2 : p1;
      } catch (_) {
        return true; 
      }
      
      double dx = r.location.width / r.maskWidth!;
      
      for (int y = 0; y < r.maskHeight!; y++) {
        for (int x = 0; x < r.maskWidth!; x++) {
          if (r.maskGrid![y * r.maskWidth! + x]) {
             double globalPx = r.location.left + (x * dx);
             if (globalPx >= xStart && globalPx <= xEnd) {
                 return true;
             }
          }
        }
      }
      return false;
    }
    return containImage(r.location, modes);
  }

  bool containImage(Rect location, List<String> modes) {
    if (modes[0] == "Any") {
      return true;
    }

    double xStart = 0;
    double xEnd = 0;
    try {
      double p1 = double.parse(modes[1]);
      double p2 = double.parse(modes[2]);
      xStart = p1 < p2 ? p1 : p2;
      xEnd = p1 < p2 ? p2 : p1;
    } catch (_) {
        return true; 
    }

    // Check for HORIZONTAL INTERSECTION/OVERLAP (Parity with AI Logic)
    // Instead of checking if the center is strictly inside, we check if the object's box overlaps the zone.
    // Overlap condition: (Rect.Right > Zone.Left) AND (Rect.Left < Zone.Right)
    
    // "Left", "Right", "Custom" all basically define an X-range [xStart, xEnd].
    // We treat them uniformly here.
    if (modes[0] == "Left" || modes[0] == "Right" || modes[0] == "Custom") {
        if (location.right > xStart && location.left < xEnd) {
            return true;
        } else {
            return false;
        }
    } else if (modes[0] == "Any") {
      // any
      return true;
    }
    return false;
  }



}
  void printDebug(dynamic msg) {
    if (kDebugMode) {
      print(msg);
      try {
        // Append to debug_log.txt for retrieval tool
        final directory = Directory("${Platform.environment['HOME']}/.gemini/antigravity/brain/b55c58ab-9253-42f0-874d-78e164ae4e6f");
        if (!directory.existsSync()) return;
        final file = File('${directory.path}/debug_log.txt');
        file.writeAsStringSync("${DateTime.now()}: $msg\n", mode: FileMode.append);
      } catch (e) {
        // ignore
      }
    }
  }

// Custom Widget for Remote Control Keycaps
// SIMPLIFIED: Stateless, driven by parent 'overrideColor' from Nucleus


class RemoteControlKeycap extends StatelessWidget {
  // Use Node to look up key dynamically (Fixes sticky state on updates)
  final InfiniteCanvasNode? node; 
  final String fallbackKeyName;
  final bool isExcitatory;
  final double size;
  final Color? overrideColor; 
  final bool transparentBackground;
  final Map<String, String>? remoteControlMap;

  const RemoteControlKeycap({
    Key? key,
    this.node,
    this.fallbackKeyName = "",
    required this.isExcitatory,
    required this.size,
    this.overrideColor,
    this.transparentBackground = false,
    this.remoteControlMap,
  }) : super(key: key);

  String? getIconPath() {
    // Dynamic Lookup
    String keyName = fallbackKeyName;
    if (node != null && remoteControlMap != null && remoteControlMap!.containsKey(node!.id)) {
        keyName = remoteControlMap![node!.id] ?? "";
    }
    
    String key = keyName.toLowerCase().trim();

    if (key.isEmpty) return "assets/icons/remoteControlKeys/RemoteControl.svg";

    // Debug D-Pad Input (Write to file)
    if (key.contains("dpad")) {
        bool neg = key.contains("val:-") || key.contains("-1.0") || key.contains(":-") || key.contains(":-1") || key.contains(" -1") || key.contains("left") || key.contains("down");
        String msg = "Key: '$key' | isNegative: $neg\n";
        // printDebug(msg);
        try {
            File('${Platform.environment['HOME']}/.gemini/antigravity/brain/b55c58ab-9253-42f0-874d-78e164ae4e6f/dpad_log.txt').writeAsStringSync(msg, mode: FileMode.append);
        } catch(e) {}
    } 

    // Helper for robust matching
    bool has(String token) => key.contains(token);
    bool hasAll(List<String> tokens) => tokens.every((t) => key.contains(t));

    // 0. STRICT USER MAPPINGS (Apple/SDL Controller specific)
    // Place these FIRST to override generic "circle" or "dpad" logic
    
    // Face Buttons (x.circle, a.circle etc)
    if (has("a.circle")) return "assets/icons/remoteControlKeys/ButtonA.svg";
    if (has("b.circle")) return "assets/icons/remoteControlKeys/ButtonB.svg";
    if (has("x.circle")) return "assets/icons/remoteControlKeys/ButtonX.svg";
    if (has("y.circle")) return "assets/icons/remoteControlKeys/ButtonY.svg";
    if (has("xmark")) return "assets/icons/remoteControlKeys/ButtonX.svg"; // "xmark"
    
    // Plus/Minus
    if (has("minus.circle") || has("minus")) return "assets/icons/remoteControlKeys/ButtonMinus.svg";
    if (has("plus.circle") || has("plus")) return "assets/icons/remoteControlKeys/ButtonPlus.svg";
    
    // D-Pad Specifics
    if (has("dpad") || has("hat")) {
        // X-Axis
        if (has("xaxis")) {
             // 1. Strict Val checks
             if (has("-1.0") || has("val:-1.0")) return "assets/icons/remoteControlKeys/dPadLeft.svg";
             if (has("1.0") || has("val:1.0")) return "assets/icons/remoteControlKeys/dPadRight.svg";
             
             // 2. Word checks
             if (has("left")) return "assets/icons/remoteControlKeys/dPadLeft.svg";
             if (has("right")) return "assets/icons/remoteControlKeys/dPadRight.svg";
        }
        
        // Y-Axis
        if (has("yaxis")) {
             // 1. Strict Val checks
             if (has("-1.0") || has("val:-1.0")) return "assets/icons/remoteControlKeys/dPadDown.svg";
             if (has("1.0") || has("val:1.0")) return "assets/icons/remoteControlKeys/dPadUp.svg";

             // 2. Word checks
             if (has("up")) return "assets/icons/remoteControlKeys/dPadUp.svg";
             if (has("down")) return "assets/icons/remoteControlKeys/dPadDown.svg";
        }

        // Fallback checks (No Axis)
        if (has("left")) return "assets/icons/remoteControlKeys/dPadLeft.svg";
        if (has("right")) return "assets/icons/remoteControlKeys/dPadRight.svg";
        if (has("up")) return "assets/icons/remoteControlKeys/dPadUp.svg";
        if (has("down")) return "assets/icons/remoteControlKeys/dPadDown.svg";
        
        // Logical Fallbacks for Axis (non-explicit 1.0)
        // CRITICAL: The input string contains "dpad - xAxis" (separator hyphen).
        // We CANNOT check for " -" (space hyphen) because it matches the separator!
        // We must check for explicit negative indicators like "val:-" or "-1.0" or "left"/"down".
        
        // Helper to check for negative value specifically
        // Added checks for " -1" (space minus 1) and ":-" (colon minus) and ": -1" just in case
        bool isNegative() => has("val:-") || has("-1.0") || has(":-") || has(":-1") || has(" -1") || has("left") || has("down");
        
        // Debugging for D-Pad
        // printDebug("D-Pad Check: Key='$key', isNegative=${isNegative()}");

        if (has("xaxis")) {
            if (isNegative()) return "assets/icons/remoteControlKeys/dPadLeft.svg";
            return "assets/icons/remoteControlKeys/dPadRight.svg"; 
        }
        
        if (has("yaxis")) {
            if (isNegative()) return "assets/icons/remoteControlKeys/dPadDown.svg";
            return "assets/icons/remoteControlKeys/dPadUp.svg";
        }
    }

    // 1. Generic Buttons (if not caught by above)
    if (has("button a") || key == "button 0") return "assets/icons/remoteControlKeys/ButtonA.svg";
    if (has("button b") || key == "button 1") return "assets/icons/remoteControlKeys/ButtonB.svg";
    if (has("button x") || key == "button 2") return "assets/icons/remoteControlKeys/ButtonX.svg";
    if (has("button y") || key == "button 3") return "assets/icons/remoteControlKeys/ButtonY.svg";

    // 2. Shapes
    if (has("triangle")) return "assets/icons/remoteControlKeys/ButtonTriangle.svg";
    if (has("square")) return "assets/icons/remoteControlKeys/ButtonSquare.svg";
    // Only return Circle shape if it wasn't caught by a.circle/b.circle above
    if (has("circle") && !has("button") && !has("a.") && !has("b.") && !has("x.") && !has("y.") && !has("minus.") && !has("plus.")) return "assets/icons/remoteControlKeys/ButtonCircle.svg";
    if (has("cross")) return "assets/icons/remoteControlKeys/ButtonX.svg";

    // 3. Start/Select
    if (has("select") || has("back")) return "assets/icons/remoteControlKeys/ButtonMinus.svg"; 
    if (has("start") || has("menu") || has("options")) return "assets/icons/remoteControlKeys/ButtonPlus.svg";
    if (has("padclick") || has("touchpad")) return "assets/icons/remoteControlKeys/PadClick.svg";

    // 4. Joysticks
    if (has("joystick") || has("thumb") || has("stick")) {
         if (has("xaxis")) {
             if (has(">0.4") || has("> 0.4") || has("+") || has("right")) return "assets/icons/remoteControlKeys/JoyRight.svg";
             if (has("<-0.4") || has("< -0.4") || has("-") || has("left")) return "assets/icons/remoteControlKeys/JoyLeft.svg";
         }
         if (has("yaxis")) {
             // User: "y axis >0.4 ... JoyUp"
             if (has(">0.4") || has("> 0.4") || has("+") || has("up") || has("1.0")) return "assets/icons/remoteControlKeys/JoyUp.svg";
             if (has("<-0.4") || has("< -0.4") || has("-") || has("down") || has("-1.0")) return "assets/icons/remoteControlKeys/JoyDown.svg";
         }
         // Fallback for "Axis" strings directly
         if (has("axis 0")) return (has("+") || has(">")) ? "assets/icons/remoteControlKeys/JoyRight.svg" : "assets/icons/remoteControlKeys/JoyLeft.svg";
         if (has("axis 1")) return (has("+") || has(">")) ? "assets/icons/remoteControlKeys/JoyDown.svg" : "assets/icons/remoteControlKeys/JoyUp.svg";
    }
    
    // 5. Hand Draw
    if (has("hand.draw")) {
         if (has("xaxis")) {
             if (has(">0.4") || has(">") || has("+")) return "assets/icons/remoteControlKeys/PadRight.svg";
             if (has("<-0.4") || has("<") || has("-")) return "assets/icons/remoteControlKeys/PadLeft.svg";
         }
         if (has("yaxis")) {
             if (has(">0.4") || has(">") || has("+")) return "assets/icons/remoteControlKeys/PadUp.svg";
             if (has("<-0.4") || has("<") || has("-")) return "assets/icons/remoteControlKeys/PadDown.svg";
         }
    }

    // 6. Keyboard Arrows
    if (has("arrow")) {
        if (has("left")) return "assets/icons/remoteControlKeys/KeyLeft.svg";
        if (has("right")) return "assets/icons/remoteControlKeys/KeyRight.svg";
        if (has("up")) return "assets/icons/remoteControlKeys/KeyUp.svg";
        if (has("down")) return "assets/icons/remoteControlKeys/KeyDown.svg";
    }

    return null;
  }

  String getLabel() {
    // Dynamic Lookup
    String keyName = fallbackKeyName;
    if (node != null && remoteControlMap != null && remoteControlMap!.containsKey(node!.id)) {
        keyName = remoteControlMap![node!.id] ?? "";
    }
    String key = keyName.toLowerCase().trim();
    
    // Strict Label Mapping (User Request)
    // l.joystick.down -> L3
    if (key.contains("l.joystick.down") || key.contains("thumb l") || key.contains("stick l")) return "L3";
    // r.joystick.press.down -> R3
    if (key.contains("r.joystick.press.down") || key.contains("thumb r") || key.contains("stick r")) return "R3";
    
    // L1/R1/L2/R2
    if (key.contains("l.rectangle.roundedbottom") || key.contains("l1.rectangle") || key.contains("bumper left") || key.contains("button 4")) return "L1";
    if (key.contains("r.rectangle.roundedbottom") || key.contains("r1.rectangle") || key.contains("bumper right") || key.contains("button 5")) return "R1";
    if (key.contains("zl.rectangle.roundedtop") || key.contains("l2.rectangle") || key.contains("trigger left") || key.contains("button 6")) return "L2";
    if (key.contains("zr.rectangle.roundedtop") || key.contains("r2.rectangle") || key.contains("trigger right") || key.contains("button 7")) return "R2";

    // Clean up "Pad:..." prefix if present
    String cleanKey = key;
    if (key.startsWith("pad:")) {
        List<String> parts = key.split(":");
        if (parts.length >= 3) cleanKey = parts[2];
    }
    
    // Keyboard Keys fallback
    if (cleanKey.startsWith("key ")) {
        String k = cleanKey.substring(4).toUpperCase();
        if (k.length == 1) return k;
        if (k == "SPACE") return "SP";
        if (k == "ENTER") return "RET";
        if (k == "SHIFT") return "SH";
        return k.length > 2 ? k.substring(0, 2) : k;
    }

    return cleanKey.toUpperCase().substring(0, min(2, cleanKey.length));
  }

  @override
  Widget build(BuildContext context) {
      Color baseTextColor = isExcitatory ? Colors.black : Colors.white;
      // Use override color from Nucleus (blinking) or default
      Color textColor = overrideColor ?? baseTextColor;
      
      String? iconPath = getIconPath();
      
      Widget content;
      
      if (iconPath != null) {
          content = SvgPicture.asset(
              iconPath,
              colorFilter: ColorFilter.mode(textColor, BlendMode.srcIn), // Tint properly
              width: size * 0.9 * 1.25 * 0.9, // Scaled 90% of current (90% of 125%)
              height: size * 0.9 * 1.25 * 0.9,
              fit: BoxFit.contain,
          );
      } else {
          String label = getLabel();
          
          content = Text(
            label,
            style: TextStyle(
              fontSize: transparentBackground ? size * 0.75 * 1.25 * 0.9 : size * 0.6, // Scaled 90% of current
              fontFamily: "BybHanddrawn", 
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          );
      }

      if (transparentBackground) {
         // Fix: Larger Container, Center Alignment, Allow Content to exceed bounds if needed (though Center should hold it)
         return SizedBox(
             width: size, 
             height: size, 
             child: OverflowBox(
                 minWidth: size, maxWidth: size * 3, // Allow plenty of width
                 minHeight: size, maxHeight: size * 3,
                 alignment: Alignment.center,
                 child: Center(child: content)
             )
         );
      }

    // Parse Label logic (OLD LOGIC - REMOVED/REPLACED by helpers above)
    // We only keep the container/decoration logic for Sidebar Widget
     return Container(
       width: size,
       height: size,
       decoration: BoxDecoration(
         color: isExcitatory ? Colors.white : Colors.black,
         borderRadius: BorderRadius.circular(size * 0.2), // Rounded square
         border: Border.all(
           color: Colors.black, // Always black border for widget?
           width: 1,
         ),
         boxShadow: [
           BoxShadow(
             color: Colors.black.withOpacity(0.2),
             blurRadius: 2,
             offset: const Offset(1, 1),
           )
         ],
       ),
       alignment: Alignment.center,
       child: content,
     );
  }
}



class MotorAnimatedWidget extends StatefulWidget {
  final double value;
  final String wheel;
  final String action;
  final bool isExcitatory;
  final bool isMixed;
  final ValueChanged<double> onChanged;

  const MotorAnimatedWidget({
    Key? key,
    required this.value,
    required this.wheel,
    required this.action,
    required this.isExcitatory,
    required this.isMixed,
    required this.onChanged,
  }) : super(key: key);

  @override
  _MotorAnimatedWidgetState createState() => _MotorAnimatedWidgetState();
}

class _MotorAnimatedWidgetState extends State<MotorAnimatedWidget> with SingleTickerProviderStateMixin {
  late Ticker _ticker;
  double _accumulatedTime = 0.5; // Starts resting in the middle of the arc
  Duration _lastElapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
    _ticker.start();
  }
  
  void _onTick(Duration elapsed) {
    if (_lastElapsed == Duration.zero) {
        _lastElapsed = elapsed;
        return;
    }
    double dtSeconds = (elapsed.inMicroseconds - _lastElapsed.inMicroseconds) / 1000000.0;
    _lastElapsed = elapsed;

    if (widget.value == 0 && widget.isExcitatory) return;
    
    // For excitatory, use actual slider value. For inhibitory, simulate a default speed (e.g. 25%)
    double simulatedSpeed = widget.isExcitatory ? widget.value : 25.0;
    
    // Analog speed: 100% = 1.5 cycles per second.
    double cyclesPerSecond = (simulatedSpeed / 100.0) * 1.5; 
    
    // For inhibitory, we periodically interrupt the motion.
    // At 0%, no interruption (moves entirely at 25% speed). 
    // At 100%, always interrupted (moves 0% of the time).
    // Let's use time mod a period.
    bool paused = false;
    if (!widget.isExcitatory && widget.value > 0) {
        // We evaluate an interruption sequence.
        // A full cycle of motion + potential pause could be ~1.0 second.
        double totalTime = DateTime.now().millisecondsSinceEpoch / 1000.0;
        
        // Let's make the interruption check period 1.0 seconds.
        double period = 1.0; 
        double phase = totalTime % period;
        
        // widget.value / 100 represents the fraction of the period spent paused.
        double pauseFraction = widget.value / 100.0;
        
        if (phase < pauseFraction) {
            paused = true;
        }
    }
    
    setState(() {
      if (!paused) {
         _accumulatedTime += dtSeconds * cyclesPerSecond;
         if (_accumulatedTime > 1.0) _accumulatedTime -= 1.0;
         if (_accumulatedTime < 0.0) _accumulatedTime += 1.0;
      }
    });
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isLeftWheel = widget.wheel == "Left"; 
    
    // Right wheel forward = Clockwise, Left wheel forward = Clockwise. Let's start with 1.0 for both per feedback.
    double directionMult = 1.0;
    if (widget.action == "reverse") directionMult *= -1.0;

    double robotCenterX = isLeftWheel ? 180.0 : 120.0;
    double robotCenterY = 120.0;
    double rRobot = 90.0; // Tighter loop radius

    return SizedBox(
      width: 300, 
      height: 250, // Add 10px height to deeply extend past the 0% handle
      child: Stack(
        children: [
          // ArcSlider Widget Layer
          Positioned(
             left: isLeftWheel ? null : 0,
             right: isLeftWheel ? 0 : null,
             top: 0,
             child: SizedBox(
               width: 140,
               child: ArcSliderWidget(
                 value: widget.value,
                 min: 0,
                 max: 100,
                 widgetWidth: 140,
                 widgetHeight: 250,
                 orientation: isLeftWheel ? ArcSliderOrientation.verticalRight : ArcSliderOrientation.verticalLeft,
                 flipVertical: !isLeftWheel, 
                 isPercentageFormatter: true,
                 isMixedState: widget.isMixed,
                 title: "", // Remove "Speed:" text
                 onChanged: widget.onChanged,
               ),
             ),
          ),     
          // Animated Orbiting Robot Layer
          Builder(
            builder: (context) {
              double v = _accumulatedTime; // Freezes exactly in place if widget.value == 0

              // Travel in an exact 45-degree arc layout
              double sweep = pi / 4; 
              
              // Bottom to Top Sweep Native Layouts
              double startRel = sweep / 2; // +22.5 (Bottom Y)
              double endRel = -sweep / 2;  // -22.5 (Top Y)

              if (directionMult < 0) {
                  startRel = -sweep / 2;
                  endRel = sweep / 2;
              }

              double relAngle = startRel + (endRel - startRel) * v;

              double theta = !isLeftWheel ? relAngle : (pi - relAngle);

              double rx = robotCenterX + rRobot * cos(theta);
              double ry = robotCenterY + rRobot * sin(theta);

              double robotRotation = theta;
              
              // Handle reversing upright
              if (directionMult < 0) {
                  // Reversing should keep robot upright, offset by 180 degrees
                  robotRotation += pi;
              }
              
              if (!isLeftWheel) {
                 if (directionMult < 0) robotRotation += pi;
              } else {
                 if (directionMult > 0) robotRotation += pi;
              }

              // Opaque everywhere except near the very end of loop
              // If inhibitory, keep it fully opaque to show the pausing clearly
              double opacity = 1.0;
              if (widget.value > 0) {
                 if (!widget.isExcitatory) {
                     opacity = 1.0;
                 } else {
                     if (v < 0.1) opacity = v / 0.1;
                     else if (v > 0.9) opacity = (1.0 - v) / 0.1;
                 }
              }

              return Positioned(
                left: rx - 74.5, // Center mathematical point based on SVG + padding
                top: ry - 74.5,  
                child: Opacity(
                  opacity: opacity,
                  child: Transform.rotate(
                    angle: robotRotation,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: SvgPicture.asset(
                        "assets/icons/SpikerbotTopDownBlue.svg",
                        width: 125,
                        height: 125,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _DistanceRulerProportionalClipper extends CustomClipper<Rect> {
  final double minVal;
  final double maxVal;

  _DistanceRulerProportionalClipper(this.minVal, this.maxVal);

  @override
  Rect getClip(Size size) {
    double xMinFraction = 0.0;
    if (minVal > 1.0) {
      xMinFraction = (114.0 + (minVal / 130.0) * 286.0) / 400.0;
    }
    double xMaxFraction = (114.0 + (maxVal / 130.0) * 286.0) / 400.0;
    if (xMaxFraction > 1.0) xMaxFraction = 1.0;

    double left = size.width * xMinFraction;
    double width = (size.width * xMaxFraction) - left;
    return Rect.fromLTWH(left, 0, width, size.height);
  }

  @override
  bool shouldReclip(_DistanceRulerProportionalClipper oldClipper) {
    return minVal != oldClipper.minVal || maxVal != oldClipper.maxVal;
  }
}

class _CameraAreaProportionalClipper extends CustomClipper<Rect> {
  final double minVal;
  final double maxVal;

  _CameraAreaProportionalClipper(this.minVal, this.maxVal);

  @override
  Rect getClip(Size size) {
    double xMinFraction = (minVal - 1) / 319.0;
    double xMaxFraction = (maxVal - 1) / 319.0;
    if (xMinFraction < 0) xMinFraction = 0;
    if (xMaxFraction > 1.0) xMaxFraction = 1.0;

    double left = size.width * xMinFraction;
    double width = (size.width * xMaxFraction) - left;
    return Rect.fromLTWH(left, 0, width, size.height);
  }

  @override
  bool shouldReclip(_CameraAreaProportionalClipper oldClipper) {
    return minVal != oldClipper.minVal || maxVal != oldClipper.maxVal;
  }
}

/// Draws up to 3 sine waves stacked vertically (top=high, mid=mid, bottom=low).
/// Only waves whose band overlaps the selected Hz range are painted.
class MicFrequencyWavePainter extends CustomPainter {
  final bool showLow;   // range covers < 250 Hz
  final bool showMid;   // range covers 251–4000 Hz
  final bool showHigh;  // range covers > 4000 Hz

  const MicFrequencyWavePainter({
    required this.showLow,
    required this.showMid,
    required this.showHigh,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final rowH = size.height / 3;

    void drawWave(int row, double cycles, double amplitude, double stroke) {
      final midY = (row + 0.5) * rowH;
      final amp  = rowH * amplitude;
      paint.strokeWidth = stroke;
      final path = Path();
      const steps = 300;
      for (int i = 0; i <= steps; i++) {
        final x = i / steps * size.width;
        final y = midY - amp * sin(2 * pi * cycles * x / size.width);
        if (i == 0) path.moveTo(x, y); else path.lineTo(x, y);
      }
      canvas.drawPath(path, paint);
    }

    // Row 0 = top    → high freq  (many tight cycles, thin stroke)
    // Row 1 = middle → medium freq
    // Row 2 = bottom → low freq   (few wide cycles, thick stroke)
    if (showHigh) drawWave(0, 11, 0.28, 1.5);
    if (showMid)  drawWave(1,  5, 0.34, 2.2);
    if (showLow)  drawWave(2,  2, 0.38, 3.0);
  }

  @override
  bool shouldRepaint(MicFrequencyWavePainter o) =>
      o.showLow != showLow || o.showMid != showMid || o.showHigh != showHigh;
}
