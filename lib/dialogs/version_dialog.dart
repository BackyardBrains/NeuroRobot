// WEB CHANGE
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../main.dart';
import '../utils/General.dart';
// import 'package:cart_stepper/cart_stepper.dart';
// import 'package:item_count_number_button/item_count_number_button.dart';
// import 'package:number_selection/number_selection.dart';

bool isVersionDialog = false;
Future<void> versionDialogBuilder(
    String version,
    BuildContext context,
    String title,
    String description,
    List<Widget> content,
    bool isForceUpdate,
    bool isInformation) {
  if (!isVersionDialog) {
    isVersionDialog = true;

    return showDialog<void>(
      context: context,
      barrierDismissible: isInformation,
      builder: (BuildContext context) {
        return StatefulBuilder(builder: (ctx, setState) {
          return AlertDialog(
            content: SizedBox(
              height: 300,
              width: 400,
              child: ListView(
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                  LayoutBuilder(builder: (context, snapshot) {
                    return SizedBox(
                      width: snapshot.maxWidth,
                      height: 150,
                      child: HtmlWidget(description),
                    );
                  }),
                  ...content,
                  if (!isForceUpdate) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade600,
                            ),
                            onPressed: () {
                              getApplicationDocumentsDirectory()
                                  .then((documentDirectory) async {
                                String versionPath =
                                    "${documentDirectory.path}${Platform.pathSeparator}spikerbot${Platform.pathSeparator}version";

                                File resultFile = File(
                                    "$versionPath${Platform.pathSeparator}currentVersion.txt");
                                if (!resultFile.existsSync()) {
                                  resultFile.createSync();
                                }
                                Map<String, String> content = {
                                  "version": version,
                                  "remindTime": DateTime.now()
                                      .add(const Duration(days: 1))
                                      .millisecondsSinceEpoch
                                      .toString(),
                                };
                                resultFile
                                    .writeAsStringSync(jsonEncode(content));
                                Navigator.pop(context);
                              });
                            },
                            child: const Text("Remind me tomorrow",
                                style: TextStyle(color: Colors.white))),
                        const SizedBox(
                          width: 20,
                        ),
                        ElevatedButton(
                            onPressed: () {
                              getApplicationDocumentsDirectory()
                                  .then((documentDirectory) async {
                                String versionPath =
                                    "${documentDirectory.path}${Platform.pathSeparator}spikerbot${Platform.pathSeparator}version";
                                File resultFile = File(
                                    "$versionPath${Platform.pathSeparator}currentVersion.txt");
                                if (!resultFile.existsSync()) {
                                  resultFile.createSync();
                                }
                                Map<String, String> content = {
                                  "version": version,
                                  "remindTime": DateTime.now()
                                      .add(const Duration(days: 999))
                                      .millisecondsSinceEpoch
                                      .toString(),
                                };
                                resultFile
                                    .writeAsStringSync(jsonEncode(content));
                                Navigator.pop(context);
                              });

                              // set localstorage version of the current one.
                            },
                            child: const Text("Skip this version")),
                      ],
                    )
                  ]
                ],
              ),
            ),
          );
        });
      },
    ).whenComplete(() => isVersionDialog = false);
  } else {
    return Future<void>.value();
  }
}
