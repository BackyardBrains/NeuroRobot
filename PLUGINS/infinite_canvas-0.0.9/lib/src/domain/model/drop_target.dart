import 'package:flutter/material.dart';

class InfiniteDropTarget<T> {
  InfiniteDropTarget({
    required this.key,
    required this.size,
    required this.offset,
    required this.child,
    this.clipBehavior = Clip.none,
  });
  LocalKey key;
  late Size size;
  late Offset offset;
  final Widget child;

  final Clip clipBehavior;
  Rect get rect => offset & size;
}
