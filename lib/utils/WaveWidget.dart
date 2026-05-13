import 'dart:async';
import 'package:spikerbot/utils/platform_imports.dart';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_audio_waveforms/flutter_audio_waveforms.dart';
// WEB CHANGE
import 'package:spikerbot/stubs/nativec_imports.dart';

// import 'package:spikerbox_architecture/models/microphone_stream/microphone_stream.dart'
// if (dart.library.io) 'package:spikerbox_architecture/models/microphone_stream/microphone_stream_native.dart'
// if (dart.library.html) 'package:spikerbox_architecture/models/microphone_stream/microphone_stream_web.dart';
//https://stackoverflow.com/questions/54797911/flutter-where-to-add-listeners-in-statelesswidget
class WaveWidget extends StatefulWidget {
  WaveWidget(
      {super.key,
      required this.valueNotifier,
      required this.chartGain,
      required this.screenWidth,
      required this.screenHeight,
      required this.levelMedian,
      this.initialVisibleSeconds = 2.0,
      this.neuronIdx1 = -1,
      this.neuronIdx2 = -1,
      this.onVisibleSecondsChanged});
  int neuronIdx1;
  int neuronIdx2;
  double chartGain;
  double screenWidth;
  double screenHeight;
  double levelMedian;
  double initialVisibleSeconds;
  final ValueChanged<double>? onVisibleSecondsChanged;
  // True while the pointer is hovering over this widget. Used by _globalScrollRoute
  // to yield trackpad scroll events to this widget instead of panning the canvas.
  static bool isMouseOver = false;
  static Int16List positionsBufView = Int16List(0);

  // static Float64List canvasBufferBytes1 = Float64List(0); // Deprecated: Use Nativec.canvasBufferBytes1
  // ValueListenable<int> valueListenable;
  ValueNotifier<int> valueNotifier;
  // final ValueChanged<int> onChange;
  // final Widget child;

  @override
  State<WaveWidget> createState() => _WaveWidgetState();
}

class _WaveWidgetState extends State<WaveWidget> {
  GlobalKey waveKey = GlobalKey();
  double rightGap = 20;
  bool isGapCalculated = false;
  double visibleWindowSeconds = 2.0; // Default zoom level (within 3s limit)
  double _scaleStartSeconds = 2.0; // Captures zoom level at gesture start
  static const int sampleRate = 1000; // Corrected: C++ ms_per_step=1 means 1000Hz
  static const int visualOffset = 0; // Optional: Shift data left (positive) or right (negative)


  void _handleScroll(PointerSignalEvent event) {
    if (event is PointerScrollEvent) {
      // Register with the resolver so WaveWidget wins over the global trackpad
      // scroll route (which also calls register). Being the deepest hit widget,
      // our registration takes priority, preventing canvas pan while over the plot.
      GestureBinding.instance.pointerSignalResolver.register(event, (PointerSignalEvent resolved) {
        if (resolved is PointerScrollEvent) {
          setState(() {
            double dy = resolved.scrollDelta.dy;
            double zoomFactor = 0.1;
            if (dy > 0) {
              visibleWindowSeconds *= (1 + zoomFactor);
            } else {
              visibleWindowSeconds /= (1 + zoomFactor);
            }
            if (visibleWindowSeconds < 0.5) visibleWindowSeconds = 0.5;
            if (visibleWindowSeconds > 10.0) visibleWindowSeconds = 10.0;
            widget.onVisibleSecondsChanged?.call(visibleWindowSeconds);
          });
        }
      });
    }
  }

  Float64List _getOrderedSamples(List<double> sourceData) {
    int numSamples = (visibleWindowSeconds * sampleRate).toInt();
    
    // Simple Tail View
    List<double> viewData;
    
    if (sourceData.length >= numSamples) {
      viewData = sourceData.sublist(sourceData.length - numSamples);
    } else {
      // Pad Left
      int padding = numSamples - sourceData.length;
      viewData = List<double>.filled(padding, 0.0) + sourceData;
    }
    
    // Debug to confirm flow
    // if (_plotData.isNotEmpty) print("Plot Head: ${_plotData.last} Len: ${_plotData.length}");
    
    return Float64List.fromList(viewData);
  }

  @override
  Widget build(BuildContext context) {
      return LayoutBuilder(
        builder: (context, constraint) {
          // Detect Dual Mode
          bool isDual = (widget.neuronIdx1 != -1 && widget.neuronIdx2 != -1);
          
          double boxH = constraint.maxHeight;
          double midLine = boxH / 2;
          
          const double vMax = 30.0;
          const double vMin = -115.0;
          const double vRange = vMax - vMin;

          // CHANNEL 1 CONFIG (Orange)
          double topY1, bottomY1;
          if (isDual) {
            topY1 = 10.0;
            bottomY1 = midLine - 5.0;
          } else {
            topY1 = 15.0;
            bottomY1 = boxH - 15.0;
          }
          double h1 = bottomY1 - topY1;
          if (h1 < 10) h1 = 10;
          double pxPerVolt1 = h1 / vRange;
          double gain1 = 1.0 / pxPerVolt1;
          double median1 = topY1 + (vMax * pxPerVolt1);

          // CHANNEL 2 CONFIG (Blue)
          double topY2, bottomY2;
          if (isDual) {
             topY2 = midLine + 5.0;
             bottomY2 = boxH - 10.0;
          } else {
             // If ONLY Blue is active (Single Mode), it takes full screen
             topY2 = 15.0;
             bottomY2 = boxH - 15.0;
          }
          double h2 = bottomY2 - topY2;
          if (h2 < 10) h2 = 10;
          double pxPerVolt2 = h2 / vRange;
          double gain2 = 1.0 / pxPerVolt2;
          double median2 = topY2 + (vMax * pxPerVolt2);

          // Get Data
          Float64List samples = _getOrderedSamples(_plotData);
          
          // If both channels are inactive/empty, show blank.
          if (samples.isEmpty && widget.neuronIdx2 == -1) {
             return Container(color: Colors.black);
          }

          return MouseRegion(
            onEnter: (_) { WaveWidget.isMouseOver = true; },
            onExit: (_) { WaveWidget.isMouseOver = false; },
            child: GestureDetector(
              // Pinch-to-zoom (macOS trackpad / iOS two-finger pinch).
              // PointerPanZoomEvent is used for pinch — not intercepted by global scroll route.
              onScaleStart: (d) { _scaleStartSeconds = visibleWindowSeconds; },
              onScaleUpdate: (d) {
                if ((d.scale - 1.0).abs() > 0.01) {
                  setState(() {
                    visibleWindowSeconds = (_scaleStartSeconds / d.scale).clamp(0.5, 10.0);
                    widget.onVisibleSecondsChanged?.call(visibleWindowSeconds);
                  });
                }
              },
              child: Listener(
                onPointerSignal: _handleScroll, // Mouse-wheel + trackpad 2-finger scroll

            child: Container(
              height: constraint.maxHeight,
              width: constraint.maxWidth,
              color: Colors.black,
              child: Stack(children: [
              if (widget.neuronIdx1 != -1)
                PolygonWaveform(
                  key: waveKey,
                  activeColor: const Color(0xFFFF785B),
                  inactiveColor: const Color(0xFFFF785B),
                  gain: gain1,
                  channelIdx: 0,
                  channelActive: 0,
                  levelMedian: median1,
                  strokeWidth: 1.0,
                  samples: samples,
                  height: constraint.maxHeight, 
                  width: constraint.maxWidth, 
                  maxDuration: Duration(milliseconds: (visibleWindowSeconds * 1000).toInt()),
                  elapsedDuration: Duration(milliseconds: (visibleWindowSeconds * 1000).toInt()),
                  eventMarkersPosition: [],
                ),
              if (widget.neuronIdx2 != -1)
                IgnorePointer( // Allow gestures to pass to bottom layer
                  child: PolygonWaveform(
                    key: ValueKey("wave2_${widget.neuronIdx2}"),
                    activeColor: const Color(0xFF00BFFF), // Blue Pin Color
                    inactiveColor: const Color(0xFF00BFFF),
                    gain: gain2,
                    channelIdx: 0,
                    channelActive: 0,
                    levelMedian: median2,
                    strokeWidth: 1.0,
                    samples: _getOrderedSamples(_plotData2),
                    height: constraint.maxHeight,
                    width: constraint.maxWidth,
                    maxDuration: Duration(milliseconds: (visibleWindowSeconds * 1000).toInt()),
                    elapsedDuration: Duration(milliseconds: (visibleWindowSeconds * 1000).toInt()),
                    eventMarkersPosition: [],
                  ),
                ),
              ], // End Stack Children
             ), // End Stack
            ), // End Container
              ), // End Listener
            ), // End GestureDetector
          ); // End MouseRegion
        },
      );
  }

  @override
  void didUpdateWidget(oldWidget) {
    super.didUpdateWidget(oldWidget);
    // if (oldWidget.valueListenable != widget.valueListenable) {
    //   oldWidget.valueListenable?.removeListener(_listener);
    //   widget.valueListenable?.addListener(_listener);
    //   // _preFillData(); // Disabled to prevent Mixed History artifacts (Step 2168)
    //   _listener();
    // }
  }

  @override
  void dispose() {
    widget.valueNotifier.removeListener(_markDirty);
    _redrawTimer?.cancel();
    super.dispose();
  }

  // Accumulator State
  List<double> _plotData = []; 
  List<double> _plotData2 = [];
  int _lastHead = 0;
  int _lastHead2 = 0;
  static const int maxHistorySamples = 1000 * 10; // 10s history @ 1000Hz (Reverted to 10s)

  void _updateData() {
    if (WaveWidget.positionsBufView.isEmpty) return;
    int currentHead = WaveWidget.positionsBufView[0];
    int bufferLen = Nativec.canvasBufferBytes1.length;
    
    // Safety check
    if (currentHead < 0 || currentHead >= bufferLen) return;
    
    // CHANNEL 1
    if (Nativec.canvasBufferBytes1.isNotEmpty) {
      List<double> newSamples = [];
      if (currentHead >= _lastHead) {
        if (currentHead > _lastHead) {
           newSamples = Nativec.canvasBufferBytes1.sublist(_lastHead, currentHead);
        }
      } else {
        newSamples.addAll(Nativec.canvasBufferBytes1.sublist(_lastHead, bufferLen));
        newSamples.addAll(Nativec.canvasBufferBytes1.sublist(0, currentHead));
      }
      
      if (newSamples.isNotEmpty) {
        _plotData.addAll(newSamples);
        if (_plotData.length > maxHistorySamples) {
           _plotData.removeRange(0, _plotData.length - maxHistorySamples);
        }
        _lastHead = currentHead;
      }
    }

    // CHANNEL 2 (Only if active)
    if (widget.neuronIdx2 != -1 && Nativec.canvasBufferBytes2.isNotEmpty) {
       List<double> newSamples2 = [];
       if (currentHead >= _lastHead2) {
         if (currentHead > _lastHead2) {
            newSamples2 = Nativec.canvasBufferBytes2.sublist(_lastHead2, currentHead);
         }
       } else {
         newSamples2.addAll(Nativec.canvasBufferBytes2.sublist(_lastHead2, bufferLen));
         newSamples2.addAll(Nativec.canvasBufferBytes2.sublist(0, currentHead));
       }

       if (newSamples2.isNotEmpty) {
         _plotData2.addAll(newSamples2);
         if (_plotData2.length > maxHistorySamples) {
            _plotData2.removeRange(0, _plotData2.length - maxHistorySamples);
         }
         _lastHead2 = currentHead;
       }
    }
  }

  // Flag set by valueNotifier; timer reads+clears it at 30fps.
  bool _dirty = false;
  Timer? _redrawTimer;

  void _markDirty() {
    _dirty = true; // no setState here — let the timer batch it
  }

  void _listener() {
    _updateData();
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    visibleWindowSeconds = widget.initialVisibleSeconds;
    // valueNotifier only sets a dirty flag; timer throttles actual redraws to 30fps.
    widget.valueNotifier.addListener(_markDirty);
    _redrawTimer = Timer.periodic(const Duration(milliseconds: 16), (_) { // 60fps
      if (!mounted || !_dirty) return;
      _dirty = false;
      _updateData();
      setState(() {});
    });
    
    // Pre-Fill buffer from C++ history if available
    // RESTORED: To show full history of newly selected neuron
    if (WaveWidget.positionsBufView.isNotEmpty && Nativec.canvasBufferBytes1.isNotEmpty) {
       int head = WaveWidget.positionsBufView[0];
       int len = Nativec.canvasBufferBytes1.length;
       
       // Safety Clamp
       if (head < 0) head = 0;
       if (head > len) head = len;
       
       // Ring Buffer Unwrap
       var partA = Nativec.canvasBufferBytes1.sublist(head);
       var partB = Nativec.canvasBufferBytes1.sublist(0, head);
       _plotData = [...partA, ...partB];
       _lastHead = head;
       
       print("WaveWidget INIT! Pre-Filled ${_plotData.length} samples. Head: $head");

       // Pre-Fill Channel 2
       if (widget.neuronIdx2 != -1 && Nativec.canvasBufferBytes2.isNotEmpty) {
          int len2 = Nativec.canvasBufferBytes2.length;
          // Reuse same head
          var partA2 = Nativec.canvasBufferBytes2.sublist(head);
          var partB2 = Nativec.canvasBufferBytes2.sublist(0, head);
          _plotData2 = [...partA2, ...partB2];
          _lastHead2 = head;
       }
    }
    // Initialize Accumulator
  }
}
