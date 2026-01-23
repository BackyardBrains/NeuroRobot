import 'package:flutter/material.dart';

class Nucleus extends StatelessWidget {
  int isSpiking = -1;
  int lastSpikeTime = 0;
  int normalNeuronStartIdx = 13;
  final List<ValueNotifier<int>> neuronSpikeFlags;
  final Color activeColor;
  final Color inactiveColor;
  final Widget Function(BuildContext, Color?) childBuilder;
  final int index;
  final Offset centerPos;
  final GlobalKey circleKey;
  final double scale;
  final double size;

  Nucleus({
    Key? key,
    required this.isSpiking,
    this.lastSpikeTime = 0,
    required this.neuronSpikeFlags,
    required this.activeColor,
    required this.inactiveColor,
    required this.childBuilder,
    required this.index,
    required this.centerPos,
    required this.circleKey,
    required this.size,
    this.scale = 1.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (index < normalNeuronStartIdx) {
      return const SizedBox();
    }
    return Positioned(
        top: centerPos.dy,
        left: centerPos.dx,
        child: Transform.scale(
          scale: scale,
          child: SizedBox(
            width: size,
            height: size,
            key: circleKey,
            child: ValueListenableBuilder(
              valueListenable: neuronSpikeFlags[index],
              builder: ((context, value, child) {
                  return TweenAnimationBuilder<Color?>(
                    key: ValueKey(lastSpikeTime),
                    tween: ColorTween(begin: activeColor, end: inactiveColor),
                    duration: const Duration(milliseconds: 750),
                    curve: Curves.linear,
                    builder: (context, color, child) {
                       return childBuilder(context, color);
                    },
                    onEnd: () {},
                  );
              }),
            ))));
  }
}
