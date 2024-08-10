import 'package:flutter/material.dart';
import 'package:infinite_canvas/infinite_canvas.dart';
import 'package:infinite_canvas/src/domain/model/drop_target.dart';
import 'package:infinite_canvas/src/presentation/widgets/clipper.dart';
import 'package:infinite_canvas/src/presentation/widgets/inline_painter.dart';

class InfiniteDropTargetsRenderer extends StatelessWidget {
  final InfiniteCanvasController controller;
  final InfiniteDropTarget dropTarget;

  InfiniteDropTargetsRenderer(
      {super.key, required this.controller, required this.dropTarget});

  @override
  Widget build(BuildContext context) {
    // return Container(
    //     width: dropTarget.size.width,
    //     height: dropTarget.size.height,

    return SizedBox.fromSize(
        size: dropTarget.size,
        child: Stack(clipBehavior: Clip.none, children: [
          Positioned.fill(
            key: key,
            child: dropTarget.clipBehavior != Clip.none
                ? ClipRect(
                    clipper: Clipper(dropTarget.rect),
                    clipBehavior: dropTarget.clipBehavior,
                    child: dropTarget.child,
                  )
                : Container(
                    // width: 10,
                    // height: 10,
                    // color: Colors.red,
                    child: dropTarget.child),
            // : dropTarget.child,
          ),
        ]
            // children: dropTargets.map((e) => e.child).toList(),
            ));

    // return CustomPaint(
    //   painter: InlinePainter(
    //       brush: Paint()..color = Colors.transparent,
    //       builder: (Paint paint, Canvas canvas, Rect rect) {}),
    // );
  }
}
