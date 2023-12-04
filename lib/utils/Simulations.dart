import 'dart:math';

// List<String> neuronFixedType = ["RS", "IB","CH","FS", "TC", "RZ","LTS"];
List<String> neuronFixedType = ["Quiet", "Occassionally active", "Highly active", "Generates bursts", "Bursts when activated", "Dopaminergic", "Striatal"];
String randomNeuronType(){
  int r = Random().nextInt(7); // <9
  return neuronFixedType[r];
}

