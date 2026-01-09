import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:fialogs/fialogs.dart';
import 'package:file_picker/file_picker.dart';
import 'package:filesystem_picker/filesystem_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/material.dart';
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
String currentFileName = "-";
Map mapStatus = {};

// String infoPath = "${Platform.pathSeparator}info";
// String imagesPath =
//     "${Platform.pathSeparator}spikerbot${Platform.pathSeparator}images";
String textPath =
    "${Platform.pathSeparator}spikerbot${Platform.pathSeparator}text";
List<File> fileNames = [];

Directory? documentPath;
List<Map<String, String>> fileInfos = [];

bool isLoadBrainDialog = false;
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
           if (jsonMap.containsKey("info")) {
              var info = jsonMap["info"];
              if (info["title"] != null) brainInfo["title"] = info["title"];
              if (info["description"] != null) brainInfo["description"] = info["description"];
           }
        } catch (e) {
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

  fileInfos = [];
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

  isEditingMenu = false;

  // ignore: use_build_context_synchronously
  return showDialog<void>(
    context: context,
    barrierDismissible: false, // We handle dismissal manually for perfect control
    barrierColor: Colors.transparent, // We draw our own barrier
    useSafeArea: false,
    builder: (BuildContext context) {
      return StatefulBuilder(builder: (ctx, setState) {
        printDebug("REDRAW - LoadBrainDialog");
        
        bool allowClose = false;

        void closeDialog() {
           printDebug("CLOSING DIALOG (Valid Action)");
           allowClose = true;
           Navigator.of(context).pop();
        }

        double verticalPadding = MediaQuery.of(context).size.shortestSide < 600 ? 0 : 15;
        
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
                     double screenW = MediaQuery.of(context).size.width;
                     double touchX = details.globalPosition.dx;
                     double touchY = details.globalPosition.dy;
                     
                     // SAFETY SHOULDERS:
                     // Ignore taps in the top 100px of the side strips (near header buttons)
                     // This prevents sloppy taps on "Share/Menu" from hitting the barrier
                     if (touchY < 100) {
                        printDebug("BARRIER TAP IN HEADER SAFETY ZONE (Y < 100) - IGNORED");
                        return;
                     }

                     // Only close if tapping the Left or Right 50px strips
                     if (touchX < 50 || touchX > screenW - 50) {
                        printDebug("SIDE BARRIER TAPPED - X: $touchX Y: $touchY - CLOSING");
                        closeDialog();
                     } else {
                        printDebug("TOP/BOTTOM BARRIER TAPPED - X: $touchX - IGNORED (SAFE ZONE)");
                     }
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
                  padding: EdgeInsets.symmetric(horizontal: 50, vertical: verticalPadding),
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
                      width: MediaQuery.of(context).size.width, // constraints will limit this
                      height: MediaQuery.of(context).size.height,
                      child: showBrainDisplay(
                          context, fileNames, selectCallback, saveCallback, setState, closeDialog),
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
    saveCallback, setState, Function closeDialog) {
  return LayoutBuilder(builder: (ctx, constraints) {
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
                SizedBox(
                  width: constraints.maxWidth,
                  height: 70,
                  child: Row(
                    children: [
                      const SizedBox(width: 7),
                      GestureDetector(
                        onTapDown: (details) async {
                          if (buttonOnPressedSource != null) {
                            buttonOnPressedHandle = await soloud?.play(
                                buttonOnPressedSource!,
                                looping: false);
                          }
                        },
                        onTap: () async {
                          printDebug("IMPORT BUTTON TAPPED");
                          isUploading = false;
                          if (buttonPopSource != null) {
                            buttonPopHandle = await soloud?.play(
                                buttonPopSource!,
                                looping: false);
                          }

                          if (Platform.isAndroid) {
                            await [
                              Permission.manageExternalStorage,
                            ].request();
                          }
                          String? path;
                          if (Platform.isMacOS || Platform.isIOS) {
                            FilePickerResult? result =
                                await FilePicker.platform.pickFiles(
                              type: FileType.custom,
                              allowedExtensions: ['brain'],
                            );
                            if (result != null) {
                              path = result.files.single.path;
                            }
                          } else {
                            Directory? rootPath;
                            if (Platform.isAndroid) {
                              rootPath =
                                  Directory('/storage/emulated/0/Download');
                              Directory txtDirectory = Directory(
                                  "${(await getApplicationDocumentsDirectory()).path}${Platform.pathSeparator}spikerbot${Platform.pathSeparator}text");
                              if (!txtDirectory.existsSync())
                                txtDirectory.createSync();
                            } else {
                              try {
                                rootPath = await getDownloadsDirectory();
                              } catch (e) {
                                printDebug(
                                    "Error getting downloads directory: $e");
                              }
                              if (rootPath == null ||
                                  !rootPath.existsSync()) {
                                rootPath =
                                    await getApplicationDocumentsDirectory();
                              }
                            }
                            path = await FilesystemPicker.open(
                              title: 'Open file',
                              context: context,
                              rootDirectory: rootPath,
                              fsType: FilesystemType.file,
                              allowedExtensions: ['.brain'],
                              fileTileSelectMode:
                                  FileTileSelectMode.wholeTile,
                            );
                          }

                          if (path != null) {
                            File srcFile = File(path);
                            String baseFileName = basename(srcFile.path);
                            Directory? documentPath =
                                await getApplicationDocumentsDirectory();
                            Directory directory = Directory(
                                "${documentPath.path}$textPath");

                            if (directory.existsSync()) {
                              File resultFile = File(
                                  "${directory.path}${Platform.pathSeparator}$baseFileName");
                              srcFile.copySync(resultFile.path);
                            }
                          }
                          fileInfos = [];
                          fileNames =
                              await loadBrainFiles(fileInfos, context);

                          setState(() {});
                        },
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                            color: Colors.transparent,
                            width: 40,
                            height: 40,
                            alignment: Alignment.center,
                            child: const Icon(Icons.folder_open, size: 28)),
                      ),
                      GestureDetector(
                        onTapDown: (details) async {
                          if (buttonOnPressedSource != null) {
                            buttonOnPressedHandle = await soloud?.play(
                                buttonOnPressedSource!,
                                looping: false);
                          }
                        },
                        onTap: () async {
                          printDebug("SHARE BUTTON TAPPED");
                          if (buttonPopSource != null) {
                            buttonPopHandle = await soloud?.play(
                                buttonPopSource!,
                                looping: false);
                          }
                          isUploading = !isUploading;
                          setState(() {});
                        },
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                            color: Colors.transparent,
                            width: 40,
                            height: 40,
                            alignment: Alignment.center,
                            child: Icon(
                              Icons.ios_share,
                              size: 28,
                              color: !isUploading
                                  ? Colors.black
                                  : Colors.blue,
                            )),
                      ),
                      const SizedBox(width: 5),
                      GestureDetector(
                        onTap: () {
                          printDebug("MENU BUTTON TAPPED");
                          isEditingMenu = !isEditingMenu;
                          setState(() {});
                        },
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          color: Colors.transparent,
                          width: 40,
                          height: 40,
                          alignment: Alignment.center,
                          child: isEditingMenu
                              ? const Icon(Icons.keyboard_arrow_up)
                              : const Icon(Icons.menu),
                        ),
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Container(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 10),
                          color: Colors.transparent,
                          height: 40,
                          alignment: Alignment.center,
                          child: TextField(
                            maxLength: 25,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 20),
                            decoration: const InputDecoration(
                                counterText: "",
                                hintText: 'Name this brain'),
                            controller: tecBrainName,
                            enabled:
                                isSavingMode < 10 || isEditingMenu
                                    ? true
                                    : false,
                          ),
                        ),
                      ),
                      const SizedBox(width: 5),
                      GestureDetector(
                        onTap: () async {
                          printDebug("SAVE BUTTON TAPPED");
                          if (buttonPopSource != null) {
                            buttonPopHandle = await soloud?.play(
                                buttonPopSource!,
                                looping: false);
                          }

                          if (isSavingMode == 1) {
                          } else if (isSavingMode == 10) {
                            File deleteFile = File(currentFileName);
                            if (deleteFile.existsSync()) {
                              deleteFile.deleteSync();
                            }
                          }

                          currentFileName = await saveCallback(
                            tecBrainName.text,
                            tecBrainDescription.text,
                          );
                          mapStatus["isSavingBrain"] = 10;
                          mapStatus["currentFileName"] = currentFileName;
                          fileInfos = [];
                          fileNames =
                              await loadBrainFiles(fileInfos, context);
                            isSavingMode = 10;

                            setState(() {});
                          },
                          onTapDown: (details) async {
                            if (buttonOnPressedSource != null) {
                              buttonOnPressedHandle = await soloud?.play(
                                  buttonOnPressedSource!,
                                  looping: false);
                            }                          
                          },
                      onLongPress: () async {
                        if (buttonPopSource != null) {
                          buttonPopHandle = await soloud?.play(buttonPopSource!, looping: false);
                        }
                        singleInputDialog(
                          context,
                          "Save as current brain",
                          DialogTextField(
                              label: "Please name your brain",
                              obscureText: false,
                              textInputType: TextInputType.text,
                              validator: (value) {
                                if (value!.toString().isEmpty) {
                                  return "Required!";
                                }
                                return null;
                              },
                              onEditingComplete: (value) {
                                printDebug(value);
                              }),
                          positiveButtonText: "Yes",
                          positiveButtonAction: (title) async {
                            tecBrainDescription.text = "";
                            currentFileName = await saveCallback(
                                title, tecBrainDescription.text);
                            mapStatus["isSavingBrain"] = 10;
                            mapStatus["currentFileName"] = currentFileName;
                            tecBrainName.text = title;

                            fileInfos = [];
                            fileNames =
                                await loadBrainFiles(fileInfos, context);
                            isSavingMode = 10;

                            setState(() {});
                          },
                          negativeButtonText: "Cancel",
                          negativeButtonAction: () {},
                          hideNeutralButton: true,
                          closeOnBackPress: true,
                        );
                      },
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                            color: Colors.transparent,
                            width: 40,
                            height: 40,
                            alignment: Alignment.center,
                            child: const Icon(Icons.save)),
                      ),
                      GestureDetector(
                        onTap: () {
                           printDebug("SAVE AS BUTTON TAPPED");
                           if (buttonPopSource != null) {
                              soloud?.play(buttonPopSource!, looping: false);
                            }

                            singleInputDialog(
                              context,
                              "Save as current brain",
                              DialogTextField(
                                  label: "Please name your brain",
                                  obscureText: false,
                                  textInputType: TextInputType.text,
                                  validator: (value) {
                                    if (value!.toString().isEmpty)
                                      return "Required!";
                                    return null;
                                  },
                                  onEditingComplete: (value) {
                                    printDebug(value);
                                  }),
                              positiveButtonText: "Yes",
                              positiveButtonAction: (title) async {
                                ProgressDialog pd =
                                    ProgressDialog(context: context);
                                pd.show(msg: 'Saving Brain...');

                                tecBrainDescription.text = "";
                                currentFileName = await saveCallback(
                                    title, tecBrainDescription.text);
                                mapStatus["isSavingBrain"] = 10;
                                mapStatus["currentFileName"] = currentFileName;
                                tecBrainName.text = title;

                                fileInfos = [];
                                fileNames =
                                    await loadBrainFiles(fileInfos, context);
                                isSavingMode = 10;

                                setState(() {});
                                pd.close();
                              },
                              negativeButtonText: "Cancel",
                              negativeButtonAction: () {},
                              hideNeutralButton: true,
                              closeOnBackPress: true,
                            );
                        },
                        onTapDown: (details) async {
                          if (buttonOnPressedSource != null) {
                            buttonOnPressedHandle = await soloud?.play(
                                buttonOnPressedSource!,
                                looping: false);
                          }
                        },
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                            color: Colors.transparent,
                            width: 40,
                            height: 40,
                            alignment: Alignment.center,
                            child: const Icon(Icons.save_as)),
                      ),
                      GestureDetector(
                        onTap: () async {
                          printDebug("NEW BRAIN BUTTON TAPPED");
                          if (isSavingMode < 10) {
                            tecBrainName.clear();
                            tecBrainDescription.clear();
                            mapStatus["isSavingBrain"] = 1;
                            mapStatus["currentFileName"] = "-";
                            currentFileName = "-";
                            selectCallback("-1");
                            if (pageFlipSource != null) {
                              soloud?.play(pageFlipSource!,
                                  looping: false);
                            }

                            closeDialog();
                          } else {
                            if (buttonOnPressedSource != null) {
                              soloud?.play(buttonOnPressedSource!,
                                  looping: false);
                            }

                            confirmationDialog(context,
                                "Creating new brain",
                                "Are you sure to start a new workspace?",
                                titleIcon: const Icon(Icons.warning),
                                hideNeutralButton: true,
                                negativeButtonText: "Cancel",
                                negativeButtonAction: () {
                                  printDebug("");
                                },
                                positiveButtonText: "Yes",
                                positiveButtonAction: () async {
                                  tecBrainName.clear();
                                  tecBrainDescription.clear();
                                  mapStatus["isSavingBrain"] = 1;
                                  mapStatus["currentFileName"] = "-";
                                  currentFileName = "-";
                                  selectCallback("-1");
                                  if (pageFlipSource != null) {
                                    pageFlipHandle = await soloud?.play(
                                        pageFlipSource!,
                                        looping: false);
                                    Future.delayed(const Duration(milliseconds: 1000),
                                        () {
                                      if (pageFlipHandle != null) {
                                        soloud?.stop(pageFlipHandle!);
                                        soloud?.disposeSource(pageFlipSource!);
                                        soloud?.disposeSource(buttonOnPressedSource!);
                                      }
                                    });
                                  }

                                  closeDialog();
                                },
                                confirmationDialog: false);
                          }
                        },
                        onTapDown: (details) async {
                          if (buttonOnPressedSource != null) {
                            buttonOnPressedHandle = await soloud?.play(
                                buttonOnPressedSource!,
                                looping: false);
                          }
                        },
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                            color: Colors.transparent,
                            width: 40,
                            height: 40,
                            alignment: Alignment.center,
                            child: const Icon(Icons.edit_document)),
                      ),
                    ],
                  ),
                ),
                !isEditingMenu
                    ? Container()
                    : Container(
                        color: Colors.transparent,
                        margin: const EdgeInsets.fromLTRB(70, 0, 70, 5),
                        child: TextFormField(
                          style: const TextStyle(fontSize: 16),
                          controller: tecBrainDescription,
                          maxLength: 75,
                          decoration: const InputDecoration(
                            counterText: "",
                          ),
                          minLines:
                              2, // any number you need (It works as the rows for the textarea)
                          keyboardType: TextInputType.multiline,
                          maxLines: 7,
                        ),
                      ),
                Expanded(
                  child: ResponsiveGridList(
                      // desiredItemWidth: MediaQuery.of(context).size.width * 0.2,
                      desiredItemWidth: 200,
                      minSpacing: 10,
                      children:
                          List.generate(fileNames.length, (index) => index)
                              .map((i) {
                        String currentFullFilePath = currentFileName;
                        printDebug("currentFullFilePath");
                        printDebug(fileNames[i].path);
                        printDebug(currentFullFilePath);
                        printDebug(fileNames[i].path == currentFullFilePath);

                        return Stack(
                          children: [
                            GestureDetector(
                              onTap: () {
                                String filename = basename(fileNames[i].path);
                                filename = filename.replaceAll(".txt", "").replaceAll(".brain", "");
                                // List<String> arrImageInfo =
                                //     filename.split("@@@");
                                String imageId = filename;
                                mapStatus["isSavingBrain"] = 10;
                                mapStatus["currentFileName"] =
                                    fileNames[i].path;

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
                                      offset: const Offset(
                                          0, 0), // No offset for centered glow
                                      blurRadius: 3, // Adjust blur radius
                                      spreadRadius:
                                          1, // Positive value for glow
                                    ),
                                  ],
                                ),
                                child: Card(
                                  // margin: const EdgeInsets.all(7),
                                  elevation: 0, // Remove default elevation
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10)),
                                  borderOnForeground: true,
                                  color: Colors.white,
                                  child: Container(
                                    height: 270,
                                    padding: const EdgeInsets.all(7),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        FutureBuilder<Uint8List>(
                                            future: getImageFromText(
                                                fileNames[i].path),
                                            builder: (BuildContext context,
                                                AsyncSnapshot<Uint8List>
                                                    snapshot) {
                                              if (snapshot.connectionState ==
                                                  ConnectionState.waiting) {
                                                return const CircularProgressIndicator();
                                              } else if (snapshot.hasError) {
                                                return Text(
                                                    'Error: ${snapshot.error}');
                                              } else {
                                                if (snapshot.data!.length <
                                                    10) {
                                                  return Text(
                                                      'Error: ${snapshot.error}');
                                                } else {
                                                  return Image.memory(
                                                      snapshot.data!);
                                                }
                                              }
                                            }),
                                        Text(imageTitles[i],
                                            style: headerStyle),
                                        Text(imageDescriptions[i],
                                            style: subHeaderStyle),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            if (isUploading) ... [
                              Positioned(
                                left: 0,
                                top: 0,
                                child: GestureDetector(
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.ios_share, size: 20, color: Colors.blue)
                                  ),
                                  onTapDown: (details) async {
                                    if (buttonOnPressedSource != null) {
                                      buttonOnPressedHandle = await soloud?.play(buttonOnPressedSource!, looping: false);
                                    }

                                  },
                                  onTapUp: (details) async {
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
                                          ? Rect.fromLTWH(details.globalPosition.dx, details.globalPosition.dy, 2, 2)
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
                                )
                              )
                            ],
                            Positioned(
                              right: 0,
                              top: 0,
                              child: !isDeleteMode
                                  ? Container()
                                  : GestureDetector(
                                      onTapDown: (details) async {
                                        if (eraseOnPressedSource != null) {
                                          eraseOnPressedHandle = await soloud?.play(eraseOnPressedSource!, looping: false);
                                          // Future.delayed(const Duration(milliseconds: 1000), (){
                                          //   if (eraseOnPressedHandle != null) {
                                          //     soloud?.stop(eraseOnPressedHandle!);
                                          //   }
                                          // });
                                        }
                                      },
                                      onTapUp: (details) async {
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

                                        setState(() {});
                                      },
                                      child: Container(
                                        width: 25,
                                        height: 25,
                                        decoration: const BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.grey,
                                              blurRadius:
                                                  5.0, // soften the shadow
                                              spreadRadius:
                                                  2.0, //extend the shadow
                                              offset: Offset(
                                                5.0, // Move to right 5  horizontally
                                                5.0, // Move to bottom 5 Vertically
                                              ),
                                            )
                                          ],
                                        ),
                                        child: const Icon(Icons.remove),
                                      ),
                                    ),
                            ),
                          ],
                        );
                        // }
                      }).toList()),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          bottom: 5,
          left: 5,
          child: GestureDetector(
            onTapCancel: () async {
              if (buttonPopSource != null) {
                buttonPopHandle = await soloud?.play(buttonPopSource!, looping: false);
                // Future.delayed(const Duration(milliseconds: 1000), (){
                //   if (buttonOnPressedHandle != null) {
                //     soloud?.stop(buttonOnPressedHandle!);
                //   }
                // });
              }
            },
            onTapDown: (details) async {
                isDeleteMode = !isDeleteMode;
                if (buttonOnPressedSource != null) {
                  buttonOnPressedHandle = await soloud?.play(buttonOnPressedSource!, looping: false);
                  // Future.delayed(const Duration(milliseconds: 1000), (){
                  //   if (buttonOnPressedHandle != null) {
                  //     soloud?.stop(buttonOnPressedHandle!);
                  //   }
                  // });
                }
                setState(() {});              
            },
            child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  elevation: 7,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5.0),
                      side: const BorderSide(color: Colors.transparent)),
                  backgroundColor:
                      isDeleteMode ? const Color(0XFFFD8164) : Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 0, vertical: 20),
                ),
                onPressed: () async {
            
                },
                child: const Icon(
                  size: 30,
                  Icons.delete,
                  color: Colors.black,
                )),
          ),
        )
      ],
    );
  });
}

void printDebug(s) {
  print(s);
}
