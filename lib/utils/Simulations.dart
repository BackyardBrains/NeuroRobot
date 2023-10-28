import 'dart:math';

List<String> neuronFixedType = ["RS", "IB","CH","FS", "TC", "RZ","LTS"];
String randomNeuronType(){
  int r = Random().nextInt(7); // <9
  return neuronFixedType[r];
}

