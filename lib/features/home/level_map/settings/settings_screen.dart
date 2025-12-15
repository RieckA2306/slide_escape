import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  final double width;
  final double height;

  const SettingsScreen({
    super.key,
    this.width = 300,  // Standardbreite
    this.height = 400, // Standardhöhe
  });

  @override
  Widget build(BuildContext context) {
    // Ein einfaches weißes Rechteck mit abgerundeten Ecken
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20), // Abgerundete Ecken
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2), // Leichter Schatten für 3D-Effekt
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
            decoration: TextDecoration.none, // Wichtig bei Overlays ohne Material-Widget
          ),
        ),
      ),
    );
  }
}