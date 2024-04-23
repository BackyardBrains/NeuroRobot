import 'dart:io';

import 'package:fialogs/fialogs.dart';
import 'package:flutter/material.dart';
import 'package:neurorobot/brands/brandguide.dart';
import 'package:path/path.dart';
// import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:responsive_grid/responsive_grid.dart';

TextEditingController tecBrainName = TextEditingController();
TextEditingController tecBrainDescription = TextEditingController();
bool isDeleteMode = false;
int isSavingMode = 1;
bool isEditingMenu = false;
String currentFileName = "-";
Map mapStatus = {};

String infoPath = "${Platform.pathSeparator}info";
String imagesPath = "${Platform.pathSeparator}images";
String textPath = "${Platform.pathSeparator}text";
List<File> fileNames = [];

Directory? documentPath;
List<Map<String, String>> fileInfos = [];

bool isLoadBrainDialog = false;
Future<List<File>> loadBrainFiles(fileInfos, context) async {
  // String imagesPath = "";

  List<File> fileNames = [];
  // fileInfos = [];

  isLoadBrainDialog = true;
  documentPath = await getApplicationDocumentsDirectory();
  final Directory directory = Directory("${(documentPath)?.path}$imagesPath");
  if (!directory.existsSync()) {
    // if (entity.isEmpty) {
    // ignore: use_build_context_synchronously
    // noSavedBrainAlert(context);
    return [];
  }
  List<FileSystemEntity> entity = directory.listSync(recursive: false);
  var fileList = entity
      .map((item) => item.path)
      .where((item) => item.endsWith('.png'))
      .toList(growable: false);
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
    // print(fileString);
    if (fileString.contains(".png")) {
      fileNames.insert(0, File(fileString));
      String fileNameOnly = fileString
          .substring(fileString.lastIndexOf(Platform.pathSeparator) + 1)
          .replaceFirst("Brain", "BrainText")
          .replaceAll(".png", "");
      // String fileInfoString = fileString
      //     .substring(fileString.lastIndexOf(Platform.pathSeparator))
      //     .replaceAll("Brain", "BrainInfo")
      //     .replaceAll(".png", ".txt");
      List<String> arr = fileNameOnly.split("@@@");
      print("arr");
      print(fileNameOnly);
      print(arr);
      String fileInfoString = "${arr[0]}.txt";
      final File savedFile = File(
          '${documentPath!.path}$textPath${Platform.pathSeparator}$fileInfoString');
      print("fileInfoString");
      print(savedFile.path);
      if (savedFile.existsSync()) {
        Map<String, String> brainInfo = {};
        brainInfo.putIfAbsent("title", () => arr[1]);
        brainInfo.putIfAbsent("description", () => arr[2]);
        fileInfos.insert(0, brainInfo);
      } else {
        Map<String, String> brainInfo = {
          "title": "Default title",
          "description": "Old file version, please recreate and delete this."
        };
        fileInfos.insert(0, brainInfo);
      }
    }
    // if (element.path.contains(".png")) fileNames.add(File(element.path));
  }
  ;

  return fileNames;
}

String brainNameFromFileName(String filename) {
  filename = filename.replaceAll(".png", "");
  filename = filename.replaceAll("Brain", "");
  return filename;
}

Future<void> showLoadBrainDialog(BuildContext context, String title,
    selectCallback, saveCallback, pMapStatus) async {
  mapStatus = pMapStatus;
  print("mapStatus");
  print(mapStatus);
  isSavingMode = pMapStatus["isSavingBrain"];
  currentFileName = pMapStatus["currentFileName"];

  fileInfos = [];
  fileNames = await loadBrainFiles(fileInfos, context);
  // if (fileNames.isEmpty) return;

  print("currentFileName");
  print(currentFileName);
  if (currentFileName != "-") {
    int tempIdx = 0;
    int loadedIdx = -1;
    fileNames.forEach((file) {
      if (file.path.contains(currentFileName)) {
        print("file.path");
        print(file.path);
        print(currentFileName);
        loadedIdx = tempIdx;
      }
      tempIdx++;
    });
    if (loadedIdx >= 0) {
      tecBrainName.text = fileInfos[loadedIdx]["title"]!;
      tecBrainDescription.text = fileInfos[loadedIdx]["description"]!;
    }
  }

  print("fileNames");
  // print(fileNames);
  print(fileInfos);

  // ignore: use_build_context_synchronously
  return showDialog<void>(
    context: context,
    builder: (BuildContext context) {
      return StatefulBuilder(builder: (ctx, setState) {
        print("REDRAW");
        return AlertDialog(
          // title: const Text('Basic dialog title'),
          content: SizedBox(
            width: 500,
            height: 400,
            // width: MediaQuery.of(context).size.width * 0.7,
            // height: MediaQuery.of(context).size.height * 0.7,
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
    saveCallback, setState) {
  return LayoutBuilder(builder: (ctx, constraints) {
    List<String> imageIds = [];
    List<String> imageTitles = [];
    List<String> imageDescriptions = [];
    print("constraints");
    print(constraints);

    int idx = 0;

    fileNames.every((file) {
      String filename = basename(file.path).replaceAll("Brain", "");
      filename = filename.replaceAll(".png", "");
      // List<String> arrImageInfo = filename.split("@@@");

      imageIds.add(filename);
      try {
        imageTitles.add(fileInfos[idx]["title"]!);
        imageDescriptions.add(fileInfos[idx]["description"]!);
        idx++;
      } catch (err) {
        imageTitles.add("Default Title");
        imageDescriptions.add("Default Description");
        idx++;
        print("load err");
        print(err);
        print(fileInfos);
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
                      ElevatedButton(
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
                          child: isEditingMenu
                              ? const Icon(Icons.keyboard_arrow_up)
                              : const Icon(Icons.menu)),
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
                        onTap: () async {
                          // if it is a new file
                          //    do nothing
                          // if not
                          //    delete old file

                          if (isSavingMode == 1) {
                          } else if (isSavingMode == 10) {
                            // delete old file
                            File deleteFile = File(currentFileName);
                            deleteFile.deleteSync();
                          }

                          // create new file
                          currentFileName = await saveCallback(
                            tecBrainName.text,
                            tecBrainDescription.text,
                          );
                          print("currentFileName");
                          print(currentFileName);
                          mapStatus["isSavingBrain"] = 10;
                          mapStatus["currentFileName"] = currentFileName;
                          // "${(documentPath)?.path}$imagesPath${Platform.pathSeparator}Brain$currentFileName.png";
                          // currentFileName = mapStatus["currentFileName"];
                          fileInfos = [];
                          fileNames = await loadBrainFiles(fileInfos, context);
                          print("fileNames");
                          print(fileNames);
                          isSavingMode = 10;
                          setState(() {});
                        },
                        onLongPress: () {
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
                                  print(value);
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
                        child: const Icon(Icons.edit_document),
                        onTap: () {
                          if (isSavingMode < 10) {
                            tecBrainName.clear();
                            tecBrainDescription.clear();
                            mapStatus["isSavingBrain"] = 1;
                            mapStatus["currentFileName"] = "-";
                            currentFileName = "-";
                            selectCallback("-1");
                            Navigator.pop(context);
                          } else {
                            confirmationDialog(context, "Creating new brain",
                                "Are you sure to start a new workspace?",
                                titleIcon: const Icon(Icons.warning),
                                hideNeutralButton: true,
                                negativeButtonText: "Cancel",
                                negativeButtonAction: () {
                                  print("");
                                },
                                positiveButtonText: "Yes",
                                positiveButtonAction: () {
                                  tecBrainName.clear();
                                  tecBrainDescription.clear();
                                  mapStatus["isSavingBrain"] = 1;
                                  mapStatus["currentFileName"] = "-";
                                  currentFileName = "-";
                                  selectCallback("-1");
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
                      desiredItemWidth: MediaQuery.of(context).size.width * 0.2,
                      minSpacing: 10,
                      children:
                          List.generate(fileNames.length, (index) => index)
                              .map((i) {
                        // if (i == 0) {
                        //   return GestureDetector(
                        //     onTap: () {
                        //       // widget.callback("add_brain");
                        //     },
                        //     child: Card(
                        //       child: SizedBox(
                        //           height: 270,
                        //           child: Center(
                        //             child: Text(
                        //               "+",
                        //               style: TextStyle(fontSize: 70, color: brandBlue),
                        //             ),
                        //           )),
                        //     ),
                        //   );
                        // } else {
                        String currentFullFilePath = currentFileName;
                        print("currentFullFilePath");
                        print(currentFullFilePath);
                        print(fileNames[i].path);
                        print(fileNames[i].path == currentFullFilePath);

                        return Stack(
                          children: [
                            GestureDetector(
                              onTap: () {
                                String filename = basename(fileNames[i].path)
                                    .replaceAll("Brain", "");
                                filename = filename.replaceAll(".png", "");
                                List<String> arrImageInfo =
                                    filename.split("@@@");
                                String imageId = arrImageInfo[0];
                                mapStatus["isSavingBrain"] = 10;
                                mapStatus["currentFileName"] =
                                    fileNames[i].path;

                                selectCallback(imageId,
                                    filePath: fileNames[i].path);
                                Navigator.pop(context);
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
                                        // Text((fileNames[i].path ==
                                        //         currentFileName)
                                        //     .toString()),
                                        // Text(currentFileName),
                                        Image.file(
                                          fileNames[i],
                                          fit: BoxFit.contain,
                                          height: 150,
                                        ),
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
                            Positioned(
                              right: 0,
                              top: 0,
                              child: !isDeleteMode
                                  ? Container()
                                  : GestureDetector(
                                      onTap: () async {
                                        String filename =
                                            basename(fileNames[i].path)
                                                .replaceAll("Brain", "");
                                        filename =
                                            filename.replaceAll(".png", "");
                                        List<String> arrImageInfo =
                                            filename.split("@@@");
                                        String imageId = arrImageInfo[0];

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
                                        final File file = File(
                                            '${txtDirectory.path}${Platform.pathSeparator}BrainText$imageId.txt');
                                        file.deleteSync();
                                        final File fileImage =
                                            File(fileNames[i].path);
                                        fileImage.deleteSync();
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
          child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                elevation: 7,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5.0),
                    side: const BorderSide(color: Colors.transparent)),
                backgroundColor:
                    isDeleteMode ? const Color(0xFFEF5B5C) : Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 0, vertical: 20),
              ),
              onPressed: () {
                isDeleteMode = !isDeleteMode;
                setState(() {});
              },
              child: const Icon(
                size: 30,
                Icons.delete,
                color: Colors.black,
              )),
        )
      ],
    );
  });
}
