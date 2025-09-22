import 'package:flutter/material.dart';
import '../../domain/level.dart';

class LevelMapScreen extends StatelessWidget {
  const LevelMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Dummy Levels für Test
    final levels = List.generate(
      20,
          (i) => Level(
        id: i + 1,
        type: (i + 1) % 20 == 0
            ? LevelType.boss
            : (i + 1) % 10 == 0
            ? LevelType.moveLimit
            : (i + 1) % 5 == 0
            ? LevelType.timeLimit
            : LevelType.normal,
        size: 6,
        targetIds: [1],
      ),
    );

    return Scaffold(
      appBar: AppBar(title: const Text("Level Map")),
      body: Center(
        child: Wrap(
          spacing: 20,
          runSpacing: 20,
          children: levels.map((level) {
            return GestureDetector(
              onTap: () {
                Navigator.pushNamed(context, "/game", arguments: level);
              },
              child: CircleAvatar(
                radius: 30,
                backgroundColor: _getColor(level.type),
                child: Text(level.id.toString()),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Color _getColor(LevelType type) {
    switch (type) {
      case LevelType.timeLimit:
        return Colors.red;
      case LevelType.moveLimit:
        return Colors.blue;
      case LevelType.boss:
        return Colors.purple;
      default:
        return Colors.green;
    }
  }
}
