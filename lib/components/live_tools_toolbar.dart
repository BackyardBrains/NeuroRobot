import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:flutter_svg/svg.dart';
import 'package:spikerbot/components/menu_icon_animation.dart';

class LiveLeftToolbar extends StatefulWidget {
  LiveLeftToolbar({
    super.key,
    required this.callback,
    required this.isPlaying,
    required this.menuIdx,
  });
  late Function callback;
  final int menuIdx;
  final bool isPlaying;

  @override
  State<LiveLeftToolbar> createState() => _LiveLeftToolbarState();
}

class _LiveLeftToolbarState extends State<LiveLeftToolbar> {
  List<Widget> menuIcons = [];

  List<String> activeIconsPath = [];
  List<String> inactiveIconsPath = [];

  // Use Pin 1 and Pin 2
  // We will manually populate active/inactive lists below based on specific filenames
  List<String> iconsPath = [];
  
  List<SoundHandle> arrHandleDragNeuronSound = [];
  
  SoLoud? soloud;
  AudioSource? neuronSpikeSource;
  AudioSource? neuronOnTouchSource;
  
  getSound() {
    if (soloud!= null && soloud!.isInitialized) {
      Future.delayed(const Duration(milliseconds: 1500), () async {
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

    // Specific filenames as requested
    inactiveIconsPath = [
      "assets/icons/DragmenuPin1Placed.svg",
      "assets/icons/DragmenuPin2Placed.svg"
    ];
    activeIconsPath = [
      "assets/icons/DragmenuPin1Lifted.svg",
      "assets/icons/DragmenuPin2Lifted.svg"
    ];

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
              }
            }
          },
          // Use 10 and 11 as unique IDs for Live Mode Pins
          data: idx + 10,
          onDragStarted: () async {
            print("Drag started Live Pin ${idx + 10}");
            // Pass the Live Pin ID to the callback
            widget.callback({
              "modeIdx": idx + 10,
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
            widget.callback({
              "modeIdx": -1,
            });
            if (arrHandleDragNeuronSound.isNotEmpty) {
              SoundHandle handleDragNeuronSound = arrHandleDragNeuronSound[arrHandleDragNeuronSound.length - 1];
              if (handleDragNeuronSound != null){
                soloud?.fadeVolume(handleDragNeuronSound!, 0, const Duration(milliseconds: 300));
                soloud?.scheduleStop(handleDragNeuronSound!, const Duration(milliseconds: 300));
              }
            }
          },
          feedback: MenuIconAnimation(
            svgPath: activeIconsPath[idx],
            width: 175, // 70 * 2.0 * 1.25 = 175
            height: 175, 
          ),
          dragAnchorStrategy: (draggable, context, offset) {
            return const Offset(87.5, 87.5); // Center of 175
          },
          childWhenDragging: Transform.translate(
            offset: const Offset(16, 24), // Left 4, Down 4 from (20,20)
            child: Transform.scale(
              scale: 2.0, // 80% of 2.5
              child: SvgPicture.asset(
                inactiveIconsPath[idx],
                width: 70,
                height: 70,
              ),
            ),
          ),
          child: Transform.translate(
            offset: const Offset(16, 24), // Left 4, Down 4 from (20,20)
            child: Transform.scale(
              scale: 2.0, // 80% of 2.5
              child: SvgPicture.asset(inactiveIconsPath[idx],
                  width: 70,
                  height: 70,
                  semanticsLabel: 'Inactive Pin ${idx + 1}'),
            ),
          ),
        ),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        margin: const EdgeInsets.only(top: 30), child: createLeftToolbar());
  }

  Widget createLeftToolbar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(20.0),
          bottomRight: Radius.circular(20.0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            spreadRadius: 1.0,
            blurRadius: 1.0,
            offset: const Offset(1.0, 1.0),
          ),
        ],
      ),
      margin: const EdgeInsets.fromLTRB(0, 10, 0, 10),
      width: 70,
      child: Column(
        children: menuIcons,
      ),
    );
  }
}
