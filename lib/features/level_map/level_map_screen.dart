import 'package:flutter/material.dart';
import '../../domain/level.dart';

class LevelMapScreen extends StatelessWidget {
  const LevelMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Testlevels
    final levels = [
      Level(id: 1, type: LevelType.normal, size: 6, targetIds: [1]),
      Level(id: 2, type: LevelType.normal, size: 6, targetIds: [1]),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text("Level Map")),
      body: Stack(
        children: [
          // Hintergrundbild füllt den kompletten Screen
          Positioned.fill(
            child: Image.asset(
              "assets/map_background/background.jpg",
              fit: BoxFit.cover, // skaliert so, dass alles ausgefüllt ist
            ),
          ),

          // Level 1 Button
          Positioned(
            left: 216, // X-Koordinate
            top: 748,  // Y-Koordinate
            child: GestureDetector(
              onTap: () => Navigator.pushNamed(context, "/game", arguments: levels[0]),
              child: const CircleAvatar(
                radius: 30,
                backgroundColor: Colors.blue,
                child: Text("1"),
              ),
            ),
          ),

          // Level 2 Button
          Positioned(
            left: 125,
            top: 520,
            child: GestureDetector(
              onTap: () => Navigator.pushNamed(context, "/game", arguments: levels[1]),
              child: const CircleAvatar(
                radius: 26,
                backgroundColor: Colors.red,
                child: Text("2"),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
