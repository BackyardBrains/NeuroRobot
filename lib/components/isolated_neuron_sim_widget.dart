import 'package:flutter/material.dart';
import '../utils/izhikevich_sim.dart';

class IsolatedNeuronSimWidget extends StatefulWidget {
  const IsolatedNeuronSimWidget({Key? key}) : super(key: key);

  @override
  _IsolatedNeuronSimWidgetState createState() => _IsolatedNeuronSimWidgetState();
}

class _IsolatedNeuronSimWidgetState extends State<IsolatedNeuronSimWidget> with SingleTickerProviderStateMixin {
  late NeuronChainNetwork network;
  late AnimationController _controller;

  NeuronType n1Type = NeuronType.regularSpiking;
  NeuronType n2Type = NeuronType.regularSpiking;
  NeuronType n3Type = NeuronType.regularSpiking;

  double injectedInput = 0.0;
  int inputFramesRemaining = 0;

  @override
  void initState() {
    super.initState();
    _initNetwork();
    
    // UI refreshes roughly 60fps (~16ms). We want to simulate real-time, 
    // where 1 step = 1ms. So we do 16 steps per frame.
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat();
    _controller.addListener(() {
      _runSimSteps(16);
      setState(() {});
    });
  }

  void _initNetwork() {
    var n1 = IzhikevichNeuron.withType(n1Type, historySize: 200);
    var n2 = IzhikevichNeuron.withType(n2Type, historySize: 200);
    var n3 = IzhikevichNeuron.withType(n3Type, historySize: 200);

    // Three neuron chain: 1 -> 2 -> 3
    var weights = [
      [0.0, 20.0, 0.0],  // n1 -> n2 
      [0.0, 0.0, 20.0],  // n2 -> n3
      [0.0, 0.0, 0.0],   // n3 -> none
    ];

    network = NeuronChainNetwork([n1, n2, n3], weights);
  }

  void _runSimSteps(int steps) {
    for (int i = 0; i < steps; i++) {
      double i1 = 0;
      if (inputFramesRemaining > 0) {
        i1 = injectedInput;
        inputFramesRemaining--;
      }
      network.runStep([i1, 0.0, 0.0]);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _triggerInput() {
    // Inject current into Neuron 1 for 10ms
    injectedInput = 15.0;
    inputFramesRemaining = 10;
  }

  void _restartSim() {
    _initNetwork();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 400,
      height: 350,
      decoration: BoxDecoration(
        color: const Color(0xff2d2d2d),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 10,
            offset: const Offset(0, 5),
          )
        ],
        border: Border.all(color: Colors.white24, width: 1),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: const BoxDecoration(
              color: Color(0xff1d1d1d),
              borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Isolated 3-Neuron Sim', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white70, size: 20),
                  onPressed: _restartSim,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                )
              ],
            ),
          ),
          
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildControlsRow('Neuron 1', n1Type, (t) { setState(() { n1Type = t; _restartSim(); }); }),
                  _buildControlsRow('Neuron 2', n2Type, (t) { setState(() { n2Type = t; _restartSim(); }); }),
                  _buildControlsRow('Neuron 3', n3Type, (t) { setState(() { n3Type = t; _restartSim(); }); }),
                  const SizedBox(height: 10),
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CustomPaint(
                          painter: NeuronPlotPainter(network),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 40,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: _triggerInput,
                      child: const Text('Test Input on N1', style: TextStyle(color: Colors.white)),
                    ),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildControlsRow(String label, NeuronType currentType, ValueChanged<NeuronType> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13)),
          Container(
            height: 30,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: const Color(0xff3d3d3d),
              borderRadius: BorderRadius.circular(6),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<NeuronType>(
                value: currentType,
                dropdownColor: const Color(0xff3d3d3d),
                icon: const Icon(Icons.arrow_drop_down, color: Colors.white54),
                style: const TextStyle(color: Colors.white, fontSize: 12),
                onChanged: (val) {
                  if (val != null) onChanged(val);
                },
                items: NeuronType.values.map((t) {
                  return DropdownMenuItem(
                    value: t,
                    child: Text(t.name),
                  );
                }).toList(),
              ),
            ),
          )
        ],
      ),
    );
  }
}

class NeuronPlotPainter extends CustomPainter {
  final NeuronChainNetwork network;

  NeuronPlotPainter(this.network);

  @override
  void paint(Canvas canvas, Size size) {
    final colors = [Colors.blue, Colors.green, Colors.orange];
    
    // Background grid
    final gridPaint = Paint()..color = Colors.white12..style = PaintingStyle.stroke..strokeWidth = 1;
    for (int i = 1; i <= 3; i++) {
        double y = size.height * (i / 4);
        canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Min voltage is ~ -90, max is ~ 30, so voltage range = 120
    double vMin = -90;
    double vMax = 30;
    double vRange = vMax - vMin;

    double sectionHeight = size.height / network.neurons.length;

    for (int nIdx = 0; nIdx < network.neurons.length; nIdx++) {
      var neuron = network.neurons[nIdx];
      final paint = Paint()
        ..color = colors[nIdx]
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      Path path = Path();
      double wStep = size.width / (neuron.historySize - 1);
      
      for (int i = 0; i < neuron.historySize; i++) {
        double x = i * wStep;
        
        // Normalize v to 0.0 - 1.0 (clamped)
        double v = neuron.vHistory[i];
        if (v < vMin) v = vMin;
        if (v > vMax) v = vMax;
        double normV = (v - vMin) / vRange;

        // Invert Y because 0 is at top
        double ny = 1.0 - normV; 

        // Map to section
        double sectionTop = nIdx * sectionHeight;
        double y = sectionTop + (ny * sectionHeight);
        
        // Pad slightly within section
        y = y.clamp(sectionTop + 2, sectionTop + sectionHeight - 2);

        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant NeuronPlotPainter oldDelegate) => true;
}
