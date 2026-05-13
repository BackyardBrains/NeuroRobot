import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../domain/model/node.dart';
import '../state/controller.dart';
import 'inline_painter.dart';

class InfiniteCanvasSynapseRenderer extends StatefulWidget {
  const InfiniteCanvasSynapseRenderer({super.key, required this.controller});
  final InfiniteCanvasController controller;

  @override
  State<InfiniteCanvasSynapseRenderer> createState() => _InfiniteCanvasSynapseRendererState();
}

class _InfiniteCanvasSynapseRendererState extends State<InfiniteCanvasSynapseRenderer> {
  Timer? _timer;
  final ValueNotifier<int> _clockTick = ValueNotifier(0);

  @override
  void initState() {
    super.initState();
    // Raw Dart Timer bypasses macOS power nap `vsync` sleep policies
    _timer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
       // Only increment while playing AND not animating camera.
       // In design mode the painter returns early anyway.
       if (widget.controller.isPlaying && !widget.controller.isAnimatingCamera) {
         _clockTick.value++;
       }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _clockTick.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: InlinePainter(
        // Repaint from two sources:
        // • _clockTick: 60fps while isPlaying (play-mode synapse animation)
        // • synapseFadeNotifier: design-mode spike fires this via synapseFadeController
        repaint: Listenable.merge([_clockTick, widget.controller.synapseFadeNotifier]),
        brush: Paint()..style = PaintingStyle.fill,
        builder: (brush, canvas, rect) {

          if (widget.controller.nucleusList == null || widget.controller.isAnimatingCamera) {
              return;
          }

          for (var shape in widget.controller.cachedSynapses) {

             if (shape.fromIdx < 0 || shape.fromIdx >= widget.controller.nucleusList!.length) {
                 continue; // Safety bounds
             }

             var nucleus = widget.controller.nucleusList![shape.fromIdx];
             int diff = DateTime.now().millisecondsSinceEpoch - nucleus.lastSpikeTime;
             int decayDuration = 750;

             if (nucleus.lastSpikeTime > 0 && diff < decayDuration) {
                double t = diff / decayDuration.toDouble();
                t = t.clamp(0.0, 1.0);

                // Fade from spike colour → transparent so the flash dissolves
                // into the existing terminal drawn by the edge renderer.
                // Previously fading → white caused the overlay to visually
                // cover the edge-rendered terminal, making it appear larger.
                if (shape.isExcitatory) {
                   Color c = Color.lerp(const Color(0xCC00FF00), Colors.white, t)!;
                   Paint synapseFill = Paint()
                     ..color = c
                     ..style = PaintingStyle.fill
                     ..blendMode = BlendMode.srcOver;
                   if (shape.triPath != null) {
                       canvas.drawPath(shape.triPath!, synapseFill);
                       // Re-draw the outline on top so it sits above the flash
                       canvas.drawPath(shape.triPath!, Paint()
                         ..color = Colors.black
                         ..style = PaintingStyle.stroke
                         ..strokeWidth = 1.2
                         ..blendMode = BlendMode.srcOver);
                   }
                } else {
                   Color c = Color.lerp(const Color(0xCCFF0000), Colors.white, t)!;
                   Paint synapseFill = Paint()
                     ..color = c
                     ..style = PaintingStyle.fill
                     ..blendMode = BlendMode.srcOver;
                   if (shape.circleCenter != null) {
                       double drawRadius = (shape.radius ?? 20.0) - 1.5;
                       canvas.drawCircle(shape.circleCenter!, drawRadius, synapseFill);
                       // No black outline for inhibitory synapses during blink
                   }
                }
             }
          }
        },
      ),
    );
  }
}
