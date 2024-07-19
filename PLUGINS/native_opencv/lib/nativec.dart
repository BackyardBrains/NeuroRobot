import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

// import 'package:nativec/allocation.dart';

import 'package:ffi/ffi.dart';
import 'package:native_opencv/allocator.dart';

// import 'nativec_platform_interface.dart';
import 'dart:ffi' as ffi;
// import 'package:ffi/ffi.dart';

typedef stop_thread_func = ffi.Int16 Function(ffi.Int16);
typedef StopThreadProcess = int Function(int);
typedef change_is_playing_func = ffi.Int16 Function(ffi.Int16);
typedef ChangeIsPlayingProcess = int Function(int);
typedef change_idx_selected_func = ffi.Int16 Function(ffi.Int16);
typedef ChangeIdxSelectedProcess = int Function(int);

typedef _initialize_func = ffi.Int Function();
typedef InitializeProcess = int Function();

typedef change_neuron_simulator_func = ffi.Double Function(
  ffi.Pointer<ffi.Double>,
  ffi.Pointer<ffi.Double>,
  ffi.Pointer<ffi.Int16>,
  ffi.Pointer<ffi.Int16>,
  ffi.Pointer<ffi.Double>,
  ffi.Pointer<ffi.Double>,
  // ffi.Pointer<ffi.Double>,
  // ffi.Pointer<ffi.Double>,
  // ffi.Pointer<ffi.Uint16>,
  ffi.Pointer<ffi.Double>,

  // ffi.Pointer<ffi.Int16>,
  // ffi.Pointer<ffi.Int32>,
  ffi.Int16,
  ffi.Uint32,
  ffi.Uint32,
  ffi.Uint32,
  ffi.Int16,
  ffi.Pointer<ffi.Int16>, // visualPreferences
  ffi.Pointer<ffi.Double>, //motorCommandBuf
  ffi.Pointer<ffi.Double>, //neuronContactsBuf

  ffi.Pointer<ffi.Int16>, // mapNeuronType
  ffi.Pointer<ffi.Int16>, // mapDelayNeuron
  ffi.Pointer<ffi.Int16>, // mapRhytmicNeuron
  ffi.Pointer<ffi.Int16>, // mapCountingNeuron
);
typedef ChangeNeuronSimulatorProcess = double Function(
  ffi.Pointer<ffi.Double>, // a
  ffi.Pointer<ffi.Double>, // b
  ffi.Pointer<ffi.Int16>, // c
  ffi.Pointer<ffi.Int16>, // d
  ffi.Pointer<ffi.Double>, // i
  ffi.Pointer<ffi.Double>, // w

  // ffi.Pointer<ffi.Double>, // canvas buffer neuron 1
  // ffi.Pointer<ffi.Double>, // canvas buffer neuron 2
  // ffi.Pointer<ffi.Uint16>, // position
  ffi.Pointer<ffi.Double>, //connectome

  // ffi.Pointer<ffi.Int16>, // neuroncircle
  // ffi.Pointer<ffi.Int32>, //nps
  int, // level
  int, // neuron length
  int, // envelope size
  int, // buffer size
  int, // isPlaying
  ffi.Pointer<ffi.Int16>, // visualPreferences
  ffi.Pointer<ffi.Double>, //motorCommandBuf
  ffi.Pointer<ffi.Double>, //neuronContactsBuf

  ffi.Pointer<ffi.Int16>, // mapNeuronType
  ffi.Pointer<ffi.Int16>, // mapDelayNeuron
  ffi.Pointer<ffi.Int16>, // mapRhytmicNeuron
  ffi.Pointer<ffi.Int16>, // mapCountingNeuron
);

typedef set_threshold_dart_port_func = ffi.Double Function(ffi.Int64);
typedef SetThresholdDartPortFunc = double Function(int);

typedef pass_pointers_func = ffi.Double Function(
  ffi.Pointer<ffi.Double>,
  ffi.Pointer<ffi.Int16>,
  ffi.Pointer<ffi.Int16>,
  ffi.Pointer<ffi.Uint32>,
  ffi.Pointer<ffi.Int32>,
  ffi.Pointer<ffi.Int16>,
  ffi.Pointer<ffi.Double>,
  ffi.Pointer<ffi.Uint8>,
  ffi.Pointer<ffi.Double>,
  ffi.Pointer<ffi.Int16>,
  ffi.Pointer<ffi.Int16>,
  ffi.Pointer<ffi.Int16>,
  ffi.Pointer<ffi.Int16>,
  ffi.Pointer<ffi.Int16>,
);
typedef PassPointers = double Function(
  ffi.Pointer<ffi.Double>,
  ffi.Pointer<ffi.Int16>,
  ffi.Pointer<ffi.Int16>,
  ffi.Pointer<ffi.Uint32>,
  ffi.Pointer<ffi.Int32>,
  ffi.Pointer<ffi.Int16>,
  ffi.Pointer<ffi.Double>,
  ffi.Pointer<ffi.Uint8>,
  ffi.Pointer<ffi.Double>,
  ffi.Pointer<ffi.Int16>,
  ffi.Pointer<ffi.Int16>,
  ffi.Pointer<ffi.Int16>,
  ffi.Pointer<ffi.Int16>,
  ffi.Pointer<ffi.Int16>,
);

typedef pass_input_func = ffi.Double Function(
  ffi.Pointer<ffi.Double>,
);
typedef PassInput = double Function(
  ffi.Pointer<ffi.Double>,
);

// typedef _SimulationCallbackFunc = int Function(ffi.Pointer<ffi.Uint8>, int, ffi.Pointer<ffi.Uint8>);
// final _SimulationCallbackFunc _simulationCallbackFunc = _lib
//   .lookup<ffi.NativeFunction<_find_color_in_image_func>>('simulationCallbackFunc')
//   .asFunction();

// typedef SimulationCallback = Void Function(Pointer<Utf8>);
typedef HttpCallback = ffi.Void Function(ffi.Pointer<Utf8>);

typedef HttpServeFunction = void Function(
    ffi.Pointer<ffi.NativeFunction<HttpCallback>>);
typedef HttpServeNativeFunction = ffi.Void Function(
    ffi.Pointer<ffi.NativeFunction<HttpCallback>>);

// Low Pass filter sample https://www.youtube.com/watch?v=X8JD8hHkBMc

class Nativec {
  // ffi.DynamicLibrary nativeLrsLib = Platform.isAndroid
  //     ? ffi.DynamicLibrary.open("libnative_nativec.so")
  //     : (Platform.isWindows)
  //         ? ffi.DynamicLibrary.open("nativec_plugin.dll")
  //         : ffi.DynamicLibrary.process();
  ffi.DynamicLibrary nativeLrsLib = Platform.isAndroid
      ? Platform.isWindows
          ? ffi.DynamicLibrary.open('native_opencv.dll')
          : ffi.DynamicLibrary.open('libnative_opencv.so')
      : ffi.DynamicLibrary.process();

  late PassInput _passInput;
  late PassPointers _passPointers;
  late ChangeNeuronSimulatorProcess _changeNeuronSimulatorProcess;
  late ChangeIsPlayingProcess _changeIsPlayingProcess;
  late ChangeIdxSelectedProcess _changeIdxSelectedProcess;
  late StopThreadProcess _stopThreadProcess;
  late InitializeProcess _initialize;

  static int totalBytes = 200 * 30;

  static ffi.Pointer<ffi.Double>? canvasBuffer1;
  static ffi.Pointer<ffi.Double>? canvasBuffer2;

  static Float64List canvasBufferBytes1 = Float64List(0);
  Float64List canvasBufferBytes2 = Float64List(0);

  static ReceivePort? thresholdPublication;
  static Stream? cPublicationStream;

  // Future<String?> getPlatformVersion() {
  //   //https://docs.flutter.dev/development/platform-integration/macos/c-interop
  //   return NativecPlatform.instance.getPlatformVersion();
  // }

  static ffi.Pointer<ffi.Void>? cookie;
  late var nativeHttpServe;

  Nativec() {
    nativeHttpServe =
        nativeLrsLib.lookupFunction<HttpServeNativeFunction, HttpServeFunction>(
            'nativeSimulationCallback');

    canvasBuffer1 = allocate<ffi.Double>(
        count: totalBytes, sizeOfType: ffi.sizeOf<ffi.Double>());
    // canvasBuffer2 = allocate<ffi.Double>(
    //     count: totalBytes, sizeOfType: ffi.sizeOf<ffi.Double>());

    _passPointers = nativeLrsLib
        .lookup<ffi.NativeFunction<pass_pointers_func>>('passPointers')
        .asFunction();
    _changeNeuronSimulatorProcess = nativeLrsLib
        .lookup<ffi.NativeFunction<change_neuron_simulator_func>>(
            'changeNeuronSimulatorProcess')
        .asFunction();
    _changeIsPlayingProcess = nativeLrsLib
        .lookup<ffi.NativeFunction<change_is_playing_func>>(
            'changeIsPlayingProcess')
        .asFunction();
    _changeIdxSelectedProcess = nativeLrsLib
        .lookup<ffi.NativeFunction<change_is_playing_func>>(
            'changeIdxSelectedProcess')
        .asFunction();
    _stopThreadProcess = nativeLrsLib
        .lookup<ffi.NativeFunction<stop_thread_func>>('stopThreadProcess')
        .asFunction();
    _initialize = nativeLrsLib
        .lookup<ffi.NativeFunction<_initialize_func>>('initialize')
        .asFunction();
    _passInput = nativeLrsLib
        .lookup<ffi.NativeFunction<pass_input_func>>('passInput')
        .asFunction();

    // C++ to Flutter
    // final initializeApi = nativeLrsLib.lookupFunction<
    //     ffi.IntPtr Function(ffi.Pointer<ffi.Void>),
    //     int Function(ffi.Pointer<ffi.Void>)>("InitDartApiDL");
    // final SetThresholdDartPortFunc _setDartPort = nativeLrsLib
    //     .lookup<ffi.NativeFunction<set_threshold_dart_port_func>>(
    //         "set_dart_port")
    //     .asFunction();

    // initializeApi(ffi.NativeApi.initializeApiDLData);
    // thresholdPublication = ReceivePort();
    // cPublicationStream = thresholdPublication!.asBroadcastStream()
    //   ..listen((message) {
    //     print("PRINT C++ MESSAGE : ");
    //     print(message);
    //     // print(_canvasBufferBytes1.getRange(0, 10));
    //     // print(_canvasBufferBytes2);
    //   });
    // _setDartPort(thresholdPublication!.sendPort.nativePort);
    // END C++ to Flutter

    // if (_data == null) {
    //   // _data = allocate<ffi.Int16>(count: totalBytes);
    // }
    // // int byteCount = Nativec.totalBytes;
    // _bytes = _data.asTypedList(Nativec.totalBytes);

    // CHANGE ME
    canvasBufferBytes1 = canvasBuffer1!.asTypedList(totalBytes);
    canvasBufferBytes1.fillRange(0, totalBytes, 0.0);

    // canvasBufferBytes2 = canvasBuffer2!.asTypedList(totalBytes);
    // canvasBufferBytes2.fillRange(0, totalBytes, 0.0);
  }

  // double changeNeuronSimulatorProcess(ffi.Pointer<ffi.Double> a, ffi.Pointer<ffi.Double> b, ffi.Pointer<ffi.Int16> c,
  //   ffi.Pointer<ffi.Int16> d, ffi.Pointer<ffi.Double> i, ffi.Pointer<ffi.Double> w, ffi.Pointer<ffi.Uint16> position, ffi.Pointer<ffi.Double> connectome,
  //   ffi.Pointer<ffi.Int16> neuronCircle,ffi.Pointer<ffi.Int32> nps,int level,int neuronLength, int envelopeSize, int bufferSize, int isPlaying ) {
  //     return _changeNeuronSimulatorProcess(
  //       a,b,c,d,i,w, _canvasBuffer1, _canvasBuffer2, position,connectome,
  //       neuronCircle,nps,level, neuronLength, envelopeSize, bufferSize, isPlaying);
  // }
  double changeNeuronSimulatorProcess(
    ffi.Pointer<ffi.Double> a,
    ffi.Pointer<ffi.Double> b,
    ffi.Pointer<ffi.Int16> c,
    ffi.Pointer<ffi.Int16> d,
    ffi.Pointer<ffi.Double> i,
    ffi.Pointer<ffi.Double> w,
    ffi.Pointer<ffi.Double> connectome,
    int level,
    int neuronLength,
    int envelopeSize,
    int bufferSize,
    int isPlaying,
    ffi.Pointer<ffi.Int16> visPrefs,
    ffi.Pointer<ffi.Double> motorCommandBuf,
    ffi.Pointer<ffi.Double> neuronContactsBuf,
    ffi.Pointer<ffi.Int16> mapNeuronType,
    ffi.Pointer<ffi.Int16> mapDelayNeuron,
    ffi.Pointer<ffi.Int16> mapRhytmicNeuron,
    ffi.Pointer<ffi.Int16> mapCountingNeuron,
  ) {
    double res = _changeNeuronSimulatorProcess(
      a,
      b,
      c,
      d,
      i,
      w,
      connectome,
      level,
      neuronLength,
      envelopeSize,
      bufferSize,
      isPlaying,
      visPrefs,
      motorCommandBuf,
      neuronContactsBuf,
      mapNeuronType,
      mapDelayNeuron,
      mapRhytmicNeuron,
      mapCountingNeuron,
    );
    print("res");
    print(res);
    return res;
  }

// double *_canvasBuffer, short *_positions, short *_neuronCircle,int *_nps,
// int *p_state_buf, short *p_vis_prefs, double *p_vis_pref_vals, uint8_t *p_motor_command_message,double *p_neuron_contacts
  double passPointers(
    ffi.Pointer<ffi.Double> pCanvasbuffer1,
    ffi.Pointer<ffi.Int16> pPositions,
    ffi.Pointer<ffi.Int16> pNeuronCircle,
    ffi.Pointer<ffi.Uint32> pNps,
    ffi.Pointer<ffi.Int32> p_state_buf,
    ffi.Pointer<ffi.Int16> p_vis_prefs,
    ffi.Pointer<ffi.Double> p_vis_pref_vals,
    ffi.Pointer<ffi.Uint8> p_motor_command_message,
    ffi.Pointer<ffi.Double> p_neuron_contacts,
    ffi.Pointer<ffi.Int16> p_dist_prefs,
    ffi.Pointer<ffi.Int16> p_speaker_prefs,
    ffi.Pointer<ffi.Int16> p_microphone_prefs,
    ffi.Pointer<ffi.Int16> p_led_prefs,
    ffi.Pointer<ffi.Int16> p_led_pos_prefs,
  ) {
    var test = _passPointers(
      pCanvasbuffer1,
      pPositions,
      pNeuronCircle,
      pNps,
      p_state_buf,
      p_vis_prefs,
      p_vis_pref_vals,
      p_motor_command_message,
      p_neuron_contacts,
      p_dist_prefs,
      p_speaker_prefs,
      p_microphone_prefs,
      p_led_prefs,
      p_led_pos_prefs,
    );
    // print("pPositions.asTypedList(20)");
    // print(pPositions.asTypedList(20));
    return test;
  }

  int changeIsPlayingProcess(int isPlaying) {
    return _changeIsPlayingProcess(isPlaying);
  }

  int changeIdxSelected(int idxSelected) {
    return _changeIdxSelectedProcess(idxSelected);
  }

  int stopThreadProcess(int idxSelected) {
    return _stopThreadProcess(idxSelected);
  }

  int initialize() {
    return _initialize();
  }

  void simulationCallback(void Function(String) onSimulationCallback) {
    // Create the NativeCallable.listener.
    void onNativeSimulationCallback(ffi.Pointer<Utf8> requestPointer) {
      try {
        onSimulationCallback(requestPointer.toDartString().toString());
      } catch (err) {
        print("ERROR! requestPointer.toDartString");
        print(err);
      }
      // calloc.free(requestPointer);
    }

    // ignore: sdk_version_since
    final callback =
        ffi.NativeCallable<HttpCallback>.listener(onNativeSimulationCallback);
    // ignore: sdk_version_since
    nativeHttpServe(callback.nativeFunction);
    // ignore: sdk_version_since
    callback.keepIsolateAlive = false;
  }

  void passInput(ffi.Pointer<ffi.Double> pSensorDistance) {
    _passInput(
      pSensorDistance,
    );
    return;
  }
}
