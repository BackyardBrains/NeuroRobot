import 'dart:ffi';
import 'package:ffi/ffi.dart';


class MemoryAllocator implements Allocator {
  final Allocator _wrappedAllocator;
  int _totalAllocations = 0;
  int _nonFreedAllocations = 0;

  MemoryAllocator([Allocator? allocator])
      : _wrappedAllocator = allocator ?? calloc;

  int get totalAllocations => _totalAllocations;

  int get nonFreedAllocations => _nonFreedAllocations;

  @override
  Pointer<T> allocate<T extends NativeType>(int byteCount, {int? alignment}) {
    final result =
        _wrappedAllocator.allocate<T>(byteCount, alignment: alignment);
    _totalAllocations++;
    _nonFreedAllocations++;
    return result;
  }

  @override
  void free(Pointer<NativeType> pointer) {
    _wrappedAllocator.free(pointer);
    _nonFreedAllocations--;
  }
}

MemoryAllocator allocator = MemoryAllocator();
Pointer<T> allocate<T extends NativeType>( {int? count, int? alignment, int? sizeOfType}){
  return allocator.allocate(count! * sizeOfType!);
}