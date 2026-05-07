import 'package:flutter/material.dart';

class TitledTextField extends StatelessWidget {
  const TitledTextField({
    super.key,
    required this.title,
    required this.controller,
    this.keyboardType,
    this.obscureText = false,
  });

  final String title;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final bool obscureText;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 130, child: Text('$title:', style: const TextStyle(fontWeight: FontWeight.bold))),
        Expanded(
          child: TextField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
        ),
      ],
    );
  }
}
