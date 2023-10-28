  import 'package:flutter/material.dart';

Future<void> neuronDialogBuilder(BuildContext context, String title, String nodeId, neuronTypeChangecallback,deleteCallback) {
  String val = "-";
  List<String> neuronTypesLabel = ["Select Neuron Type","Quiet", "Occassionally active", "Highly active", "Generates bursts", "Bursts when activated", "Dopaminergic", "Striatal"];
  List<String> neuronTypes = ["-","RS", "FS", "LTS", "IB", "CH", "RZ", "TC"];
  List<DropdownMenuItem> dropdownMenuItems = List<DropdownMenuItem>.generate(neuronTypes.length, (index) {
    return DropdownMenuItem(
      value: neuronTypes[index],
      child: Text(neuronTypesLabel[index]),
    );
  });

  return showDialog<void>(
    context: context,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (ctx, setState) {
          return AlertDialog(
            // title: const Text('Basic dialog title'),
            content: SizedBox(
              height: 250,
              width: 400,
              child: ListView(
                children: [
                  Row(
                    children: [
                      Text(title, style: const TextStyle(fontWeight: FontWeight.bold),),
                      Text("#$nodeId"),
                      const VerticalDivider(),
                      DropdownButton(
                        value: val,
                        items: dropdownMenuItems, 
                        onChanged: (value) {
                          val = value;
                          neuronTypeChangecallback(value);
                          setState((){});
                        }, 
                      ),
                      const VerticalDivider(),
                      GestureDetector(
                        onTap:(){
                          deleteCallback();
                          Navigator.pop(context);
                        },
                        child: const Icon(Icons.delete)
                      )
                    ],
                  ),
                ],
              ),
            ),
          );
        }
      );
    },
  );
}

Future<void> axonDialogBuilder(BuildContext context, String title, String nodeId, neuronTypeChangecallback,deleteCallback) {
 
  return showDialog<void>(
    context: context,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (ctx, setState) {
          return AlertDialog(
            // title: const Text('Basic dialog title'),
            content: SizedBox(
              height: 50,
              child: Row(
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold),),
                  const VerticalDivider(),
                  GestureDetector(
                    onTap:(){
                      deleteCallback();
                      Navigator.pop(context);
                    },
                    child: const Icon(Icons.delete)
                  )
                ],
              ),
            ),
          );
        }
      );
    },
  );
}