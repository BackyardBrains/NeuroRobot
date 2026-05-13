import 'dart:typed_data';
import 'package:spikerbot/stubs/nativec_stub.dart';
import 'package:spikerbot/utils/WaveWidget.dart';

/// Web implementation — passes typed lists directly to the WASM-backed stub.
/// Returns true so caller skips the FFI path.
bool runWebSimulation(
  dynamic nativec,
  void Function(String) callback,
  Float64List aBuf, Float64List bBuf, Int16List cBuf, Int16List dBuf,
  Float64List iBuf, Float64List wBuf, Float64List connectomeBuf,
  int level, int neuronSize, int envelopeSize, int bufferSize,
  Int16List visPrefsBuf, Float64List motorCommandBuf, Float64List neuronContactsBuf,
  Int16List mapNeuronTypeBuf, Int16List mapDelayNeuronBuf,
  Int16List mapRhytmicNeuronBuf, Int16List mapCountingNeuronBuf,
) {
  print('WEB_SIM: runWebSimulation called, neuronSize=$neuronSize');
  
  try {
    final stub = nativec as Nativec;
    print('WEB_SIM: stub cast OK');

    // Allocate WASM heap buffers (passPointers) before starting the simulation
    stub.passPointers(
      null, null, null, null, null, null, null, null, null, null, null, null, null, null, null,
    );
    print('WEB_SIM: passPointers done');

    // Link WaveWidget.positionsBufView to the stub's polling target
    WaveWidget.positionsBufView = Nativec.positionsBufView;
    print('WEB_SIM: positionsBufView linked, length=${Nativec.positionsBufView.length}');

    // Register the Dart motor callback with WASM
    stub.simulationCallback(callback);
    print('WEB_SIM: simulationCallback done');

    // Pass typed lists to the WASM-backed stub
    print('WEB_SIM: calling changeNeuronSimulatorProcess...');
    print('WEB_SIM: aBuf.len=${aBuf.length} bBuf.len=${bBuf.length} cBuf.len=${cBuf.length} connectome.len=${connectomeBuf.length}');
    
    stub.changeNeuronSimulatorProcess(
      aBuf, bBuf, cBuf, dBuf, iBuf, wBuf, connectomeBuf,
      level, neuronSize, envelopeSize, bufferSize, 1,
      visPrefsBuf, motorCommandBuf, neuronContactsBuf,
      mapNeuronTypeBuf, mapDelayNeuronBuf, mapRhytmicNeuronBuf, mapCountingNeuronBuf,
    );
    print('WEB_SIM: changeNeuronSimulatorProcess DONE');
  } catch (e, stack) {
    print('WEB_SIM: ERROR: $e');
    print('WEB_SIM: STACK: $stack');
  }

  return true; // Web: skip FFI path
}
