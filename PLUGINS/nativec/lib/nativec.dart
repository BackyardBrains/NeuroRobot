import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:nativec/allocation.dart';

import 'nativec_platform_interface.dart';
import 'dart:ffi' as ffi;
// import 'package:ffi/ffi.dart';


typedef stop_thread_func = ffi.Int16 Function(ffi.Int16);
typedef StopThreadProcess = int Function(int);
typedef change_is_playing_func = ffi.Int16 Function(ffi.Int16);
typedef ChangeIsPlayingProcess = int Function(int);
typedef change_idx_selected_func = ffi.Int16 Function(ffi.Int16);
typedef ChangeIdxSelectedProcess = int Function(int);

typedef change_neuron_simulator_func = ffi.Double Function(
  ffi.Pointer<ffi.Double>,
  ffi.Pointer<ffi.Double>,
  ffi.Pointer<ffi.Int16>,
  ffi.Pointer<ffi.Int16>,
  ffi.Pointer<ffi.Int16>,
  ffi.Pointer<ffi.Double>,
  ffi.Pointer<ffi.Double>,
  ffi.Pointer<ffi.Double>,
  ffi.Pointer<ffi.Uint16>,
  ffi.Pointer<ffi.Double>,

  ffi.Int16,
  ffi.Uint32,    
  ffi.Uint32,    
  ffi.Uint32,    
  ffi.Int16,    

);
typedef ChangeNeuronSimulatorProcess = double Function(
    ffi.Pointer<ffi.Double>, // a
    ffi.Pointer<ffi.Double>, // b
    ffi.Pointer<ffi.Int16>, // c
    ffi.Pointer<ffi.Int16>, // d
    ffi.Pointer<ffi.Int16>, // i
    ffi.Pointer<ffi.Double>, // w

    ffi.Pointer<ffi.Double>, // canvas buffer neuron 1
    ffi.Pointer<ffi.Double>, // canvas buffer neuron 2
    ffi.Pointer<ffi.Uint16>, // position
    ffi.Pointer<ffi.Double>, //connectome
    int, // level
    int, // neuron length
    int, // envelope size
    int, // buffer size
    int, // isPlaying
    
    ); 

typedef set_threshold_dart_port_func = ffi.Double Function(ffi.Int64);
typedef SetThresholdDartPortFunc = double Function(int);



// Low Pass filter sample https://www.youtube.com/watch?v=X8JD8hHkBMc
class Nativec {
  ffi.DynamicLibrary nativeLrsLib = Platform.isAndroid
      ? ffi.DynamicLibrary.open("libnative_nativec.so")
      : (Platform.isWindows)
          ? ffi.DynamicLibrary.open("nativec_plugin.dll")
          : ffi.DynamicLibrary.process();
  
  late ChangeNeuronSimulatorProcess _changeNeuronSimulatorProcess;
  late ChangeIsPlayingProcess _changeIsPlayingProcess;
  late ChangeIdxSelectedProcess _changeIdxSelectedProcess;
  late StopThreadProcess _stopThreadProcess;

  static int totalBytes = 200*30;

  static ffi.Pointer<ffi.Double> _canvasBuffer1 = allocate<ffi.Double>(
      count: totalBytes, sizeOfType: ffi.sizeOf<ffi.Double>());
  static ffi.Pointer<ffi.Double> _canvasBuffer2 = allocate<ffi.Double>(
      count: totalBytes, sizeOfType: ffi.sizeOf<ffi.Double>());

  static Float64List canvasBufferBytes1  = Float64List(0);
  static Float64List canvasBufferBytes2  = Float64List(0);

  static ReceivePort? thresholdPublication;
  static Stream? cPublicationStream;

  Future<String?> getPlatformVersion() {
    //https://docs.flutter.dev/development/platform-integration/macos/c-interop
    return NativecPlatform.instance.getPlatformVersion();
  }

  static ffi.Pointer<ffi.Void>? cookie;

  Nativec() {
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
        .lookup<ffi.NativeFunction<stop_thread_func>>(
            'stopThreadProcess')
        .asFunction();
    // C++ to Flutter
    final initializeApi = nativeLrsLib.lookupFunction<
        ffi.IntPtr Function(ffi.Pointer<ffi.Void>),
        int Function(ffi.Pointer<ffi.Void>)>("InitDartApiDL");
    final SetThresholdDartPortFunc _setDartPort = nativeLrsLib
        .lookup<ffi.NativeFunction<set_threshold_dart_port_func>>(
            "set_dart_port")
        .asFunction();

    initializeApi(ffi.NativeApi.initializeApiDLData);
    thresholdPublication = ReceivePort();
    cPublicationStream = thresholdPublication!.asBroadcastStream();
      // ..listen((message) {
      //   print("PRINT C++ MESSAGE : ");
      //   print(message);
      //   // print(_canvasBufferBytes1.getRange(0, 10));
      //   // print(_canvasBufferBytes2);
      // });
    _setDartPort(thresholdPublication!.sendPort.nativePort);
    // END C++ to Flutter

    // if (_data == null) {
    //   // _data = allocate<ffi.Int16>(count: totalBytes);
    // }
    // // int byteCount = Nativec.totalBytes;
    // _bytes = _data.asTypedList(Nativec.totalBytes);
    canvasBufferBytes1 = _canvasBuffer1.asTypedList(totalBytes);
    canvasBufferBytes2 = _canvasBuffer2.asTypedList(totalBytes);
    
    canvasBufferBytes1.fillRange(0, totalBytes,0.0);
    canvasBufferBytes2.fillRange(0, totalBytes,0.0);
  }

  double changeNeuronSimulatorProcess(ffi.Pointer<ffi.Double> a, ffi.Pointer<ffi.Double> b, ffi.Pointer<ffi.Int16> c,
    ffi.Pointer<ffi.Int16> d, ffi.Pointer<ffi.Int16> i, ffi.Pointer<ffi.Double> w, ffi.Pointer<ffi.Uint16> position, ffi.Pointer<ffi.Double> connectome,
    int level,int neuronLength, int envelopeSize, int bufferSize, int isPlaying ) {
      print("connectome");
      // return 0;
      return _changeNeuronSimulatorProcess(
        a,b,c,d,i,w, _canvasBuffer1, _canvasBuffer2, position,connectome,
        level, neuronLength, envelopeSize, bufferSize, isPlaying);
  }

  int changeIsPlayingProcess(int isPlaying){
    return _changeIsPlayingProcess(isPlaying);
  }
  int changeIdxSelected(int idxSelected){
    return _changeIdxSelectedProcess(idxSelected);
  }
  int stopThreadProcess(int idxSelected){
    return _stopThreadProcess(idxSelected);
  }
}
