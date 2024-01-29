import 'dart:async';
import 'dart:typed_data';

class Bloc {
  final StreamController<int> _redrawNeuronController = StreamController<int>();

  Stream<int> get redrawNeuronStream => _redrawNeuronController.stream;

  Sink<int> get redrawNeuronSink => _redrawNeuronController.sink;

  void refreshNow(int flag) {
    redrawNeuronSink.add(flag);
  }

  final StreamController<Uint8List> _imageController =
      StreamController<Uint8List>.broadcast();

  Stream<Uint8List> get imageStream => _imageController.stream;

  Sink<Uint8List> get imageSink => _imageController.sink;

  void drawImageNow(Uint8List flag) {
    imageSink.add(flag);
  }

  final StreamController<int> _loadingController =
      StreamController<int>.broadcast();
  Stream<int> get loadingStream => _loadingController.stream;
  Sink<int> get loadingSink => _loadingController.sink;
  void setLoading(int flag) {
    loadingSink.add(flag);
  }

  // final StreamController<List<bool>> _redrawNeuronController = StreamController<List<bool>>.broadcast();

  // Stream<List<bool>> get redrawNeuronStream => _redrawNeuronController.stream;

  // Sink<List<bool>> get redrawNeuronSink => _redrawNeuronController.sink;

  // void refreshNow(List<bool> flag ) {
  //   redrawNeuronSink.add(flag);
  // }
}

Bloc mainBloc = new Bloc();
