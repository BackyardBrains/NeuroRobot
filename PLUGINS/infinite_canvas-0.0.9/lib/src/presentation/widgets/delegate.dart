import 'package:flutter/material.dart';
import 'package:infinite_canvas/src/domain/model/drop_target.dart';

import '../../domain/model/node.dart';

/// A [CustomMultiChildLayout] delegate that renders the nodes in the [InfiniteCanvas].
class InfiniteCanvasNodesDelegate extends MultiChildLayoutDelegate {
  InfiniteCanvasNodesDelegate(this.nodes);
  final List<InfiniteCanvasNode> nodes;

  @override
  void performLayout(Size size) {
    for (final widget in nodes) {
      layoutChild(widget, BoxConstraints.tight(widget.size));
      positionChild(widget, widget.offset);
    }
  }

  @override
  bool shouldRelayout(InfiniteCanvasNodesDelegate oldDelegate) => true;
}

class InfiniteCanvasDropTargetsDelegate extends MultiChildLayoutDelegate {
  InfiniteCanvasDropTargetsDelegate(this.dropTargets);
  final List<InfiniteDropTarget> dropTargets;

  @override
  void performLayout(Size size) {
    for (final widget in dropTargets) {
      layoutChild(widget, BoxConstraints.tight(widget.size));
      positionChild(widget, widget.offset);
    }
  }

  @override
  bool shouldRelayout(InfiniteCanvasDropTargetsDelegate oldDelegate) => true;
}
