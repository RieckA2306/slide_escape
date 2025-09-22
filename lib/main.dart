import 'package:flutter/material.dart';
import 'features/level_map/level_map_screen.dart';
import 'features/game/game_screen.dart';
import 'domain/level.dart';

void main() {
  runApp(const SlideEscapeApp());
}

class SlideEscapeApp extends StatelessWidget {
  const SlideEscapeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Slide Escape',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: "/map",
      routes: {
        "/map": (context) => const LevelMapScreen(),
        "/game": (context) {
          final level = ModalRoute.of(context)!.settings.arguments as Level;
          return GameScreen(level: level);
        },
      },
    );
  }
}
