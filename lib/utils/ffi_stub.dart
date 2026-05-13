/// Stub implementation of dart:ffi types for web platform.
/// These are type-compatible stubs so that code using `ffi.Pointer<ffi.Double>`
/// can compile on web without modifications.

import 'dart:typed_data';

// Stub NativeType hierarchy
abstract class NativeType {}
abstract class NativeInteger extends NativeType {}
abstract class NativeDouble extends NativeType {}

class Int8 extends NativeInteger {}
class Int16 extends NativeInteger {}
class Int32 extends NativeInteger {}
class Int64 extends NativeInteger {}
class Uint8 extends NativeInteger {}
class Uint16 extends NativeInteger {}
class Uint32 extends NativeInteger {}
class Uint64 extends NativeInteger {}
class Float extends NativeDouble {}
class Double extends NativeDouble {}
class Int extends NativeInteger {}
class IntPtr extends NativeInteger {}
class Void extends NativeType {}
class Bool extends NativeType {}
class Opaque extends NativeType {}

/// Stub Pointer class — no asTypedList here; extensions provide
/// type-specific versions that return the correct TypedData list.
class Pointer<T extends NativeType> {
  final int address;
  Pointer._(this.address);
  
  factory Pointer.fromAddress(int address) => Pointer._(address);
  
  /// Cast to another pointer type
  Pointer<U> cast<U extends NativeType>() => Pointer<U>.fromAddress(address);

  static Pointer<Never> get nullptr => Pointer._(0);
}

/// Stub nullptr
final Pointer<Never> nullptr = Pointer<Never>.fromAddress(0);

/// Stub sizeOf
int sizeOf<T extends NativeType>() => 8;

/// Extensions that return the correct TypedData types, matching real dart:ffi behavior
extension Uint8Pointer on Pointer<Uint8> {
  Uint8List asTypedList(int length) => Uint8List(length);
  int get value => 0;
  void set value(int v) {}
  int operator [](int index) => 0;
  void operator []=(int index, int value) {}
}

extension Int16Pointer on Pointer<Int16> {
  Int16List asTypedList(int length) => Int16List(length);
  int get value => 0;
  void set value(int v) {}
  int operator [](int index) => 0;
  void operator []=(int index, int value) {}
}

extension Int32Pointer on Pointer<Int32> {
  Int32List asTypedList(int length) => Int32List(length);
  int get value => 0;
  void set value(int v) {}
  int operator [](int index) => 0;
  void operator []=(int index, int value) {}
}

extension Uint16Pointer on Pointer<Uint16> {
  Uint16List asTypedList(int length) => Uint16List(length);
  int get value => 0;
  void set value(int v) {}
}

extension Uint32Pointer on Pointer<Uint32> {
  Uint32List asTypedList(int length) => Uint32List(length);
  int get value => 0;
  void set value(int v) {}
}

extension Float32Pointer on Pointer<Float> {
  Float32List asTypedList(int length) => Float32List(length);
  double get value => 0.0;
  void set value(double v) {}
}

extension Float64Pointer on Pointer<Double> {
  Float64List asTypedList(int length) => Float64List(length);
  double get value => 0.0;
  void set value(double v) {}
}

extension Int64Pointer on Pointer<Int64> {
  int get value => 0;
  void set value(int v) {}
}

/// Stub DynamicLibrary
class DynamicLibrary {
  DynamicLibrary.process();
  DynamicLibrary.open(String name);
  DynamicLibrary.executable();
  
  Pointer<T> lookup<T extends NativeType>(String symbolName) => Pointer<T>.fromAddress(0);
  F lookupFunction<T extends Function, F extends Function>(String symbolName) {
    throw UnsupportedError('dart:ffi not available on web');
  }
}

/// Stub Allocator
abstract class Allocator {
  Pointer<T> allocate<T extends NativeType>(int byteCount, {int? alignment});
  void free(Pointer<NativeType> pointer);
}

/// Stub NativeCallable
class NativeCallable<T extends Function> {
  NativeCallable.listener(Function callback);
  Pointer<NativeFunction<T>> get nativeFunction => Pointer<NativeFunction<T>>.fromAddress(0);
  bool keepIsolateAlive = false;
}

/// Stub NativeFunction
class NativeFunction<T extends Function> extends NativeType {}

/// Stub NativeApi
class NativeApi {
  static Pointer<Void> get initializeApiDLData => Pointer<Void>.fromAddress(0);
}

/// Stub NativeFinalizer
class NativeFinalizer {
  NativeFinalizer(Pointer<NativeFinalizerFunction> callback);
  void attach(Object value, Pointer<Void> token, {Object? detach, int? externalSize}) {}
}

/// Stub NativeFinalizerFunction
class NativeFinalizerFunction extends NativeType {}
