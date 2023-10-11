import 'dart:async';
import 'dart:convert';
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
  int menuIdx = 0;
  bool isCreatePoint = false;

  List<UniqueKey> neuronsKey = [];
  List<UniqueKey> axonsKey = [];
  
  Offset constraintOffsetTopLeft = const Offset(300, 170);
  Offset constraintOffsetTopRight = const Offset(500,170);
  Offset constraintOffsetBottomRight = const Offset(500, 430);
  Offset constraintOffsetBottomLeft = const Offset(300, 430);

  List<InfiniteCanvasNode> listDefaultSensor = [];
  List<String> listDefaultSensorLabel = [];
  InfiniteCanvasNode nodeDistanceSensor = InfiniteCanvasNode(
    key: UniqueKey(),
    allowMove: false,
    allowResize: false,
    offset: const Offset(395, 150),
    size: const Size(20, 20), 
    child: Container(width: 15,height:15, color:Colors.black),
  );

  InfiniteCanvasNode nodeLeftEyeSensor = InfiniteCanvasNode(
    key: UniqueKey(),
    allowMove: false,
    allowResize: false,
    offset: const Offset(320, 150),
    size: const Size(20, 20), 
    child: Container(width: 15,height:15, color:Colors.black),
  );  
  InfiniteCanvasNode nodeRightEyeSensor = InfiniteCanvasNode(
    key: UniqueKey(),
    allowMove: false,
    allowResize: false,
    offset: const Offset(470, 150),
    size: const Size(20, 20), 
    child: Container(width: 15,height:15, color:Colors.black),
  );  

  InfiniteCanvasNode nodeMicrophoneSensor = InfiniteCanvasNode(
    key: UniqueKey(),
    allowMove: false,
    allowResize: false,
    offset: const Offset(267, 217),
    size: const Size(20, 20), 
    child: Container(width: 15,height:15, color:Colors.black),
  );  
  InfiniteCanvasNode nodeSpeakerSensor = InfiniteCanvasNode(
    key: UniqueKey(),
    allowMove: false,
    allowResize: false,
    offset: const Offset(523, 217),
    size: const Size(20, 20), 
    child: Container(width: 15,height:15, color:Colors.black),
  );  

  InfiniteCanvasNode nodeLeftMotorForwardSensor = InfiniteCanvasNode(
    key: UniqueKey(),
    allowMove: false,
    allowResize: false,
    offset: const Offset(243, 310),
    size: const Size(20, 20), 
    child: Container(width: 15,height:15, color:Colors.black),
  );  
  InfiniteCanvasNode nodeRightMotorForwardSensor = InfiniteCanvasNode(
    key: UniqueKey(),
    allowMove: false,
    allowResize: false,
    offset: const Offset(547, 310),
    size: const Size(20, 20), 
    child: Container(width: 15,height:15, color:Colors.black),
  );

  InfiniteCanvasNode nodeLeftMotorBackwardSensor = InfiniteCanvasNode(
    key: UniqueKey(),
    allowMove: false,
    allowResize: false,
    offset: const Offset(240, 405),
    size: const Size(20, 20), 
    child: Container(width: 15,height:15, color:Colors.black),
  );  
  InfiniteCanvasNode nodeRightMotorBackwardSensor = InfiniteCanvasNode(
    key: UniqueKey(),
    allowMove: false,
    allowResize: false,
    offset: const Offset(550, 405),
    size: const Size(20, 20), 
    child: Container(width: 15,height:15, color:Colors.black),
  );    
  // InfiniteCanvasNode constraintOffsetTopRight = InfiniteCanvasNode(
  //   key: UniqueKey(),
  //   allowMove: false,
  //   allowResize: false,
  //   offset: const Offset(500, 170),
  //   size: const Size(10, 10), 
  //   child: Container(width: 0,height:0, color:Colors.green),
  // );
  // InfiniteCanvasNode constraintOffsetBottomRight = InfiniteCanvasNode(
  //   key: UniqueKey(),
  //   allowMove: false,
  //   allowResize: false,
  //   offset: const Offset(300, 430),
  //   size: const Size(10, 10), 
  //   child: Container(width: 0,height:0, color:Colors.green),
  // );
  // InfiniteCanvasNode constraintOffsetBottomLeft = InfiniteCanvasNode(
  //     key: UniqueKey(),
  //     allowMove: false,
  //     allowResize: false,
  //     offset: const Offset(500, 430),
  //     size: const Size(10, 10), 
  //     child: Container(width: 0,height:0, color:Colors.green),
  // );


  double constraintBrainLeft = 300.0;
  double constraintBrainRight = 500.0;
  double constraintBrainTop = 170.0;
  double constraintBrainBottom = 430.0;
  
  double prevScreenWidth = 800.0;
  double prevScreenHeight = 600.0;
  double screenWidth = 800.0;
  double screenHeight = 600.0;
  bool isResizingFlag = false;

  var viewportKey = UniqueKey();
  
  bool axonFromSelected = false;
  bool axonToSelected = false;
  late InfiniteCanvasNode axonFrom;
  late InfiniteCanvasNode axonTo;
  
  double tooltipOverlayX = 10;
  double tooltipOverlayY = 10;
  String tooltipOverlayMessage = "";
  bool isTooltipOverlay = false;
  @override
  void initState(){
    super.initState();

   final rectangleNode = InfiniteCanvasNode(
      key: UniqueKey(),
      // label: 'Rectangle',
      allowResize: false,
      
      offset: const Offset(300, 300),
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
      offset: const Offset(500, 170),
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
      offset: const Offset(320, 430),
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
      InfiniteCanvasNode(
        key: viewportKey,
        allowMove: false,
        allowResize: false,
        offset: const Offset(800, 600),
        size: const Size(0, 0), 
        child: const SizedBox(width: 0,height:0,)
      ),

      // constraintOffsetTopLeft,
      // constraintOffsetTopRight,
      // constraintOffsetBottomRight,
      // constraintOffsetBottomLeft,

      rectangleNode,
      triangleNode,
      circleNode,

      nodeDistanceSensor,
      nodeLeftEyeSensor,
      nodeRightEyeSensor,

      nodeLeftMotorForwardSensor,
      nodeRightMotorForwardSensor,
      nodeLeftMotorBackwardSensor,
      nodeRightMotorBackwardSensor,

      nodeMicrophoneSensor,
      nodeSpeakerSensor
    ];    

    listDefaultSensorLabel = [
      "Distance Sensor",
      "Left Eye",
      "Right Eye",

      "Microphone",
      "Speaker",

      "Left Motor (Forward)",
      "Right Motor (Forward)",
      "Left Motor (Backward)",
      "Right Motor (Backward)",
    ];
    listDefaultSensor = [
      nodeDistanceSensor,
      nodeLeftEyeSensor,
      nodeRightEyeSensor,

      nodeMicrophoneSensor,
      nodeSpeakerSensor,

      nodeLeftMotorForwardSensor,
      nodeRightMotorForwardSensor,
      nodeLeftMotorBackwardSensor,
      nodeRightMotorBackwardSensor,
    ];
    controller = InfiniteCanvasController(nodes: nodes, edges: [
      InfiniteCanvasEdge(
        from: rectangleNode.key,
        to: triangleNode.key,
        // label: '4 -> 3',
      ),
      InfiniteCanvasEdge(
        from: rectangleNode.key,
        to: circleNode.key,
        // label: '[] -> ()',
      ),
      InfiniteCanvasEdge(
        from: triangleNode.key,
        to: circleNode.key,
      ),
    ]);
    controller.maxScale = 1.5;
    controller.scale = 1;
    controller.minScale = 0.5;
    controller.addListener(() {

      if (controller.mouseDown){

        // print(menuIdx);
        if (menuIdx == 0 && controller.hasSelection){
          var selected = controller.selection[0];
          var pos = selected.offset;
          int defaultSensorLength = listDefaultSensor.length;
          bool foundSelected = false;
          for (int i = 0 ; i < defaultSensorLength; i++){
            if (selected == listDefaultSensor[i]){
              tooltipOverlayX = selected.offset.dx;
              tooltipOverlayY = selected.offset.dy;
              tooltipOverlayMessage = listDefaultSensorLabel[i];
              isTooltipOverlay = true;
              foundSelected = true;
            }
          }
          if (foundSelected) {
            setState((){});
            Future.delayed(const Duration(milliseconds: 1000),(){
              isTooltipOverlay = false;
              setState(() {
                
              });
            });
            return;
          }

          if (selected.offset.dx < constraintBrainLeft){
            var newOffset = Offset(constraintBrainLeft, pos.dy);
            selected.update(size:selected.size, offset:newOffset, label:"");
          }else
          if (selected.offset.dx > constraintBrainRight){
            var newOffset = Offset(constraintBrainRight, pos.dy);
            selected.update(size:selected.size, offset:newOffset, label:"");
          }

          pos = selected.offset;

          if (selected.offset.dy < constraintBrainTop){
            var newOffset = Offset(pos.dx, constraintBrainTop);
            selected.update(size:selected.size, offset:newOffset, label:"");
          }else
          if (selected.offset.dy > constraintBrainBottom){
            var newOffset = Offset(pos.dx, constraintBrainBottom);
            selected.update(size:selected.size, offset:newOffset, label:"");
          }
        }else
        if ( menuIdx == 1 && !isCreatePoint && !controller.hasSelection){
          isCreatePoint = true;
          double mouseX = controller.mousePosition.dx;
          double mouseY = controller.mousePosition.dy;
          if (mouseX < constraintBrainLeft || mouseX > constraintBrainRight){
            return;
          }
          if (mouseY < constraintBrainTop || mouseY > constraintBrainBottom){
            return;
          }
          neuronsKey.add(UniqueKey());
          controller.add(
            InfiniteCanvasNode(
              key: neuronsKey[ neuronsKey.length - 1 ],
              allowMove: false,
              allowResize: false,
              offset: Offset(mouseX, mouseY),
              size: const Size(20, 20), 
              child: CustomPaint(
                isComplex: true,
                willChange: true,
                painter: InlineCustomPainter(
                  brush: Paint(),
                  builder: (brush, canvas, rect) {
                    brush.color = Theme.of(context).colorScheme.secondary;
                    canvas.drawCircle(rect.center, rect.width / 2, brush);                
                  },
                ),
              ),
              // child: Container(width: 0,height:0, color:Colors.green),
            )
          );
          Future.delayed(const Duration(milliseconds: 100),(){
            controller.deselect(neuronsKey[ neuronsKey.length - 1 ]);
          });

        }else
        if ( menuIdx == 2 && !isCreatePoint){
          print('design brain');
          print(controller.hasSelection);
          print(axonFromSelected);
          print(axonToSelected);
          isCreatePoint = true;
          if (!axonFromSelected && controller.hasSelection){
            axonFromSelected = true;
            axonFrom = controller.selection[0];
            isCreatePoint = false;
          }else
          if (!axonToSelected && controller.hasSelection){
            axonFromSelected = true;
            axonTo = controller.selection[0];
            if (axonFrom == axonTo){
            }else{
              // if there is already the same edge from one node to another node, don't add
              bool isAddUniqueEdge = true;

              int totalEdges = controller.edges.length;
              for (int i = 0; i < totalEdges; i++){
                if (controller.edges[i].from == axonFrom.key && controller.edges[i].to == axonTo.key){
                  isAddUniqueEdge = false;
                }
              }

              if (isAddUniqueEdge){
                controller.edges.add(InfiniteCanvasEdge(from: axonFrom.key, to: axonTo.key));
              }
            }
            axonFromSelected = false;
            axonToSelected = false;
            
            isCreatePoint = false;
          }
          
        }
      }else{
        isCreatePoint = false;
        // isTooltipOverlay = false;
        // setState((){});
      }

     });
  }

  @override
  Widget build(BuildContext context) {
    // double density = MediaQuery.of(context).devicePixelRatio;
    screenWidth = MediaQuery.of(context).size.width;
    screenHeight = MediaQuery.of(context).size.height;

    if (prevScreenWidth != screenWidth){
      isResizingFlag = true;
    }
    if (prevScreenHeight != screenHeight){
      isResizingFlag = true;
    }
    if (isResizingFlag){
      controller.getNode(viewportKey)?.offset = Offset(screenWidth, screenHeight);
      int idx = 0;
      double scaleX = screenWidth / prevScreenWidth;
      double scaleY = screenHeight / prevScreenHeight;

      constraintOffsetTopLeft = constraintOffsetTopLeft.scale(scaleX, scaleY);
      constraintOffsetTopRight = constraintOffsetTopRight.scale(scaleX, scaleY);
      constraintOffsetBottomRight = constraintOffsetBottomRight.scale(scaleX, scaleY);
      constraintOffsetBottomLeft = constraintOffsetBottomLeft.scale(scaleX, scaleY);

      constraintBrainLeft = constraintOffsetTopLeft.dx;
      constraintBrainRight = constraintOffsetTopRight.dx;
      constraintBrainTop = constraintOffsetTopLeft.dy;
      constraintBrainBottom = constraintOffsetBottomLeft.dy;

      // print("constraintBrainLeft");
      // print(controller.scale);
      // print(constraintOffsetTopLeft);
      // print(constraintBrainLeft);
      // print(constraintBrainTop);

      for (var element in controller.nodes) { 
        if (idx>0){
          element.offset = element.offset.scale( scaleX , scaleY );

          // constraintBrainLeft *= scaleX;
          // constraintBrainRight *= scaleX;
          // constraintBrainTop *= scaleY;
          // constraintBrainBottom *= scaleY;
          
          // print("screen dimension");
          // print(screenWidth);
          // print(screenHeight);
          // print("constraintBrainLeft");
          // print(constraintBrainLeft);
          // print(constraintBrainRight);
          // print(constraintBrainTop);
          // print(constraintBrainBottom);

          // Offset prevOffset = element.offset;
          // element.offset = element.offset.scale( scaleX , scaleY );
          // constraintBrainLeft += (element.offset.dx - prevOffset.dx);
          // constraintBrainRight += (element.offset.dx - prevOffset.dx);
          // constraintBrainTop += (element.offset.dy - prevOffset.dy);
          // constraintBrainBottom += (element.offset.dy - prevOffset.dy);
        }
        idx++;
      }
      isResizingFlag = false;
      // print("isResizingFlag");
      // print(isResizingFlag);

      prevScreenWidth = screenWidth;
      prevScreenHeight = screenHeight;

    }
    
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
              color: Colors.white,
              width:screenWidth, 
              height:screenHeight,
              child: InfiniteCanvas(
                backgroundBuilder: (ctx, r){ 
                // print("MediaQuery.of(context).screenWidth");
                // print(screenWidth);
                // print(screenHeight);


                  return Container(
                    color:Colors.white,
                    width:screenWidth * 2, 
                    height:screenHeight,
                    child: Image.asset(
                      width: screenWidth,
                      height: screenHeight,
                      // scale: screenWidth/800,
                      fit:BoxFit.contain,
                      // scale: density,
                      "assets/bg/bg1.0x.jpeg"
                    ),
                  );
                },
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
            child: RightToolbar(key: GlobalKey(), callback:(map){
              print("map");
              print(map);
              menuIdx = map["menuIdx"];
              isCreatePoint = false;
              if (menuIdx == 0){
                allowMoveNodes();
              }else{
                disallowMoveNodes();
              }
              if (menuIdx == 6){
                // print( json.encode(controller.nodes) );
                // print( json.encode(controller.edges) );
              }else
              if (menuIdx == 8){
                print("home");
                Navigator.pop(context);
              }
              // add nodes into canvas
            }),
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
        
          !isTooltipOverlay? Container():
          Positioned(
            left : tooltipOverlayX-20,
            top : tooltipOverlayY-50,
            child : Container(
              color: Colors.black,
              padding: const EdgeInsets.all(5),
              child:Text(tooltipOverlayMessage, style : const TextStyle(color: Colors.white))
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
  
  void allowMoveNodes() {
    int n = controller.nodes.length;
    for (int i = 0; i < n; i++){
      controller.nodes[i].allowMove = true;
    }
  }  
  void disallowMoveNodes() {
    int n = controller.nodes.length;
    for (int i = 0; i < n; i++){
      controller.nodes[i].allowMove = false;
    }
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