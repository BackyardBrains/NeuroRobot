import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:metooltip/metooltip.dart';

class RightToolbar extends StatefulWidget {
  RightToolbar({super.key, required this.callback});
  late Function callback;
  @override
  State<RightToolbar> createState() => _RightToolbarState();
}


class _RightToolbarState extends State<RightToolbar> {
  static int totalActionIcons = 6;
  static int totalSimulationIcons = 3;
  static List<String> activeActionIconsStr = ["assets/icons/ArrowSelect.svg","assets/icons/NeuronActive.svg", "assets/icons/Axon.svg", "-", "assets/icons/Undo.svg","assets/icons/Redo.svg"];
  static List<String> inactiveActionIconsStr = ["assets/icons/ArrowSelect.svg","assets/icons/Neuron.svg", "assets/icons/Axon.svg", "-", "assets/icons/Undo.svg","assets/icons/Redo.svg"];
  static List<ColorFilter> colorActionFilters = List<ColorFilter>.generate(6, (index) => const ColorFilter.mode(Colors.white, BlendMode.srcIn));

  static List<String> activeSimulationIconsStr = ["assets/icons/Save.svg","assets/icons/Play.svg","assets/icons/Home.svg"];
  static List<String> inactiveSimulationIconsStr = ["assets/icons/Save.svg","assets/icons/Play.svg","assets/icons/Home.svg"];
  static List<ColorFilter> colorSimulationFilters = List<ColorFilter>.generate(3, (index) => const ColorFilter.mode(Colors.white, BlendMode.srcIn));
  
  int activeIdx=0;
  List<String> tooltipActions = ["\nEdit Properties\nNeuron/Axon\n","Create Neuron","Create Axon","-","Undo","Redo"];
  List<Widget> activeActionIcons = List.generate(totalActionIcons, (index) {
    if (index == 3 ){
      return const Divider();
    }else
    if (index == 1){
      return SvgPicture.asset(
        activeActionIconsStr[index],
      );
    }

    return SvgPicture.asset(
      activeActionIconsStr[index],
      colorFilter: colorActionFilters[index],
    );
  });
  List<Widget> inactiveActionIcons = List.generate(totalActionIcons, (index) {
    if (index == 3 ){
      return const Divider();
    }
    return SvgPicture.asset(
      inactiveActionIconsStr[index],
      // colorFilter :const ColorFilter.mode(Color(0xFF13A9FC), BlendMode.srcIn),
    );
  });



  List<String> tooltipSimulations = ["Save Brain","Run Brain","Home"];
  List<Widget> activeSimulationIcons = List.generate(totalSimulationIcons, (index) {
    return SvgPicture.asset(
      activeSimulationIconsStr[index],
      colorFilter: colorSimulationFilters[index],
    );
  });
  List<Widget> inactiveSimulationIcons = List.generate(totalSimulationIcons, (index) {
    return SvgPicture.asset(
      inactiveSimulationIconsStr[index],
    );
  });

  // List<int> containerActionWidth = [30,20,15,15,15,15,15,15,15];
  List<EdgeInsets> containerActionPadding = [const EdgeInsets.all(8),const EdgeInsets.all(5),const EdgeInsets.all(5),const EdgeInsets.all(5),const EdgeInsets.all(5),const EdgeInsets.all(5),const EdgeInsets.all(5),const EdgeInsets.all(5),const EdgeInsets.all(6)];

  @override
  Widget build(BuildContext context) {
    return createRightToolbar();
  }

  Widget createRightToolbar(){
    return Column(
      children: [
        createActionToolbar(),
        createSimulationToolbar(),
      ],
    );
  }

  Widget createActionToolbar() {
    return Container(
      padding: const EdgeInsets.all(8.0)..copyWith(top:18),
      width:70,
      child: Card(
        surfaceTintColor: Colors.white,
        child: Container(
          
          padding: const EdgeInsets.fromLTRB(7, 10, 8, 10),
          width:54,
          height:205,
          child: ListView.builder(
            itemCount:6,
            physics: const NeverScrollableScrollPhysics(),
            itemBuilder: (ctx, idx){
              if (idx == 3){
                return const Divider();
              }
              return MeTooltip(
                message: tooltipActions[idx],
                preferOri: PreferOrientation.left,
                child:GestureDetector(
                  onTap:(){
                    activeIdx = idx;
                    widget.callback({"menuIdx":activeIdx});
                    setState(() {});
                  },
                  child: Container(
                    width:30,
                    height:30,
                    margin: const EdgeInsets.fromLTRB(0, 3, 0, 0),
                    decoration: 
                      idx==activeIdx && activeIdx<4 ? const BoxDecoration(
                        color: Color(0xFF13A9FC),
                        borderRadius: BorderRadius.all(Radius.circular(5))
                      )
                      :
                      const BoxDecoration(
                        color: Colors.white,
                      )
                    ,
                    padding: containerActionPadding[idx],
                    child: idx==activeIdx && activeIdx<4 ? activeActionIcons[idx] : inactiveActionIcons[idx],
                  ),
                ),
              );
            },
            // children: [
            //   const SizedBox(height:10),
        
            //   MeTooltip(
            //     message: "Create Neuron",
            //     preferOri: PreferOrientation.left,
            //     child: Container(
            //       padding: const EdgeInsets.all(5),
            //       child: SvgPicture.asset(
            //         width:20,
            //         "assets/icons/Neuron.svg",
            //       ),
            //     ),
            //   ),
            //   MeTooltip(
            //     message: "Create Axon",
            //     preferOri: PreferOrientation.left,
            //     child: Container(
            //       padding: const EdgeInsets.all(5),
            //       child: SvgPicture.asset(
            //         width:15,
            //         colorFilter: const ColorFilter.mode(Color(0xFF13A9FC), BlendMode.srcIn),
            //         "assets/icons/Axon.svg",
            //       ),
            //     ),
            //   ),                 
        
            //   Divider(),
              
            //   MeTooltip(
            //     message: "Undo",
            //     preferOri: PreferOrientation.left,
            //     child: Container(
            //       padding: const EdgeInsets.all(5),
            //       child: SvgPicture.asset(
            //         width: 15,
            //         "assets/icons/Undo.svg",
            //         colorFilter: const ColorFilter.mode(Color(0xFF13A9FC), BlendMode.srcIn),
            //         semanticsLabel: 'A red up arrow'
            //       ),
            //     ),
            //   ),
            //   MeTooltip(
            //     message: "Redo",
            //     preferOri: PreferOrientation.left,
            //     child: Container(
            //       padding: const EdgeInsets.all(5),
            //       child: SvgPicture.asset(
            //         width: 15,
            //         "assets/icons/Redo.svg",
            //         colorFilter: const ColorFilter.mode(Color(0xFF13A9FC), BlendMode.srcIn),
            //         semanticsLabel: 'A red up arrow'
            //       )
            //     ),
            //   ),
            //   MeTooltip(
            //     message: "Save Brain",
            //     preferOri: PreferOrientation.left,
            //     child: Container(
            //       padding: const EdgeInsets.all(5),
            //       child: SvgPicture.asset(
            //         width: 15,
            //         "assets/icons/Save.svg",
            //         colorFilter: const ColorFilter.mode(Color(0xFF13A9FC), BlendMode.srcIn),
            //         semanticsLabel: 'A red up arrow'
            //       )
            //     ),
            //   ),
            //   MeTooltip(
            //     message: "Run Brain",
            //     preferOri: PreferOrientation.left,
            //     child: Container(
            //       padding: const EdgeInsets.all(5),
            //       child:SvgPicture.asset(
            //         width: 10,
            //         "assets/icons/Play.svg",
            //         colorFilter: const ColorFilter.mode(Color(0xFF13A9FC), BlendMode.srcIn),
            //         semanticsLabel: 'A red up arrow'
            //       ),
            //     ),            
            //   ),
        
            //   MeTooltip(
            //     message: "Home",
            //     preferOri: PreferOrientation.left,
            //     child: Container(
            //       padding: const EdgeInsets.all(5),
            //       child:SvgPicture.asset(
            //         width: 15,
            //         "assets/icons/Home.svg",
            //         colorFilter: const ColorFilter.mode(Color(0xFF13A9FC), BlendMode.srcIn),
            //         semanticsLabel: 'A red up arrow'
            //       ),    
            //     ),
            //   ),
            //   const SizedBox(height:10),
            // ],
          ),
        ),
      ),
    );

  }
    
  Widget createSimulationToolbar() {
    return Container(
      padding: const EdgeInsets.all(8.0)..copyWith(top:18),
      width:70,
      child: Card(
        surfaceTintColor: Colors.white,
        child: Container(
          padding: const EdgeInsets.fromLTRB(7, 10, 8, 10),
          width:54,
          height:125,
          child: ListView.builder(
            itemCount:3,
            physics: const NeverScrollableScrollPhysics(),
            itemBuilder: (ctx, index){
              int idx = index;
              return MeTooltip(
                message: tooltipSimulations[idx],
                preferOri: PreferOrientation.left,
                child:GestureDetector(
                  onTap:(){
                    activeIdx = idx + 6;
                    widget.callback({"menuIdx":activeIdx});
                    setState(() {});
                  },
                  child: Container(
                    width:30,
                    height:30,
                    margin: const EdgeInsets.fromLTRB(0, 3, 0, 0),
                    decoration: 
                      idx==activeIdx - 6 ? const BoxDecoration(
                        // color : Colors.transparent,
                        color: Color(0xFF13A9FC),
                        borderRadius: BorderRadius.all(Radius.circular(5))
                      )
                      :
                      const BoxDecoration(
                        // color : Colors.transparent,
                        color: Colors.white,
                      )
                    ,
                    padding: containerActionPadding[idx],
                    child: idx == activeIdx - 6 ? activeSimulationIcons[idx] : inactiveSimulationIcons[idx],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );    
  }


}