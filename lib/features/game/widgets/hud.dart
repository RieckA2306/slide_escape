import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controller/game_controller.dart';

class GameHud extends ConsumerWidget {
  final VoidCallback onRestart;

  // Anpassungs-Parameter
  final Color buttonColor;          // Farbe des Restart Buttons
  final Color activeUndoRedoColor;  // NEU: Farbe für Undo/Redo wenn aktiv
  final double fontSize;
  final FontWeight fontWeight;
  final double verticalOffset;

  const GameHud({
    super.key,
    required this.onRestart,
    this.buttonColor = Colors.blue,
    this.activeUndoRedoColor = Colors.blue, // Standardwert
    this.fontSize = 16.0,
    this.fontWeight = FontWeight.normal,
    this.verticalOffset = 0.0,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameControllerProvider);
    final controller = ref.read(gameControllerProvider.notifier);

    final used = state.movesUsed;
    final limit = state.moveLimit;
    // Timer wurde hier entfernt

    final textStyle = TextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: Colors.black87,
    );

    // Hilfsfunktion für den Style der Undo/Redo Buttons
    ButtonStyle undoRedoStyle(bool enabled) {
      return FilledButton.styleFrom(
        textStyle: textStyle,
        // Wenn aktiv -> Deine Wunschfarbe. Wenn inaktiv -> Standard (Transparent/Grau)
        backgroundColor: enabled ? activeUndoRedoColor : null,
        // Damit die Textfarbe auf dem farbigen Button gut aussieht (meist weiß),
        // oder schwarz, je nach Wunsch. Hier standardmäßig Kontrastfarbe.
        foregroundColor: enabled ? Colors.black : null,
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
                  textStyle: textStyle,
                ),
                child: const Text('Restart'),
              ),
              const SizedBox(width: 24),

              // Moves Text
              Text(
                limit == null ? 'Moves: $used' : 'Moves: $used / $limit',
                style: textStyle,
              ),
            ],
          ),
        ),
      ),
    );
  }
}