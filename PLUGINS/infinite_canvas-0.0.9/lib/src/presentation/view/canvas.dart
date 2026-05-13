import 'package:spikerbot/utils/platform_imports.dart';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:infinite_canvas/src/domain/model/drop_target.dart';
import 'package:infinite_canvas/src/presentation/widgets/droptargets_renderer.dart';
import 'package:infinite_canvas/src/presentation/widgets/nucleus.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;

import '../widgets/delegate.dart';
import '../../domain/model/node.dart';
import '../../domain/model/edge.dart';
import '../widgets/edge_renderer.dart';
import '../widgets/synapse_renderer.dart';
import '../state/controller.dart';
import '../widgets/grid_background.dart';
import '../widgets/marquee.dart';
import '../../domain/model/menu_entry.dart';
import '../widgets/menus.dart';
import '../widgets/node_renderer.dart';
import '../widgets/annotation_edge_highlighter.dart';

/// A Widget that renders a canvas that can be
/// panned and zoomed.
///
/// This can not be shrink wrapped, so it should be used
/// as a full screen / expanded widget.
class InfiniteCanvas extends StatefulWidget {
  const InfiniteCanvas(
      {super.key,
      required this.controller,
      this.gridSize = const Size.square(50),
      this.menuVisible = true,
      this.menus = const [],
      this.activeComponent,
      this.backgroundBuilder,
      this.drawVisibleOnly = false,
      this.canAddEdges = false,
      this.edgesUseStraightLines = false});

  final InfiniteCanvasController controller;
  final Size gridSize;
  final bool menuVisible;
  final List<MenuEntry> menus;
  final bool drawVisibleOnly;
  final bool canAddEdges;
  final bool edgesUseStraightLines;
  final Widget Function(BuildContext, Rect)? backgroundBuilder;
  final Widget Function(BuildContext, Rect)? activeComponent;

  @override
  State<InfiniteCanvas> createState() => InfiniteCanvasState();
}

class InfiniteCanvasState extends State<InfiniteCanvas> {
  int lastPointerDownTime = 0;

  Duration holdDuration = const Duration(milliseconds: 1000);

  late Future longPressFuture;

  int firstTapTime = 0;
  int secondTapTime = 0;

  late Positioned edgesWidget;
  Widget? dropTargetsWidget;
  
  // V25 FEATURE: Right Click Panning State
  Offset? _rightClickDragStart;
  Matrix4? _rightClickTransformStart;

  @override
  void initState() {
    super.initState();
    controller.addListener(onUpdate);
    controller.focusNode.requestFocus();
  }

  @override
  void dispose() {
    controller.removeListener(onUpdate);
    // BUGFIX: Controller outlives this Widget State. 
    // Disposing the focusNode here ruins the persistence of the controller!
    // controller.focusNode.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant InfiniteCanvas oldWidget) {
    if (oldWidget.controller != controller) {
      oldWidget.controller.removeListener(onUpdate);
      controller.addListener(onUpdate);
    }
    if (oldWidget.menus != widget.menus ||
        oldWidget.menuVisible != widget.menuVisible ||
        oldWidget.canAddEdges != widget.canAddEdges ||
        oldWidget.drawVisibleOnly != widget.drawVisibleOnly) {
      if (mounted) setState(() {});
    }
    super.didUpdateWidget(oldWidget);
  }

  void onUpdate() {
    // During camera animation, skip the rebuild — simulation callbacks and
    // edge-colour updates would otherwise force a full canvas repaint (all
    // axon Bezier paths) on every frame, causing visible stutter.
    // _animateCanvasToReset's .then() calls notifyListeners() once on
    // completion, so everything syncs the moment the pan finishes.
    if (controller.isAnimatingCamera) return;
    if (mounted) setState(() {});
  }

  InfiniteCanvasController get controller => widget.controller;

  Rect axisAlignedBoundingBox(Quad quad) {
    double xMin = quad.point0.x;
    double xMax = quad.point0.x;
    double yMin = quad.point0.y;
    double yMax = quad.point0.y;

    for (final Vector3 point in <Vector3>[
      quad.point1,
      quad.point2,
      quad.point3,
    ]) {
      if (point.x < xMin) {
        xMin = point.x;
      } else if (point.x > xMax) {
        xMax = point.x;
      }

      if (point.y < yMin) {
        yMin = point.y;
      } else if (point.y > yMax) {
        yMax = point.y;
      }
    }

    return Rect.fromLTRB(xMin, yMin, xMax, yMax);
  }

  Widget buildBackground(BuildContext context, Quad quad) {
    final viewport = axisAlignedBoundingBox(quad);
    if (widget.backgroundBuilder != null) {
      return widget.backgroundBuilder!(context, viewport);
    }
    return GridBackgroundBuilder(
      cellWidth: widget.gridSize.width,
      cellHeight: widget.gridSize.height,
      viewport: viewport,
    );
  }

  Widget buildActiveComponent(BuildContext context, Quad quad) {
    final viewport = axisAlignedBoundingBox(quad);
    if (widget.activeComponent != null) {
      return widget.activeComponent!(context, viewport);
    }
    return GridBackgroundBuilder(
      cellWidth: widget.gridSize.width,
      cellHeight: widget.gridSize.height,
      viewport: viewport,
    );
  }

  List<InfiniteCanvasNode> getNodes(BoxConstraints constraints) {
    if (widget.drawVisibleOnly) {
      final nodes = <InfiniteCanvasNode>[];
      final viewport = controller.getRect(constraints);
      for (final node in controller.nodes) {
        if (node.rect.overlaps(viewport)) {
          nodes.add(node);
        }
      }
      return nodes;
    }
    return controller.nodes;
  }

  List<InfiniteCanvasEdge> getEdges(BoxConstraints constraints) {
    if (widget.drawVisibleOnly) {
      final viewport = controller.getRect(constraints);
      final edges = <InfiniteCanvasEdge>[];
      
      // Build a map for O(1) node lookup
      final nodeMap = {for (var node in controller.nodes) node.key: node};

      for (final edge in controller.edges) {
        final fromNode = nodeMap[edge.from];
        final toNode = nodeMap[edge.to];
        
        if (fromNode != null && toNode != null) {
          // Calculate the expanded geometric bounding box of the axon
          // 150px padding ensures Bezier control points and tangents don't clip prematurely
          double minX = math.min(fromNode.rect.left, toNode.rect.left) - 150.0;
          double maxX = math.max(fromNode.rect.right, toNode.rect.right) + 150.0;
          double minY = math.min(fromNode.rect.top, toNode.rect.top) - 150.0;
          double maxY = math.max(fromNode.rect.bottom, toNode.rect.bottom) + 150.0;
          
          Rect edgeBounds = Rect.fromLTRB(minX, minY, maxX, maxY);
          
          if (edgeBounds.overlaps(viewport)) {
            edges.add(edge);
          }
        } else {
           // Fallback if node not found
           edges.add(edge);
        }
      }
      return edges;
    }
    return controller.edges;
  }

  @override
  Widget build(BuildContext context) {
    return Menus(
      controller: widget.controller,
      visible: widget.menuVisible,
      menus: widget.menus,
      child: KeyboardListener(
        focusNode: controller.focusNode,
        onKeyEvent: (event) {
          if (event is KeyDownEvent) {
            if (event.logicalKey == LogicalKeyboardKey.shiftLeft ||
                event.logicalKey == LogicalKeyboardKey.shiftRight) {
              // controller.shiftPressed = true;
            }
            if (event.logicalKey == LogicalKeyboardKey.controlLeft ||
                event.logicalKey == LogicalKeyboardKey.controlRight) {
              // controller.controlPressed = true;
            }
            if (event.logicalKey == LogicalKeyboardKey.metaLeft ||
                event.logicalKey == LogicalKeyboardKey.metaRight) {
              // controller.metaPressed = true;
            }
            if (event.logicalKey == LogicalKeyboardKey.space) {
              // controller.spacePressed = true;
            }
          }
          if (event is KeyUpEvent) {
            if (event.logicalKey == LogicalKeyboardKey.shiftLeft ||
                event.logicalKey == LogicalKeyboardKey.shiftRight) {
              // controller.shiftPressed = false;
            }
            if (event.logicalKey == LogicalKeyboardKey.metaLeft ||
                event.logicalKey == LogicalKeyboardKey.metaRight) {
              // controller.metaPressed = false;
            }
            if (event.logicalKey == LogicalKeyboardKey.controlLeft ||
                event.logicalKey == LogicalKeyboardKey.controlRight) {
              // controller.controlPressed = false;
              // controller.linkStart = null;
              // controller.linkEnd = null;
            }
            if (event.logicalKey == LogicalKeyboardKey.space) {
              // controller.spacePressed = false;
            }
            if (event.logicalKey == LogicalKeyboardKey.delete ||
                event.logicalKey == LogicalKeyboardKey.backspace) {
              if (controller.focusNode.hasFocus) {
                controller.onDeleteCallback();
                // controller.deleteSelection();
              }
            }
          }
        },
        child: Listener(
          // Mouse scroll zoom: linear zoom anchored at cursor position.
          // InteractiveViewer's built-in handler uses math.exp(-dy/scaleFactor)
          // which feels unnatural (exponential rate, no cursor anchor correction).
          // We intercept mouse-kind scroll here and apply the standard "zoom at point"
          // matrix: translate-to-cursor → scale → translate-back.
          // Trackpad (kind==trackpad) scroll is handled by _globalScrollRoute for pan.
          onPointerSignal: (event) {
                  // Desktop only: mouse scroll wheel zoom anchored at cursor.
                  // iOS/Android don't have physical mouse scroll events.
                  if (Platform.isIOS || Platform.isAndroid) return;
                  if (event is PointerScrollEvent &&
                      event.kind == PointerDeviceKind.mouse) {
                    const double zoomStep = 0.12;
                    final double factor = event.scrollDelta.dy > 0
                        ? 1.0 - zoomStep
                        : 1.0 + zoomStep;
                    final double currentScale = controller.getScale();
                    final double newScale = (currentScale * factor)
                        .clamp(controller.minScale, controller.maxScale);
                    if (newScale == currentScale) return;
                    final double effectiveFactor = newScale / currentScale;
                    final Offset focal = event.localPosition;
                    final Matrix4 matrix = controller.transform.value.clone();
                    matrix.translate(focal.dx, focal.dy);
                    matrix.scale(effectiveFactor, effectiveFactor);
                    matrix.translate(-focal.dx, -focal.dy);
                    controller.transform.value = matrix;
                  }
                },
          onPointerDown: (details) {
            // Right-click / middle-click panning: record start position ONLY.
            // Do NOT set mouseDown=true — that would let InteractiveViewer treat
            // this pointer as a node-drag event and fight with our pan below.
            if (details.buttons == 2 || details.buttons == 4) {
                _rightClickDragStart = details.position;
                return;
            }

            // V25: ALWAYS check selection BEFORE setting mouseDown (which notifies listeners).
            controller.checkSelection(details.localPosition);

            // print("mouse down");
            // print(controller.scale);

            // BUGFIX: MUST set mousePosition before mouseDown, because mouseDown is a setter that calls notifyListeners(),
            // and the UI listeners rely on the new mousePosition!
            controller.mousePosition = details.localPosition;
            controller.mouseDown = true;

            // WEB: Set mouseDragStart here because InteractiveViewer's gesture
            // handling is disabled on web (both panEnabled and scaleEnabled are
            // false), so onInteractionStart won't set it.
            if (kIsWeb) {
              controller.mouseDragStart = details.localPosition;
            }
            
            // WEB CHANGE
            if (kIsWeb) {
            } else if (Platform.isAndroid || Platform.isIOS) {
              lastPointerDownTime = DateTime.now().millisecondsSinceEpoch;
              Future.delayed(holdDuration, () {
                if (lastPointerDownTime != 0 &&
                    (controller.hasSelection || controller.isSelectingEdge)) {
                  var curTimeStamp = DateTime.now().millisecondsSinceEpoch;
                  if (curTimeStamp - lastPointerDownTime >
                      holdDuration.inMilliseconds) {
                    controller.onLongPress.call();
                    return;
                  }
                }
                // firstTapTime = 0;
                // secondTapTime = 0;
              });
            }

            // controller.mousePosition = details.position;

            // CHANGE ME
            // try {
            // if (Platform.isIOS) {
            //   controller.checkSelection(details.localPosition);
            // } // } catch (err) {
            //   print(err);
            // }
            // if (controller.selection.isEmpty) {
            //   if (!controller.spacePressed) {
            //     controller.marqueeStart = details.localPosition;
            //     controller.marqueeEnd = details.localPosition;
            //   }
            // } else {
            if (controller.controlPressed && widget.canAddEdges) {
              final selected = controller.selection.last;
              controller.linkStart = selected.key;
              controller.linkEnd = null;
            }

            if (!controller.canvasMoveEnabled) {
              // print("123");
              // controller.transformNeuronPositionWrapper();
              // final mat = controller.transform.value.clone();
              // mat.scale(controller.scale, controller.scale);
              // mat.translate(0, 0);
              // controller.transform.value = mat;
              // controller.notifyMousePosition();
              // controller.zoomReset();
              // Future.delayed(Duration(milliseconds: 10), () {
              // controller.zoom(controller.scale);
              // });
              //   return;
            }
            // }
          },
          onPointerUp: (details) {
            // Always reset mouseDown regardless of which button was released.
            // Previously the right-click path returned early WITHOUT resetting mouseDown,
            // which caused it to get stuck = true — all subsequent 2-finger trackpad
            // events would hit moveSelection() instead of the pan branch.
            controller.mouseDown = false;

            // WEB: onInteractionEnd won't reliably fire (pan/scale disabled), so
            // clear mouseDragStart here to prevent stale drag origins.
            if (kIsWeb) {
              controller.mouseDragStart = null;
            }

            // Right-click / middle-click pan end — clear the flag.
            if (_rightClickDragStart != null) {
                _rightClickDragStart = null;
                _rightClickTransformStart = null;
                return;
            }

            // CHANGE ME
            // if (controller.marqueeStart != null &&
            //     controller.marqueeEnd != null) {
            //   controller.checkMarqueeSelection();
            // }

            // print("mouse UP");
            // WEB CHANGE
            // if (kIsWeb){

            // }else
            // if (Platform.isAndroid || Platform.isIOS) {
            //   var curTimeStamp = DateTime.now().millisecondsSinceEpoch;
            //   if (firstTapTime == 0) {
            //     firstTapTime = curTimeStamp;
            //     Future.delayed(holdDuration, () {
            //       firstTapTime = 0;
            //       secondTapTime = 0;
            //     });
            //   } else if (secondTapTime == 0) {
            //     secondTapTime = curTimeStamp;
            //   } else {
            //     if (secondTapTime - firstTapTime < 2000) {
            //       firstTapTime = 0;
            //       secondTapTime = 0;
            //       controller.onDoubleTap.call();
            //     }
            //     // firstTapTime = 0;
            //     // secondTapTime = 0;
            //   }
            //   lastPointerDownTime = 0;
            // }

            if (controller.linkStart != null && controller.linkEnd != null) {
              controller.checkSelection(controller.linkEnd!);
              if (controller.selection.isNotEmpty) {
                final selected = controller.selection.last;
                controller.addLink(controller.linkStart!, selected.key);
              }
            }
            controller.marqueeStart = null;
            controller.marqueeEnd = null;
            controller.linkStart = null;
            controller.linkEnd = null;
            if (!controller.canvasMoveEnabled) {
              // controller.transformNeuronPositionWrapper();
            }
          },
          onPointerCancel: (details) {
            controller.mouseDown = false;
            // print("Pointer Cancel");
          },
          onPointerHover: (details) {
            controller.mousePosition = details.localPosition;
            // STEVANUS : Optimize?
            // controller.checkSelection(controller.mousePosition, true);
          },
          onPointerMove: (details) {
            // Right-click / middle-click pan: directly update the TransformationController
            // value WITHOUT calling controller.notifyListeners(). This mirrors exactly how
            // InteractiveViewer handles 2-finger trackpad pan internally — transform.value
            // schedules a display-sync repaint while leaving the ChangeNotifier chain quiet.
            if (_rightClickDragStart != null) {
                final double scale = controller.getScale();
                final Matrix4 matrix = controller.transform.value.clone();
                matrix.translate(details.delta.dx / scale, details.delta.dy / scale);
                controller.transform.value = matrix; // display-sync, no notifyListeners
                return;
            }

            lastPointerDownTime = 0;
            firstTapTime = 0;
            secondTapTime = 0;

            // WEB: Handle ALL pointer-move gestures here instead of through
            // InteractiveViewer. IV's gesture arena on Chrome causes pan+zoom
            // conflicts, neuron lag, and stuck drag states. By handling pan and
            // neuron drag directly in the Listener, we get clean 1:1 behavior.
            // Native (iOS/macOS) is unaffected — it uses IV's onInteractionUpdate.
            if (kIsWeb && controller.mouseDown) {
              if (controller.linkStart != null) {
                // Drawing a connection line
                controller.linkEnd = details.localPosition;
                controller.checkSelection(controller.linkEnd!, true);
              } else if (controller.controlPressed) {
                // Ctrl+drag = draw edge, no move
              } else if (controller.hasSelection && !controller.lockNodeDragging) {
                // Drag selected neuron(s) — use localPosition to match
                // the coordinate space of mouseDragStart.
                controller.moveSelection(details.localPosition);
              } else if (controller.canvasMoveEnabled) {
                // Pan canvas — translate by pointer delta in canvas coords
                final double scale = controller.getScale();
                final Matrix4 matrix = controller.transform.value.clone();
                matrix.translate(details.delta.dx / scale, details.delta.dy / scale);
                controller.transform.value = matrix;
              }
              controller.mousePosition = details.localPosition;
              return;
            }

            // CHANGE ME
            // controller.marqueeEnd = details.localPosition;
            // if (controller.marqueeStart != null &&
            //     controller.marqueeEnd != null) {
            //   controller.checkMarqueeSelection(true);
            // }
            if (controller.linkStart != null) {
              controller.linkEnd = details.localPosition;
              controller.checkSelection(controller.linkEnd!, true);
            }
          },
          child: LayoutBuilder(
            builder: (context, constraints) {
              controller.viewport = constraints.biggest;
              
              // V25 FEATURE: ZERO-ALLOCATION PANNING CACHE
              // By lifting this logic OUT of InteractiveViewer.builder, we stop building and dropping
              // 10,000 `LayoutId` and `NodeRenderer` widgets 60 times a second. 
              // The nodes list remains identical unless notifyListeners() is called, so we only parse it once.
              final nodes = getNodes(constraints);
              final edges = getEdges(constraints);

              Widget edgesWidget = Positioned.fill(
                child: InfiniteCanvasEdgeRenderer(
                  controller: controller,
                  edges: edges,
                  linkStart: controller
                      .getNode(controller.linkStart)
                      ?.rect
                      .center,
                  linkEnd: controller.linkEnd,
                  linkIsExcitatory: controller.getNode(controller.linkStart)?.isExcitatory == 1,
                  straightLines: widget.edgesUseStraightLines,
                ),
              );

              Widget? dropTargetsWidget;
              if (!controller.isPlaying && controller.dropTargets.isNotEmpty) {
                dropTargetsWidget = Positioned.fill(
                  child: InfiniteDropTargetsRenderer(
                    controller: controller,
                    dropTargets: controller.dropTargets,
                  ),
                );
              }

              List<Widget> nucleusWidgets = [];
              if (controller.nucleusList != null) {
                  nucleusWidgets = controller.nucleusList!;
              }

              // This entire massive tree is generated ONE time per structural change.
              Widget cachedNodesLayer = Positioned.fill(
                 child: Stack(
                   children: [
                      edgesWidget,
                      Positioned.fill(
                        child: CustomMultiChildLayout(
                          delegate: InfiniteCanvasNodesDelegate(nodes),
                          children: nodes
                              .map((e) => LayoutId(
                                    key: e.key,
                                    id: e,
                                    child: NodeRenderer(
                                      node: e,
                                      controller: controller,
                                    ),
                                  ))
                              .toList(),
                        ),
                      ),
                      Positioned.fill(child: InfiniteCanvasSynapseRenderer(controller: controller)),
                      if (controller.dropTargets.isNotEmpty && dropTargetsWidget != null) dropTargetsWidget,
                      ...nucleusWidgets,
                   ]
                 )
              );

              return InteractiveViewer.builder(
                transformationController: controller.transform,
                // WEB: Disable BOTH pan and scale — all gesture handling is done
                // in the Listener above (onPointerMove for pan/drag, onPointerSignal
                // for zoom). This eliminates Chrome's gesture arena conflicts.
                // Native: InteractiveViewer owns pan (single-pointer) and scale (pinch).
                panEnabled: !kIsWeb &&
                    controller.canvasMoveEnabled &&
                    !controller.controlPressed &&
                    controller.linkStart == null,
                scaleEnabled: !kIsWeb,
                onInteractionStart: (details) {
                  // print("controller.mousePosition");
                  // print(details.focalPoint);

                  // WEB: Use localFocalPoint (local to InteractiveViewer) so
                  // that toLocal(mousePosition) in designbrain_page works
                  // correctly under FittedBox. On native, use global focalPoint
                  // for compatibility with globalToLocal() callers.
                  controller.mousePosition = kIsWeb
                      ? details.localFocalPoint
                      : details.focalPoint;

                  // WEB: Do NOT overwrite mouseDragStart here.
                  // On web, onPointerDown already set it correctly using
                  // Listener.localPosition (which respects FittedBox's
                  // coordinate inflation). details.focalPoint is in GLOBAL
                  // screen coordinates — overwriting would cause a snap offset
                  // when FittedBox is active (shortestSide < 600).
                  if (!kIsWeb) {
                    controller.mouseDragStart = controller.mousePosition;
                  }
                  if (kIsWeb) {
                  } else if (Platform.isIOS) {
                    // print(controller.mousePosition);
                    // controller.notifyMousePosition();
                  }
                },
                onInteractionUpdate: (details) {
                  // WEB: All gesture handling is done in the Listener (onPointerMove).
                  // Skip InteractiveViewer callback processing entirely on web.
                  if (kIsWeb) return;

                  // Right-click/middle-click pan already handled in Listener.onPointerMove.
                  if (_rightClickDragStart != null) return;

                  if (details.pointerCount >= 2) {
                    // Multi-finger gesture (pinch/spread on touchscreen, or 2-finger trackpad).
                    // InteractiveViewer is ALREADY applying zoom+pan to the transform internally.
                    // Calling controller.pan() here would create two simultaneous transform
                    // mutations per frame, causing them to fight and block both zoom and pan.
                    // Solution: do nothing here — let InteractiveViewer own the transform.
                    controller.mousePosition = details.focalPoint;
                    return;
                  }

                  if (!controller.mouseDown) {
                    // No button pressed — trackpad/mouse scale gesture.
                    // InteractiveViewer applies zoom+pan to the transform internally.
                    // Global scroll route handles trackpad 2-finger pan via PointerSignalResolver.
                    // We only cache the scale value here for other calculations.
                    controller.quietlySetScale(details.scale);
                  } else if (controller.spacePressed) {
                    if (controller.canvasMoveEnabled) {
                      controller.pan(details.focalPointDelta);
                    }
                  } else if (controller.controlPressed) {
                    // ctrl+drag = draw edge, no move
                  } else {
                    // Single-pointer click+drag → move selected node(s)
                    controller.moveSelection(details.focalPoint);
                  }
                  controller.mousePosition = details.focalPoint;
                  if (Platform.isIOS) {
                    // print("controller.mousePosition2");
                    // print(details.focalPoint);
                    // print(controller.mousePosition);
                    // controller.notifyMousePosition();
                  }
                },
                onInteractionEnd: (_) => controller.mouseDragStart = null,
                minScale: controller.minScale,
                maxScale: controller.maxScale,
                alignment: Alignment.topLeft,
                // scaleFactor=infinity disables InteractiveViewer's own mouse scroll zoom:
                // math.exp(-dy/infinity) = exp(0) = 1.0 → scaleChange=1.0 → IV returns early.
                // Our deep Listener (inside builder) handles mouse scroll with correct
                // pre-multiply formula + hard direction+limit boundary checks.
                scaleFactor: double.maxFinite,
                boundaryMargin: const EdgeInsets.all(100000.0),
                builder: (context, quad) {
                  // InteractiveViewer natively triggers this frame builder during every micro-movement to update the quad.
                  // Since `cachedNodesLayer` is a final reference to a pre-defined tree, Flutter diffs it in 0.0ms.
                  // Deep Listener inside InteractiveViewer's builder content.
                  // Being INSIDE the builder makes it DEEPER in the hit tree than
                  // InteractiveViewer's own internal Listener. Flutter hit testing resolves
                  // deepest-first, so this Listener registers in PointerSignalResolver FIRST,
                  // winning the ??= race and blocking InteractiveViewer's handler.
                  // Mouse scroll: applies cursor-anchored zoom (pre-multiply viewport-space).
                  // Hard clamp at min/max — overflow returns early, no pan drift at bounds.
                  // Trackpad pan: handled via _globalScrollRoute (global route, separate path).
                  return Listener(
                    onPointerSignal: (Platform.isIOS || Platform.isAndroid)
                        ? null
                        : (event) {
                            if (event is PointerScrollEvent &&
                                event.kind == PointerDeviceKind.mouse) {
                              const double zoomStep = 0.12;
                              final double factor = event.scrollDelta.dy > 0
                                  ? 1.0 - zoomStep
                                  : 1.0 + zoomStep;
                              final double currentScale = controller.getScale();
                              // Direction+limit check: avoids float-equality drift.
                              // At minScale, any zoom-out intent → hard stop, no transform.
                              // At maxScale, any zoom-in intent → hard stop, no transform.
                              final bool zoomingOut = event.scrollDelta.dy > 0;
                              if (zoomingOut && currentScale <= controller.minScale) return;
                              if (!zoomingOut && currentScale >= controller.maxScale) return;
                              final double newScale = (currentScale * factor)
                                  .clamp(controller.minScale, controller.maxScale);
                              final double f = newScale / currentScale;
                              // event.localPosition inside InteractiveViewer's builder is in
                              // SCENE coordinates. Convert to VIEWPORT coordinates by applying
                              // the transform (which maps scene→viewport).
                              // Using transform * scenePoint gives the correct screen-space pos
                              // regardless of window position on the display.
                              final Vector3 sceneVec = Vector3(
                                event.localPosition.dx,
                                event.localPosition.dy,
                                0.0,
                              );
                              final Vector3 vpVec =
                                  controller.transform.value.transform3(sceneVec);
                              final Offset p = Offset(vpVec.x, vpVec.y);

                              final Matrix4 viewportZoom = Matrix4.identity()
                                ..translate(p.dx * (1.0 - f), p.dy * (1.0 - f), 0.0)
                                ..scale(f, f, 1.0);
                              viewportZoom.multiply(controller.transform.value);
                              controller.transform.value = viewportZoom;
                            }
                          },
                    child: SizedBox.fromSize(
                      size: controller.getMaxSize().size,
                      child: Stack(
                        // clipBehavior: Clip.none,
                        children: [
                          if (widget.backgroundBuilder != null) ...[
                            Positioned(
                              left: 0,
                              top: 0,
                              child: buildBackground(context, quad),
                            ),
                          ],
                          if (widget.activeComponent != null) ...[
                            Positioned(
                              left: 0,
                              top: 0,
                              child: buildActiveComponent(context, quad),
                            ),
                          ],
                          cachedNodesLayer,
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
