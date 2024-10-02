import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

Future<bool> dataCaptureSave(map) async {
  // print(frameData);
  return await compute(_dataCaptureSave, map);
}

Future<bool> _dataCaptureSave(rawData) async {
  String pathSeparator = Platform.pathSeparator; //"/"; //
  if (Platform.isWindows) {
    pathSeparator = Platform.pathSeparator;
  }
  String captureDirectoryPath = rawData["path"];
  Uint8List frameData = rawData["frameData"];
  String serialData = rawData["serial_data"];
  String torqueData = rawData["torque_data"];

  final dateFormat = DateFormat('yyyy-MM-dd hh_mm_ss');
  final curDate = DateTime.now();
  String fileName = curDate.millisecondsSinceEpoch.toString();
  final strDateNow = dateFormat.format(curDate);
  const String singleFileName = "_InformationData";

  if (frameData.isNotEmpty) {
    final File file = File(
        '$captureDirectoryPath${pathSeparator}spikerbot$pathSeparator$strDateNow-$fileName.jpg');
    // file.createSync();
    file.writeAsBytesSync(frameData);
  }

  // if (serialData.isNotEmpty) {
  // final File serialFile =
  //     File('$captureDirectoryPath$pathSeparator${singleFileName}.txt');
  // serialFile.createSync();
  // serialFile.writeAsStringSync("$serialData\r\n", mode: FileMode.append);
  // }

  // if (torqueData.isNotEmpty) {
  final File torqueFile = File(
      '$captureDirectoryPath${pathSeparator}spikerbot$pathSeparator$singleFileName.txt');
  // torqueFile.createSync();
  torqueFile.writeAsStringSync(
      "$strDateNow-$fileName\r\n$serialData\r\n$torqueData\r\n",
      mode: FileMode.append);
  // }

  return true;
}
