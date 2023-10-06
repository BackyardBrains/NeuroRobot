import 'dart:async';
import 'dart:ffi' as ffi;
import 'dart:isolate';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:infinite_canvas/infinite_canvas.dart';
import 'package:metooltip/metooltip.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:neurorobot/components/right_toolbar.dart';

class DesignBrainPage extends StatefulWidget {
  DesignBrainPage({super.key});
  @override
  State<DesignBrainPage> createState() => _DesignBrainPageState();
}

class _DesignBrainPageState extends State<DesignBrainPage> {
  late InfiniteCanvasController controller;
  @override
  void initState(){
    super.initState();

   final rectangleNode = InfiniteCanvasNode(
      key: UniqueKey(),
      // label: 'Rectangle',
      allowResize: false,
      
      offset: const Offset(100, 100),
      size: const Size(20, 20),
      child: Builder(
        builder: (context) {
          return CustomPaint(
            isComplex: true,
            willChange: true,
            painter: InlineCustomPainter(
              brush: Paint(),
              builder: (brush, canvas, rect) {
                // Draw rect
                brush.color = Theme.of(context).colorScheme.secondary;
                // canvas.drawRect(rect, brush);
                canvas.drawCircle(rect.center, rect.width / 2, brush);                
              },
            ),
          );
        },
      ),
    );
    final triangleNode = InfiniteCanvasNode(
      key: UniqueKey(),
      // label: 'Triangle',
      offset: const Offset(250, 100),
      size: const Size(20, 20),
      child: Builder(
        builder: (context) {
          return CustomPaint(
            painter: InlineCustomPainter(
              brush: Paint(),
              builder: (brush, canvas, rect) {
                // Draw triangle
                brush.color = Theme.of(context).colorScheme.secondaryContainer;
                canvas.drawCircle(rect.center, rect.width / 2, brush);                
                // final path = Path();
                // path.addPolygon([
                //   rect.topCenter,
                //   rect.bottomLeft,
                //   rect.bottomRight,
                // ], true);
                // canvas.drawPath(path, brush);
              },
            ),
          );
        },
      ),
    );
    final circleNode = InfiniteCanvasNode(
      key: UniqueKey(),
      // label: 'Circle',
      offset: const Offset(200, 250),
      size: const Size(20, 20),
      child: Builder(
        builder: (context) {
          return CustomPaint(
            painter: InlineCustomPainter(
              brush: Paint(),
              builder: (brush, canvas, rect) {
                // Draw circle
                brush.color = Theme.of(context).colorScheme.tertiary;
                canvas.drawCircle(rect.center, rect.width / 2, brush);
              },
            ),
          );
        },
      ),
    );
    final nodes = [
      rectangleNode,
      triangleNode,
      circleNode,
    ];    
    controller = InfiniteCanvasController(nodes: nodes, edges: [
      InfiniteCanvasEdge(
        from: rectangleNode.key,
        to: triangleNode.key,
        label: '4 -> 3',
      ),
      InfiniteCanvasEdge(
        from: rectangleNode.key,
        to: circleNode.key,
        label: '[] -> ()',
      ),
      InfiniteCanvasEdge(
        from: triangleNode.key,
        to: circleNode.key,
      ),
    ]);
    controller.maxScale = 1.5;
    controller.scale = 0.75;
    controller.minScale = 0.5;
    controller.addListener(() {
      if (controller.hasSelection){
        if (controller.mouseDown){
          var selected = controller.selection[0];
          if (selected.offset.dx < 0){
            print(controller.mousePosition.dx);
            print(controller.mousePosition.dy);
            var pos = selected.offset;
            var newOffset = Offset(0, pos.dy);
            selected.update(size:selected.size, offset:newOffset, label:"");
          }

          if (selected.offset.dy < 0){
            var pos = selected.offset;
            var newOffset = Offset(pos.dx, 0);
            selected.update(size:selected.size, offset:newOffset, label:"");
          }

        }
      }
     });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   title: Text(widget.title),
      // ),
      body: Stack(
        children: [
          Positioned(
            left:0,
            top:0,
            child: Container(
              width:800, 
              height:600,
              child: InfiniteCanvas(
                drawVisibleOnly: true,
                canAddEdges: true,
                menuVisible: false,
                controller: controller,
              ),
            ),
          ),
          Positioned(
            right:10,
            top:20,
            child: RightToolbar(key: GlobalKey()),
          ),

          Positioned(
            right:10,
            bottom:20,
            child: Card(
              surfaceTintColor: Colors.white,
              // surfaceTintColor: Colors.transparent,
              shadowColor: Colors.white,
              // color: Colors.transparent,
              child: Container(
                color: Colors.transparent,
                width:127,
                child: Row(
                  children: [
                    MeTooltip(
                      message: "Zoom Out",
                      preferOri: PreferOrientation.up,
                      child: ElevatedButton(
                        onPressed: (){
                          controller.zoomOut();
                        }, 
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          surfaceTintColor: Colors.white,
                          shadowColor: Colors.transparent
                          // shadowColor: Colors.white,
                        ),
                        child: const Text("-", style:TextStyle(fontSize:25,color: Color(0xFF4e4e4e))),
                      ),
                    ),
                    MeTooltip(
                      message: "Zoom In",
                      preferOri: PreferOrientation.up,
                      child: ElevatedButton(
                        onPressed: (){
                          controller.zoomIn();
                        }, 
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          surfaceTintColor: Colors.white,
                          shadowColor: Colors.transparent

                          // shadowColor: Colors.white,
                        ),
                        child: const Text("+", style:TextStyle(fontSize:25,color: Color(0xFF4e4e4e))),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
        ],
      ),      
      // body: Center(
      //   child: Column(
      //     mainAxisAlignment: MainAxisAlignment.center,
      //     children: <Widget>[
      //       Mjpeg(
      //         isLive:true,
      //         stream: 'http://192.168.4.1:81/stream',
      //       ),
      //       // const Text(
      //       //   'You have pushed the button this many times:',
      //       // ),
      //       CircularProgressIndicator(),
      //       // Text(
      //       //   '$_counter',
      //       //   style: Theme.of(context).textTheme.headlineMedium,
      //       // ),
      //     ],
      //   ),
      // ),
      // floatingActionButton: FloatingActionButton(
      //   // onPressed: startWebSocket,
      //   onPressed: (){
      //     controller.zoomReset();
      //   },
      //   tooltip: 'Increment',
      //   child: const Icon(Icons.add),
      // ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}


class InlineCustomPainter extends CustomPainter {
  const InlineCustomPainter({
    required this.brush,
    required this.builder,
    this.isAntiAlias = true,
  });
  final Paint brush;
  final bool isAntiAlias;
  final void Function(Paint paint, Canvas canvas, Rect rect) builder;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    brush.isAntiAlias = isAntiAlias;
    canvas.save();
    builder(brush, canvas, rect);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}