import 'package:flutter/material.dart';
import 'package:game_levels_scrolling_map/game_levels_scrolling_map.dart';
import 'package:game_levels_scrolling_map/model/point_model.dart';

import '../../domain/level.dart';

class LevelMapScreen extends StatelessWidget {
  const LevelMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Dummy Levels (wie vorher)
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

    // Punkte für die pub.dev-Map erzeugen
    final points = levels.map((level) {
      return PointModel(
        100,
        GestureDetector(
          onTap: () {
            // ✅ Übergang bleibt identisch
            Navigator.pushNamed(context, "/game", arguments: level);
          },
          child: CircleAvatar(
            radius: 20,
            backgroundColor: _getColor(level.type),
            child: Text(level.id.toString()),
          ),
        ),
      )..isCurrent = (level.id == 5); // Beispiel: aktuelles Level markieren
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text("Level Map")),
      body: GameLevelsScrollingMap.scrollable(
        imageUrl: "assets/drawable/map_vertical.png",
        svgUrl: "",
        direction: Axis.vertical,
        reverseScrolling: true,
        points: points,
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
