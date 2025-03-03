/*
  Belgrade 11 July 2024
  We are using Draggable and DragTarget, https://www.youtube.com/watch?v=q4x2G_9-Mu0
*/
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:flutter_svg/svg.dart';
// import 'package:metooltip/metooltip.dart';
import 'package:neurorobot/components/menu_icon_animation.dart';

class LeftToolbar extends StatefulWidget {
  LeftToolbar({
    super.key,
    required this.callback,
    required this.isPlaying,
    required this.menuIdx,
    //required this.startDragOffset
  });
  late Function callback;
  final int menuIdx;
  final bool isPlaying;
  // final Offset startDragOffset;

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
    // "assets/icons/DragMenuIconsNucleus",
    // "assets/icons/DragMenuIconsNote"
  ];
  
  List<SoundHandle> arrHandleDragNeuronSound = [];
  
  SoLoud? soloud;
  AudioSource? neuronSpikeSource;
  AudioSource? neuronOnTouchSource;
  
  

  getSound() {
    if (soloud!= null && soloud!.isInitialized) {
      Future.delayed(const Duration(milliseconds: 1500), () async {
        // print("GET SOUNDZZ");
        // print(soloud);
        // print(soloud!.isInitialized);
        try{
          await soloud!.loadAsset('assets/audio/NeuronSpikes.mp3').then((src){
            neuronSpikeSource = src;
          }).catchError((onError){
            print("onError");
            print(onError);
          });      
          await soloud!.loadAsset('assets/audio/NeuronOnTouch.mp3').then((src){
            neuronOnTouchSource = src;
          }).catchError((onError){
            print("onError");
            print(onError);
          });      

        }catch(err){
            print("onError");
            print(err);
          
        }
      });
    } else {
      Future.delayed(const Duration(milliseconds: 1000), getSound);
    }

  }

  @override
  void initState() {
    super.initState();
    soloud = SoLoud.instance;
    getSound();
    // soloud.init().then((_){
    //   soloud.loadAsset('assets/audio/test.mp3').then((src){
    //     source = src;
    //   });

    // });

    for (int idx = 0; idx < iconsPath.length; idx++) {
      inactiveIconsPath.add("${iconsPath[idx]}0.svg");
      activeIconsPath.add("${iconsPath[idx]}1.svg");
    }
    print("inactiveIconsPath");
    print(inactiveIconsPath);
    for (int idx = 0; idx < inactiveIconsPath.length; idx++) {
      menuIcons.add(Container(
        padding: const EdgeInsets.all(3),
        child: Draggable(
          onDragCompleted: (){
            if (arrHandleDragNeuronSound.isNotEmpty) {
              SoundHandle handleDragNeuronSound = arrHandleDragNeuronSound[arrHandleDragNeuronSound.length - 1];
              if ( handleDragNeuronSound != null){
                soloud?.fadeVolume(handleDragNeuronSound!, 0, const Duration(milliseconds: 300));
                soloud?.scheduleStop(handleDragNeuronSound!, const Duration(milliseconds: 300));
                Future.delayed(const Duration(milliseconds: 300), () {
                  arrHandleDragNeuronSound.removeAt(0);
                });
                // soloud.stop(handleDragNeuronSound!);
              }
            }
          },
          data: idx,
          onDragStarted: () async {
            // change the background to be gray
            print("Drag started $idx");
            widget.callback({
              "modeIdx": idx,
            });
            if (soloud != null && neuronSpikeSource!= null) {
              SoundHandle handleDragNeuronSound = await soloud!.play(neuronSpikeSource!);
              soloud?.fadeVolume(handleDragNeuronSound!, 0.5, const Duration(milliseconds: 500));

              soloud?.setLooping(handleDragNeuronSound, true);
              arrHandleDragNeuronSound.add(handleDragNeuronSound);
            }
            if (soloud != null && neuronOnTouchSource!= null) {
              soloud?.play(neuronOnTouchSource!);
            }

          },
          onDraggableCanceled: (_, __) {
            print('Drag Canceled');
            // change the background to be black
            widget.callback({
              "modeIdx": -1,
            });
            if (arrHandleDragNeuronSound.isNotEmpty) {
              SoundHandle handleDragNeuronSound = arrHandleDragNeuronSound[arrHandleDragNeuronSound.length - 1];
              if (handleDragNeuronSound != null){
                soloud?.fadeVolume(handleDragNeuronSound!, 0, const Duration(milliseconds: 300));
                soloud?.scheduleStop(handleDragNeuronSound!, const Duration(milliseconds: 300));
                // soloud.stop(handleDragNeuronSound!);
              }
            }
          },
          feedback: MenuIconAnimation(
            svgPath: activeIconsPath[idx],
            width: 90,
            height: 90,
          ),
          dragAnchorStrategy: (draggable, context, offset) {
            // _dragOffset = offset;
            // return Offset(offset.dx - draggable.size.width / 2, offset.dy - draggable.size.height / 2);
            // print("draggable");
            // print(draggable);
            return const Offset(45, 45);
            // return const Offset(0, 0);
          },
          childWhenDragging: SvgPicture.asset(
            // colorFilter: ColorFilter.mode(Colors.red, BlendMode.srcIn),
            inactiveIconsPath[idx],
            width: 70,
            height: 70,
          ),
          child: SvgPicture.asset(inactiveIconsPath[idx],
              width: 70,
              height: 70,
              semanticsLabel: 'Inactive Excitatory neuron'),
        ),
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
            color: Colors.black.withOpacity(0.5), // Shadow color
            spreadRadius: 1.0, // Adjust shadow spread
            blurRadius: 1.0, // Adjust shadow blur
            offset: const Offset(1.0, 1.0), // Offset shadow slightly
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
