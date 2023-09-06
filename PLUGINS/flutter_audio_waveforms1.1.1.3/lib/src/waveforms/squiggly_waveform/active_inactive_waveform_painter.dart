import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_audio_waveforms/src/util/waveform_alignment.dart';
import 'package:flutter_audio_waveforms/src/core/waveform_painters_ab.dart';
import 'package:flutter_audio_waveforms/src/waveforms/squiggly_waveform/squiggly_waveform.dart';

///Painter for the [SquigglyWaveform]
/// Handles Painting both InActive and Active Waveforms.
class SquigglyWaveformPainter extends ActiveInActiveWaveformPainter {
  // ignore: public_member_api_docs
  SquigglyWaveformPainter({
    required Color activeColor,
    required Float64List samples,
    required Color inactiveColor,
    required double activeRatio,
    required WaveformAlignment waveformAlignment,
    required double sampleWidth,
    required double strokeWidth,
    required this.absolute,
    required this.invert,
  }) : super(
          samples: samples,
          activeColor: activeColor,
          inactiveColor: inactiveColor,
          activeRatio: activeRatio,
          waveformAlignment: waveformAlignment,
          sampleWidth: sampleWidth,
          strokeWidth: strokeWidth,
        );

  ///Whether to draw the absolute waveform or not
  final bool absolute;

  ///Whether to invert the waveform or not
  final bool invert;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..shader = LinearGradient(
        begin: const Alignment(-1.001, 0),
        end: const Alignment(1.001, 0),
        colors: [activeColor, inactiveColor],
        stops: [activeRatio, 0],
      ).createShader(
        Rect.fromLTWH(0, 0, size.width, size.height),
      );

    final waveformPath = Path();
    if (!absolute) {
      paintDefaultWaveform(waveformPath, sampleWidth, invert);
    } else if (absolute && !invert) {
      downwardFacingAbsoluteWaveform(waveformPath, sampleWidth);
    } else {
      upwardFacingAbsoluteWaveform(waveformPath, sampleWidth);
    }

    final alignPosition = waveformAlignment.getAlignPosition(size.height);

    final shiftedPath = waveformPath.shift(Offset(0, alignPosition));

    canvas.drawPath(shiftedPath, paint);
  }

  /// Draws the default waveform
  // ignore: avoid_positional_boolean_parameters
  void paintDefaultWaveform(Path waveformPath, double pointWidth, bool invert) {
    for (var i = 0; i < samples.length; i++) {
      final value = samples[i];
      final upOrDown = invert ? i.isOdd : i.isEven;
      final x = pointWidth * i;
      final x2 = pointWidth * (i + 1);
      final y2 = i != samples.length - 1
          ? upOrDown
              ? -value
              : value
          : 0.0;
      final diameter = x2 - x;
      final radius = diameter / 2;
      waveformPath
        ..lineTo(x, y2.toDouble())
        ..lineTo(x, upOrDown ? y2.toDouble() - diameter : y2 + diameter)
        ..addArc(
          Rect.fromCircle(
            center:
                Offset(x2 - radius, upOrDown ? y2 - diameter : y2 + diameter),
            radius: radius,
          ),
          -math.pi,
          upOrDown ? math.pi : -math.pi,
        )
        ..lineTo(x2, y2.toDouble());
    }
  }

  /// Draws the downward facing absolute waveform
  void upwardFacingAbsoluteWaveform(Path waveformPath, double pointWidth) {
    for (var i = 0; i < samples.length; i++) {
      final value = samples[i];
      final x = pointWidth * i;
      final x2 = pointWidth * (i + 1);
      final y2 = value;
      final diameter = x2 - x;
      final radius = diameter / 2;
      waveformPath
        ..lineTo(x, y2.toDouble())
        ..lineTo(x, y2.toDouble() + diameter)
        ..addArc(
          Rect.fromCircle(
            center: Offset(x2 - radius, y2.toDouble() + diameter),
            radius: radius,
          ),
          -math.pi,
          -math.pi,
        )
        ..lineTo(x2, 0);
    }
    waveformPath.lineTo(0, 0);
  }

  /// Draws the upward facing absolute waveform
  void downwardFacingAbsoluteWaveform(Path waveformPath, double pointWidth) {
    for (var i = 0; i < samples.length; i++) {
      final value = samples[i];
      final x = pointWidth * i;
      final x2 = pointWidth * (i + 1);
      final y2 = -value;
      final diameter = x2 - x;
      final radius = diameter / 2;
      waveformPath
        ..lineTo(x, y2.toDouble())
        ..lineTo(x, y2.toDouble() - diameter)
        ..addArc(
          Rect.fromCircle(
            center: Offset(x2 - radius, y2.toDouble() - diameter),
            radius: radius,
          ),
          math.pi,
          math.pi,
        )
        ..lineTo(x2, 0);
    }

    waveformPath.lineTo(0, 0);
  }
}
