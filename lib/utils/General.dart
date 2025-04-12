import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

List<TextInputFormatter> whiteListingTextInputFormatter = [
  FilteringTextInputFormatter.allow(RegExp(r'[0-9.-]')),
  FilteringTextInputFormatter.digitsOnly
];
List<TextInputFormatter> neuronListingTextInputFormatter = [
  FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d{0,2}')),
];

InputDecoration inputWeightDecoration = const InputDecoration(
    labelText: "Input Weight",
    // hintText: "Input Weight",
    icon: Icon(Icons.monitor_weight));


double fillDefaultData(map, key, tec) {
  if (map[key] != null) {
    double sldSynapticWeight = (map[key] ?? 0).roundToDouble();
    tec.text = sldSynapticWeight.round().toString();
    return sldSynapticWeight;
  } else {
    tec.text = "0";
    return 0;
  }

}


Color hexToColor(String hexColor) {
  hexColor = hexColor.toUpperCase().replaceAll("#", "");
  if (hexColor.length == 6) {
    hexColor = "FF$hexColor"; // Add alpha channel if missing
  }
  return Color(int.parse(hexColor, radix: 16));
}

Map<String, int> hexToRgb(String hexColor) {
  Color color = hexToColor(hexColor);
  return {
    'r': color.red,
    'g': color.green,
    'b': color.blue,
  };
}

String rgbToHex(int r, int g, int b) {
  return '${r.toRadixString(16).padLeft(2, '0')}${g.toRadixString(16).padLeft(2, '0')}${b.toRadixString(16).padLeft(2, '0')}';
}