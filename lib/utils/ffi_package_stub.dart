/// Stub implementation of package:ffi/ffi.dart for web platform.
/// Provides calloc, malloc, Utf8, etc. as no-op stubs.

import 'package:spikerbot/utils/ffi_imports.dart';

/// Stub calloc allocator
final StubAllocator calloc = StubAllocator();

/// Stub malloc allocator  
final StubAllocator malloc = StubAllocator();

class StubAllocator implements Allocator {
  @override
  Pointer<T> allocate<T extends NativeType>(int byteCount, {int? alignment}) {
    return Pointer<T>.fromAddress(0);
  }
  
  @override
  void free(Pointer<NativeType> pointer) {}
  
  /// Convenience call syntax: calloc<Uint8>(count)
  Pointer<T> call<T extends NativeType>(int count) {
    return Pointer<T>.fromAddress(0);
  }
}

/// Stub Utf8 type
class Utf8 extends NativeType {
  static String fromUtf8(Pointer<Utf8> pointer) => '';
}

/// Extension on Pointer<Utf8> for string conversion
extension Utf8Pointer on Pointer<Utf8> {
  String toDartString({int? length}) => '';
}

/// Extension to convert String to native Utf8
extension StringUtf8Pointer on String {
  Pointer<Utf8> toNativeUtf8({Allocator allocator = const _DefaultAllocator()}) {
    return Pointer<Utf8>.fromAddress(0);
  }
}

class _DefaultAllocator implements Allocator {
  const _DefaultAllocator();
  @override
  Pointer<T> allocate<T extends NativeType>(int byteCount, {int? alignment}) {
    return Pointer<T>.fromAddress(0);
  }
  @override
  void free(Pointer<NativeType> pointer) {}
}
