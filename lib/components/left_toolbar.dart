import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:metooltip/metooltip.dart';

class LeftToolbar extends StatefulWidget {
  LeftToolbar(
      {super.key,
      required this.callback,
      required this.isPlaying,
      required this.menuIdx});
  late Function callback;
  final int menuIdx;
  final bool isPlaying;

  @override
  State<LeftToolbar> createState() => _RightToolbarState();
}

class _RightToolbarState extends State<LeftToolbar> {
  List<Widget> menuIcons = [];

  List<String> activeIconsPath = [];
  List<String> inactiveIconsPath = [];

  List<String> iconsPath = [
    "assets/icons/DragMenuIconsExcitatory",
    "assets/icons/DragMenuIconsInhibitory",
    "assets/icons/DragMenuIconsNucleus",
    "assets/icons/DragMenuIconsNote"
  ];

  @override
  void initState() {
    super.initState();
    for (int idx = 0; idx < iconsPath.length; idx++) {
      inactiveIconsPath.add("${iconsPath[idx]}0.svg");
      activeIconsPath.add("${iconsPath[idx]}1.svg");
    }
    print("inactiveIconsPath");
    print(inactiveIconsPath);
    for (int idx = 0; idx < inactiveIconsPath.length; idx++) {
      menuIcons.add(Container(
        padding: const EdgeInsets.all(3),
        child: SvgPicture.asset(inactiveIconsPath[idx],
            width: 70,
            height: 70,
            semanticsLabel: 'Inactive Excitatory neuron'),
      ));
    }
    // print("widget.menuIcons");
    // print(menuIcons);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        margin: const EdgeInsets.only(top: 30), child: createLeftToolbar());
  }

  Widget createLeftToolbar() {
    return Container(
      // color: Colors.red,
      decoration: BoxDecoration(
        color: Colors.white, // Container background color
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(20.0),
          bottomRight: Radius.circular(20.0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5), // Shadow color
            spreadRadius: 5.0, // Adjust shadow spread
            blurRadius: 7.0, // Adjust shadow blur
            offset: const Offset(4.0, 4.0), // Offset shadow slightly
          ),
        ],
      ),
      margin: const EdgeInsets.fromLTRB(0, 10, 0, 10),
      // color: Colors.red,
      width: 70,
      child: Column(
        children: menuIcons,
      ),
    );
  }
}
