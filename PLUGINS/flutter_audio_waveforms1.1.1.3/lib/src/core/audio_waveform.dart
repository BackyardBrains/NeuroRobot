import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_audio_waveforms/src/core/waveform_painters_ab.dart';
import 'package:flutter_audio_waveforms/src/util/check_samples_equality.dart';
import 'package:flutter_audio_waveforms/src/util/waveform_alignment.dart';

/// [AudioWaveform] is a custom StatefulWidget that other Waveform classes
/// extend to.
///
/// This class handles the common functionality, properties and provides the
/// most common waveform details to the subclasses. This details then can be
/// used by the [WaveformPainter] to paint the waveform.
///
/// Anything that can be shared and used across all waveforms should
/// be handled by this class.
///
abstract class AudioWaveform extends StatefulWidget {
  /// Constructor for [AudioWaveform]
  AudioWaveform({
    Key? key,
    required this.samples,
    required this.height,
    required this.width,
    required this.maxDuration,
    required this.elapsedDuration,
    required this.showActiveWaveform,
    this.absolute = false,
    this.invert = false,
  })  : assert(
          elapsedDuration.inMilliseconds <= maxDuration.inMilliseconds,
          'elapsedDuration must be less than or equal to maxDuration',
        ),
        assert(
          maxDuration.inMilliseconds > 0,
          'maxDuration must be greater than 0',
        ),
        waveformAlignment = absolute
            ? invert
                ? WaveformAlignment.top
                : WaveformAlignment.bottom
            : WaveformAlignment.center,
        super(key: key);

  /// Audio samples raw input.
  /// This raw samples are processed before being used to paint the waveform.
  final Float64List samples;

  /// Height of the canvas on which the waveform will be drawn.
  final double height;

  /// Width of the canvas on which the waveform will be drawn.
  final double width;

  /// Maximum duration of the audio.
  final Duration maxDuration;

  /// Elapsed duration of the audio.
  final Duration elapsedDuration;

  /// Makes the waveform absolute.
  /// Draws the waveform along the positive y-axis.
  /// Samples are processed such that we end up with positive sample values.
  final bool absolute;

  /// Inverts/Flips the waveform along x-axis.
  /// Samples are processed such that we end up with samples having opposite
  /// sign.
  final bool invert;

  /// Whether to show the active waveform or not.
  final bool showActiveWaveform;

  /// Alignment of the waveform in the canvas.
  @protected
  final WaveformAlignment waveformAlignment;

  @override
  AudioWaveformState<AudioWaveform> createState();
}

/// State of the [AudioWaveform]
abstract class AudioWaveformState<T extends AudioWaveform> extends State<T> {
  /// Samples after processing.
  /// This are used to paint the waveform.
  late Float64List _processedSamples;

  ///Getter for processed samples.
  Float64List get processedSamples => _processedSamples;

  late double _sampleWidth;

  ///Getter for sample width.
  double get sampleWidth => _sampleWidth;

  ///Method for subsclass to update the processed samples
  @protected
  // ignore: use_setters_to_change_properties
  void updateProcessedSamples(Float64List updatedSamples) {
    _processedSamples = updatedSamples;
  }

  /// Active index of the sample in the raw samples.
  ///
  /// Used to obtain the [activeSamples] for the audio as the
  /// audio progresses.
  /// This is calculated based on the [elapsedDuration], [maxDuration] and the
  /// raw samples.
  ///
  /// final elapsedTimeRatio = elapsedDuration.inMilliseconds / maxDuration.inMilliseconds;
  /// _activeIndex = (widget.samples.length * elapsedTimeRatio).round();
  late int _activeIndex;

  /// Active samples that are used to draw the ActiveWaveform.
  /// This are calculated using [_activeIndex] and are subList of the
  /// [_processedSamples] at any given time.
  late Float64List _activeSamples;

  ///Getter for active samples.
  Float64List get activeSamples => _activeSamples;

  ///Getter for maxDuration
  Duration get maxDuration => widget.maxDuration;

  ///getter for elapsedDuration
  Duration get elapsedDuration => widget.elapsedDuration;

  ///Whether to show active waveform or not
  bool get showActiveWaveform => widget.showActiveWaveform;

  ///Whether to invert/flip waveform or not
  bool get invert => widget.absolute ? !widget.invert : widget.invert;

  ///Whether to show absolute waveform or not
  bool get absolute => widget.absolute;

  ///Getter for waveformAlignment.
  WaveformAlignment get waveformAlignment => widget.waveformAlignment;

  /// Raw samples are processed before used following some
  /// techniques. This is to have consistent samples that can be used to draw
  /// the waveform properly.
  @protected
  void processSamples() {
    _processedSamples = widget.samples;
    // final rawSamples = widget.samples;

    // _processedSamples = rawSamples
    //     .map((e) => absolute ? e.abs() * widget.height : e * widget.height)
    //     .toList();

    // // final maxNum =
    // //     _processedSamples.reduce((a, b) => math.max(a.abs(), b.abs()));

    // //STEVANUS CHANGES
    // final maxNum = 300;

    // if (maxNum > 0) {
    //   final multiplier = math.pow(maxNum, -1).toDouble();
    //   final finalHeight = absolute ? widget.height : widget.height / 2;
    //   final finalMultiplier = multiplier * finalHeight;

    //   _processedSamples = _processedSamples
    //       .map(
    //         (e) => invert ? -e * finalMultiplier : e * finalMultiplier,
    //       )
    //       .toList();
    // }
  }

  /// Calculates the width that each sample would take.
  /// This is later used in the Painters to calculate the Offset along x-axis
  /// from the start for any sample while painting.
  void _calculateSampleWidth() {
    _sampleWidth = widget.width / (_processedSamples.length);
  }

  /// Updates the [_activeIndex] whenever the duration changes.
  @protected
  void _updateActiveIndex() {
    // if (activeIndex != null) {
    //   _activeIndex = activeIndex;

    //   return;
    // }
    final elapsedTimeRatio =
        elapsedDuration.inMilliseconds / maxDuration.inMilliseconds;

    _activeIndex = (widget.samples.length * elapsedTimeRatio).round();
  }

  /// Updates [_activeSamples] based on the [_activeIndex].
  @protected
  void _updateActiveSamples() {
    _activeSamples = _processedSamples.sublist(0, _activeIndex);
  }

  @override
  void initState() {
    super.initState();

    _processedSamples = widget.samples;
    _activeIndex = 0;
    // _activeSamples = [];
    _activeSamples = Float64List(0);
    _sampleWidth = 0;

    if (_processedSamples.isNotEmpty) {
      processSamples();
      _calculateSampleWidth();
    }
  }

  @override
  void didUpdateWidget(covariant T oldWidget) {
    super.didUpdateWidget(oldWidget);
    // if (!checkforSamplesEquality(widget.samples, oldWidget.samples) &&
    if (widget.samples.isNotEmpty) {
      processSamples();
      _calculateSampleWidth();
      _updateActiveIndex();
      _updateActiveSamples();
    }
    if (widget.showActiveWaveform) {
      if (widget.elapsedDuration != oldWidget.elapsedDuration) {
        _updateActiveIndex();
        _updateActiveSamples();
      }
    }
    if (widget.height != oldWidget.height || widget.width != oldWidget.width) {
      processSamples();
      _calculateSampleWidth();
      _updateActiveSamples();
    }
    if (widget.absolute != oldWidget.absolute) {
      processSamples();
      _updateActiveSamples();
    }
    if (widget.invert != oldWidget.invert) {
      processSamples();
      _updateActiveSamples();
    }
  }
}
