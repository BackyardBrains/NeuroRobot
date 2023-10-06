import 'package:flutter/material.dart';
import 'package:neurorobot/brands/brandguide.dart';
import 'package:responsive_grid/responsive_grid.dart';

class WelcomePage extends StatelessWidget{
  Orientation orientation = Orientation.landscape;
  List<String> stepData = ['Turn on the Robot', 'Connect your device to Wifi: Neurorobot_{xyz}', 'Click on "Connect Now" below'];
  WelcomePage({required this.callback});
  final Function callback;
  @override
  Widget build(BuildContext context) {
    orientation = MediaQuery.of(context).orientation;
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: MediaQuery.of(context).size.width,
              height:MediaQuery.of(context).size.height/4,
              padding: const EdgeInsets.fromLTRB(20, 80, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Welcome", style: headerStyle,),
                  Text("Follow the instructions to connect your robot!", style: subHeaderStyle,),

                ],
              )
            ),
            if (orientation == Orientation.landscape)...[
              SizedBox(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height * 0.5,
                child: ResponsiveGridList(
                  desiredItemWidth: MediaQuery.of(context).size.width / 4,
                  minSpacing: 10,
                  children: List.generate(3, (index)=> index+1).map((i) {
                    return Card(
                      child: Container(
                        height: 200,
                        // alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.all(15),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Step ${i.toString()}", style: stepStyle,),
                            Text(stepData[i - 1], style:subHeaderStyle),
                          ],
                        ),
                      ),
                    );
                  }).toList()
                ),
              ), 
              Container(
                margin: const EdgeInsets.only(right:15),
                width: MediaQuery.of(context).size.width,
                height:70,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      // padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                      textStyle: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      )
                    ),
                    onPressed: (){
                      callback();
                    },
                    child: const Text("Connect", style: TextStyle(color: Colors.white),),
                  ),
                ),
              )
              
            ]else...[
              Column(
                children: [
                  Card(
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      child: const Text("123")
                    ),
                  )
                ],
              )
      
            ]
      
          ],
        ),
      )
    );
  }

}