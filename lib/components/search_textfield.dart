import 'package:flutter/material.dart';

class SearchTextField extends StatelessWidget {
  final String hintText;
  final TextEditingController controller;
  final void Function(String) onChanged;

  const SearchTextField({
    Key? key,
    required this.hintText,
    required this.controller,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hintText,
        filled: true,
        fillColor: Colors.grey[200],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
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
