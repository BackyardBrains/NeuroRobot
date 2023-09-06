import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_audio_waveforms/flutter_audio_waveforms.dart';
import 'package:flutter_audio_waveforms/src/core/audio_waveform.dart';
import 'package:flutter_audio_waveforms/src/waveforms/polygon_waveform/active_waveform_painter.dart';
import 'package:flutter_audio_waveforms/src/waveforms/polygon_waveform/inactive_waveform_painter.dart';

/// [PolygonWaveform] paints the standard waveform that is used for audio
/// waveforms, a sharp continuous line joining the points of a waveform.
///
/// {@tool snippet}
/// Example :
/// ```dart
/// PolygonWaveform(
///   maxDuration: maxDuration,
///   elapsedDuration: elapsedDuration,
///   samples: samples,
///   height: 300,
///   width: MediaQuery.of(context).size.width,
/// )
///```
/// {@end-tool}
class PolygonWaveform extends AudioWaveform {
  // ignore: public_member_api_docs
  PolygonWaveform({
    Key? key,
    required Float64List samples,
    required double height,
    required double width,
    required Duration maxDuration,
    required Duration elapsedDuration,
    this.activeColor = Colors.red,
    this.inactiveColor = Colors.blue,
    this.activeGradient,
    this.inactiveGradient,
    this.style = PaintingStyle.stroke,
    bool showActiveWaveform = true,
    bool absolute = false,
    bool invert = false,
    this.channelIdx = 0,
    this.channelActive = 0,
    this.gain = 1000,
    this.levelMedian = -1,
    this.strokeWidth = 1,
    this.eventMarkersNumber = const [],
    this.eventMarkersPosition = const [],
  }) : super(
          key: key,
          samples: samples,
          height: height,
          width: width,
          maxDuration: maxDuration,
          elapsedDuration: elapsedDuration,
          showActiveWaveform: showActiveWaveform,
          absolute: absolute,
          invert: invert,
        );

  /// active waveform color
  final Color activeColor;

  /// inactive waveform color
  final Color inactiveColor;

  /// active waveform gradient
  final Gradient? activeGradient;

  /// inactive waveform gradient
  final Gradient? inactiveGradient;

  /// waveform style
  final PaintingStyle style;

  final int channelIdx;
  final int channelActive;
  final double gain;
  final double levelMedian;
  final double strokeWidth;

  final List<int> eventMarkersNumber;
  final List<double> eventMarkersPosition;

  @override
  AudioWaveformState<PolygonWaveform> createState() => _PolygonWaveformState();
}

class _PolygonWaveformState extends AudioWaveformState<PolygonWaveform> {
  @override
  Widget build(BuildContext context) {
    if (widget.samples.isEmpty) {
      return const SizedBox.shrink();
    }
    final processedSamples = this.processedSamples;
    final activeSamples = this.activeSamples;
    final showActiveWaveform = this.showActiveWaveform;
    //STEVANUS CHANGES
    // final sampleWidth = this.sampleWidth;
    // final waveformAlignment = this.waveformAlignment;
    final waveformAlignment = WaveformAlignment.center;
    final sampleWidth = this.sampleWidth;
    // final testSamples = List<double>.from(processedSamples);
    // testSamples.sort();
    // print(testSamples[testSamples.length-1]);
    return Stack(
      children: [
        RepaintBoundary(
          child: CustomPaint(
            size: Size(widget.width, widget.height),
            isComplex: false,
            willChange: true,
            painter: PolygonInActiveWaveformPainter(
              samples: processedSamples,
              style: widget.style,
              channelIdx: widget.channelIdx,
              channelActive: widget.channelActive,
              color: widget.inactiveColor,
              gradient: widget.inactiveGradient,
              waveformAlignment: waveformAlignment,
              sampleWidth: sampleWidth,
              gain: widget.gain,
              levelMedian: widget.levelMedian,
              strokeWidth: widget.strokeWidth,
              eventMarkersNumber: widget.eventMarkersNumber,
              eventMarkersPosition: widget.eventMarkersPosition,
            ),
          ),
        ),
        // if (showActiveWaveform)
        //   RepaintBoundary(
        //     child: CustomPaint(
        //       isComplex: true,
        //       size: Size(widget.width, widget.height),
        //       painter: PolygonActiveWaveformPainter(
        //         style: widget.style,
        //         color: widget.activeColor,
        //         activeSamples: activeSamples,
        //         gradient: widget.activeGradient,
        //         waveformAlignment: waveformAlignment,
        //         sampleWidth: sampleWidth,
        //       ),
        //     ),
        //   ),
      ],
    );
  }
}
