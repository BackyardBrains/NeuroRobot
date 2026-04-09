import 'dart:async';
import 'dart:convert';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:spikerbot/utils/example_brain_loader.dart';
import 'package:spikerbot/utils/brain_annotation.dart';

import 'package:fialogs/fialogs.dart';
import 'package:file_picker/file_picker.dart';
import 'package:filesystem_picker/filesystem_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:spikerbot/brands/brandguide.dart';
import 'package:path/path.dart';
// import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:responsive_grid/responsive_grid.dart';
import 'package:sn_progress_dialog/progress_dialog.dart';
import 'package:permission_handler/permission_handler.dart';

TextEditingController tecBrainName = TextEditingController();
TextEditingController tecBrainDescription = TextEditingController();
bool isDeleteMode = false;
int isSavingMode = 1;
// bool isEditingMenu = false;
bool isEditingMenu = true;
bool isUploading = false;
bool dialogIsSaving = false; // true during save ops → blocks controller listener from setting unsaved flag
// Thumbnail Future cache — keyed by file path; cleared on dialog open and file changes
Map<String, Future<Uint8List>> thumbnailCache = {};
ValueNotifier<bool> brainHasUnsavedChanges = ValueNotifier<bool>(false);  // true when canvas modified since last save
bool isCurrentBrainExample = false;   // true when current brain came from Example Brains
String currentFileName = "-";
Map mapStatus = {};

/// Annotations on the currently loaded brain — set by the page before opening
/// the dialog so the Current Brain tab can display them.
List<BrainAnnotation> currentBrainAnnotations = [];
/// Called when the user taps "Add Annotation" — the page enters annotation mode.
VoidCallback? onAddAnnotationRequested;
/// Called after the user reorders or deletes an annotation so the page marks unsaved.
VoidCallback? onAnnotationsModified;
/// Called when the user taps an annotation card to view/edit it.
/// Receives the annotation and its current index in the list.
void Function(BrainAnnotation ann, int idx)? onAnnotationViewRequested;

// String infoPath = "${Platform.pathSeparator}info";
// String imagesPath =
//     "${Platform.pathSeparator}spikerbot${Platform.pathSeparator}images";
String textPath =
    "${Platform.pathSeparator}spikerbot${Platform.pathSeparator}text";
List<File> fileNames = [];

Directory? documentPath;
List<Map<String, String>> fileInfos = [];

// ── Annotation list drag state ─────────────────────────────────────────────
// Custom vertical drag avoids ReorderableListView's FittedBox coordinate bug.
int? _annDraggingIdx;          // which item is being dragged
double _annTotalDy = 0;        // accumulated vertical movement (list-local coords)
double _annStartTouchLocalY = 0; // touch Y in list-local coords at drag start
double _annStartScrollOffset = 0; // offset at drag start
final GlobalKey _annListKey = GlobalKey();
const double _annItemEst = 80.0; // estimated item height in logical pixels

bool isLoadBrainDialog = false;
int myBrainsSortMode = 0; // 0=Recent, 1=Name, 2=Size
bool myBrainsSortAscending = false;
List<String> activeFilters = [];

Future<List<File>> loadBrainFiles(fileInfos, context) async {
  // String imagesPath = "";

  List<File> fileNames = [];
  // fileInfos = [];

  isLoadBrainDialog = true;
  documentPath = Directory((await getApplicationDocumentsDirectory()).path);
  final Directory directory = Directory("${(documentPath)?.path}$textPath");
  if (!directory.existsSync()) {
    // if (entity.isEmpty) {
    // ignore: use_build_context_synchronously
    // noSavedBrainAlert(context);
    return [];
  }

  List<FileSystemEntity> entity = directory.listSync(recursive: false);
  var fileList = entity
      .map((item) => item.path)
      // .where((item) => item.endsWith('.txt') || item.endsWith('.brain'))
      .toList(growable: false);
  // print("FILE LIST ${fileList}");

  if (fileList.isEmpty) {
    // noSavedBrainAlert(context);
    return [];
  }

  var statResults = await Future.wait([
    for (var path in fileList) FileStat.stat(path),
  ]);

  var mtimes = <String, DateTime>{
    for (var i = 0; i < fileList.length; i += 1)
      fileList[i]: statResults[i].changed,
  };
  fileList.sort((a, b) => mtimes[a]!.compareTo(mtimes[b]!));

  for (String fileString in fileList) {
    // {{title@@@description@@@timestamp.brain}}
    if (fileString.contains(".brain")) {
      fileNames.insert(0, File(fileString));
      List<String> arr = fileString.split("@@@");
      final File savedFile = File(fileString);
      if (savedFile.existsSync()) {
        Map<String, String> brainInfo = {};
        // 1. Initial Metadata from Filename
        if (arr.length >= 2) {
          int lastIndex = arr[0].lastIndexOf(Platform.pathSeparator) + 1;
          brainInfo.putIfAbsent("title", () => arr[0].substring(lastIndex));
          brainInfo.putIfAbsent("description", () => arr[1]);
        } else {
           // Simple Filename Fallback
           int lastIndex = fileString.lastIndexOf(Platform.pathSeparator) + 1;
           String simpleName = fileString.substring(lastIndex).replaceAll(".brain", "");
           brainInfo.putIfAbsent("title", () => simpleName);
           brainInfo.putIfAbsent("description", () => "Imported File");
        }

        // 2. Override with Internal Metadata (if available)
        try {
           String content = await savedFile.readAsString();
           Map<String, dynamic> jsonMap = jsonDecode(content);

           // Extract Complexity Size
           int neuronsCount = jsonMap.containsKey("nodes") ? (jsonMap["nodes"] as List).length : 0;
           int synapsesCount = jsonMap.containsKey("edges") ? (jsonMap["edges"] as List).length : 0;
           brainInfo["complexity"] = (neuronsCount + synapsesCount).toString();

           Set<String> tags = {};
           if (jsonMap.containsKey("edges") && jsonMap.containsKey("nodes")) {
              List edges = jsonMap["edges"] as List;
              Set<String> connectedKeys = {};
              for (var edge in edges) {
                 if (edge is String) {
                    var parts = edge.split("_#_");
                    if (parts.length == 2) {
                       connectedKeys.add(parts[0]);
                       connectedKeys.add(parts[1]); 
                    }
                 }
              }
              List nodes = jsonMap["nodes"] as List;
              for (var n in nodes) {
                 if (n is Map && connectedKeys.contains(n["valKey"])) {
                    int idx = n["index"] ?? -1;
                    if (idx == 0) tags.add("Distance");
                    else if (idx == 1 || idx == 2) tags.add("Camera Target");
                    else if (idx == 3) tags.add("Microphone Input");
                    else if (idx == 4) tags.add("Speaker");
                    else if (idx >= 5 && idx <= 8) tags.add("Motor Movement");
                    else if (idx >= 9 && idx <= 12) tags.add("LED Lights");
                 }
              }
           }
           if (jsonMap["mapRemoteControlNeuron"] != null && (jsonMap["mapRemoteControlNeuron"] as Map).isNotEmpty) {
              tags.add("Remote Control");
           }
           brainInfo["tags"] = tags.join(",");

           if (jsonMap.containsKey("info")) {
              var info = jsonMap["info"];
              if (info["title"] != null) brainInfo["title"] = info["title"];
              if (info["description"] != null) brainInfo["description"] = info["description"];
              if (info["timestamp"] != null) brainInfo["timestamp"] = info["timestamp"].toString();
           }
        } catch (e) {
           brainInfo["complexity"] = "0";
           // Ignore parsing errors, stick to filename metadata
        }
        fileInfos.insert(0, brainInfo);
      } else {
        Map<String, String> brainInfo = {
          "title": "Default title",
          "description": "Old file version, please recreate and delete this."
        };
        fileInfos.insert(0, brainInfo);
      }

    } else
    if (fileString.contains(".txt")) {
      fileNames.insert(0, File(fileString));
      List<String> arr = fileString.split("@@@");
      final File savedFile = File(fileString);
      if (savedFile.existsSync()) {
        Map<String, String> brainInfo = {};
        if (arr.length >= 3) {
           brainInfo.putIfAbsent("title", () => arr[1]);
           brainInfo.putIfAbsent("description", () => arr[2].replaceAll(".txt", ""));
        } else {
           // Fallback for simple .txt files
           int lastIndex = fileString.lastIndexOf(Platform.pathSeparator) + 1;
           String simpleName = fileString.substring(lastIndex).replaceAll(".txt", "");
           brainInfo.putIfAbsent("title", () => simpleName);
           brainInfo.putIfAbsent("description", () => "Legacy/Imported File");
        }
        fileInfos.insert(0, brainInfo);
      } else {
        Map<String, String> brainInfo = {
          "title": "Default title",
          "description": "Old file version, please recreate and delete this."
        };
        fileInfos.insert(0, brainInfo);
      }
    }
  }

  return fileNames;
}

String brainNameFromFileName(String filename) {
  filename = filename.replaceAll(".png", "");
  filename = filename.replaceAll("Brain", "");
  return filename;
}

Future<Uint8List> getImageFromText(path) async {
  Uint8List imageBytes = Uint8List(0);
  final File savedFile = File(path);
  if (savedFile.existsSync()) {
    String strSavedFile = await savedFile.readAsString();
    // printDebug("strSavedFile");
    // printDebug(strSavedFile);
    Map<String, dynamic> mapSavedFile = jsonDecode(strSavedFile);
    imageBytes = Uint8List.fromList(mapSavedFile["screenshot"].cast<int>());
  }

  return imageBytes;
}

SoLoud? soloud;
AudioSource? pageFlipSource;
AudioSource? buttonOnPressedSource;
AudioSource? buttonPopSource;
AudioSource? eraseOnPressedSource;
SoundHandle? pageFlipHandle;
SoundHandle? buttonOnPressedHandle;
SoundHandle? buttonPopHandle;
SoundHandle? eraseOnPressedHandle;

Future<void> showLoadBrainDialog(BuildContext context, String title,
    selectCallback, saveCallback, pMapStatus) async {
  soloud = SoLoud.instance;
  try{
    pageFlipSource = await soloud?.loadAsset('assets/audio/PageFlip.mp3');
    buttonOnPressedSource = await soloud?.loadAsset('assets/audio/ButtonOnPress.mp3');
    buttonPopSource = await soloud?.loadAsset('assets/audio/ButtonPop.mp3');
    eraseOnPressedSource = await soloud?.loadAsset('assets/audio/Erase.mp3');
  }catch(err){}

  mapStatus = pMapStatus;
  printDebug("mapStatus");
  printDebug(mapStatus);
  isSavingMode = pMapStatus["isSavingBrain"];
  currentFileName = pMapStatus["currentFileName"];

  activeFilters.clear();
  fileInfos = [];
  _annDraggingIdx = null; _annTotalDy = 0; // reset drag state on dialog open
  fileNames = await loadBrainFiles(fileInfos, context);
  // if (fileNames.isEmpty) return;

  printDebug("currentFileName0");
  printDebug(currentFileName);
  if (currentFileName != "-") {
    int tempIdx = 0;
    int loadedIdx = -1;
    for (var file in fileNames) {
      if (file.path.contains(currentFileName)) {
        printDebug("file.path");
        printDebug(file.path);
        printDebug(currentFileName);
        loadedIdx = tempIdx;
      }
      tempIdx++;
    }
    if (loadedIdx >= 0) {
      tecBrainName.text = fileInfos[loadedIdx]["title"]!;
      tecBrainDescription.text = fileInfos[loadedIdx]["description"]!;
    }
  }

  printDebug("fileNames");
  printDebug(fileInfos);

  int selectedTab = 2;
  // isEditingMenu removed – always show description on Current Brain tab

  // ignore: use_build_context_synchronously
  return showDialog<void>(
    context: context,
    barrierDismissible: false, // We handle dismissal manually for perfect control
    barrierColor: Colors.transparent, // We draw our own barrier
    useSafeArea: false,
    builder: (BuildContext context) {
      final ScrollController annScrollCtrl = ScrollController();
      Timer? scrollTimer;
      void startScroll(double speed) {
        if (scrollTimer?.isActive ?? false) return;
        scrollTimer = Timer.periodic(const Duration(milliseconds: 16), (t) {
          if (!annScrollCtrl.hasClients) return;
          double current = annScrollCtrl.offset;
          double next = (current + speed).clamp(0.0, annScrollCtrl.position.maxScrollExtent);
          annScrollCtrl.jumpTo(next);
        });
      }
      void stopScroll() { scrollTimer?.cancel(); scrollTimer = null; }

      return StatefulBuilder(builder: (ctx, setState) {
        printDebug("REDRAW - LoadBrainDialog");
        
        bool allowClose = false;

        void closeDialog() {
           printDebug("CLOSING DIALOG (Valid Action)");
           allowClose = true;
           Navigator.of(context).pop();
        }

        double topPadding = MediaQuery.of(context).padding.top;
        double bottomPadding = MediaQuery.of(context).padding.bottom;
        double verticalPadding = MediaQuery.of(context).size.shortestSide < 600 ? topPadding + 8 : 15 + topPadding;
        double bottomPad = MediaQuery.of(context).size.shortestSide < 600 ? bottomPadding : 15;
        
        // Manual Barrier Implementation
        return WillPopScope(
          onWillPop: () async {
            printDebug("POP ATTEMPTED (System/Back). ALLOWED: $allowClose");
            return allowClose;
          },
          child: Stack(
            children: [
              // 1. The Barrier (Tap to close - SIDES ONLY)
              Positioned.fill(
                child: GestureDetector(
                  onTapUp: (details) {
                     // Since the inner card has a shield, any tap that makes it here is outside the card.
                     // We just check the top 100px safety shoulder.
                     double touchY = details.globalPosition.dy;
                     
                     if (touchY < 100) {
                        printDebug("BARRIER TAP IN HEADER SAFETY ZONE (Y < 100) - IGNORED");
                        return;
                     }

                     printDebug("BARRIER TAPPED - CLOSING");
                     closeDialog();
                  },
                  onPanDown: (_) {
                    printDebug("BARRIER DRAG CAUGHT - IGNORING");
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    color: Colors.black54,
                  ),
                ),
              ),
              // 2. The Content (Tap to do nothing/interact)
              Center(
                child: Padding(
                  padding: EdgeInsets.only(
                    left: MediaQuery.of(context).size.shortestSide < 600 ? 8 : 50,
                    right: MediaQuery.of(context).size.shortestSide < 600 ? 8 : 50,
                    top: verticalPadding,
                    bottom: bottomPad,
                  ),
                  child: GestureDetector(
                    onTap: () {
                      printDebug("SHIELD TAPPED");
                    }, // Shield: Absorb taps inside the card
                    onTapUp: (_) {
                       printDebug("SHIELD TAP UP CAUGHT");
                    },
                    onPanDown: (_) {
                      printDebug("SHIELD DRAG CAUGHT");
                    },
                    behavior: HitTestBehavior.opaque,
                    child: Material(
                    type: MaterialType.card,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    clipBehavior: Clip.antiAlias,
                    color: Colors.white, // Explicit card color
                     child: SizedBox(
                       width: MediaQuery.of(context).size.width -
                           MediaQuery.of(context).padding.left -
                           MediaQuery.of(context).padding.right,
                       height: MediaQuery.of(context).size.height,
                      child: showBrainDisplay(
                          context, fileNames, selectCallback, saveCallback, setState, closeDialog,
                          annScrollCtrl: annScrollCtrl, startScroll: startScroll, stopScroll: stopScroll,
                          selectedTab: selectedTab,
                          onTabChanged: (idx) async {
                            selectedTab = idx;
                            fileInfos = [];
                            fileNames = [];
                            setState((){});
                            
                            if (idx == 0) {
                              fileNames = await loadBrainFiles(fileInfos, context);
                            } else if (idx == 1) {
                              fileNames = await loadExampleBrains(fileInfos);
                            } // idx==2 (Current Brain): no file load
                            setState((){});
                          }),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
      });
    },
  ).whenComplete(() => isLoadBrainDialog = false);
}

void noSavedBrainAlert(context) {
  customAlertDialog(
    context,
    const Text("Load Brain"),
    const Text("There is no saved brain."),
    titleIcon: const Icon(Icons.save),
    positiveButtonText: "OK",
    positiveButtonAction: () {},
    negativeButtonText: "",
    negativeButtonAction: () {},
    neutralButtonText: "",
    neutralButtonAction: () {},
    hideNeutralButton: true,
    closeOnBackPress: false,
    confirmationDialog: false,
    confirmationMessage: "",
  );
}

showBrainDisplay(BuildContext context, List<File> fileNamez, selectCallback,
    saveCallback, setState, Function closeDialog, {int selectedTab = 0, Function(int)? onTabChanged, ScrollController? annScrollCtrl, Function(double)? startScroll, Function()? stopScroll}) {
  return LayoutBuilder(builder: (ctx, constraints) {
    final bool isLandscape = constraints.maxWidth > constraints.maxHeight;
    List<String> imageIds = [];
    List<String> imageTitles = [];
    List<String> imageDescriptions = [];
    List<List<int>> imageMemories =
        List.generate(fileNames.length, (index) => [0]);
    int idx = 0;

    fileNames.every((file) {
      String filename = basename(file.path);
      // filename = filename.replaceAll(".txt", "");
      imageIds.add(filename);

      try {
        imageTitles.add(fileInfos[idx]["title"]!);
        imageDescriptions.add(fileInfos[idx]["description"]!);
        idx++;
      } catch (err) {
        imageTitles.add("Default Title");
        imageDescriptions.add("Default Description");
        idx++;
        printDebug("load err");
        printDebug(err);
        printDebug(fileInfos);
      }
      return true;
    });

    // ── Pre-Filter based on active filters ──
    List<int> filteredIndices = [];
    for (int i = 0; i < fileNames.length; i++) {
       if (selectedTab != 2 && activeFilters.isNotEmpty) {
          String tagsStr = fileInfos[i]["tags"] ?? "";
          List<String> brainTags = tagsStr.split(",");
          bool passesAll = true;
          for (String f in activeFilters) {
             if (!brainTags.contains(f)) { passesAll = false; break; }
          }
          if (!passesAll) continue;
       }
       filteredIndices.add(i);
    }

    // ── Determine sort order based on active mode ──
    List<int> sortedIndices = List.from(filteredIndices);
    if (selectedTab != 2) {
      if (myBrainsSortMode == 0) { // Recent (timestamp)
        sortedIndices.sort((a, b) {
          DateTime timeA;
          try { timeA = DateTime.parse(fileInfos[a]["timestamp"] ?? ""); } catch(_) { timeA = fileNames[a].statSync().changed; }
          DateTime timeB;
          try { timeB = DateTime.parse(fileInfos[b]["timestamp"] ?? ""); } catch(_) { timeB = fileNames[b].statSync().changed; }
          return myBrainsSortAscending ? timeA.compareTo(timeB) : timeB.compareTo(timeA);
        });
      } else if (myBrainsSortMode == 1) { // Alphabetical
        sortedIndices.sort((a, b) {
          int cmp = imageTitles[a].toLowerCase().compareTo(imageTitles[b].toLowerCase());
          return myBrainsSortAscending ? -cmp : cmp; // Default descending represents strictly A-Z (cmp)
        });
      } else if (myBrainsSortMode == 2) { // File Size
        sortedIndices.sort((a, b) {
          int sizeA = int.tryParse(fileInfos[a]["complexity"] ?? "0") ?? fileNames[a].lengthSync();
          int sizeB = int.tryParse(fileInfos[b]["complexity"] ?? "0") ?? fileNames[b].lengthSync();
          // Since descending usually implies highest complexity first, invert default sort
          return myBrainsSortAscending ? sizeB.compareTo(sizeA) : sizeA.compareTo(sizeB);
        });
      }
    }


    // ── Unsaved-changes guard ─────────────────────────────────────────────────
    // Returns true if the caller should proceed, false if the user cancelled.
    // When the user picks "Save", saves the current brain first then returns true.
    Future<bool> _confirmIfUnsaved() async {
      if (!brainHasUnsavedChanges.value) return true;
      final result = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const _UnsavedChangesDialog(),
      );
      if (result == 'save') {
        // Save current brain then proceed
        if (isSavingMode == 10) {
          final f = File(currentFileName);
          if (f.existsSync()) f.deleteSync();
        }
        currentFileName = await saveCallback(tecBrainName.text, tecBrainDescription.text);
        mapStatus['isSavingBrain'] = 10;
        mapStatus['currentFileName'] = currentFileName;
        isSavingMode = 10;
        brainHasUnsavedChanges.value = false;
        setState(() {});
        return true;
      } else if (result == 'discard') {
        return true;
      }
      return false; // cancelled — stay in dialog
    }

    return Stack(
      children: [
        Positioned(
          left: 0,
          top: 0,
          child: SizedBox(
            width: constraints.maxWidth,
            height: constraints.maxHeight,
            child: Column(
              children: [
                // ═══════════ UNIFIED TOP ROW ═══════════
                Container(
                  margin: const EdgeInsets.only(top: 6, bottom: 0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── × Close (left) ──
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTapDown: (details) async {
                          if (buttonOnPressedSource != null) {
                            buttonOnPressedHandle = await soloud?.play(buttonOnPressedSource!, looping: false);
                          }
                        },
                        onTap: () async {
                          if (buttonPopSource != null) {
                            buttonPopHandle = await soloud?.play(buttonPopSource!, looping: false);
                          }
                          closeDialog();
                        },
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          width: 40, height: 40,
                          alignment: Alignment.center,
                          child: const Icon(Icons.close, size: 26),
                        ),
                      ),
                      // ── Tabs (centered, flex) ──
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.center,
                          child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ①  Current Brain (orange when active + V-arrow)
                            _TapDarken(
                              onTapDown: () async {
                                if (buttonOnPressedSource != null) buttonOnPressedHandle = await soloud?.play(buttonOnPressedSource!, looping: false);
                              },
                              onTap: () async {
                                if (buttonPopSource != null) buttonPopHandle = await soloud?.play(buttonPopSource!, looping: false);
                                if (selectedTab != 2) { isUploading = false; isDeleteMode = false; onTabChanged?.call(2); }
                              },
                              builder: (pressed) => Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                    decoration: BoxDecoration(
                                      color: pressed ? (selectedTab == 2 ? const Color(0xFFE06040) : Colors.grey.shade400) : (selectedTab == 2 ? const Color(0xFFFD8164) : Colors.grey[300]),
                                      borderRadius: BorderRadius.circular(100),
                                      boxShadow: (pressed || selectedTab != 2) ? [] : [BoxShadow(color: Colors.black.withOpacity(0.18), blurRadius: 5, offset: const Offset(0, 2))],
                                    ),
                                    child: ValueListenableBuilder<bool>(valueListenable: brainHasUnsavedChanges, builder: (_, unsaved, __) => Text(unsaved ? 'Current Brain (unsaved)' : 'Current Brain',
                                      style: TextStyle(
                                        fontFamily: 'Roboto',
                                        fontSize: 16,
                                        color: selectedTab == 2 ? Colors.white : Colors.black,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    )),
                                  ),
                                  if (selectedTab == 2)
                                    SizedBox(
                                      width: 44, height: 10,
                                      child: CustomPaint(
                                        painter: _BrainCardArrowPainter(color: const Color(0xFFFD8164)),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            // ②  My Brains (blue when active)
                            _TapDarken(
                              onTapDown: () async {
                                if (buttonOnPressedSource != null) buttonOnPressedHandle = await soloud?.play(buttonOnPressedSource!, looping: false);
                              },
                              onTap: () async {
                                if (buttonPopSource != null) buttonPopHandle = await soloud?.play(buttonPopSource!, looping: false);
                                if (selectedTab != 0) { isUploading = false; isDeleteMode = false; onTabChanged?.call(0); }
                              },
                              builder: (pressed) => Container(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                                decoration: BoxDecoration(
                                  color: pressed ? (selectedTab == 0 ? Colors.blue.shade700 : Colors.grey.shade400) : (selectedTab == 0 ? Colors.blue : Colors.grey[300]),
                                  borderRadius: BorderRadius.circular(100),
                                  boxShadow: (pressed || selectedTab != 0) ? [] : [BoxShadow(color: Colors.black.withOpacity(0.18), blurRadius: 5, offset: const Offset(0, 2))],
                                ),
                                child: Text('My Brains',
                                  style: TextStyle(
                                    fontFamily: 'Roboto',
                                    fontSize: 16,
                                    color: selectedTab == 0 ? Colors.white : Colors.black,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // ③  Example Brains (blue when active)
                            _TapDarken(
                              onTapDown: () async {
                                if (buttonOnPressedSource != null) buttonOnPressedHandle = await soloud?.play(buttonOnPressedSource!, looping: false);
                              },
                              onTap: () async {
                                if (buttonPopSource != null) buttonPopHandle = await soloud?.play(buttonPopSource!, looping: false);
                                if (selectedTab != 1) { isUploading = false; isDeleteMode = false; onTabChanged?.call(1); }
                              },
                              builder: (pressed) => Container(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                                decoration: BoxDecoration(
                                  color: pressed ? (selectedTab == 1 ? Colors.blue.shade700 : Colors.grey.shade400) : (selectedTab == 1 ? Colors.blue : Colors.grey[300]),
                                  borderRadius: BorderRadius.circular(100),
                                  boxShadow: (pressed || selectedTab != 1) ? [] : [BoxShadow(color: Colors.black.withOpacity(0.18), blurRadius: 5, offset: const Offset(0, 2))],
                                ),
                                child: Text('Example Brains',
                                  style: TextStyle(
                                    fontFamily: 'Roboto',
                                    fontSize: 16,
                                    color: selectedTab == 1 ? Colors.white : Colors.black,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        ),
                      ),
                      // ── Spacer to balance the Close button (approx 46px) ──
                      const SizedBox(width: 46),
                    ],
                  ),
                ),
                // ─── Action Row: moved to Stack bottom Positioned (see below) ───
                if (false) // handled by Stack Positioned below
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: selectedTab == 2 ? [
                      // ── Current Brain: Save / Save A Copy / New ──
                      if (!isCurrentBrainExample) ...[
                        _buildActionBtn(
                          icon: SvgPicture.asset('assets/icons/Save.svg', width: 60, height: 60),
                          label: 'Save',
                          onTap: () async {
                            if (isSavingMode == 10) { File d = File(currentFileName); if (d.existsSync()) d.deleteSync(); }
                            currentFileName = await saveCallback(tecBrainName.text, tecBrainDescription.text);
                            mapStatus["isSavingBrain"] = 10;
                            mapStatus["currentFileName"] = currentFileName;
                            fileInfos = []; fileNames = await loadBrainFiles(fileInfos, context);
                            isSavingMode = 10; brainHasUnsavedChanges.value = false;
                            setState(() {});
                          },
                        ),
                        const SizedBox(width: 16),
                      ],
                      _buildActionBtn(
                        icon: SvgPicture.asset('assets/icons/SaveAs.svg', width: 60, height: 60),
                        label: isCurrentBrainExample ? 'Save As' : 'Save A Copy',
                        onTap: () async {
                          if (buttonPopSource != null) soloud?.play(buttonPopSource!, looping: false);
                          await Future.delayed(const Duration(milliseconds: 100));
                          if (!context.mounted) return;
                          singleInputDialog(context, "Save A Copy",
                            DialogTextField(label: "Brain name", obscureText: false, textInputType: TextInputType.text,
                              validator: (v) => v!.isEmpty ? "Required!" : null,
                              onEditingComplete: (v) { printDebug(v); }),
                            positiveButtonText: "Save",
                            positiveButtonAction: (title) async {
                              dialogIsSaving = true;
                              ProgressDialog pd = ProgressDialog(context: context);
                              pd.show(msg: 'Saving Brain...');
                              currentFileName = await saveCallback(title, tecBrainDescription.text);
                              mapStatus["isSavingBrain"] = 10; mapStatus["currentFileName"] = currentFileName;
                              tecBrainName.text = title; isCurrentBrainExample = false;
                              isSavingMode = 10; brainHasUnsavedChanges.value = false;
                              if (onTabChanged != null) { await onTabChanged(2); } else {
                                fileInfos = []; fileNames = await loadBrainFiles(fileInfos, context);
                              }
                              setState(() {}); pd.close();
                              Future.delayed(const Duration(milliseconds: 200), () { dialogIsSaving = false; });
                            },
                            negativeButtonText: "Cancel", negativeButtonAction: () {},
                            hideNeutralButton: true, closeOnBackPress: false);
                        },
                      ),
                      const SizedBox(width: 16),
                      _buildActionBtn(
                        icon: SvgPicture.asset('assets/icons/NewFile.svg', width: 60, height: 60),
                        label: 'New',
                        onTap: () async {
                          if (!await _confirmIfUnsaved()) return;
                          tecBrainName.clear(); tecBrainDescription.clear();
                          mapStatus["isSavingBrain"] = 1; mapStatus["currentFileName"] = "-";
                          currentFileName = "-"; brainHasUnsavedChanges.value = false; isCurrentBrainExample = false;
                          selectCallback("-1");
                          if (pageFlipSource != null) soloud?.play(pageFlipSource!, looping: false);
                          closeDialog();
                        },
                      ),
                    ] : [
                      // ── My Brains: Import / Share / Delete ──
                      _buildActionBtn(
                        icon: SvgPicture.asset('assets/icons/Import.svg', width: 60, height: 60),
                        label: 'Import',
                        onTap: () async {
                          isUploading = false;
                          if (buttonPopSource != null) buttonPopHandle = await soloud?.play(buttonPopSource!, looping: false);
                          if (Platform.isAndroid) await [Permission.manageExternalStorage].request();
                          String? importPath;
                          if (Platform.isMacOS || Platform.isIOS) {
                            FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['brain']);
                            if (result != null) importPath = result.files.single.path;
                          } else {
                            Directory? rootPath;
                            try { rootPath = await getDownloadsDirectory(); } catch (e) {}
                            if (rootPath == null || !rootPath.existsSync()) rootPath = await getApplicationDocumentsDirectory();
                            importPath = await FilesystemPicker.open(title: 'Open file', context: context, rootDirectory: rootPath, fsType: FilesystemType.file, allowedExtensions: ['.brain'], fileTileSelectMode: FileTileSelectMode.wholeTile);
                          }
                          if (importPath != null) {
                            File srcFile = File(importPath);
                            Directory? doc = await getApplicationDocumentsDirectory();
                            Directory dir = Directory("${doc.path}$textPath");
                            if (dir.existsSync()) srcFile.copySync("${dir.path}${Platform.pathSeparator}${basename(srcFile.path)}");
                          }
                          fileInfos = []; fileNames = await loadBrainFiles(fileInfos, context);
                          setState(() {});
                        },
                      ),
                      const SizedBox(width: 16),
                      _buildActionBtn(
                        icon: SvgPicture.asset('assets/icons/Share.svg', width: 60, height: 60, colorFilter: isUploading ? const ColorFilter.mode(Colors.blue, BlendMode.srcIn) : null),
                        label: 'Share',
                        onTap: () async {
                          if (buttonPopSource != null) buttonPopHandle = await soloud?.play(buttonPopSource!, looping: false);
                          isUploading = !isUploading; setState(() {});
                        },
                      ),
                      const SizedBox(width: 16),
                      _buildActionBtn(
                        icon: SvgPicture.asset('assets/icons/Delete.svg', width: 60, height: 60, colorFilter: isDeleteMode ? const ColorFilter.mode(Colors.red, BlendMode.srcIn) : null),
                        label: 'Delete',
                        onTap: () async {
                          isDeleteMode = !isDeleteMode;
                          setState(() {});
                        },
                      ),
                    ],
                  ),
                ),
                // ═══════════ CURRENT BRAIN PANEL (tab == 2) ═══════════
                if (selectedTab == 2) ...[
                  // Import / Share / BoldoaMat title row
                  // Title row — landscape: SizedBox height extended to 57px so the
                  // button (h=34) with Padding(top:23) fits without overflow.
                  // With CrossAxisAlignment.start the TextField Container(h=40) anchors at
                  // top, placing its underline at y=40. Button centre = 21+19 = 40 (perfect aligned).
                  SizedBox(
                    height: 59, // Set height so 38px button padded by 21px fits exactly
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(width: 7),
                        const SizedBox(width: 7),
                        // Brain title — BoldoaMat, no char limit shown
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            height: 40,
                            alignment: Alignment.center,
                            child: TextField(
                              maxLength: 200,
                              inputFormatters: [
                                FilteringTextInputFormatter.deny(RegExp(r'[\\/:*?"<>|@]')),
                              ],
                              style: const TextStyle(fontFamily: 'BoldoaMat', fontSize: 22),
                              decoration: const InputDecoration(
                                contentPadding: EdgeInsets.only(top: 10),
                                counterText: "",
                                hintText: 'Name this brain',
                              ),
                              controller: tecBrainName,
                              onChanged: (val) {
                                if (!brainHasUnsavedChanges.value) {
                                  brainHasUnsavedChanges.value = true;
                                  setState(() {});
                                }
                              },
                            ),
                          ),
                        ),
                        // In landscape: pill vertically centred on the TextField underline.
                        // Padding(top:23) on button of height 34 → centre = 23+17 = 40px from
                        // row top = exact y of TextField bottom/underline.
                        if (isLandscape) ...[
                          Padding(
                            padding: const EdgeInsets.only(top: 21, right: 8),
                            child: GestureDetector(
                              onTap: () {
                                onAddAnnotationRequested?.call();
                                closeDialog();
                              },
                              child: Container(
                                width: 196,
                                height: 38,
                                padding: const EdgeInsets.symmetric(horizontal: 14),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFD8164),
                                  borderRadius: BorderRadius.circular(19),
                                  boxShadow: [BoxShadow(color: const Color(0xFFFD8164).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))],
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Icon(Icons.add, color: Colors.white, size: 16),
                                    SizedBox(width: 4),
                                    Text('Add Annotation', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13, letterSpacing: 0.1)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Description — always visible, generous limit
                  Container(
                    color: Colors.transparent,
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 6),
                    child: TextFormField(
                      style: const TextStyle(fontSize: 15),
                      controller: tecBrainDescription,
                      maxLength: 500,
                      decoration: const InputDecoration(
                        counterText: "",
                        hintText: "Describe this brain...",
                        border: InputBorder.none,
                      ),
                      textInputAction: TextInputAction.done,
                      onChanged: (val) {
                        if (!brainHasUnsavedChanges.value) {
                          brainHasUnsavedChanges.value = true;
                          setState(() {});
                        }
                      },
                      minLines: 1,
                      maxLines: 4,
                      keyboardType: TextInputType.text,
                    ),
                  ),
                ],
                // Small landscape gap: action button labels add height to tab row,
                // so a small separator aligns brain cards visually with pill tab center
                if (isLandscape) const SizedBox(height: 6),
                // ── Content area: either brain grid (tabs 0/1) or annotations (tab 2) ──
                if (selectedTab != 2) Expanded(
                  child: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Column(
                    children: [
                      // ── Sort and Filter Pills ──
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Builder(builder: (context) {
                              return _TapDarken(
                                onTapDown: () async {
                                  if (buttonOnPressedSource != null) buttonOnPressedHandle = await soloud?.play(buttonOnPressedSource!, looping: false);
                                },
                                onTap: () async {
                                  if (buttonPopSource != null) buttonPopHandle = await soloud?.play(buttonPopSource!, looping: false);
                                  final RenderBox button = context.findRenderObject() as RenderBox;
                                  final RenderBox overlay = Navigator.of(context).overlay!.context.findRenderObject() as RenderBox;
                                  final RelativeRect position = RelativeRect.fromRect(
                                    Rect.fromPoints(
                                      button.localToGlobal(Offset.zero, ancestor: overlay),
                                      button.localToGlobal(button.size.bottomRight(Offset.zero), ancestor: overlay),
                                    ),
                                    Offset.zero & overlay.size,
                                  );
                                  int? result = await showMenu<int>(
                                    context: context,
                                    position: position,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    items: [
                                      PopupMenuItem<int>(value: 0, child: Listener(behavior: HitTestBehavior.opaque, onPointerDown: (_) async { if (buttonOnPressedSource != null) await soloud?.play(buttonOnPressedSource!, looping: false); }, child: const SizedBox(width: double.infinity, child: Text('Sort by Recent')))),
                                      PopupMenuItem<int>(value: 1, child: Listener(behavior: HitTestBehavior.opaque, onPointerDown: (_) async { if (buttonOnPressedSource != null) await soloud?.play(buttonOnPressedSource!, looping: false); }, child: const SizedBox(width: double.infinity, child: Text('Sort by Name (A-Z)')))),
                                      PopupMenuItem<int>(value: 2, child: Listener(behavior: HitTestBehavior.opaque, onPointerDown: (_) async { if (buttonOnPressedSource != null) await soloud?.play(buttonOnPressedSource!, looping: false); }, child: const SizedBox(width: double.infinity, child: Text('Sort by Complexity')))),
                                    ],
                                  );
                                  if (result != null) {
                                    if (buttonPopSource != null) await soloud?.play(buttonPopSource!, looping: false);
                                    myBrainsSortMode = result;
                                    setState(() {});
                                  }
                                },
                                builder: (pressed) => Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: pressed ? Colors.grey.shade400 : Colors.grey[300],
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: pressed ? [] : [BoxShadow(color: Colors.black.withOpacity(0.18), blurRadius: 5, offset: const Offset(0, 2))],
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.sort, size: 18, color: Colors.black87),
                                      const SizedBox(width: 6),
                                      Text(myBrainsSortMode == 1 ? 'Name (A-Z)' : (myBrainsSortMode == 2 ? 'Complexity' : 'Recent'), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                                    ],
                                  ),
                                ),
                              );
                            }),
                            const SizedBox(width: 6),
                            _TapDarken(
                              onTapDown: () async {
                                if (buttonOnPressedSource != null) buttonOnPressedHandle = await soloud?.play(buttonOnPressedSource!, looping: false);
                              },
                              onTap: () async {
                                if (buttonPopSource != null) buttonPopHandle = await soloud?.play(buttonPopSource!, looping: false);
                                myBrainsSortAscending = !myBrainsSortAscending;
                                setState(() {});
                              },
                              builder: (pressed) => Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                decoration: BoxDecoration(
                                  color: pressed ? Colors.grey.shade400 : Colors.grey[300],
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: pressed ? [] : [BoxShadow(color: Colors.black.withOpacity(0.18), blurRadius: 5, offset: const Offset(0, 2))],
                                ),
                                child: Icon(
                                  myBrainsSortAscending ? Icons.arrow_upward : Icons.arrow_downward, 
                                  size: 18, 
                                  color: Colors.black87
                                ),
                              ),
                            ),
                            const SizedBox(width: 40),
                            _TapDarken(
                              onTapDown: () async {
                                if (buttonOnPressedSource != null) buttonOnPressedHandle = await soloud?.play(buttonOnPressedSource!, looping: false);
                              },
                              onTap: () async {
                                if (buttonPopSource != null) buttonPopHandle = await soloud?.play(buttonPopSource!, looping: false);
                                List<String> options = [
                                  "Distance", "Camera Target", "Microphone Input", 
                                  "Speaker", "Motor Movement", "LED Lights", "Remote Control"
                                ];
                                await showDialog(
                                  context: context,
                                  builder: (BuildContext dContext) {
                                    return StatefulBuilder(
                                      builder: (context, setDialogState) {
                                        return AlertDialog(
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                          title: const Text('Filter Brains', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                          content: SingleChildScrollView(
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: options.map((String filterName) {
                                                return Listener(
                                                  behavior: HitTestBehavior.opaque,
                                                  onPointerDown: (_) async { if (buttonOnPressedSource != null) await soloud?.play(buttonOnPressedSource!, looping: false); },
                                                  child: CheckboxListTile(
                                                    contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                                                    title: Text(filterName, style: const TextStyle(fontSize: 15)),
                                                    value: activeFilters.contains(filterName),
                                                    onChanged: (bool? value) async {
                                                      if (buttonPopSource != null) await soloud?.play(buttonPopSource!, looping: false);
                                                      setDialogState(() {
                                                        if (value == true) {
                                                          activeFilters.add(filterName);
                                                        } else {
                                                          activeFilters.remove(filterName);
                                                        }
                                                      });
                                                    },
                                                  ),
                                                );
                                              }).toList(),
                                            ),
                                          ),
                                          actions: <Widget>[
                                            _TapDarken(
                                              onTapDown: () async { if (buttonOnPressedSource != null) await soloud?.play(buttonOnPressedSource!, looping: false); },
                                              onTap: () async {
                                                if (buttonPopSource != null) await soloud?.play(buttonPopSource!, looping: false);
                                                setDialogState(() { activeFilters.clear(); });
                                              },
                                              builder: (pressed) => Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                                decoration: BoxDecoration(
                                                  color: pressed ? const Color(0xFFEAA0A0) : const Color(0xFFCC4444), // Strong red
                                                  borderRadius: BorderRadius.circular(100),
                                                ),
                                                child: const Text('Clear All', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            _TapDarken(
                                              onTapDown: () async { if (buttonOnPressedSource != null) await soloud?.play(buttonOnPressedSource!, looping: false); },
                                              onTap: () async {
                                                if (buttonPopSource != null) await soloud?.play(buttonPopSource!, looping: false);
                                                Navigator.of(dContext).pop();
                                              },
                                              builder: (pressed) => Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                                decoration: BoxDecoration(
                                                  color: pressed ? const Color(0xFF90D0A0) : const Color(0xFF28A745), // Strong green
                                                  borderRadius: BorderRadius.circular(100),
                                                ),
                                                child: const Text('Apply', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  },
                                );
                                // Update main grid layout when the user closes the filters menu
                                setState(() {});
                              },
                              builder: (pressed) => Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: activeFilters.isNotEmpty ? (pressed ? const Color(0xFFC0DFC0) : const Color(0xFFE2EFE1)) : (pressed ? Colors.grey.shade400 : Colors.grey[300]),
                                  borderRadius: BorderRadius.circular(20),
                                  border: activeFilters.isNotEmpty ? Border.all(color: const Color(0xFF28A745), width: 1) : null,
                                  boxShadow: pressed ? [] : [BoxShadow(color: Colors.black.withOpacity(0.18), blurRadius: 5, offset: const Offset(0, 2))],
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.filter_list, size: 18, color: activeFilters.isNotEmpty ? const Color(0xFF28A745) : Colors.black87),
                                    const SizedBox(width: 6),
                                    Text('Filters${activeFilters.isNotEmpty ? " (${activeFilters.length})" : "..."}', 
                                         style: TextStyle(fontWeight: FontWeight.bold, color: activeFilters.isNotEmpty ? const Color(0xFF28A745) : Colors.black87)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: LayoutBuilder(builder: (ctx2, gridConstraints) {
                    // Force at least 2 columns: compute max width that fits 2 side-by-side
                    const double spacing = 10;
                    final double twoColWidth = (gridConstraints.maxWidth - spacing) / 2;
                    // Clamp: prefer 200 on wide screens, scale down to fit 2 cols on narrow
                    final double itemW = twoColWidth < 200 ? twoColWidth : 200;
                    return MediaQuery.removePadding(
                      context: ctx2,
                      removeTop: true,
                      removeBottom: true,
                      child: ResponsiveGridList(
                      desiredItemWidth: itemW,
                      minSpacing: spacing,
                      children:
                          List.generate(sortedIndices.length, (index) => index)
                              .map((baseIdx) {
                        int i = sortedIndices[baseIdx];

                        String currentFullFilePath = currentFileName;
                        printDebug("currentFullFilePath");
                        printDebug(fileNames[i].path);
                        printDebug(currentFullFilePath);
                        printDebug(fileNames[i].path == currentFullFilePath);

                        return Stack(
                          children: [
                            GestureDetector(
                              onTap: () async {
                                if (!await _confirmIfUnsaved()) return;
                                String filename = basename(fileNames[i].path);
                                filename = filename.replaceAll(".txt", "").replaceAll(".brain", "");
                                String imageId = filename;
                                mapStatus["isSavingBrain"] = 10;
                                mapStatus["currentFileName"] =
                                    fileNames[i].path;

                                // Track whether this is an example brain
                                isCurrentBrainExample = (selectedTab == 1);
                                brainHasUnsavedChanges.value = false;
                                // Populate title/description for both user & example brains
                                tecBrainName.text = imageTitles[i];
                                tecBrainDescription.text = imageDescriptions[i];

                                selectCallback(imageId,
                                    filePath: fileNames[i].path);
                                closeDialog();
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(17),
                                  boxShadow: [
                                    BoxShadow(
                                      color: fileNames[i].path ==
                                              (currentFullFilePath)
                                          ? Colors.blue.withOpacity(0.35)
                                          : Colors.blue.withOpacity(0),
                                      offset: const Offset(0, 0),
                                      blurRadius: 3,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                                child: Card(
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10)),
                                   borderOnForeground: true,
                                   color: Colors.white,
                                   child: Column( // intrinsic height — no fixed size needed
                                      mainAxisAlignment: MainAxisAlignment.start,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // ── Blue thumbnail area + right-edge downward arrow ──
                                        FutureBuilder<Uint8List>(
                                          future: thumbnailCache.putIfAbsent(fileNames[i].path, () => getImageFromText(fileNames[i].path)),
                                          builder: (BuildContext context, AsyncSnapshot<Uint8List> snapshot) {
                                            // Exact canvas background blue (matches designbrain_page.dart L3366)
                                            const Color kBrainBlue = Color(0xFF1996FC);
                                            Widget imageWidget;
                                            if (snapshot.connectionState == ConnectionState.waiting) {
                                              imageWidget = const AspectRatio(
                                                aspectRatio: 1,
                                                child: Center(child: CircularProgressIndicator()),
                                              );
                                            } else if (!snapshot.hasData || snapshot.data!.length < 10) {
                                              imageWidget = const AspectRatio(aspectRatio: 1, child: SizedBox());
                                            } else {
                                               // To fully fix old saves, re-save each brain once.
                                               imageWidget = AspectRatio(
                                                 aspectRatio: 1,
                                                 child: Image.memory(
                                                   snapshot.data!,
                                                   fit: BoxFit.cover,
                                                 ),
                                               );
                                             }
                                             return Column(
                                               crossAxisAlignment: CrossAxisAlignment.stretch,
                                               children: [
                                                 // Blue rounded-corner square, 6px white card gap on all sides
                                                 Container(
                                                   margin: const EdgeInsets.fromLTRB(6, 6, 6, 0),
                                                   decoration: BoxDecoration(
                                                     color: kBrainBlue,
                                                     borderRadius: BorderRadius.circular(10),
                                                   ),
                                                   child: ClipRRect(
                                                     borderRadius: BorderRadius.circular(10),
                                                     child: imageWidget,
                                                   ),
                                                 ),
                                                 // Small downward arrow: ~1/3 card width, near right edge
                                                 Padding(
                                                   padding: const EdgeInsets.only(right: 12),
                                                   child: Align(
                                                     alignment: Alignment.centerRight,
                                                     child: SizedBox(
                                                       width: 56,
                                                       height: 13,
                                                       child: CustomPaint(
                                                         painter: _BrainCardArrowPainter(color: kBrainBlue),
                                                       ),
                                                     ),
                                                   ),
                                                 ),
                                               ],
                                             );
                                           },
                                         ),
                                         const SizedBox(height: 5),
                                         // ── Title: Boldoa Mat, auto-shrinks to fit ──
                                         Padding(
                                           padding: const EdgeInsets.symmetric(horizontal: 8),
                                           child: SizedBox(
                                             width: double.infinity,
                                             child: FittedBox(
                                               fit: BoxFit.scaleDown,
                                               alignment: Alignment.centerLeft,
                                               child: Text(
                                                 imageTitles[i],
                                                 style: const TextStyle(
                                                   fontFamily: 'BoldoaMat',
                                                   fontSize: 22,
                                                 ),
                                                 maxLines: 1,
                                               ),
                                             ),
                                           ),
                                         ),
                                         const SizedBox(height: 3),
                                         // ── Description: same font as before ──
                                         Padding(
                                           padding: const EdgeInsets.symmetric(horizontal: 8),
                                           child: Text(
                                             imageDescriptions[i],
                                             style: subHeaderStyle,
                                             maxLines: 2,
                                             overflow: TextOverflow.ellipsis,
                                           ),
                                         ),
                                         const SizedBox(height: 6), // bottom breathing room
                                       ],
                                   ),
                                 ),
                               ),
                             ),
                            if (isUploading) ... [
                              Positioned(
                                left: 0,
                                top: 0,
                                 child: _TapDarken(
                                  onTapDown: () async {
                                    if (buttonOnPressedSource != null) {
                                      buttonOnPressedHandle = await soloud?.play(buttonOnPressedSource!, looping: false);
                                    }
                                  },
                                  onTap: () async {
                                    if (buttonPopSource != null) {
                                      buttonPopHandle = await soloud?.play(buttonPopSource!, looping: false);
                                    }

                                    String? path;
                                    // Sanitize Title as Filename (User preferred "normal save name")
                                    String title = imageTitles[i]; // Get the human-readable title
                                    // Remove invalid characters for filenames (simple approach)
                                    String cleanTitle = title.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_').trim();
                                    if (cleanTitle.isEmpty) cleanTitle = "BrainBackup";
                                    
                                    String baseFileName = cleanTitle;
                                    
                                    if (Platform.isMacOS) {
                                      path = await FilePicker.platform.saveFile(
                                        dialogTitle: 'Save Brain File',
                                        fileName: baseFileName, // Clean name
                                        allowedExtensions: ['brain'], // Only allow .brain
                                        type: FileType.custom,
                                      );
                                      if (path != null) {
                                         // Enforce .brain suffix
                                         if (!path!.endsWith(".brain")) {
                                            path = "$path.brain";
                                         }
                                         
                                         // FilePicker returns the full path including filename
                                         File resultFile = File(path!);
                                          fileNames[i].copySync(resultFile.path);
                                       }
                                     } else if (Platform.isIOS) {
                                       // Sanitize Title as Filename (User preferred "normal save name")
                                       String title = imageTitles[i]; // Get the human-readable title
                                       // Remove invalid characters for filenames (simple approach)
                                       String cleanTitle = title.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_').trim();
                                       if (cleanTitle.isEmpty) cleanTitle = "BrainBackup";
                                       
                                       baseFileName = cleanTitle;

                                       // Enforce .brain suffix
                                       if (!baseFileName.endsWith(".brain")) {
                                          baseFileName = "$baseFileName.brain";
                                       }
                                       // Create temp file for sharing
                                       String tempPath = "${(await getTemporaryDirectory()).path}/$baseFileName";
                                       File tempFile = File(tempPath);
                                       if (tempFile.existsSync()) tempFile.deleteSync(); // Clear old temp
                                       
                                       // Ensure we copy from the original file (fileNames[i])
                                       fileNames[i].copySync(tempFile.path);

                                       // Share result (Without text to avoid extra text.txt file)
                                       // Fix for iPad: Must provide sharePositionOrigin
                                       final box = context.findRenderObject() as RenderBox?;
                                       final origin = box != null 
                                          ? Rect.fromLTWH(0, 0, 2, 2) // Use a small rect at 0,0 for general case
                                          : Rect.fromLTWH(0, 0, MediaQuery.of(context).size.width, 100);
                                          
                                       await Share.shareXFiles(
                                          [XFile(tempFile.path)],
                                          sharePositionOrigin: origin
                                       );
                                     } else {
                                      Directory? rootPath;
                                      try {
                                        rootPath = await getDownloadsDirectory();
                                      } catch (e) {
                                        printDebug("Error getting downloads directory: $e");
                                      }
                                      if (rootPath == null || !rootPath.existsSync()) {
                                        rootPath = await getApplicationDocumentsDirectory();
                                      }
                                      // Directory? rootPath = await getTemporaryDirectory();
                                      path = await FilesystemPicker.open(
                                        title: 'Save to folder',
                                        context: context,
                                        rootDirectory: rootPath,
                                        fsType: FilesystemType.folder,
                                        pickText: 'Save file to this folder',
                                      );
                                      if (path != null) {
                                        // String content = await fileNames[i].readAsString();
                                        File resultFile = File("$path${Platform.pathSeparator}$baseFileName");
                                        fileNames[i].copySync(resultFile.path);
                                      }
                                    }
                                  },
                                  builder: (pressed) => Container(
                                    width: 28, height: 28,
                                    clipBehavior: Clip.none,
                                    decoration: BoxDecoration(
                                       color: pressed ? Colors.grey.shade300 : Colors.white,
                                      borderRadius: BorderRadius.circular(100),
                                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.28), blurRadius: 5, spreadRadius: 0, offset: const Offset(1, 2))],
                                    ),
                                    child: Center(child: SvgPicture.asset('assets/icons/Share.svg', width: 32, height: 32, colorFilter: const ColorFilter.mode(Colors.blue, BlendMode.srcIn)))
                                  ),
                                )
                              )
                            ],
                            Positioned(
                              right: 0,
                              top: 0,
                              child: !isDeleteMode
                                  ? Container()
                                  : _TapDarken(
                                       onTapDown: () async {
                                        if (buttonOnPressedSource != null) {
                                          buttonOnPressedHandle = await soloud?.play(buttonOnPressedSource!, looping: false);
                                        }
                                      },
                                       onTap: () async {
                                        String filename =
                                            basename(fileNames[i].path);
                                        filename =
                                            filename.replaceAll(".txt", "").replaceAll(".brain", "");
                                        // List<String> arrImageInfo =
                                        //     filename.split("@@@");
                                        // String imageId = filename;

                                        if (fileNames[i].path ==
                                            currentFileName) {
                                          tecBrainName.clear();
                                          tecBrainDescription.clear();
                                          currentFileName = "-";
                                          isSavingMode = 0;
                                          mapStatus["isSavingBrain"] = 0;
                                          mapStatus["currentFileName"] = "-1";
                                        }

                                        Directory txtDirectory = Directory(
                                            "${(await getApplicationDocumentsDirectory()).path}$textPath");
                                        // String textPath = "/text";
                                        // final File file = File(
                                        //     '${txtDirectory.path}${Platform.pathSeparator}$filename.txt');
                                        final File file = File(
                                            '${txtDirectory.path}${Platform.pathSeparator}$filename.brain');
                                        if (file.existsSync()) {
                                          file.deleteSync();
                                        }

                                        try{
                                          final File fileTxt = File(
                                              '${txtDirectory.path}${Platform.pathSeparator}$filename.txt');
                                          fileTxt.deleteSync();
                                        }catch(err){
                                          print("err");
                                          print(err);
                                        }
                                        // final File fileImage =
                                        //     File(fileNames[i].path);
                                        // fileImage.deleteSync();
                                        fileNames.removeAt(i);
                                        imageTitles.removeAt(i);
                                        imageDescriptions.removeAt(i);
                                        fileInfos.removeAt(i);
                                        // Play erase sound on successful delete
                                        if (eraseOnPressedSource != null) soloud?.play(eraseOnPressedSource!, looping: false);
                                        setState(() {});
                                      },
                                      builder: (pressed) => Container(
                                        width: 30, height: 30,
                                        decoration: BoxDecoration(
                                           color: pressed ? const Color(0xFFCC4444) : const Color(0xFFE96565),
                                          borderRadius: BorderRadius.circular(100),
                                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.28), blurRadius: 5, spreadRadius: 0, offset: const Offset(1, 2))],
                                        ),
                                        child: Center(child: Transform.translate(
                                          offset: Offset(0, Platform.isMacOS ? -3 : -1),
                                          child: Text('\u2212', style: const TextStyle(fontFamily: 'BYBHandDrawn', fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white)))),
                                      ),
                                    ),
                            ),
                          ],
                        );
                        // }
                      }).toList(),
                     ),          // closes ResponsiveGridList
                     );          // closes MediaQuery.removePadding return statement
                   }),           // closes LayoutBuilder builder + widget
                   ),            // closes Expanded containing LayoutBuilder
                  ],             // closes Column children
                 ),              // closes Column
                 ),              // closes Padding
               ),                // closes Expanded (selectedTab != 2)
                 // ── Current Brain tab: annotation list ───────────────────────
                 if (selectedTab == 2) Expanded(
                   child: Padding(
                     padding: EdgeInsets.only(top: 2, bottom: isLandscape ? 8 : 76),
                     child: Column(
                               crossAxisAlignment: CrossAxisAlignment.stretch,
                       children: [
                         // "Add Annotation" pill button — portrait only
                         // (In landscape this button is in the title row to save vertical space)
                         if (!isLandscape) ...[
                           Center(
                             child: GestureDetector(
                               onTap: () {
                                 onAddAnnotationRequested?.call();
                                 closeDialog();
                               },
                               child: Container(
                                 width: 196,
                                 height: 38,
                                 padding: const EdgeInsets.symmetric(horizontal: 18),
                                 decoration: BoxDecoration(
                                   color: const Color(0xFFFD8164),
                                   borderRadius: BorderRadius.circular(19),
                                   boxShadow: [BoxShadow(color: const Color(0xFFFD8164).withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
                                 ),
                                 child: Row(
                                   mainAxisAlignment: MainAxisAlignment.center,
                                   children: const [
                                     Icon(Icons.add, color: Colors.white, size: 18),
                                     SizedBox(width: 6),
                                     Text('Add Annotation', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14, letterSpacing: 0.2)),
                                   ],
                                 ),
                               ),
                             ),
                           ),
                           const SizedBox(height: 10),
                         ],
                         // Annotation list or empty state
                         if (currentBrainAnnotations.isEmpty)
                           Expanded(
                             child: Center(
                               child: Column(
                                 mainAxisSize: MainAxisSize.min,
                                 children: [
                                   Icon(Icons.layers_outlined, size: 36, color: Colors.grey.shade300),
                                   const SizedBox(height: 8),
                                   Text('No annotations yet', style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
                                   const SizedBox(height: 4),
                                   Text('Tap + to highlight neurons and explain their role.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade400, fontSize: 11)),
                                 ],
                               ),
                             ),
                           )
                          else
                            Expanded(
                               child: Stack(
                                 key: _annListKey,
                                 clipBehavior: Clip.hardEdge,
                                 children: [
                                   // ── Scrollable annotation list ──────────────────────────────
                                   // The dragged item stays in the tree (just opacity-0) so its
                                   // GestureDetector is never removed mid-drag.  Only a separate
                                   // drop-line overlay indicates where it will land.
                                   SingleChildScrollView(
                                     controller: annScrollCtrl,
                                     padding: const EdgeInsets.symmetric(horizontal: 4),
                                     child: Column(
                                       crossAxisAlignment: CrossAxisAlignment.stretch,
                                       children: List.generate(currentBrainAnnotations.length, (idx) {
                                         final ann = currentBrainAnnotations[idx];
                                       final bool hasThumbnail = ann.thumbnail.isNotEmpty;
                                       final bool isBeingDragged = _annDraggingIdx == idx;
                                       // Compute slide: items between fromIdx and toIdx shift by
                                       // ±1 of their own height to visually make room for the drop.
                                       Offset slideOffset = Offset.zero;
                                       if (_annDraggingIdx != null && !isBeingDragged) {
                                         final n = currentBrainAnnotations.length;
                                         final from = _annDraggingIdx!;
                                         final double netDy = _annTotalDy + (annScrollCtrl?.offset ?? 0) - _annStartScrollOffset;
                                         final to = (from + netDy / _annItemEst)
                                             .round().clamp(0, n - 1);
                                         if (from < to && idx > from && idx <= to) {
                                           slideOffset = const Offset(0, -1); // drag down → items above gap shift up
                                         } else if (from > to && idx >= to && idx < from) {
                                           slideOffset = const Offset(0, 1);  // drag up → items below gap shift down
                                         }
                                       }
                                       return AnimatedSlide(
                                         offset: slideOffset,
                                         duration: const Duration(milliseconds: 150),
                                         curve: Curves.easeOut,
                                         child: Opacity(
                                           opacity: isBeingDragged ? 0.0 : 1.0,
                                           child: GestureDetector(
                                             onTap: () {
                                               if (_annDraggingIdx != null) return;
                                               final annCopy = ann;
                                               final idxCopy = idx;
                                               closeDialog();
                                               onAnnotationViewRequested?.call(annCopy, idxCopy);
                                             },
                                             child: Container(
                                               margin: const EdgeInsets.only(bottom: 8),
                                               decoration: BoxDecoration(
                                                 color: Colors.white,
                                                 borderRadius: BorderRadius.circular(14),
                                                 border: Border.all(color: Colors.grey.shade100),
                                                 boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 2))],
                                               ),
                                               padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                               child: Row(
                                                 crossAxisAlignment: CrossAxisAlignment.center,
                                                 children: [
                                                   // Numbered orange circle
                                                   Container(
                                                     width: 38, height: 38,
                                                     margin: const EdgeInsets.only(right: 6),
                                                     alignment: Alignment.center,
                                                     decoration: const BoxDecoration(
                                                       color: Color(0xFFFD8164), shape: BoxShape.circle,
                                                     ),
                                                     child: Center(
                                                       child: Text('${idx + 1}',
                                                         textScaler: TextScaler.noScaling,
                                                         style: const TextStyle(
                                                           fontFamily: 'BYBHandDrawn', fontSize: 22,
                                                           fontWeight: FontWeight.bold, color: Colors.white, height: 1.0,
                                                         ),
                                                       ),
                                                     ),
                                                   ),
                                                   // Thumbnail or blue placeholder
                                                   ClipRRect(
                                                     borderRadius: BorderRadius.circular(10),
                                                     child: hasThumbnail
                                                         ? Image.memory(ann.thumbnail, width: 52, height: 52, fit: BoxFit.cover)
                                                         : Container(
                                                             width: 52, height: 52,
                                                             decoration: const BoxDecoration(color: Color(0xFF1996FC)),
                                                           ),
                                                   ),
                                                   const SizedBox(width: 10),
                                                   Expanded(
                                                     child: Column(
                                                       crossAxisAlignment: CrossAxisAlignment.start,
                                                       children: [
                                                         Text(ann.description, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500), maxLines: 2, overflow: TextOverflow.ellipsis),
                                                         const SizedBox(height: 3),
                                                         Text(
                                                           '${ann.neuronKeys.length} neuron${ann.neuronKeys.length == 1 ? "" : "s"}  •  ${ann.edgeStrings.length} synapse${ann.edgeStrings.length == 1 ? "" : "s"}',
                                                           style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                                                         ),
                                                       ],
                                                     ),
                                                   ),
                                                   const SizedBox(width: 4),
                                                   // Delete button
                                                   GestureDetector(
                                                     onTap: () {
                                                       currentBrainAnnotations.removeAt(idx);
                                                       onAnnotationsModified?.call();
                                                       setState(() {});
                                                     },
                                                     child: Padding(
                                                       padding: const EdgeInsets.all(4),
                                                       child: SvgPicture.asset('assets/icons/Delete.svg', width: 44, height: 44,
                                                         colorFilter: const ColorFilter.mode(Color(0xFFE96565), BlendMode.srcIn)),
                                                     ),
                                                   ),
                                                   // Drag handle — GestureDetector persists in the tree
                                                   // even while dragging (opacity-0 preserves the slot
                                                   // so the recognizer keeps receiving drag events).
                                                   GestureDetector(
                                                     onVerticalDragStart: (d) {
                                                       final box = _annListKey.currentContext!.findRenderObject() as RenderBox;
                                                       setState(() {
                                                         _annDraggingIdx = idx;
                                                         _annStartTouchLocalY = box.globalToLocal(d.globalPosition).dy;
                                                         _annTotalDy = 0;
                                                         _annStartScrollOffset = annScrollCtrl?.offset ?? 0;
                                                       });
                                                     },
                                                     onVerticalDragUpdate: (d) {
                                                       final box = _annListKey.currentContext!.findRenderObject() as RenderBox;
                                                       setState(() {
                                                         _annTotalDy = box.globalToLocal(d.globalPosition).dy - _annStartTouchLocalY;
                                                       });
                                                       final localY = box.globalToLocal(d.globalPosition).dy;
                                                       if (localY < 40) startScroll?.call(-15.0);
                                                       else if (localY > box.size.height - 40) startScroll?.call(15.0);
                                                       else stopScroll?.call();
                                                     },
                                                     onVerticalDragEnd: (d) {
                                                       stopScroll?.call();
                                                       if (_annDraggingIdx != null) {
                                                         final double netDy = _annTotalDy + (annScrollCtrl?.offset ?? 0) - _annStartScrollOffset;
                                                         final newIdx = (_annDraggingIdx! + netDy / _annItemEst)
                                                             .round().clamp(0, currentBrainAnnotations.length - 1);
                                                         final item = currentBrainAnnotations.removeAt(_annDraggingIdx!);
                                                         currentBrainAnnotations.insert(newIdx, item);
                                                         onAnnotationsModified?.call();
                                                       }
                                                       setState(() => _annDraggingIdx = null);
                                                     },
                                                     onVerticalDragCancel: () {
                                                       stopScroll?.call();
                                                       if (_annDraggingIdx != null) {
                                                         setState(() => _annDraggingIdx = null);
                                                       }
                                                     },
                                                     child: const Padding(
                                                       padding: EdgeInsets.all(4),
                                                       child: Icon(Icons.drag_handle, color: Colors.grey, size: 22),
                                                     ),
                                                   ),
                                                 ],
                                               ),
                                             ),
                                           ),
                                         ),
                                       );
                                     }),
                                   ),
                                   ),
                                   // ── Floating drag proxy ──────────────────────────────────────
                                   // Elevated card that follows the finger, rendered inside the
                                   // same Stack so Positioned.top is in list-local coordinates —
                                   // correct on all platforms even with FittedBox scaling.
                                   if (_annDraggingIdx != null && _annDraggingIdx! < currentBrainAnnotations.length)
                                     Builder(builder: (ctx) {
                                       final dAnn = currentBrainAnnotations[_annDraggingIdx!];
                                       final dHas = dAnn.thumbnail.isNotEmpty;
                                       final floatTop = (_annStartTouchLocalY + _annTotalDy) - _annItemEst / 2;
                                       return Positioned(
                                         top: floatTop, left: 4, right: 4,
                                         child: IgnorePointer(
                                           child: Material(
                                             elevation: 8,
                                             borderRadius: BorderRadius.circular(14),
                                             child: Container(
                                               decoration: BoxDecoration(
                                                 color: Colors.white,
                                                 borderRadius: BorderRadius.circular(14),
                                                 border: Border.all(color: Colors.grey.shade200),
                                               ),
                                               padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                               child: Row(
                                                 crossAxisAlignment: CrossAxisAlignment.center,
                                                 children: [
                                                   Container(
                                                     width: 38, height: 38,
                                                     margin: const EdgeInsets.only(right: 6),
                                                     alignment: Alignment.center,
                                                     decoration: const BoxDecoration(
                                                       color: Color(0xFFFD8164), shape: BoxShape.circle,
                                                     ),
                                                     child: Center(
                                                       child: Text('${_annDraggingIdx! + 1}',
                                                         textScaler: TextScaler.noScaling,
                                                         style: const TextStyle(
                                                           fontFamily: 'BYBHandDrawn', fontSize: 22,
                                                           fontWeight: FontWeight.bold, color: Colors.white, height: 1.0,
                                                         ),
                                                       ),
                                                     ),
                                                   ),
                                                   ClipRRect(
                                                     borderRadius: BorderRadius.circular(10),
                                                     child: dHas
                                                         ? Image.memory(dAnn.thumbnail, width: 52, height: 52, fit: BoxFit.cover)
                                                         : Container(width: 52, height: 52,
                                                             decoration: const BoxDecoration(color: Color(0xFF1996FC))),
                                                   ),
                                                   const SizedBox(width: 10),
                                                   Expanded(child: Column(
                                                     crossAxisAlignment: CrossAxisAlignment.start,
                                                     children: [
                                                       Text(dAnn.description,
                                                         style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                                                         maxLines: 2, overflow: TextOverflow.ellipsis),
                                                       const SizedBox(height: 3),
                                                       Text(
                                                         '${dAnn.neuronKeys.length} neuron${dAnn.neuronKeys.length == 1 ? "" : "s"}  •  ${dAnn.edgeStrings.length} synapse${dAnn.edgeStrings.length == 1 ? "" : "s"}',
                                                         style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                                                       ),
                                                     ],
                                                   )),
                                                   const SizedBox(width: 4),
                                                   SvgPicture.asset('assets/icons/Delete.svg', width: 44, height: 44,
                                                     colorFilter: const ColorFilter.mode(Color(0xFFE96565), BlendMode.srcIn)),
                                                   const Padding(
                                                     padding: EdgeInsets.all(4),
                                                     child: Icon(Icons.drag_handle, color: Colors.grey, size: 22),
                                                   ),
                                                 ],
                                               ),
                                             ),
                                           ),
                                         ),
                                       );
                                     }),
                                 ],
                               ),
                             ),
                       ],
                     ),
                   ),
                 ),
               ],
            ),
          ),
        ),
        // ─── Portrait action bar: fixed at screen bottom ───
        if (!isLandscape && (selectedTab == 0 || selectedTab == 2))
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade200, width: 1)),
            ),
            padding: EdgeInsets.only(
              left: 16, right: 16,
              top: 10,
              bottom: 10, // card is already above safe area via outer bottomPad
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: selectedTab == 2 ? [
                if (!isCurrentBrainExample) _buildActionBtn(
                  labelOnRight: true,
                  icon: SvgPicture.asset('assets/icons/Save.svg', width: 60, height: 60),
                  label: 'Save', onTap: () async {
                    if (isSavingMode == 10) { File d = File(currentFileName); if (d.existsSync()) d.deleteSync(); }
                    currentFileName = await saveCallback(tecBrainName.text, tecBrainDescription.text);
                    mapStatus["isSavingBrain"] = 10; mapStatus["currentFileName"] = currentFileName;
                    fileInfos = []; fileNames = await loadBrainFiles(fileInfos, context);
                    isSavingMode = 10; brainHasUnsavedChanges.value = false; setState(() {});
                  }),
                _buildActionBtn(
                  labelOnRight: true,
                  icon: SvgPicture.asset('assets/icons/SaveAs.svg', width: 60, height: 60),
                  label: isCurrentBrainExample ? 'Save As' : 'Save Copy', onTap: () async {
                    if (buttonPopSource != null) soloud?.play(buttonPopSource!, looping: false);
                    await Future.delayed(const Duration(milliseconds: 100));
                    if (!context.mounted) return;
                    singleInputDialog(context, "Save A Copy",
                      DialogTextField(label: "Brain name", obscureText: false, textInputType: TextInputType.text,
                        validator: (v) => v!.isEmpty ? "Required!" : null,
                        onEditingComplete: (v) { printDebug(v); }),
                      positiveButtonText: "Save",
                      positiveButtonAction: (title) async {
                        dialogIsSaving = true;
                        ProgressDialog pd = ProgressDialog(context: context);
                        pd.show(msg: 'Saving Brain...');
                        currentFileName = await saveCallback(title, tecBrainDescription.text);
                        mapStatus["isSavingBrain"] = 10; mapStatus["currentFileName"] = currentFileName;
                        tecBrainName.text = title; isCurrentBrainExample = false;
                        isSavingMode = 10; brainHasUnsavedChanges.value = false;
                        if (onTabChanged != null) { await onTabChanged(2); } else { fileInfos = []; fileNames = await loadBrainFiles(fileInfos, context); }
                        setState(() {}); pd.close();
                        Future.delayed(const Duration(milliseconds: 200), () { dialogIsSaving = false; });
                      },
                      negativeButtonText: "Cancel", negativeButtonAction: () {},
                      hideNeutralButton: true, closeOnBackPress: false);
                  }),
                _buildActionBtn(
                  labelOnRight: true,
                  icon: SvgPicture.asset('assets/icons/NewFile.svg', width: 60, height: 60),
                  label: 'New', onTap: () async {
                    if (!await _confirmIfUnsaved()) return;
                    // Unsaved-changes guard already ran above — no second popup needed.
                    tecBrainName.clear(); tecBrainDescription.clear();
                    mapStatus["isSavingBrain"] = 1; mapStatus["currentFileName"] = "-";
                    currentFileName = "-"; brainHasUnsavedChanges.value = false; isCurrentBrainExample = false;
                    selectCallback("-1"); if (pageFlipSource != null) soloud?.play(pageFlipSource!, looping: false); closeDialog();
                  }),
              ] : [
                _buildActionBtn(labelOnRight: true, icon: SvgPicture.asset('assets/icons/Import.svg', width: 60, height: 60), label: 'Import', onTap: () async {
                  isUploading = false;
                  if (buttonPopSource != null) buttonPopHandle = await soloud?.play(buttonPopSource!, looping: false);
                  if (Platform.isAndroid) await [Permission.manageExternalStorage].request();
                  String? importPath;
                  if (Platform.isMacOS || Platform.isIOS) {
                    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['brain']);
                    if (result != null) importPath = result.files.single.path;
                  } else {
                    Directory? rootPath;
                    try { rootPath = await getDownloadsDirectory(); } catch (e) {}
                    if (rootPath == null || !rootPath.existsSync()) rootPath = await getApplicationDocumentsDirectory();
                    importPath = await FilesystemPicker.open(title: 'Open file', context: context, rootDirectory: rootPath, fsType: FilesystemType.file, allowedExtensions: ['.brain'], fileTileSelectMode: FileTileSelectMode.wholeTile);
                  }
                  if (importPath != null) {
                    File srcFile = File(importPath);
                    Directory? doc = await getApplicationDocumentsDirectory();
                    Directory dir = Directory("${doc.path}$textPath");
                    if (dir.existsSync()) srcFile.copySync("${dir.path}${Platform.pathSeparator}${basename(srcFile.path)}");
                  }
                  fileInfos = []; fileNames = await loadBrainFiles(fileInfos, context); thumbnailCache.clear(); setState(() {});
                }),
                _buildActionBtn(labelOnRight: true, icon: SvgPicture.asset('assets/icons/Share.svg', width: 60, height: 60, colorFilter: isUploading ? const ColorFilter.mode(Colors.blue, BlendMode.srcIn) : null), label: 'Share', onTap: () async {
                  if (buttonPopSource != null) buttonPopHandle = await soloud?.play(buttonPopSource!, looping: false);
                  isUploading = !isUploading; setState(() {});
                }),
                _buildActionBtn(labelOnRight: true, icon: SvgPicture.asset('assets/icons/Delete.svg', width: 60, height: 60, colorFilter: isDeleteMode ? const ColorFilter.mode(Colors.red, BlendMode.srcIn) : null), label: 'Delete', onTap: () async {
                  isDeleteMode = !isDeleteMode;
                  setState(() {});
                }),
              ],
            ),
          ),
        ),
        // ── Landscape: action buttons inline right of tabs (AnimatedSize for smooth transitions) ──
        if (isLandscape) Positioned(
          top: 6,
          right: 4,
          child: AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeInOut,
            alignment: Alignment.centerRight,
            child: (selectedTab == 0 || selectedTab == 2)
              ? Row(mainAxisSize: MainAxisSize.min, children: [
            const SizedBox(width: 6),
            Container(width: 1, height: 52, color: Colors.grey.shade200),
            const SizedBox(width: 6),
            if (selectedTab == 2) ...[
              if (!isCurrentBrainExample) _buildActionBtn(
                icon: SvgPicture.asset('assets/icons/Save.svg', width: 60, height: 60),
                label: 'Save', onTap: () async {
                  if (isSavingMode == 10) { File d = File(currentFileName); if (d.existsSync()) d.deleteSync(); }
                  currentFileName = await saveCallback(tecBrainName.text, tecBrainDescription.text);
                  mapStatus["isSavingBrain"] = 10; mapStatus["currentFileName"] = currentFileName;
                  fileInfos = []; fileNames = await loadBrainFiles(fileInfos, context);
                  isSavingMode = 10; brainHasUnsavedChanges.value = false; setState(() {});
                }),
              if (!isCurrentBrainExample) const SizedBox(width: 8),
              _buildActionBtn(
                icon: SvgPicture.asset('assets/icons/SaveAs.svg', width: 60, height: 60),
                label: isCurrentBrainExample ? 'Save As' : 'Save Copy', onTap: () async {
                  if (buttonPopSource != null) soloud?.play(buttonPopSource!, looping: false);
                  await Future.delayed(const Duration(milliseconds: 100));
                  if (!context.mounted) return;
                  singleInputDialog(context, "Save A Copy",
                    DialogTextField(label: "Brain name", obscureText: false, textInputType: TextInputType.text,
                      validator: (v) => v!.isEmpty ? "Required!" : null,
                      onEditingComplete: (v) { printDebug(v); }),
                    positiveButtonText: "Save",
                    positiveButtonAction: (title) async {
                      dialogIsSaving = true;
                      ProgressDialog pd = ProgressDialog(context: context);
                      pd.show(msg: 'Saving Brain...');
                      currentFileName = await saveCallback(title, tecBrainDescription.text);
                      mapStatus["isSavingBrain"] = 10; mapStatus["currentFileName"] = currentFileName;
                      tecBrainName.text = title; isCurrentBrainExample = false;
                      isSavingMode = 10; brainHasUnsavedChanges.value = false;
                      if (onTabChanged != null) { await onTabChanged(2); } else { fileInfos = []; fileNames = await loadBrainFiles(fileInfos, context); thumbnailCache.clear(); }
                      setState(() {}); pd.close();
                      Future.delayed(const Duration(milliseconds: 200), () { dialogIsSaving = false; });
                    },
                    negativeButtonText: "Cancel", negativeButtonAction: () {},
                    hideNeutralButton: true, closeOnBackPress: false);
                }),
              const SizedBox(width: 8),
              _buildActionBtn(
                icon: SvgPicture.asset('assets/icons/NewFile.svg', width: 60, height: 60),
                label: 'New', onTap: () async {
                  if (!await _confirmIfUnsaved()) return;
                  tecBrainName.clear(); tecBrainDescription.clear();
                  mapStatus["isSavingBrain"] = 1; mapStatus["currentFileName"] = "-";
                  currentFileName = "-"; brainHasUnsavedChanges.value = false; isCurrentBrainExample = false;
                  selectCallback("-1"); if (pageFlipSource != null) soloud?.play(pageFlipSource!, looping: false); closeDialog();
                }),
            ] else ...[
              _buildActionBtn(icon: SvgPicture.asset('assets/icons/Import.svg', width: 60, height: 60), label: 'Import', onTap: () async {
                isUploading = false;
                if (buttonPopSource != null) buttonPopHandle = await soloud?.play(buttonPopSource!, looping: false);
                if (Platform.isAndroid) await [Permission.manageExternalStorage].request();
                String? importPath;
                if (Platform.isMacOS || Platform.isIOS) {
                  FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['brain']);
                  if (result != null) importPath = result.files.single.path;
                } else {
                  Directory? rootPath;
                  try { rootPath = await getDownloadsDirectory(); } catch (e) {}
                  if (rootPath == null || !rootPath.existsSync()) rootPath = await getApplicationDocumentsDirectory();
                  importPath = await FilesystemPicker.open(title: 'Open file', context: context, rootDirectory: rootPath, fsType: FilesystemType.file, allowedExtensions: ['.brain'], fileTileSelectMode: FileTileSelectMode.wholeTile);
                }
                if (importPath != null) {
                  File srcFile = File(importPath);
                  Directory? doc = await getApplicationDocumentsDirectory();
                  Directory dir = Directory("${doc.path}$textPath");
                  if (dir.existsSync()) srcFile.copySync("${dir.path}${Platform.pathSeparator}${basename(srcFile.path)}");
                }
                fileInfos = []; fileNames = await loadBrainFiles(fileInfos, context); thumbnailCache.clear(); setState(() {});
              }),
              const SizedBox(width: 8),
              _buildActionBtn(icon: SvgPicture.asset('assets/icons/Share.svg', width: 60, height: 60, colorFilter: isUploading ? const ColorFilter.mode(Colors.blue, BlendMode.srcIn) : null), label: 'Share', onTap: () async {
                if (buttonPopSource != null) buttonPopHandle = await soloud?.play(buttonPopSource!, looping: false);
                isUploading = !isUploading; setState(() {});
              }),
              const SizedBox(width: 8),
              _buildActionBtn(icon: SvgPicture.asset('assets/icons/Delete.svg', width: 60, height: 60, colorFilter: isDeleteMode ? const ColorFilter.mode(Colors.red, BlendMode.srcIn) : null), label: 'Delete', onTap: () async {
                isDeleteMode = !isDeleteMode;
                setState(() {});
              }),
            ],
          ])
              : const SizedBox.shrink(),
          ),
        ),
      ],
    );
  });
}

void printDebug(s) {
  print(s);
}

// ── Tap-darkening wrapper — builder provides pressed state to darken circle bg ──
class _TapDarken extends StatefulWidget {
  final Widget Function(bool pressed) builder;
  final Future<void> Function() onTap;
  final Future<void> Function()? onTapDown;
  const _TapDarken({required this.builder, required this.onTap, this.onTapDown});
  @override
  State<_TapDarken> createState() => _TapDarkenState();
}
class _TapDarkenState extends State<_TapDarken> {
  bool _pressed = false;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) { setState(() => _pressed = true); widget.onTapDown?.call(); },
      onTapUp: (_) { setState(() => _pressed = false); },
      onTapCancel: () { setState(() => _pressed = false); },
      onTap: () { setState(() => _pressed = false); widget.onTap(); },
      behavior: HitTestBehavior.opaque,
      child: widget.builder(_pressed),
    );
  }
}

// ── Circle-icon + label action button helper ──────────────────────────────────
Widget _buildActionBtn({required Widget icon, required String label, required VoidCallback onTap, bool labelOnRight = false}) {
  return _TapDarken(
    onTapDown: () async {
      if (buttonOnPressedSource != null) {
        buttonOnPressedHandle = await soloud?.play(buttonOnPressedSource!, looping: false);
      }
    },
    onTap: () async {
      if (buttonPopSource != null) {
        buttonPopHandle = await soloud?.play(buttonPopSource!, looping: false);
      }
      onTap();
    },
    builder: (pressed) {
      final circle = Container(
        width: 56, height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: pressed ? Colors.grey.shade300 : Colors.white,
          border: Border.all(color: Colors.grey.shade300, width: 1.5),
          boxShadow: pressed ? [] : [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 4, offset: const Offset(0, 2))],
        ),
        child: Center(child: icon),
      );
      final lbl = Text(label,
        style: TextStyle(fontFamily: 'Roboto', fontSize: labelOnRight ? 16 : 11, fontWeight: FontWeight.w500));
      return labelOnRight
        ? Row(mainAxisSize: MainAxisSize.min, children: [circle, const SizedBox(width: 10), lbl])
        : Column(mainAxisSize: MainAxisSize.min, children: [circle, const SizedBox(height: 4), lbl]);
    },
  );
}

// ── Downward-pointing blue arrow painter (website-style section divider) ──
// Draws the blue V-shape that visually bridges the thumbnail area to the
// white card text section below, mimicking the curved triangular separators
// on spikerbot.backyardbrains.com.
class _BrainCardArrowPainter extends CustomPainter {
  final Color color;
  const _BrainCardArrowPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..style = PaintingStyle.fill;
    final w = size.width;
    final h = size.height;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(w, 0)
      // Right side: curves down toward the center tip
      ..quadraticBezierTo(w * 0.65, 0,      w * 0.545, h - 2)
      ..quadraticBezierTo(w * 0.515, h,     w / 2,     h)
      // Left side: mirror curve back up
      ..quadraticBezierTo(w * 0.485, h,     w * 0.455, h - 2)
      ..quadraticBezierTo(w * 0.35, 0,      0,          0)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_BrainCardArrowPainter old) => old.color != color;
}

// ── Unsaved Changes confirmation dialog ────────────────────────────────────────
// Shown before any destructive action (load different brain, new brain) when
// brainHasUnsavedChanges is true.  Returns:
//   'save'    → caller should save then proceed
//   'discard' → caller should proceed without saving
//   null      → cancelled; caller should abort
class _UnsavedChangesDialog extends StatelessWidget {
  const _UnsavedChangesDialog();

  @override
  Widget build(BuildContext context) {
    // ConstrainedBox caps width to ~340pt — about half of a typical tablet dialog.
    // insetPadding pushes inward from the screen edges on all screen sizes.
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 10,
      insetPadding: const EdgeInsets.symmetric(horizontal: 60, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Title row: [X close] [title] [spacer]
              Row(children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context, null),
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    width: 34, height: 34,
                    alignment: Alignment.center,
                    child: const Icon(Icons.close, size: 22, color: Colors.black54),
                  ),
                ),
                const Expanded(
                  child: Text(
                    'Unsaved Changes',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w800,
                      fontFamily: 'Roboto', color: Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(width: 34), // mirrors X for visual balance
              ]),
              const SizedBox(height: 10),
              const Text(
                'Your brain has unsaved changes.\nSave before continuing?',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13.5, color: Colors.black54, fontFamily: 'Roboto', height: 1.5),
              ),
              const SizedBox(height: 16),
              Row(children: [
                // No — styled like the annotation Delete button (light red bg, red text)
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context, 'discard'),
                    child: Container(
                      height: 42,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE96565).withOpacity(0.10),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text('No',
                        style: TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 14,
                          color: Color(0xFFE96565), fontFamily: 'Roboto',
                        )),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Save — signature orange
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context, 'save'),
                    child: Container(
                      height: 42,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFD8164),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text('Save',
                        style: TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 14,
                          color: Colors.white, fontFamily: 'Roboto',
                        )),
                    ),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}
