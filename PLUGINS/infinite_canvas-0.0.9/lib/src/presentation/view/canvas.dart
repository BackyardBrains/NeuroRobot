import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;

import '../widgets/delegate.dart';
import '../../domain/model/node.dart';
import '../../domain/model/edge.dart';
import '../widgets/edge_renderer.dart';
import '../state/controller.dart';
import '../widgets/grid_background.dart';
import '../widgets/marquee.dart';
import '../../domain/model/menu_entry.dart';
import '../widgets/menus.dart';
import '../widgets/node_renderer.dart';

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

  @override
  void initState() {
    super.initState();
    controller.addListener(onUpdate);
    controller.focusNode.requestFocus();
  }

  @override
  void dispose() {
    controller.removeListener(onUpdate);
    controller.focusNode.dispose();
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
    // print("onUpdate");
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
      final nodes = getNodes(constraints);
      final nodeKeys = nodes.map((e) => e.key).toSet();
      final edges = <InfiniteCanvasEdge>[];
      for (final edge in controller.edges) {
        if (nodeKeys.contains(edge.from) || nodeKeys.contains(edge.to)) {
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
          onPointerDown: (details) {
            if (!Platform.isIOS) {
              controller.checkSelection(details.localPosition);
            }
            // print("mouse down");

            // print(controller.scale);
            controller.mouseDown = true;
            controller.mousePosition = details.localPosition;
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
            if (Platform.isIOS) {
              controller.checkSelection(details.localPosition);
            }

            // try {
            // } catch (err) {
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
            controller.mouseDown = false;
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
            lastPointerDownTime = 0;
            firstTapTime = 0;
            secondTapTime = 0;

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
              // print("constraints.maxWidth");
              // print(constraints.maxWidth);
              // print(constraints.maxHeight);
              return InteractiveViewer.builder(
                transformationController: controller.transform,
                panEnabled: controller.canvasMoveEnabled,
                // scaleEnabled: controller.canvasMoveEnabled,
                scaleEnabled: true,
                onInteractionStart: (details) {
                  // print("controller.mousePosition");
                  // print(details.focalPoint);

                  controller.mousePosition = details.focalPoint;
                  controller.mouseDragStart = controller.mousePosition;
                  // WEB CHANGE
                  if (kIsWeb) {
                  } else if (Platform.isIOS) {
                    // print(controller.mousePosition);
                    // controller.notifyMousePosition();
                  }
                },
                onInteractionUpdate: (details) {
                  if (!controller.mouseDown) {
                    controller.scale = details.scale;
                  } else if (controller.spacePressed) {
                    // print("controller.canvasMoveEnabled");
                    // print(controller.canvasMoveEnabled);
                    if (controller.canvasMoveEnabled) {
                      controller.pan(details.focalPointDelta);
                    }
                  } else if (controller.controlPressed) {
                  } else {
                    controller.moveSelection(details.focalPoint);
                  }
                  controller.mousePosition = details.focalPoint;
                  // print("controller.mousePosition2");
                  if (Platform.isIOS) {
                    // print(details.focalPoint);
                    // print(controller.mousePosition);
                    // controller.notifyMousePosition();
                  }
                },
                onInteractionEnd: (_) => controller.mouseDragStart = null,
                minScale: controller.minScale,
                maxScale: controller.maxScale,
                boundaryMargin: const EdgeInsets.all(double.infinity),
                builder: (context, quad) {
                  final nodes = getNodes(constraints);
                  final edges = getEdges(constraints);
                  if (!controller.isPlaying) {
                    edgesWidget = Positioned.fill(
                      child: InfiniteCanvasEdgeRenderer(
                        controller: controller,
                        edges: edges,
                        linkStart: controller
                            .getNode(controller.linkStart)
                            ?.rect
                            .center,
                        linkEnd: controller.linkEnd,
                        straightLines: widget.edgesUseStraightLines,
                      ),
                    );
                  } else {
                    // print("edges widget cache");
                  }
                  return SizedBox.fromSize(
                    size: controller.getMaxSize().size,
                    child: Stack(
                      // clipBehavior: Clip.none,
                      children: [
                        Positioned.fill(
                          child: buildBackground(context, quad),
                        ),
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
                        // CHANGE ME
                        // if (controller.marqueeStart != null &&
                        //     controller.marqueeEnd != null) ...[
                        //   Positioned.fill(
                        //     child: Marquee(
                        //       start:
                        //           controller.toLocal(controller.marqueeStart!),
                        //       end: controller.toLocal(controller.marqueeEnd!),
                        //     ),
                        //   ),
                        // ],
                      ],
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
