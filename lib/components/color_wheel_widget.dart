import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class LEDControlWidget extends StatefulWidget {
  final Function(String, String) onColorChanged; // hex, brightness
  final Function(int) onLightToggled; // index
  final String activeLights; // "1100"
  final String initialHex;
  final String initialBrightness;
  final int infoState; // V28: 0=Off, 1=Info

  final VoidCallback? onInteractionStart; // Button pressed sound
  final VoidCallback? onInteractionEnd;   // Button pop sound

  const LEDControlWidget({
    Key? key,
    required this.onColorChanged,
    required this.onLightToggled,
    required this.activeLights,
    required this.initialHex,
    required this.initialBrightness,
    this.infoState = 0,
    this.onInteractionStart,
    this.onInteractionEnd,
  }) : super(key: key);

  @override
  State<LEDControlWidget> createState() => _LEDControlWidgetState();
}

class _LEDControlWidgetState extends State<LEDControlWidget> {
  late HSVColor _hsvColor;
  late double _brightness; 
  final double robotSize = 120; // V22
  final TextEditingController _brightnessController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Parse hex
    Color color = const Color(0xFFFF00FF);
    try {
      color = Color(int.parse("0xFF${widget.initialHex}"));
    } catch (e) {
      // fallback
    }
    _hsvColor = HSVColor.fromColor(color);
    
    // Parse brightness
    try {
      _brightness = double.parse(widget.initialBrightness);
    } catch (e) {
      _brightness = 1.0;
    }
    _brightnessController.text = (_brightness * 100).round().toString();
  }

  @override
  void dispose() {
    _brightnessController.dispose();
    super.dispose();
  }

  void _updateColor(HSVColor newHsv) {
    setState(() {
      _hsvColor = newHsv;
    });
    widget.onColorChanged(
      _hsvColor.toColor().value.toRadixString(16).substring(2).toUpperCase(),
      _brightness.toStringAsFixed(2),
    );
  }

  void _updateBrightness(double val) {
    setState(() {
      _brightness = val;
      _brightnessController.text = (_brightness * 100).round().toString();
    });
    widget.onColorChanged(
      _hsvColor.toColor().value.toRadixString(16).substring(2).toUpperCase(),
      _brightness.toStringAsFixed(2),
    );
  }

  Widget _buildCheckbox(int index) {
      bool isChecked = widget.activeLights[index] == "1";
      return Transform.scale(
        scale: 1.3,
        child: Checkbox(
          value: isChecked,
          activeColor: const Color(0XFFFD8164),
          side: const BorderSide(color: Colors.grey, width: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          onChanged: (val) {
            // Play sounds back-to-back for checkbox click illusion
            widget.onInteractionStart?.call();
            widget.onInteractionEnd?.call();
            widget.onLightToggled(index);
          },
        ),
      );
  }

  void _handleWheelGesture(Offset localPos, double radius) {
     final dx = localPos.dx - radius;
     final dy = localPos.dy - radius;
     final dist = sqrt(dx * dx + dy * dy);
     double angle = atan2(dy, dx);
     if (angle < 0) angle += 2 * pi;
     
     // Hue from angle
     double hue = (angle * 180 / pi);
     
     // Saturation from distance (clamped)
     double saturation = (dist / radius).clamp(0.0, 1.0);
     
     _updateColor(HSVColor.fromAHSV(1.0, hue, saturation, 1.0));
  }

  @override
  Widget build(BuildContext context) {
    // V29: Glow Colors
    final Color glowColor = _hsvColor.withValue(1.0).toColor().withOpacity(_brightness * 0.6);
    final Color fadeColor = _hsvColor.withValue(1.0).toColor().withOpacity(0.0);

    return Column( // V23: Unified Column
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.start, // Align top
          children: [
            // 1. Color Wheel
            // V29: Dimming logic - V32: Opacity passed to Painter (Puck Ring Opaque)
            GestureDetector(
               onPanUpdate: (details) {
                  // Captured by inner gesture detector
                },
               child: SizedBox(
                 width: 160, 
                 height: 160,
                 child: LayoutBuilder(
                   builder: (context, constraints) {
                     return GestureDetector(
                       onPanStart: (details) {
                         // widget.onInteractionStart?.call(); // Removed to prevent double trigger (handled by onTapDown)
                         _handleWheelGesture(details.localPosition, 80);
                       },
                       onPanUpdate: (details) => _handleWheelGesture(details.localPosition, 80),
                       onPanEnd: (details) => widget.onInteractionEnd?.call(),
                       onPanCancel: () => widget.onInteractionEnd?.call(),
                       onTapDown: (details) {
                         widget.onInteractionStart?.call();
                         _handleWheelGesture(details.localPosition, 80);
                       },
                       onTapUp: (details) => widget.onInteractionEnd?.call(),
                       child: CustomPaint(
                         painter: _ColorWheelPainter(
                            hsvColor: _hsvColor, 
                            opacity: _brightness.clamp(0.3, 1.0)
                         ),
                       ),
                     );
                   }
                 ),
               ),
            ),

            // 2. Robot Control
            Column(
              children: [
                const Text("Active Lights"), 
                const SizedBox(height: 8),   // V29: Padding moved here (below title)  
                SizedBox(
                  width: 160, // V29: Increased Width to spread checkboxes (140->160)
                  height: 160,
                  child: Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      // V29: Localized Glows (60x60 circles)
                      
                      // NW Glow (Top Left)
                      if (widget.activeLights[0] == "1")
                        Positioned(
                          top: 25, left: 25, 
                          child: Container(
                            width: 60, height: 60,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [glowColor, fadeColor],
                                radius: 0.5,
                              ),
                            ),
                          ),
                        ),
                       
                      // NE Glow (Top Right)
                      if (widget.activeLights[1] == "1")
                        Positioned(
                          top: 25, right: 25, 
                          child: Container(
                            width: 60, height: 60,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [glowColor, fadeColor],
                                radius: 0.5,
                              ),
                            ),
                          ),
                        ),

                      // SW Glow (Bottom Left)
                      if (widget.activeLights[2] == "1")
                        Positioned(
                          bottom: 25, left: 25, 
                           child: Container(
                             width: 60, height: 60,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [glowColor, fadeColor],
                                radius: 0.5,
                              ),
                            ),
                          ),
                        ),

                      // SE Glow (Bottom Right)
                      if (widget.activeLights[3] == "1")
                        Positioned(
                          bottom: 25, right: 25, 
                           child: Container(
                             width: 60, height: 60,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [glowColor, fadeColor],
                                radius: 0.5,
                              ),
                            ),
                          ),
                        ),

                      // Base SVG
                      SvgPicture.asset(
                         "assets/icons/SpikerbotTopDownBlue.svg",
                         width: robotSize,
                         height: robotSize,
                      ),
                      
                      // Active Light Overlays
                      
                      // 0: NW
                      if (widget.activeLights[0] == "1")
                       Center(
                         child: SvgPicture.asset(
                           "assets/icons/SpikerbotLEDHighlight-NW.svg",
                           width: robotSize,
                           height: robotSize,
                           colorFilter: ColorFilter.mode(
                             _hsvColor.withValue(1.0).toColor().withOpacity(_brightness), 
                             BlendMode.srcIn
                           ),
                         ),
                       ),
                         
                      // 1: NE
                      if (widget.activeLights[1] == "1")
                       Center(
                         child: SvgPicture.asset(
                           "assets/icons/SpikerbotLEDHighlight-NE.svg",
                           width: robotSize,
                           height: robotSize,
                           colorFilter: ColorFilter.mode(
                             _hsvColor.withValue(1.0).toColor().withOpacity(_brightness), 
                             BlendMode.srcIn
                           ),
                         ),
                       ),
                         
                      // 2: SW
                      if (widget.activeLights[2] == "1")
                       Center(
                         child: SvgPicture.asset(
                           "assets/icons/SpikerbotLEDHighlight-SW.svg",
                           width: robotSize,
                           height: robotSize,
                           colorFilter: ColorFilter.mode(
                             _hsvColor.withValue(1.0).toColor().withOpacity(_brightness), 
                             BlendMode.srcIn
                           ),
                         ),
                       ),
                         
                      // 3: SE
                      if (widget.activeLights[3] == "1")
                       Center(
                         child: SvgPicture.asset(
                           "assets/icons/SpikerbotLEDHighlight-SE.svg",
                           width: robotSize,
                           height: robotSize,
                           colorFilter: ColorFilter.mode(
                             _hsvColor.withValue(1.0).toColor().withOpacity(_brightness), 
                             BlendMode.srcIn
                           ),
                         ),
                       ),

                      // Checkboxes (Corners)
                      Positioned(top: 0, left: 0, child: _buildCheckbox(0)),
                      Positioned(top: 0, right: 0, child: _buildCheckbox(1)),
                      Positioned(bottom: 0, left: 0, child: _buildCheckbox(2)),
                      Positioned(bottom: 0, right: 0, child: _buildCheckbox(3)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        
        // 3. Brightness Control
        const SizedBox(height: 5), // V29: Reduced spacing (10->5)
        const Text("Brightness"),
        // const SizedBox(height: 0), // Removed
        Row(
          children: [
            // Percentage Input
            SizedBox(
              width: 50,
              child: TextField(
                controller: _brightnessController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 4),
                  suffixText: "%",
                  border: UnderlineInputBorder(), 
                ),
                onSubmitted: (val) {
                  double? v = double.tryParse(val);
                  if (v != null) {
                    _updateBrightness((v.clamp(40, 100)) / 100);
                  }
                },
              ),
            ),
            const SizedBox(width: 10),
            // Slider
            Expanded(
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: const Color(0XFFFD8164), 
                  thumbColor: Colors.white,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12.0),
                  overlayColor: const Color(0XFFFD8164).withOpacity(0.2),
                ),
                child: Slider(
                  value: _brightness,
                  min: 0.4, // Min brightness 40%
                  max: 1.0,
                  onChanged: _updateBrightness,
                  onChangeStart: (_) => widget.onInteractionStart?.call(),
                  onChangeEnd: (_) => widget.onInteractionEnd?.call(),
                ),
              ),
            ),
          ],
        ),
        
        if (widget.infoState == 1) ...[ // V29: Footer (Distance Sensor Style)
          const SizedBox(height: 10),
           SizedBox( 
            width: 360,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                 // V29: Styled Container
                 Container(
                    width: 40, 
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.5),
                          spreadRadius: 0.3,
                          blurRadius: 0.3,
                          offset: const Offset(1, 1), 
                        ),
                      ],
                    ),
                    child: SvgPicture.asset("assets/icons/Info.svg"),
                  ),
                 const SizedBox(width: 10), 
                 const Expanded(
                   child: Text(
                     "When the NEURON sends a SPIKE, lights will glow with the set color!",
                     style: TextStyle(
                       fontFamily: "BybHanddrawn", 
                       fontSize: 16, // V30: Reduced from 18
                       color: Colors.black87
                     ),
                     maxLines: 3,
                     textAlign: TextAlign.left,
                   ),
                 ),
              ],
            ),
           ),
        ],
      ],
    );
  }
}

class _ColorWheelPainter extends CustomPainter {
  final HSVColor hsvColor;
  final double opacity; 

  _ColorWheelPainter({required this.hsvColor, required this.opacity});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final center = rect.center;
    final radius = size.width / 2;

    // V33: Composite Layer for Opacity (Fixes Gradient Center)
    // Save layer with alpha to apply opacity to the entire group
    // V34: Inflate rect to prevent clipping of the Puck at the edges
    canvas.saveLayer(rect.inflate(20), Paint()..color = Colors.black.withOpacity(opacity));

    // 1. Draw Hue Sweep (True RGB Primaries V21) - Opaque (Composite handles alpha)
    final huePaint = Paint()
      ..shader = const SweepGradient(
        colors: [
          Color(0xFFFF0000), // Red
          Color(0xFFFFFF00), // Yellow
          Color(0xFF00FF00), // Green
          Color(0xFF00FFFF), // Cyan
          Color(0xFF0000FF), // Blue
          Color(0xFFFF00FF), // Magenta
          Color(0xFFFF0000), // Red
        ],
      ).createShader(rect);
    canvas.drawCircle(center, radius, huePaint);

    // 2. Draw Saturation overlay (White center -> Transparent edge) - Opaque
    final saturationPaint = Paint()
      ..shader = const RadialGradient(
        colors: [
          Colors.white,
          Color(0x00FFFFFF), // Transparent White
        ],
      ).createShader(rect);
    canvas.drawCircle(center, radius, saturationPaint);

    // 3. Draw Selector Thumb Fill - Opaque (Composite handles alpha)
    final thumbHue = hsvColor.hue;
    final thumbSat = hsvColor.saturation;
    final thumbDist = thumbSat * radius;
    final thumbAngle = (thumbHue / 360) * 2 * pi;
    final thumbDx = center.dx + thumbDist * cos(thumbAngle);
    final thumbDy = center.dy + thumbDist * sin(thumbAngle);

    canvas.drawCircle(
      Offset(thumbDx, thumbDy),
      10, 
      Paint()..color = hsvColor.withValue(1.0).toColor()..style = PaintingStyle.fill,
    );

    // Restore layer (Opacity applied)
    canvas.restore();

    // 4. Contrast ring (V31: Solid Black 3px stroke) - ALWAYS OPAQUE (Outside Layer)
    canvas.drawCircle(
      Offset(thumbDx, thumbDy),
      12, // Outer ring
      Paint()..color = Colors.black..style = PaintingStyle.stroke..strokeWidth = 3,
    );
  }

  @override
  bool shouldRepaint(covariant _ColorWheelPainter oldDelegate) {
    return oldDelegate.hsvColor != hsvColor;
  }
}
