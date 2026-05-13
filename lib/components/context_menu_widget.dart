import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ContextMenuWidget extends StatelessWidget {
  final VoidCallback? onClonePressed;
  final VoidCallback onDeletePressed;
  final VoidCallback? onPressSound;
  final bool isCloneVisible;
  final bool isShowingInfo;

  const ContextMenuWidget({
    Key? key,
    this.onClonePressed,
    required this.onDeletePressed,
    this.onPressSound,
    this.isCloneVisible = true,
    this.isShowingInfo = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Pill Container
        Container(
          padding: EdgeInsets.only(
            left: 4.0, 
            right: isShowingInfo ? 16.0 : 4.0, 
            top: 4.0, 
            bottom: 4.0
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(40.0), // Fully rounded pill
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 6,
                offset: const Offset(2, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Clone Button Group
              if (isCloneVisible) ...[
                GestureDetector(
                  onTapDown: (_) => onPressSound?.call(),
                  onTap: onClonePressed,
                  behavior: HitTestBehavior.translucent, // don't block canvas pan/zoom gesture arena
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          border: Border.all(color: Colors.grey.shade400, width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 2,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: SvgPicture.asset(
                            'assets/icons/Clone.svg',
                            width: 48,
                            height: 48,
                          ),
                        ),
                      ),
                      if (isShowingInfo) ...[
                        const SizedBox(width: 6),
                        const Text(
                          'Clone',
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 22,
                            fontWeight: FontWeight.w400,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8), // Separator
              ],
              
              // Delete Button Group
              GestureDetector(
                onTapDown: (_) => onPressSound?.call(),
                onTap: onDeletePressed,
                behavior: HitTestBehavior.translucent, // don't block canvas pan/zoom gesture arena
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFE96565), // Red shade matching mockup
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 2,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: SvgPicture.asset(
                          'assets/icons/Delete.svg',
                          width: 48,
                          height: 48,
                        ),
                      ),
                    ),
                    if (isShowingInfo) ...[
                      const SizedBox(width: 6),
                      const Text(
                        'Delete',
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 22,
                          fontWeight: FontWeight.w400,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        
        // Downward-pointing curved V-arrow (matches brain card / website style)
        CustomPaint(
          size: const Size(40, 14),
          painter: _TrianglePainter(),
        ),
      ],
    );
  }
}

class _TrianglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    final fillPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;

    // Curved V-shape matching the brain-card arrow panel style
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(w, 0)
      ..quadraticBezierTo(w * 0.65,  0,      w * 0.545, h - 2)
      ..quadraticBezierTo(w * 0.515, h,      w / 2,     h)
      ..quadraticBezierTo(w * 0.485, h,      w * 0.455, h - 2)
      ..quadraticBezierTo(w * 0.35,  0,      0,          0)
      ..close();

    canvas.drawPath(path.shift(const Offset(1, 3)), shadowPaint);
    canvas.drawPath(path, fillPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
