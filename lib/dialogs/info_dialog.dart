import 'package:flutter/material.dart';

import '../utils/General.dart';
// import 'package:cart_stepper/cart_stepper.dart';
// import 'package:item_count_number_button/item_count_number_button.dart';
// import 'package:number_selection/number_selection.dart';

Future<void> neuronDialogBuilder(
    BuildContext context,
    String title,
    String nodeId,
    String neuronType,
    neuronTypeChangecallback,
    deleteCallback) {
  String val = neuronType;
  List<String> neuronTypesLabel = [
    "Select Neuron Type",
    "Quiet",
    "Occassionally active",
    "Highly active",
    "Generates bursts",
    "Bursts when activated",
    "Dopaminergic",
    "Striatal"
  ];
  List<String> neuronTypes = ["-", "Quiet", "Occassionally active", "Highly active", "Generates bursts", "Bursts when activated", "Dopaminergic", "Striatal"];
  List<DropdownMenuItem> dropdownMenuItems =
      List<DropdownMenuItem>.generate(neuronTypes.length, (index) {
    return DropdownMenuItem(
      value: neuronTypes[index],
      child: Text(neuronTypesLabel[index]),
    );
  });

  return showDialog<void>(
    context: context,
    builder: (BuildContext context) {
      return StatefulBuilder(builder: (ctx, setState) {
        return AlertDialog(
          // title: const Text('Basic dialog title'),
          content: SizedBox(
            height: 250,
            width: 400,
            child: ListView(
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text("#$nodeId"),
                    const VerticalDivider(),
                    DropdownButton(
                      value: val,
                      items: dropdownMenuItems,
                      onChanged: (value) {
                        val = value;
                        neuronTypeChangecallback(value);
                        setState(() {});
                      },
                    ),
                    const VerticalDivider(),
                    GestureDetector(
                        onTap: () {
                          deleteCallback();
                          Navigator.pop(context);
                        },
                        child: const Icon(Icons.delete))
                  ],
                ),
              ],
            ),
          ),
        );
      });
    },
  );
}

Future<void> axonDialogBuilder(
    BuildContext context,
    int isSensoryType,
    String title,
    String nodeId,
    map,
    neuronTypeChangecallback,
    deleteCallback,
    linkTypeChangecallback,
    linkMotorCallback,
    linkNeuronConnection) {
  List<String> linkTypesLabel = [
    "Select Visual Preference",
    "Blue",
    "Blue (side)",
    "Green",
    "Green (side)",
    "Red",
    "Red (side)",
    "Movement"
  ];
  List<String> linkTypes = [
    "-",
    "Blue",
    "Blue (side)",
    "Green",
    "Green (side)",
    "Red",
    "Red (side)",
    "Movement"
  ];

  // int motorValue = map["visualPref"].floor();
  // print("motorValue");
  // print(motorValue);

  String val = linkTypes[map["visualPref"].floor() + 1];
  List<DropdownMenuItem> dropdownMenuItems =
      List<DropdownMenuItem>.generate(linkTypes.length, (index) {
    return DropdownMenuItem(
      value: linkTypes[index],
      child: Text(linkTypesLabel[index]),
    );
  });

  TextEditingController txtContactWeightController =
      TextEditingController(text: map["neuronContact"].floor().toString());
  TextEditingController txtNeuronWeightController =
      TextEditingController(text: map["connectomeContact"].floor().toString());

  txtContactWeightController.addListener(() {
    linkMotorCallback(txtContactWeightController.text);
  });

  txtNeuronWeightController.addListener(() {
    linkMotorCallback(txtNeuronWeightController.text);
  });

  return showDialog<void>(
    context: context,
    builder: (BuildContext context) {
      return StatefulBuilder(builder: (ctx, setState) {
        return AlertDialog(
          // title: const Text('Basic dialog title'),
          content: SizedBox(
            width: 300,
            height: 250,
            child: ListView(
              // mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const VerticalDivider(),
                    GestureDetector(
                        onTap: () {
                          deleteCallback();
                          Navigator.pop(context);
                        },
                        child: const Icon(Icons.delete)),
                  ],
                ),
                if (isSensoryType == 0) ...{
                  TextField(
                    onChanged: (val) {
                      linkNeuronConnection(val);
                    },
                    controller: txtNeuronWeightController,
                    keyboardType: TextInputType.number,
                    inputFormatters: whiteListingTextInputFormatter,
                    decoration: inputWeightDecoration,
                    maxLines: 1,
                  ),
                } else if (isSensoryType == 1) ...{
                  DropdownButton(
                    value: val,
                    items: dropdownMenuItems,
                    onChanged: (value) {
                      val = value;
                      linkTypeChangecallback(
                          linkTypes.indexOf(value.toString()) - 1);
                      setState(() {});

                      // Navigator.pop(context);
                    },
                  ),
                } else if (isSensoryType == 2) ...[
                  TextField(
                    onChanged: (val) {
                      linkMotorCallback(val);
                    },
                    controller: txtContactWeightController,
                    keyboardType: TextInputType.number,
                    inputFormatters: whiteListingTextInputFormatter,
                    decoration: inputWeightDecoration,
                    maxLines: 1,
                  ),
                  // SizedBox(
                  //   width: 100,
                  //   height:50,
                  //   child: CartStepperInt(
                  //     value: _motorValue,
                  //     numberSize: 20,
                  //     size: 10,
                  //     // style: CartStepperTheme.of(context).copyWith(activeForegroundColor: Colors.purple,),
                  //     didChangeCount: (count) {
                  //       setState(() {
                  //         _motorValue = count;
                  //         linkMotorCallback(count);
                  //       });
                  //     }
                  //   ),
                  // )
                ],
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 20),
                ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text("Save")),

                // const SizedBox(width:10,height:10,)
              ],
            ),
          ),
        );
      });
    },
  );
}

Future<void> linkDialogBuilder(
    BuildContext context, String linkType, linkTypeChangecallback) {
  String val = linkType;
  List<String> linkTypesLabel = [
    "Select Visual Preference",
    "Red",
    "Red (side)",
    "Green",
    "Green (side)",
    "Blue",
    "Blue (side)",
    "Movement"
  ];
  List<String> linkTypes = [
    "-",
    "Red",
    "Red (side)",
    "Green",
    "Green (side)",
    "Blue",
    "Blue (side)",
    "Movement"
  ];
  List<DropdownMenuItem> dropdownMenuItems =
      List<DropdownMenuItem>.generate(linkTypes.length, (index) {
    return DropdownMenuItem(
      value: linkTypes[index],
      child: Text(linkTypesLabel[index]),
    );
  });

  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return StatefulBuilder(builder: (ctx, setState) {
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
      });
    },
  );
}
