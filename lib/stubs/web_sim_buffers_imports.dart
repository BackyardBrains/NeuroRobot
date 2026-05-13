/// Conditional import for web simulation startup.
/// On web: calls WASM changeNeuronSimulatorProcess with typed lists.
/// On native: no-op (native uses FFI pointers directly).
export 'web_sim_buffers_stub.dart'
    if (dart.library.html) 'web_sim_buffers_web.dart';
