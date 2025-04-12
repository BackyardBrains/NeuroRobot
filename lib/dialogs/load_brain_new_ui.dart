import 'package:file_picker/file_picker.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/foundation.dart';
import 'package:idb_shim/idb.dart';
import 'package:idb_shim/idb_browser.dart';
// import 'package:file_selector/file_selector.dart';

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:fialogs/fialogs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:neurorobot/brands/brandguide.dart';
import 'package:path/path.dart';
// import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:responsive_grid/responsive_grid.dart';
import 'package:sn_progress_dialog/progress_dialog.dart';

TextEditingController tecBrainName = TextEditingController();
TextEditingController tecBrainDescription = TextEditingController();
bool isDeleteMode = false;
int isSavingMode = 1;
bool isEditingMenu = true;
bool isUploading = false;
String currentFileName = "-";
Map mapStatus = {};
int idbVersion = 1;

// String infoPath = "${Platform.pathSeparator}info";
// String imagesPath =
//     "${Platform.pathSeparator}spikerbot${Platform.pathSeparator}images";
// String textPath =
//     "${Platform.pathSeparator}spikerbot${Platform.pathSeparator}text";
List<String> fileNames = [];

Directory? documentPath;
List<Map<String, String>> fileInfos = [];

bool isLoadBrainDialog = false;
late Database db;
// IdbFactory? idbFactory = getIdbFactory();
Future<List<String>> loadBrainFiles(fileInfos, context) async {
  List<String> fileNames = [];

  isLoadBrainDialog = true;

  // open the database
  // bool isDatabaseCreated = false;
  const String storeName = "spikerbot";
  // if (idbFactory != null) {
  //   Database db = await idbFactory.open("byb_spikerbot.db", version: idbVersion,
  //       onUpgradeNeeded: (VersionChangeEvent event) {
  //     Database db = event.database;
  //     if (db.objectStoreNames.toList().contains(storeName)) {
  //       isDatabaseCreated = true;
  //     }
  //   });
  {
    // printDebug("isDatabaseCreated");
    // printDebug(isDatabaseCreated);
    // if (!isDatabaseCreated) {
    //   return [];
    // }

    var txn = db.transaction(storeName, "readonly");
    var store = txn.objectStore(storeName);
    // Map value = await store.getObject(key);
    var rawKeys = await store.getAllKeys();
    printDebug("rawKeys");
    printDebug(rawKeys);

    Map mapValues = {};
    for (var rawKey in rawKeys) {
      String key = rawKey as String;
      if (key.contains(".brain")) {
        fileNames.insert(0, key);
        Map myMap = (await store.getObject(key) as Map);
        mapValues[key] = (myMap);
        List<String> arr = key.split("@@@");
        Map<String, String> brainInfo = {};
        brainInfo.putIfAbsent("title", () => arr[0]);
        brainInfo.putIfAbsent("description", () => arr[1]);
        fileInfos.insert(0, brainInfo);

      } else
      if (key.contains(".txt")) {      
        fileNames.insert(0, key);
        Map myMap = (await store.getObject(key) as Map);
        mapValues[key] = (myMap);
        List<String> arr = key.split("@@@");
        Map<String, String> brainInfo = {};
        brainInfo.putIfAbsent("title", () => arr[1]);
        brainInfo.putIfAbsent("description", () => arr[2].replaceAll(".txt", ""));
        fileInfos.insert(0, brainInfo);
      }
    }
    await txn.completed;
    printDebug("isDatabaseCreated2");
    printDebug(fileInfos);
    printDebug(mapValues.isEmpty);
    if (mapValues.isEmpty) {
      return [];
    }

    // var statResults = await Future.wait([
    //   for (var path in fileList) FileStat.stat(path),
    // ]);

    // var mtimes = <String, DateTime>{
    //   for (var i = 0; i < fileList.length; i += 1)
    //     fileList[i]: statResults[i].changed,
    // };
    // fileList.sort((a, b) => mtimes[a]!.compareTo(mtimes[b]!));

    // for (String fileString in mapValues.keys.toList()) {
    //   // printDebug(fileString);
    //   if (fileString.contains(".txt")) {
    //     fileNames.insert(0, File(fileString));
    //     List<String> arr = fileString.split("@@@");
    //     printDebug("arr");
    //     printDebug(arr);
    //     final File savedFile = File(fileString);
    //     if (savedFile.existsSync()) {
    //       Map<String, String> brainInfo = {};
    //       brainInfo.putIfAbsent("title", () => arr[1]);
    //       brainInfo.putIfAbsent(
    //           "description", () => arr[2].replaceAll(".txt", ""));
    //       fileInfos.insert(0, brainInfo);
    //     } else {
    //       Map<String, String> brainInfo = {
    //         "title": "Default title",
    //         "description": "Old file version, please recreate and delete this."
    //       };
    //       fileInfos.insert(0, brainInfo);
    //     }
    //   }
    // }
  }
  // else {
  //   return [];
  // }

  // read some data

  return fileNames;
}

String brainNameFromFileName(String filename) {
  filename = filename.replaceAll(".png", "");
  filename = filename.replaceAll("Brain", "");
  return filename;
}

passDatabase(database) {
  // print("pass Database0000");
  db = database;
}

Future<Uint8List> getImageFromText(path) async {
  Uint8List imageBytes = Uint8List(0);
  // final File savedFile = File(path);
  // if (savedFile.existsSync()) {
  // String strSavedFile = await savedFile.readAsString();
  printDebug("strSavedFile getImageFrom Text");
  printDebug(path);
  // printDebug(strSavedFile);
  const String storeName = "spikerbot";

  var txn = db.transaction(storeName, "readonly");
  var store = txn.objectStore(storeName);
  Map mapSavedFile = await store.getObject(path) as Map;
  // Map<String, dynamic> mapSavedFile = jsonDecode(strSavedFile);
  imageBytes = Uint8List.fromList(mapSavedFile["screenshot"].cast<int>());
  await txn.completed;
  // }
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
    for (String fileString in fileNames) {
      if (fileString.contains(currentFileName)) {
        printDebug("file.path");
        printDebug(fileString);
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

  // ignore: use_build_context_synchronously
  return showDialog<void>(
    context: context,
    builder: (BuildContext context) {
      return StatefulBuilder(builder: (ctx, setState) {
        printDebug("REDRAW");
        return AlertDialog(
          content: SizedBox(
            width: 500,
            height: 400,
            child: showBrainDisplay(
                context, fileNames, selectCallback, saveCallback, setState),
          ),
        );
      });
    },
  ).whenComplete(() => isLoadBrainDialog = false);
}

void noSavedBrainAlert(context) {
  customAlertDialog(
    context,
    const Text("Load Brain", style: TextStyle(fontFamily: "RobotoLocal")),
    const Text("There is no saved brain.", style: TextStyle(fontFamily: "RobotoLocal")),
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

showBrainDisplay(BuildContext context, List<String> fileNamez, selectCallback,
    saveCallback, setState) {
  return LayoutBuilder(builder: (ctx, constraints) {
    List<String> imageIds = [];
    List<String> imageTitles = [];
    List<String> imageDescriptions = [];
    List<List<int>> imageMemories =
        List.generate(fileNames.length, (index) => [0]);
    int idx = 0;

    fileNames.every((file) {
      String filename = file;
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
                      Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                    shadowColor: Colors.transparent,
                                    backgroundColor: Colors.transparent,
                                    foregroundColor: Colors.black,
                                    elevation: 0,
                                    side: BorderSide.none),
                                onPressed: () {
                                  isEditingMenu = !isEditingMenu;
                                  setState(() {});
                                },
                                child: isEditingMenu?
                                  const Icon(Icons.keyboard_arrow_up)
                                    : const Icon(Icons.menu)
                            ),
                          ),                      
                          Row(
                            children: [
                              GestureDetector(
                                onTapDown: (details) async {
                                  if (buttonOnPressedSource != null) {
                                    buttonOnPressedHandle = await soloud?.play(buttonOnPressedSource!, looping: false);
                                  }
                                },
                                onTapUp: (details) async {
                                  isUploading = false;
                                  if (buttonPopSource != null) {
                                    buttonPopHandle = await soloud?.play(buttonPopSource!, looping: false);
                                  }
                                  isUploading = false;
                                  FilePickerResult? result = await FilePicker.platform.pickFiles();
                                  if (result != null) {
                                    try{
                                      String strFile = utf8.decode(result.files[0].bytes!);
                                      var savedFileJson = jsonDecode(strFile);
                                      String key = result.files[0].name;
                                      const String storeName = "spikerbot";
                                      var txn = db.transaction(storeName, "readwrite");
                                      var store = txn.objectStore(storeName);
                                      // strNodesJson["fileName"] = fileName;
                                      // BrainText1727836013889917@@@save1@@@.txt

                                      await store.put(savedFileJson, key);
                                      await txn.completed;

                                    }catch(err) {
                                      print("err");
                                      print(err);
                                    }                                  
                                  }
                                // const XTypeGroup typeGroup = XTypeGroup(
                                //   extensions: <String>['txt'],
                                // );
                                // final XFile? file =
                                //     await openFile(acceptedTypeGroups: <XTypeGroup>[typeGroup], initialDirectory: "Downloads",confirmButtonText: "Open File");
                                // if (file!=null) {
                                //   String strFile = await file.readAsString();
                                //   var savedFileJson = jsonDecode(strFile);

                                //   try{
                                //     const String storeName = "spikerbot";
                                //     var txn = db.transaction(storeName, "readwrite");
                                //     var store = txn.objectStore(storeName);
                                //     // strNodesJson["fileName"] = fileName;
                                //     // BrainText1727836013889917@@@save1@@@.txt
                                //     String key = file.name;
                                //     print(key);

                                //     // await store.put(savedFileJson, key);
                                //     // await txn.completed;
                                    
                                //   }catch(err) {
                                //     print("err");
                                //     print(err);
                                //   }

                                // }
                                  fileInfos = [];
                                  fileNames = await loadBrainFiles(fileInfos, context);
                                  setState((){});

                              }, child: const Icon(Icons.cloud_download)),

                              GestureDetector(
                                onTapDown: (details) async {
                                  if (buttonOnPressedSource != null) {
                                    buttonOnPressedHandle = await soloud?.play(buttonOnPressedSource!, looping: false);
                                  }
                                },
                                onTapUp: (details) async {
                                  if (buttonPopSource != null) {
                                    buttonPopHandle = await soloud?.play(buttonPopSource!, looping: false);
                                  }

                                  isUploading = !isUploading;
                                  setState((){});
                                }, 
                                child: Icon(Icons.cloud_upload, color: !isUploading ? Colors.black: Colors.blue,)
                              )

                            ],
                          )
                        ],
                      ),
                      Expanded(
                        child: Container(
                          color: isSavingMode < 10 || isEditingMenu
                              ? Colors.white
                              : Colors.transparent,
                          height: 40,
                          alignment: Alignment.center,
                          child: TextField(
                            maxLength: 25,
                            decoration: const InputDecoration(
                                counterText: "", hintText: 'Name this brain'),
                            controller: tecBrainName,
                            enabled: isSavingMode < 10 || isEditingMenu
                                ? true
                                : false,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        child: const Icon(Icons.save),
                        onTapDown: (details) async {
                          if (buttonOnPressedSource != null) {
                            buttonOnPressedHandle = await soloud?.play(buttonOnPressedSource!, looping: false);
                          }
                        },
                        onTapUp: (details) async {
                          if (buttonPopSource != null) {
                            buttonPopHandle = await soloud?.play(buttonPopSource!, looping: false);
                          }
                          // if it is a new file
                          //    do nothing
                          // if not
                          //    delete old file

                          if (isSavingMode == 1) {
                          } else if (isSavingMode == 10) {
                            // delete old file
                            // File deleteFile = File(currentFileName);
                            // deleteFile.deleteSync();
                            deleteBrainRecord(currentFileName);
                          }

                          // create new file
                          currentFileName = await saveCallback(
                            tecBrainName.text,
                            tecBrainDescription.text,
                          );
                          printDebug("currentFileName1");
                          printDebug(currentFileName);
                          mapStatus["isSavingBrain"] = 10;
                          mapStatus["currentFileName"] = currentFileName;
                          // "${(documentPath)?.path}$imagesPath${Platform.pathSeparator}Brain$currentFileName.png";
                          // currentFileName = mapStatus["currentFileName"];
                          fileInfos = [];
                          fileNames = await loadBrainFiles(fileInfos, context);
                          isSavingMode = 10;
                          setState(() {});
                        },
                        onLongPress: () async {
                          if (buttonPopSource != null) {
                            buttonPopHandle = await soloud?.play(buttonPopSource!, looping: false);
                          }

                          singleInputDialog(
                            context,
                            "Save as current brain",
                            DialogTextField(
                                label: "Please name your brainzz",
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
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                          child: const Icon(Icons.save_as),
                          onTapDown: (details) async {
                            if (buttonOnPressedSource != null) {
                              buttonOnPressedHandle = await soloud?.play(buttonOnPressedSource!, looping: false);
                            }
                          },
                          onTapUp: (details) async {
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
                          }),
                      const SizedBox(width: 10),
                      GestureDetector(
                        child: const Icon(Icons.edit_document),
                        onTapDown: (details) async {
                          if (buttonOnPressedSource != null) {
                            buttonOnPressedHandle = await soloud?.play(buttonOnPressedSource!, looping: false);
                          }
                        },
                        onTapUp: (details) async {
                          if (buttonPopSource != null) {
                            buttonPopHandle = await soloud?.play(buttonPopSource!, looping: false);
                          }
                          if (isSavingMode < 10) {
                            tecBrainName.clear();
                            tecBrainDescription.clear();
                            mapStatus["isSavingBrain"] = 1;
                            mapStatus["currentFileName"] = "-";
                            currentFileName = "-";
                            selectCallback("-1");
                            if (pageFlipSource != null) {
                              pageFlipHandle = await soloud?.play(pageFlipSource!, looping: false);
                              Future.delayed(const Duration(milliseconds: 1000), (){
                                if (pageFlipHandle != null) {
                                  soloud?.stop(pageFlipHandle!);
                                  soloud?.disposeSource(pageFlipSource!);
                                }
                              });
                            }

                            Navigator.pop(context);
                          } else {
                            if (buttonOnPressedSource != null) {
                              buttonOnPressedHandle = await soloud?.play(buttonOnPressedSource!, looping: false);
                            }

                            confirmationDialog(context, "Creating new brain",
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
                                    pageFlipHandle = await soloud?.play(pageFlipSource!, looping: false);
                                    Future.delayed(const Duration(milliseconds: 1000), (){
                                      if (pageFlipHandle != null) {
                                        soloud?.stop(pageFlipHandle!);
                                        soloud?.disposeSource(pageFlipSource!);
                                        soloud?.disposeSource(buttonOnPressedSource!);

                                      }
                                    });
                                  }

                                  Navigator.pop(context);
                                },
                                confirmationDialog: false);
                          }
                        },
                      ),
                    ],
                  ),
                ),
                !isEditingMenu
                    ? Container()
                    : Container(
                        color: Colors.white,
                        margin: const EdgeInsets.fromLTRB(70, 0, 70, 10),
                        child: TextFormField(
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
                        printDebug(fileNames[i]);
                        printDebug(currentFullFilePath);
                        printDebug(fileNames[i] == currentFullFilePath);

                        return Stack(
                          children: [
                            GestureDetector(
                              onTap: () {
                                String filename = basename(fileNames[i]);
                                if (!kIsWeb) {
                                  filename = filename.replaceAll(".txt", "");
                                }
                                // List<String> arrImageInfo =
                                //     filename.split("@@@");
                                String imageId = filename;
                                mapStatus["isSavingBrain"] = 10;
                                mapStatus["currentFileName"] = fileNames[i];

                                selectCallback(imageId, filePath: fileNames[i]);
                                Navigator.pop(context);
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(17),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          fileNames[i] == (currentFullFilePath)
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
                                            future:
                                                getImageFromText(fileNames[i]),
                                            builder: (BuildContext context,
                                                AsyncSnapshot<Uint8List>
                                                    snapshot) {
                                              if (snapshot.connectionState ==
                                                  ConnectionState.waiting) {
                                                return const CircularProgressIndicator();
                                              } else if (snapshot.hasError) {
                                                return Text(
                                                    'Error: ${snapshot.error}', style: const TextStyle(fontFamily: "RobotoLocal")
                                                    );
                                              } else {
                                                if (snapshot.data!.length <
                                                    10) {
                                                  return Text(
                                                      'Error: ${snapshot.error}', style: const TextStyle(fontFamily: "RobotoLocal"));
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
                                  child: const Icon(Icons.cloud_upload_outlined),
                                  onTapDown: (details) async {
                                    if (buttonOnPressedSource != null) {
                                      buttonOnPressedHandle = await soloud?.play(buttonOnPressedSource!, looping: false);
                                    }

                                  },
                                  onTapUp: (details) async {
                                    if (buttonPopSource != null) {
                                      buttonPopHandle = await soloud?.play(buttonPopSource!, looping: false);
                                    }

                                    // basename(fileNames[i]);
                                    const String storeName = "spikerbot";
                                    var txn = db.transaction(storeName, "readonly");
                                    var store = txn.objectStore(storeName);
                                    String filename = fileNames[i];
                                    Map savedFileJson = await store.getObject(filename) as Map;
                                    await txn.completed;
                                    String myString = jsonEncode(savedFileJson);

                                    Uint8List bytesContent = utf8.encode(myString);
                                    await FileSaver.instance.saveFile(name: filename, bytes:bytesContent);
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
                                        }
                                      },
                                      onTapUp: (details) async {
                                        String filename =
                                            basename(fileNames[i]);
                                        filename =
                                            filename.replaceAll(".txt", "");
                                        // List<String> arrImageInfo =
                                        //     filename.split("@@@");
                                        // String imageId = filename;

                                        if (fileNames[i] == currentFileName) {
                                          tecBrainName.clear();
                                          tecBrainDescription.clear();
                                          currentFileName = "-";
                                          isSavingMode = 0;
                                          mapStatus["isSavingBrain"] = 0;
                                          mapStatus["currentFileName"] = "-1";
                                        }

                                        // Directory txtDirectory = Directory(
                                        //     "${(await getApplicationDocumentsDirectory()).path}$textPath");
                                        // // String textPath = "/text";
                                        // final File file = File(
                                        //     '${txtDirectory.path}${Platform.pathSeparator}$filename.txt');
                                        // file.deleteSync();
                                        deleteBrainRecord(filename);

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

void deleteBrainRecord(String filename) async {
  // bool isDatabaseCreated = false;
  const String storeName = "spikerbot";
  if (filename.contains(".txt") || filename.contains(".brain")) {
  } else {
    filename = "$filename.brain";
  }
  // IdbFactory? idbFactory = getIdbFactory();
  // if (idbFactory != null) {
  //   Database db = await idbFactory.open("byb_spikerbot.db", version: idbVersion,
  //       onUpgradeNeeded: (VersionChangeEvent event) {
  //     Database db = event.database;
  //     if (db.objectStoreNames.toList().contains(storeName)) {
  //       isDatabaseCreated = true;
  //     }
  //   });

  // if (!isDatabaseCreated) {
  //   printDebug("IS DATABASE NOT CREATED");
  // }

  print("delete brain 0");
  var txn = db.transaction(storeName, "readwrite");
  var store = txn.objectStore(storeName);
  await store.delete(filename);

  print("delete brain 1");
  print(filename);
  await txn.completed;
  // }
}

void printDebug(s) {
  // print(s);
}
