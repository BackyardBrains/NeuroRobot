import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;

class RadialDialWidget extends StatefulWidget {
  final double value;
  final double min;
  final double max;
  final double? renderMin;
  final String title;
  final bool isTimeFormatter;
  final ValueChanged<double> onChanged;
  final ValueChanged<String>? onSubmitted;
  final double dialSize;
  final double widgetWidth;
  final bool alignRight;
  final bool isMixedState;
  final bool isPercentageFormatter;
  final double startAngleOffset;

  const RadialDialWidget({
    Key? key,
    required this.value,
    required this.min,
    required this.max,
    this.renderMin,
    required this.title,
    required this.onChanged,
    this.onSubmitted,
    this.isTimeFormatter = false,
    this.dialSize = 80.0,
    this.widgetWidth = 140.0,
    this.alignRight = false,
    this.isMixedState = false,
    this.isPercentageFormatter = false,
    this.startAngleOffset = 0.0,
  }) : super(key: key);

  @override
  State<RadialDialWidget> createState() => _RadialDialWidgetState();
}

class _RadialDialWidgetState extends State<RadialDialWidget> {
  late TextEditingController _textController;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _textController = TextEditingController(text: widget.isMixedState ? "Different weights" : _formatValue(widget.value));
    
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        _submitText(_textController.text);
      }
    });
  }

  @override
  void didUpdateWidget(RadialDialWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isMixedState && !_focusNode.hasFocus) {
        _textController.text = "Different weights";
    } else if (!widget.isMixedState && oldWidget.value != widget.value && !_focusNode.hasFocus) {
      _textController.text = _formatValue(widget.value);
    }
  }

  @override
  void dispose() {
    _focusNode.unfocus();
    _focusNode.dispose();
    _textController.dispose();
    super.dispose();
  }

  String _formatValue(double val) {
    if (widget.isPercentageFormatter) {
      return "${val.truncate()}%";
    }

    if (!widget.isTimeFormatter) {
      return val == val.truncateToDouble() ? val.truncate().toString() : val.toStringAsFixed(2);
    }

    if (val >= 1000) {
      double seconds = val / 1000.0;
      return "${seconds.toStringAsFixed(1)} Seconds";
    } else {
      return "${val.truncate()} milliseconds";
    }
  }

  void _submitText(String text) {
    _focusNode.unfocus();
    if (widget.onSubmitted != null) {
      widget.onSubmitted!(text);
      return;
    }
    
    String lowerText = text.toLowerCase().trim();
    String cleanText = text.replaceAll(RegExp(r'[^0-9.]'), '');
    double? parsed = double.tryParse(cleanText);
    
    if (parsed != null) {
      double finalValue = parsed;
      if (widget.isTimeFormatter) {
        bool hasMs = lowerText.contains("msec") || lowerText.contains("millisecond") || RegExp(r'\bms\b').hasMatch(lowerText);
        // If not explicitly MS, check if it's explicitly S
        bool hasS = !hasMs && (lowerText.contains("sec") || RegExp(r'\bs\b').hasMatch(lowerText));
        
        if (hasMs) {
          finalValue = parsed;
        } else if (hasS) {
          finalValue = parsed * 1000;
        } else {
          // No explicit unit
          if (cleanText.contains(".")) {
            finalValue = parsed * 1000;
          } else if (parsed < 20) {
            finalValue = parsed * 1000; 
          } else {
            finalValue = parsed;
          }
        }
      }
      
      finalValue = finalValue.clamp(widget.min, widget.max);
      widget.onChanged(finalValue);
      // Wait for the rebuild to handle text update, but set a fallback here
      if (widget.isMixedState && !_focusNode.hasFocus) {
        _textController.text = "Different weights";
      } else {
        _textController.text = _formatValue(finalValue);
      }
    } else {
      if (widget.isMixedState && !_focusNode.hasFocus) {
        _textController.text = "Different weights";
      } else {
        _textController.text = _formatValue(widget.value);
      }
    }
  }

  double? _lastPercentage;

  double get _effectiveRenderMin => widget.renderMin ?? widget.min;

  void _handlePanUpdate(DragUpdateDetails details, {bool isStart = false}) {
    // Allows dial interaction even in mixed state
    RenderBox renderBox = context.findRenderObject() as RenderBox;
    Offset localPosition = details.localPosition;
    
    double dx = localPosition.dx - (widget.dialSize / 2);
    double dy = localPosition.dy - (widget.dialSize / 2);
    
    double angle = math.atan2(dy, dx);
    angle += math.pi / 2;
    angle -= widget.startAngleOffset; // Apply user rotation offset
    if (angle < 0) angle += 2 * math.pi;
    
    double percentage = angle / (2 * math.pi);
    
    if (isStart) {
      _lastPercentage = percentage;
    } else if (_lastPercentage != null) {
      if ((percentage - _lastPercentage!).abs() > 0.5) {
        if (_lastPercentage! > 0.8 && percentage < 0.2) {
          percentage = 1.0;
        } else if (_lastPercentage! < 0.2 && percentage > 0.8) {
          percentage = 0.0;
        }
      }
      _lastPercentage = percentage;
    }
    
    double newValue = _effectiveRenderMin + percentage * (widget.max - _effectiveRenderMin);
    newValue = newValue.clamp(widget.min, widget.max);
    
    widget.onChanged(newValue);
  }

  @override
  Widget build(BuildContext context) {
    double percentage = widget.isMixedState 
        ? 0.5 
        : (widget.value - _effectiveRenderMin) / (widget.max - _effectiveRenderMin);
    percentage = percentage.clamp(0.0, 1.0);

    return SizedBox(
      width: widget.widgetWidth,
      height: math.max(widget.dialSize, (widget.dialSize / 2) + 36), // Height bounded to accommodate the dial or text box
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Text Title
          Positioned(
            left: widget.alignRight ? null : 0,
            right: widget.alignRight ? 0 : null,
            top: 10,
            child: Text(
              widget.title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              textAlign: widget.alignRight ? TextAlign.right : TextAlign.left,
            ),
          ),
          
          // Hint text when focused
          if (_focusNode.hasFocus && widget.isTimeFormatter) ...[
            Positioned(
              left: widget.alignRight ? null : 4,
              right: widget.alignRight ? 4 : null,
              top: (widget.dialSize / 2) - 26, // Moved hint text up to sit clearly above the text box
              child: Text(
                "Input seconds\nor ms",
                textAlign: widget.alignRight ? TextAlign.right : TextAlign.left,
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.grey,
                  height: 1.1,
                ),
              ),
            ),
          ],
          
          // TextField spanning the bottom
          Positioned(
            left: widget.alignRight ? widget.dialSize * 0.4 : 0,
            right: widget.alignRight ? 0 : widget.dialSize * 0.4, 
            top: widget.dialSize / 2, // Align the top of the text box perfectly with the center of the dial
            height: 32,
            child: TextField(
              controller: _textController,
              focusNode: _focusNode,
              textAlign: widget.alignRight ? TextAlign.right : TextAlign.left,
              decoration: InputDecoration(
                contentPadding: EdgeInsets.only(
                    left: widget.alignRight ? 0 : 8, 
                    right: widget.alignRight ? 8 : 0, 
                    top: 0, bottom: 0),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              style: const TextStyle(fontSize: 12),
              onTap: () {
                _textController.selection = TextSelection(
                  baseOffset: 0,
                  extentOffset: _textController.text.length,
                );
              },
              onSubmitted: _submitText,
            ),
          ),
          
          // Dial pie chart overlapping
          Positioned(
            right: widget.alignRight ? null : 0,
            left: widget.alignRight ? 0 : null,
            top: 0,
            child: GestureDetector(
              onPanUpdate: (details) => _handlePanUpdate(details, isStart: false),
              onPanDown: (details) => _handlePanUpdate(DragUpdateDetails(
                  globalPosition: details.globalPosition, 
                  delta: Offset.zero, 
                  primaryDelta: 0, 
                  localPosition: details.localPosition
                ), isStart: true),
              child: SizedBox(
                width: widget.dialSize,
                height: widget.dialSize,
                child: CustomPaint(
                  painter: DialPainter(
                    percentage: percentage,
                    colorOrange: widget.isMixedState ? Colors.grey : const Color(0XFFFD8164), 
                    startAngleOffset: widget.startAngleOffset,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DialPainter extends CustomPainter {
  final double percentage;
  final Color colorOrange;
  final double startAngleOffset;

  DialPainter({required this.percentage, required this.colorOrange, this.startAngleOffset = 0.0});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final dialRadius = size.width / 2 * 0.75; 
    final pieRadius = size.width / 2;

    Paint pieBgPaint = Paint()
      ..color = Colors.grey.shade300
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, pieRadius, pieBgPaint);

    Paint piePaint = Paint()
      ..color = colorOrange
      ..style = PaintingStyle.fill;
    
    double sweepAngle = percentage * 2 * math.pi;
    double startAngle = -math.pi / 2 + startAngleOffset;
    
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: pieRadius),
      startAngle, 
      sweepAngle,
      true,
      piePaint,
    );

    Paint dialPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    
    canvas.drawShadow(Path()..addOval(Rect.fromCircle(center: center, radius: dialRadius)), Colors.black, 4, true);
    canvas.drawCircle(center, dialRadius, dialPaint);

    Paint tickPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    double tickAngle = startAngle + sweepAngle;
    double tickStartRadius = dialRadius * 0.35;
    double tickEndRadius = dialRadius * 0.85;
    
    Offset p1 = Offset(
      center.dx + tickStartRadius * math.cos(tickAngle),
      center.dy + tickStartRadius * math.sin(tickAngle),
    );
    Offset p2 = Offset(
      center.dx + tickEndRadius * math.cos(tickAngle),
      center.dy + tickEndRadius * math.sin(tickAngle),
    );
    
    canvas.drawLine(p1, p2, tickPaint);
  }

  @override
  bool shouldRepaint(covariant DialPainter oldDelegate) {
    return percentage != oldDelegate.percentage;
  }
}
