import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:gamepads/gamepads.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../utils/izhikevich_sim.dart';

class EmbeddedNeuronPlotWidget extends StatefulWidget {
  final String neuronTypeLabel;
  final double a;
  final double b;
  final double c;
  final double d;
  final double i;
  final int delayMs;
  final String? boundKey;
  final VoidCallback? onSpike;

  const EmbeddedNeuronPlotWidget({
    Key? key,
    required this.neuronTypeLabel,
    this.a = 0.02,
    this.b = 0.2,
    this.c = -65,
    this.d = 8,
    this.i = 5.0,
    this.delayMs = 100,
    this.boundKey,
    this.onSpike,
  }) : super(key: key);

  @override
  EmbeddedNeuronPlotWidgetState createState() => EmbeddedNeuronPlotWidgetState();
}

class EmbeddedNeuronPlotWidgetState extends State<EmbeddedNeuronPlotWidget> with SingleTickerProviderStateMixin {
  late NeuronChainNetwork network;
  late AnimationController _controller;

  double injectedInput = 0.0;
  int inputFramesRemaining = 0;
  bool inputPressing = false; // continuous hold trigger
  StreamSubscription<GamepadEvent>? _gamepadSubscription;

  DateTime? _lastTick;

  @override
  void initState() {
    super.initState();
    _initNetwork();
    HardwareKeyboard.instance.addHandler(_handleKey);

    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat();
    _controller.addListener(() {
      DateTime now = DateTime.now();
      if (_lastTick != null) {
          int steps = now.difference(_lastTick!).inMilliseconds;
          if (steps > 0) {
              // Cap maximum catch-up to prevent huge lag spikes if app was backgrounded
              if (steps > 100) steps = 100; 
              _runSimSteps(steps);
              _lastTick = now;
              setState(() {});
          }
      } else {
          _lastTick = now;
      }
    });

    _gamepadSubscription = Gamepads.events.listen(_onGamepadEvent);
  }

  void _onGamepadEvent(GamepadEvent event) {
    if (widget.neuronTypeLabel != "Remote Control") return;

    String baseKeyName = "Pad:${event.gamepadId}:${event.key}";
    String keyName = baseKeyName;
    
    if (event.type == KeyType.analog || (event.value.abs() > 0.5 && event.value < 0)) {
       String direction = event.value > 0 ? "+" : "-";
       keyName = "$baseKeyName:$direction";
    }

    // Filter by bound key string created in parent widget
    if (widget.boundKey != null && widget.boundKey!.isNotEmpty) {
      bool isMatch = false;
      if (event.value.abs() > 0.5) {
         if (keyName.toLowerCase() == widget.boundKey!.toLowerCase()) isMatch = true;
      } else {
         if (widget.boundKey!.toLowerCase().startsWith(baseKeyName.toLowerCase())) isMatch = true;
      }
      if (!isMatch) return;
    }

    bool isButtonPress = event.type == KeyType.button && event.value > 0.5;
    bool isAxisPress = (event.type == KeyType.analog || event.type == KeyType.button) && (event.value > 0.5 || event.value < -0.5);

    if (isButtonPress || isAxisPress) {
       inputPressing = true; // Continuous hold
    } else if (event.value.abs() <= 0.5) {
       inputPressing = false; // Release
    }
  }


  bool _handleKey(KeyEvent event) {
    if (widget.neuronTypeLabel != "Remote Control") return false;

    // Ignore generic HID usage 0x70000
    if (event.physicalKey.usbHidUsage == 0x00070000) return false;

    // Filter by bound key if one is set
    if (widget.boundKey != null && widget.boundKey!.isNotEmpty) {
      if (event.logicalKey.keyLabel.toLowerCase() != widget.boundKey!.toLowerCase()) {
        return false;
      }
    }

    if (event is KeyDownEvent) {
      inputPressing = true;
      return true; // Consume to avoid MacOS error beep
    } else if (event is KeyUpEvent) {
      inputPressing = false;
      return true;
    }
    return false;
  }

  @override
  void didUpdateWidget(covariant EmbeddedNeuronPlotWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.neuronTypeLabel != oldWidget.neuronTypeLabel ||
        widget.a != oldWidget.a ||
        widget.b != oldWidget.b ||
        widget.c != oldWidget.c ||
        widget.d != oldWidget.d ||
        widget.i != oldWidget.i ||
        widget.delayMs != oldWidget.delayMs) {
      _updateNeuron2();
      // Ensure we reset press state if user switches away while holding
      if (widget.neuronTypeLabel != "Remote Control") {
        inputPressing = false;
      }
    }
  }

  void _initNetwork() {
    // Neuron 1: Quiet neuron (Input Driver)
    var n1 = IzhikevichNeuron.withType(NeuronType.regularSpiking, historySize: 2000);
    n1.a = 0.02;
    n1.b = 0.2;
    n1.c = -65;
    n1.d = 8;
    
    // Neuron 2: The Tuned Neuron we are adjusting
    var n2 = IzhikevichNeuron.withType(NeuronType.regularSpiking, historySize: 2000);
    
    // Neuron 3: Target Neuron (Bursts when activated)
    var n3 = IzhikevichNeuron.withType(NeuronType.regularSpiking, historySize: 2000);
    n3.a = 0.02;
    n3.b = 0.1;
    n3.c = -37;
    n3.d = 2;
    n3.baseDcInput = 0.0;
    
    // N1 triggers N2 strongly. N2 triggers N3 strongly.
    var weights = [
      [0.0, 200.0, 0.0],  
      [0.0, 0.0, 200.0],  
      [0.0, 0.0, 0.0],    
    ];

    network = NeuronChainNetwork([n1, n2, n3], weights);
    _updateNeuron2();
  }



  void _updateNeuron2() {
    // Set actual Izhikevich parameters
    IzhikevichNeuron n2 = network.neurons[1];

    // Map the UI string label to typical DC inputs matching Nativec mappings
    n2.applyNoise = true; // Default to noisy C++ baseline matches
    switch (widget.neuronTypeLabel) {
      case "Quiet":
        n2.a = 0.02; n2.b = 0.1; n2.c = -65; n2.d = 2;
        n2.baseDcInput = 0.0;
        break;
      case "Bursts when activated":
        n2.a = 0.02; n2.b = 0.1; n2.c = -37; n2.d = 2;
        n2.baseDcInput = 0.0;
        break;
      case "Occassionally active":
        n2.a = 0.02; n2.b = 0.17; n2.c = -65; n2.d = 2;
        n2.baseDcInput = 5.0; 
        break;
      case "Generates bursts":
        n2.a = 0.02; n2.b = 0.17; n2.c = -20; n2.d = 2;
        n2.baseDcInput = 5.0; 
        break;
      case "Highly active":
        n2.a = 0.02; n2.b = 0.24; n2.c = -65; n2.d = 2;
        n2.baseDcInput = 15.0;
        break;
      case "Delay": 
        n2.a = 0.02; n2.b = 0.1; n2.c = -37; n2.d = 2;
        n2.baseDcInput = 0.0;
        break;
      case "Remote Control":
        n2.a = 0.02; n2.b = 0.1; n2.c = -65; n2.d = 2;
        n2.baseDcInput = 0.0;
        break;
      case "Custom":
      default:
        n2.a = widget.a;
        n2.b = widget.b;
        n2.c = widget.c;
        n2.d = widget.d;
        n2.baseDcInput = widget.i;
        n2.applyNoise = false; // Custom neurons don't get the baseline noise
        break;
    }
  }

  List<int> delayedInputQueue = [];
  List<int> eventMarkers = []; // Tracks frames remaining on screen (from 2000 down to 0)

  void _runSimSteps(int steps) {
    bool spiked = false;
    for (int i = 0; i < steps; i++) {
        double i1 = 0;
        double i3 = 0;

        // Shift event markers left
        for (int m = eventMarkers.length - 1; m >= 0; m--) {
            eventMarkers[m]--;
            if (eventMarkers[m] <= 0) {
                eventMarkers.removeAt(m);
            }
        }

        if (delayedInputQueue.isNotEmpty) {
            for (int k = delayedInputQueue.length - 1; k >= 0; k--) {
                delayedInputQueue[k]--;
                if (delayedInputQueue[k] <= 0) {
                    delayedInputQueue.removeAt(k);
                    inputFramesRemaining = 2; // Minimal trigger for sharp single spikes
                }
            }
        }

        if (inputPressing || inputFramesRemaining > 0) {
            i1 = 100.0; // Strong current to N1 to cause immediate spike
            if (inputFramesRemaining > 0) inputFramesRemaining--;
        }
        
        // N1 receives injected burst, N2 receives 0.0 (baseline handled internally by network)
        List<bool> frameSpikes = network.runStep([i1, 0.0, i3]);
        if (frameSpikes[1]) spiked = true; // network.neurons[1] is the target
    }
    if (spiked) {
        widget.onSpike?.call();
    }
  }

  void startInput() {
    inputPressing = true;
  }

  void stopInput() {
    inputPressing = false;
    // For single-tap compatibility
    inputFramesRemaining = 0;
  }

  void triggerInput() {
    eventMarkers.add(2000); // 2000 frames is the full width of the plot
    
    if (widget.neuronTypeLabel == "Delay") {
        int dMs = widget.delayMs;
        if (dMs < 10) dMs = 10;
        delayedInputQueue.add(dMs);
    } else {
        // Inject enough frame ticks of current to guarantee the Quiet driver N1 crosses threshold and spikes once.
        inputFramesRemaining = 2; 
    }
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleKey);
    _gamepadSubscription?.cancel();
    _controller.dispose();
    super.dispose();
  }

  bool showEventMarkers = true;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
            width: double.infinity,
            height: 90, // Match live widget scale
            decoration: BoxDecoration(
              color: const Color(0xff181a1b), // Dark background mimicking WaveWidget
              borderRadius: BorderRadius.circular(15),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: CustomPaint(
                // We now plot the targetNeuron (n2) directly since it correctly replicates its own delayed bursts natively!
                painter: WavePlotPainter(network.neurons[1], showEventMarkers ? eventMarkers : []), 
              ),
            ),
        ),
        Positioned(
          bottom: 4,
          left: 4,
          child: GestureDetector(
            onTap: () {
              setState(() {
                showEventMarkers = !showEventMarkers;
              });
            },
            child: Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  const Text(
                    '🏴',
                    style: TextStyle(
                      fontSize: 18,
                      fontFamily: 'NotoEmoji',
                    ),
                  ),
                  if (!showEventMarkers)
                    SvgPicture.asset(
                      "assets/icons/Disabled.svg",
                      width: 24,
                      height: 24,
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class WavePlotPainter extends CustomPainter {
  final IzhikevichNeuron targetNeuron;
  final List<int> eventMarkers;

  WavePlotPainter(this.targetNeuron, this.eventMarkers);

  @override
  void paint(Canvas canvas, Size size) {
    // Spikerbot Orange trace
    final paint = Paint()
      ..color = const Color(0xfffd8164) // Signature orange color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    Path path = Path();
    
    double wStep = size.width / (targetNeuron.historySize - 1);
    
    // Typical Izhikevich range: -115mV to 30mV based on WaveWidget and action potential height
    double vMin = -115;
    double vMax = 30; // Native WaveWidget explicitly limits at 30.0
    double vRange = vMax - vMin;

    for (int i = 0; i < targetNeuron.historySize; i++) {
      double x = i * wStep;
      
      double v = targetNeuron.vHistory[i];
      if (v < vMin) v = vMin;
      if (v > vMax) v = vMax;
      
      double normV = (v - vMin) / vRange;
      
      // Match Native WaveWidget margins: topY1 = 15.0, bottomY1 = boxH - 15.0
      double h = size.height - 30.0;
      if (h < 10) h = 10;
      double y = 15.0 + h * (1.0 - normV);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    
    canvas.drawPath(path, paint);
    
    // Draw event markers
    final markerPaint = Paint()
      ..color = Colors.blueAccent.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
      
    final iconPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );
    
    // Reverse iterating to avoid bounds issues if drawing logic modifies anything
    for (int markerFrames in eventMarkers) {
       // Frames count down from 2000 to 0, matching the right-to-left scrolling nature 
       // where the newest data is on the right. Event happened at the right edge, so it scrolls left.
       double x = (markerFrames / targetNeuron.historySize) * size.width;
       
       canvas.drawLine(Offset(x, 0), Offset(x, size.height), markerPaint);
       
       // Draw blue circle background behind bolt
       canvas.drawCircle(Offset(x, size.height - 12), 8, Paint()..color = const Color(0xff181a1b));
       canvas.drawCircle(Offset(x, size.height - 12), 8, Paint()..color = Colors.blueAccent..style = PaintingStyle.stroke..strokeWidth = 1.5);
       
       // Draw filled lightning bolt path directly (web-safe, no font dependency)
       final boltPaint = Paint()..color = Colors.blueAccent..style = PaintingStyle.fill;
       final boltSize = 12.0;
       final bx = x - boltSize / 2;
       final by = size.height - 18;
       final boltPath = Path()
         ..moveTo(bx + boltSize * 0.55, by)
         ..lineTo(bx + boltSize * 0.25, by + boltSize * 0.5)
         ..lineTo(bx + boltSize * 0.45, by + boltSize * 0.5)
         ..lineTo(bx + boltSize * 0.35, by + boltSize)
         ..lineTo(bx + boltSize * 0.75, by + boltSize * 0.42)
         ..lineTo(bx + boltSize * 0.55, by + boltSize * 0.42)
         ..lineTo(bx + boltSize * 0.65, by)
         ..close();
       canvas.drawPath(boltPath, boltPaint);
    }
  }

  @override
  bool shouldRepaint(covariant WavePlotPainter oldDelegate) => true;
}
