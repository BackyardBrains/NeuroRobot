import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'arc_slider_widget.dart';
import 'byb_highlighted_text.dart';

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
  final double robotSize = 120;
  late TextEditingController _brightnessController;
  late FocusNode _brightnessFocusNode;

  @override
  void initState() {
    super.initState();
    Color color = const Color(0xFFFF00FF);
    try { color = Color(int.parse("0xFF${widget.initialHex}")); } catch (e) {}
    _hsvColor = HSVColor.fromColor(color);
    try {
      _brightness = double.parse(widget.initialBrightness);
    } catch (e) {
      _brightness = 1.0;
    }
    _brightnessController = TextEditingController(
      text: "${(_brightness * 100).round()}%",
    );
    _brightnessFocusNode = FocusNode();
    _brightnessFocusNode.addListener(() {
      if (!_brightnessFocusNode.hasFocus) {
        _submitBrightnessText(_brightnessController.text);
      }
    });
  }

  @override
  void dispose() {
    _brightnessFocusNode.dispose();
    _brightnessController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(LEDControlWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialHex != widget.initialHex) {
      Color color = const Color(0xFFFF00FF);
      try { color = Color(int.parse("0xFF${widget.initialHex}")); } catch (e) {}
      setState(() { _hsvColor = HSVColor.fromColor(color); });
    }
    if (oldWidget.initialBrightness != widget.initialBrightness) {
      try {
        double b = double.parse(widget.initialBrightness);
        setState(() {
          _brightness = b;
          _brightnessController.text = "${(_brightness * 100).round()}%";
        });
      } catch (e) {}
    }
  }

  void _updateColor(HSVColor newHsv) {
    setState(() { _hsvColor = newHsv; });
    widget.onColorChanged(
      _hsvColor.toColor().value.toRadixString(16).substring(2).toUpperCase(),
      _brightness.toString(),
    );
  }

  void _updateBrightness(double val) {
    setState(() {
      _brightness = val;
      _brightnessController.text = "${(_brightness * 100).round()}%";
    });
    widget.onColorChanged(
      _hsvColor.toColor().value.toRadixString(16).substring(2).toUpperCase(),
      _brightness.toString(),
    );
  }

  void _submitBrightnessText(String text) {
    String cleaned = text.replaceAll(RegExp(r'[^0-9.]'), '');
    double? parsed = double.tryParse(cleaned);
    if (parsed != null) {
      double internal = parsed.clamp(1, 100) / 100.0;
      _updateBrightness(internal.clamp(0.01, 1.0));
    } else {
      // Restore display
      _brightnessController.text =
          "${(_brightness * 100).round()}%";
    }
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
    double hue = (angle * 180 / pi);
    double saturation = (dist / radius).clamp(0.0, 1.0);
    _updateColor(HSVColor.fromAHSV(1.0, hue, saturation, 1.0));
  }

  // Styled input box matching ArcSliderWidget's internal text field aesthetic
  Widget _buildBrightnessInput() {
    return Container(
      width: 60,
      height: 34,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black, width: 1.5),
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
      ),
      alignment: Alignment.center,
      child: TextField(
        controller: _brightnessController,
        focusNode: _brightnessFocusNode,
        textAlign: TextAlign.center,
        textAlignVertical: TextAlignVertical.center,
        style: const TextStyle(fontSize: 16),
        decoration: const InputDecoration(
          border: InputBorder.none,
          isCollapsed: true,
          contentPadding: EdgeInsets.only(bottom: 5),
        ),
        keyboardType: TextInputType.numberWithOptions(signed: true, decimal: true),
        textInputAction: TextInputAction.done,
        onSubmitted: _submitBrightnessText,
        onTap: () {
          _brightnessController.selection = TextSelection(
            baseOffset: 0,
            extentOffset: _brightnessController.text.length,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color glowColor =
        _hsvColor.withValue(1.0).toColor().withOpacity(_brightness * 0.6);
    final Color fadeColor =
        _hsvColor.withValue(1.0).toColor().withOpacity(0.0);
    // Display value for arc
    final double displayBrightness = _brightness * 100;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── LEFT COLUMN ────────────────────────────────────────────────
            // Arc slider (widgetWidth 174) concentric above color wheel (160).
            // With default 80° sweep all handle positions fall within SizedBox
            // bounds (x: 0..174, y: 0..110) so gesture detection works fully.
            Column(
              children: [
                const SizedBox(height: 8),
                ArcSliderWidget(
                  min: 1,
                  max: 100,
                  value: displayBrightness,
                  isPercentageFormatter: true,
                  showTextInput: false,
                  activeColor: _hsvColor
                      .withValue(1.0)
                      .toColor()
                      .withOpacity(_brightness.clamp(0.3, 1.0)),
                  inactiveColor: const Color(0xFFD0D0D0),
                  widgetWidth: 180,
                  // widgetHeight:100 → pivotY=180, handle center at y=16,
                  // handle top at y=1 — fully within SizedBox for hit detection.
                  widgetHeight: 100,
                  arcSweepAngle: pi * 65 / 180,
                  onChanged: (val) {
                    double internal = val / 100.0;
                    _updateBrightness(internal.clamp(0.01, 1.0));
                  },
                ),
                // Tight gap — just enough to clear the arc detection zone
                const SizedBox(height: 6),
                // Color Wheel — 160 px, visually concentric with arc above
                GestureDetector(
                  onPanUpdate: (_) {}, // absorbed by inner detector
                  child: SizedBox(
                    width: 160,
                    height: 160,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return GestureDetector(
                          onPanStart: (d) => _handleWheelGesture(d.localPosition, 80),
                          onPanUpdate: (d) => _handleWheelGesture(d.localPosition, 80),
                          onPanEnd: (_) => widget.onInteractionEnd?.call(),
                          onPanCancel: () => widget.onInteractionEnd?.call(),
                          onTapDown: (d) {
                            widget.onInteractionStart?.call();
                            _handleWheelGesture(d.localPosition, 80);
                          },
                          onTapUp: (_) => widget.onInteractionEnd?.call(),
                          child: CustomPaint(
                            painter: _ColorWheelPainter(
                              hsvColor: _hsvColor,
                              opacity: _brightness.clamp(0.3, 1.0),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),

            // ── RIGHT COLUMN ───────────────────────────────────────────────
            // Top spacer = arc widget height (74px) + gap (24px) = 98px,
            // so the robot section starts at the same y as the color wheel →
            // the two elements are vertically centered/aligned with each other.
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Brightness label + editable input aligned to arc top
                const Text(
                  "Brightness",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 6),
                _buildBrightnessInput(),
                // Spacer: left col above CW = 16+100+6=122px, right col
                // brightness controls ≈90px → spacer=32 → robot center≈202
                const SizedBox(height: 24),
                // Active Lights — same style as Brightness label
                const Text(
                  "Active Lights",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: 160,
                  height: 160,
                  child: Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      // Localized glows
                      if (widget.activeLights[0] == "1")
                        Positioned(
                          top: 25, left: 25,
                          child: Container(
                            width: 60, height: 60,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [glowColor, fadeColor], radius: 0.5),
                            ),
                          ),
                        ),
                      if (widget.activeLights[1] == "1")
                        Positioned(
                          top: 25, right: 25,
                          child: Container(
                            width: 60, height: 60,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [glowColor, fadeColor], radius: 0.5),
                            ),
                          ),
                        ),
                      if (widget.activeLights[2] == "1")
                        Positioned(
                          bottom: 25, left: 25,
                          child: Container(
                            width: 60, height: 60,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [glowColor, fadeColor], radius: 0.5),
                            ),
                          ),
                        ),
                      if (widget.activeLights[3] == "1")
                        Positioned(
                          bottom: 25, right: 25,
                          child: Container(
                            width: 60, height: 60,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [glowColor, fadeColor], radius: 0.5),
                            ),
                          ),
                        ),
                      // Base robot SVG
                      SvgPicture.asset(
                        "assets/icons/SpikerbotTopDownBlue.svg",
                        width: robotSize, height: robotSize,
                      ),
                      // LED overlays
                      if (widget.activeLights[0] == "1")
                        Center(child: SvgPicture.asset(
                          "assets/icons/SpikerbotLEDHighlight-NW.svg",
                          width: robotSize, height: robotSize,
                          colorFilter: ColorFilter.mode(
                            _hsvColor.withValue(1.0).toColor().withOpacity(_brightness),
                            BlendMode.srcIn),
                        )),
                      if (widget.activeLights[1] == "1")
                        Center(child: SvgPicture.asset(
                          "assets/icons/SpikerbotLEDHighlight-NE.svg",
                          width: robotSize, height: robotSize,
                          colorFilter: ColorFilter.mode(
                            _hsvColor.withValue(1.0).toColor().withOpacity(_brightness),
                            BlendMode.srcIn),
                        )),
                      if (widget.activeLights[2] == "1")
                        Center(child: SvgPicture.asset(
                          "assets/icons/SpikerbotLEDHighlight-SW.svg",
                          width: robotSize, height: robotSize,
                          colorFilter: ColorFilter.mode(
                            _hsvColor.withValue(1.0).toColor().withOpacity(_brightness),
                            BlendMode.srcIn),
                        )),
                      if (widget.activeLights[3] == "1")
                        Center(child: SvgPicture.asset(
                          "assets/icons/SpikerbotLEDHighlight-SE.svg",
                          width: robotSize, height: robotSize,
                          colorFilter: ColorFilter.mode(
                            _hsvColor.withValue(1.0).toColor().withOpacity(_brightness),
                            BlendMode.srcIn),
                        )),
                      // Corner checkboxes
                      Positioned(top: 0,    left: 0,   child: _buildCheckbox(0)),
                      Positioned(top: 0,    right: 0,  child: _buildCheckbox(1)),
                      Positioned(bottom: 0, left: 0,   child: _buildCheckbox(2)),
                      Positioned(bottom: 0, right: 0,  child: _buildCheckbox(3)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),

        // Info footer
        if (widget.infoState == 1) ...[
          const SizedBox(height: 10),
          SizedBox(
            width: 360,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.5),
                        spreadRadius: 0.3, blurRadius: 0.3,
                        offset: const Offset(1, 1),
                      ),
                    ],
                  ),
                  child: SvgPicture.asset("assets/icons/Info.svg"),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: BybHighlightedText(
                    "When the NEURON sends a SPIKE, lights will glow with the set color!",
                    fontSize: 16,
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
