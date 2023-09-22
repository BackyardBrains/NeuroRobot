import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_audio_waveforms/flutter_audio_waveforms.dart';
import 'package:nativec/nativec.dart';
//https://stackoverflow.com/questions/54797911/flutter-where-to-add-listeners-in-statelesswidget
class WaveWidget extends StatefulWidget {
  WaveWidget({ super.key, required this.valueNotifier,required this.chartGain, required this.screenWidth, required this.screenHeight, 
      required this.levelMedian});
  double chartGain;
  double screenWidth;
  double screenHeight;
  double levelMedian;
  static Int16List positionsBufView = Int16List(0);
  static Float64List canvasBufferBytes1 = Float64List(0);
  // ValueListenable<int> valueListenable;
  ValueNotifier<int> valueNotifier;
  // final ValueChanged<int> onChange;
  // final Widget child;  

  @override
  State<WaveWidget> createState() => _WaveWidgetState();
}

class _WaveWidgetState extends State<WaveWidget> {
  @override
  Widget build(BuildContext context) {
    return PolygonWaveform(
      activeColor: Colors.black,
      inactiveColor: Colors.black,
      gain:widget.chartGain,
      channelIdx: 0,
      channelActive: 0,
      levelMedian:widget.levelMedian,
      // levelMedian:0,
      strokeWidth: 1.0,

      height: widget.screenHeight/2-130,
      width: widget.screenWidth-20, 
      // samples: WaveWidget.canvasBufferBytes1, 
      samples: Nativec.canvasBufferBytes1, 
      // samples: Float64List(0), 
      maxDuration: const Duration(seconds:3), 
      elapsedDuration: const Duration(seconds:1),
      eventMarkersPosition: [WaveWidget.positionsBufView[0].toDouble()],
    );
  }
    @override
  void didUpdateWidget(oldWidget) {
    super.didUpdateWidget(oldWidget);
    // if (oldWidget.valueListenable != widget.valueListenable) {
    //   oldWidget.valueListenable?.removeListener(_listener);
    //   widget.valueListenable?.addListener(_listener);
    //   _listener();
    // }
  }

  @override
  void dispose() {
    // widget.valueListenable.removeListener(_listener);
    widget.valueNotifier.removeListener(_listener);
    super.dispose();
  }  
  void _listener() {
    // widget.onChange?.call(widget.valueListenable.value);
    // print("stateful setstate");
    setState(() {
      
    });
  }  

  void initState() {
    super.initState();
    widget.valueNotifier.addListener(_listener);
  }  
}

