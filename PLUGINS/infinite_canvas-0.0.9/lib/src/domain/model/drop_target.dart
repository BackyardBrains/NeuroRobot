import 'package:flutter/material.dart';

class InfiniteDropTarget {
  InfiniteDropTarget({
    required this.key,
    required this.size,
    required this.offset,
    required this.child,
  });
  LocalKey key;
  late Size size;
  late Offset offset;
  final Widget child;
}
