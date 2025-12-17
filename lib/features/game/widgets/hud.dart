import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controller/game_controller.dart';

class GameHud extends ConsumerWidget {
  final VoidCallback onRestart;

  // Farben
  final Color buttonColor;
  final Color activeUndoRedoColor;
  final Color textColor;
  final Color buttonTextColor;

  // Schriftgrößen
  final double fontSize;
  final double movesFontSize;
  final FontWeight fontWeight;

  // Layout & Dimensionen
  final double verticalOffset;
  final double movesRightPadding; // NEU: Abstand von rechts

  // Button Dimensionen (null = automatisch)
  final double? undoRedoWidth;
  final double? undoRedoHeight;
  final double? restartWidth;
  final double? restartHeight;

  const GameHud({
    super.key,
    required this.onRestart,
    this.buttonColor = Colors.blue,
    this.activeUndoRedoColor = Colors.blue,
    this.textColor = Colors.black87,
    this.buttonTextColor = Colors.black,
    this.fontSize = 16.0,
    this.movesFontSize = 16.0,
    this.fontWeight = FontWeight.normal,
    this.verticalOffset = 0.0,
    this.movesRightPadding = 0.0, // Standardwert
    // Button Dimensionen
    this.undoRedoWidth,
    this.undoRedoHeight,
    this.restartWidth,
    this.restartHeight,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameControllerProvider);
    final controller = ref.read(gameControllerProvider.notifier);

    final used = state.movesUsed;
    final limit = state.moveLimit;

    // Style für Text innerhalb der Buttons
    final buttonTextStyle = TextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: buttonTextColor,
    );

    // Style für die Moves-Anzeige
    final movesTextStyle = TextStyle(
      fontSize: movesFontSize,
      fontWeight: fontWeight,
      color: textColor,
    );

    // Style-Funktion für Undo/Redo
    ButtonStyle undoRedoStyle(bool enabled) {
      return FilledButton.styleFrom(
        textStyle: buttonTextStyle,
        backgroundColor: enabled ? activeUndoRedoColor : null,
        foregroundColor: enabled ? buttonTextColor : null,
        padding: (undoRedoWidth != null) ? EdgeInsets.zero : null,
      );
    }

    final canUndo = state.history.isNotEmpty && !state.failed;
    final canRedo = state.future.isNotEmpty && !state.failed;

    return Transform.translate(
      offset: Offset(0, verticalOffset),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ZEILE 1: Buttons (Zentriert)
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Undo Button
                  SizedBox(
                    width: undoRedoWidth,
                    height: undoRedoHeight,
                    child: FilledButton.tonal(
                      onPressed: canUndo ? controller.undo : null,
                      style: undoRedoStyle(canUndo),
                      child: const Text('Undo'),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Redo Button
                  SizedBox(
                    width: undoRedoWidth,
                    height: undoRedoHeight,
                    child: FilledButton.tonal(
                      onPressed: canRedo ? controller.redo : null,
                      style: undoRedoStyle(canRedo),
                      child: const Text('Redo'),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Restart Button
                  SizedBox(
                    width: restartWidth,
                    height: restartHeight,
                    child: FilledButton(
                      onPressed: onRestart,
                      style: FilledButton.styleFrom(
                        backgroundColor: buttonColor,
                        foregroundColor: buttonTextColor,
                        textStyle: buttonTextStyle,
                        padding: (restartWidth != null) ? EdgeInsets.zero : null,
                      ),
                      child: const Text('Restart'),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // ZEILE 2: Moves Text (Rechtsbündig mit Padding)
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: EdgeInsets.only(right: movesRightPadding), // HIER IST DEIN ABSTAND
                child: Text(
                  limit == null ? 'Moves: $used' : 'Moves: $used / $limit',
                  style: movesTextStyle,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}