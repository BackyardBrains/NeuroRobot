import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../state/controller.dart';
import '../../domain/model/node.dart';

// NucleusCircleParams kept for API compat; no longer drives a separate paint path.
class NucleusCircleParams {
  final int isExcitatory;
  final double circleRadius;
  final double xNucleus, yNucleus, widthNucleus, heightNucleus;
  const NucleusCircleParams({
    required this.isExcitatory,
    required this.circleRadius,
    required this.xNucleus,
    required this.yNucleus,
    required this.widthNucleus,
    required this.heightNucleus,
  });
}

class Nucleus extends StatefulWidget {
  int isSpiking;
  int lastSpikeTime;
  final int normalNeuronStartIdx = 13;
  final List<ValueNotifier<int>> neuronSpikeFlags;
  final Color activeColor;
  final Color inactiveColor;
  final Widget Function(BuildContext, Color?, InfiniteCanvasNode) childBuilder;
  final NucleusCircleParams? circleParams; // reserved, not used for rendering
  final int flagIndex;
  final LocalKey nodeKey;
  final Offset centerPos;
  final GlobalKey circleKey;
  final double scale;
  final double size;
  final InfiniteCanvasController controller;

  Nucleus({
    Key? key,
    required this.isSpiking,
    this.lastSpikeTime = 0,
    required this.neuronSpikeFlags,
    required this.activeColor,
    required this.inactiveColor,
    required this.childBuilder,
    this.circleParams,
    required this.flagIndex,
    required this.nodeKey,
    required this.centerPos,
    required this.circleKey,
    required this.size,
    this.scale = 1.0,
    required this.controller,
  }) : super(key: key);

  @override
  State<Nucleus> createState() => _NucleusState();
}

class _NucleusState extends State<Nucleus> {
  Offset? _cachedOffset;
  bool _cachedIsSelected = false;
  bool _cachedIsAnimating = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChange);
  }

  void _onControllerChange() {
    if (!mounted) return;
    final node = widget.controller.getNode(widget.nodeKey);
    final newOffset = node?.offset;
    final nowSelected = widget.controller.selection.any((n) => n.key == widget.nodeKey);
    final nowAnimating = widget.controller.isAnimatingCamera;

    if (newOffset != _cachedOffset ||
        nowSelected != _cachedIsSelected ||
        nowAnimating != _cachedIsAnimating) {
      _cachedOffset      = newOffset;
      _cachedIsSelected  = nowSelected;
      _cachedIsAnimating = nowAnimating;
      setState(() {});
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Offset effectivePos = widget.centerPos;
    var node = widget.controller.getNode(widget.nodeKey);
    if (node != null) {
      effectivePos = node.offset;
      _cachedOffset = effectivePos;
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() {});
      });
      return const SizedBox();
    }

    final child = SizedBox(
          width: widget.size,
          height: widget.size,
          key: widget.circleKey,
          child: AnimatedBuilder(
            animation: widget.neuronSpikeFlags[widget.flagIndex],
            builder: (context, child) {
              // Skip animation during camera pan to keep panning smooth.
              if (_cachedIsAnimating) {
                return widget.childBuilder(context, widget.inactiveColor, node!);
              }
              return TweenAnimationBuilder<Color?>(
                key: ValueKey(widget.lastSpikeTime),
                tween: ColorTween(
                    begin: widget.activeColor, end: widget.inactiveColor),
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOut,
                builder: (context, color, child) {
                  return widget.childBuilder(context, color, node!);
                },
              );
            },
          ),
        );

    return Positioned(
      top: effectivePos.dy,
      left: effectivePos.dx,
      child: Transform.scale(
        scale: widget.scale,
        // On web/CanvasKit, RepaintBoundary creates grey compositing layers.
        // On native (macOS/iOS), it's needed for raster cache performance.
        // ColoredBox(transparent) forces CanvasKit to clear the backing store.
        child: kIsWeb
            ? ColoredBox(color: const Color(0x00000000), child: child)
            : RepaintBoundary(child: child),
      ),
    );
  }
}
