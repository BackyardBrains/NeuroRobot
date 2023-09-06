import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_audio_waveforms/src/core/audio_waveform.dart';
import 'package:flutter_audio_waveforms/src/core/waveform_painters_ab.dart';
import 'package:flutter_audio_waveforms/src/util/waveform_alignment.dart';
import 'package:flutter_audio_waveforms/src/waveforms/squiggly_waveform/active_inactive_waveform_painter.dart';

/// [SquigglyWaveform] paints a squiggly waveform.
/// The painter for this waveform is of the type [ActiveInActiveWaveformPainter]
///
/// {@tool snippet}
/// Example :
/// ```dart
/// SquigglyWaveform(
///   maxDuration: maxDuration,
///   elapsedDuration: elapsedDuration,
///   samples: samples,
///   height: 300,
///   width: MediaQuery.of(context).size.width,
/// )
///```
/// {@end-tool}
class SquigglyWaveform extends AudioWaveform {
  // ignore: public_member_api_docs
  SquigglyWaveform({
    Key? key,
    required Float64List samples,
    required double height,
    required double width,
    required Duration maxDuration,
    required Duration elapsedDuration,
    this.activeColor = Colors.red,
    this.inactiveColor = Colors.blue,
    this.strokeWidth = 1.0,
    bool showActiveWaveform = true,
    bool absolute = false,
    bool invert = false,
  })  : assert(strokeWidth >= 0, "strokeWidth can't be negative."),
        super(
          key: key,
          samples: samples,
          height: height,
          width: width,
          maxDuration: maxDuration,
          elapsedDuration: elapsedDuration,
          absolute: absolute,
          invert: invert,
          showActiveWaveform: showActiveWaveform,
        );

  /// The color of the active portion of the waveform.
  final Color activeColor;

  /// The color of the inactive portion of the waveform.
  final Color inactiveColor;

  /// The stroke width of the waveform.
  final double strokeWidth;

  @override
  AudioWaveformState<SquigglyWaveform> createState() =>
      _SquigglyWaveformState();
}

class _SquigglyWaveformState extends AudioWaveformState<SquigglyWaveform> {
  @override
  void processSamples() {
    final rawSamples = widget.samples;
    // ignore: omit_local_variable_types
    Float64List processedSamples =
        Float64List.fromList(rawSamples.map((e) => e.abs() * widget.height.floor()).toList());

    final maxNum =
        processedSamples.reduce((a, b) => math.max(a.abs(), b.abs()));

    if (maxNum > 0) {
      final multiplier = math.pow(maxNum, -1).toDouble();
      final finalHeight = absolute ? widget.height : widget.height / 2;
      final finalMultiplier = multiplier * finalHeight;

      processedSamples = Float64List.fromList(processedSamples
          .map(
            (e) => e * finalMultiplier.floor(),
          )
          .toList());
    }
    updateProcessedSamples(processedSamples);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.samples.isEmpty) {
      return const SizedBox.shrink();
    }
    final processedSamples = this.processedSamples;
    final activeRatio = showActiveWaveform
        ? elapsedDuration.inMilliseconds / maxDuration.inMilliseconds
        : 0.0;
    final waveformAlignment = this.waveformAlignment;

    return RepaintBoundary(
      child: CustomPaint(
        size: Size(widget.width, widget.height),
        isComplex: true,
        painter: SquigglyWaveformPainter(
          samples: processedSamples,
          activeColor: widget.activeColor,
          inactiveColor: widget.inactiveColor,
          activeRatio: activeRatio,
          waveformAlignment: waveformAlignment,
          absolute: widget.absolute,
          invert: widget.invert,
          strokeWidth: widget.strokeWidth,
          sampleWidth: sampleWidth,
        ),
      ),
    );
  }
}
