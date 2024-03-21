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
