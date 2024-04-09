import 'dart:io';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../domain/model/edge.dart';
import '../../domain/model/graph.dart';
import '../../domain/model/node.dart';

typedef NodeFormatter = void Function(InfiniteCanvasNode);

/// A controller for the [InfiniteCanvas].
class InfiniteCanvasController extends ChangeNotifier implements Graph {
  bool isInteractable = true;
  bool isFoundEdge = false;
  bool isSelectingEdge = false;
  final VoidCallback onLongPress;
  final VoidCallback onDoubleTap;
  // final VoidCallback transformNeuronPositionWrapper;

  InfiniteCanvasController({
    required this.onLongPress,
    required this.onDoubleTap,
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
    notifyListeners();
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

      Path p = Path()
        ..moveTo(iFrom.dx, iFrom.dy)
        ..lineTo(iTo.dx, iTo.dy)
        ..lineTo(oTo.dx, oTo.dy)
        ..lineTo(oFrom.dx, oFrom.dy)
        ..lineTo(iFrom.dx, iFrom.dy);

      p.close();

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
    deselectAll(true);
    deselectAll(false);
    notifyListeners();
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
}
