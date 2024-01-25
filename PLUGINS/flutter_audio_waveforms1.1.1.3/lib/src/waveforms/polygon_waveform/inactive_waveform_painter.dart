import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_audio_waveforms/src/core/waveform_painters_ab.dart';
import 'package:flutter_audio_waveforms/src/util/waveform_alignment.dart';
import 'package:flutter_audio_waveforms/src/waveforms/polygon_waveform/polygon_waveform.dart';

///InActiveWaveformPainter for the [PolygonWaveform]
class PolygonInActiveWaveformPainter extends InActiveWaveformPainter {
  // ignore: public_member_api_docs
  final int channelIdx;
  final int channelActive;
  final double gain;
  final double levelMedian;
  final double strokeWidth;
  final List<int> eventMarkersNumber;
  final List<double> eventMarkersPosition;

  double prevMax = 0;
  double curMax = 0;

  List<TextPainter> textPainters = [];
  late Paint mypaint;
  late Paint myCurrentBarPaint;

  PolygonInActiveWaveformPainter({
    Color color = Colors.white,
    Gradient? gradient,
    required Float64List samples,
    required WaveformAlignment waveformAlignment,
    required PaintingStyle style,
    required double sampleWidth,
    this.channelIdx = 0,
    this.channelActive = 1,
    this.gain = 1000,
    this.levelMedian = -1,
    this.strokeWidth = 0.5,
    this.eventMarkersNumber = const [],
    this.eventMarkersPosition = const [],
  }) : super(
          samples: samples,
          color: color,
          gradient: gradient,
          waveformAlignment: waveformAlignment,
          sampleWidth: sampleWidth,
          style: style,
        ) {
    mypaint = Paint()
      ..style = style
      ..isAntiAlias = false
      ..shader = null
      ..color = color
      ..strokeWidth = this.strokeWidth;
    myCurrentBarPaint = Paint()
          ..style = PaintingStyle.stroke
          ..color = Color.fromARGB(255, 255, 80, 0)
          ..strokeWidth = 1;

  }

  @override
  bool shouldRepaint(PolygonInActiveWaveformPainter oldDelegate) {
    if (oldDelegate.gain != gain ||
        oldDelegate.samples != samples ||
        oldDelegate.levelMedian != levelMedian ||
        oldDelegate.eventMarkersPosition != eventMarkersPosition) {
      return true;
    }
    return false;
  }

  /// Style of the waveform
  int sign = 1;
  // https://groups.google.com/g/flutter-dev/c/Za4M3U_MaAo?pli=1
  // Performance textPainter vs Paragraph https://stackoverflow.com/questions/51640388/flutter-textpainter-vs-paragraph-for-drawing-book-page
  @override
  void paint(Canvas canvas, Size size) {
    try {
      // ..shader = gradient?.createShader(
      //   Rect.fromLTWH(0, 0, size.width, size.height),
      // );

      final path = Path();
      int i = 0;
      double prevX=0;
      double prevY=0;
      for (; i < samples.length - 1; i++) {
        final x = sampleWidth * i;
        final y = -(samples[i]>30?30:samples[i])/gain ;
        prevX = x;
        prevY = y;
        path.lineTo(x, y);
      }
      // print(samples);
      // print('gain');
      // print(gain);
      //END TAIL
      // final sLen = samples.length - 1;
      // final x = sampleWidth * sLen;
      // final y = samples[sLen];
      // path.moveTo(x, 0);
      // path.lineTo(x, y);
      // path.moveTo(x, y);
      final shiftedPath = path.shift(Offset(0, levelMedian));
      final rect = Rect.fromLTWH(0, 0, size.width, size.height);
      canvas.clipRect(rect, doAntiAlias:false);
      canvas.drawPath(shiftedPath, mypaint);

      // if (channelIdx == 0){
        final evX = eventMarkersPosition[0] * sampleWidth;
        final offset1 = Offset(evX, 0);
        final offset2 = Offset(evX, 900);
        // final spikingLine1 = new Offset(0, -30/gain + levelMedian);
        // final spikingLine2 = new Offset(1200, -30/gain + levelMedian);


        // final offset2 = new Offset(evX, size.height * 2);
        // linePath.lineTo(evX, 900);
        // sign = sign * -1;
        canvas.drawLine(
          offset1,
          offset2,
          myCurrentBarPaint,
        );        
        // canvas.drawLine(
        //   spikingLine1,
        //   spikingLine2,
        //   myCurrentBarPaint,
        // );        

      // }

    } catch (err) {
      print("errx");
      print(err);
    }
  }
}
