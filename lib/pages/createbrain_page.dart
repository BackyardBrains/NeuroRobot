import 'package:easy_animated_tabbar/easy_animated_tabbar.dart';
import 'package:flutter/material.dart';
import 'package:neurorobot/brands/brandguide.dart';
import 'package:responsive_grid/responsive_grid.dart';

class CreateBrainPage extends StatefulWidget {
  CreateBrainPage({super.key, required this.callback});
  Function callback;
  @override
  State<CreateBrainPage> createState() => _CreateBrainPageState();
}


class _CreateBrainPageState extends State<CreateBrainPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text("NeuroRobot"),
        
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: brandBlue,
              ), 
              child: const Text("Drawer Header"),
            ),
            const ListTile(
              leading: Icon(Icons.ac_unit_sharp),
              title: Text("All Brains"),
            ),
            const ListTile(
              leading: Icon(Icons.ac_unit_sharp),
              title: Text("Templates"),
            ),
            const ListTile(
              leading: Icon(Icons.ac_unit_sharp),
              title: Text("My Brain"),
            ),
          ],
        )
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: createMainBody(context),
      ),
    );

  }
  
  List<Widget> createMainBody(context) {
    return [
      Padding(
        padding: const EdgeInsets.fromLTRB(12,0,0,0),
        child: Text("Create or Select a Brain", style: headerStyle..copyWith(fontWeight: FontWeight.bold),),
      ),
      EasyAnimatedTab(
        buttonTitles: const ['All Brains', 'Templates','My Brains', 'Search'],
        onSelected: (index) {},
        animationDuration: 500,
        minWidthOfItem: 70,
        minHeightOfItem: 40,
        deActiveItemColor: Colors.grey,
        activeItemColor: Colors.redAccent,
        activeTextStyle: const TextStyle(color: Colors.white, fontSize: 14),
        deActiveTextStyle: const TextStyle(color: Colors.redAccent, fontSize: 14),
      ),      
      Expanded(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Container(
              width:constraints.maxWidth,
              height:constraints.maxHeight,
              child: ResponsiveGridList(
                desiredItemWidth: MediaQuery.of(context).size.width*0.2,
                minSpacing: 10,
                children: List.generate(20, (index)=> index).map((i) {
                  if (i==0){
                    return GestureDetector(
                      onTap:(){
                        widget.callback("add_brain");
                      },
                      child: Card(
                        child: SizedBox(
                          height: 270,
                          child:Center(
                            child: Text("+", style: TextStyle(fontSize: 70,color: brandBlue),),
                          )
                        ),
                      ),
                    );
                  }else{
                    return Card(
                      margin: const EdgeInsets.all(7),                    
                      child: Container(
                        height: 270,
                        padding: const EdgeInsets.all(7),
                        // alignment: const Alignment(0, 0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(
                              height: 150,
                            ),
                            Text("Lab 1", style:headerStyle),
                            Text("Description", style:subHeaderStyle),
                          ],
                        ),
                      ),
                    );
                  }
                }).toList()
              ),
            );
          }
        ),
      ),
    ];
  }
}