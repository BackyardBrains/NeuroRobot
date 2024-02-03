import 'dart:io';

import 'package:fialogs/fialogs.dart';
import 'package:flutter/material.dart';
import 'package:neurorobot/brands/brandguide.dart';
import 'package:path/path.dart';
// import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:responsive_grid/responsive_grid.dart';

bool isLoadBrainDialog = false;
Future<void> loadBrainDialog(
    BuildContext context, String title, selectCallback) async {
  String imagesPath = "/images";
  // String imagesPath = "";

  List<File> fileNames = [];
  isLoadBrainDialog = true;
  final Directory directory = Directory(
      "${(await getApplicationDocumentsDirectory()).path}$imagesPath");
  // print("directory.existsSync()");
  // print(directory.existsSync());
  // print(directory.path);
  // List<FileSystemEntity> entity = directory.listSync(recursive: false);
  // print(entity.length);
  if (!directory.existsSync()) {
    // if (entity.isEmpty) {
    // ignore: use_build_context_synchronously
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
    return;
  }
  List<FileSystemEntity> entity = directory.listSync(recursive: false);
  var fileList = entity
      .map((item) => item.path)
      .where((item) => item.endsWith('.png'))
      .toList(growable: false);
  var statResults = await Future.wait([
    for (var path in fileList) FileStat.stat(path),
  ]);

  var mtimes = <String, DateTime>{
    for (var i = 0; i < fileList.length; i += 1)
      fileList[i]: statResults[i].changed,
  };
  fileList.sort((a, b) => mtimes[a]!.compareTo(mtimes[b]!));

  fileList.forEach((fileString) {
    print(fileString);
    if (fileString.contains(".png")) fileNames.insert(0, File(fileString));
    // if (element.path.contains(".png")) fileNames.add(File(element.path));
  });
  print("fileNames");
  print(fileNames);

  // ignore: use_build_context_synchronously
  return showDialog<void>(
    context: context,
    builder: (BuildContext context) {
      return StatefulBuilder(builder: (ctx, setState) {
        return AlertDialog(
          // title: const Text('Basic dialog title'),
          content: SizedBox(
            width: 500,
            height: 400,
            // width: MediaQuery.of(context).size.width * 0.7,
            // height: MediaQuery.of(context).size.height * 0.7,
            child: showBrainDisplay(context, fileNames, selectCallback),
          ),
        );
      });
    },
  ).whenComplete(() => isLoadBrainDialog = false);
}

showBrainDisplay(BuildContext context, List<File> fileNames, selectCallback) {
  return LayoutBuilder(builder: (ctx, constraints) {
    List<String> imageIds = [];
    List<String> imageTitles = [];
    List<String> imageDescriptions = [];
    print("constraints");
    print(constraints);

    fileNames.every((file) {
      String filename = basename(file.path).replaceAll("Brain", "");
      filename = filename.replaceAll(".png", "");
      List<String> arrImageInfo = filename.split("@@@");
      print("arrImageInfo");
      print(arrImageInfo);

      imageIds.add(arrImageInfo[0]);
      imageTitles.add(arrImageInfo[1]);
      imageDescriptions.add(arrImageInfo[2]);
      return true;
    });

    return SizedBox(
      width: constraints.maxWidth,
      height: constraints.maxHeight,
      child: ResponsiveGridList(
          desiredItemWidth: MediaQuery.of(context).size.width * 0.2,
          minSpacing: 10,
          children: List.generate(fileNames.length, (index) => index).map((i) {
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

            return GestureDetector(
              onTap: () {
                String filename =
                    basename(fileNames[i].path).replaceAll("Brain", "");
                filename = filename.replaceAll(".png", "");
                List<String> arrImageInfo = filename.split("@@@");
                String imageId = arrImageInfo[0];
                selectCallback(imageId);
                Navigator.pop(context);
              },
              child: Card(
                margin: const EdgeInsets.all(7),
                child: Container(
                  height: 270,
                  padding: const EdgeInsets.all(7),
                  // alignment: const Alignment(0, 0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Image.file(
                        fileNames[i],
                        fit: BoxFit.contain,
                        height: 150,
                      ),
                      Text(imageTitles[i], style: headerStyle),
                      Text(imageDescriptions[i], style: subHeaderStyle),
                    ],
                  ),
                ),
              ),
            );
            // }
          }).toList()),
    );
  });
}
