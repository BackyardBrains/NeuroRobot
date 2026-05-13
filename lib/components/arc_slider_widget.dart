import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;

/// A custom Arc Slider widget that allows precise control by dragging handles.
/// The further radially outward the user drags, the finer the precision.
enum ArcSliderOrientation { horizontal, verticalLeft, verticalRight }

class ArcSliderWidget extends StatefulWidget {
  final double min;
  final double max;
  final double? lowerValue;
  final double? upperValue;
  final double value;
  final bool isRange;
  
  // Formatters
  final bool isTimeFormatter;
  final bool isPercentageFormatter;
  final bool isDegreeFormatter;
  final String unitSuffix;
  
  // Orientation and Look
  final double startAngleOffset; 
  final double arcSweepAngle; 
  final Color activeColor;
  final Color inactiveColor;
  final bool showHitZones;
  final bool isMixedState;
  final ArcSliderOrientation orientation;
  final bool flipVertical;
  /// When false the built-in value text field is hidden so hosts can place
  /// their own label/value display anywhere (e.g. in a Row to the right).
  final bool showTextInput;
  
  final double? widgetWidth;
  final double? widgetHeight;

  // Title and Text positions
  final String title;
  final String? lowerTitle;
  final String? upperTitle;
  
  final bool isLogarithmic; // logarithmic angle→value mapping (better for freq ranges)
  final ValueChanged<double>? onChanged;
  final void Function(double lower, double upper)? onRangeChanged;
  
  const ArcSliderWidget({
    Key? key,
    required this.min,
    required this.max,
    this.value = 0.0,
    this.lowerValue,
    this.upperValue,
    this.isRange = false,
    this.isTimeFormatter = false,
    this.isPercentageFormatter = false,
    this.isDegreeFormatter = false,
    this.unitSuffix = "",
    this.startAngleOffset = -math.pi / 2, // Default top center (-90 deg)
    this.arcSweepAngle = math.pi * 80 / 180, // 80 degrees
    this.activeColor = const Color(0XFFFD8164),
    this.inactiveColor = const Color(0xFFD0D0D0),
    this.showHitZones = false, 
    this.isMixedState = false,
    this.orientation = ArcSliderOrientation.horizontal,
    this.flipVertical = false,
    this.showTextInput = true,
    this.isLogarithmic = false,
    this.widgetWidth,
    this.widgetHeight,
    this.title = "",
    this.lowerTitle = "From:",
    this.upperTitle = "To:",
    this.onChanged,
    this.onRangeChanged,
  }) : super(key: key);

  @override
  State<ArcSliderWidget> createState() => _ArcSliderWidgetState();
}

class _ArcSliderWidgetState extends State<ArcSliderWidget> {
  late TextEditingController _lowerTextController;
  late TextEditingController _upperTextController;
  late FocusNode _lowerFocusNode;
  late FocusNode _upperFocusNode;
  
  // Radius specs
  // Center it slightly lower by default, use a larger radius maybe
  final double _arcBaseRadius = 135.0;
  final double _arcThickness = 24.0;

  // Interaction State
  bool _isDraggingLower = false;
  bool _isDraggingUpper = false;
  
  // To avoid crossing over
  double _currentLower = 0;
  double _currentUpper = 0;
  
  @override
  void initState() {
    super.initState();
    _currentLower = widget.isRange ? (widget.lowerValue ?? widget.min) : widget.value;
    _currentUpper = widget.isRange ? (widget.upperValue ?? widget.max) : widget.max;
    
    _lowerTextController = TextEditingController(text: (widget.isMixedState && !widget.isRange) ? "Mixed" : _formatValue(_currentLower));
    _upperTextController = TextEditingController(text: _formatValue(_currentUpper));

    // Submit value when focus leaves (covers iOS numpad tap-to-dismiss)
    _lowerFocusNode = FocusNode();
    _lowerFocusNode.addListener(() {
      if (!_lowerFocusNode.hasFocus) _submitLowerText(_lowerTextController.text);
    });
    _upperFocusNode = FocusNode();
    _upperFocusNode.addListener(() {
      if (!_upperFocusNode.hasFocus) _submitUpperText(_upperTextController.text);
    });
  }

  @override
  void didUpdateWidget(ArcSliderWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.isRange) {
      if (oldWidget.value != widget.value || oldWidget.isMixedState != widget.isMixedState) {
        _currentLower = widget.value;
        if (widget.isMixedState) {
           _lowerTextController.text = "Mixed";
        } else {
           _lowerTextController.text = _formatValue(_currentLower);
        }
      }
    } else {
      if (oldWidget.lowerValue != widget.lowerValue) {
        _currentLower = widget.lowerValue ?? widget.min;
        _lowerTextController.text = _formatValue(_currentLower);
      }
      if (oldWidget.upperValue != widget.upperValue) {
        _currentUpper = widget.upperValue ?? widget.max;
        _upperTextController.text = _formatValue(_currentUpper);
      }
    }
  }

  @override
  void dispose() {
    _lowerTextController.dispose();
    _upperTextController.dispose();
    _lowerFocusNode.dispose();
    _upperFocusNode.dispose();
    super.dispose();
  }
  
  String _formatValue(double val) {
    if (widget.isDegreeFormatter) {
      int deg = ((val / 2.0) - 80.0).round();
      return "$deg°";
    }

    if (widget.isPercentageFormatter) {
      return "${val.truncate()}%";
    }

    if (widget.isTimeFormatter) {
      if (val >= 1000) {
        double seconds = val / 1000.0;
        return "${seconds.truncate()}s";
      } else {
        return "${val.truncate()}ms";
      }
    }
    
    if (widget.unitSuffix == "cm" && val >= 100) {
      double meters = val / 100.0;
      // Show one decimal for meters 1.0m, 1.2m
      String formattedM = meters == meters.truncateToDouble() ? meters.truncate().toString() + ".0" : meters.toStringAsFixed(1);
      return "${formattedM}m";
    }
    
    String formatted = val.truncate().toString();
    return "$formatted${widget.unitSuffix}";
  }
  
  void _submitLowerText(String text) {
     double? parsed = _parseText(text);
     if (parsed != null) {
       double minDistance = widget.isRange ? 2.0 : 0.0;
       
       _currentLower = parsed.clamp(widget.min, widget.max);
       if (widget.isRange && _currentLower > _currentUpper - minDistance) {
           _currentUpper = _currentLower + minDistance;
           if (_currentUpper > widget.max) {
               _currentUpper = widget.max;
               _currentLower = _currentUpper - minDistance;
           }
           _upperTextController.text = _formatValue(_currentUpper);
       }
       _fireChange();
     }
     if (widget.isMixedState && !widget.isRange) {
        _lowerTextController.text = "Mixed";
     } else {
        _lowerTextController.text = _formatValue(_currentLower);
     }
  }
  
  void _submitUpperText(String text) {
     if (!widget.isRange) return;
     double? parsed = _parseText(text);
     if (parsed != null) {
       double minDistance = widget.isRange ? 2.0 : 0.0;
       
       _currentUpper = parsed.clamp(widget.min, widget.max);
       if (_currentUpper < _currentLower + minDistance) {
           _currentLower = _currentUpper - minDistance;
           if (_currentLower < widget.min) {
               _currentLower = widget.min;
               _currentUpper = _currentLower + minDistance;
           }
           _lowerTextController.text = _formatValue(_currentLower);
       }
       _fireChange();
     }
     _upperTextController.text = _formatValue(_currentUpper);
  }

  double? _parseText(String text) {
    String cleanText = text.replaceAll(RegExp(r'[^0-9.\-]'), '');
    double? parsed = double.tryParse(cleanText);
    if (parsed == null) return null;
    
    if (widget.isDegreeFormatter) {
       return (parsed + 80.0) * 2.0;
    }
    
    String lowerText = text.toLowerCase().trim();
    if (widget.isTimeFormatter) {
       bool hasMs = lowerText.contains("ms");
       bool hasS = !hasMs && lowerText.contains("s");
       if (hasS) return parsed * 1000;
       if (cleanText.contains(".")) return parsed * 1000; 
       if (parsed < 20 && !hasMs) return parsed * 1000;
    }
    
    if (widget.unitSuffix == "cm") {
       if (lowerText.contains("m") && !lowerText.contains("cm") && !lowerText.contains("ms")) {
          return parsed * 100;
       }
    }
    
    return parsed;
  }
  
  void _fireChange() {
    if (widget.isRange) {
      widget.onRangeChanged?.call(_currentLower, _currentUpper);
    } else {
      widget.onChanged?.call(_currentLower);
    }
    setState(() {});
  }
  

  
  void _endPan(DragEndDetails details) {
    _isDraggingLower = false;
    _isDraggingUpper = false;
    // Format text nicely on drop
    _lowerTextController.text = _formatValue(_currentLower);
    if (widget.isRange) _upperTextController.text = _formatValue(_currentUpper);
    setState((){});
  }

  @override
  Widget build(BuildContext context) {
    double widgetWidth = widget.widgetWidth ?? (widget.orientation == ArcSliderOrientation.horizontal ? 360.0 : 125.0); 
    
    // For single-slider horizontal instances we strip another 15px off since the top title is gone,
    // and raise the pivot axis slightly higher to clamp it beautifully against the container.
    double defaultHeight = widget.orientation == ArcSliderOrientation.horizontal ? 125.0 : 360.0;
    double widgetHeight = widget.widgetHeight ?? (widget.isRange ? 108.0 : defaultHeight - 15.0); 
    
    Offset pivotOffset;
    double resolvedStartAngleOffset = widget.startAngleOffset;

    if (widget.orientation == ArcSliderOrientation.horizontal) {
        double pivotY = widget.isRange ? widgetHeight + 75.0 : widgetHeight + 80.0; // Standard layout bounds
        if (widget.isDegreeFormatter) {
           pivotY += 20.0; // Pushed structurally lower specifically into the camera boundary cleanly avoiding layout overlap
        }
        pivotOffset = Offset(widgetWidth / 2, pivotY);
    } else if (widget.orientation == ArcSliderOrientation.verticalLeft) {
        pivotOffset = Offset(-50.0, widgetHeight / 2);
        resolvedStartAngleOffset = 0.0; // Pointing precisely Right from left pivot
    } else {
        pivotOffset = Offset(widgetWidth + 50.0, widgetHeight / 2);
        resolvedStartAngleOffset = math.pi; // Pointing precisely Left from right pivot
    }
    
    void _processPan(Offset localPosition, {required Offset localPivot}) {
       double dx = localPosition.dx - localPivot.dx;
       double dy = localPosition.dy - localPivot.dy;
       
       double touchAngle = math.atan2(dy, dx);
       double touchRadius = math.sqrt(dx*dx + dy*dy);
       double normalizedAngle = touchAngle - resolvedStartAngleOffset;
       while (normalizedAngle > math.pi) normalizedAngle -= 2 * math.pi;
       while (normalizedAngle < -math.pi) normalizedAngle += 2 * math.pi;
       
       double halfSweep = widget.arcSweepAngle / 2.0; 
       double innerBandRadius = _arcBaseRadius + _arcThickness / 2;
       double arcOuterEdge = _arcBaseRadius + _arcThickness / 2;
       
       // Handle positions:
       // Layer 0 circle is at: arcOuterEdge + 17
       // Layer 1 circle is at: layer0Radius + 20 (overlapping by 10) -> arcOuterEdge + 37
       // The middle of the overlap is at arcOuterEdge + 27
       
       double band1Outer = arcOuterEdge + 27; // Outer edge of green
       double band2Outer = band1Outer + 30; // Outer edge of blue
       
       if (!_isDraggingLower && !_isDraggingUpper) {
          bool hitLower = false;
          bool hitUpper = false;
          
          // Check if radius falls within bands
          if (widget.isRange) {
             // Lower handle (main arc to green)
             if (touchRadius > innerBandRadius - 15 && touchRadius <= band1Outer + 10) {
                hitLower = true;
             }
             // Upper handle (blue band)
             if (touchRadius > band1Outer && touchRadius < band2Outer + 15) {
                hitUpper = true;
             }
          } else {
             // Single handle
             if (touchRadius > innerBandRadius - 15 && touchRadius < band1Outer + 15) {
                hitLower = true;
             }
          }
          
          // Sweeps need to match visual limits carefully
          bool withinAngle = (normalizedAngle >= -halfSweep - 0.2) && (normalizedAngle <= halfSweep + 0.2);
          if (withinAngle) {
              if (hitUpper && hitLower) _isDraggingUpper = true; 
              else if (hitUpper) _isDraggingUpper = true;
              else if (hitLower) _isDraggingLower = true;
              else return; 
          } else {
              return;
          }
       }
       
       double percentage = (normalizedAngle + halfSweep) / widget.arcSweepAngle;
       if (widget.flipVertical) percentage = 1.0 - percentage;
       
       if (percentage < 0) percentage = 0;
       if (percentage > 1) percentage = 1;
       
       // Log or linear angle→value conversion
       double newValue;
       if (widget.isLogarithmic && widget.min > 0 && widget.max > widget.min) {
         newValue = widget.min * math.pow(widget.max / widget.min, percentage);
       } else {
         newValue = widget.min + percentage * (widget.max - widget.min);
       }
       
       // Ensure there is always a minimum distance of 1 whole unit (e.g. 1cm) when in range mode.
       double minDistance = widget.isRange ? 2.0 : 0.0;
       
       if (_isDraggingLower) {
           _currentLower = newValue;
           if (widget.isRange && _currentLower > _currentUpper - minDistance) {
               _currentUpper = _currentLower + minDistance;
               // Push upper bound! Let lower handle push the upper handle along the track.
               if (_currentUpper > widget.max) {
                   _currentUpper = widget.max;
                   _currentLower = _currentUpper - minDistance;
               }
               _upperTextController.text = _formatValue(_currentUpper);
           }
           _lowerTextController.text = _formatValue(_currentLower);
       } else if (_isDraggingUpper) {
           _currentUpper = newValue;
           if (widget.isRange && _currentUpper < _currentLower + minDistance) {
               _currentLower = _currentUpper - minDistance;
               // Push lower bound! Let upper handle push the lower handle along the track.
               if (_currentLower < widget.min) {
                   _currentLower = widget.min;
                   _currentUpper = _currentLower + minDistance;
               }
               _lowerTextController.text = _formatValue(_currentLower);
           }
           _upperTextController.text = _formatValue(_currentUpper);
       }
       _fireChange();
    }
    
    return SizedBox(
      width: widgetWidth,
      height: widgetHeight,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // The Arc Painter
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanDown: (details) {
               _isDraggingLower = false;
               _isDraggingUpper = false;
               
               // Snap to tab immediately
               _processPan(details.localPosition, localPivot: pivotOffset);
            },
            onPanUpdate: (details) {
               _processPan(details.localPosition, localPivot: pivotOffset);
            },
            onPanEnd: _endPan,
            onPanCancel: () => _endPan(DragEndDetails()),
            child: SizedBox(
              width: widgetWidth,
              height: widgetHeight,
              child: CustomPaint(
                painter: ArcSliderPainter(
                  min: widget.min,
                  max: widget.max,
                  lowerValue: _currentLower,
                  upperValue: widget.isRange ? _currentUpper : null,
                  isRange: widget.isRange,
                  arcBaseRadius: _arcBaseRadius,
                  arcThickness: _arcThickness,
                  startAngleOffset: resolvedStartAngleOffset,
                  arcSweepAngle: widget.arcSweepAngle,
                  activeColor: widget.isMixedState ? Colors.grey : widget.activeColor,
                  inactiveColor: widget.inactiveColor,
                  showHitZones: widget.showHitZones,
                  pivotOffset: pivotOffset,
                  flipVertical: widget.flipVertical,
                  isLogarithmic: widget.isLogarithmic,
                ),
              ),
            ),
          ),
          
          // Text Input Overlays
          if (widget.showTextInput) ...[
          if (widget.orientation == ArcSliderOrientation.horizontal) ...[
              Positioned(
                 left: widget.isRange ? -5 : null, // Outward for text box
                 bottom: widget.isRange ? (widget.isDegreeFormatter ? 0 : 8) : -3, // Isolate Camera (0), move Distance up (8), move Single down (-3)
                 child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start, // Aligns container left edge perfectly
                   children: [
                     if (widget.lowerTitle != null) Padding(padding: const EdgeInsets.only(left: 8), child: Text(widget.lowerTitle!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                     Container(
                       width: 72, // Wide enough for "5000Hz"
                       height: 32,
                       decoration: BoxDecoration(
                         border: Border.all(color: Colors.black, width: 1.5), 
                         borderRadius: BorderRadius.circular(12), 
                         color: Colors.white
                       ),
                       alignment: Alignment.center,
                       child: TextField(
                         controller: _lowerTextController,
                         focusNode: _lowerFocusNode,
                         textAlign: TextAlign.center,
                         textAlignVertical: TextAlignVertical.center,
                         style: const TextStyle(fontSize: 16),
                         decoration: const InputDecoration(
                             border: InputBorder.none, 
                             isCollapsed: true, // Centers text completely vertically
                             contentPadding: EdgeInsets.only(bottom: 6), // Push text up slightly
                         ),
                         keyboardType: TextInputType.numberWithOptions(signed: true, decimal: true),
                         textInputAction: TextInputAction.done,
                         onSubmitted: _submitLowerText,
                         onTap: () {
                            _lowerTextController.selection = TextSelection(baseOffset: 0, extentOffset: _lowerTextController.text.length);
                         },
                       ),
                     )
                   ],
                 )
              ),
              
              if (widget.isRange)
                Positioned(
                   right: -5, // Outward for text box
                   bottom: widget.isDegreeFormatter ? 0 : 8, // Isolate Camera (0) and move Distance up (8)
                   child: Column(
                     crossAxisAlignment: CrossAxisAlignment.end, // Aligns container right edge perfectly
                     children: [
                       if (widget.upperTitle != null) Padding(padding: const EdgeInsets.only(right: 8), child: Text(widget.upperTitle!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                       Container(
                         width: 72, // Wide enough for "5000Hz" / "100%"
                         height: 32,
                         decoration: BoxDecoration(
                           border: Border.all(color: Colors.black, width: 1.5), 
                           borderRadius: BorderRadius.circular(12), 
                           color: Colors.white
                         ),
                         alignment: Alignment.center,
                         child: TextField(
                           controller: _upperTextController,
                           focusNode: _upperFocusNode,
                           textAlign: TextAlign.center,
                           textAlignVertical: TextAlignVertical.center,
                           style: const TextStyle(fontSize: 16),
                           decoration: const InputDecoration(
                               border: InputBorder.none, 
                               isCollapsed: true, 
                               contentPadding: EdgeInsets.only(bottom: 6), 
                           ),
                           keyboardType: TextInputType.numberWithOptions(signed: true, decimal: true),
                           textInputAction: TextInputAction.done,
                           onSubmitted: _submitUpperText,
                           onTap: () {
                              _upperTextController.selection = TextSelection(baseOffset: 0, extentOffset: _upperTextController.text.length);
                           },
                         ),
                       )
                     ],
                   )
                ),
          ] else ...[
              Positioned(
                 left: widget.orientation == ArcSliderOrientation.verticalLeft ? 0 : null,
                 right: widget.orientation == ArcSliderOrientation.verticalRight ? 0 : null,
                 top: widget.flipVertical ? null : (widgetHeight / 2) - 16,
                 bottom: widget.flipVertical ? (widgetHeight / 2) - 16 : null,
                 child: Container(
                   width: 60,
                   height: 32,
                   decoration: BoxDecoration(
                     border: Border.all(color: Colors.black, width: 1.5), 
                     borderRadius: BorderRadius.circular(12), 
                     color: Colors.white
                   ),
                   alignment: Alignment.center,
                   child: TextField(
                     controller: _lowerTextController,
                     focusNode: _lowerFocusNode,
                     textAlign: TextAlign.center,
                     textAlignVertical: TextAlignVertical.center,
                     style: const TextStyle(fontSize: 15),
                     decoration: const InputDecoration(
                         border: InputBorder.none, 
                         isCollapsed: true, 
                         contentPadding: EdgeInsets.only(bottom: 5), 
                     ),
                     keyboardType: TextInputType.numberWithOptions(signed: true, decimal: true),
                     textInputAction: TextInputAction.done,
                     onSubmitted: _submitLowerText,
                     onTap: () {
                        _lowerTextController.selection = TextSelection(baseOffset: 0, extentOffset: _lowerTextController.text.length);
                     },
                   ),
                 )
              ),
              
              if (widget.title.isNotEmpty)
                Positioned(
                   left: widget.orientation == ArcSliderOrientation.verticalLeft ? 0 : null,
                   right: widget.orientation == ArcSliderOrientation.verticalRight ? 0 : null,
                   top: widget.flipVertical ? null : (widgetHeight / 2) - 40,
                   bottom: widget.flipVertical ? (widgetHeight / 2) + 20 : null,
                   child: Text(
                       widget.title, 
                       style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)
                   )
                ),
          ]
          ]  // end showTextInput guard
        ],
      ),
    );
  }
}

class ArcSliderPainter extends CustomPainter {
  final double min;
  final double max;
  final double lowerValue;
  final double? upperValue;
  final bool isRange;
  
  final double arcBaseRadius;
  final double arcThickness;
  final double startAngleOffset;
  final double arcSweepAngle;
  final Color activeColor;
  final Color inactiveColor;
  final bool showHitZones;
  final Offset pivotOffset;
  final bool flipVertical;
  final bool isLogarithmic;

  ArcSliderPainter({
    required this.min,
    required this.max,
    required this.lowerValue,
    this.upperValue,
    required this.isRange,
    required this.arcBaseRadius,
    required this.arcThickness,
    required this.startAngleOffset,
    required this.arcSweepAngle,
    required this.activeColor,
    required this.inactiveColor,
    required this.showHitZones,
    required this.pivotOffset,
    this.flipVertical = false,
    this.isLogarithmic = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Center point
    final center = pivotOffset;

    final Paint inactivePaint = Paint()
      ..color = inactiveColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = arcThickness
      ..strokeCap = StrokeCap.butt;

    final Paint activePaint = Paint()
      ..color = activeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = arcThickness
      ..strokeCap = StrokeCap.butt;
      
    // 1. Draw inactive arc base
    double halfSweep = arcSweepAngle / 2;
    double drawStart = flipVertical ? (startAngleOffset + halfSweep) : (startAngleOffset - halfSweep);
    double dir = flipVertical ? -1.0 : 1.0;
    
    Rect rect = Rect.fromCircle(center: center, radius: arcBaseRadius);
    canvas.drawArc(rect, drawStart, arcSweepAngle * dir, false, inactivePaint);
    
    // 2. Determine active sweep
    double range = max - min;
    if (range <= 0) range = 1; // avoid div by 0
    
    double vLower;
    if (isLogarithmic && min > 0 && lowerValue >= min) {
      vLower = math.log(lowerValue / min) / math.log(max / min);
    } else {
      vLower = (lowerValue - min) / range;
    }
    double lowerAng = drawStart + arcSweepAngle * dir * vLower;
    
    // 1.5 Grey backing cap at the START of the arc — drawn BEFORE the active
    // arc so that semi-transparent active colors (e.g. brightness < 100%) blend
    // over grey rather than the card background.  The active cap in step 2.5
    // will paint on top; at full opacity the result is identical to before.
    _drawArcCap(canvas, center, arcBaseRadius, drawStart, arcThickness,
        inactiveColor, isStart: dir > 0 ? true : false);

    if (isRange) {
        double vUpper;
        if (isLogarithmic && min > 0 && upperValue! >= min) {
          vUpper = math.log(upperValue! / min) / math.log(max / min);
        } else {
          vUpper = (upperValue! - min) / range;
        }
        double upperAng = drawStart + arcSweepAngle * dir * vUpper;
        canvas.drawArc(rect, lowerAng, upperAng - lowerAng, false, activePaint);
    } else {
        canvas.drawArc(rect, drawStart, lowerAng - drawStart, false, activePaint);
    }

    // 2.5 Draw absolute caps (slightly rounded, instead of fully rounded)
    bool startIsActive = isRange ? (lowerValue == min) : true;
    _drawArcCap(canvas, center, arcBaseRadius, drawStart, arcThickness, startIsActive ? activeColor : inactiveColor, isStart: dir > 0 ? true : false);

    bool endIsActive = isRange ? (upperValue == max) : (lowerValue == max);
    _drawArcCap(canvas, center, arcBaseRadius, drawStart + arcSweepAngle * dir, arcThickness, endIsActive ? activeColor : inactiveColor, isStart: dir > 0 ? false : true);
    
    // 3. Draw Hit Zones (Debug) - Draw these first so they are underneath
    if (showHitZones) {
       Paint hitZonePaintUpper = Paint()..color = Colors.blue.withOpacity(0.3);
       Paint hitZonePaintLower = Paint()..color = Colors.green.withOpacity(0.3);
       
       double arcOuterEdge = arcBaseRadius + arcThickness / 2;
       
       double band1Outer = arcOuterEdge + 27; // Outer edge of green
       double band2Outer = band1Outer + 30; // Outer edge of blue

       double hitStart = drawStart - (0.1 * dir);
       double hitSweep = (arcSweepAngle + 0.2) * dir;

       if (isRange) {
           Paint greenBand = Paint()
             ..color = hitZonePaintLower.color
             ..style = PaintingStyle.stroke
             ..strokeWidth = (band1Outer - arcOuterEdge).abs();
           double centerOfGreenBand = (arcOuterEdge + band1Outer) / 2;
           canvas.drawArc(Rect.fromCircle(center: center, radius: centerOfGreenBand), hitStart, hitSweep, false, greenBand);
           
           Paint blueBand = Paint()
             ..color = hitZonePaintUpper.color
             ..style = PaintingStyle.stroke
             ..strokeWidth = (band2Outer - band1Outer).abs();
           double centerOfBlueBand = (band1Outer + band2Outer) / 2;
           canvas.drawArc(Rect.fromCircle(center: center, radius: centerOfBlueBand), hitStart, hitSweep, false, blueBand);
       } else {
           double singleBandOuter = arcOuterEdge + 35; 
           Paint blueBand = Paint()
             ..color = hitZonePaintUpper.color
             ..style = PaintingStyle.stroke
             ..strokeWidth = (singleBandOuter - arcOuterEdge + 15).abs();
           double centerOfBlueBand = (arcOuterEdge - 15 + singleBandOuter) / 2;
           canvas.drawArc(Rect.fromCircle(center: center, radius: centerOfBlueBand), hitStart, hitSweep, false, blueBand);
       }
    }
    
// 4. Draw Handles — use same log-aware angle as the fill arc
double upperAng;
if (isRange) {
    double vUpperH;
    if (isLogarithmic && min > 0 && upperValue! >= min) {
      vUpperH = math.log(upperValue! / min) / math.log(max / min);
    } else {
      vUpperH = (upperValue! - min) / range;
    }
  upperAng = drawStart + arcSweepAngle * dir * vUpperH;
} else {
  upperAng = lowerAng;
}

    if (isRange) {
       // Lower handle is the inner layer
       _drawHandle(canvas, center, lowerAng, arcBaseRadius, arcThickness, layer: 0);
       // Upper handle is the outer layer
       _drawHandle(canvas, center, upperAng, arcBaseRadius, arcThickness, layer: 1);
    } else {
       // Single handle
       _drawHandle(canvas, center, lowerAng, arcBaseRadius, arcThickness, layer: 0);
    }
  }

  void _drawArcCap(Canvas canvas, Offset center, double radius, double angle, double thickness, Color color, {required bool isStart}) {
     canvas.save();
     canvas.translate(center.dx, center.dy);
     canvas.rotate(angle);
     double capLen = 5.0; // Extend slightly to create a cap
     double r = 4.0; // Corner rounding radius
     RRect capRect;
     if (isStart) {
        capRect = RRect.fromRectAndCorners(
           Rect.fromCenter(center: Offset(radius, -capLen/2), width: thickness, height: capLen),
           topLeft: Radius.circular(r), 
           topRight: Radius.circular(r),
           bottomLeft: Radius.zero, 
           bottomRight: Radius.zero,
        );
     } else {
        capRect = RRect.fromRectAndCorners(
           Rect.fromCenter(center: Offset(radius, capLen/2), width: thickness, height: capLen),
           bottomLeft: Radius.circular(r), 
           bottomRight: Radius.circular(r),
           topLeft: Radius.zero, 
           topRight: Radius.zero,
        );
     }
     Paint capPaint = Paint()..color = color..style = PaintingStyle.fill;
     canvas.drawRRect(capRect, capPaint);
     canvas.restore();
  }
  
  void _drawHandle(Canvas canvas, Offset center, double angle, double baseRadius, double thickness, {required int layer}) {
    // Both handles are on the outside of the arc.
    // layer 0 is just outside. layer 1 is further outside.
    
    double halfThick = thickness / 2;
    double circleRad = 15;
    
    // Line endpoints (full width of arc + extension to the circle)
    double innerLineRadius = baseRadius - halfThick; // start at inner rim of the arc
    
    // The black line extends from the inner edge of the arc, entirely across it, and reaches to the circle handle.
    // Circle position offset
    double circleRadiusDist;
    if (layer == 0) {
       // Layer 0 is just outside the arc (r=15). Center is offset by 15 + padding.
       circleRadiusDist = baseRadius + halfThick + circleRad + 2; 
    } else {
       // Layer 1 is 20px further out than Layer 0, creating a 10px overlap between their 30px boundaries.
       // The midpoint seam is exactly 10px beyond Layer 0's center.
       circleRadiusDist = baseRadius + halfThick + circleRad + 2 + 20; 
    }
    
    double outerLineRadius = circleRadiusDist - circleRad + 2; // draw line up to the inner edge of the circle radially
    
    Offset circleCenter = Offset(
      center.dx + circleRadiusDist * math.cos(angle),
      center.dy + circleRadiusDist * math.sin(angle),
    );
    
    Offset lineStart = Offset(
      center.dx + innerLineRadius * math.cos(angle),
      center.dy + innerLineRadius * math.sin(angle),
    );
    Offset lineEnd = Offset(
      center.dx + outerLineRadius * math.cos(angle),
      center.dy + outerLineRadius * math.sin(angle),
    );
    
    // 1. Draw solid line connecting the inner and outer radius, OVER the arc
    Paint linePaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2.5 // Thinner
      ..strokeCap = StrokeCap.round;
      
    canvas.drawLine(lineStart, lineEnd, linePaint);
    
    // 2. Draw the circle handle
    Paint circlePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
      
    // Drop shadow for the circle knob
    canvas.drawShadow(Path()..addOval(Rect.fromCircle(center: circleCenter, radius: circleRad)), Colors.black, 4, true);
    canvas.drawCircle(circleCenter, circleRad, circlePaint);
    
    // Optional: Draw small black line connecting the handle fully if needed, 
    // but the mockup shows the black line only crosses the arc, and the circle touches it.
  }

  @override
  bool shouldRepaint(covariant ArcSliderPainter oldDelegate) {
    return oldDelegate.lowerValue != lowerValue || 
           oldDelegate.upperValue != upperValue ||
           oldDelegate.min != min || 
           oldDelegate.max != max;
  }
}
