import 'dart:math';
import 'dart:collection';

enum NeuronType {
  regularSpiking,
  intrinsicallyBursting,
  chattering,
  fastSpiking,
  lowThresholdSpiking,
  resonator,
}

class IzhikevichNeuron {
  // Parameters
  double a;
  double b;
  double c;
  double d;

  // State
  double v;
  double u;
  double baseDcInput = 0.0;
  bool applyNoise = true;

  // Buffers for plotting
  List<double> vHistory;
  int historySize;
  
  bool spikedLastFrame = false;

  // Custom neuron parameters mapping based on regular spiking
  IzhikevichNeuron.withType(NeuronType type, {this.historySize = 1000}) 
    : a = 0.02, b = 0.2, c = -65, d = 8, v = -65, u = 0.2 * -65, baseDcInput = 0.0, vHistory = [] {
    setType(type);
  }

  void reset() {
    v = c;
    u = b * v;
    spikedLastFrame = false;
    vHistory = List.filled(historySize, c, growable: true);
  }

  void setType(NeuronType type) {
    switch (type) {
      case NeuronType.regularSpiking:
        a = 0.02; b = 0.2; c = -65; d = 8;
        break;
      case NeuronType.intrinsicallyBursting:
        a = 0.02; b = 0.2; c = -55; d = 4;
        break;
      case NeuronType.chattering:
        a = 0.02; b = 0.2; c = -50; d = 2;
        break;
      case NeuronType.fastSpiking:
        a = 0.1; b = 0.2; c = -65; d = 2;
        break;
      case NeuronType.lowThresholdSpiking:
        a = 0.02; b = 0.25; c = -65; d = 2;
        break;
      case NeuronType.resonator:
        a = 0.1; b = 0.26; c = -65; d = 2;
        break;
    }
    reset();
  }
}

class NeuronChainNetwork {
  final List<IzhikevichNeuron> neurons;
  final List<List<double>> weights;
  final Random _random = Random();

  NeuronChainNetwork(this.neurons, this.weights);

  List<bool> runStep(List<double> externalInputs) {
    List<bool> spikes = List.filled(neurons.length, false);
    List<double> outVs = List.filled(neurons.length, 0.0);
    
    // Evaluate spikes and update states
    for (int i = 0; i < neurons.length; i++) {
        spikes[i] = neurons[i].v >= 30;
        if (spikes[i]) {
            neurons[i].v = neurons[i].c;
            neurons[i].u += neurons[i].d;
        }
        outVs[i] = neurons[i].v;
    }

    // Calculate inputs
    List<double> totalInputs = List.from(externalInputs);
    for (int i = 0; i < neurons.length; i++) {
      for (int j = 0; j < neurons.length; j++) {
        if (spikes[j]) { // Neuron j spiked, send input to neuron i
          totalInputs[i] += weights[j][i];
        }
      }
    }

    // Update neurons using 2-step method for stability
    for (int i = 0; i < neurons.length; i++) {
        double v = neurons[i].v;
        double u = neurons[i].u;
        double a = neurons[i].a;
        double b = neurons[i].b;
        
        // Native C++ calculating the injection current directly with its specific base noise:
        // `tI[neuronIndex] = i[neuronIndex] * (1.5 * randoms())`
        double baseDc = neurons[i].baseDcInput;
        
        // We only apply noise if baseDc > 0 to perfectly match the pure C++ threshold logic
        double noisyDc = baseDc;
        if (baseDc > 0 && neurons[i].applyNoise) {
             noisyDc = baseDc * (1.5 * _random.nextDouble());
        }
        
        // Add any external manual inputs or synaptic weights that arrived
        double synapticAndExternalInput = totalInputs[i];
        
        // Sum total current 
        double totalCurrent = noisyDc + synapticAndExternalInput;

        v += 0.5 * (0.04 * v * v + 5 * v + 140 - u + totalCurrent);
        v += 0.5 * (0.04 * v * v + 5 * v + 140 - u + totalCurrent);
        u += a * (b * v - u);

      if (v >= 30) {
          v = 30; // Native limit to prevent RK4 math explosions
      }
      neurons[i].v = v;
      neurons[i].u = u;

      // Add to history
      neurons[i].vHistory.removeAt(0);
      
      // If the neuron spiked this frame, force the visualization to draw the peak (e.g., 30.0) 
      // If it spikes multiple frames in a row (like during a burst), we inject 'c'
      // on alternating frames to simulate visual gap jitter seen in the native downsampled rendering.
      if (spikes[i]) {
          if (!neurons[i].spikedLastFrame) {
              neurons[i].vHistory.add(30.0);
          } else {
              neurons[i].vHistory.add(neurons[i].c);
          }
      } else {
          neurons[i].vHistory.add(v);
      }
      neurons[i].spikedLastFrame = spikes[i];
    }
    return spikes;
  }

  void reset() {
    for (var neuron in neurons) {
      neuron.reset();
    }
  }
}
