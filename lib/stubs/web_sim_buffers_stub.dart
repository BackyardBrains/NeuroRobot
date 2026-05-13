import 'dart:typed_data';

/// Native stub — returns false so caller runs the FFI path.
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
  return false; // Native: use FFI path
}
