/// Web stub for the Nativec class (neural simulation engine).
/// On web, the simulation runs in WASM (compiled from the same NeuronPrototype.cpp
/// used by macOS/iOS). This stub bridges Dart to WASM via dart:js_util.
///
/// The WASM module is loaded in index.html and exposed as window.SpikerSim.module.
/// A polling timer copies WASM heap → Dart typed lists at 60fps so WaveWidget
/// can read waveform data.

import 'dart:async';
import 'dart:typed_data';
import 'dart:js_util' as js_util;
import 'dart:html' as html;

class Nativec {
  static int totalBytes = 10000;
  static dynamic canvasBuffer1;
  static dynamic canvasBuffer2;
  
  static Float64List canvasBufferBytes1 = Float64List(totalBytes);
  static Float64List canvasBufferBytes2 = Float64List(totalBytes);

  // WASM heap pointers (allocated via Module._malloc)
  static int _wasmCanvasBuffer1Ptr = 0;
  static int _wasmCanvasBuffer2Ptr = 0;
  static int _wasmPositionsPtr = 0;
  static int _wasmNeuronCirclePtr = 0;
  static int _wasmNpsPtr = 0;
  static int _wasmStateBufPtr = 0;
  static int _wasmVisPrefsPtr = 0;
  static int _wasmVisPrefValsPtr = 0;
  static int _wasmMotorCommandPtr = 0;
  static int _wasmNeuronContactsPtr = 0;
  static int _wasmDistPrefsPtr = 0;
  static int _wasmSpeakerPtr = 0;
  static int _wasmMicrophonePtr = 0;
  static int _wasmLedPtr = 0;
  static int _wasmLedPosPtr = 0;
  static int _wasmVisualInputPtr = 0;

  // Sensor pointers
  static int _wasmSensorDistancePtr = 0;
  static int _wasmSensorMinLimitPtr = 0;
  static int _wasmSensorMaxLimitPtr = 0;
  static int _wasmSensorMicrophonePtr = 0;
  static int _wasmSensorMicMinLimitPtr = 0;
  static int _wasmSensorMicMaxLimitPtr = 0;
  static int _wasmSensorMicTypePtr = 0;

  // Simulation parameter pointers (stored for live sync)
  static int _wasmAPtr = 0;
  static int _wasmBPtr = 0;
  static int _wasmCPtr = 0;
  static int _wasmDPtr = 0;
  static int _wasmIPtr = 0;
  static int _wasmWPtr = 0;
  static int _wasmConnectomePtr = 0;
  static int _wasmMapNeuronTypePtr = 0;
  static int _wasmMapDelayNeuronPtr = 0;
  static int _wasmMapRhytmicNeuronPtr = 0;
  static int _wasmMapCountingNeuronPtr = 0;

  /// Dart buffer references for live sync to WASM heap
  static Float64List? iBufViewRef;
  static Float64List? aBufViewRef;
  static Float64List? bBufViewRef;
  static Int16List? cBufViewRef;
  static Int16List? dBufViewRef;
  static Float64List? wBufViewRef;
  static Float64List? connectomeBufViewRef;
  static Int16List? mapNeuronTypeBufViewRef;
  static Int16List? mapDelayNeuronBufViewRef;
  static Int16List? mapRhytmicNeuronBufViewRef;
  static Int16List? mapCountingNeuronBufViewRef;
  static Int16List? visPrefsBufViewRef;
  static Float64List? neuronContactsBufViewRef;

  /// Sensor buffer refs for live Dart→WASM sync (distance, microphone, visual input)
  static Float64List? distanceBufViewRef;
  static Float64List? microphoneBufViewRef;
  static Float64List? visualInputBufViewRef;

  /// Neuron pref maps: which neurons are distance/speaker/mic/LED neurons
  static Int16List? neuronDistanceBufViewRef;
  static Int16List? neuronSpeakerBufViewRef;
  static Int16List? neuronMicrophoneBufViewRef;
  static Int16List? neuronLedBufViewRef;
  static Int16List? neuronLedPositionBufViewRef;
  static Int16List? distanceMinLimitBufViewRef;
  static Int16List? distanceMaxLimitBufViewRef;
  static Int16List? microphoneMinLimitBufViewRef;
  static Int16List? microphoneMaxLimitBufViewRef;
  static Int16List? microphoneTypeBufViewRef;

  static int _neuronCount = 0;
  static bool _wasmReady = false;

  /// Positions buffer exposed for WaveWidget to read head position from WASM.
  static Int16List positionsBufView = Int16List(0);

  /// Polling timer that copies WASM heap → Dart buffers at 60fps.
  static Timer? _pollTimer;

  /// JS setInterval ID for calling simulationStep_opencv
  static int _simIntervalId = 0;

  Nativec() {
    canvasBuffer1 ??= Object();
    canvasBuffer2 ??= Object();
    canvasBufferBytes1 = Float64List(totalBytes);
    canvasBufferBytes1.fillRange(0, totalBytes, 0.0);
    canvasBufferBytes2 = Float64List(totalBytes);
    canvasBufferBytes2.fillRange(0, totalBytes, 0.0);
    _checkWasmReady();
  }

  static void _checkWasmReady() {
    try {
      final spikerSim = js_util.getProperty(html.window, 'SpikerSim');
      if (spikerSim != null) {
        _wasmReady = js_util.getProperty(spikerSim, 'ready') == true;
      }
    } catch (e) {
      _wasmReady = false;
    }
  }

  static dynamic get _module {
    _checkWasmReady();
    if (!_wasmReady) return null;
    try {
      final spikerSim = js_util.getProperty(html.window, 'SpikerSim');
      return js_util.getProperty(spikerSim, 'module');
    } catch (e) {
      return null;
    }
  }

  /// Allocate WASM heap memory
  static int _malloc(int bytes) {
    final mod = _module;
    if (mod == null) return 0;
    return js_util.callMethod(mod, '_malloc', [bytes]) as int;
  }

  /// Write Float64List to WASM heap via JS helper.
  /// Dart Float64List IS a JS Float64Array in dart2js — pass directly (zero-copy).
  static void _writeFloat64(int ptr, Float64List data) {
    if (ptr == 0 || data.isEmpty) return;
    js_util.callMethod(html.window, 'writeWasmF64', [ptr, data]);
  }

  /// Write Int16List to WASM heap via JS helper.
  /// Dart Int16List IS a JS Int16Array in dart2js — pass directly (zero-copy).
  static void _writeInt16(int ptr, Int16List data) {
    if (ptr == 0 || data.isEmpty) return;
    js_util.callMethod(html.window, 'writeWasmI16', [ptr, data]);
  }

  /// Start polling WASM heap → Dart buffers at 60fps.
  /// PERFORMANCE: JS helpers now return typed array slices (Float64Array/Int16Array)
  /// which in dart2js ARE Dart Float64List/Int16List. We cast and use setAll()
  /// for O(1) bulk memcpy instead of 10,000+ individual getProperty() calls.
  static bool _pollInProgress = false;
  static bool _canvasBuffer2Active = false; // Gate: only copy buffer 2 when wave chart needs it
  
  static void _startPolling() {
    _pollTimer?.cancel();
    _pollInProgress = false;
    _pollTimer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      // Overrun guard: skip this tick if the previous one hasn't finished.
      // Prevents timer callback stacking when JS event loop is saturated.
      if (_pollInProgress) return;
      _pollInProgress = true;
      
      try {
        // Read positions (head pointer for ring buffer) — 1 JS call + 1 cast + 1 setAll
        if (_wasmPositionsPtr != 0 && positionsBufView.isNotEmpty) {
          final result = js_util.callMethod(html.window, 'readWasmI16', [_wasmPositionsPtr, positionsBufView.length]);
          if (result != null) {
            try {
              final Int16List src = result as Int16List;
              positionsBufView.setAll(0, src);
            } catch (_) {} // Graceful fallback if cast fails
          }
        }
        
        // Read canvas buffer 1 (waveform data) — 1 JS call + 1 cast + 1 setAll
        if (_wasmCanvasBuffer1Ptr != 0 && canvasBufferBytes1.isNotEmpty) {
          final result = js_util.callMethod(html.window, 'readWasmF64', [_wasmCanvasBuffer1Ptr, canvasBufferBytes1.length]);
          if (result != null) {
            try {
              final Float64List src = result as Float64List;
              canvasBufferBytes1.setAll(0, src);
            } catch (_) {}
          }
        }
        
        // Read canvas buffer 2 — ONLY when wave chart channel 2 is active
        if (_canvasBuffer2Active && _wasmCanvasBuffer2Ptr != 0 && canvasBufferBytes2.isNotEmpty) {
          final result = js_util.callMethod(html.window, 'readWasmF64', [_wasmCanvasBuffer2Ptr, canvasBufferBytes2.length]);
          if (result != null) {
            try {
              final Float64List src = result as Float64List;
              canvasBufferBytes2.setAll(0, src);
            } catch (_) {}
          }
        }

        // Sync iBufView → WASM heap (for remote control current injection)
        if (_wasmIPtr != 0 && _neuronCount > 0 && iBufViewRef != null) {
          try { _writeFloat64(_wasmIPtr, iBufViewRef!); } catch (_) {}
        }

        // Sync distance sensor → WASM heap (robot → simulation)
        if (_wasmSensorDistancePtr != 0 && distanceBufViewRef != null) {
          try { _writeFloat64(_wasmSensorDistancePtr, distanceBufViewRef!); } catch (_) {}
        }

        // Sync microphone sensor → WASM heap (robot → simulation)
        if (_wasmSensorMicrophonePtr != 0 && microphoneBufViewRef != null) {
          try { _writeFloat64(_wasmSensorMicrophonePtr, microphoneBufViewRef!); } catch (_) {}
        }

        // Sync visual input → WASM heap (camera color detection → simulation)
        if (_wasmVisualInputPtr != 0 && visualInputBufViewRef != null) {
          try { _writeFloat64(_wasmVisualInputPtr, visualInputBufViewRef!); } catch (_) {}
        }

        // Sync neuron preference maps → WASM heap (which neurons are distance/speaker/mic/LED)
        if (_wasmDistPrefsPtr != 0 && neuronDistanceBufViewRef != null) {
          try { _writeInt16(_wasmDistPrefsPtr, neuronDistanceBufViewRef!); } catch (_) {}
        }
        if (_wasmSpeakerPtr != 0 && neuronSpeakerBufViewRef != null) {
          try { _writeInt16(_wasmSpeakerPtr, neuronSpeakerBufViewRef!); } catch (_) {}
        }
        if (_wasmMicrophonePtr != 0 && neuronMicrophoneBufViewRef != null) {
          try { _writeInt16(_wasmMicrophonePtr, neuronMicrophoneBufViewRef!); } catch (_) {}
        }
        if (_wasmLedPtr != 0 && neuronLedBufViewRef != null) {
          try { _writeInt16(_wasmLedPtr, neuronLedBufViewRef!); } catch (_) {}
        }
        if (_wasmLedPosPtr != 0 && neuronLedPositionBufViewRef != null) {
          try { _writeInt16(_wasmLedPosPtr, neuronLedPositionBufViewRef!); } catch (_) {}
        }
        // Sync sensor limits
        if (_wasmSensorMinLimitPtr != 0 && distanceMinLimitBufViewRef != null) {
          try { _writeInt16(_wasmSensorMinLimitPtr, distanceMinLimitBufViewRef!); } catch (_) {}
        }
        if (_wasmSensorMaxLimitPtr != 0 && distanceMaxLimitBufViewRef != null) {
          try { _writeInt16(_wasmSensorMaxLimitPtr, distanceMaxLimitBufViewRef!); } catch (_) {}
        }
        if (_wasmSensorMicMinLimitPtr != 0 && microphoneMinLimitBufViewRef != null) {
          try { _writeInt16(_wasmSensorMicMinLimitPtr, microphoneMinLimitBufViewRef!); } catch (_) {}
        }
        if (_wasmSensorMicMaxLimitPtr != 0 && microphoneMaxLimitBufViewRef != null) {
          try { _writeInt16(_wasmSensorMicMaxLimitPtr, microphoneMaxLimitBufViewRef!); } catch (_) {}
        }
        if (_wasmSensorMicTypePtr != 0 && microphoneTypeBufViewRef != null) {
          try { _writeInt16(_wasmSensorMicTypePtr, microphoneTypeBufViewRef!); } catch (_) {}
        }
      } finally {
        _pollInProgress = false;
      }
    });
  }

  /// Stop the polling timer.
  static void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  /// Stop the JS simulation step loop.
  static void _stopSimInterval() {
    if (_simIntervalId != 0) {
      js_util.callMethod(html.window, 'clearInterval', [_simIntervalId]);
      _simIntervalId = 0;
    }
  }

  /// Sync ALL Dart-side buffers to WASM heap and call C++ syncSimulationBuffers_opencv
  /// to re-populate the 2D connectome array. This bridges the shared-memory gap
  /// between Dart TypedLists and WASM heap that macOS FFI handles automatically.
  static void syncBuffersToWasm() {
    if (_module == null || _neuronCount <= 0 || !_wasmReady) return;
    final nn = _neuronCount;
    try {
      // Push scalar buffers to WASM heap
      if (_wasmAPtr != 0 && aBufViewRef != null) _writeFloat64(_wasmAPtr, aBufViewRef!);
      if (_wasmBPtr != 0 && bBufViewRef != null) _writeFloat64(_wasmBPtr, bBufViewRef!);
      if (_wasmCPtr != 0 && cBufViewRef != null) _writeInt16(_wasmCPtr, cBufViewRef!);
      if (_wasmDPtr != 0 && dBufViewRef != null) _writeInt16(_wasmDPtr, dBufViewRef!);
      if (_wasmIPtr != 0 && iBufViewRef != null) _writeFloat64(_wasmIPtr, iBufViewRef!);
      if (_wasmWPtr != 0 && wBufViewRef != null) _writeFloat64(_wasmWPtr, wBufViewRef!);
      if (_wasmConnectomePtr != 0 && connectomeBufViewRef != null) _writeFloat64(_wasmConnectomePtr, connectomeBufViewRef!);
      if (_wasmMapNeuronTypePtr != 0 && mapNeuronTypeBufViewRef != null) _writeInt16(_wasmMapNeuronTypePtr, mapNeuronTypeBufViewRef!);
      if (_wasmMapDelayNeuronPtr != 0 && mapDelayNeuronBufViewRef != null) _writeInt16(_wasmMapDelayNeuronPtr, mapDelayNeuronBufViewRef!);
      if (_wasmMapRhytmicNeuronPtr != 0 && mapRhytmicNeuronBufViewRef != null) _writeInt16(_wasmMapRhytmicNeuronPtr, mapRhytmicNeuronBufViewRef!);
      if (_wasmMapCountingNeuronPtr != 0 && mapCountingNeuronBufViewRef != null) _writeInt16(_wasmMapCountingNeuronPtr, mapCountingNeuronBufViewRef!);

      // Call C++ syncSimulationBuffers_opencv to re-populate 2D connectome array
      // and update guidedDelayList neuron types
      js_util.callMethod(_module!, 'ccall', [
        'syncSimulationBuffers_opencv',
        'null', // void return
        js_util.jsify(['number', 'number', 'number', 'number', 'number', 'number', 'number', 'number', 'number', 'number', 'number', 'number']),
        js_util.jsify([_wasmAPtr, _wasmBPtr, _wasmCPtr, _wasmDPtr, _wasmIPtr, _wasmWPtr, _wasmConnectomePtr, nn, _wasmMapNeuronTypePtr, _wasmMapDelayNeuronPtr, _wasmMapRhytmicNeuronPtr, _wasmMapCountingNeuronPtr]),
      ]);
      print('SpikerSim: syncBuffersToWasm completed for $nn neurons');
    } catch (e) {
      print('SpikerSim: syncBuffersToWasm error: $e');
    }
  }

  double changeNeuronSimulatorProcess(
    dynamic a, dynamic b, dynamic c, dynamic d,
    dynamic i, dynamic w, dynamic connectome,
    int level, int neuronLength, int envelopeSize,
    int bufferSize, int isPlaying,
    dynamic visPrefs, dynamic motorCommandBuf,
    dynamic neuronContactsBuf,
    dynamic mapNeuronType, dynamic mapDelayNeuron,
    dynamic mapRhytmicNeuron, dynamic mapCountingNeuron,
  ) {
    print('SpikerSim: ENTER changeNeuronSimulatorProcess, neuronLength=$neuronLength');
    // Force immediate WASM readiness check (bypass polling interval)
    _wasmReady = false;
    _checkWasmReady();
    if (!_wasmReady) {
      // Direct check: Module may be ready but polling hasn't fired yet
      try {
        final directMod = js_util.getProperty(html.window, 'Module');
        if (directMod != null && js_util.hasProperty(directMod, 'ccall')) {
          // Module is ready — set it up directly
          final spikerSim = js_util.getProperty(html.window, 'SpikerSim');
          js_util.setProperty(spikerSim, 'module', directMod);
          js_util.setProperty(spikerSim, 'ready', true);
          _wasmReady = true;
          print('SpikerSim: Module found via direct check!');
        }
      } catch (e) {
        print('SpikerSim: Direct Module check failed: $e');
      }
    }
    dynamic mod = _module;
    if (mod == null) {
      print('SpikerSim: WASM module not ready!');
      return 0.0;
    }

    _neuronCount = neuronLength;
    final nn = neuronLength;
    final nn2 = nn * nn;

    // Allocate WASM heap for parameters and store pointers for live sync
    final wasmAPtr = _malloc(nn * 8); _wasmAPtr = wasmAPtr;
    final wasmBPtr = _malloc(nn * 8); _wasmBPtr = wasmBPtr;
    final wasmCPtr = _malloc(nn * 2); _wasmCPtr = wasmCPtr;
    final wasmDPtr = _malloc(nn * 2); _wasmDPtr = wasmDPtr;
    final wasmIPtr = _malloc(nn * 8); _wasmIPtr = wasmIPtr;
    final wasmWPtr = _malloc(nn * 8); _wasmWPtr = wasmWPtr;
    final wasmConnectomePtr = _malloc(nn2 * 8); _wasmConnectomePtr = wasmConnectomePtr;
    final wasmMapNeuronTypePtr = _malloc(nn * 2); _wasmMapNeuronTypePtr = wasmMapNeuronTypePtr;
    final wasmMapDelayNeuronPtr = _malloc(nn * 2); _wasmMapDelayNeuronPtr = wasmMapDelayNeuronPtr;
    final wasmMapRhytmicNeuronPtr = _malloc(nn * 2); _wasmMapRhytmicNeuronPtr = wasmMapRhytmicNeuronPtr;
    final wasmMapCountingNeuronPtr = _malloc(nn * 2); _wasmMapCountingNeuronPtr = wasmMapCountingNeuronPtr;

    // Copy Dart data to WASM heap
    if (a is Float64List) _writeFloat64(wasmAPtr, a);
    if (b is Float64List) _writeFloat64(wasmBPtr, b);
    if (c is Int16List) _writeInt16(wasmCPtr, c);
    if (d is Int16List) _writeInt16(wasmDPtr, d);
    if (i is Float64List) _writeFloat64(wasmIPtr, i);
    if (w is Float64List) _writeFloat64(wasmWPtr, w);
    if (connectome is Float64List) {
      // Debug: Check connectome weights including sign
      int nonZero = 0;
      int negCount = 0;
      for (int k = 0; k < connectome.length; k++) {
        if (connectome[k] != 0.0) {
          nonZero++;
          if (connectome[k] < 0) negCount++;
        }
      }
      print('SpikerSim: connectome has $nonZero non-zero ($negCount negative) weights out of ${connectome.length}');
      // Dump connectome matrix for debugging (small brains only)
      if (nn <= 20) {
        for (int row = 0; row < nn; row++) {
          String rowStr = 'CONN[$row]: ';
          for (int col = 0; col < nn; col++) {
            double val = connectome[row * nn + col];
            if (val != 0) rowStr += 'c$col=${val.toStringAsFixed(1)} ';
          }
          if (rowStr.contains('=')) print(rowStr);
        }
      }
      _writeFloat64(wasmConnectomePtr, connectome);
    }
    if (visPrefs is Int16List && _wasmVisPrefsPtr != 0) _writeInt16(_wasmVisPrefsPtr, visPrefs);
    if (neuronContactsBuf is Float64List && _wasmNeuronContactsPtr != 0) _writeFloat64(_wasmNeuronContactsPtr, neuronContactsBuf);
    if (mapNeuronType is Int16List) {
      // Debug: Dump neuronType values (>=1000 means inhibitory)
      print('SpikerSim: neuronTypes (>=1000=inhibitory):');
      for (int k = 0; k < nn; k++) {
        print('  neuron[$k] type=${mapNeuronType[k]} ${mapNeuronType[k] >= 1000 ? "INHIBITORY" : "excitatory"}');
      }
      _writeInt16(wasmMapNeuronTypePtr, mapNeuronType);
    }
    if (mapDelayNeuron is Int16List) _writeInt16(wasmMapDelayNeuronPtr, mapDelayNeuron);
    if (mapRhytmicNeuron is Int16List) _writeInt16(wasmMapRhytmicNeuronPtr, mapRhytmicNeuron);
    if (mapCountingNeuron is Int16List) _writeInt16(wasmMapCountingNeuronPtr, mapCountingNeuron);

    print('SpikerSim: Calling changeNeuronSimulatorProcess_opencv with $nn neurons');
    print('SpikerSim: ptrs A=$wasmAPtr B=$wasmBPtr C=$wasmCPtr vis=$_wasmVisPrefsPtr motor=$_wasmMotorCommandPtr contacts=$_wasmNeuronContactsPtr');
    // DIAGNOSTIC: Dump ABCD/I values being sent to WASM
    if (a is Float64List && b is Float64List && c is Int16List && d is Int16List && i is Float64List) {
      for (int k = 0; k < nn; k++) {
        print('SpikerSim INIT: neuron[$k] a=${a[k]} b=${b[k]} c=${c[k]} d=${d[k]} i=${i[k]} type=${mapNeuronType is Int16List ? mapNeuronType[k] : "?"}');
      }
    }

    // Call the C function via ccall
    try {
      js_util.callMethod(mod, 'ccall', [
        'changeNeuronSimulatorProcess_opencv',
        'number',
        js_util.jsify(['number','number','number','number','number','number','number',
         'number','number','number','number','number',
         'number','number','number',
         'number','number','number','number']),
        js_util.jsify([wasmAPtr, wasmBPtr, wasmCPtr, wasmDPtr, wasmIPtr, wasmWPtr, wasmConnectomePtr,
         level, neuronLength, envelopeSize, bufferSize, isPlaying,
         _wasmVisPrefsPtr, _wasmMotorCommandPtr, _wasmNeuronContactsPtr,
         wasmMapNeuronTypePtr, wasmMapDelayNeuronPtr, wasmMapRhytmicNeuronPtr, wasmMapCountingNeuronPtr]),
      ]);
      print('SpikerSim: changeNeuronSimulatorProcess_opencv SUCCEEDED');

      // Time-calibrated batch simulation using Dart DateTime
      // Measures actual elapsed ms → consistent speed across all devices
      _stopSimInterval();
      int lastTimeMs = DateTime.now().millisecondsSinceEpoch;
      
      _simIntervalId = js_util.callMethod(html.window, 'setInterval', [
        js_util.allowInterop(() {
          try {
            final nowMs = DateTime.now().millisecondsSinceEpoch;
            final elapsed = nowMs - lastTimeMs;
            lastTimeMs = nowMs;
            
            // Run 1 step per elapsed ms (matching native 1 step/ms rate)
            // Clamp to prevent runaway if tab was backgrounded then refocused
            final steps = elapsed.clamp(1, 30);
            js_util.callMethod(mod, 'ccall', [
              'simulationBatchStep_opencv', 'number',
              js_util.jsify(['number']), js_util.jsify([steps])
            ]);
          } catch (e) {
            print('SpikerSim: batchStep error: $e');
          }
        }),
        8, // 8ms interval — 125Hz with auto-calibrated step count = 1000 steps/sec
      ]) as int;
      print('SpikerSim: Started time-calibrated simulation interval');
    } catch (e) {
      print('SpikerSim: changeNeuronSimulatorProcess_opencv FAILED: $e');
    }

    // Start polling WASM→Dart after simulation starts
    _startPolling();

    return 0.0;
  }

  double passPointers(
    dynamic pCanvasbuffer1, dynamic pPositions,
    dynamic pNeuronCircle, dynamic pNps,
    dynamic p_state_buf, dynamic p_vis_prefs,
    dynamic p_vis_pref_vals, dynamic p_motor_command_message,
    dynamic p_neuron_contacts, dynamic p_dist_prefs,
    dynamic p_speaker_prefs, dynamic p_microphone_prefs,
    dynamic p_led_prefs, dynamic p_led_pos_prefs,
    dynamic p_visual_input,
  ) {
    // Force immediate WASM readiness check
    _wasmReady = false;
    _checkWasmReady();
    if (!_wasmReady) {
      try {
        final directMod = js_util.getProperty(html.window, 'Module');
        if (directMod != null && js_util.hasProperty(directMod, 'ccall')) {
          final spikerSim = js_util.getProperty(html.window, 'SpikerSim');
          js_util.setProperty(spikerSim, 'module', directMod);
          js_util.setProperty(spikerSim, 'ready', true);
          _wasmReady = true;
          print('SpikerSim: passPointers - Module found via direct check');
        }
      } catch (e) {
        print('SpikerSim: passPointers direct check failed: $e');
      }
    }
    final mod = _module;
    if (mod == null) {
      print('SpikerSim: WASM module not ready for passPointers!');
      return 0.0;
    }

    // Allocate all buffer pointers in WASM heap
    _wasmCanvasBuffer1Ptr = _malloc(totalBytes * 8);
    _wasmCanvasBuffer2Ptr = _malloc(totalBytes * 8);
    _wasmPositionsPtr = _malloc(200 * 2);
    _wasmNeuronCirclePtr = _malloc(200 * 2);
    _wasmNpsPtr = _malloc(2 * 4);
    _wasmStateBufPtr = _malloc(10 * 4);
    _wasmVisPrefsPtr = _malloc(200 * 200 * 2);
    _wasmVisPrefValsPtr = _malloc(200 * 8);
    _wasmMotorCommandPtr = _malloc(100 * 8);
    _wasmNeuronContactsPtr = _malloc(200 * 200 * 8);
    _wasmDistPrefsPtr = _malloc(200 * 2);
    _wasmSpeakerPtr = _malloc(200 * 200 * 2);
    _wasmMicrophonePtr = _malloc(200 * 200 * 2);
    _wasmLedPtr = _malloc(200 * 200 * 2);
    _wasmLedPosPtr = _malloc(200 * 200 * 2);
    _wasmVisualInputPtr = _malloc(200 * 80 * 8);

    // Initialize positionsBufView to point at our polling target
    positionsBufView = Int16List(200);

    print('SpikerSim: passPointers allocated WASM buffers, cb1=$_wasmCanvasBuffer1Ptr pos=$_wasmPositionsPtr');

    // Call passPointers_opencv
    try {
      js_util.callMethod(mod, 'ccall', [
        'passPointers_opencv',
        'number',
        js_util.jsify(List.generate(16, (_) => 'number')),
        js_util.jsify([_wasmCanvasBuffer1Ptr, _wasmCanvasBuffer2Ptr, _wasmPositionsPtr, _wasmNeuronCirclePtr,
         _wasmNpsPtr, _wasmStateBufPtr, _wasmVisPrefsPtr, _wasmVisPrefValsPtr,
         _wasmMotorCommandPtr, _wasmNeuronContactsPtr, _wasmDistPrefsPtr,
         _wasmSpeakerPtr, _wasmMicrophonePtr, _wasmLedPtr, _wasmLedPosPtr, _wasmVisualInputPtr]),
      ]);
      print('SpikerSim: passPointers_opencv SUCCEEDED');
    } catch (e) {
      print('SpikerSim: passPointers_opencv FAILED: $e');
    }

    return 0.0;
  }

  int changeIsPlayingProcess(int isPlaying) {
    final mod = _module;
    if (mod == null) return 0;
    try {
      js_util.callMethod(mod, 'changeIsPlayingProcess', [isPlaying]);
    } catch (e) {
      js_util.callMethod(mod, 'ccall', [
        'changeIsPlayingProcess_opencv', 'number',
        js_util.jsify(['number']), js_util.jsify([isPlaying])
      ]);
    }
    if (isPlaying == -1) {
      // Pausing: stop simulation and polling
      _stopSimInterval();
      _stopPolling();
    }
    return 0;
  }

  int changeIdxSelected(int idxSelected) {
    final mod = _module;
    if (mod == null) return 0;
    try {
      js_util.callMethod(mod, 'changeIdxSelectedProcess', [idxSelected]);
    } catch (e) {
      js_util.callMethod(mod, 'ccall', [
        'changeIdxSelectedProcess_opencv', 'number',
        js_util.jsify(['number']), js_util.jsify([idxSelected])
      ]);
    }
    return 0;
  }

  int changeIdxSelected2(int idxSelected2) {
    // Gate buffer 2 polling: only copy 10K doubles when channel 2 is in use
    _canvasBuffer2Active = idxSelected2 >= 0;
    final mod = _module;
    if (mod == null) return 0;
    try {
      js_util.callMethod(mod, 'changeIdxSelected2Process', [idxSelected2]);
    } catch (e) {
      js_util.callMethod(mod, 'ccall', [
        'changeIdxSelected2Process_opencv', 'number',
        js_util.jsify(['number']), js_util.jsify([idxSelected2])
      ]);
    }
    return 0;
  }

  int stopThreadProcess(int idxSelected) {
    final mod = _module;
    if (mod == null) return 0;
    _stopPolling();
    _stopSimInterval();
    try {
      js_util.callMethod(mod, 'stopThreadProcess', [idxSelected]);
    } catch (e) {
      js_util.callMethod(mod, 'ccall', [
        'stopThreadProcess_opencv', 'number',
        js_util.jsify(['number']), js_util.jsify([idxSelected])
      ]);
    }
    return 0;
  }

  int initialize() {
    final mod = _module;
    if (mod == null) return 0;
    try {
      js_util.callMethod(mod, 'initialize', []);
    } catch (e) {
      js_util.callMethod(mod, 'ccall', [
        'initialize_opencv', 'number',
        js_util.jsify([]), js_util.jsify([])
      ]);
    }
    return 0;
  }

  void simulationCallback(void Function(String) onSimulationCallback) {
    // Register the Dart callback via JS global
    try {
      final spikerSim = js_util.getProperty(html.window, 'SpikerSim');
      if (spikerSim != null) {
        js_util.setProperty(spikerSim, 'motorCallbackFn',
          js_util.allowInterop((String msg) {
            onSimulationCallback(msg);
          })
        );
      }
    } catch (e) {
      print('simulationCallback registration failed: $e');
    }
  }

  void passInput(
    dynamic pSensorDistance, dynamic pSensorMinLimit,
    dynamic pSensorMaxLimit, dynamic pSensorMicrophone,
    dynamic pSensorMicMinLimit, dynamic pSensorMicMaxLimit,
    dynamic pSensorMicType,
  ) {
    final mod = _module;
    if (mod == null) return;

    if (_wasmSensorDistancePtr == 0) {
      _wasmSensorDistancePtr = _malloc(200 * 8);
      _wasmSensorMinLimitPtr = _malloc(200 * 2);
      _wasmSensorMaxLimitPtr = _malloc(200 * 2);
      _wasmSensorMicrophonePtr = _malloc(200 * 8);
      _wasmSensorMicMinLimitPtr = _malloc(200 * 2);
      _wasmSensorMicMaxLimitPtr = _malloc(200 * 2);
      _wasmSensorMicTypePtr = _malloc(200 * 2);
    }

    if (pSensorDistance is Float64List) _writeFloat64(_wasmSensorDistancePtr, pSensorDistance);
    if (pSensorMinLimit is Int16List) _writeInt16(_wasmSensorMinLimitPtr, pSensorMinLimit);
    if (pSensorMaxLimit is Int16List) _writeInt16(_wasmSensorMaxLimitPtr, pSensorMaxLimit);
    if (pSensorMicrophone is Float64List) _writeFloat64(_wasmSensorMicrophonePtr, pSensorMicrophone);
    if (pSensorMicMinLimit is Int16List) _writeInt16(_wasmSensorMicMinLimitPtr, pSensorMicMinLimit);
    if (pSensorMicMaxLimit is Int16List) _writeInt16(_wasmSensorMicMaxLimitPtr, pSensorMicMaxLimit);
    if (pSensorMicType is Int16List) _writeInt16(_wasmSensorMicTypePtr, pSensorMicType);

    js_util.callMethod(mod, 'ccall', [
      'passInput_opencv', 'number',
      js_util.jsify(List.generate(7, (_) => 'number')),
      js_util.jsify([_wasmSensorDistancePtr, _wasmSensorMinLimitPtr, _wasmSensorMaxLimitPtr,
       _wasmSensorMicrophonePtr, _wasmSensorMicMinLimitPtr, _wasmSensorMicMaxLimitPtr,
       _wasmSensorMicTypePtr]),
    ]);
  }
}
