import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

List<TextInputFormatter> whiteListingTextInputFormatter = [
  FilteringTextInputFormatter.allow(RegExp(r'[0-9]')), 
  FilteringTextInputFormatter.digitsOnly
];

InputDecoration inputWeightDecoration = const InputDecoration(
    labelText: "Input Weight",
    // hintText: "Input Weight",
    icon: Icon(Icons.monitor_weight)
);