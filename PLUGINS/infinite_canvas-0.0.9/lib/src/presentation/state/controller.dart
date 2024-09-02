import 'dart:io';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:infinite_canvas/src/domain/model/SyntheticEdge.dart';
import 'package:infinite_canvas/src/domain/model/SyntheticNeuron.dart';

import '../../domain/model/edge.dart';
import '../../domain/model/graph.dart';
import '../../domain/model/node.dart';

typedef NodeFormatter = void Function(InfiniteCanvasNode);

/// A controller for the [InfiniteCanvas].
class InfiniteCanvasController extends ChangeNotifier implements Graph {
  late bool isPlaying = false;
  bool isInteractable = true;
  bool isFoundEdge = false;
  bool isSelectingEdge = false;
  final List<SyntheticNeuron> rawSyntheticNeuronList;
  List<SyntheticNeuron> syntheticNeuronList;
  final List<Connection> syntheticConnections;
  final Map<String, String> neuronTypes;
  final VoidCallback onLongPress;
  final VoidCallback onDoubleTap;
  final VoidCallback onDeleteCallback;

  Map<String, Path> axonPathMap = {};

  List<LocalKey>? restrictedToNeuronsKey;
  List<LocalKey>? restrictedFromNeuronsKey;
  // final VoidCallback transformNeuronPositionWrapper;

  InfiniteCanvasController({
    required this.rawSyntheticNeuronList,
    required this.syntheticNeuronList,
    required this.syntheticConnections,
    required this.neuronTypes,
    required this.onLongPress,
    required this.onDoubleTap,
    required this.onDeleteCallback,
    // required this.transformNeuronPositionWrapper,
    List<InfiniteCanvasNode> nodes = const [],
    List<InfiniteCanvasEdge> edges = const [],
  }) {
    if (nodes.isNotEmpty) {
      this.nodes.addAll(nodes);
    }
    if (edges.isNotEmpty) {
      this.edges.addAll(edges);
    }
  }

  double minScale = 0.4;
  double maxScale = 4;
  final focusNode = FocusNode();
  Size? viewport;

  @override
  final List<InfiniteCanvasNode> nodes = [];

  @override
  final List<InfiniteCanvasEdge> edges = [];

  // STEVE
  late InfiniteCanvasEdge edgeFound;
  late InfiniteCanvasEdge edgeSelected;
  List<InfiniteCanvasEdge> get edgeSelection => edges
      .where((e) => edgeSelected.from == e.from && edgeSelected.to == e.to)
      .toList();

  final Set<Key> _selected = {};
  List<InfiniteCanvasNode> get selection =>
      nodes.where((e) => _selected.contains(e.key)).toList();
  final Set<Key> _hovered = {};
  List<InfiniteCanvasNode> get hovered =>
      nodes.where((e) => _hovered.contains(e.key)).toList();

  void _cacheSelectedOrigins() {
    // cache selected node origins
    _selectedOrigins.clear();
    for (final key in _selected) {
      final index = nodes.indexWhere((e) => e.key == key);
      if (index == -1) continue;
      final current = nodes[index];
      _selectedOrigins[key] = current.offset;
    }
  }

  void _cacheSelectedOrigin(Key key) {
    final index = nodes.indexWhere((e) => e.key == key);
    if (index == -1) return;
    final current = nodes[index];
    _selectedOrigins[key] = current.offset;
  }

  final Map<Key, Offset> _selectedOrigins = {};

  late final transform = TransformationController();
  Matrix4 get matrix => transform.value;
  Offset mousePosition = Offset.zero;
  Offset? mouseDragStart;
  Offset? marqueeStart, marqueeEnd;
  LocalKey? linkStart;

  void _formatAll() {
    for (InfiniteCanvasNode node in nodes) {
      _formatter!(node);
    }
  }

  bool _formatterHasChanged = false;
  NodeFormatter? _formatter;
  set formatter(NodeFormatter value) {
    _formatterHasChanged = _formatter != value;

    if (_formatterHasChanged == false) return;

    _formatter = value;
    _formatAll();
    notifyListeners();
  }

  Offset? _linkEnd;
  Offset? get linkEnd => _linkEnd;
  set linkEnd(Offset? value) {
    if (value == _linkEnd) return;
    _linkEnd = value;
    notifyListeners();
  }

  bool _mouseDown = false;
  bool get mouseDown => _mouseDown;
  set mouseDown(bool value) {
    if (value == _mouseDown) return;
    _mouseDown = value;
    notifyListeners();
  }

  bool _shiftPressed = false;
  bool get shiftPressed => _shiftPressed;
  set shiftPressed(bool value) {
    if (value == _shiftPressed) return;
    _shiftPressed = value;
    notifyListeners();
  }

  bool _spacePressed = false;
  bool get spacePressed => _spacePressed;
  set spacePressed(bool value) {
    if (value == _spacePressed) return;
    _spacePressed = value;
    notifyListeners();
  }

  bool _controlPressed = false;
  bool get controlPressed => _controlPressed;
  set controlPressed(bool value) {
    if (value == _controlPressed) return;
    _controlPressed = value;
    notifyListeners();
  }

  bool _metaPressed = false;
  bool get metaPressed => _metaPressed;
  set metaPressed(bool value) {
    if (value == _metaPressed) return;
    _metaPressed = value;
    notifyListeners();
  }

  double _scale = 1;
  double get scale => _scale;
  set scale(double value) {
    if (value == _scale) return;
    _scale = value;
    notifyListeners();
  }

  double getScale() {
    final matrix = transform.value;
    final scaleX = matrix.getMaxScaleOnAxis();
    return scaleX;
  }

  Rect getMaxSize() {
    Rect rect = Rect.zero;
    for (final child in nodes) {
      rect = Rect.fromLTRB(
        min(rect.left, child.rect.left),
        min(rect.top, child.rect.top),
        max(rect.right, child.rect.right),
        max(rect.bottom, child.rect.bottom),
      );
    }
    return rect;
  }

  // STEVE
  bool isEdgeSelected(LocalKey keyFrom, LocalKey keyTo) =>
      edgeSelected.from == keyFrom && edgeSelected.to == keyTo;
  bool get hasEdgeSelection => edgeSelection.isNotEmpty;

  bool isSelected(LocalKey key) => _selected.contains(key);
  bool isHovered(LocalKey key) => _hovered.contains(key);

  bool get hasSelection => _selected.isNotEmpty;

  bool _canvasMoveEnabled = true;
  // bool get canvasMoveEnabled => !mouseDown;
  // bool get canvasMoveEnabled => _canvasMoveEnabled && !mouseDown;
  bool get canvasMoveEnabled => _canvasMoveEnabled;
  void setCanvasMove(bool value) {
    _canvasMoveEnabled = value;
    // notifyListeners();
  }

  void notifyMousePosition() {
    // notifyListeners();
  }

  Offset toLocal(Offset global) {
    return transform.toScene(global);
  }

  void checkSelection(Offset localPosition, [bool hover = false]) {
    if (!isInteractable) {
      deselectAll(true);
      deselectAll();
      return;
    }

    final offset = toLocal(localPosition);
    final selection = <Key>[];
    for (final child in nodes) {
      final rect = child.rect;
      if (rect.contains(offset)) {
        selection.add(child.key);
      }
    }
    if (kIsWeb) {
    } else if (Platform.isIOS || Platform.isAndroid) {
      isSelectingEdge = false;
    }
    for (final edge in edges) {
      const lineWidth = 7;
      const radius = 10;
      var eFrom = nodes.where((e) => edge.from == (e.key)).toList()[0];
      var eTo = nodes.where((e) => edge.to == (e.key)).toList()[0];

      // IS RECIPROCATE
      // var oFrom = Offset( eFrom.offset.dx + lineWidth, eFrom.offset.dy + lineWidth + edge.isReciprocate  );
      // var oTo = Offset( eTo.offset.dx + lineWidth, eTo.offset.dy + lineWidth + edge.isReciprocate  );

      /*
      Path p = Path()
        ..moveTo(eFrom.offset.dx - lineWidth, eFrom.offset.dy - lineWidth)
        ..lineTo(eTo.offset.dx - lineWidth, eTo.offset.dy - lineWidth)
        ..lineTo(oTo.dx, oTo.dy)
        ..lineTo(oFrom.dx, oFrom.dy)
        ..lineTo(eFrom.offset.dx - lineWidth, eFrom.offset.dy - lineWidth);
        */
      // IS RECIPROCATE

      // Calculate direction vector of the line
      double dx = eTo.offset.dx - eFrom.offset.dx;
      double dy = eTo.offset.dy - eFrom.offset.dy;

      // Normalize the direction vector
      double length = sqrt(dx * dx + dy * dy);
      double unitDx = dx / length;
      double unitDy = dy / length;

      // Compute the perpendicular direction
      double perpDx = -unitDy;
      double perpDy = unitDx;

      double pairSpace = edge.isReciprocate * 7;
      var iFrom = Offset(
          eFrom.offset.dx - perpDx * lineWidth + radius + pairSpace,
          eFrom.offset.dy - perpDy * lineWidth + radius + pairSpace);
      var oFrom = Offset(
          eFrom.offset.dx + perpDx * lineWidth + radius + pairSpace,
          eFrom.offset.dy + perpDy * lineWidth + radius + pairSpace);

      var iTo = Offset(eTo.offset.dx - perpDx * lineWidth + radius + pairSpace,
          eTo.offset.dy - perpDy * lineWidth + radius + pairSpace);
      var oTo = Offset(eTo.offset.dx + perpDx * lineWidth + radius + pairSpace,
          eTo.offset.dy + perpDy * lineWidth + radius + pairSpace);

      // Path p = Path()
      //   ..moveTo(iFrom.dx, iFrom.dy)
      //   ..lineTo(iTo.dx, iTo.dy)
      //   ..lineTo(oTo.dx, oTo.dy)
      //   ..lineTo(oFrom.dx, oFrom.dy)
      //   ..lineTo(iFrom.dx, iFrom.dy);

      // p.close();
      String pathKey = "${eFrom.key.toString()}_${eTo.key.toString()}";
      if (axonPathMap.containsKey(pathKey)) {
        Path p = axonPathMap[pathKey]!;

        if (p.contains(offset)) {
          edgeFound = edge;
          isFoundEdge = true;
          if (kIsWeb) {
          } else if (Platform.isIOS || Platform.isAndroid) {
            isSelectingEdge = true;
            edgeSelected = edge;
          }
          // print("OFFSET");
          // print(isSelectingEdge);
          // print(eFrom.value);
          // print(eTo.value);
          // print(eFrom.offset);
          // print(eTo.offset);
          // print(iFrom);
          // print(oFrom);
          // print(iTo);
          // print(oTo);

          break;
        } else {
          isFoundEdge = false;
        }
      } else {
        isFoundEdge = false;
      }

      // Rect rect = Rect.fromLTRB(
      //   min(eFrom.rect.left, eTo.rect.left),
      //   min(eFrom.rect.top, eTo.rect.top),
      //   max(eFrom.rect.right, eTo.rect.right),
      //   max(eFrom.rect.bottom, eTo.rect.bottom),
      // );

      // if (rect.contains(offset)){
      //   edgeSelected = edge;
      //   print("edgeSelected");
      //   print(edgeSelected);
      // }
      // final rect = child.rect;
      // if (rect.contains(offset)) {
      //   selection.add(child.key);
      // }
    }
    if (selection.isNotEmpty) {
      if (shiftPressed) {
        setSelection({selection.last, ..._selected.toSet()}, hover);
      } else {
        setSelection({selection.last}, hover);
      }
    } else {
      deselectAll(hover);
    }
  }

  void checkMarqueeSelection([bool hover = false]) {
    if (marqueeStart == null || marqueeEnd == null) return;
    final selection = <Key>{};
    final rect = Rect.fromPoints(
      toLocal(marqueeStart!),
      toLocal(marqueeEnd!),
    );
    for (final child in nodes) {
      if (rect.overlaps(child.rect)) {
        selection.add(child.key);
      }
    }
    if (selection.isNotEmpty) {
      if (shiftPressed) {
        setSelection(selection.union(_selected.toSet()), hover);
      } else {
        setSelection(selection, hover);
      }
    } else {
      deselectAll(hover);
    }
  }

  InfiniteCanvasNode? getNode(LocalKey? key) {
    if (key == null) return null;
    return nodes.firstWhereOrNull((e) => e.key == key);
  }

  void addLink(LocalKey from, LocalKey to, [String? label]) {
    var tailNode = nodes[0];

    if (from == tailNode.key || to == tailNode.key) {
      linkStart = null;
      return;
    }

    final edge = InfiniteCanvasEdge(
      from: from,
      to: to,
      label: label,
    );
    bool isAddingEdge = true;
    if (from == to) {
      isAddingEdge = false;
    } else if (restrictedToNeuronsKey!.contains(to)) {
      isAddingEdge = false;
    } else if (restrictedFromNeuronsKey!.contains(from)) {
      isAddingEdge = false;
    }
    if (isAddingEdge) {
      List<InfiniteCanvasEdge> foundNodeList = edges
          .where(
            (element) => element.from == edge.from && element.to == edge.to,
          )
          .toList();
      List<InfiniteCanvasEdge> foundReciprocateNodeList = edges
          .where(
            (element) => element.from == edge.to && element.to == edge.from,
          )
          .toList();
      int foundNode = foundNodeList.length;

      if (foundNode == 0) {
        //not duplicate
        if (foundReciprocateNodeList.isNotEmpty) {
          foundReciprocateNodeList[0].isReciprocate = 1;
          edge.isReciprocate = -1;
          edges.add(edge);
        } else {
          edges.add(edge);
        }
      }
    }
    deselectAll(true);
    deselectAll(false);
    notifyListeners();
    // addSyntheticConnection(edge.from, edge.to);
  }

  void moveSelection(Offset position) {
    final delta = mouseDragStart != null
        ? toLocal(position) - toLocal(mouseDragStart!)
        : toLocal(position);
    for (final key in _selected) {
      final index = nodes.indexWhere((e) => e.key == key);
      if (index == -1) continue;
      final current = nodes[index];
      final origin = _selectedOrigins[key];
      current.update(offset: origin! + delta);
      if (_formatter != null) {
        _formatter!(current);
      }
    }
    notifyListeners();
  }

  void select(Key key, [bool hover = false]) {
    if (hover) {
      _hovered.add(key);
    } else {
      _selected.add(key);
      _cacheSelectedOrigin(key);
    }

    notifyListeners();
  }

  void setSelection(Set<Key> keys, [bool hover = false]) {
    if (hover) {
      _hovered.clear();
      _hovered.addAll(keys);
    } else {
      _selected.clear();
      _selected.addAll(keys);
      _cacheSelectedOrigins();
    }
    notifyListeners();
  }

  void deselect(Key key, [bool hover = false]) {
    if (hover) {
      _hovered.remove(key);
    } else {
      _selected.remove(key);
      _selectedOrigins.remove(key);
    }
    notifyListeners();
  }

  void deselectAll([bool hover = false]) {
    if (hover) {
      // _hovered.clear();
      if (_hovered.isNotEmpty) _hovered.clear();
    } else {
      // _selected.clear();
      // _selectedOrigins.clear();
      if (_selected.isNotEmpty) _selected.clear();
      if (_selectedOrigins.isNotEmpty) _selectedOrigins.clear();
    }
    notifyListeners();
  }

  void add(InfiniteCanvasNode child) {
    if (_formatter != null) {
      _formatter!(child);
    }
    nodes.add(child);
    notifyListeners();
  }

  void edit(InfiniteCanvasNode child) {
    if (_selected.length == 1) {
      final idx = nodes.indexWhere((e) => e.key == _selected.first);
      nodes[idx] = child;
      notifyListeners();
    }
  }

  void remove(Key key) {
    nodes.removeWhere((e) => e.key == key);
    _selected.remove(key);
    _selectedOrigins.remove(key);
    notifyListeners();
  }

  void bringToFront() {
    final selection = _selected.toList();
    for (final key in selection) {
      final index = nodes.indexWhere((e) => e.key == key);
      if (index == -1) continue;
      final current = nodes[index];
      nodes.removeAt(index);
      nodes.add(current);
    }
    notifyListeners();
  }

  void sendBackward() {
    final selection = _selected.toList();
    if (selection.length == 1) {
      final key = selection.first;
      final index = nodes.indexWhere((e) => e.key == key);
      if (index == -1) return;
      if (index == 0) return;
      final current = nodes[index];
      nodes.removeAt(index);
      nodes.insert(index - 1, current);
      notifyListeners();
    }
  }

  void sendForward() {
    final selection = _selected.toList();
    if (selection.length == 1) {
      final key = selection.first;
      final index = nodes.indexWhere((e) => e.key == key);
      if (index == -1) return;
      if (index == nodes.length - 1) return;
      final current = nodes[index];
      nodes.removeAt(index);
      nodes.insert(index + 1, current);
      notifyListeners();
    }
  }

  void sendToBack() {
    final selection = _selected.toList();
    for (final key in selection) {
      final index = nodes.indexWhere((e) => e.key == key);
      if (index == -1) continue;
      final current = nodes[index];
      nodes.removeAt(index);
      nodes.insert(0, current);
    }
    notifyListeners();
  }

  void deleteSelection() {
    final selection = _selected.toList();
    for (final key in selection) {
      final index = nodes.indexWhere((e) => e.key == key);
      if (index == -1) continue;
      nodes.removeAt(index);
      _selectedOrigins.remove(key);
    }
    // Delete related connections
    edges.removeWhere(
      (e) => selection.contains(e.from) || selection.contains(e.to),
    );
    notifyListeners();
  }

  void selectAll() {
    _selected.clear();
    _selected.addAll(nodes.map((e) => e.key).toList());
    _cacheSelectedOrigins();
    notifyListeners();
  }

  void zoom(double delta) {
    final matrix = transform.value.clone();
    final local = toLocal(mousePosition);
    matrix.translate(local.dx, local.dy);
    matrix.scale(delta, delta);
    matrix.translate(-local.dx, -local.dy);
    transform.value = matrix;
    notifyListeners();
  }

  void zoomIn() => zoom(1.1);
  void zoomOut() => zoom(0.9);
  void zoomReset() => transform.value = Matrix4.identity();

  void pan(Offset delta) {
    final matrix = transform.value.clone();
    matrix.translate(delta.dx, delta.dy);
    transform.value = matrix;
    notifyListeners();
  }

  void panUp() => pan(const Offset(0, -10));
  void panDown() => pan(const Offset(0, 10));
  void panLeft() => pan(const Offset(-10, 0));
  void panRight() => pan(const Offset(10, 0));

  Offset getOffset() {
    final matrix = transform.value.clone();
    matrix.invert();
    final result = matrix.getTranslation();
    return Offset(result.x, result.y);
  }

  Rect getRect(BoxConstraints constraints) {
    final offset = getOffset();
    final scale = matrix.getMaxScaleOnAxis();
    final size = constraints.biggest;
    return offset & size / scale;
  }

  void addSyntheticConnection(LocalKey axonFrom, LocalKey axonTo) {
    List<SyntheticNeuron> syntheticNeurons =
        copyFromRawSynthetics(syntheticNeuronList);
    syntheticNeuronList = syntheticNeurons;

    int fromIdx = neuronTypes.keys.toList().indexOf(axonFrom.toString());
    int toIdx = neuronTypes.keys.toList().indexOf(axonTo.toString());
    final nodeFrom = nodes.firstWhere((node) => node.key == axonFrom);
    final nodeTo = nodes.firstWhere((node) => node.key == axonTo);
    double circleRadius = nodeFrom.syntheticNeuron.circleRadius;

    syntheticConnections.add(Connection(axonFrom, axonTo, 25.0, Path()));
    // print("Add Synthetic Connection ${syntheticConnections.length}");
    // for (int i = syntheticNeurons.length - 1;
    for (int i = 0; i < syntheticNeurons.length; i++) {
      Neuron syntheticRawNeuron = syntheticNeurons[i].newNeuron;

      if (syntheticRawNeuron.isIO) {
        continue;
      }

      double numberofConnections = 1;
      double averageX = syntheticRawNeuron.x;
      double averageY = syntheticRawNeuron.y;
      bool hasAxon = false;
      for (Connection con in syntheticConnections) {
        int fromNeuronIdx =
            neuronTypes.keys.toList().indexOf(con.neuronIndex1.toString());
        int toNeuronIdx =
            neuronTypes.keys.toList().indexOf(con.neuronIndex2.toString());
        if (fromNeuronIdx == i) {
          hasAxon = true;
          averageX +=
              (syntheticNeurons[toNeuronIdx].newNeuron.x - circleRadius);
          averageY +=
              (syntheticNeurons[toNeuronIdx].newNeuron.y - circleRadius);
          numberofConnections = numberofConnections + 1;
          print(
              "Connection ${con.neuronIndex1} $i == $fromNeuronIdx $numberofConnections $averageX, $averageY");
        }
      }
      averageX = averageX / numberofConnections;
      averageY = averageY / numberofConnections;
      syntheticRawNeuron.xCenterOfConnections = averageX;
      syntheticRawNeuron.yCenterOfConnections = averageY;
      if (hasAxon && !syntheticRawNeuron.isIO) {
        double tempAxonAngle = angleBetweenTwoPoints(
            syntheticRawNeuron.x, syntheticRawNeuron.y, averageX, averageY);
        double minDistanceValue = 361;
        int minDistanceIndex = 0;
        for (int angleIndex = 0;
            angleIndex < syntheticRawNeuron.dendrites.length;
            angleIndex++) {
          double distance1 =
              ((tempAxonAngle - syntheticRawNeuron.dendrites[angleIndex].angle)
                  .abs());
          double distance2 = ((tempAxonAngle -
                  360 -
                  syntheticRawNeuron.dendrites[angleIndex].angle)
              .abs());
          // print(
          //     "$tempAxonAngle 360 ${syntheticRawNeuron.dendrites[angleIndex].angle}");
          // print(
          //     "distance1: $distance1 , distance2: $distance2 ,angleIndex: $angleIndex, ${syntheticRawNeuron.dendrites[angleIndex].angle},i:$i = minDistanceValue: $minDistanceValue minDistanceIndex:$minDistanceIndex");
          if (distance1 < minDistanceValue) {
            minDistanceValue = distance1;
            minDistanceIndex = angleIndex;
          }
          if (distance2 < minDistanceValue) {
            minDistanceValue = distance2;
            minDistanceIndex = angleIndex;
          }
        }

        syntheticRawNeuron.axonAngle =
            syntheticRawNeuron.dendrites[minDistanceIndex].angle;
        syntheticRawNeuron.dendriteIdx = minDistanceIndex;
        syntheticRawNeuron.xAxon =
            syntheticRawNeuron.dendrites[minDistanceIndex].xFirstLevel;
        syntheticRawNeuron.yAxon =
            syntheticRawNeuron.dendrites[minDistanceIndex].yFirstLevel;
        print("remove how many times? $i - $minDistanceIndex");
        syntheticRawNeuron.dendrites.removeAt(minDistanceIndex);
      }
    }
    for (SyntheticNeuron syntheticNeuron in syntheticNeuronList) {
      syntheticNeuron.recalculate(null);
    }

    createSyntheticAxon2(syntheticNeurons, fromIdx, toIdx, 50 / 2);
  }

  void createSyntheticAxon(List<SyntheticNeuron> syntheticNeurons, int fromIdx,
      toIdx, double connectionStrength) {
    List<SyntheticNeuron> neurons = syntheticNeurons;
    Neuron neuronTo = neurons[toIdx].newNeuron;
    if (neuronTo.isIO) {
      int emptySpotIndex = 0;
      int smalestNumber = 9999999;
      for (int dendriteIndex = 0;
          dendriteIndex < neuronTo.dendrites.length;
          dendriteIndex++) {
        if (neuronTo.dendrites[dendriteIndex].sinapseFirstLevel.length <
            smalestNumber) {
          emptySpotIndex = dendriteIndex;
          smalestNumber =
              neuronTo.dendrites[dendriteIndex].sinapseFirstLevel.length;
        }
      }
      Sinapse newSinapse = Sinapse(
        presinapticNeuronIndex: fromIdx,
        sinapticValue: connectionStrength,
      );
      neuronTo.dendrites[emptySpotIndex].sinapseFirstLevel.add(newSinapse);
      // continue;
      return;
    }

    Neuron neuronFrom = neurons[fromIdx].newNeuron;
    // neuronFrom.displayInfo();
    // neuronTo.displayInfo();
    //neuron to neuron connection
    List<SinapsePoint> distancesToSinapses = [];
    //find dendrite (on posinaptic neuron ) that is pointing toward center of connections of presinaptic neuron
    // print("neuronFrom.dendrites.length: ${neuronTo.dendrites.length}");
    // print("distancesToSinapses0");
    for (int dendriteIndex = 0;
        dendriteIndex < neuronTo.dendrites.length;
        dendriteIndex++) {
      double distance = euclideanDistance(
          neuronFrom.xCenterOfConnections,
          neuronFrom.yCenterOfConnections,
          neuronTo.dendrites[dendriteIndex].xFirstLevel + neuronTo.x,
          neuronTo.dendrites[dendriteIndex].yFirstLevel + neuronTo.y);
      distancesToSinapses.add(SinapsePoint(
          dendriteIndex: dendriteIndex,
          distance: distance,
          isFirstLevel: true));
      // print(
      //     "${dendriteIndex} : ${distance} ${neuronFrom.xCenterOfConnections}, ${neuronFrom.yCenterOfConnections}, FirstLevel:${neuronTo.dendrites[dendriteIndex].xFirstLevel + neuronTo.x}, ${neuronTo.dendrites[dendriteIndex].yFirstLevel + neuronTo.y} - Raw Second Level: ${neuronTo.dendrites[dendriteIndex].xSecondLevel}, ${neuronTo.dendrites[dendriteIndex].ySecondLevel} - ${neuronTo.dendrites[dendriteIndex].hasSecondLevel} isFirstLevel true");

      // print(
      //     "${neuronFrom.xCenterOfConnections} -- ${neuronFrom.yCenterOfConnections} -- ${neuronTo.dendrites[dendriteIndex].xFirstLevel} -- ${neuronTo.dendrites[dendriteIndex].yFirstLevel}");
      if (neuronTo.dendrites[dendriteIndex].hasSecondLevel) {
        distance = euclideanDistance(
            neuronFrom.xCenterOfConnections,
            neuronFrom.yCenterOfConnections,
            neuronTo.dendrites[dendriteIndex].xSecondLevel + neuronTo.x,
            neuronTo.dendrites[dendriteIndex].ySecondLevel + neuronTo.y);
        distancesToSinapses.add(SinapsePoint(
            dendriteIndex: dendriteIndex,
            distance: distance,
            isFirstLevel: false));
        print(
            "${dendriteIndex} : ${distance} ${neuronFrom.xCenterOfConnections}, ${neuronFrom.yCenterOfConnections}, SecondLevel: ${neuronTo.dendrites[dendriteIndex].xSecondLevel + neuronTo.x}, ${neuronTo.dendrites[dendriteIndex].ySecondLevel + neuronTo.y} - ${neuronTo.dendrites[dendriteIndex].hasSecondLevel} ${neuronTo.dendrites[dendriteIndex].hasSecondLevel} isFirstLevel false");
      }
    }
    distancesToSinapses.sort((a, b) => a.distance.compareTo(b.distance));
    print("distancesToSinapses");
    for (var sinapse in distancesToSinapses) {
      print(
          "${sinapse.dendriteIndex} : ${sinapse.distance} ${sinapse.isFirstLevel}");
    }
    //distancesToSinapses = distancesToSinapses.reversed.toList();R

    bool foundPlace = false;
    for (int disin = 0; disin < distancesToSinapses.length; disin++) {
      // print(
      //     "isFirstLevel : ${distancesToSinapses[disin].isFirstLevel} - isSinapseFirstLevel.isEmpty : ${neuronTo.dendrites[distancesToSinapses[disin].dendriteIndex].sinapseFirstLevel.isEmpty}");
      // print(
      //     "isSecondLevel : ${distancesToSinapses[disin].isFirstLevel} - isSinapseSecondLevel.isEmpty : ${neuronTo.dendrites[distancesToSinapses[disin].dendriteIndex].sinapseSecondLevel.isEmpty}");

      if (distancesToSinapses[disin].isFirstLevel) {
        if (neuronTo.dendrites[distancesToSinapses[disin].dendriteIndex]
            .sinapseFirstLevel.isEmpty) {
          foundPlace = true;

          Sinapse newSinapse = Sinapse(
            presinapticNeuronIndex: fromIdx,
            sinapticValue: connectionStrength,
          );
          neuronTo.dendrites[distancesToSinapses[disin].dendriteIndex]
              .sinapseFirstLevel
              .add(newSinapse);
          break;
        }
      } else {
        if (neuronTo.dendrites[distancesToSinapses[disin].dendriteIndex]
            .sinapseSecondLevel.isEmpty) {
          foundPlace = true;
          Sinapse newSinapse = Sinapse(
            presinapticNeuronIndex: fromIdx,
            sinapticValue: connectionStrength,
          );
          neuronTo.dendrites[distancesToSinapses[disin].dendriteIndex]
              .sinapseSecondLevel
              .add(newSinapse);
          break;
        }
      }
    }

    print("foundPlace: $foundPlace");

    if (!foundPlace) {
      Sinapse newSinapse = Sinapse(
        presinapticNeuronIndex: fromIdx,
        sinapticValue: connectionStrength,
      );
      neuronTo.dendrites[distancesToSinapses[0].dendriteIndex].sinapseFirstLevel
          .add(newSinapse);
    }
  }

  List<SyntheticNeuron> copyFromRawSynthetics(
      List<SyntheticNeuron> syntheticNeuronList) {
    var neuronIdx = 0;
    for (SyntheticNeuron syntheticNeuron in syntheticNeuronList) {
      SyntheticNeuron rawSyntheticNeuron = syntheticNeuron.rawSyntheticNeuron;
      if (rawSyntheticNeuron.dendrites.isNotEmpty) {
        // print("raw dendrite length: ${rawSyntheticNeuron.dendrites.length}");
        // print(
        //     "dendrite length: ${syntheticNeuronList[neuronIdx].dendrites.length}");
        syntheticNeuronList[neuronIdx].dendrites.clear();

        // List<Dendrite> tempDendritesList = [];
        int dendriteIdx = 0;
        for (Dendrite rawDendrite in rawSyntheticNeuron.dendrites) {
          Dendrite newDendrite = Dendrite(
              hasSecondLevel: rawDendrite.hasSecondLevel,
              angle: rawDendrite.angle,
              // sinapseFirstLevel: rawDendrite.sinapseFirstLevel,
              // sinapseSecondLevel: rawDendrite.sinapseSecondLevel,
              // xFirstLevel: rawDendrite.xFirstLevel,
              // xSecondLevel: rawDendrite.xSecondLevel,
              sinapseFirstLevel: [],
              sinapseSecondLevel: [],
              xFirstLevel: rawDendrite.xFirstLevel,
              yFirstLevel: rawDendrite.yFirstLevel,
              xSecondLevel: rawDendrite.xSecondLevel,
              ySecondLevel: rawDendrite.ySecondLevel,
              xTriangleFirstLevel: rawDendrite.xTriangleFirstLevel,
              yTriangleFirstLevel: rawDendrite.yTriangleFirstLevel,
              xTriangleSecondLevel: rawDendrite.xTriangleSecondLevel,
              yTriangleSecondLevel: rawDendrite.yTriangleSecondLevel);
          // tempDendritesList.add(newDendrite);
          syntheticNeuronList[neuronIdx].dendrites.add(newDendrite);
          if (neuronIdx >= 12) {
            print(rawDendrite.xFirstLevel);
            print(rawDendrite.yFirstLevel);
            print(rawDendrite.xSecondLevel);
            print(rawDendrite.ySecondLevel);
            print(syntheticNeuronList[neuronIdx].newNeuron.x);
            print(syntheticNeuronList[neuronIdx].newNeuron.y);
            print("============ $neuronIdx dendrite: $dendriteIdx");
          }
          dendriteIdx++;
        }
        // syntheticNeuronList[neuronIdx].dendrites.addAll(tempDendritesList);
      }
      syntheticNeuronList[neuronIdx].recalculate(null);

      neuronIdx++;
    }
    return syntheticNeuronList;
  }

  void createSyntheticAxon2(List<SyntheticNeuron> syntheticNeurons,
      int pfromIdx, int ptoIdx, double d) {
    List<SyntheticNeuron> neurons = syntheticNeurons;
    List<Connection> connections = syntheticConnections;
    for (int i = 0; i < neurons.length; i++) {
      for (Connection con in connections) {
        int fromIdx =
            neuronTypes.keys.toList().indexOf(con.neuronIndex1.toString());
        int toIdx =
            neuronTypes.keys.toList().indexOf(con.neuronIndex2.toString());
        Neuron neuronTo = neurons[toIdx].newNeuron;
        Neuron neuronFrom = neurons[fromIdx].newNeuron;

        // Neuron neuronFrom = neurons[fromIdx].newNeuron;

        if (toIdx == i) {
          //check if we are connection to IO connections
          //use different logic
          if (neurons[toIdx].newNeuron.isIO) {
            int emptySpotIndex = 0;
            int smalestNumber = 9999999;
            for (int dendriteIndex = 0;
                dendriteIndex < neurons[toIdx].dendrites.length;
                dendriteIndex++) {
              if (neurons[toIdx]
                      .dendrites[dendriteIndex]
                      .sinapseFirstLevel
                      .length <
                  smalestNumber) {
                emptySpotIndex = dendriteIndex;
                smalestNumber = neurons[toIdx]
                    .dendrites[dendriteIndex]
                    .sinapseFirstLevel
                    .length;
              }
            }
            Sinapse newSinapse = Sinapse(
              presinapticNeuronIndex: fromIdx,
              sinapticValue: con.connectionStrength,
            );
            neurons[toIdx]
                .dendrites[emptySpotIndex]
                .sinapseFirstLevel
                .add(newSinapse);
            continue;
          }

          //neuron to neuron connection
          List<SinapsePoint> distancesToSinapses = [];
          //find dendrite (on posinaptic neuron ) that is pointing toward center of connections of presinaptic neuron
          for (int dendriteIndex = 0;
              dendriteIndex < neurons[toIdx].dendrites.length;
              dendriteIndex++) {
            double distance = euclideanDistance(
                neurons[fromIdx].newNeuron.xCenterOfConnections,
                neurons[fromIdx].newNeuron.yCenterOfConnections,
                neurons[toIdx].newNeuron.dendrites[dendriteIndex].xFirstLevel +
                    neuronTo.x,
                neurons[toIdx].newNeuron.dendrites[dendriteIndex].yFirstLevel +
                    neuronTo.y);
            distancesToSinapses.add(SinapsePoint(
                dendriteIndex: dendriteIndex,
                distance: distance,
                isFirstLevel: true));
            if (neurons[toIdx].dendrites[dendriteIndex].hasSecondLevel) {
              distance = euclideanDistance(
                  neurons[fromIdx].newNeuron.xCenterOfConnections,
                  neurons[fromIdx].newNeuron.yCenterOfConnections,
                  neurons[toIdx].dendrites[dendriteIndex].xSecondLevel +
                      neuronTo.x,
                  neurons[toIdx].dendrites[dendriteIndex].ySecondLevel +
                      neuronTo.y);
              distancesToSinapses.add(SinapsePoint(
                  dendriteIndex: dendriteIndex,
                  distance: distance,
                  isFirstLevel: false));
            }
            print(
                "${dendriteIndex} : ${distance} ${neuronFrom.xCenterOfConnections}, ${neuronFrom.yCenterOfConnections}, SecondLevel: ${neuronTo.dendrites[dendriteIndex].xSecondLevel + neuronTo.x}, ${neuronTo.dendrites[dendriteIndex].ySecondLevel + neuronTo.y} - ${neuronTo.dendrites[dendriteIndex].hasSecondLevel} ${neuronTo.dendrites[dendriteIndex].hasSecondLevel} isFirstLevel false");
          }
          distancesToSinapses.sort((a, b) => a.distance.compareTo(b.distance));
          print("distancesToSinapses ${distancesToSinapses.length}");
          for (var sinapse in distancesToSinapses) {
            print(
                " $fromIdx @ $toIdx-- ${sinapse.dendriteIndex} : ${sinapse.distance} ${sinapse.isFirstLevel} == ${neuronFrom.x}|${neuronFrom.y} __ ${neuronTo.x}|${neuronTo.y}");
          }

          //distancesToSinapses = distancesToSinapses.reversed.toList();

          bool foundPlace = false;
          for (int disin = 0; disin < distancesToSinapses.length; disin++) {
            if (distancesToSinapses[disin].isFirstLevel) {
              if (neurons[toIdx]
                  .dendrites[distancesToSinapses[disin].dendriteIndex]
                  .sinapseFirstLevel
                  .isEmpty) {
                foundPlace = true;

                Sinapse newSinapse = Sinapse(
                  presinapticNeuronIndex: fromIdx,
                  sinapticValue: con.connectionStrength,
                );
                neurons[toIdx]
                    .dendrites[distancesToSinapses[disin].dendriteIndex]
                    .sinapseFirstLevel
                    .add(newSinapse);
                break;
              }
            } else {
              if (neurons[toIdx]
                  .dendrites[distancesToSinapses[disin].dendriteIndex]
                  .sinapseSecondLevel
                  .isEmpty) {
                foundPlace = true;
                Sinapse newSinapse = Sinapse(
                  presinapticNeuronIndex: fromIdx,
                  sinapticValue: con.connectionStrength,
                );
                neurons[toIdx]
                    .dendrites[distancesToSinapses[disin].dendriteIndex]
                    .sinapseSecondLevel
                    .add(newSinapse);
                break;
              }
            }
          }

          if (!foundPlace) {
            Sinapse newSinapse = Sinapse(
              presinapticNeuronIndex: fromIdx,
              sinapticValue: con.connectionStrength,
            );
            neurons[toIdx]
                .dendrites[distancesToSinapses[0].dendriteIndex]
                .sinapseFirstLevel
                .add(newSinapse);
          }
        }
      }
    }
  }
}
