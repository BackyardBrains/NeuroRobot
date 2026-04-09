import 'dart:io';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:infinite_canvas/src/domain/model/SyntheticEdge.dart';
import 'package:infinite_canvas/src/domain/model/SyntheticNeuron.dart';
import 'package:infinite_canvas/src/presentation/widgets/nucleus.dart';

import '../../domain/model/drop_target.dart';
import '../../domain/model/edge.dart';
import '../../domain/model/graph.dart';
import '../../domain/model/node.dart';

class SynapseShape {
  final int fromIdx;
  final Path? triPath;
  final Offset? circleCenter;
  final double? radius;
  final bool isExcitatory;

  SynapseShape({
    required this.fromIdx,
    this.triPath,
    this.circleCenter,
    this.radius,
    required this.isExcitatory,
  });
}

typedef NodeFormatter = void Function(InfiniteCanvasNode);

/// A controller for the [InfiniteCanvas].
class InfiniteCanvasController extends ChangeNotifier implements Graph {
  late bool isPlaying = false;
  bool isInteractable = true;
  bool isFoundEdge = false;
  bool isSelectingEdge = false;
  bool isDraggingPin = false; // V25: Track Live Mode Pin drags for +30px target inflation
  ValueNotifier<int> waveRedraw = ValueNotifier(0); // V25: Synchronizes physics simulation updates to the display canvas
  ValueNotifier<int> synapseFadeNotifier = ValueNotifier(0); // Targeted repaint for spike fade — avoids full canvas rebuild
  final List<SyntheticNeuron> rawSyntheticNeuronList;
  List<SyntheticNeuron> syntheticNeuronList;
  final List<Connection> syntheticConnections;
  List<Nucleus>? nucleusList;
  final Map<String, String> neuronTypes;
  final VoidCallback onLongPress;
  final VoidCallback onDoubleTap;
  final VoidCallback onDeleteCallback;
  final Function(LocalKey a, LocalKey b) onAxonCreatedCallback;

  Map<String, Path> axonPathMap = {};
  Map<String, int> axonPathHashes = {}; // V25: Caches bezier coordinates to avoid O(N) path math per frame
  Map<String, TextPainter> textPainterCache = {}; // V25: Caches heavy typography layouts
  Map<String, List<InfiniteCanvasEdge>> trunkToEdgesMap = {}; // Maps Trunk Key to Downstream Edges
  Map<String, List<Offset>> edgeBranchPointMap = {}; // Maps Edge Key to [branchPoint, branchDirection]
  Map<LocalKey, int> sourcePreviousEdgeCount = {}; // V25: Tracks edge count per source for cache invalidation
  int modeIdx = 0;
  List<SynapseShape> cachedSynapses = [];
  /// True whenever edges or nodes change structure — tells edge_renderer to
  /// rebuild syntheticConnections and cachedSynapses on the next paint.
  /// Starts true so the very first paint populates both caches.
  bool syntheticConnectionsDirty = true;
  /// Set true during the one paint where cachedSynapses is being rebuilt.
  /// Prevents unbounded list growth from add() calls on subsequent paints.
  bool buildingSynapseCache = false;
  /// Set true when nodes move — triggers a cheap cachedSynapses position rebuild
  /// without the expensive addSyntheticConnection dendrite rebuild.
  bool positionDirty = false;

  List<LocalKey>? restrictedToNeuronsKey;
  List<LocalKey>? restrictedFromNeuronsKey;
  // final VoidCallback transformNeuronPositionWrapper;

  // V25: Proactive Boundary Constraint Callback to fix drag flickering
  Offset Function(InfiniteCanvasNode node, Offset newOffset)? boundaryConstraint;

  // V25: Sensory Config Maps (Reference to DesignBrainPage state)
  Map<dynamic, dynamic> mapSensoryNeuron = {};
  Map<dynamic, dynamic> mapDistanceNeuron = {};
  Map<dynamic, dynamic> mapMicrophoneTypeNeuron = {}; // Mode
  Map<dynamic, dynamic> mapMicrophoneLimitNeuron = {}; // Limits (and Piano Notes)
  Map<dynamic, dynamic> mapMicrophoneNeuron = {}; // Connection Strength/ID
  Map<dynamic, dynamic> mapSpeakerNeuron = {}; // Tone definition
  
  // V25: Missing Maps added for Persistence Sync
  Map<dynamic, dynamic> mapContactsNeuron = {}; 
  Map<dynamic, dynamic> mapConnectome = {};
  Map<dynamic, dynamic> mapLedNeuron = {};

  InfiniteCanvasController({
    required this.rawSyntheticNeuronList,
    required this.syntheticNeuronList,
    required this.syntheticConnections,
    this.nucleusList,
    required this.neuronTypes,
    required this.onLongPress,
    required this.onDoubleTap,
    required this.onDeleteCallback,
    required this.onAxonCreatedCallback,
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

  List<InfiniteDropTarget> dropTargets = [];

  @override
  final List<InfiniteCanvasNode> nodes = [];

  @override
  final List<InfiniteCanvasEdge> edges = [];

  // STEVE
  InfiniteCanvasEdge? edgeFound;
  InfiniteCanvasEdge? edgeSelected;
  List<InfiniteCanvasEdge> get edgeSelection => edgeSelected == null
      ? []
      : edges
          .where((e) =>
              edgeSelected!.from == e.from && edgeSelected!.to == e.to)
          .toList();
      
  // V25: Support for multiple edge selection (Trunk Selection)
  Set<InfiniteCanvasEdge> multiEdgeSelection = {};
  
  bool isEdgeInSelection(InfiniteCanvasEdge edge) {
    if (multiEdgeSelection.contains(edge)) return true;
    if (isSelectingEdge && edgeSelected == edge) return true;
    return false;
  }

  InfiniteCanvasNode? singleSelection;
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
  bool isAnimatingCamera = false;
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
    
    // V25: Update source neuron rotation during drag
    if (linkStart != null && value != null) {
      _updateDragRotation();
    }
    
    notifyListeners();
  }
  
  // V25: Update source neuron rotation to point toward drag position + existing connections
  void _updateDragRotation() {
    if (linkStart == null || linkEnd == null) return;
    
    try {
      // Find the synthetic neuron that corresponds to the drag source
      SyntheticNeuron? sourceNeuron;
      for (var sn in syntheticNeuronList) {
        if (sn.node.key == linkStart) {
          sourceNeuron = sn;
          break;
        }
      }
      
      if (sourceNeuron == null) return;
      
      final neuron = sourceNeuron.newNeuron;
      final sourceX = neuron.x;
      final sourceY = neuron.y;
      
      // Calculate centroid including existing downstream connections + drag position
      double sumX = linkEnd!.dx;
      double sumY = linkEnd!.dy;
      int count = 1;
      
      // Include all existing downstream connections in centroid
      for (var edge in edges) {
        if (edge.from == linkStart) {
          final targetNode = nodes.firstWhere((n) => n.key == edge.to);
          Offset targetCenter = targetNode.offset + Offset(targetNode.size.width/2, targetNode.size.height/2);
          sumX += targetCenter.dx;
          sumY += targetCenter.dy;
          count++;
        }
      }
      
      // Calculate angle toward centroid
      double centroidX = sumX / count;
      double centroidY = sumY / count;
      double targetAngle = atan2(centroidY - sourceY, centroidX - sourceX) * 180 / pi;
      
      // Normalize to 0-360 to avoid negative values
      if (targetAngle < 0) targetAngle += 360;
      
      // Update axonAngle - initialize baseAxonAngle if needed
      if (neuron.axonAngle <= -1) {
        neuron.axonAngle = targetAngle;
        neuron.baseAxonAngle = targetAngle;
      } else {
        neuron.axonAngle = targetAngle;
      }
    } catch (e) {
      // Neuron not initialized yet
    }
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

  void quietlySetScale(double value) { 
    _scale = value; 
  }

  // --- Frame-rate throttle for hot-path notifications (e.g. node drag) ---
  // Pointer events can arrive at 250 Hz+. Calling notifyListeners() on every
  // event triggers setState() in every listener at that rate, causing jitter.
  // _scheduleNotify() coalesces all notifications within a single frame into
  // one call — matching the display-sync behaviour of InteractiveViewer.
  bool _frameNotifyPending = false;
  void _scheduleNotify() {
    if (_frameNotifyPending) return;
    _frameNotifyPending = true;
    SchedulerBinding.instance.scheduleFrameCallback((_) {
      _frameNotifyPending = false;
      notifyListeners();
    });
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
      edgeSelected != null &&
      edgeSelected!.from == keyFrom &&
      edgeSelected!.to == keyTo;
  bool get hasEdgeSelection => edgeSelection.isNotEmpty;

  bool isSelected(LocalKey key) => _selected.contains(key);
  bool isHovered(LocalKey key) => _hovered.contains(key);

  bool get hasSelection => _selected.isNotEmpty;

  bool _canvasMoveEnabled = true;
  bool get canvasMoveEnabled => _canvasMoveEnabled;
  void setCanvasMove(bool value) {
    _canvasMoveEnabled = value;
  }

  /// When true, single-pointer drag does NOT move nodes (annotation select mode).
  bool lockNodeDragging = false;

  // ─── Annotation Selection State ────────────────────────────────────────────
  /// True while the annotation-selection UI is active.
  bool isInAnnotationMode = false;
  /// True when the user has pressed Edit and can change the selection.
  /// When false (view-only), tapping neurons/axons must NOT modify the highlight.
  bool annotationEditEnabled = false;
  /// Node key strings (GlobalKey.toString()) currently highlighted for annotation.
  Set<String> annotationHighlightNodeKeys = {};
  /// Edge objects currently highlighted for annotation.
  Set<InfiniteCanvasEdge> annotationHighlightEdges = {};

  void clearAnnotationHighlights() {
    annotationHighlightNodeKeys.clear();
    annotationHighlightEdges.clear();
  }

  void notifyMousePosition() {
    // notifyListeners();
  }

  Offset toLocal(Offset global) {
    return transform.toScene(global);
  }

  // V25: Callback to check if a node is a sensor (to prevent trunk selection)
  bool Function(InfiniteCanvasNode)? isSensorNode;

  // V25: Multi-selection Synaptic Weight Accessor
  double get synapticWeight {
    if (multiEdgeSelection.isNotEmpty) {
      // Return value of first selected edge (or maybe average? User requested 50 if mixed)
      // Logic for "Grey if different" will be in UI. Here we just return a representative value.
      return multiEdgeSelection.first.connectionStrength ?? 0;
    }
    if (isSelectingEdge) {
      return edgeSelected?.connectionStrength ?? 0;
    }
    return 0;
  }

  int renderVersion = 0;

  @override
  void notifyListeners() {
    renderVersion++;
    super.notifyListeners();
  }

  set synapticWeight(double value) {
    if (multiEdgeSelection.isNotEmpty) {
      for (var edge in multiEdgeSelection) {
        edge.connectionStrength = value;
        edge.label = value.toInt().toString();
      }
    } else if (isSelectingEdge && edgeSelected != null) {
      edgeSelected!.connectionStrength = value;
      edgeSelected!.label = value.toInt().toString();
    }
    // Rebuild dendrite sinapticValue so drawAxon reads updated thickness.
    syntheticConnectionsDirty = true;
    notifyListeners();
  }

  void checkSelection(Offset localPosition, [bool hover = false]) {
    // Disable interaction in Live Mode (User Request)
    if (isPlaying) return;

    if (!isInteractable) {
      deselectAll(true);
      deselectAll();
      return;
    }
    // print("CHECK SELECT");
    if (_selected.isNotEmpty) {
      // print(_selected.last);
      List<InfiniteCanvasNode> prevSelection =
          nodes.where((element) => element.key == _selected.last).toList();
      // print(prevSelection);
      singleSelection = prevSelection.isEmpty ? null : prevSelection[0];
    } else {
      singleSelection = null;
    }

    final offset = toLocal(localPosition);
    final selection = <Key>[];
    double minHitDistance = double.infinity;
    Key? closestNodeKey;

    for (final child in nodes) {
      // V25: Ignore hidden/zero-sized nodes (Fixes invisible tail interference)
      // V25: Circular Precision Hitbox (User Request)
      // Extract the exact center of the square node
      double centerX = child.rect.left + (child.rect.width / 2.0);
      double centerY = child.rect.top + (child.rect.height / 2.0);
      
      // Base radius is precisely half the visual width without any massive invisible padding
      double baseRadius = child.rect.width / 2.0;
      
      double currentScale = getScale();

      // If the user is currently targeting this exact node, it visually expanded to 1.5x in the GUI.
      // We must match that expanded visual radius so they don't accidentally click off it while tuning!
      if (_selected.contains(child.key)) {
          baseRadius *= 1.5;
      }
      
      // To allow dragging links from tiny zoomed-out distances, we allow a small snap-radius 
      // ONLY when actively dragging a line. Otherwise, we keep it pixel perfect for tapping.
      // V25 FEATURE: We now also include `isDraggingPin` to provide $+30px$ target magnetism 
      // when placing Live Mode plot Pins on neurons.
      if (linkStart != null || controlPressed || isDraggingPin) {
          if (isHovered(child.key)) {
             baseRadius += 30.0 / currentScale;
          } else {
             baseRadius += 15.0 / currentScale; 
          }
      } else {
          // V25 FEATURE: General node touch slop MUST scale dynamically! Otherwise, zooming out 10x 
          // squishes a 30 logical-pixel threshold into a 3 screen-pixel dot, freezing the UI.
          baseRadius += 10.0 / currentScale;
      }
      
      // Calculate Euclidean distance from tap to center
      double dx = offset.dx - centerX;
      double dy = offset.dy - centerY;
      double distance = sqrt(dx*dx + dy*dy);
      
      if (distance <= baseRadius) {
         // V25 FEATURE: Reject click events on output neurons' empty body space
         bool isOutput = false;
         for (var sn in syntheticNeuronList) {
            if (sn.node.key == child.key && sn.isOutput) {
                 isOutput = true; 
                 break;
            }
         }
         
         if (!isOutput) {
            if (distance < minHitDistance) {
               minHitDistance = distance;
               closestNodeKey = child.key;
            }
         }
      }
    }

    if (closestNodeKey != null) {
        selection.add(closestNodeKey);
    }
    // print("DEBUG: checkSelection: offset $offset, nodes: ${nodes.length}, edges: ${edges.length}");
    if (!hover) {
      if (kIsWeb) {
      } else if (Platform.isIOS || Platform.isAndroid || Platform.isMacOS) {
        isSelectingEdge = false;
        // edgeSelected = null; // Don't null here, let loop overwrite or final check clear?
        // Actually, if we reset isSelectingEdge to false, then even if edgeSelected persists, it won't show.
        // UNLESS we re-enable isSelectingEdge later without updating edgeSelected.
        // Let's be safe.
        edgeSelected = null;  // V25: Ensure cleared to prevent ghosts
        // V25: Also clear edgeFound to prevent stale overwrites in onTapUp
        edgeFound = null;
        isFoundEdge = false;
      }
      // V25: Unconditional clear for safety even if platform logic differs? 
      // No, sticking to platform block is safer for now, but adding explicit multi-clear if needed?
      // Actually, let's just be sure.
      if (!hover) {
          edgeSelected = null;
          isSelectingEdge = false;
          // Note: multiEdgeSelection is cleared later if we find a hit, 
          // OR we should clear it here? 
          // If we click empty space, we want to clear.
          // The loop logic does `deselectAll` at the end if nothing found.
      }
    }
    
    
    // V25: PRIORITY 1 - NEURONS.
    // If we hit a neuron, skip edge selection entirely.
    if (selection.isNotEmpty) {
       // V25: User clicked a generic node/neuron.
       // Explicitly clear any edge selection to ensure only the neuron is highlighted.
       edgeSelected = null;
       edgeFound = null;
       isSelectingEdge = false;
       multiEdgeSelection.clear();
    } else {
       // Only check edges if no neuron was hit, AND not currently dragging a connection
       if (linkStart == null && !controlPressed) {
         for (final edge in edges) {
      const lineWidth = 7;
      const radius = 10;
      var eFromList = nodes.where((e) => edge.from == (e.key)).toList();
      var eBookList = nodes.where((e) => edge.to == (e.key)).toList();
      
      if (eFromList.isEmpty || eBookList.isEmpty) {
          // printDebug("Warning: Edge ${edge.from}->${edge.to} references missing node.");
          continue;
      }
      var eFrom = eFromList[0];
      var eTo = eBookList[0];

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

/*
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
*/
      // Path p = Path()
      //   ..moveTo(iFrom.dx, iFrom.dy)
      //   ..lineTo(iTo.dx, iTo.dy)
      //   ..lineTo(oTo.dx, oTo.dy)
      //   ..lineTo(oFrom.dx, oFrom.dy)
      //   ..lineTo(iFrom.dx, iFrom.dy);

      // p.close();
      String pathKey = "${eFrom.key.toString()}_${eTo.key.toString()}";
      
      // V25: Trunk Segment Hit Testing (PRIORITY 2 - TRUNK)
      // Iterate over all keys in axonPathMap to find trunk segments from this source
      // Keys are formatted as: "${sourceKey}_trunk_${index}"
      bool trunkHit = false;
      
      // Check if source is a sensor - if so, skip trunk selection
      if (isSensorNode == null || !isSensorNode!(eFrom)) {
        for (String key in axonPathMap.keys) {
          if (key.startsWith("${eFrom.key.toString()}_trunk_")) {
             Path p = axonPathMap[key]!;
             
             // Check if we hit this trunk segment
             if (p.contains(offset)) {
               trunkHit = true;
               // print("DEBUG: Trunk Hit! Key: $key");
               
               // Extract segment index
               int segmentIndex = int.tryParse(key.split("_trunk_").last) ?? 0;
               
               // Get all downstream edges for this source
               // The trunkToEdgesMap stores them sorted by branch order (closest to soma first)
               String trunkBaseKey = "${eFrom.key.toString()}_trunk";
               List<InfiniteCanvasEdge>? downstreamEdges = trunkToEdgesMap[trunkBaseKey];
               
               if (downstreamEdges != null && segmentIndex < downstreamEdges.length) {
                 isSelectingEdge = true;
                 isFoundEdge = true; // V25: Found edge (trunk)
                 
                 multiEdgeSelection.clear();
                 
                 // V25: Improved Selection Logic for Mixed Trunks
                 // Goal: If ANY standard neuron connections exist, prioritize them. 
                 // Do NOT select Speaker/LED edges for multi-selection to avoid wrong UI widgets.
                 
                 List<InfiniteCanvasEdge> validNeuronEdges = [];
                 List<InfiniteCanvasEdge> sensoryEdges = [];
                 
                 for (int i = segmentIndex; i < downstreamEdges.length; i++) {
                     InfiniteCanvasEdge edge = downstreamEdges[i];
                     bool isSensory = false;
                     try {
                        var targetNode = nodes.firstWhere((n) => n.key == edge.to);
                        
                        // Check 1: Explicit isSensory flag (Architecture property)
                        // Check 2: Label String Analysis
                         String lbl = (targetNode.label ?? "").toUpperCase();
                        
                        // V25: Explicitly exclude MOTORS from multi-selection (User Request)
                        // They should behave like Speakers/LEDs (Sensory)
                           if (targetNode.isSensory == 1) isSensory = true;
                           if (lbl.contains("SPEAKER") || lbl.contains("LED") || lbl.contains("MIC") || lbl.contains("CAMERA") || lbl.contains("MOTOR")) {
                              isSensory = true;
                           }
                        
                     } catch (e) {
                        // print("DEBUG: Error checking edge target: $e");
                     }
                     
                     if (isSensory) {
                        sensoryEdges.add(edge);
                     } else {
                        validNeuronEdges.add(edge);
                     }
                 }
                 
                 // print("DEBUG: Valid Neuron/Motor Edges: ${validNeuronEdges.length}");

                 if (validNeuronEdges.isNotEmpty) {
                    // CASE A: Standard Neurons Present -> Select them ALL (Multi)
                    // Ensure the 'primary' selection is a valid neuron edge to trigger Weight Widget
                    edgeSelected = validNeuronEdges.first;
                    multiEdgeSelection.addAll(validNeuronEdges);
                 } else {
                    // CASE B: Only Sensory/Other -> Keep specific selection
                    // Select the specific edge corresponding to this segment (if possible)
                    // or just the first one if we are at the end.
                    edgeSelected = downstreamEdges[segmentIndex];
                 }
                 
                 edgeFound = edgeSelected; // V25: Sync edgeFound so onTapUp doesn't revert to old edge!
                 
                 // V25: Explicitly clear NODE selection to prevent ghost highlights
                 _selected.clear();
                 singleSelection = null;
                 
                 // ANNOTATION MODE: toggle all downstream axons ONLY in edit mode.
                 if (isInAnnotationMode && annotationEditEnabled && validNeuronEdges.isNotEmpty) {
                   final allSelected = validNeuronEdges.every((e) => annotationHighlightEdges.contains(e));
                   if (allSelected) {
                     for (final e in validNeuronEdges) annotationHighlightEdges.remove(e);
                   } else {
                     for (final e in validNeuronEdges) annotationHighlightEdges.add(e);
                   }
                   isSelectingEdge = false;
                   edgeSelected = null;
                   multiEdgeSelection.clear();
                   isFoundEdge = false;
                   edgeFound = null;
                 } else if (isInAnnotationMode) {
                   // View-only: do nothing to highlights, but still clear edge state
                   isSelectingEdge = false;
                   edgeSelected = null;
                   multiEdgeSelection.clear();
                   isFoundEdge = false;
                   edgeFound = null;
                 }
               }
               break;
             }
          }
        }
      }
      if (trunkHit) break; // Stop checking other edges if we hit a trunk

      // V25: Check for direct edge hit (PRIORITY 3 - AXON)
      if (axonPathMap.containsKey(pathKey)) {
        Path p = axonPathMap[pathKey]!;

        if (p.contains(offset)) {
          edgeFound = edge;
          isFoundEdge = true;
          if (kIsWeb) {
          } else if (Platform.isIOS || Platform.isAndroid || Platform.isMacOS) {
            // print("DEBUG: Direct Edge Hit. Selecting edge.");
            isSelectingEdge = true;
            edgeSelected = edge;
            multiEdgeSelection.clear(); // Clear multi-selection on direct tap
            multiEdgeSelection.add(edge);
            
            // V25: Explicitly clear NODE selection to prevent "Ghost" highlights
            _selected.clear();
            singleSelection = null;
            
            // ANNOTATION MODE: toggle this single axon ONLY in edit mode.
            if (isInAnnotationMode) {
              if (annotationEditEnabled) {
                if (annotationHighlightEdges.contains(edge)) {
                  annotationHighlightEdges.remove(edge);
                } else {
                  annotationHighlightEdges.add(edge);
                }
              }
              // Always clear edge selection state so the outer GestureDetector.onTapUp
              // cannot read isFoundEdge=true and restore isSelectingEdge on finger-up.
              isSelectingEdge = false;
              edgeSelected = null;
              multiEdgeSelection.clear();
              isFoundEdge = false;
              edgeFound = null;
            }
          }

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
    }
    }
    if (selection.isNotEmpty && !isSelectingEdge) {
      if (shiftPressed) {
        setSelection({selection.last, ..._selected.toSet()}, hover);
      } else {
        setSelection({selection.last}, hover);
      }
    } else {
      // V25: Only deselect all if we also didn't select an edge
      // AND prioritize updated edge selection signal
       if (!isSelectingEdge) {
          deselectAll(hover);
       } else {
          // We have an edge selected, so just clear node selection logic without clearing edge flags
          if (hover) {
            _hovered.clear();
          } else {
             _selected.clear();
             _selectedOrigins.clear();
             // Important: Do NOT call deselectAll() as it clears multiEdgeSelection
          }
          notifyListeners();
       }
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
        for (InfiniteCanvasNode n in nodes) {
          if (n.key == from) {
            print("edge.isExcitatory");
            print("${n.isExcitatory}");
            edge.isExcitatory = n.isExcitatory.toDouble();
          }
        }
        onAxonCreatedCallback(edge.from, edge.to);
      }
    }
    deselectAll(true);
    deselectAll(false);
    multiEdgeSelection.clear();
    syntheticConnectionsDirty = true; // force edge_renderer rebuild on next paint
    notifyListeners();
    // addSyntheticConnection(edge.from, edge.to);
  }

  void moveSelection(Offset position) {
    if (lockNodeDragging) return; // annotation mode: nodes are not movable
    if (_selected.isEmpty) {
        return; // Early bailout to prevent massive unnecessary redraw loop!
    }
    final delta = mouseDragStart != null
        ? toLocal(position) - toLocal(mouseDragStart!)
        : toLocal(position);
    for (final key in _selected) {
      final index = nodes.indexWhere((e) => e.key == key);
      if (index == -1) continue;
      final current = nodes[index];
      final origin = _selectedOrigins[key];
      Offset newOffset = origin! + delta;
      
      // Proactive boundary check before applying the offset
      if (boundaryConstraint != null) {
         newOffset = boundaryConstraint!(current, newOffset);
      }
      
      current.update(offset: newOffset);
      if (_formatter != null) {
        _formatter!(current);
      }
    }
    // Mark synapse position cache dirty so blink positions update after move.
    positionDirty = true;
    // Use frame-rate-throttled notify so that 250 Hz+ pointer events don't
    // trigger 250+ setState() rebuilds per second. Coalesces to one per frame.
    _scheduleNotify();
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


  
  // V25: Clear multi-selection when deselecting all
  void deselectAll([bool hover = false]) {
    if (hover) {
      // _hovered.clear();
      if (_hovered.isNotEmpty) _hovered.clear();
    } else {
      // _selected.clear();
      // _selectedOrigins.clear();
      if (_selected.isNotEmpty) _selected.clear();
      if (_selectedOrigins.isNotEmpty) _selectedOrigins.clear();
      isSelectingEdge = false;
      edgeSelected = null;
      multiEdgeSelection.clear();
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
    syntheticConnectionsDirty = true; // force edge_renderer rebuild on next paint
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

    syntheticConnections.add(Connection(
        axonFrom,
        axonTo,
        25.0,
        Path(),
        nodeFrom
            .isExcitatory)); // print("Add Synthetic Connection ${syntheticConnections.length}");
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
      if (neurons[toIdx].isOutput && neuronTo.dendrites.isNotEmpty) {
        Sinapse newSinapse = Sinapse(
          presinapticNeuronIndex: fromIdx,
          sinapticValue: connectionStrength,
        );
        if (neurons[fromIdx].node.isExcitatory == 1) {
          neuronTo.dendrites[0].sinapseSecondLevel.add(newSinapse);
        } else {
          neuronTo.dendrites[0].sinapseFirstLevel.add(newSinapse);
        }
        return;
      }
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
      
      // V25 FEATURE: Output Dendrite Preservation
      // Output neurons only have one rigidly computed dendrite tree. We do not want to 
      // replace it with a stale raw copy (which might have wrong angles from setup). 
      // Instead, we just wipe its synapse state so it can be cleanly rebuilt.
      if (syntheticNeuron.isOutput) {
          if (syntheticNeuron.dendrites.isNotEmpty) {
              for (var d in syntheticNeuron.dendrites) {
                  d.sinapseFirstLevel.clear();
                  d.sinapseSecondLevel.clear();
              }
          }
      } else if (rawSyntheticNeuron.dendrites.isNotEmpty) {
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
          if (neurons[toIdx].isOutput) {
            if (neurons[toIdx].isOutput && neurons[toIdx].dendrites.isNotEmpty) {
              Sinapse newSinapse = Sinapse(
                presinapticNeuronIndex: fromIdx,
                sinapticValue: con.connectionStrength,
              );
              if (neurons[fromIdx].node.isExcitatory == 1) {
                neurons[toIdx].dendrites[0].sinapseSecondLevel.add(newSinapse);
              } else {
                neurons[toIdx].dendrites[0].sinapseFirstLevel.add(newSinapse);
              }
              continue;
            }
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
