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
        return Dialog(
          insetPadding: const EdgeInsets.all(20), // Minimal padding for full width feel
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            width: MediaQuery.of(context).size.width,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  children: [
                    const Icon(Icons.save_as_rounded, size: 40, color: Colors.blueGrey),
                    const SizedBox(width: 16),
                    Text(
                      "Save Brain",
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.blueGrey
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Body
                TextField(
                    maxLength: 25,
                    decoration: const InputDecoration(
                      labelText: "Title",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.title),
                    ),
                    controller: txtSaveTitleController),
                const SizedBox(height: 16),
                TextField(
                    maxLength: 70,
                    decoration: const InputDecoration(
                      labelText: "Description",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.description),
                    ),
                    controller: txtSaveDescriptionController),
                
                isSaveBrainError
                    ? Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text("Please provide a Title and Description", 
                          style: TextStyle(color: Theme.of(context).colorScheme.error)),
                      )
                    : const SizedBox(),
                
                const SizedBox(height: 32),

                // Footer
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text("Cancel")),
                    const SizedBox(width: 16),
                    FilledButton.icon(
                        icon: const Icon(Icons.save),
                        onPressed: () {
                          String title = txtSaveTitleController.text;
                          String description = txtSaveDescriptionController.text;
                          if (title.trim().isEmpty || description.trim().isEmpty) {
                            isSaveBrainError = true;
                            setState(() {});
                          } else {
                            isSaveBrainError = false;
                            Navigator.pop(context);
                            saveCallback(txtSaveTitleController.text, txtSaveDescriptionController.text);
                          }
                        },
                        label: const Text("Save Brain")),
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
