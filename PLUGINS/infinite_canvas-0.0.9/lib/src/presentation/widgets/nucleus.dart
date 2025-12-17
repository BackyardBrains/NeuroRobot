import 'package:flutter/material.dart';

class Nucleus extends StatelessWidget {
  int isSpiking = -1;
  int normalNeuronStartIdx = 13;
  final List<ValueNotifier<int>> neuronSpikeFlags;
  final CustomPaint neuronActiveCircle;
  final CustomPaint neuronInactiveCircle;
  final int index;
  final Offset centerPos;
  final GlobalKey circleKey;
  final double scale;
  final double size;

  Nucleus({
    Key? key,
    required this.isSpiking,
    required this.neuronSpikeFlags,
    required this.neuronActiveCircle,
    required this.neuronInactiveCircle,
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
                // print("isSpiking");
                // print(isSpiking);
                if (isSpiking == -1) {
                  return neuronInactiveCircle;
                } else {
                  return neuronActiveCircle;
                }
              }),
            ))));
  }
}
