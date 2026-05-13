/// Stub implementation of dart:isolate types for web platform.
/// On web, Isolate isn't available — we use Web Workers instead.
/// These stubs allow code to compile; actual web behavior is
/// handled by kIsWeb guards redirecting to Web Workers.

import 'dart:async';

class Isolate {
  static Future<Isolate> spawn<T>(void Function(T) entryPoint, T message) async {
    // Web stub — actual web implementation uses Web Workers
    return Isolate._();
  }
  Isolate._();
  
  void kill({int priority = 0}) {}
  
  static const int immediate = 0;
  static const int beforeNextEvent = 1;
}

class SendPort {
  void send(dynamic message) {}
}

class ReceivePort {
  SendPort get sendPort => SendPort();
  
  StreamSubscription<dynamic> listen(
    void Function(dynamic)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return _StubStreamSubscription();
  }
  
  void close() {}
}

class RootIsolateToken {
  static RootIsolateToken? instance;
}

/// Stub StreamSubscription for web ReceivePort
class _StubStreamSubscription implements StreamSubscription<dynamic> {
  @override
  Future<void> cancel() async {}
  @override
  void onData(void Function(dynamic)? handleData) {}
  @override
  void onError(Function? handleError) {}
  @override
  void onDone(void Function()? handleDone) {}
  @override
  void pause([Future<void>? resumeSignal]) {}
  @override
  void resume() {}
  @override
  bool get isPaused => false;
  @override
  Future<E> asFuture<E>([E? futureValue]) => Future.value(futureValue as E);
}
