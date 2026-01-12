import 'package:flutter/material.dart';
import 'features/home/home_screen.dart';
import 'features/game/game_screen.dart';
import 'domain/entities/level.dart';

void main() {
  runApp(const SlideEscapeApp());
}

class SlideEscapeApp extends StatelessWidget {
  const SlideEscapeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Slide Escape',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),

      // >>> Important! This is the entrypoint!
      home: const HomeScreen(),

      onGenerateRoute: (settings) {
        if (settings.name == '/game') {
          final level = settings.arguments as Level;
          return MaterialPageRoute(
            builder: (_) => GameScreen(level: level),
          );
        }
        return null;
      },
    );
  }
}
