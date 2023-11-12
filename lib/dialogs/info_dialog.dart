  import 'package:flutter/material.dart';

Future<void> neuronDialogBuilder(BuildContext context, String title, String nodeId, String neuronType, neuronTypeChangecallback,deleteCallback) {
  String val = neuronType;
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

Future<void> axonDialogBuilder(BuildContext context, bool isVisualSensory, String title, String nodeId, neuronTypeChangecallback,deleteCallback, linkTypeChangecallback) {
  String val = '-';
  List<String> linkTypesLabel = ["Select Visual Preference","Red", "Red (side)", "Green", "Green (side)", "Blue", "Blue (side)", "Movement"];
  List<String> linkTypes = ["-","Red", "Red (side)", "Green", "Green (side)", "Blue", "Blue (side)", "Movement"];
  List<DropdownMenuItem> dropdownMenuItems = List<DropdownMenuItem>.generate(linkTypes.length, (index) {
    return DropdownMenuItem(
      value: linkTypes[index],
      child: Text(linkTypesLabel[index]),
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
              child: Column(
                children: [
                  Row(
                    children: [
                      Text(title, style: const TextStyle(fontWeight: FontWeight.bold),),
                      const VerticalDivider(),
                      GestureDetector(
                        onTap:(){
                          deleteCallback();
                          Navigator.pop(context);
                        },
                        child: const Icon(Icons.delete)
                      ),

                    ],
                  ),
                  !isVisualSensory?
                  const SizedBox(width:10,height:10,)
                  :
                  DropdownButton(
                    value: val,
                    items: dropdownMenuItems, 
                    onChanged: (value) {
                      val = value;
                      linkTypeChangecallback(value);
                      // setState((){});
                      Navigator.pop(context);

                    }, 
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



Future<void> linkDialogBuilder(BuildContext context, String linkType, linkTypeChangecallback) {
  String val = linkType;
  List<String> linkTypesLabel = ["Select Visual Preference","Red", "Red (side)", "Green", "Green (side)", "Blue", "Blue (side)", "Movement"];
  List<String> linkTypes = ["-","Red", "Red (side)", "Green", "Green (side)", "Blue", "Blue (side)", "Movement"];
  List<DropdownMenuItem> dropdownMenuItems = List<DropdownMenuItem>.generate(linkTypes.length, (index) {
    return DropdownMenuItem(
      value: linkTypes[index],
      child: Text(linkTypesLabel[index]),
    );
  });

  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (ctx, setState) {
          return AlertDialog(
            content: SizedBox(
              height: 250,
              width: 400,
              child: ListView(
                children: [
                  Row(
                    children: [
                      DropdownButton(
                        value: val,
                        items: dropdownMenuItems, 
                        onChanged: (value) {
                          val = value;
                          linkTypeChangecallback(value);
                          // setState((){});
                          Navigator.pop(context);

                        }, 
                      ),
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
