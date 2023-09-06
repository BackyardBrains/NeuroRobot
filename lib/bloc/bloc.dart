import 'dart:async';

class Bloc {
  final StreamController<int> _redrawNeuronController = StreamController<int>();

  Stream<int> get redrawNeuronStream => _redrawNeuronController.stream;

  Sink<int> get redrawNeuronSink => _redrawNeuronController.sink;

  void refreshNow(int flag ) {
    redrawNeuronSink.add(flag);
  }

  // final StreamController<List<bool>> _redrawNeuronController = StreamController<List<bool>>.broadcast();

  // Stream<List<bool>> get redrawNeuronStream => _redrawNeuronController.stream;

  // Sink<List<bool>> get redrawNeuronSink => _redrawNeuronController.sink;

  // void refreshNow(List<bool> flag ) {
  //   redrawNeuronSink.add(flag);
  // }

}

Bloc mainBloc = new Bloc();