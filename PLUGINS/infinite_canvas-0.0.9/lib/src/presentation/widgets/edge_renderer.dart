import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:infinite_canvas/infinite_canvas.dart';
import 'package:infinite_canvas/src/domain/model/SyntheticEdge.dart';
import 'package:infinite_canvas/src/domain/model/SyntheticNeuron.dart';

import '../../domain/model/edge.dart';
import 'package:infinite_canvas/src/presentation/widgets/nucleus.dart';
import '../state/controller.dart';
import 'inline_painter.dart';

/// A widget that renders all the edges in the [InfiniteCanvas].
class InfiniteCanvasEdgeRenderer extends StatelessWidget {
  double widthClickMask = 15;

  int refreshRetainer = 0;

  InfiniteCanvasEdgeRenderer(
      {super.key,
      required this.controller,
      required this.edges,
      this.linkStart,
      this.linkEnd,
      this.linkIsExcitatory = true,
      this.straightLines = false});

  final InfiniteCanvasController controller;
  final List<InfiniteCanvasEdge> edges;
  final Offset? linkStart, linkEnd;
  final bool linkIsExcitatory; // Determines triangle (true) or circle (false) for drag preview
  final bool straightLines;

  final double arrowSize = 15.0;
  final double arrowMultiplier = 1.0;
  final arrowAngle = 25 * pi / 180;

  // NEW NEURON DRAWING
  Paint blackBrush = Paint()
    ..color = Colors.black
    ..style = PaintingStyle.fill
    ..strokeWidth = 2;
  Paint graykBrush = Paint()
    ..color = Colors.grey
    ..style = PaintingStyle.fill
    ..strokeWidth = 2;
  Paint whiteBrush = Paint()
    ..color = Colors.white
    ..style = PaintingStyle.fill
    ..strokeWidth = 2;

  Paint greenBrush = Paint()
    ..color = Colors.green
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;
  Paint yellowBrush = Paint()
    // ..color = Colors.yellow
    ..color = const Color(0XFFFD8164)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1;
    
  // V23: Orange highlight for 3-pass organic axon rendering
  Paint orangeHighlightBrush = Paint()
    ..color = const Color(0xFFFD8164)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 8
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final Paint foundEdgeBrush = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final Paint selectedEdgeBrush = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    return CustomPaint(
      painter: InlinePainter(
        brush: Paint()
          ..color = colors.outlineVariant
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
        builder: (brush, canvas, rect) {
          // List<InfiniteCanvasEdge> reciprocateList = [];
          // controller.syntheticConnections.clear();
          // in Stan code it create connections and then draw the neuron
          // V25: Reset blackBrush color at start of frame to prevent pollution
          blackBrush.color = Colors.black;

          if (refreshRetainer == 0) {
            controller.syntheticConnections.clear();
            // int start = DateTime.now().millisecondsSinceEpoch;
            for (InfiniteCanvasEdge edge in controller.edges) {
              addSyntheticConnection(
                  edge.from, edge.to, edge.connectionStrength);
            }
            // int end = DateTime.now().millisecondsSinceEpoch;
            // print("end - start");
            // print(end - start);
            // print("refresh build");
          }
          refreshRetainer++;
          refreshRetainer %= 120;

          // V23: COMPLETE REWRITE - Proper tree-based trunk system
          // Phase 1: Build tree structure with bottom-up thickness calculation
          // Phase 2: Draw trunks with correct thickness and G1 continuity
          // USING VECTORS NOT ANGLES to eliminate trig conversion errors
          
          // Store direction as VECTOR (Offset), not angle
          // V23: Direct Draw Refactor - eliminate branchPoints map
          // Store edges we have already drawn as part of a trunk using KEYS to avoid identity issues
          Set<String> drawnEdgeKeys = {};
          
          // V24: Clear trunk mapping before rebuild
          controller.trunkToEdgesMap.clear();
          // V25: Axon bounds caching - removed controller.axonPathMap.clear() to support geometry caching
          
          // V25: Clean up stale edgeBranchPointMap entries for edges that no longer exist
          // This fixes the issue where highlights follow old paths after connection deletion
          Set<String> validEdgeKeys = {};
          for (final edge in edges) {
            validEdgeKeys.add("${edge.from}->${edge.to}");
          }
          controller.edgeBranchPointMap.removeWhere((key, value) => !validEdgeKeys.contains(key));
          
          // V25: Track edge counts per source to detect when trunk vs direct path changes
          // If count changed since last frame, clear all cache entries for that source
          Map<LocalKey, int> currentEdgeCounts = {};
          for (final edge in edges) {
            currentEdgeCounts[edge.from] = (currentEdgeCounts[edge.from] ?? 0) + 1;
          }
          // Clear cache for any source whose edge count changed (path type may have changed)
          for (var sourceKey in currentEdgeCounts.keys) {
            int currentCount = currentEdgeCounts[sourceKey]!;
            int? previousCount = controller.sourcePreviousEdgeCount[sourceKey];
            if (previousCount != null && previousCount != currentCount) {
              // Edge count changed - clear all cache entries for this source
              controller.edgeBranchPointMap.removeWhere((key, value) => key.startsWith("$sourceKey->"));
              controller.axonPathMap.removeWhere((key, value) => key.startsWith("${sourceKey}_"));
              controller.axonPathHashes.removeWhere((key, value) => key.startsWith("${sourceKey}_"));
              
              // We can't cleanly regex edge->target on arbitrary text labels, so we flush the painter cache entirely
              // when structural counts change to guarantee no ghost labels. It will organically rebuild next frame.
              controller.textPainterCache.clear();
            }
          }
          controller.sourcePreviousEdgeCount = currentEdgeCounts;
          
          // V25: Clean up stale axonPathMap entries for completely deleted edges
          controller.axonPathMap.removeWhere((key, value) => !key.contains("_trunk_") && !validEdgeKeys.contains(key.replaceFirst("_", "->")));
          controller.axonPathHashes.removeWhere((key, value) => !key.contains("_trunk_") && !validEdgeKeys.contains(key.replaceFirst("_", "->")));
          
          // V25: Create outputGroups early so pre-compute pass can use it
          Map<LocalKey, List<InfiniteCanvasEdge>> outputGroups = {};
          for (final edge in edges) {
            if (!outputGroups.containsKey(edge.from)) {
              outputGroups[edge.from] = [];
            }
            outputGroups[edge.from]!.add(edge);
          }
          
          // Pre-compute pass removed (merged into main loop)
          
          // Phase 0: Draw neuron highlight circles for selected neurons (bottom-most layer)
          if (!controller.isPlaying && controller.selection.isNotEmpty) {
            for (var node in controller.selection) {
              try {
                // Only draw highlight for actual neurons (not sensors)
                if (node.value != -1 && node.isSensory == 0) {
                  final paint = Paint()
                    ..color = const Color(0xFFFD8164)
                    ..style = PaintingStyle.fill;
                  // Draw circle at node center with radius larger than neuron
                  canvas.drawCircle(
                    node.offset + Offset(node.size.width/2, node.size.height/2),
                    node.size.width/2 * 2.0 + 3.0, // V25: +3 radius for border effect
                    paint);
                }
              } catch (e) {
                // Node not found or error
              }
            }
          }
          
          // Legacy highlight passes removed (lines 273-317)
          
          // outputGroups already populated earlier for pre-compute pass
          
          // V25: Update axonAngle for ALL neurons with outputs (1+)
          // xFirstLevel/yFirstLevel are calculated dynamically in recalculate() 
          // using angle + rotationDelta, so they already include rotation
          for (var sourceKey in outputGroups.keys) {
            List<InfiniteCanvasEdge> group = outputGroups[sourceKey]!;
            if (group.isEmpty) continue;
            
            try {
              final sourceNode = controller.nodes.firstWhere((n) => n.key == sourceKey);
              Offset sourceCenter = sourceNode.offset + Offset(sourceNode.size.width/2, sourceNode.size.height/2);
              
              int fromIdx = findSyntheticNeuronIdx(sourceKey.toString(), controller.syntheticNeuronList);
              if (fromIdx < 0 || fromIdx >= controller.syntheticNeuronList.length) continue;
              
              var neuronFrom = controller.syntheticNeuronList[fromIdx].newNeuron;
              
              // Calculate centroid of all downstream targets
              double sumX = 0, sumY = 0;
              int count = 0;
              
              for (var edge in group) {
                final targetNode = controller.nodes.firstWhere((n) => n.key == edge.to);
                Offset targetCenter = targetNode.offset + Offset(targetNode.size.width/2, targetNode.size.height/2);
                sumX += targetCenter.dx;
                sumY += targetCenter.dy;
                count++;
              }
              
              // If dragging from this neuron, include drag position in centroid
              if (controller.linkStart == sourceKey && controller.linkEnd != null) {
                sumX += controller.linkEnd!.dx;
                sumY += controller.linkEnd!.dy;
                count++;
              }
              
              if (count == 0) continue;
              
              // Calculate angle toward centroid
              double centroidX = sumX / count;
              double centroidY = sumY / count;
              double targetAngle = atan2(centroidY - sourceCenter.dy, centroidX - sourceCenter.dx) * 180 / pi;
              
              // Normalize to 0-360
              if (targetAngle < 0) targetAngle += 360;
              
              // V25: Update axonAngle to drive rotation via rotationDelta
              // rotationDelta = axonAngle - baseAxonAngle
              // baseAxonAngle stays FIXED at original dendrite angle
              // axonAngle updates to track downstream centroid
              if (neuronFrom.axonAngle <= -1) {
                // First time - initialize both
                neuronFrom.axonAngle = targetAngle;
                neuronFrom.baseAxonAngle = targetAngle;
              } else {
                // Update axonAngle only - baseAxonAngle stays fixed
                // This changes rotationDelta and rotates the whole neuron
                neuronFrom.axonAngle = targetAngle;
              }
              
              // V25: CRITICAL - Recalculate dendrite positions immediately after updating rotation
              // This ensures xFirstLevel/yFirstLevel include the new rotation before edges are drawn
              controller.syntheticNeuronList[fromIdx].recalculate(null);
            } catch (e) {
              // Node not found
            }
          }
          // V25: Three-pass rendering (Highlights, then Structure, then Synapses)
          // Pass 0: Highlights
          // Pass 1: Structures (black lines, gradients - no synapses)
          // Pass 2: Synapses (triangles, circles, icons)
          for (int renderPass = 0; renderPass < 3; renderPass++) {
            bool isHighlightPass = renderPass == 0;
            bool isDrawingSynapsesOnly = renderPass == 2;
            
            drawnEdgeKeys.clear(); // Reset handled edges for this pass
            
          // Process each source neuron with 2+ outputs (for trunk drawing)
          for (var sourceKey in outputGroups.keys) {
            List<InfiniteCanvasEdge> group = outputGroups[sourceKey]!;
            if (group.length < 2) continue;
            
            // V25Fix: Mark ALL edges in this group as drawn to prevent "Ghost Axons" (double drawing) in fallback loop
            // The trunk builder handles them; the straight-line fallback loop must ignore them.
            for (var e in group) {
              drawnEdgeKeys.add("${e.from}->${e.to}");
            }
            
            try {
              final sourceNode = controller.nodes.firstWhere((n) => n.key == sourceKey);
              Offset sourceCenter = sourceNode.offset + Offset(sourceNode.size.width/2, sourceNode.size.height/2);
              
              // Get axon thicknesses for each edge (use connection strength)
              Map<InfiniteCanvasEdge, double> edgeThickness = {};
              for (var edge in group) {
                // Axon thickness matched to drawAxon logic:
                double strengthVal = edge.connectionStrength / 2.0;

                // V23: MATCH drawAxon EXACTLY
                int fromIdx = findSyntheticNeuronIdx(sourceNode.key.toString(), controller.syntheticNeuronList);
                double visualRadius = 20.0; // Fallback
                if (fromIdx >= 0 && fromIdx < controller.syntheticNeuronList.length) {
                   visualRadius = controller.syntheticNeuronList[fromIdx].circleRadius;
                }
                
                double maxAbsoluteConnectionStrength = 110 - strengthVal.floor().abs().toDouble(); 
                if (maxAbsoluteConnectionStrength <= 0) maxAbsoluteConnectionStrength = 1;

                // V23: User demanded multiplication by 2.0 for trunk thickness
                double thickness = ((strengthVal.abs() / maxAbsoluteConnectionStrength) * visualRadius / 2) * 2.0;
                
                if ((visualRadius * 0.1) > thickness) thickness = visualRadius * 0.1;
                if (thickness < 1.0) thickness = 1.0;
                
                edgeThickness[edge] = thickness;
              }
              
              // Build list of targets with edges
              List<MapEntry<Offset, InfiniteCanvasEdge>> targetsWithEdges = [];
              for (var edge in group) {
                final targetNode = controller.nodes.firstWhere((n) => n.key == edge.to);
                Offset pos = targetNode.offset + Offset(targetNode.size.width/2, targetNode.size.height/2);
                targetsWithEdges.add(MapEntry(pos, edge));
              }
              
              // Calculate Centroid (Moved up for sorting)
              double cX = 0, cY = 0;
              for (var entry in targetsWithEdges) {
                cX += entry.key.dx;
                cY += entry.key.dy;
              }
              Offset globalCentroid = Offset(cX / targetsWithEdges.length, cY / targetsWithEdges.length);
              
              // SORT ALGORITHM: Projected Distance
              // Sort by distance projected onto the main flow vector (Source -> Centroid).
              // This ensures axons peel off in "sequence" along the path, avoiding zig-zags.
              Offset flowVec = (globalCentroid - sourceCenter);
              if (flowVec.distance > 0.1) {
                  Offset flowDir = flowVec / flowVec.distance;
                  targetsWithEdges.sort((a, b) {
                      double projA = (a.key - sourceCenter).dx * flowDir.dx + (a.key - sourceCenter).dy * flowDir.dy;
                      double projB = (b.key - sourceCenter).dx * flowDir.dx + (b.key - sourceCenter).dy * flowDir.dy;
                      return projA.compareTo(projB);
                  });
              } else {
                  // Fallback to strict distance if no clear flow
                  targetsWithEdges.sort((a, b) => 
                     (a.key - sourceCenter).distanceSquared.compareTo((b.key - sourceCenter).distanceSquared));
              }

              // PHASE 1: Calculate thickness bottom-up
              // We need to know exact thickness of every axon first
              List<double> segmentThicknesses = [];
              double currentTrunkThickness = 0;
              
              // Compute thicknesses from leaves up
              // Last segment feeds 2 axons: last one and second to last
              // Iterate backwards to build trunk thickness
              for (int i = targetsWithEdges.length - 1; i >= 0; i--) {
                double axonThickness = edgeThickness[targetsWithEdges[i].value] ?? 2.0;
                
                if (i == targetsWithEdges.length - 1) {
                   // Bottom of tree - just the last axon
                   currentTrunkThickness = axonThickness;
                } else {
                   // This trunk segment carries the current axon PLUS everything below
                   // Reverting to strict MAX as per user request
                   currentTrunkThickness = max(axonThickness, currentTrunkThickness);
                }
                if (i < targetsWithEdges.length - 1) {
                  segmentThicknesses.insert(0, currentTrunkThickness);
                }
              }
              
              // PHASE 2: Draw SINGLE ARC trunk
              Offset currentStart = sourceCenter;
              
              // (Centroid calculation moved up)
              
              // V25: Update neuronFrom.axonAngle to point toward centroid
              
              // V25: Update neuronFrom.axonAngle to point toward centroid
              // Include drag position if we're actively dragging a new link from this neuron
              int fromIdx = findSyntheticNeuronIdx(sourceKey.toString(), controller.syntheticNeuronList);
              if (fromIdx >= 0 && fromIdx < controller.syntheticNeuronList.length) {
                var neuronFrom = controller.syntheticNeuronList[fromIdx].newNeuron;
                
                // Calculate target angle toward centroid
                double targetAngle;
                
                // Check if we're dragging from this neuron - if so, include drag position in centroid
                if (controller.linkStart == sourceKey && controller.linkEnd != null) {
                  // Include linkEnd position in the centroid calculation
                  double dragCX = (cX + controller.linkEnd!.dx) / (targetsWithEdges.length + 1);
                  double dragCY = (cY + controller.linkEnd!.dy) / (targetsWithEdges.length + 1);
                  targetAngle = atan2(dragCY - sourceCenter.dy, dragCX - sourceCenter.dx) * 180 / pi;
                } else {
                  targetAngle = atan2(globalCentroid.dy - sourceCenter.dy, globalCentroid.dx - sourceCenter.dx) * 180 / pi;
                }
                
                // Normalize to 0-360
                if (targetAngle < 0) targetAngle += 360;
                
                // V25: Update axonAngle to drive rotation via rotationDelta
                // baseAxonAngle stays FIXED at original dendrite angle
                if (neuronFrom.axonAngle <= -1) {
                  neuronFrom.axonAngle = targetAngle;
                  neuronFrom.baseAxonAngle = targetAngle;
                } else {
                  neuronFrom.axonAngle = targetAngle;
                }
              }
              
              // Trunk length: Based on segment count constraints (User Request)
              // Each segment must be between 25px and 60px long.
              int totalSegments = max(1, targetsWithEdges.length - 1);
              double minTrunkLen = totalSegments * 25.0;
              double maxTrunkLen = totalSegments * 60.0;
              
              double distanceToCentroid = (globalCentroid - sourceCenter).distance;
              double distanceToFirstTarget = (targetsWithEdges.first.key - sourceCenter).distance;
              double closerDistance = min(distanceToCentroid, distanceToFirstTarget);
              
              // Base calculation (51% distance), clamped by segment requirements
              double trunkLength = min(closerDistance * 0.51, maxTrunkLen);
              trunkLength = max(trunkLength, minTrunkLen);
              
              // V25: SNAKE TRUNK LOGIC (Iterative Segments)
              // User Request: Segments curve independently towards their targets.

              // V25: Store SORTED edges in trunkToEdgesMap (Fixes Highlight Mismatch)
              List<InfiniteCanvasEdge> sortedEdges = targetsWithEdges.map((e) => e.value).toList();
              controller.trunkToEdgesMap["${sourceNode.key}_trunk"] = sortedEdges;
              
              // Helper to check highlight
              bool shouldHighlightSegment(int segmentIndex) {
                 if (!controller.isSelectingEdge) return false;
                 for (int k = segmentIndex; k < sortedEdges.length; k++) {
                     InfiniteCanvasEdge edge = sortedEdges[k];
                     if (controller.multiEdgeSelection.contains(edge)) return true;
                     if (controller.edgeSelected == edge) return true;
                 }
                 return false;
              }
              
              // 1. Setup Iteration State
              Offset currentPos = currentStart;
              
              Offset direction = (globalCentroid - sourceCenter);
              if (direction.distance > 0) direction = direction / direction.distance;

              // Initial direction: Towards global centroid (or driven by source axon angle if set?)
              // Re-use 'direction' calculated above which points to global centroid.
              Offset currentTangent = direction;

              int totalSegmentsSnake = max(1, sortedEdges.length - 1);
              
              // 2. Iterate Segments
              for (int i = 0; i < totalSegmentsSnake; i++) {
                 // A. Determine Target Cluster for THIS segment
                 // This segment supports edges 'i' through 'end'.
                 // We want to aim towards the centroid of these remaining targets.
                 Offset clusterSum = Offset.zero;
                 int count = 0;
                 for (int j = i; j < targetsWithEdges.length; j++) {
                     clusterSum += targetsWithEdges[j].key;
                     count++;
                 }
                 Offset segmentTargetCentroid = count > 0 ? clusterSum / count.toDouble() : globalCentroid;
                 
                 // B. Calculate Dynamic Segment Length
                 Offset toCentroid = segmentTargetCentroid - currentPos;
                 double distToCentroid = toCentroid.distance;
                 
                 // Default length logic (clamp 15-30)
                 double desiredLen = min(distToCentroid * 0.35, 30.0);
                 desiredLen = max(desiredLen, 15.0);
                 
                 // Constraint: First segment larger (User Request)
                 if (i == 0) {
                     desiredLen = max(30.0, desiredLen * 1.2);
                     desiredLen = min(desiredLen, 60.0); // Cap it
                 }
                 
                 // C. Calculate Curve Geometry (Snake Segment)
                 // p0 = currentPos
                 // p1 = p0 + currentTangent * (len * 0.5)  (Project forward from previous)
                 // p2 = ?
                 
                 // Target direction for this segment
                 Offset targetDir = toCentroid;
                 if (targetDir.distance > 0) targetDir = targetDir / targetDir.distance;
                 
                 // Bias the target direction slightly by the CURRENT tangent (Momentum)
                 // This restoration of mixing (30% momentum) prevents the "polyline" look.
                 Offset paramSum = (currentTangent * 0.3 + targetDir * 0.7);
                 Offset mixDir = paramSum.distance > 0 ? paramSum / paramSum.distance : targetDir;
                 
                 // Restore handle length (0.45) for flowy ("sine-like") S-curves
                 Offset p0 = currentPos;
                 Offset p1 = p0 + currentTangent * (desiredLen * 0.45);
                 Offset p2 = p0 + mixDir * desiredLen;
                 
                 // Re-calculate p2 to ensure G1 continuity smoothness? 
                 // If p1 is fixed (tangent match), p2 determines the curve.
                 // Just using p2 = p0 + targetDir * len is simple and effective.
                 
                 // Bezier helper for this segment
                 Offset getSegBezier(double t) {
                     double mt = 1 - t;
                     return p0 * mt * mt + p1 * 2 * mt * t + p2 * t * t;
                 }
                 // Tangent helper
                 Offset getSegTangent(double t) {
                     double mt = 1 - t;
                     Offset tan = (p1 - p0) * 2 * mt + (p2 - p1) * 2 * t;
                     return tan.distance > 0 ? tan / tan.distance : currentTangent;
                 }
                 
                 // D. Draw Segment (Subdivide)
                 int subdivisions = 10;
                 // Register Hit Path (index i)
                 Path segmentPath = Path();
                 segmentPath.moveTo(p0.dx, p0.dy);
                 for (int s = 1; s <= subdivisions; s++) {
                     double st = s / subdivisions;
                     Offset sp = getSegBezier(st);
                     segmentPath.lineTo(sp.dx, sp.dy);
                 }
                 
                 if (!isHighlightPass) {
                    int pHash = Object.hash(p0.dx, p0.dy, p1.dx, p1.dy, p2.dx, p2.dy);
                    String pKey = "${sourceNode.key}_trunk_$i";
                    if (controller.axonPathHashes[pKey] != pHash || !controller.axonPathMap.containsKey(pKey)) {
                        controller.axonPathMap[pKey] = getOutlinePath(segmentPath, widthClickMask);
                        controller.axonPathHashes[pKey] = pHash;
                    }
                 }
                 if (isHighlightPass && shouldHighlightSegment(i)) {
                    Paint trunkHighlightPaint = Paint()
                      ..color = const Color(0xFFFD8164)
                      ..style = PaintingStyle.stroke
                      ..strokeWidth = 17.0
                      ..strokeCap = StrokeCap.round;
                    canvas.drawPath(segmentPath, trunkHighlightPaint);
                 }
                 
                 double currentThickness = segmentThicknesses.isNotEmpty && i < segmentThicknesses.length 
                      ? segmentThicknesses[i] : 2.0;

                 if (!isHighlightPass) {
                   Paint segPaint = Paint()
                     ..color = Colors.black
                     ..style = PaintingStyle.stroke
                     ..strokeWidth = currentThickness
                     ..strokeCap = StrokeCap.round;
                   canvas.drawPath(segmentPath, segPaint);
                 }
                 
                 // E. Update State for Next Segment
                 currentPos = p2;
                 currentTangent = getSegTangent(1.0);
                 
                 // F. Draw Branch (If not the final tip-segment)
                 // The 'final' segment (i == totalSegments - 1) is the one that ENDS at the split of the last two axons.
                 // So for i < totalSegments - 1, we branch off sortedEdges[i].
                 // For i == totalSegments - 1, we branch off BOTH of the last two edges at the tip.
                 
                 Offset branchPoint = p2; // Actually branch point is usually p0? 
                 // Wait, original logic branched at the END of the segment? 
                 // "Branch at 'pos' ... (loop uses t=step*(i+1))"
                 // So yes, at the END of segment i, we find Branch Point for axon i.
                 // EXCEPTION: The original logic had 'numBranches' segments. At the end of segment i, it branched taxon i.
                 
                 if (i < totalSegmentsSnake - 1) {
                     // Branch Standard Axon
                     InfiniteCanvasEdge edge = sortedEdges[i];
                     drawnEdgeKeys.add("${edge.from}->${edge.to}");
                     final from = controller.nodes.firstWhere((node) => node.key == edge.from);
                     final to = controller.nodes.firstWhere((node) => node.key == edge.to);
                     String label = edge.label ?? "";
                     bool isEdgeSelected = controller.isEdgeInSelection(edge);
                     double connectionStrength = edge.connectionStrength / 2.0;
                     int fromIdx = findSyntheticNeuronIdx(edge.from.toString(), controller.syntheticNeuronList);
                     int toIdx = findSyntheticNeuronIdx(edge.to.toString(), controller.syntheticNeuronList);
                     
                     controller.edgeBranchPointMap["${edge.from}->${edge.to}"] = [branchPoint, currentTangent];
                     
                     drawAxon(from, to, fromIdx, toIdx, connectionStrength, canvas, from.isExcitatory, label, InfiniteCanvasEdge.isShowingInfo,
                        isSelected: isEdgeSelected, isHighlightPass: isHighlightPass, branchPoint: branchPoint, branchDirection: currentTangent, isDrawingSynapsesOnly: isDrawingSynapsesOnly, edgeColor: edge.color);
                        
                 } else {
                     // Final Tip (Split last two axons)
                     // Edges 'totalSegments - 1' AND 'totalSegments' (Wait, index mismatch?)
                     // If 6 edges. totalSegments=5. Indices 0..5.
                     // i=0..3: branch edges 0..3.
                     // i=4 (last): branch edges 4 AND 5.
                     
                     List<int> lastIndices = [];
                     if (sortedEdges.length > i) lastIndices.add(i);
                     if (sortedEdges.length > i+1) lastIndices.add(i+1);
                     
                     for (int edgeIdx in lastIndices) {
                         InfiniteCanvasEdge edge = sortedEdges[edgeIdx];
                         drawnEdgeKeys.add("${edge.from}->${edge.to}");
                         final from = controller.nodes.firstWhere((node) => node.key == edge.from);
                         final to = controller.nodes.firstWhere((node) => node.key == edge.to);
                         String label = edge.label ?? "";
                         bool isEdgeSelected = controller.isEdgeInSelection(edge);
                         double connectionStrength = edge.connectionStrength / 2.0;
                         int fromIdx = findSyntheticNeuronIdx(edge.from.toString(), controller.syntheticNeuronList);
                         int toIdx = findSyntheticNeuronIdx(edge.to.toString(), controller.syntheticNeuronList);
                         
                         controller.edgeBranchPointMap["${edge.from}->${edge.to}"] = [branchPoint, currentTangent];
                         
                         drawAxon(from, to, fromIdx, toIdx, connectionStrength, canvas, from.isExcitatory, label, InfiniteCanvasEdge.isShowingInfo,
                            isSelected: controller.isEdgeInSelection(edge), isHighlightPass: isHighlightPass, branchPoint: branchPoint, branchDirection: currentTangent, isDrawingSynapsesOnly: isDrawingSynapsesOnly, edgeColor: edge.color);
                     }
                 }
              }
            } catch (e) {
            }
          } // RESTORED CLOSURE: Closes 'outputGroups' loop. Fallback loop follows.


          for (final edge in edges) {
            try {
              final from =
                  controller.nodes.firstWhere((node) => node.key == edge.from);
              final to =
                  controller.nodes.firstWhere((node) => node.key == edge.to);
            final label = edge.label ?? "";

            Paint curBrush = brush;
            if (controller.isSelectingEdge && controller.edgeSelected == edge) {
              curBrush = selectedEdgeBrush;
              // V23: Removed square hit area highlight
              // drawHitArea(canvas, edge);
            } else if (controller.isFoundEdge && controller.edgeFound == edge) {
              curBrush = foundEdgeBrush;
            } else {}

            double pairSpace = edge.isReciprocate * 7;
            int fromIdx = findSyntheticNeuronIdx(
                edge.from.toString(), controller.syntheticNeuronList);
            int toIdx = findSyntheticNeuronIdx(
                edge.to.toString(), controller.syntheticNeuronList);

            double connectionStrength = edge.connectionStrength / 2.0;

            // V25: Do NOT modify blackBrush color here. It is shared and must remain black.
            // drawAxon handles colors internally via gradients.
            // if (edge.color != null) {
            //   blackBrush.color = edge.color!;
            // } else {
            //   blackBrush.color = Colors.black;
            // }
            
            // V23: Pass selection state for conditional orange highlight
            bool isEdgeSelected = controller.isEdgeInSelection(edge); // V25: Helper

            // V23: Check if already drawn by trunk builder
            // Use String Key for robust check
            String checkKey = "${edge.from}->${edge.to}";
            if (drawnEdgeKeys.contains(checkKey)) continue;

            // V25Fix: ROBUST GHOST AXON CHECK
            // If this edge belongs to a generic output group with >= 2 edges, it IS a trunk.
            // It should have been handled by the trunk builder. Skip it here to prevent double drawing.
            if (outputGroups.containsKey(edge.from) && outputGroups[edge.from]!.length >= 2) {
              continue; 
            }
            
            Offset? branchPoint = null;
            Offset? branchDirection = null;


            drawAxon(from, to, fromIdx, toIdx, connectionStrength, canvas,
                from.isExcitatory, label, InfiniteCanvasEdge.isShowingInfo, 
                isSelected: isEdgeSelected, isHighlightPass: isHighlightPass, branchPoint: branchPoint, branchDirection: branchDirection, isDrawingSynapsesOnly: isDrawingSynapsesOnly, edgeColor: edge.color);
            // }
            // drawEdge(
            //   context,
            //   canvas,
            //   // IS RECIPROCATE
            //   // from.rect.center,
            //   // to.rect.center,
            //   Offset(from.rect.center.dx + pairSpace,
            //       from.rect.center.dy + pairSpace),
            //   Offset(
            //       to.rect.center.dx + pairSpace, to.rect.center.dy + pairSpace),
            //   curBrush,
            //   label: edge.label,
            // );
            } catch (e) {}
          }
          
          // V25 FEATURE: Manually paint dendrites for Output nodes
          // Output nodes (motors, speakers, LEDs) use a transparent Container as their node child,
          // so Flutter never calls their CustomPainter's paint() method.
          // To make their dendrites visible, we manually trigger recalculate(canvas) here 
          // on the background layer, above edges but below nodes.
          if (!isHighlightPass) {
             for (int i = 0; i < controller.syntheticNeuronList.length; i++) {
                if (controller.syntheticNeuronList[i].isOutput) {
                   InfiniteCanvasNode? activeNode = null;
                   try {
                     activeNode = controller.nodes.firstWhere((n) => n.key == controller.syntheticNeuronList[i].node.key);
                   } catch (e) {}
                   
                   if (activeNode != null && (activeNode.offset.dx != 0.0 || activeNode.offset.dy != 0.0)) {
                       canvas.save();
                       canvas.translate(activeNode.offset.dx, activeNode.offset.dy);
                       controller.syntheticNeuronList[i].recalculate(canvas);
                       canvas.restore();
                   }
                }
             }
          }
          
            } // End of Three-Pass Loop
        },
      ),
      foregroundPainter: InlinePainter(
        brush: Paint()
          // ..color = colors.primary
          ..color = const Color(0XFFFD8164)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
        builder: (brush, canvas, child) {
          if (linkStart != null && linkEnd != null) {
            drawEdge(
              context,
              canvas,
              linkStart!,
              controller.toLocal(linkEnd!),
              brush,
            );
          }
        },
      ),
    );
  }

  void drawEdge(
    BuildContext context,
    Canvas canvas,
    Offset fromOffset,
    Offset toOffset,
    Paint brush, {
    String? label,
  }) {
    final colors = Theme.of(context).colorScheme;
    
    // V25: Orange highlight paint (drawn first, behind)
    final orangeHighlight = Paint()
      ..color = const Color(0xFFFD8164)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    
    // Black stroke paint (on top)
    final blackStroke = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    
    // Draw line from fromOffset to toOffset
    final path = Path();
    path.moveTo(fromOffset.dx, fromOffset.dy);

    if (straightLines) {
      path.lineTo(toOffset.dx, toOffset.dy);
    } else {
      path.lineTo(toOffset.dx, toOffset.dy);
    }
    
    // V25: Draw order: orange highlight (behind) -> black stroke (on top)
    canvas.drawPath(path, orangeHighlight);
    canvas.drawPath(path, blackStroke);
    
    // V25: Draw styled synapse arrow (triangle/circle based on excitatory/inhibitory)
    if (!straightLines) {
      drawArrow(context, canvas, fromOffset, toOffset, brush, path);
    }
    
    if (label != null) {
      // V25: TextPainter Cache Optimization
      String cacheKey = "straight_label_${label}";
      TextPainter? textPainter = controller.textPainterCache[cacheKey];
      
      if (textPainter == null) {
          textPainter = TextPainter(
            text: TextSpan(
              text: label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colors.onSurface,
                shadows: [
                  Shadow(
                    offset: const Offset(0.8, 0.8),
                    blurRadius: 3,
                    color: colors.surface,
                  ),
                ],
              ),
            ),
            textDirection: TextDirection.ltr,
          )..layout();
          controller.textPainterCache[cacheKey] = textPainter;
      }
      
      // Render label on line
      Offset textOffset = Offset(
        (fromOffset.dx + toOffset.dx) / 2,
        (fromOffset.dy + toOffset.dy) / 2,
      );
      // Center on curve, if used
      // V25 Optimization: computeMetrics is O(N) but required for curved generic paths
      // This straight-line block is a fallback, but we keep it safe
      final pathMetrics = path.computeMetrics();
      if (pathMetrics.isNotEmpty) {
          final pathMetric = pathMetrics.first;
          final pathLength = pathMetric.length;
          final middle = pathMetric.getTangentForOffset(pathLength / 2);
          textOffset = middle?.position ?? textOffset;
      }
      
      // Offset to top left
      textOffset = textOffset.translate(
        -textPainter.width / 2,
        -textPainter.height / 2,
      );
      textPainter.paint(canvas, textOffset);
    }
  }

  void drawArrow(
    BuildContext context,
    Canvas canvas,
    Offset fromOffset,
    Offset rawToOffset,
    Paint rawBrush,
    Path line,
  ) {
    // V25: Orange highlight (drawn first, behind)
    final orangeHighlight = Paint()
      ..color = const Color(0xFFFD8164)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    
    // Black stroke for outline
    final blackStroke = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    
    // White fill
    final whiteFill = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    try {
      ui.PathMetric pathMetric = line.computeMetrics().first;
      Path extractPath = pathMetric.extractPath(0.0, pathMetric.length - 10);
      var metric = extractPath.computeMetrics().first;
      final offsetMetricPos =
          metric.getTangentForOffset(metric.length)!.position;
      Offset toOffset = offsetMetricPos;

      final dX = toOffset.dx - fromOffset.dx;
      final dY = toOffset.dy - fromOffset.dy;
      final angle = atan2(dY, dX);

      if (linkIsExcitatory) {
        // V25: Draw TRIANGLE - tip points TOWARD the line (toward fromOffset), base away
        // This matches real synapse triangles that "receive" from the axon
        final triangleSize = 12.0;
        
        // Tip points TOWARD fromOffset (opposite of travel direction)
        final tipX = toOffset.dx - triangleSize * 0.8 * cos(angle);
        final tipY = toOffset.dy - triangleSize * 0.8 * sin(angle);
        
        // Base corners spread perpendicular, positioned ahead of toOffset
        final baseX1 = toOffset.dx + triangleSize * 0.5 * cos(angle) + triangleSize * 0.6 * cos(angle + pi/2);
        final baseY1 = toOffset.dy + triangleSize * 0.5 * sin(angle) + triangleSize * 0.6 * sin(angle + pi/2);
        final baseX2 = toOffset.dx + triangleSize * 0.5 * cos(angle) + triangleSize * 0.6 * cos(angle - pi/2);
        final baseY2 = toOffset.dy + triangleSize * 0.5 * sin(angle) + triangleSize * 0.6 * sin(angle - pi/2);
        
        Path arrowPath = Path();
        arrowPath.moveTo(tipX, tipY);
        arrowPath.lineTo(baseX1, baseY1);
        arrowPath.lineTo(baseX2, baseY2);
        arrowPath.close();
        
        // Draw order: orange highlight (behind) -> white fill -> black stroke (on top)
        canvas.drawPath(arrowPath, orangeHighlight);
        canvas.drawPath(arrowPath, whiteFill);
        canvas.drawPath(arrowPath, blackStroke);
      } else {
        // V25: Draw CIRCLE for inhibitory
        final circleRadius = 8.0;
        
        // Draw order: orange highlight (behind) -> white fill -> black stroke (on top)
        canvas.drawCircle(toOffset, circleRadius + 1.5, orangeHighlight);
        canvas.drawCircle(toOffset, circleRadius, whiteFill);
        canvas.drawCircle(toOffset, circleRadius, blackStroke);
      }
    } catch (err) {
      print("err edge renderer");
      print(err);
      return;
    }
  }

  void drawHitArea(
      // BuildContext context,
      Canvas canvas,
      InfiniteCanvasEdge edge) {
    const lineWidth = 7;
    int radius = 10;

    var eFrom = controller.nodes.where((e) => edge.from == (e.key)).toList()[0];
    var eTo = controller.nodes.where((e) => edge.to == (e.key)).toList()[0];

    String pathKey = "${eFrom.key.toString()}_${eTo.key.toString()}";
    if (controller.axonPathMap.containsKey(pathKey)) {
      canvas.drawPath(controller.axonPathMap[pathKey]!, yellowBrush);
    }
    return;

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

    // print("OFFSET DRAW");
    // print(eFrom.value);
    // print(eTo.value);
    // print(eFrom.offset);
    // print(eTo.offset);
    // print(iFrom);
    // print(oFrom);
    // print(iTo);
    // print(oTo);

    p.close();
    Paint paint = Paint()
      ..color = Colors.yellow
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawPath(p, paint);
  }

  void drawNeuralAxon(InfiniteCanvasNode from, InfiniteCanvasNode to,
      int fromIdx, int toIdx, double connectionStrength, Canvas canvas) {
    List<SyntheticNeuron> neurons = controller.syntheticNeuronList;
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
    
    // V25 REVERTED: Rotation disabled - use original positions
    //find dendrite (on posinaptic neuron ) that is pointing toward center of connections of presinaptic neuron
    for (int dendriteIndex = 0;
        dendriteIndex < neuronFrom.dendrites.length;
        dendriteIndex++) {
      double distance = euclideanDistance(
          neuronFrom.xCenterOfConnections,
          neuronFrom.yCenterOfConnections,
          neuronTo.dendrites[dendriteIndex].xFirstLevel,
          neuronTo.dendrites[dendriteIndex].yFirstLevel);
      distancesToSinapses.add(SinapsePoint(
          dendriteIndex: dendriteIndex,
          distance: distance,
          isFirstLevel: true));
      if (neuronTo.dendrites[dendriteIndex].hasSecondLevel) {
        distance = euclideanDistance(
            neuronFrom.xCenterOfConnections,
            neuronFrom.yCenterOfConnections,
            neuronTo.dendrites[dendriteIndex].xSecondLevel,
            neuronTo.dendrites[dendriteIndex].ySecondLevel);
        distancesToSinapses.add(SinapsePoint(
            dendriteIndex: dendriteIndex,
            distance: distance,
            isFirstLevel: false));
      }
    }
    distancesToSinapses.sort((a, b) => a.distance.compareTo(b.distance));
    // for (var sinapse in distancesToSinapses) {
    //   print("distancesToSinapses");
    //   print(
    //       "${sinapse.dendriteIndex} : ${sinapse.distance} ${sinapse.isFirstLevel}");
    // }
    //distancesToSinapses = distancesToSinapses.reversed.toList();

    bool foundPlace = false;
    
    // V25 FEATURE: Structured Output Dendrites - Enforce strict Left (Inhibitory) / Right (Excitatory) attachment points.
    if (neurons[toIdx].isOutput && neuronTo.dendrites.isNotEmpty) {
      if (from.isExcitatory == 1) {
        // Excitatory -> Right side (Second Level)
        Sinapse newSinapse = Sinapse(
          presinapticNeuronIndex: fromIdx,
          sinapticValue: connectionStrength,
        );
        // Fix: Output dendrites can absorb infinite synapses visually overlapping. 
        // We do not check for .isEmpty, we just push it allowing them to stack.
        neuronTo.dendrites[0].sinapseSecondLevel.add(newSinapse);
        foundPlace = true;
      } else {
        // Inhibitory -> Left side (First Level)
        Sinapse newSinapse = Sinapse(
          presinapticNeuronIndex: fromIdx,
          sinapticValue: connectionStrength,
        );
        neuronTo.dendrites[0].sinapseFirstLevel.add(newSinapse);
        foundPlace = true;
      }
    } else {
      for (int disin = 0; disin < distancesToSinapses.length; disin++) {
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
    }

    if (!foundPlace) {
      Sinapse newSinapse = Sinapse(
        presinapticNeuronIndex: fromIdx,
        sinapticValue: connectionStrength,
      );
      neuronTo.dendrites[distancesToSinapses[0].dendriteIndex].sinapseFirstLevel
          .add(newSinapse);
    }
    drawAxon(from, to, fromIdx, toIdx, connectionStrength, canvas,
        from.isExcitatory, "", InfiniteCanvasEdge.isShowingInfo);
  }

  // V23: Added isSelected, branchPoint, branchDirection for trunk-to-axon continuity
  // V24: Added isHighlightPass for two-pass rendering (highlights below main drawing)
  void drawAxon(InfiniteCanvasNode from, InfiniteCanvasNode to, int fromIdx,
      int toIdx, double connectionStrength, Canvas canvas, int isExcitatory, String label, bool isShowingInfo, 
      {bool isSelected = false, bool isHighlightPass = false, Offset? branchPoint, Offset? branchDirection, bool isDrawingSynapsesOnly = false, Color? edgeColor}) {

    // V25: Determine Synapse Fill Color based on Spike State with Decay
    Paint synapseFill = whiteBrush;
    if (controller.isPlaying && controller.nucleusList != null && fromIdx >= 0 && fromIdx < controller.nucleusList!.length) {
       var nucleus = controller.nucleusList![fromIdx];
       int diff = DateTime.now().millisecondsSinceEpoch - nucleus.lastSpikeTime;
       int decayDuration = 750;
       
       if (nucleus.lastSpikeTime > 0 && diff < decayDuration) {
          double t = diff / decayDuration.toDouble();
          t = t.clamp(0.0, 1.0);
          // Curve for nicer fade? Linear is fine. 
          // t=0 (Spike) -> Color. t=1 (End) -> White.
          
          if (isExcitatory == 1) {
             Color c = Color.lerp(const Color(0xFF00FF00), Colors.white, t)!;
             synapseFill = Paint()..color = c ..style = PaintingStyle.fill..strokeWidth=2; 
          } else {
             Color c = Color.lerp(Colors.red, Colors.white, t)!;
             synapseFill = Paint()..color = c ..style = PaintingStyle.fill..strokeWidth=2;
          }
       }
    }
    double initialAxonExtensionSize = 0.5;

    List<SyntheticNeuron> neurons = controller.syntheticNeuronList;
    
    // V25: Safety Guard - Prevent crash if indices are invalid (e.g. stale data after load)
    if (fromIdx < 0 || fromIdx >= neurons.length || toIdx < 0 || toIdx >= neurons.length) {
      if (controller.isPlaying == false) { // Only spam debug in design mode
         print("DEBUG: drawAxon invalid indices: from=$fromIdx, to=$toIdx, listLen=${neurons.length}");
      }
      return; 
    }

    Neuron neuronFrom = neurons[fromIdx].newNeuron;
    Neuron neuronTo = neurons[toIdx].newNeuron;
    double circleRadius = neurons[fromIdx].circleRadius;

    double diameterOfNeuron = neurons[fromIdx].circleRadius;
    int maxAbsoluteConnectionStrength = 110 - connectionStrength.floor().abs();
    double minimalTicknessOfAxon = 1;
    
    // Calculate strength (thickness) early for G1 extension
    // Note: detailed synapse-specific strength adjustment happens in loop, 
    // but we use base connectionStrength for initial segments to ensure continuity
    // V23: User clarified "it was perfect last time".
    // "Last time" was Hybrid Mode: Trunk 2.0x, Axon 1.0x.
    // BUT we bridge the gap by starting the G1 extension at the Trunk's thickness (2.0x).
    double thicknessMultiplier = (branchPoint != null) ? 2.0 : 1.0;
    
    double baseStrength = ((connectionStrength.abs() / maxAbsoluteConnectionStrength) * diameterOfNeuron / 2) * thicknessMultiplier;
    if ((diameterOfNeuron * 0.1) > baseStrength) {
      baseStrength = diameterOfNeuron * 0.1;
    }
    if (baseStrength < minimalTicknessOfAxon) {
      baseStrength = minimalTicknessOfAxon;
    }

    const textStyle = TextStyle(
      color: Colors.black,
      fontSize: 14,
    );

    if (neuronFrom.axonAngle <= -1) return;


    
    // V23: If branchPoint provided, use it as axon start instead of neuron center
    double centerBeginAxon_x;
    double centerBeginAxon_y;
    
    if (branchPoint != null) {
      // V23: SIMPLIFIED GEOMETRY - Start curve directly from branch point.
      // Removed 30px straight line extension to avoid "kinked joint" look.
      centerBeginAxon_x = branchPoint.dx;
      centerBeginAxon_y = branchPoint.dy;
    } else {
      // Fallback: If no branch point (single axon or lookup failed), 
      // Point towards the FIRST dendrite target to avoid 90-degree kinks.
      // We need to find where the target is.
      // We can't know the exact target synapse here easily without looping.
      // But we are ABOUT to loop.
      // Let's defer calculation or pick a default that isn't 90 degrees.
      // Actually, let's use the neuron center. 
      centerBeginAxon_x = neuronFrom.x;
      centerBeginAxon_y = neuronFrom.y;
    }

    // V25: Scale factor for target neuron selection/hover
    // When target is selected (design mode) or hovered (any mode, for pin drag), scale dendrite positions
    bool isTargetSelected = (!controller.isPlaying && controller.isSelected(to.key)) || controller.isHovered(to.key);
    double targetScale = isTargetSelected ? 1.65 : 1.0;

    for (int posin = 0; posin < neuronTo.dendrites.length; posin++) {
      // Loop 1: First Level Synapses
    // DEBUG LOOP 1 ENTRY
      // print("DrawAxon Loop 1: from=${from.label} to=${to.label} posin=$posin 1stLen=${neuronTo.dendrites[posin].sinapseFirstLevel.length}");
    if (neuronTo.dendrites[posin].sinapseFirstLevel.isNotEmpty) {
        for (int sinindex = 0;
            sinindex < neuronTo.dendrites[posin].sinapseFirstLevel.length;
            sinindex++) {
          if (neuronTo.dendrites[posin].sinapseFirstLevel[sinindex]
                  .presinapticNeuronIndex ==
              fromIdx) {
            // V25 REVERTED: Rotation disabled - scale only for selection highlight
            // V25: Output Dendrites map Left to Inhibitory (First Level) and Right to Excitatory (Second Level)
            // The routing logic already successfully placed this synapse in `sinapseFirstLevel`.
            // We just extract the exact X/Y coordinates of `xFirstLevel` to draw the line.
            double xOffset = -circleRadius + neuronTo.dendrites[posin].xFirstLevel;
            double yOffset = -circleRadius + neuronTo.dendrites[posin].yFirstLevel;
            
            double xc = neuronTo.x + xOffset * targetScale;
            double yc = neuronTo.y + yOffset * targetScale;

            var initialPortionOfAxon = initialAxonExtensionSize *
                euclideanDistance(
                    centerBeginAxon_x, centerBeginAxon_y, xc, yc) /
                diameterOfNeuron;

            // V23: For G1 tangent continuity
            double centerEndAxon_x;
            double centerEndAxon_y;
            if (branchDirection != null) {
              double distToTarget = euclideanDistance(centerBeginAxon_x, centerBeginAxon_y, xc, yc);
              double extensionLength = min(max(distToTarget * 0.4, 20.0), 100.0);
              centerEndAxon_x = centerBeginAxon_x + branchDirection.dx * extensionLength;
              centerEndAxon_y = centerBeginAxon_y + branchDirection.dy * extensionLength;
            } else {
              double distToTarget = euclideanDistance(centerBeginAxon_x, centerBeginAxon_y, xc, yc);
              double extensionLength = min(max(distToTarget * 0.3, 20.0), 100.0);
              
              Offset directionToTarget = Offset(xc - centerBeginAxon_x, yc - centerBeginAxon_y);
              if (directionToTarget.distance > 0) directionToTarget = directionToTarget / directionToTarget.distance;
              centerEndAxon_x = centerBeginAxon_x + directionToTarget.dx * extensionLength;
              centerEndAxon_y = centerBeginAxon_y + directionToTarget.dy * extensionLength;
            }
            double strength = ((neuronTo.dendrites[posin]
                            .sinapseFirstLevel[sinindex].sinapticValue)
                        .abs() /
                    maxAbsoluteConnectionStrength) *
                diameterOfNeuron /
                2;
            if ((diameterOfNeuron * 0.1) > strength) {
              strength = diameterOfNeuron * 0.1;
            }
            if (strength < minimalTicknessOfAxon) {
              strength = minimalTicknessOfAxon;
            }

            blackBrush.strokeWidth = strength;
            blackBrush.style = PaintingStyle.fill;

            if (isExcitatory == 1) {
              // Fixed triangle synapse size (from reference)
              double triangleSize = 10.0;
              
              // V25 REVERTED: Rotation disabled - scale only for selection highlight
              // Rely on shifted xc and yc from the top of the loop
              double xcent = xc;
              double ycent = yc;

              // Angle from Neuron Center to Dendrite (Outward)
              double angleOut = atan2(ycent - neuronTo.y, xcent - neuronTo.x);
              
              // V25: Offset stacked synapses so they peek out from behind each other
              double stackOffset = sinindex * 6.0;
              xcent += stackOffset * cos(angleOut);
              ycent += stackOffset * sin(angleOut);
              
              // Tip Position (Faces Axon / Outwards)
              double xt = xcent + triangleSize * cos(angleOut);
              double yt = ycent + triangleSize * sin(angleOut);
              
              // Base Points (Flat against neuron) - Equilateral triangle
              double halfBase = triangleSize / sqrt(3);  // For equilateral triangle
              double xBaseLeft = xcent + halfBase * cos(angleOut - pi/2);
              double yBaseLeft = ycent + halfBase * sin(angleOut - pi/2);
              double xBaseRight = xcent + halfBase * cos(angleOut + pi/2);
              double yBaseRight = ycent + halfBase * sin(angleOut + pi/2);
              
              // Axon connects to TIP (xt, yt)
              
              if (neuronTo.dendrites[posin].hasSecondLevel) {
                //draw axon lines
                blackBrush.strokeWidth = strength;
                blackBrush.style = PaintingStyle.stroke;
                double angle = neuronTo.dendrites[posin].angle;
                double distToSynapse = euclideanDistance(centerBeginAxon_x, centerBeginAxon_y, xt, yt);
                double controlDist = min(distToSynapse * 0.25, 60.0);
                double controlX = xt + controlDist * cosDeg(angle);
                double controlY = yt + controlDist * sinDeg(angle);

                double triangleCenterX = (xt + xBaseLeft + xBaseRight) / 3;
                double triangleCenterY = (yt + yBaseLeft + yBaseRight) / 3;

                Path clickPath = Path();
                clickPath.moveTo(centerBeginAxon_x, centerBeginAxon_y);
                clickPath.cubicTo(centerEndAxon_x, centerEndAxon_y, controlX,
                    controlY, triangleCenterX, triangleCenterY);
                String pathKey = "${from.key.toString()}_${to.key.toString()}";
                int pHash = Object.hash(centerBeginAxon_x, centerBeginAxon_y, centerEndAxon_x, centerEndAxon_y, controlX, controlY, triangleCenterX, triangleCenterY);
                if (controller.axonPathHashes[pathKey] != pHash || !controller.axonPathMap.containsKey(pathKey)) {
                    controller.axonPathMap[pathKey] = getOutlinePath(clickPath, widthClickMask);
                    controller.axonPathHashes[pathKey] = pHash;
                }

                Path path = Path();
                path.moveTo(centerBeginAxon_x, centerBeginAxon_y);
                path.cubicTo(centerEndAxon_x, centerEndAxon_y, controlX,
                    controlY, triangleCenterX, triangleCenterY);

                // V25: Draw highlight ONLY in highlight pass
                if (isSelected && isHighlightPass) {
                  // Axon path highlight - uses exact same 'path' variable
                  Paint highlightPaint = Paint()
                    ..color = const Color(0xFFFD8164)
                    ..style = PaintingStyle.stroke
                    ..strokeWidth = 17.0
                    ..strokeCap = StrokeCap.round;
                  canvas.drawPath(path, highlightPaint);
                  
                  // Triangle highlight
                  Path triH = Path();
                  triH.moveTo(xt, yt);
                  triH.lineTo(xBaseLeft, yBaseLeft);
                  triH.lineTo(xBaseRight, yBaseRight);
                  triH.close();
                  
                  Paint highlightTri = Paint()
                    ..color = const Color(0xFFFD8164)
                    ..style = PaintingStyle.stroke
                    ..strokeWidth = 8.0
                    ..strokeCap = StrokeCap.round
                    ..strokeJoin = StrokeJoin.round;
                  canvas.drawPath(triH, highlightTri);
                }
                
                // Skip main drawing only for highlight-only pass
                if (isHighlightPass) {
                  return;
                }
                
                // STRUCTURE PASS: Draw main elements (no highlights)
                // Main drawing (always drawn on top of highlights)
                // V25: LED Gradient Support - only for edges with actual visible colors
                // edgeColor is now passed as a parameter.
                
                // V25: Only apply gradient for visible, non-black colors (not transparent, not black)
                bool hasVisibleColor = edgeColor != null && 
                    edgeColor.alpha > 50 && 
                    (edgeColor.red > 20 || edgeColor.green > 20 || edgeColor.blue > 20);
                
                if (hasVisibleColor) {
                    // Determine gradient direction based on source type
                    List<Color> gradientColors = [edgeColor!, Colors.black];
                    bool isSourceLed = controller.syntheticNeuronList[fromIdx].node.value >= 4 ||
                                       (controller.syntheticNeuronList[fromIdx].node.label ?? "").toLowerCase().contains("led");
                    if (isSourceLed) {
                        gradientColors = [Colors.black, edgeColor!];
                    }
                    
                    final Shader gradientShader = ui.Gradient.linear(
                        Offset(centerBeginAxon_x, centerBeginAxon_y),
                        Offset(triangleCenterX, triangleCenterY),
                        gradientColors,
                        [0.0, 0.5],
                        TileMode.clamp,
                    );
                    Paint gradientPaint = Paint()
                      ..shader = gradientShader
                      ..style = PaintingStyle.stroke
                      ..strokeWidth = strength
                      ..strokeCap = StrokeCap.butt;
                    if (!isDrawingSynapsesOnly) canvas.drawPath(path, gradientPaint);
                } else {
                    if (!isDrawingSynapsesOnly) canvas.drawPath(path, blackBrush);
                }
                
                // Draw TRIANGLE (First Level) - White fill + black stroke
                blackBrush.strokeWidth = 1.5;
                blackBrush.style = PaintingStyle.stroke;
                Path triPath = Path();
                triPath.moveTo(xt, yt);
                triPath.lineTo(xBaseLeft, yBaseLeft);
                triPath.lineTo(xBaseRight, yBaseRight);
                triPath.close();
                if (isDrawingSynapsesOnly) {
                  canvas.drawPath(triPath, synapseFill);
                  canvas.drawPath(triPath, blackBrush);
                }

                 // V25: Sensory Axon Icons (Second Level - Robust)
                 if (!isHighlightPass) {
                    try {
                      String? iconText;
                      Color iconTextColor = Colors.black;
                      double iconSize = 18; // V25: Increased Size
                      
                      // Robust Key Generation
                      String rawKey = "${from.key}_${to.key}";
                      String fromIdClean = from.key.toString().replaceAll(RegExp(r"[\[\]<'>#]"), "");
                      String toIdClean = to.key.toString().replaceAll(RegExp(r"[\[\]<'>#]"), "");
                      String cleanKey = "${fromIdClean}_${toIdClean}";
                      String fromLabel = (from.label ?? "").toLowerCase();
                      String toLabel = (to.label ?? "").toLowerCase();
                      
                      // Robust Detection: Check Value + isSensory (Labels are often null, IDs are hashes)
                      // 0=Distance, 1=LeftEye, 2=RightEye, 3=Mic, 4=Speaker
                      bool isMic = (from.isSensory == 1 && from.value == 3) || fromLabel.contains("mic") || fromLabel.contains("microphone");
                      bool isSpeaker = (to.isSensory == 1 && to.value == 4) || toLabel.contains("speaker");
                      bool isCamera = (from.isSensory == 1 && (from.value == 1 || from.value == 2)) || fromLabel.contains("eye") || fromLabel.contains("camera");
                      bool isDistance = (from.isSensory == 1 && from.value == 0) || fromLabel.contains("distance");

                      // DEBUG MIC LOGIC (UNCONDITIONAL)
                      // if (isMic) {
                         // print("CheckIcon Loop1: from=$fromLabel ID=$fromIdClean to=$toLabel Key=$cleanKey MicMapKeys=${controller.mapMicrophoneTypeNeuron?.keys.length}");
                      // }

                      bool drawColoredCircle = false;
                      Color circleColor = Colors.transparent;
                      String fontFamily = "NotoEmoji"; // Default
                      double iconRadius = 12.5;

                      // Robust Lookup: Check Maps Directly (Ignore Labels)
                      
                      // 1. Camera / Sensory
                      if (controller.mapSensoryNeuron != null) {
                         int? idx;
                         String idKey = "${from.id}_${to.id}";
                         if (controller.mapSensoryNeuron.containsKey(rawKey)) idx = (controller.mapSensoryNeuron[rawKey] as num?)?.toInt();
                         else if (controller.mapSensoryNeuron.containsKey(cleanKey)) idx = (controller.mapSensoryNeuron[cleanKey] as num?)?.toInt();
                         else if (controller.mapSensoryNeuron.containsKey(idKey)) idx = (controller.mapSensoryNeuron[idKey] as num?)?.toInt();
                         
                         if (idx != null) {
                              List<String> cameraMenuTypes = [
                                 "Blue", "Blue (side)", "Green", "Green (side)", "Red", "Red (side)",
                                 "Movement", "person", "backpack", "bottle", "cup", "bowl", "banana", 
                                 "apple", "orange", "chair", "couch", "potted plant", "laptop", "cell phone", 
                                 "book", "vase", "dog", "cat", "tv", "mouse", "keyboard", "scissors", "donut", 
                                 "pizza", "hot dog"
                              ];
                              Map<String, String> lookup = {
                                 "person": "🧍", "backpack": "🎒", "bottle": "🧴", "cup": "☕", "bowl": "🥣",
                                 "banana": "🍌", "apple": "🍎", "orange": "🍊", "chair": "🪑", "couch": "🛋️",
                                 "potted plant": "🪴", "laptop": "💻", "cell phone": "📱", "book": "📒",
                                 "vase": "🏺", "Movement": "🏃", "dog": "🐕", "cat": "🐈", "tv": "📺",
                                 "mouse": "🐁", "keyboard": "⌨️", "scissors": "✂️", "donut": "🍩",
                                 "pizza": "🍕", "hot dog": "🌭"
                              };
                              if (idx >= 0 && idx < cameraMenuTypes.length) {
                                  // DEBUG: Verify lookup success
                                  // print("Camera Lookup Success: index=$idx type=${cameraMenuTypes[idx]}");
                                  String type = cameraMenuTypes[idx];
                                  if (lookup.containsKey(type)) {
                                      iconText = lookup[type];
                                      fontFamily = "NotoEmoji";
                                  } else if (type.contains("Blue")) {
                                      drawColoredCircle = true;
                                      circleColor = Colors.blue;
                                  } else if (type.contains("Green")) {
                                      drawColoredCircle = true;
                                      circleColor = Colors.green;
                                  } else if (type.contains("Red")) {
                                      drawColoredCircle = true;
                                      circleColor = Colors.red;
                                  }
                              }
                         }
                      }
                      
                      // 2. Distance (If not Camera)
                      if (iconText == null && !drawColoredCircle && controller.mapDistanceNeuron != null) {
                          int? idx;
                          String idKey = "${from.id}_${to.id}";
                          if (controller.mapDistanceNeuron.containsKey(rawKey)) idx = (controller.mapDistanceNeuron[rawKey] as num?)?.toInt();
                          else if (controller.mapDistanceNeuron.containsKey(cleanKey)) idx = (controller.mapDistanceNeuron[cleanKey] as num?)?.toInt();
                          else if (controller.mapDistanceNeuron.containsKey(idKey)) idx = (controller.mapDistanceNeuron[idKey] as num?)?.toInt();
                          
                          if (idx != null) {
                              // mapDistanceNeuron stores indices 0-3
                              // 0=Near(🛑), 1=Medium(⚠️), 2=Far(🏁), 3=Custom(📏)
                              List<String> distEmojis = ["🛑", "⚠️", "🏁", "📏"];
                              if (idx >= 0 && idx < distEmojis.length) {
                                  iconText = distEmojis[idx];
                                  fontFamily = "NotoEmoji";
                                  iconSize = 20; 
                              }
                          }
                      }
                      
                      // 3. Microphone (If not Distance)
                      if (iconText == null && !drawColoredCircle && (isMic || (controller.mapMicrophoneTypeNeuron != null && (controller.mapMicrophoneTypeNeuron.containsKey(rawKey) || controller.mapMicrophoneTypeNeuron.containsKey(cleanKey))))) {
                          int? mode;
                          if (controller.mapMicrophoneTypeNeuron != null) {
                              String idKey = "${from.id}_${to.id}";
                              if (controller.mapMicrophoneTypeNeuron.containsKey(rawKey)) mode = (controller.mapMicrophoneTypeNeuron[rawKey] as num?)?.toInt();
                              else if (controller.mapMicrophoneTypeNeuron.containsKey(cleanKey)) mode = (controller.mapMicrophoneTypeNeuron[cleanKey] as num?)?.toInt();
                              else if (controller.mapMicrophoneTypeNeuron.containsKey(idKey)) mode = (controller.mapMicrophoneTypeNeuron[idKey] as num?)?.toInt();
                          }
                          // Default to Freq (0)
                          if (mode == null) mode = 0;
                          
                          if (mode != null) {
                              // 0=Freq(〰️), 1=Vol(🔊), 2=Tone(🎹)
                              if (mode == 1) { iconText = "🔊"; iconSize = 20; fontFamily = "NotoEmoji"; }
                              else if (mode == 2) { 
                                  double val = 0;
                                  if (fromIdx >= 0 && fromIdx < controller.syntheticNeuronList.length) {
                                      val = controller.syntheticNeuronList[fromIdx].node.value;
                                  }
                                  int f = val.toInt();
                                  List<String> notes = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"];
                                  int noteIdx = f % 12;
                                  if (noteIdx < notes.length) {
                                      iconText = notes[noteIdx];
                                      fontFamily = "BybHanddrawn";
                                      iconSize = 18;
                                  } else {
                                      iconText = "🎹";
                                      fontFamily = "NotoEmoji";
                                      iconSize = 20;
                                  }
                              }
                              else { iconText = "〰️"; iconSize = 20; fontFamily = "NotoEmoji"; }
                          }
                      }
                      
                      // 4. Speaker (If not Mic)
                      if (iconText == null && !drawColoredCircle && controller.mapSpeakerNeuron != null) {
                          double? freq;
                          String idKey = "${from.id}_${to.id}";
                          if (controller.mapSpeakerNeuron.containsKey(rawKey)) freq = (controller.mapSpeakerNeuron[rawKey] as num?)?.toDouble();
                          else if (controller.mapSpeakerNeuron.containsKey(cleanKey)) freq = (controller.mapSpeakerNeuron[cleanKey] as num?)?.toDouble();
                          else if (controller.mapSpeakerNeuron.containsKey(idKey)) freq = (controller.mapSpeakerNeuron[idKey] as num?)?.toDouble();
                          
                          if (freq != null) {
                              int f = freq.toInt();
                              // Voice Range: 31-40
                              if (f >= 31 && f <= 40) {
                                  Map<int, String> voiceEmojis = {
                                     31: "👋", 32: "🫢", 33: "👍", 34: "🤔", 35: "😴",
                                     36: "🍰", 37: "🤠", 38: "🐕", 39: "🐱", 40: "✨"
                                  };
                                  if (voiceEmojis.containsKey(f)) {
                                      iconText = voiceEmojis[f];
                                      fontFamily = "NotoEmoji";
                                  }
                              } else if (f >= 70) {
                                  // Instrument Logic
                                  List<int> bases = [128, 228, 328, 428];
                                  int? bestBase;
                                  for (int b in bases) {
                                      if (f >= b && f < b + 24) { bestBase = b; break; }
                                  }
                                  if (bestBase != null) {
                                      int diff = f - bestBase;
                                      List<String> notes = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"];
                                      int noteIdx = diff % 12;
                                      if (noteIdx < notes.length) {
                                          iconText = notes[noteIdx];
                                          fontFamily = "BybHanddrawn"; // Handwritten for notes
                                          iconSize = 18;
                                      }
                                  } else {
                                      iconText = "🎵";
                                      fontFamily = "NotoEmoji";
                                  }
                              }
                          }
                      }
                      
                      // V25: No Icon Drawing for First Leg of 2-Level Connection
                      // Icons are drawn in Loop 2 (Second Leg) to appear at the synapse.
                      if (iconText != null || drawColoredCircle) {
                           // Do nothing for first leg
                      }
                  } catch (e) {}
                 }

              } else {
                 // No second level exists, draw normally (Triangle + Line)
                 // This block was previously handling standard 1-level connections
                 // ... (Original logic for 1-level dendrite connection) ...
                 // Wait, the logic above (lines 883-918) was INSIDE "if (dendrites[posin].hasSecondLevel)"??
                 // NO. The original code had:
                 // if (neuronTo.dendrites[posin].hasSecondLevel) { ... } else { ... }
                 // Let's implement BOTH paths correctly as per original but cleaner.
                 
                 // Standard Axon Path to Triangle
                 blackBrush.style = PaintingStyle.stroke;
                 double angle = neuronTo.dendrites[posin].angle;
                 double distToSynapse = euclideanDistance(centerBeginAxon_x, centerBeginAxon_y, xc, yc);
                 double controlDist = min(distToSynapse * 0.25, 60.0);
                 double controlX = xc + controlDist * cosDeg(angle);
                 double controlY = yc + controlDist * sinDeg(angle);
                 
                 double triangleCenterX = (xt + xBaseLeft + xBaseRight) / 3;
                 double triangleCenterY = (yt + yBaseLeft + yBaseRight) / 3;

                 Path clickPath = Path();
                 clickPath.moveTo(centerBeginAxon_x, centerBeginAxon_y);
                 clickPath.cubicTo(centerEndAxon_x, centerEndAxon_y, controlX,
                    controlY, triangleCenterX, triangleCenterY);
                 String pathKey = "${from.key.toString()}_${to.key.toString()}";
                 int pHash = Object.hash(centerBeginAxon_x, centerBeginAxon_y, centerEndAxon_x, centerEndAxon_y, controlX, controlY, triangleCenterX, triangleCenterY);
                 if (controller.axonPathHashes[pathKey] != pHash || !controller.axonPathMap.containsKey(pathKey)) {
                     controller.axonPathMap[pathKey] = getOutlinePath(clickPath, widthClickMask);
                     controller.axonPathHashes[pathKey] = pHash;
                 }
                 
                 Path path = Path();
                 path.moveTo(centerBeginAxon_x, centerBeginAxon_y);
                 path.cubicTo(centerEndAxon_x, centerEndAxon_y, controlX,
                    controlY, triangleCenterX, triangleCenterY);
                    
                 // V25: Draw highlight ONLY in highlight pass
                 if (isSelected && isHighlightPass) {
                   Paint highlightPaint = Paint()
                     ..color = const Color(0xFFFD8164)
                     ..style = PaintingStyle.stroke
                     ..strokeWidth = 17.0
                     ..strokeCap = StrokeCap.round;
                   canvas.drawPath(path, highlightPaint);
                   
                   Path triH = Path();
                   triH.moveTo(xt, yt);
                   triH.lineTo(xBaseLeft, yBaseLeft);
                   triH.lineTo(xBaseRight, yBaseRight);
                   triH.close();
                   
                   Paint highlightTri = Paint()
                     ..color = const Color(0xFFFD8164)
                     ..style = PaintingStyle.stroke
                     ..strokeWidth = 8.0
                     ..strokeCap = StrokeCap.round
                     ..strokeJoin = StrokeJoin.round;
                   canvas.drawPath(triH, highlightTri);
                 }
                 
                 if (isHighlightPass) {
                   return;
                 }
                 
                 // STRUCTURE PASS: Draw main elements (no highlights)
                 // V25: LED Gradient Support - only for edges with actual visible colors
                 // edgeColor is now passed as a parameter.
                 
                 // V25: Only apply gradient for visible, non-black colors
                 bool hasVisibleColor = edgeColor != null && 
                     edgeColor.alpha > 50 && 
                     (edgeColor.red > 20 || edgeColor.green > 20 || edgeColor.blue > 20);
                 
                 if (hasVisibleColor) {
                     List<Color> gradientColors = [edgeColor, Colors.black];
                     bool isSourceLed = controller.syntheticNeuronList[fromIdx].node.value >= 4 ||
                                        (controller.syntheticNeuronList[fromIdx].node.label ?? "").toLowerCase().contains("led");
                     if (isSourceLed) {
                         gradientColors = [Colors.black, edgeColor];
                     }
                     
                     final Shader gradientShader = ui.Gradient.linear(
                         Offset(centerBeginAxon_x, centerBeginAxon_y),
                         Offset(triangleCenterX, triangleCenterY),
                         gradientColors,
                         [0.0, 0.5],
                         TileMode.clamp,
                     );
                     Paint gradientPaint = Paint()
                       ..shader = gradientShader
                       ..style = PaintingStyle.stroke
                       ..strokeWidth = strength
                       ..strokeCap = StrokeCap.butt;
                     if (!isDrawingSynapsesOnly) canvas.drawPath(path, gradientPaint);
                 } else {
                     if (!isDrawingSynapsesOnly) canvas.drawPath(path, blackBrush);
                 }
                 
                 // Draw Triangle - White fill + black stroke
                 blackBrush.strokeWidth = 1.5;
                 blackBrush.style = PaintingStyle.stroke;
                 Path triPath = Path();
                 triPath.moveTo(xt, yt);
                 triPath.lineTo(xBaseLeft, yBaseLeft);
                 triPath.lineTo(xBaseRight, yBaseRight);
                 triPath.close();
                 if (isDrawingSynapsesOnly) {
                   canvas.drawPath(triPath, synapseFill);
                   canvas.drawPath(triPath, blackBrush);
                 }
              }

            } else {
              // INHIBITORY (Circle) - Reference implementation
              // Fixed radius with offset from dendrite to create gap
              double radius = 5.0;
              
              // Dendrite position
              double xcent = xc;
              double ycent = yc;
              
              // Angle from Neuron Center to Dendrite (Outward)
              double angleOut = atan2(ycent - neuronTo.y, xcent - neuronTo.x);
              
              // V25: Offset stacked synapses so they peek out from behind each other
              double stackOffset = sinindex * 6.0;
              xcent += stackOffset * cos(angleOut);
              ycent += stackOffset * sin(angleOut);
              
              // New Center = Dendrite + Radius * Vector (offset outward)
              double xc_syn = xcent + radius * cos(angleOut);
              double yc_syn = ycent + radius * sin(angleOut);
              
              blackBrush.strokeWidth = strength;
              blackBrush.style = PaintingStyle.stroke;

              // Control point logic
              double bFactor = (1.0 + sqrt((centerBeginAxon_x - xc_syn)*(centerBeginAxon_x - xc_syn) + (centerBeginAxon_y - yc_syn)*(centerBeginAxon_y - yc_syn)) / 200.0);
              double controlX = xc_syn + bFactor * (xc_syn - neuronTo.x) * 0.5;
              double controlY = yc_syn + bFactor * (yc_syn - neuronTo.y) * 0.5;

              Path clickPath = Path();
              clickPath.moveTo(centerBeginAxon_x, centerBeginAxon_y);
              clickPath.cubicTo(centerEndAxon_x, centerEndAxon_y, controlX,
                  controlY, xc_syn, yc_syn);
              String pathKey = "${from.key.toString()}_${to.key.toString()}";
              int pHash = Object.hash(centerBeginAxon_x, centerBeginAxon_y, centerEndAxon_x, centerEndAxon_y, controlX, controlY, xc_syn, yc_syn);
              if (controller.axonPathHashes[pathKey] != pHash || !controller.axonPathMap.containsKey(pathKey)) {
                  controller.axonPathMap[pathKey] = getOutlinePath(clickPath, widthClickMask);
                  controller.axonPathHashes[pathKey] = pHash;
              }

              Path path = Path();
              path.moveTo(centerBeginAxon_x, centerBeginAxon_y);
              path.cubicTo(centerEndAxon_x, centerEndAxon_y, controlX,
                  controlY, xc_syn, yc_syn);

              // V25: Draw highlight ONLY in highlight pass
              if (isSelected && isHighlightPass) {
                Paint highlightPaint = Paint()
                  ..color = const Color(0xFFFD8164)
                  ..style = PaintingStyle.stroke
                  ..strokeWidth = 17.0
                  ..strokeCap = StrokeCap.round;
                canvas.drawPath(path, highlightPaint);
                // Circle highlight
                Paint circleHighlight = Paint()
                  ..color = const Color(0xFFFD8164)
                  ..style = PaintingStyle.fill;
                canvas.drawCircle(Offset(xc_syn, yc_syn), radius + 4.0, circleHighlight);
              }
              
              if (isHighlightPass) {
                return;
              }
              
              // STRUCTURE PASS: Draw main elements (no highlights)
              // edgeColor is now passed as a parameter.
              
              if (edgeColor != null && edgeColor != Colors.black) {
                  List<Color> gradientColors = [edgeColor, Colors.black];
                  bool isSourceLed = controller.syntheticNeuronList[fromIdx].node.value >= 4 ||
                                     (controller.syntheticNeuronList[fromIdx].node.label ?? "").toLowerCase().contains("led");
                  if (isSourceLed) {
                      gradientColors = [Colors.black, edgeColor];
                  }
                  
                  final Shader gradientShader = ui.Gradient.linear(
                      Offset(centerBeginAxon_x, centerBeginAxon_y),
                      Offset(xc_syn, yc_syn),
                      gradientColors,
                      [0.0, 0.5],
                      TileMode.clamp,
                  );
                  Paint gradientPaint = Paint()
                    ..shader = gradientShader
                    ..style = PaintingStyle.stroke
                    ..strokeWidth = strength
                    ..strokeCap = StrokeCap.butt;
                  if (!isDrawingSynapsesOnly) canvas.drawPath(path, gradientPaint);
              } else {
                  if (!isDrawingSynapsesOnly) canvas.drawPath(path, blackBrush);
              }

              // Draw Circle Synapse - Black outer (5px) + white inner (3.5px) = 1.5px border
              blackBrush.style = PaintingStyle.fill;
              if (isDrawingSynapsesOnly) {
                canvas.drawCircle(Offset(xc_syn, yc_syn), radius, blackBrush);
                canvas.drawCircle(Offset(xc_syn, yc_syn), radius - 1.5, synapseFill);
              }
            }
            if (isShowingInfo && label != null) {
              // V25: TextPainter Cache Optimization
              String cacheKey = "info_${label}_${textStyle.hashCode}";
              TextPainter? textPainter = controller.textPainterCache[cacheKey];
              
              if (textPainter == null) {
                  final textSpan = TextSpan(
                    text: label,
                    style: textStyle,
                  );
                  textPainter = TextPainter(
                    text: textSpan,
                    textDirection: TextDirection.ltr,
                  );
                  textPainter.layout(
                    minWidth: 0,
                    maxWidth: 100,
                  );
                  controller.textPainterCache[cacheKey] = textPainter;
              }
              textPainter.paint(canvas, Offset(centerEndAxon_x, centerEndAxon_y));
            }

                 // V25: Sensory Axon Icons (Standard Level)
                 if (!isHighlightPass) {
                    try {
                      String? iconText;
                      Color iconTextColor = Colors.black;
                      double iconSize = 18; // V25: Increased Size
                      
                      // Robust Key Generation
                      String rawKey = "${from.key}_${to.key}";
                      String fromIdClean = from.key.toString().replaceAll(RegExp(r"[\[\]<'>#]"), "");
                      String toIdClean = to.key.toString().replaceAll(RegExp(r"[\[\]<'>#]"), "");
                      String cleanKey = "${fromIdClean}_${toIdClean}";
                      
                      // Debug Info (Temporary)
                      // print("AxonIconCheck: Raw=$rawKey Clean=$cleanKey MapSize=${controller.mapSensoryNeuron?.length}");
                      
                      String fromLabel = (from.label ?? "").toLowerCase();
                      String toLabel = (to.label ?? "").toLowerCase();
                      
                      // Robust Detection: Check Value + isSensory (Labels are often null, IDs are hashes)
                      // 0=Distance, 1=LeftEye, 2=RightEye, 3=Mic, 4=Speaker
                      bool isMic = (from.isSensory == 1 && from.value == 3) || fromLabel.contains("mic") || fromLabel.contains("microphone");
                      bool isSpeaker = (to.isSensory == 1 && to.value == 4) || toLabel.contains("speaker");
                      bool isCamera = (from.isSensory == 1 && (from.value == 1 || from.value == 2)) || fromLabel.contains("eye") || fromLabel.contains("camera");
                      bool isDistance = (from.isSensory == 1 && from.value == 0) || fromLabel.contains("distance");
                      // print("CheckIcon: Label=$fromLabel -> $toLabel. Key=$rawKey");
                      
                      bool drawColoredCircle = false;
                      Color circleColor = Colors.transparent;
                      String fontFamily = "NotoEmoji"; // Default
                      double iconRadius = 12.5;

                      // Robust Lookup: Check Maps Directly (Ignore Labels)
                      
                      // 1. Camera / Sensory
                      if (controller.mapSensoryNeuron != null) {
                         int? idx;
                         if (controller.mapSensoryNeuron.containsKey(rawKey)) idx = (controller.mapSensoryNeuron[rawKey] as num?)?.toInt();
                         else if (controller.mapSensoryNeuron.containsKey(cleanKey)) idx = (controller.mapSensoryNeuron[cleanKey] as num?)?.toInt();
                         
                         if (idx != null) {
                              List<String> cameraMenuTypes = [
                                 "Blue", "Blue (side)", "Green", "Green (side)", "Red", "Red (side)",
                                 "Movement", "person", "backpack", "bottle", "cup", "bowl", "banana", 
                                 "apple", "orange", "chair", "couch", "potted plant", "laptop", "cell phone", 
                                 "book", "vase", "dog", "cat", "tv", "mouse", "keyboard", "scissors", "donut", 
                                 "pizza", "hot dog"
                              ];
                              Map<String, String> lookup = {
                                 "person": "🧍", "backpack": "🎒", "bottle": "🧴", "cup": "☕", "bowl": "🥣",
                                 "banana": "🍌", "apple": "🍎", "orange": "🍊", "chair": "🪑", "couch": "🛋️",
                                 "potted plant": "🪴", "laptop": "💻", "cell phone": "📱", "book": "📒",
                                 "vase": "🏺", "Movement": "🏃", "dog": "🐕", "cat": "🐈", "tv": "📺",
                                 "mouse": "🐁", "keyboard": "⌨️", "scissors": "✂️", "donut": "🍩",
                                 "pizza": "🍕", "hot dog": "🌭"
                              };
                              if (idx < cameraMenuTypes.length) {
                                  String type = cameraMenuTypes[idx];
                                  if (lookup.containsKey(type)) {
                                      iconText = lookup[type];
                                      fontFamily = "NotoEmoji";
                                  } else if (type.contains("Blue")) {
                                      drawColoredCircle = true;
                                      circleColor = Colors.blue;
                                  } else if (type.contains("Green")) {
                                      drawColoredCircle = true;
                                      circleColor = Colors.green;
                                  } else if (type.contains("Red")) {
                                      drawColoredCircle = true;
                                      circleColor = Colors.red;
                                  }
                              }
                         }
                      }
                      
                      // 2. Distance (If not Camera)
                      if (iconText == null && !drawColoredCircle && controller.mapDistanceNeuron != null) {
                          int? idx;
                          if (controller.mapDistanceNeuron.containsKey(rawKey)) idx = (controller.mapDistanceNeuron[rawKey] as num?)?.toInt();
                          else if (controller.mapDistanceNeuron.containsKey(cleanKey)) idx = (controller.mapDistanceNeuron[cleanKey] as num?)?.toInt();
                          
                          if (idx != null) {
                              // mapDistanceNeuron stores indices 0-3
                              // 0=Near(🛑), 1=Medium(⚠️), 2=Far(🏁), 3=Custom(📏)
                              List<String> distEmojis = ["🛑", "⚠️", "🏁", "📏"];
                              if (idx >= 0 && idx < distEmojis.length) {
                                  iconText = distEmojis[idx];
                                  fontFamily = "NotoEmoji";
                                  iconSize = 20; 
                              }
                          }
                      }
                      
                      // 3. Microphone (If not Distance)
                      if (iconText == null && !drawColoredCircle && (isMic || (controller.mapMicrophoneTypeNeuron != null && (controller.mapMicrophoneTypeNeuron.containsKey(rawKey) || controller.mapMicrophoneTypeNeuron.containsKey(cleanKey))))) {
                          int? mode;
                          if (controller.mapMicrophoneTypeNeuron != null) {
                              if (controller.mapMicrophoneTypeNeuron.containsKey(rawKey)) mode = (controller.mapMicrophoneTypeNeuron[rawKey] as num?)?.toInt();
                              else if (controller.mapMicrophoneTypeNeuron.containsKey(cleanKey)) mode = (controller.mapMicrophoneTypeNeuron[cleanKey] as num?)?.toInt();
                          }
                          // Default to Freq (0)
                          if (mode == null) mode = 0;
                          
                          if (mode != null) {
                              // 0=Freq(〰️), 1=Vol(🔊), 2=Tone(🎹)
                              if (mode == 1) { iconText = "🔊"; iconSize = 20; fontFamily = "NotoEmoji"; }
                              else if (mode == 2) { 
                                  // Piano Note Logic: Decode from mapMicrophoneLimitNeuron string "min_@_max"
                                  // In Tone mode, Min holds the note index (0-11).
                                  int noteIndex = 0;
                                  String? limitStr;
                                  if (controller.mapMicrophoneLimitNeuron.containsKey(rawKey)) limitStr = controller.mapMicrophoneLimitNeuron[rawKey];
                                  else if (controller.mapMicrophoneLimitNeuron.containsKey(cleanKey)) limitStr = controller.mapMicrophoneLimitNeuron[cleanKey];
                                  
                                  if (limitStr != null) {
                                      List<String> parts = limitStr.split("_@_");
                                      if (parts.isNotEmpty) {
                                          noteIndex = int.tryParse(parts[0]) ?? 0;
                                      }
                                  }

                                  List<String> notes = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"];
                                  int safeIdx = noteIndex % 12;
                                  if (safeIdx < notes.length) {
                                      iconText = notes[safeIdx];
                                      fontFamily = "BybHanddrawn";
                                      iconSize = 18;
                                  } else {
                                      iconText = "🎹";
                                      fontFamily = "NotoEmoji";
                                      iconSize = 20;
                                  }
                              }
                              else { iconText = "〰️"; iconSize = 20; fontFamily = "NotoEmoji"; }
                          }
                      }
                      
                      // 4. Speaker (If not Mic)
                      if (iconText == null && !drawColoredCircle && controller.mapSpeakerNeuron != null) {
                          double? freq;
                          if (controller.mapSpeakerNeuron.containsKey(rawKey)) freq = (controller.mapSpeakerNeuron[rawKey] as num?)?.toDouble();
                          else if (controller.mapSpeakerNeuron.containsKey(cleanKey)) freq = (controller.mapSpeakerNeuron[cleanKey] as num?)?.toDouble();
                          
                          if (freq != null) {
                              int f = freq.toInt();
                              // Voice Range: 31-40
                              if (f >= 31 && f <= 40) {
                                  Map<int, String> voiceEmojis = {
                                     31: "👋", 32: "🫢", 33: "👍", 34: "🤔", 35: "😴",
                                     36: "🍰", 37: "🤠", 38: "🐕", 39: "🐱", 40: "✨"
                                  };
                                  if (voiceEmojis.containsKey(f)) {
                                      iconText = voiceEmojis[f];
                                      fontFamily = "NotoEmoji";
                                  }
                              } else if (f >= 70) {
                                  // Instrument Logic
                                  // Base Freqs: 128 (Choir), 228 (Strings), 328 (Brass), 428 (Synth)
                                  List<int> bases = [128, 228, 328, 428];
                                  int? bestBase;
                                  for (int b in bases) {
                                      if (f >= b && f < b + 24) { bestBase = b; break; }
                                  }
                                  if (bestBase != null) {
                                      int diff = f - bestBase;
                                      List<String> notes = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"];
                                      int noteIdx = diff % 12;
                                      if (noteIdx < notes.length) {
                                          iconText = notes[noteIdx];
                                          fontFamily = "BybHanddrawn"; // Handwritten for notes
                                          iconSize = 18;
                                      }
                                  } else {
                                      // Fallback for unknown instrument freq
                                      iconText = "🎵";
                                      fontFamily = "NotoEmoji";
                                  }
                              }
                          }
                      }
                      
                      if (iconText != null || drawColoredCircle) {
                          // Recalculate Control Point (Standard Axon Logic)
                          double angle = neuronTo.dendrites[posin].angle;
                          double distToSynapse = euclideanDistance(centerBeginAxon_x, centerBeginAxon_y, xc, yc);
                          
                          // V25: Fix Far Dendrite Centering
                          // Replicate initialAxonExtension logic to ensure p1 matches Drawn Path
                          double centerEndAxon_x = centerBeginAxon_x; // Start from axon origin
                          double centerEndAxon_y = centerBeginAxon_y;
                          
                          double initialAxonExtensionSize = 0.5; // Must match Loop 1 const
                          var initialPortionOfAxon = initialAxonExtensionSize * distToSynapse / diameterOfNeuron;
                          
                          // Recalculate shift (matches Loop 1 lines ~1160)
                          if (branchDirection != null) {
                             double extensionLength = min(max(distToSynapse * 0.4, 20.0), 100.0);
                             centerEndAxon_x = centerBeginAxon_x + branchDirection.dx * extensionLength;
                             centerEndAxon_y = centerBeginAxon_y + branchDirection.dy * extensionLength;
                          } else {
                             double extensionLength = min(max(distToSynapse * 0.3, 20.0), 100.0);
                             Offset directionToTarget = Offset(xc - centerBeginAxon_x, yc - centerBeginAxon_y);
                             if (directionToTarget.distance > 0) directionToTarget = directionToTarget / directionToTarget.distance;
                             centerEndAxon_x = centerBeginAxon_x + directionToTarget.dx * extensionLength;
                             centerEndAxon_y = centerBeginAxon_y + directionToTarget.dy * extensionLength;
                          }

                          // Recalculate Target for Icon Placement
                          Offset p3;
                          if (isExcitatory == 1) {
                              // Excitatory (Triangle): Target matches drawn path (Tip)
                              p3 = Offset(xc, yc); 
                          } else {
                              // Inhibitory (Circle): Target is Circle Center
                              double radius = 5.0;
                              double stackOffset = sinindex * 6.0; // V25: Inhibitory stack offset outward
                              double angleOut = atan2(yc - neuronTo.y, xc - neuronTo.x);
                              double xc_stack = xc + stackOffset * cos(angleOut);
                              double yc_stack = yc + stackOffset * sin(angleOut);
                              double xc_syn = xc_stack + radius * cos(angleOut);
                              double yc_syn = yc_stack + radius * sin(angleOut);
                              p3 = Offset(xc_syn, yc_syn);
                          }

                          // 1. Calculate Control Points FIRST to determine Tangent Length at Tip
                          double controlX, controlY;
                          double tangentLength = 1.0;

                          if (isExcitatory == 1) {
                              // Excitatory: Matches Lines ~1224 (controlDist)
                              double controlDist = min(distToSynapse * 0.25, 60.0);
                              controlX = xc + controlDist * cosDeg(angle);
                              controlY = yc + controlDist * sinDeg(angle);
                              
                              // Velocity at Tip (P3) is 3 * (P3 - P2). Tangent Length = 3 * dist(P2, P3)
                              // P2 = (controlX, controlY), P3 = (xc, yc) [Tip]
                              // Distance is exactly controlDist.
                              tangentLength = 3.0 * controlDist;
                          } else {
                              // Inhibitory: Matches Lines ~1647 (bFactor)
                              // Recalculate xc_syn/yc_syn as target (already done for p3, but needed for bFactor)
                              double radius = 5.0;
                              double stackOffset = sinindex * 6.0; // V25: Inhibitory stack offset outward
                              double angleOut = atan2(yc - neuronTo.y, xc - neuronTo.x);
                              double xc_stack = xc + stackOffset * cos(angleOut);
                              double yc_stack = yc + stackOffset * sin(angleOut);
                              double xc_syn = xc_stack + radius * cos(angleOut);
                              double yc_syn = yc_stack + radius * sin(angleOut);
                              
                              double bFactor = (1.0 + sqrt((centerBeginAxon_x - xc_syn)*(centerBeginAxon_x - xc_syn) + (centerBeginAxon_y - yc_syn)*(centerBeginAxon_y - yc_syn)) / 200.0);
                              controlX = xc_syn + bFactor * (xc_syn - neuronTo.x) * 0.5;
                              controlY = yc_syn + bFactor * (yc_syn - neuronTo.y) * 0.5;

                              // Distance P2 to P3
                              double dx = xc_syn - controlX;
                              double dy = yc_syn - controlY;
                              double distP2P3 = sqrt(dx*dx + dy*dy);
                              tangentLength = 3.0 * distP2P3;
                          }

                          // 2. Calculate T for Icon Placement
                          // V25Fix: Place icon exactly at the midpoint of the final axon segment
                          // This prevents overlapping when multiple stacked synapses terminate nearby.
                          double t = 0.5;

                          double u = 1 - t;
                          double tt = t * t; double uu = u * u; double uuu = uu * u; double ttt = tt * t;
                          Offset p0 = Offset(centerBeginAxon_x, centerBeginAxon_y);
                          Offset p1 = Offset(centerEndAxon_x, centerEndAxon_y);
                          Offset p2 = Offset(controlX, controlY);
                          double bx = uuu * p0.dx + 3 * uu * t * p1.dx + 3 * u * tt * p2.dx + ttt * p3.dx;
                          double by = uuu * p0.dy + 3 * uu * t * p1.dy + 3 * u * tt * p2.dy + ttt * p3.dy;
                          Offset iconPos = Offset(bx, by);

                          // V25: Radius 12.5 (25px Diameter)
                          canvas.drawCircle(iconPos + const Offset(1,1), iconRadius, Paint()..color = Colors.black.withOpacity(0.3));
                          canvas.drawCircle(iconPos, iconRadius, Paint()..color = Colors.white..style = PaintingStyle.fill);
                          
                          if (drawColoredCircle) {
                              // Filled Colored Circle (No Stroke)
                              canvas.drawCircle(iconPos, iconRadius - 2, Paint()..color = circleColor..style = PaintingStyle.fill);
                              // Add white stroke around color?
                              canvas.drawCircle(iconPos, iconRadius, Paint()..color = Colors.grey.withOpacity(0.5)..style = PaintingStyle.stroke..strokeWidth=1);
                          } else {
                              // Standard Icon
                              canvas.drawCircle(iconPos, iconRadius, Paint()..color = Colors.grey.withOpacity(0.5)..style = PaintingStyle.stroke..strokeWidth=1);
                              
                              // V25: TextPainter Cache Optimization
                              String cacheKey = "icon_${iconText}_${fontFamily}_$iconSize";
                              TextPainter? tp = controller.textPainterCache[cacheKey];
                              
                              if (tp == null) {
                                  TextSpan span = TextSpan(style: TextStyle(color: iconTextColor, fontSize: iconSize, fontFamily: fontFamily), text: iconText);
                                  tp = TextPainter(text: span, textAlign: TextAlign.center, textDirection: TextDirection.ltr);
                                  tp.layout();
                                  controller.textPainterCache[cacheKey] = tp;
                              }
                              
                              tp.paint(canvas, iconPos - Offset(tp.width / 2, tp.height / 2));
                          }
                      }
                     } catch (e) {}
                 }
              } // Close 'else' (Standard Axon)
           }
         }

      // Loop 2: Second Level Synapses (G1 Compliant)
      // DEBUG LOOP 2 ENTRY
      // print("DrawAxon Loop 2: from=${from.label} to=${to.label} posin=$posin 2ndLen=${neuronTo.dendrites[posin].sinapseSecondLevel.length}");
      if (neuronTo.dendrites[posin].sinapseSecondLevel.isNotEmpty) {
         for (int sinindex = 0; 
              sinindex < neuronTo.dendrites[posin].sinapseSecondLevel.length; 
              sinindex++) {
           if (neuronTo.dendrites[posin].sinapseSecondLevel[sinindex]
                  .presinapticNeuronIndex == fromIdx) {
              
              // V25: Output Dendrites map Left to Inhibitory (First Level) and Right to Excitatory (Second Level)
              // The routing logic already successfully placed this synapse in `sinapseSecondLevel`.
              // We just extract the exact X/Y coordinates of `xSecondLevel` to draw the line.
              double xOffset = -circleRadius + neuronTo.dendrites[posin].xSecondLevel;
              double yOffset = -circleRadius + neuronTo.dendrites[posin].ySecondLevel;
              
              double xc = neuronTo.x + xOffset * targetScale;
              double yc = neuronTo.y + yOffset * targetScale;
              
              var initialPortionOfAxon = initialAxonExtensionSize *
                euclideanDistance(
                    centerBeginAxon_x, centerBeginAxon_y, xc, yc) /
                diameterOfNeuron;

              // V23: G1 Compliant Tangents for Second Level
              double centerEndAxon_x;
              double centerEndAxon_y;
              if (branchDirection != null) {
                 double distToTarget = euclideanDistance(centerBeginAxon_x, centerBeginAxon_y, xc, yc);
                 double extensionLength = min(max(distToTarget * 0.4, 20.0), 100.0);
                 centerEndAxon_x = centerBeginAxon_x + branchDirection.dx * extensionLength;
                 centerEndAxon_y = centerBeginAxon_y + branchDirection.dy * extensionLength;
              } else {
                 double distToTarget = euclideanDistance(centerBeginAxon_x, centerBeginAxon_y, xc, yc);
                 double extensionLength = min(max(distToTarget * 0.3, 20.0), 100.0);
                 Offset directionToTarget = Offset(xc - centerBeginAxon_x, yc - centerBeginAxon_y);
                 if (directionToTarget.distance > 0) directionToTarget = directionToTarget / directionToTarget.distance;
                 centerEndAxon_x = centerBeginAxon_x + directionToTarget.dx * extensionLength;
                 centerEndAxon_y = centerBeginAxon_y + directionToTarget.dy * extensionLength;
              }
              
              double strength = ((neuronTo.dendrites[posin]
                            .sinapseSecondLevel[sinindex].sinapticValue)
                        .abs() /
                    maxAbsoluteConnectionStrength) *
                diameterOfNeuron / 2;
                
               if ((diameterOfNeuron * 0.1) > strength) strength = diameterOfNeuron * 0.1;
               if (strength < minimalTicknessOfAxon) strength = minimalTicknessOfAxon;

               blackBrush.strokeWidth = strength;
               blackBrush.style = PaintingStyle.fill;
               
               if (isExcitatory == 1) {
                  // Triangle for Second Level - Fixed 10px size with atan2 orientation
                  double triangleSize = 10.0;
                  
                  // Dendrite position (base of triangle)
                  double xcent = xc; 
                  double ycent = yc;
                  
                  // Angle from Neuron Center to Dendrite (Outward)
                  double angleOut = atan2(ycent - neuronTo.y, xcent - neuronTo.x);
                  
                  // V25: Offset stacked synapses so they peek out from behind each other
                  double stackOffset = sinindex * 6.0;
                  xcent += stackOffset * cos(angleOut);
                  ycent += stackOffset * sin(angleOut);
                  
                  // Tip Position (Faces Axon / Outwards)
                  double xt = xcent + triangleSize * cos(angleOut);
                  double yt = ycent + triangleSize * sin(angleOut);
                  
                  // Base Points (Flat against neuron) - Equilateral triangle
                  double halfBase = triangleSize / sqrt(3);  // For equilateral triangle
                  double xBaseLeft = xcent + halfBase * cos(angleOut - pi/2);
                  double yBaseLeft = ycent + halfBase * sin(angleOut - pi/2);
                  double xBaseRight = xcent + halfBase * cos(angleOut + pi/2);
                  double yBaseRight = ycent + halfBase * sin(angleOut + pi/2);
                   
                  // Draw Axon Line
                  blackBrush.style = PaintingStyle.stroke;
                  
                  // Control point logic
                  double bFactor = (1.0 + sqrt((centerBeginAxon_x - xt)*(centerBeginAxon_x - xt) + (centerBeginAxon_y - yt)*(centerBeginAxon_y - yt)) / 200.0);
                  double controlX = xt + bFactor * (xt - neuronTo.x) * 0.5;
                  double controlY = yt + bFactor * (yt - neuronTo.y) * 0.5;
                   
                  double triangleCenterX = (xt + xBaseLeft + xBaseRight) / 3;
                  double triangleCenterY = (yt + yBaseLeft + yBaseRight) / 3;
                  
                  Path clickPath = Path();
                  clickPath.moveTo(centerBeginAxon_x, centerBeginAxon_y);
                  clickPath.cubicTo(centerEndAxon_x, centerEndAxon_y, controlX,
                      controlY, triangleCenterX, triangleCenterY);
                  String pathKey = "${from.key.toString()}_${to.key.toString()}";
                  int pHash = Object.hash(centerBeginAxon_x, centerBeginAxon_y, centerEndAxon_x, centerEndAxon_y, controlX, controlY, triangleCenterX, triangleCenterY);
                  if (controller.axonPathHashes[pathKey] != pHash || !controller.axonPathMap.containsKey(pathKey)) {
                      controller.axonPathMap[pathKey] = getOutlinePath(clickPath, widthClickMask);
                      controller.axonPathHashes[pathKey] = pHash;
                  }
                  
                  Path path = Path();
                  path.moveTo(centerBeginAxon_x, centerBeginAxon_y);
                  path.cubicTo(centerEndAxon_x, centerEndAxon_y, controlX,
                      controlY, triangleCenterX, triangleCenterY);
                      
                  // V25: Draw highlight ONLY in highlight pass
                  if (isSelected && isHighlightPass) {
                    Paint highlightPaint = Paint()
                      ..color = const Color(0xFFFD8164)
                      ..style = PaintingStyle.stroke
                      ..strokeWidth = 17.0
                      ..strokeCap = StrokeCap.round;
                    canvas.drawPath(path, highlightPaint);
                    
                    Path triH = Path();
                    triH.moveTo(xt, yt);
                    triH.lineTo(xBaseLeft, yBaseLeft);
                    triH.lineTo(xBaseRight, yBaseRight);
                    triH.close();
                    
                    Paint highlightTri = Paint()
                      ..color = const Color(0xFFFD8164)
                      ..style = PaintingStyle.stroke
                      ..strokeWidth = 8.0
                      ..strokeCap = StrokeCap.round
                      ..strokeJoin = StrokeJoin.round;
                    canvas.drawPath(triH, highlightTri);
                  }
                  
                  if (isHighlightPass) {
                    return;
                  }
                  
                  // STRUCTURE PASS: Draw main elements (no highlights)
                  // V25: LED Gradient Support - only for edges with actual visible colors
                  // We already have edgeColor passed in as an argument!
                  
                  // V25: Only apply gradient for visible, non-black colors
                  bool hasVisibleColor = edgeColor != null && 
                      edgeColor.alpha > 50 && 
                      (edgeColor.red > 20 || edgeColor.green > 20 || edgeColor.blue > 20);
                  
                  if (hasVisibleColor) {
                      List<Color> gradientColors = [edgeColor, Colors.black];
                      bool isSourceLed = controller.syntheticNeuronList[fromIdx].node.value >= 4 ||
                                         (controller.syntheticNeuronList[fromIdx].node.label ?? "").toLowerCase().contains("led");
                      if (isSourceLed) {
                          gradientColors = [Colors.black, edgeColor];
                      }
                      
                      final Shader gradientShader = ui.Gradient.linear(
                          Offset(centerBeginAxon_x, centerBeginAxon_y),
                          Offset(triangleCenterX, triangleCenterY),
                          gradientColors,
                          [0.0, 0.5],
                          TileMode.clamp,
                      );
                      Paint gradientPaint = Paint()
                        ..shader = gradientShader
                        ..style = PaintingStyle.stroke
                        ..strokeWidth = strength
                        ..strokeCap = StrokeCap.butt;
                      if (!isDrawingSynapsesOnly) canvas.drawPath(path, gradientPaint);
                  } else {
                      if (!isDrawingSynapsesOnly) canvas.drawPath(path, blackBrush);
                  }
                  
                  // Draw Triangle (Second Level) - White fill + black stroke
                  blackBrush.strokeWidth = 1.5;
                  blackBrush.style = PaintingStyle.stroke;
                  Path triPath = Path();
                  triPath.moveTo(xt, yt);
                  triPath.lineTo(xBaseLeft, yBaseLeft);
                  triPath.lineTo(xBaseRight, yBaseRight);
                  triPath.close();
                  if (isDrawingSynapsesOnly) {
                    canvas.drawPath(triPath, synapseFill);
                    canvas.drawPath(triPath, blackBrush);
                  }

               } else {
                  // Inhibitory (Second Level) - Fixed 5px radius with offset
                  double radius = 5.0;
                  
                  // Dendrite position
                  double xcent = xc;
                  double ycent = yc;
                  
                  // Angle from Neuron Center to Dendrite (Outward)
                  double angleOut = atan2(ycent - neuronTo.y, xcent - neuronTo.x);
                  
                  // V25: Offset stacked synapses so they peek out from behind each other
                  double stackOffset = sinindex * 6.0;
                  xcent += stackOffset * cos(angleOut);
                  ycent += stackOffset * sin(angleOut);
                  
                  // New Center = Dendrite + Radius * Vector (offset outward)
                  double xc_syn = xcent + radius * cos(angleOut);
                  double yc_syn = ycent + radius * sin(angleOut);
                  
                  blackBrush.strokeWidth = strength;
                  blackBrush.style = PaintingStyle.stroke;
                  
                  // Control point logic
                  double bFactor = (1.0 + sqrt((centerBeginAxon_x - xc_syn)*(centerBeginAxon_x - xc_syn) + (centerBeginAxon_y - yc_syn)*(centerBeginAxon_y - yc_syn)) / 200.0);
                  double controlX = xc_syn + bFactor * (xc_syn - neuronTo.x) * 0.5;
                  double controlY = yc_syn + bFactor * (yc_syn - neuronTo.y) * 0.5;
                  
                  Path clickPath = Path();
                  clickPath.moveTo(centerBeginAxon_x, centerBeginAxon_y);
                  clickPath.cubicTo(centerEndAxon_x, centerEndAxon_y, controlX, controlY, xc_syn, yc_syn);
                  String pathKey = "${from.key.toString()}_${to.key.toString()}";
                  int pHash = Object.hash(centerBeginAxon_x, centerBeginAxon_y, centerEndAxon_x, centerEndAxon_y, controlX, controlY, xc_syn, yc_syn);
                  if (controller.axonPathHashes[pathKey] != pHash || !controller.axonPathMap.containsKey(pathKey)) {
                      controller.axonPathMap[pathKey] = getOutlinePath(clickPath, widthClickMask);
                      controller.axonPathHashes[pathKey] = pHash;
                  }
                  
                  Path path = Path();
                  path.moveTo(centerBeginAxon_x, centerBeginAxon_y);
                  path.cubicTo(centerEndAxon_x, centerEndAxon_y, controlX, controlY, xc_syn, yc_syn);
                  
                  // V25: Draw highlight ONLY in highlight pass
                  if (isSelected && isHighlightPass) {
                    Paint highlightPaint = Paint()
                      ..color = const Color(0xFFFD8164)
                      ..style = PaintingStyle.stroke
                      ..strokeWidth = 17.0
                      ..strokeCap = StrokeCap.round;
                    canvas.drawPath(path, highlightPaint);
                    Paint circleHighlight = Paint()
                      ..color = const Color(0xFFFD8164)
                      ..style = PaintingStyle.fill;
                    canvas.drawCircle(Offset(xc_syn, yc_syn), radius + 4.0, circleHighlight);
                  }
                  
                  if (isHighlightPass) {
                    return;
                  }
                  
                  // STRUCTURE PASS: Draw main elements (no highlights)
                  // edgeColor is now passed as a parameter.
                  
                  if (edgeColor != null && edgeColor != Colors.black) {
                      List<Color> gradientColors = [edgeColor, Colors.black];
                      bool isSourceLed = controller.syntheticNeuronList[fromIdx].node.value >= 4 ||
                                         (controller.syntheticNeuronList[fromIdx].node.label ?? "").toLowerCase().contains("led");
                      if (isSourceLed) {
                          gradientColors = [Colors.black, edgeColor];
                      }
                      
                      final Shader gradientShader = ui.Gradient.linear(
                          Offset(centerBeginAxon_x, centerBeginAxon_y),
                          Offset(xc_syn, yc_syn),
                          gradientColors,
                          [0.0, 0.5],
                          TileMode.clamp,
                      );
                      Paint gradientPaint = Paint()
                        ..shader = gradientShader
                        ..style = PaintingStyle.stroke
                        ..strokeWidth = strength
                        ..strokeCap = StrokeCap.butt;
                      if (!isDrawingSynapsesOnly) canvas.drawPath(path, gradientPaint);
                  } else {
                      if (!isDrawingSynapsesOnly) canvas.drawPath(path, blackBrush);
                  }
                  
                  // Draw Circle Synapse (Second Level) - Black outer (5px) + white inner (3.5px)
                  blackBrush.style = PaintingStyle.fill;
                  if (isDrawingSynapsesOnly) {
                    canvas.drawCircle(Offset(xc_syn, yc_syn), radius, blackBrush);
                    canvas.drawCircle(Offset(xc_syn, yc_syn), radius - 1.5, synapseFill);
                  }
               }
               
               // V25: Sensory Axon Icons (Second Level - Injected)
               // This logic was missing from Loop 2!
               if (!isHighlightPass) {
                    try {
                      String? iconText;
                      Color iconTextColor = Colors.black;
                      double iconSize = 18; 
                      
                      String rawKey = "${from.key}_${to.key}";
                      String fromIdClean = from.key.toString().replaceAll(RegExp(r"[\[\]<'>#]"), "");
                      String toIdClean = to.key.toString().replaceAll(RegExp(r"[\[\]<'>#]"), "");
                      String cleanKey = "${fromIdClean}_${toIdClean}";
                      
                      String fromLabel = (from.label ?? "").toLowerCase();
                      String toLabel = (to.label ?? "").toLowerCase();
                      
                      // Robust Detection: Check Value + isSensory (Labels are often null, IDs are hashes)
                      // 0=Distance, 1=LeftEye, 2=RightEye, 3=Mic, 4=Speaker
                      bool isMic = (from.isSensory == 1 && from.value == 3) || fromLabel.contains("mic") || fromLabel.contains("microphone");
                      bool isSpeaker = (to.isSensory == 1 && to.value == 4) || toLabel.contains("speaker");
                      bool isCamera = (from.isSensory == 1 && (from.value == 1 || from.value == 2)) || fromLabel.contains("eye") || fromLabel.contains("camera");
                      bool isDistance = (from.isSensory == 1 && from.value == 0) || fromLabel.contains("distance");

                      // DEBUG MIC LOGIC LOOP 2 (UNCONDITIONAL)
                      // if (isMic) {
                         // print("CheckIcon Loop2: from=$fromLabel ID=$fromIdClean to=$toLabel");
                      // }
                      
                      bool drawColoredCircle = false;
                      Color circleColor = Colors.transparent;
                      String fontFamily = "NotoEmoji"; 
                      double iconRadius = 12.5;

                      // 1. Camera
                      if (isCamera) {
                         if (controller.mapSensoryNeuron != null) {
                              int? idx;
                              if (controller.mapSensoryNeuron.containsKey(rawKey)) idx = (controller.mapSensoryNeuron[rawKey] as num?)?.toInt();
                              else if (controller.mapSensoryNeuron.containsKey(cleanKey)) idx = (controller.mapSensoryNeuron[cleanKey] as num?)?.toInt();
                              
                              if (idx != null) {
                                  List<String> cameraMenuTypes = ["Blue","Blue (side)","Green","Green (side)","Red","Red (side)","Movement","person","backpack","bottle","cup","bowl","banana","apple","orange","chair","couch","potted plant","laptop","cell phone","book","vase","dog","cat","tv","mouse","keyboard","scissors","donut","pizza","hot dog"];
                                  Map<String, String> lookup = {"person": "🧍", "backpack": "🎒", "bottle": "🧴", "cup": "☕", "bowl": "🥣", "banana": "🍌", "apple": "🍎", "orange": "🍊", "chair": "🪑", "couch": "🛋️", "potted plant": "🪴", "laptop": "💻", "cell phone": "📱", "book": "📒", "vase": "🏺", "Movement": "🏃", "dog": "🐕", "cat": "🐈", "tv": "📺", "mouse": "🐁", "keyboard": "⌨️", "scissors": "✂️", "donut": "🍩", "pizza": "🍕", "hot dog": "🌭"};
                                  if (idx >= 0 && idx < cameraMenuTypes.length) {
                                      String type = cameraMenuTypes[idx];
                                      if (lookup.containsKey(type)) { iconText = lookup[type]; fontFamily = "NotoEmoji"; }
                                      else if (type.contains("Blue")) { drawColoredCircle = true; circleColor = Colors.blue; }
                                      else if (type.contains("Green")) { drawColoredCircle = true; circleColor = Colors.green; }
                                      else if (type.contains("Red")) { drawColoredCircle = true; circleColor = Colors.red; }
                                  }
                              }
                         }
                      }
                      
                      // 2. Distance
                      if (iconText == null && !drawColoredCircle && (isDistance) && controller.mapDistanceNeuron != null) {
                          int? idx;
                          if (controller.mapDistanceNeuron.containsKey(rawKey)) idx = (controller.mapDistanceNeuron[rawKey] as num?)?.toInt();
                          else if (controller.mapDistanceNeuron.containsKey(cleanKey)) idx = (controller.mapDistanceNeuron[cleanKey] as num?)?.toInt();
                          if (idx != null) {
                              List<String> distEmojis = ["🛑", "⚠️", "🏁", "📏"];
                              if (idx >= 0 && idx < distEmojis.length) { iconText = distEmojis[idx]; fontFamily = "NotoEmoji"; iconSize = 20; }
                          }
                      }
                      
                      // 3. Microphone
                      if (iconText == null && !drawColoredCircle && (isMic || (controller.mapMicrophoneTypeNeuron != null && (controller.mapMicrophoneTypeNeuron.containsKey(rawKey) || controller.mapMicrophoneTypeNeuron.containsKey(cleanKey))))) {
                          int? mode;
                          if (controller.mapMicrophoneTypeNeuron != null) {
                              if (controller.mapMicrophoneTypeNeuron.containsKey(rawKey)) mode = (controller.mapMicrophoneTypeNeuron[rawKey] as num?)?.toInt();
                              else if (controller.mapMicrophoneTypeNeuron.containsKey(cleanKey)) mode = (controller.mapMicrophoneTypeNeuron[cleanKey] as num?)?.toInt();
                          }
                          if (mode == null) mode = 0; // Default
                          if (mode != null) {
                              if (mode == 1) { iconText = "🔊"; iconSize = 20; fontFamily = "NotoEmoji"; }
                              else if (mode == 2) { 
                                  // Piano Note Logic: Decode from mapMicrophoneLimitNeuron string "min_@_max"
                                  // In Tone mode, Min holds the note index (0-11).
                                  int noteIndex = 0;
                                  String? limitStr;
                                  if (controller.mapMicrophoneLimitNeuron.containsKey(rawKey)) limitStr = controller.mapMicrophoneLimitNeuron[rawKey];
                                  else if (controller.mapMicrophoneLimitNeuron.containsKey(cleanKey)) limitStr = controller.mapMicrophoneLimitNeuron[cleanKey];
                                  
                                  if (limitStr != null) {
                                      List<String> parts = limitStr.split("_@_");
                                      if (parts.isNotEmpty) {
                                          noteIndex = int.tryParse(parts[0]) ?? 0;
                                      }
                                  }

                                  List<String> notes = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"];
                                  int safeIdx = noteIndex % 12;
                                  if (safeIdx < notes.length) {
                                      iconText = notes[safeIdx];
                                      fontFamily = "BybHanddrawn";
                                      iconSize = 18;
                                  } else {
                                      iconText = "🎹";
                                      fontFamily = "NotoEmoji";
                                      iconSize = 20;
                                  }
                              }
                              else { iconText = "〰️"; iconSize = 20; fontFamily = "NotoEmoji"; }
                          }
                      }
                      
                      // 4. Speaker
                      if (iconText == null && !drawColoredCircle && (isSpeaker) && controller.mapSpeakerNeuron != null) {
                          double? freq;
                          if (controller.mapSpeakerNeuron.containsKey(rawKey)) freq = (controller.mapSpeakerNeuron[rawKey] as num?)?.toDouble();
                          else if (controller.mapSpeakerNeuron.containsKey(cleanKey)) freq = (controller.mapSpeakerNeuron[cleanKey] as num?)?.toDouble();
                          if (freq != null) {
                              int f = freq.toInt();
                              if (f >= 31 && f <= 40) {
                                  Map<int, String> voiceEmojis = {31:"👋",32:"🫢",33:"👍",34:"🤔",35:"😴",36:"🍰",37:"🤠",38:"🐕",39:"🐱",40:"✨"};
                                  if (voiceEmojis.containsKey(f)) { iconText = voiceEmojis[f]; fontFamily = "NotoEmoji"; }
                              } else if (f >= 70) {
                                  List<int> bases = [128, 228, 328, 428];
                                  int? bestBase;
                                  for (int b in bases) { if (f >= b && f < b + 24) { bestBase = b; break; } }
                                  if (bestBase != null) {
                                      List<String> notes = ["C","C#","D","D#","E","F","F#","G","G#","A","A#","B"];
                                      int noteIdx = (f - bestBase) % 12;
                                      if (noteIdx < notes.length) { iconText = notes[noteIdx]; fontFamily = "BybHanddrawn"; iconSize = 18; }
                                  } else { iconText = "🎵"; fontFamily = "NotoEmoji"; }
                              }
                          }
                      }

                      if (iconText != null || drawColoredCircle) {
                          double angle = neuronTo.dendrites[posin].angle;
                          double distToSynapse = euclideanDistance(centerBeginAxon_x, centerBeginAxon_y, xc, yc);
                          
                          // V25: Uniform 34px spacing visual gap
                          // V25: Uniform 34px spacing visual gap
                          // 1. Calculate Control Points FIRST to determine Tangent Length at Tip
                          double controlX, controlY;
                          double tangentLength = 1.0;
                          
                          if (isExcitatory == 1) {
                              // Re-calculate Triangle Tip (xt) for Excitatory with Stack Offset
                              double triangleSize = 10.0;
                              double stackOffset = sinindex * 6.0; // V25: Excitatory stack offset
                              
                              double angleOut = atan2(yc - neuronTo.y, xc - neuronTo.x);
                              
                              double xc_stack = xc + stackOffset * cos(angleOut);
                              double yc_stack = yc + stackOffset * sin(angleOut);
                              
                              double xt = xc_stack + triangleSize * cos(angleOut);
                              double yt = yc_stack + triangleSize * sin(angleOut);
                              
                              double bFactor = (1.0 + sqrt((centerBeginAxon_x - xt)*(centerBeginAxon_x - xt) + (centerBeginAxon_y - yt)*(centerBeginAxon_y - yt)) / 200.0);
                              controlX = xt + bFactor * (xt - neuronTo.x) * 0.5;
                              controlY = yt + bFactor * (yt - neuronTo.y) * 0.5;

                              // Distance P2 to P3 (Tip)
                              double dx = xt - controlX;
                              double dy = yt - controlY;
                              double distP2P3 = sqrt(dx*dx + dy*dy);
                              tangentLength = 3.0 * distP2P3;
                          } else {
                              // Inhibitory: Use Circle Center for bFactor with Stack Offset
                              double radius = 5.0;
                              double stackOffset = sinindex * 6.0; // V25: Inhibitory stack offset outward
                              
                              double angleOut = atan2(yc - neuronTo.y, xc - neuronTo.x);
                              
                              double xc_stack = xc + stackOffset * cos(angleOut);
                              double yc_stack = yc + stackOffset * sin(angleOut);
                              
                              double xc_syn = xc_stack + radius * cos(angleOut);
                              double yc_syn = yc_stack + radius * sin(angleOut);
                              
                              double bFactor = (1.0 + sqrt((centerBeginAxon_x - xc_syn)*(centerBeginAxon_x - xc_syn) + (centerBeginAxon_y - yc_syn)*(centerBeginAxon_y - yc_syn)) / 200.0);
                              controlX = xc_syn + bFactor * (xc_syn - neuronTo.x) * 0.5;
                              controlY = yc_syn + bFactor * (yc_syn - neuronTo.y) * 0.5;

                              // Distance P2 to P3 (Center of circle)
                              double dx = xc_syn - controlX;
                              double dy = yc_syn - controlY;
                              double distP2P3 = sqrt(dx*dx + dy*dy);
                              tangentLength = 3.0 * distP2P3;
                          }

                          // 2. Calculate T for Icon Placement
                          // V25Fix: Place icon exactly at the midpoint of the final axon segment
                          double t = 0.5;

                          // V25: Fix Loop 2 Far Dendrite Centering
                          // Replicate initialAxonExtension logic to ensure p1 matches Drawn Path
                          double centerEndAxon_x = centerBeginAxon_x; // Start from axon origin
                          double centerEndAxon_y = centerBeginAxon_y;
                          
                          double initialAxonExtensionSize = 0.5; // Must match Loop 2 const
                          // Replicate logic from lines ~2018
                          if (branchDirection != null) {
                             double extensionLength = min(max(distToSynapse * 0.4, 20.0), 100.0);
                             centerEndAxon_x = centerBeginAxon_x + branchDirection.dx * extensionLength;
                             centerEndAxon_y = centerBeginAxon_y + branchDirection.dy * extensionLength;
                          } else {
                             double extensionLength = min(max(distToSynapse * 0.3, 20.0), 100.0);
                             Offset directionToTarget = Offset(xc - centerBeginAxon_x, yc - centerBeginAxon_y);
                             if (directionToTarget.distance > 0) directionToTarget = directionToTarget / directionToTarget.distance;
                             centerEndAxon_x = centerBeginAxon_x + directionToTarget.dx * extensionLength;
                             centerEndAxon_y = centerBeginAxon_y + directionToTarget.dy * extensionLength;
                          }

                          double u = 1 - t;
                          double tt = t * t; double uu = u * u; double uuu = uu * u; double ttt = tt * t;
                          Offset p0 = Offset(centerBeginAxon_x, centerBeginAxon_y);
                          Offset p1 = Offset(centerEndAxon_x, centerEndAxon_y);
                          Offset p2 = Offset(controlX, controlY);


                          // Recalculate Target for Icon Placement
                          // If Excitatory (Triangle): Use Centroid
                          // If Inhibitory (Circle/Default): Use Synapse Center
                          Offset p3;
                          if (isExcitatory == 1) {
                              // Re-calculate Triangle Geometry with Stacking Offset
                              double triangleSize = 10.0;
                              double stackOffset = sinindex * 6.0; // V25: Excitatory stack offset
                              
                              double angleOut = atan2(yc - neuronTo.y, xc - neuronTo.x);
                              
                              // Apply offset to base coordinate FIRST
                              double xc_stack = xc + stackOffset * cos(angleOut);
                              double yc_stack = yc + stackOffset * sin(angleOut);
                              
                              double xt = xc_stack + triangleSize * cos(angleOut);
                              double yt = yc_stack + triangleSize * sin(angleOut);
                              double halfBase = triangleSize / sqrt(3); 
                              double xBaseLeft = xc_stack + halfBase * cos(angleOut - pi/2); 
                              double xBaseRight = xc_stack + halfBase * cos(angleOut + pi/2);
                              double yBaseLeft = yc_stack + halfBase * sin(angleOut - pi/2);
                              double yBaseRight = yc_stack + halfBase * sin(angleOut + pi/2);
                              
                              double triCenterX = (xt + xBaseLeft + xBaseRight) / 3;
                              double triCenterY = (yt + yBaseLeft + yBaseRight) / 3;
                              p3 = Offset(triCenterX, triCenterY);
                          } else {
                              // Inhibitory: Target is the Circle Center (xc_syn, yc_syn) calculated earlier
                              // Re-calc with stack offset
                              double radius = 5.0;
                              double stackOffset = sinindex * 6.0; // V25: Inhibitory stack offset outward
                              
                              double angleOut = atan2(yc - neuronTo.y, xc - neuronTo.x);
                              
                              double xc_stack = xc + stackOffset * cos(angleOut);
                              double yc_stack = yc + stackOffset * sin(angleOut);
                              
                              double xc_syn = xc_stack + radius * cos(angleOut);
                              double yc_syn = yc_stack + radius * sin(angleOut);
                              p3 = Offset(xc_syn, yc_syn);
                          }

                          double bx = uuu * p0.dx + 3 * uu * t * p1.dx + 3 * u * tt * p2.dx + ttt * p3.dx;
                          double by = uuu * p0.dy + 3 * uu * t * p1.dy + 3 * u * tt * p2.dy + ttt * p3.dy;
                          Offset iconPos = Offset(bx, by);

                          // V25: Radius 12.5 (25px Diameter)
                          canvas.drawCircle(iconPos + const Offset(1,1), iconRadius, Paint()..color = Colors.black.withOpacity(0.3));
                          canvas.drawCircle(iconPos, iconRadius, Paint()..color = Colors.white..style = PaintingStyle.fill);
                          
                          if (drawColoredCircle) {
                              canvas.drawCircle(iconPos, iconRadius - 2, Paint()..color = circleColor..style = PaintingStyle.fill);
                              canvas.drawCircle(iconPos, iconRadius, Paint()..color = Colors.grey.withOpacity(0.5)..style = PaintingStyle.stroke..strokeWidth=1);
                          } else {
                              canvas.drawCircle(iconPos, iconRadius, Paint()..color = Colors.grey.withOpacity(0.5)..style = PaintingStyle.stroke..strokeWidth=1);
                              
                              // V25: TextPainter Cache Optimization
                              String cacheKey = "icon_${iconText}_${fontFamily}_$iconSize";
                              TextPainter? tp = controller.textPainterCache[cacheKey];
                              
                              if (tp == null) {
                                  TextSpan span = TextSpan(style: TextStyle(color: iconTextColor, fontSize: iconSize, fontFamily: fontFamily), text: iconText);
                                  tp = TextPainter(text: span, textAlign: TextAlign.center, textDirection: TextDirection.ltr);
                                  tp.layout();
                                  controller.textPainterCache[cacheKey] = tp;
                              }
                              
                              tp.paint(canvas, iconPos - Offset(tp.width / 2, tp.height / 2));
                          }
                      }
                    } catch (e) {
                        print("Error in Loop 2 Icon Logic: $e");
                    }
               }
           }
         }
      }
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
        syntheticNeuronList[neuronIdx].dendrites.clear();

        int dendriteIdx = 0;
        for (Dendrite rawDendrite in rawSyntheticNeuron.dendrites) {
          Dendrite newDendrite = Dendrite(
              hasSecondLevel: rawDendrite.hasSecondLevel,
              angle: rawDendrite.angle,
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
          syntheticNeuronList[neuronIdx].dendrites.add(newDendrite);
          dendriteIdx++;
        }
      }
      syntheticNeuronList[neuronIdx].recalculate(null);

      neuronIdx++;
    }
    return syntheticNeuronList;
  }

  void addSyntheticConnection(
      LocalKey axonFrom, LocalKey axonTo, double connectionStrength) {
    Map<String, String> neuronTypes = controller.neuronTypes;
    List<SyntheticNeuron> syntheticNeuronList = controller.syntheticNeuronList;
    // we must use the default raw neuron to get the initial state of the neuron
    List<SyntheticNeuron> syntheticNeurons =
        copyFromRawSynthetics(syntheticNeuronList);
    syntheticNeuronList = syntheticNeurons;

    int fromIdx = findSyntheticNeuronIdx(axonFrom.toString(), syntheticNeurons);
    //neuronTypes.keys.toList().indexOf(axonFrom.toString());
    int toIdx = findSyntheticNeuronIdx(axonTo.toString(), syntheticNeurons);
    // neuronTypes.keys.toList().indexOf(axonTo.toString());
    final nodeFrom =
        controller.nodes.firstWhere((node) => node.key == axonFrom);
    // final nodeTo = controller.nodes.firstWhere((node) => node.key == axonTo);
    double circleRadius = nodeFrom.syntheticNeuron.circleRadius;

    int isExcitatory = nodeFrom.isExcitatory;

    controller.syntheticConnections.add(
        Connection(axonFrom, axonTo, connectionStrength, Path(), isExcitatory));
    // print("Add Synthetic Connection ${controller.syntheticConnections.length}");
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
      for (Connection con in controller.syntheticConnections) {
        int fromNeuronIdx = findSyntheticNeuronIdx(
            con.neuronIndex1.toString(), syntheticNeurons);
        // neuronTypes.keys.toList().indexOf(con.neuronIndex1.toString());
        int toNeuronIdx = findSyntheticNeuronIdx(
            con.neuronIndex2.toString(), syntheticNeurons);
        // neuronTypes.keys.toList().indexOf(con.neuronIndex2.toString());
        if (fromNeuronIdx == i) {
          hasAxon = true;
          averageX +=
              (syntheticNeurons[toNeuronIdx].newNeuron.x - circleRadius);
          averageY +=
              (syntheticNeurons[toNeuronIdx].newNeuron.y - circleRadius);
          numberofConnections = numberofConnections + 1;
          // print(
          //     "Connection ${con.neuronIndex1} $i == $fromNeuronIdx NewNeuronX:${syntheticNeurons[toNeuronIdx].newNeuron.x} NewNeuronY:${syntheticNeurons[toNeuronIdx].newNeuron.y} $numberofConnections $averageX, $averageY");
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

        // V25: Set BOTH axonAngle and baseAxonAngle to the dendrite's angle
        // baseAxonAngle is the FIXED original position
        // axonAngle will update to track downstream, rotationDelta = axonAngle - baseAxonAngle
        syntheticRawNeuron.axonAngle =
            syntheticRawNeuron.dendrites[minDistanceIndex].angle;
        syntheticRawNeuron.baseAxonAngle =
            syntheticRawNeuron.dendrites[minDistanceIndex].angle;
        syntheticRawNeuron.dendriteIdx = minDistanceIndex;
        syntheticRawNeuron.xAxon =
            syntheticRawNeuron.dendrites[minDistanceIndex].xFirstLevel;
        syntheticRawNeuron.yAxon =
            syntheticRawNeuron.dendrites[minDistanceIndex].yFirstLevel;
        // print("remove how many times? $i - $minDistanceIndex");
        syntheticRawNeuron.dendrites.removeAt(minDistanceIndex);
      }
    }
    for (SyntheticNeuron syntheticNeuron in syntheticNeuronList) {
      syntheticNeuron.recalculate(null);
    }
    createSyntheticAxon2(syntheticNeurons, fromIdx, toIdx, 50 / 2);
  }

  void createSyntheticAxon2(List<SyntheticNeuron> syntheticNeurons,
      int pfromIdx, int ptoIdx, double d) {
    List<SyntheticNeuron> neurons = syntheticNeurons;
    List<Connection> connections = controller.syntheticConnections;
    // print("connections");
    // print(connections);
    for (int i = 0; i < neurons.length; i++) {
      for (Connection con in connections) {
        int fromIdx = findSyntheticNeuronIdx(
            con.neuronIndex1.toString(), syntheticNeurons);
        // controller.neuronTypes.keys
        //     .toList()
        //     .indexOf(con.neuronIndex1.toString());
        int toIdx = findSyntheticNeuronIdx(
            con.neuronIndex2.toString(), syntheticNeurons);
        // print("con.neuronIndex1.toString()");
        // print(con.neuronIndex1.toString());
        // print(con.neuronIndex2.toString());
        // print(fromIdx);
        // print(toIdx);

        // controller.neuronTypes.keys
        //     .toList()
        //     .indexOf(con.neuronIndex2.toString());
        // if (fromIdx == -1 || toIdx == -1) {
        //   print("neuron");
        //   print(controller.neuronTypes.keys.toList().toString());
        //   print(con.neuronIndex1.toString());
        //   print(con.neuronIndex2.toString());
        // }

        // if (neurons.length <= toIdx || neurons.length <= fromIdx) return;
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
            // print(
            //     "${dendriteIndex} : ${distance} ${neuronFrom.xCenterOfConnections}, ${neuronFrom.yCenterOfConnections}, SecondLevel: ${neuronTo.dendrites[dendriteIndex].xSecondLevel + neuronTo.x}, ${neuronTo.dendrites[dendriteIndex].ySecondLevel + neuronTo.y} - ${neuronTo.dendrites[dendriteIndex].hasSecondLevel} ${neuronTo.dendrites[dendriteIndex].hasSecondLevel} isFirstLevel false");
          }
          distancesToSinapses.sort((a, b) => a.distance.compareTo(b.distance));
          // print("distancesToSinapses ${distancesToSinapses.length}");
          // for (var sinapse in distancesToSinapses) {
          //   print(
          //       " $fromIdx @ $toIdx-- ${sinapse.dendriteIndex} : ${sinapse.distance} ${sinapse.isFirstLevel} == ${neuronFrom.x}|${neuronFrom.y} __ ${neuronTo.x}|${neuronTo.y}");
          // }

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

  Path getOutlinePath(Path path, double thickness) {
    Path outlinePath = Path();
    for (ui.PathMetric pathMetric in path.computeMetrics()) {
      for (double distance = 0.0;
          distance < pathMetric.length;
          distance += 1.0) {
        ui.Tangent? tangent = pathMetric.getTangentForOffset(distance);
        if (tangent != null) {
          // Create a rectangle path to simulate thickness
          Rect rect = Rect.fromCenter(
            center: tangent.position,
            width: thickness,
            height: thickness,
          );
          outlinePath.addRect(rect);
        }
      }
    }
    outlinePath.close();
    return outlinePath;
  }

  int findSyntheticNeuronIdx(
      String key, List<SyntheticNeuron> syntheticNeurons) {
    int len = syntheticNeurons.length;
    for (int i = 0; i < len; i++) {
      if (syntheticNeurons[i].node.id == key) {
        return i;
      }
    }
    return -1;
  }
}
