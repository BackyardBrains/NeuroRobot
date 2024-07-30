import 'package:flutter/material.dart';
import 'dart:math' as math;

import 'package:flutter_svg/svg.dart';

class MenuIconAnimation extends StatefulWidget {
  final String svgPath;
  final Duration duration;
  final double width;
  final double height;

  const MenuIconAnimation({
    Key? key,
    required this.svgPath,
    required this.width,
    required this.height,
    this.duration = const Duration(milliseconds: 500),
  }) : super(key: key);

  @override
  _MenuIconAnimationState createState() => _MenuIconAnimationState();
}

class _MenuIconAnimationState extends State<MenuIconAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat(reverse: true);
    // _animation = Tween<double>(begin: 0, end: 2 * math.pi).animate(_controller);
    _animation =
        Tween<double>(begin: 0, end: 10 * math.pi / 180).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (BuildContext context, Widget? child) {
        return Transform.rotate(
          angle: _animation.value,
          child: SvgPicture.asset(
            widget.svgPath,
            width: widget.width,
            height: widget.height,
          ),
        );
      },
    );
  }
}
