import 'package:flutter/material.dart';
import '../../domain/level.dart';

class GameScreen extends StatelessWidget {
  final Level level;

  const GameScreen({super.key, required this.level});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Level ${level.id}")),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("Type: ${level.type}"),
          if (level.timeLimit != null)
            Text("⏱️ Time Limit: ${level.timeLimit}s"),
          if (level.moveLimit != null)
            Text("🎯 Move Limit: ${level.moveLimit}"),
          const SizedBox(height: 20),
          const Text("👉 Hier kommt später das Spielfeld 👈"),
        ],
      ),
    );
  }
}
