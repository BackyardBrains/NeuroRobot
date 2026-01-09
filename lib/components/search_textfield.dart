import 'package:flutter/material.dart';

class SearchTextField extends StatelessWidget {
  final String hintText;
  final TextEditingController controller;
  final void Function(String) onChanged;
  final Color? fillColor;

  const SearchTextField({
    Key? key,
    required this.hintText,
    required this.controller,
    required this.onChanged,
    this.fillColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hintText,
        filled: true,
        fillColor: fillColor ?? Colors.grey[200],
        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 20), // V17: Reduce Height
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30.0), // V17: Maximally Rounded
          borderSide: BorderSide.none,
        ),
        suffixIcon: IconButton(
          icon: const Icon(Icons.search),
          onPressed: () {
            // Implement your search logic here
          },
        ),
      ),
    );
  }
}
