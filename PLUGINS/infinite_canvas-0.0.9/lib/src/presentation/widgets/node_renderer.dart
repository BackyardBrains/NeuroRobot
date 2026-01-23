import 'package:flutter/material.dart';

import '../../domain/model/node.dart';
import '../state/controller.dart';
import 'clipper.dart';
import 'drag_handel.dart';

class NodeRenderer extends StatelessWidget {
  const NodeRenderer({
    super.key,
    required this.node,
    required this.controller,
  });

  final InfiniteCanvasNode node;
  final InfiniteCanvasController controller;

  static const double borderInset = 2;

  @override
  Widget build(BuildContext context) {
    // V25: Don't render if hidden/zero-sized
    if (node.size.isEmpty || node.size.shortestSide <= 0) return const SizedBox();

    final colors = Theme.of(context).colorScheme;
    final fonts = Theme.of(context).textTheme;
    final showHandles = node.allowResize && controller.isSelected(node.key);
    return SizedBox.fromSize(
      size: node.size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (node.label != null && InfiniteCanvasNode.isShowingInfo)
            Positioned(
              top: -30,
              left: -20,
              child: Text(
                node.label!,
                // style: fonts.bodyMedium?.copyWith(
                //   color: colors.onSurface,
                //   shadows: [
                //     Shadow(
                //       offset: const Offset(0.8, 0.8),
                //       blurRadius: 3,
                //       color: colors.surface,
                //     ),
                //   ],
                // ),
              ),
            ),
          // CHANGE ME
          // V25: Orange highlight behind neuron when dragging connection (User Request)
          // Refined: Signature Color, Larger, Exclude Source/Parent
          if (controller.isHovered(node.key) && (controller.linkStart != null || controller.controlPressed))
             Builder(builder: (context) {
                // Check exclusion: Don't highlight if this node is the source
                if (controller.linkStart == node.key) return const SizedBox();
                
                // V25: Check exclusion: Don't highlight Sensory Outputs (Motors, Speakers, etc.)
                if (node.isSensory == 1) return const SizedBox();

                // V25: Check exclusion: Don't highlight the Tail Node itself
                if (controller.nodes.isNotEmpty && controller.nodes[0].key == node.key) return const SizedBox();

                // Check exclusion: Don't highlight parent if dragging tail (Tail is usually Node 0)
                // If linkStart is tailNode (nodes[0]), and this node is close to it, exclude.
                // V25: Increased exclusion distance to 150 to catch parent reliably.
                if (controller.nodes.isNotEmpty && controller.linkStart == controller.nodes[0].key) {
                   if ((node.offset - controller.nodes[0].offset).distance < 150) {
                      return const SizedBox();
                   }
                }

                return Positioned(
                  top: -15,
                  left: -15,
                  right: -15,
                  bottom: -15,
                  child: IgnorePointer(
                    child: Container(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFFD8164), // Signature Orange Opaque
                      ),
                    ),
                  ),
                );
             }),
          Positioned.fill(
            key: key,
            child: node.clipBehavior != Clip.none
                ? ClipRect(
                    clipper: Clipper(node.rect),
                    clipBehavior: node.clipBehavior,
                    child: node.child,
                  )
                : (!controller.isPlaying && (controller.isSelected(node.key) ||
                        controller.isHovered(node.key)))
                    ? Transform.scale(
                        scale: 1.65, // V25: Adjusted growth size
                        child: node.child!, // Highlight handled in EdgeRenderer (Bottom Layer)
                      )
                    : node.child!,
          ),
          if (showHandles) ...[
            // bottom right
            Positioned(
              right: 0,
              bottom: 0,
              child: GestureDetector(
                onPanUpdate: (details) {
                  if (!controller.mouseDown) return;
                  node.update(size: node.size + details.delta);
                  controller.edit(node);
                },
                child: const DragHandel(),
              ),
            ),
            // bottom left
            Positioned(
              left: 0,
              bottom: 0,
              child: GestureDetector(
                onPanUpdate: (details) {
                  if (!controller.mouseDown) return;
                  print("panning node");
                  node.update(
                    size:
                        node.size + Offset(-details.delta.dx, details.delta.dy),
                    offset: node.offset + Offset(details.delta.dx, 0),
                  );
                  controller.edit(node);
                },
                child: const DragHandel(),
              ),
            ),
            // top right
            Positioned(
              right: 0,
              top: 0,
              child: GestureDetector(
                onPanUpdate: (details) {
                  if (!controller.mouseDown) return;
                  node.update(
                    size:
                        node.size + Offset(details.delta.dx, -details.delta.dy),
                    offset: node.offset + Offset(0, details.delta.dy),
                  );
                  controller.edit(node);
                },
                child: const DragHandel(),
              ),
            ),
            // top left
            Positioned(
              left: 0,
              top: 0,
              child: GestureDetector(
                onPanUpdate: (details) {
                  if (!controller.mouseDown) return;
                  node.update(
                    size: node.size + -details.delta,
                    offset: node.offset + details.delta,
                  );
                  controller.edit(node);
                },
                child: const DragHandel(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
