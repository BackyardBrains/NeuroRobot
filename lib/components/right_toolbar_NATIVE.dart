import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
// import 'package:metooltip/metooltip.dart';

class RightToolbar extends StatefulWidget {
  RightToolbar(
      {super.key,
      required this.callback,
      required this.isPlaying,
      required this.menuIdx});
  late Function callback;
  final int menuIdx;
  final bool isPlaying;
  @override
  State<RightToolbar> createState() => _RightToolbarState();
}

class _RightToolbarState extends State<RightToolbar> {
  ScrollController _actionController = ScrollController();
  ScrollController _simulationController = ScrollController();

  static int totalActionIcons = 5;
  static int totalSimulationIcons = 1;
  // static List<String> activeActionIconsStr = ["assets/icons/ArrowSelect.svg","assets/icons/NeuronActive.svg", "assets/icons/Axon.svg", "-", "assets/icons/Undo.svg","assets/icons/Redo.svg","pan_tool_rounded"];
  // static List<String> inactiveActionIconsStr = ["assets/icons/ArrowSelect.svg","assets/icons/Neuron.svg", "assets/icons/Axon.svg", "-", "assets/icons/Undo.svg","assets/icons/Redo.svg","pan_tool_rounded"];
  static List<String> activeActionIconsStr = [
    "assets/icons/ArrowSelect.svg",
    "assets/icons/NeuronActive.svg",
    "-",
    "assets/icons/Undo.svg",
    "assets/icons/Redo.svg",
    "pan_tool_rounded"
  ];
  static List<String> inactiveActionIconsStr = [
    "assets/icons/ArrowSelect.svg",
    "assets/icons/Neuron.svg",
    "-",
    "assets/icons/Undo.svg",
    "assets/icons/Redo.svg",
    "pan_tool_rounded"
  ];
  static List<ColorFilter> colorActionFilters = List<ColorFilter>.generate(
      7, (index) => const ColorFilter.mode(Colors.white, BlendMode.srcIn));

  // static List<String> activeSimulationIconsStr = ["assets/icons/Home.svg","assets/icons/Play.svg","assets/icons/Save.svg"];
  // static List<String> inactiveSimulationIconsStr = ["assets/icons/Home.svg","assets/icons/Play.svg","assets/icons/Save.svg"];
  static List<String> activeSimulationIconsStr = [
    // "assets/icons/Home.svg",
    "assets/icons/Load.svg",
    "assets/icons/Save.svg"
  ];
  static List<String> inactiveSimulationIconsStr = [
    // "assets/icons/Home.svg",
    "assets/icons/Load.svg",
    "assets/icons/Save.svg"
  ];
  static List<ColorFilter> colorSimulationFilters = List<ColorFilter>.generate(
      2, (index) => const ColorFilter.mode(Colors.white, BlendMode.srcIn));

  int activeIdx = 0;
  List<String> tooltipActions = [
    "\nEdit Properties\nNeuron/Axon\n",
    "Create Neuron",
    "-",
    "Undo",
    "Redo"
  ];
  List<Widget> activeActionIcons = List.generate(totalActionIcons, (index) {
    if (index == 2) {
      return const Divider();
    } else if (index == 1) {
      return SvgPicture.asset(
        activeActionIconsStr[index],
      );
    }
    // else
    // if (index == 5){
    //   return const Icon(Icons.pan_tool_rounded, size: 17,color:Color(0xFF4e4e4e));
    // }

    return SvgPicture.asset(
      activeActionIconsStr[index],
      colorFilter: colorActionFilters[index],
    );
  });
  List<Widget> inactiveActionIcons = List.generate(totalActionIcons, (index) {
    if (index == 2) {
      return const Divider();
    }
    // else
    // if (index == 5){
    //   return const Icon(Icons.pan_tool_rounded, size: 17,color:Color(0xFF4e4e4e));
    // }
    return SvgPicture.asset(
      inactiveActionIconsStr[index],
      // colorFilter :const ColorFilter.mode(Color(0xFF13A9FC), BlendMode.srcIn),
    );
  });

  List<String> tooltipSimulations = ["Load Brain", "Save Brain"];
  List<Widget> activeSimulationIcons =
      List.generate(totalSimulationIcons, (index) {
    return SvgPicture.asset(
      activeSimulationIconsStr[index],
      colorFilter: colorSimulationFilters[index],
    );
  });
  List<Widget> inactiveSimulationIcons =
      List.generate(totalSimulationIcons, (index) {
    return SvgPicture.asset(
      inactiveSimulationIconsStr[index],
    );
  });

  // List<int> containerActionWidth = [30,20,15,15,15,15,15,15,15];
  // List<EdgeInsets> containerActionPadding = [const EdgeInsets.all(8),const EdgeInsets.all(5),const EdgeInsets.all(5),const EdgeInsets.all(5),const EdgeInsets.all(5),const EdgeInsets.all(5),const EdgeInsets.all(5),const EdgeInsets.all(5),const EdgeInsets.all(6)];
  List<EdgeInsets> containerActionPadding = [
    const EdgeInsets.all(8),
    const EdgeInsets.all(5),
    const EdgeInsets.all(5),
    const EdgeInsets.all(5),
    const EdgeInsets.all(5),
    const EdgeInsets.all(5),
    const EdgeInsets.all(5),
    const EdgeInsets.all(6)
  ];

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 200), () {
      // WEB CHANGE
      if (kIsWeb) {
        if (_actionController.hasClients) {
          _actionController.animateTo(1,
              duration: const Duration(milliseconds: 10), curve: Curves.linear);
          _simulationController.animateTo(1,
              duration: const Duration(milliseconds: 10), curve: Curves.linear);
        }
      } else if (Platform.isAndroid) {
        if (_actionController.hasClients) {
          _actionController.animateTo(20,
              duration: const Duration(milliseconds: 10), curve: Curves.linear);
          _simulationController.animateTo(20,
              duration: const Duration(milliseconds: 10), curve: Curves.linear);
        }
      } else {
        try {
          if (_actionController.hasClients) {
            _actionController.animateTo(1,
                duration: const Duration(milliseconds: 10),
                curve: Curves.linear);
            _simulationController.animateTo(1,
                duration: const Duration(milliseconds: 10),
                curve: Curves.linear);
          }
        } catch (err) {}
      }
    });
    activeIdx = widget.menuIdx;
  }

  @override
  Widget build(BuildContext context) {
    return createRightToolbar();
  }

  Widget createRightToolbar() {
    return Column(
      children: [
        createActionToolbar(),
        createSimulationToolbar(),
      ],
    );
  }

  Widget createActionToolbar() {
    return Container(
      padding: const EdgeInsets.all(8.0)..copyWith(top: 10),
      width: 70,
      child: Container(
        // color:Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.all(Radius.circular(5)),
          boxShadow: [
            BoxShadow(
              color: Colors.grey,
              offset: Offset(0, 2),
              blurRadius: 4,
            ),
          ],
        ),
        // surfaceTintColor: Colors.white,
        child: Container(
          padding: const EdgeInsets.fromLTRB(7, 0, 8, 0),
          width: 54,
          height: 150,
          child: ListView.builder(
            itemCount: totalActionIcons,
            reverse: false,
            shrinkWrap: true,
            controller: _actionController,

            // physics: const NeverScrollableScrollPhysics(),
            itemBuilder: (ctx, idx) {
              if (idx == 2) {
                return const Divider();
              }
              // return MeTooltip(
              //   message: tooltipActions[idx],
              //   preferOri: PreferOrientation.left,
              // child: GestureDetector(
              return GestureDetector(
                onTap: () {
                  if (widget.isPlaying) return;

                  activeIdx = idx;
                  widget.callback({"menuIdx": activeIdx});
                  setState(() {});
                },
                child: Container(
                  width: 30,
                  height: 30,
                  margin: const EdgeInsets.fromLTRB(0, 0, 0, 3),
                  decoration: idx == activeIdx && (activeIdx < 3)
                      ? const BoxDecoration(
                          color: Color(0xFF13A9FC),
                          borderRadius: BorderRadius.all(Radius.circular(5)))
                      : const BoxDecoration(
                          color: Colors.white,
                        ),
                  padding: containerActionPadding[idx],
                  child: idx == activeIdx && activeIdx < 3
                      ? activeActionIcons[idx]
                      : inactiveActionIcons[idx],
                ),
                // ),
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
      padding: const EdgeInsets.all(8.0)..copyWith(top: 0),
      width: 70,
      child: Container(
        // surfaceTintColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.all(Radius.circular(5)),
          boxShadow: [
            BoxShadow(
              color: Colors.grey,
              offset: Offset(0, 2),
              blurRadius: 4,
            ),
          ],
        ),

        child: Container(
          padding: const EdgeInsets.fromLTRB(7, 0, 8, 0),
          width: 54,
          // height: 70,
          height: 70 / 2,
          child: ListView.builder(
            controller: _simulationController,
            shrinkWrap: true,
            itemCount: totalSimulationIcons,
            // physics: const NeverScrollableScrollPhysics(),
            itemBuilder: (ctx, index) {
              int idx = index;
              // return MeTooltip(
              return Container(
                // message: tooltipSimulations[idx],
                // preferOri: PreferOrientation.left,
                child: GestureDetector(
                  onTap: () {
                    if (widget.isPlaying) return;

                    int prevIdx = activeIdx;
                    // activeIdx = idx + 7;//6//5;
                    activeIdx = idx + 5;
                    widget.callback({"menuIdx": activeIdx});

                    // if (prevIdx == activeIdx && activeIdx == 7){
                    //   activeIdx = 0;
                    //   // Future.delayed(Duration(milliseconds: 300),(){
                    //     widget.callback({"menuIdx":activeIdx});
                    //   // });
                    // }
                    setState(() {});
                  },
                  child: Container(
                    width: 30,
                    height: 30,
                    margin: const EdgeInsets.fromLTRB(0, 0, 0, 3),
                    decoration: idx == activeIdx - 5
                        ? const BoxDecoration(
                            // idx==activeIdx - 7 ? const BoxDecoration(
                            // color : Colors.transparent,
                            color: Color(0xFF13A9FC),
                            borderRadius: BorderRadius.all(Radius.circular(5)))
                        : const BoxDecoration(
                            // color : Colors.transparent,
                            color: Colors.white,
                          ),
                    padding: containerActionPadding[idx + 6],
                    child: idx == activeIdx - 5
                        ? activeSimulationIcons[idx]
                        : inactiveSimulationIcons[idx],
                    // padding: containerActionPadding[idx+7],
                    // child: idx == activeIdx - 7 ? activeSimulationIcons[idx] : inactiveSimulationIcons[idx],
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
