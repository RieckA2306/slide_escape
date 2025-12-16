import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  // change these values to resize the box.
  final double width = 300;
  final double height = 300;

  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // We wrap everything in a Material widget to ensure standard font rendering.
    return Material(
      color: Colors.transparent,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: const Center(
          child: Text(
            "Settings",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
      ),
    );
  }
}