/// Web stub for Allocator.
/// On web, buffers are just TypedLists — no FFI allocation needed.

import 'package:spikerbot/utils/ffi_imports.dart';
import 'package:spikerbot/utils/ffi_package_imports.dart';

/// Stub allocator for web
class MemoryAllocator implements Allocator {
  int _totalAllocations = 0;
  int _nonFreedAllocations = 0;
  
  int get totalAllocations => _totalAllocations;
  int get nonFreedAllocations => _nonFreedAllocations;

  @override
  Pointer<T> allocate<T extends NativeType>(int byteCount, {int? alignment}) {
    _totalAllocations++;
    _nonFreedAllocations++;
    return Pointer<T>.fromAddress(0);
  }

  @override
  void free(Pointer<NativeType> pointer) {
    _nonFreedAllocations--;
  }
}

MemoryAllocator allocator = MemoryAllocator();

Pointer<T> allocate<T extends NativeType>({int? count, int? alignment, int? sizeOfType}) {
  return allocator.allocate(count! * (sizeOfType ?? 1));
}

void freeMemory(dynamic obj) {
  // No-op on web
}
