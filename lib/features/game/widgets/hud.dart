import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controller/game_controller.dart';

class GameHud extends ConsumerWidget {
  final VoidCallback onRestart;

  // Anpassungs-Parameter
  final Color buttonColor;          // Hintergrundfarbe Restart
  final Color activeUndoRedoColor;  // Hintergrundfarbe Undo/Redo (wenn aktiv)

  // NEU: Text-Anpassungen
  final Color textColor;            // Farbe für den Text (Moves)
  final Color buttonTextColor;      // Farbe für Text IN den Buttons

  final double fontSize;            // Basis-Schriftgröße (für Buttons)
  final double movesFontSize;       // Eigene Schriftgröße nur für "Moves"

  final FontWeight fontWeight;
  final double verticalOffset;

  const GameHud({
    super.key,
    required this.onRestart,
    this.buttonColor = Colors.blue,
    this.activeUndoRedoColor = Colors.blue,
    // Standards setzen
    this.textColor = Colors.black87,
    this.buttonTextColor = Colors.black,
    this.fontSize = 16.0,
    this.movesFontSize = 16.0, // Standardmäßig gleich groß wie der Rest
    this.fontWeight = FontWeight.normal,
    this.verticalOffset = 0.0,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameControllerProvider);
    final controller = ref.read(gameControllerProvider.notifier);

    final used = state.movesUsed;
    final limit = state.moveLimit;

    // Style für die Buttons
    final buttonTextStyle = TextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: buttonTextColor,
    );

    // Style speziell für den Moves-Text
    final movesTextStyle = TextStyle(
      fontSize: movesFontSize, // Hier nutzen wir die separate Größe
      fontWeight: fontWeight,
      color: textColor,        // Hier nutzen wir die separate Farbe
    );

    // Hilfsfunktion für den Style der Undo/Redo Buttons
    ButtonStyle undoRedoStyle(bool enabled) {
      return FilledButton.styleFrom(
        textStyle: buttonTextStyle,
        // Wenn aktiv -> Deine Wunschfarbe. Wenn inaktiv -> Standard (Transparent/Grau)
        backgroundColor: enabled ? activeUndoRedoColor : null,
        // Textfarbe: Wenn enabled -> buttonTextColor, sonst System-Standard für disabled
        foregroundColor: enabled ? buttonTextColor : null,
      );
    }

    final canUndo = state.history.isNotEmpty && !state.failed;
    final canRedo = state.future.isNotEmpty && !state.failed;

    return Transform.translate(
      offset: Offset(0, verticalOffset),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Undo Button
              FilledButton.tonal(
                onPressed: canUndo ? controller.undo : null,
                style: undoRedoStyle(canUndo),
                child: const Text('Undo'),
              ),
              const SizedBox(width: 12),

              // Redo Button
              FilledButton.tonal(
                onPressed: canRedo ? controller.redo : null,
                style: undoRedoStyle(canRedo),
                child: const Text('Redo'),
              ),
              const SizedBox(width: 12),

              // Restart Button
              FilledButton(
                onPressed: onRestart,
                style: FilledButton.styleFrom(
                  backgroundColor: buttonColor,
                  foregroundColor: buttonTextColor,
                  textStyle: buttonTextStyle,
                ),
                child: const Text('Restart'),
              ),
              const SizedBox(width: 24),

              // Moves Text (Jetzt mit eigenem Style)
              Text(
                limit == null ? 'Moves: $used' : 'Moves: $used / $limit',
                style: movesTextStyle,
              ),
            ],
          ),
        ),
      ),
    );
  }
}