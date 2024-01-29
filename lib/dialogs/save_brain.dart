import 'package:flutter/material.dart';

TextEditingController txtSaveTitleController = TextEditingController();
TextEditingController txtSaveDescriptionController = TextEditingController();

bool isSaveBrainDialog = false;
bool isSaveBrainError = false;
Future<void> saveBrainInfoDialog(BuildContext context, saveCallback) async {
  isSaveBrainDialog = true;
  isSaveBrainError = false;

  // ignore: use_build_context_synchronously
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return StatefulBuilder(builder: (ctx, setState) {
        return AlertDialog(
          // title: const Text('Basic dialog title'),
          content: SizedBox(
            height: MediaQuery.of(context).size.width * 0.7,
            width: MediaQuery.of(context).size.height * 0.7,
            child: Column(
              children: [
                TextField(
                    maxLength: 25,
                    decoration: const InputDecoration(labelText: "Title"),
                    controller: txtSaveTitleController),
                // const Divider(),
                TextField(
                    maxLength: 70,
                    decoration: const InputDecoration(labelText: "Description"),
                    controller: txtSaveDescriptionController),
                // const Divider(),
                isSaveBrainError
                    ? const Text("There is an invalid information provided")
                    : const SizedBox(),
                const SizedBox(
                  height: 10,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text("Cancel")),
                    const SizedBox(
                      width: 10,
                    ),
                    ElevatedButton(
                        onPressed: () {
                          String title = txtSaveTitleController.text;
                          String description =
                              txtSaveDescriptionController.text;
                          if (title.trim().isEmpty ||
                              description.trim().isEmpty) {
                            isSaveBrainError = true;
                            setState(() {});
                          } else {
                            isSaveBrainError = false;
                            Navigator.pop(context);
                            saveCallback(txtSaveTitleController.text,
                                txtSaveDescriptionController.text);
                          }
                        },
                        child: const Text("Save")),
                  ],
                )
              ],
            ),
          ),
        );
      });
    },
  ).whenComplete(() => isSaveBrainDialog = false);
}
