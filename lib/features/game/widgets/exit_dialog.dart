import 'package:flutter/material.dart';

class ExitDialog extends StatelessWidget {
  final VoidCallback onKeepPlaying;
  final VoidCallback onExit;

  // Anpassungs-Parameter (identisch zu Win/Fail Dialog)
  final Color backgroundColor;
  final double opacity;
  final Color buttonColor;
  final Color textColor;
  final double fontSize;

  const ExitDialog({
    super.key,
    required this.onKeepPlaying,
    required this.onExit,
    // Standardwerte
    this.backgroundColor = Colors.white,
    this.opacity = 1.0,
    this.buttonColor = Colors.blue,
    this.textColor = Colors.black,
    this.fontSize = 16.0,
  });

  @override
  Widget build(BuildContext context) {
    // Basis-Style für den Text
    final textStyle = TextStyle(
      color: textColor,
      fontSize: fontSize,
    );

    return AlertDialog(
      // Hintergrund und Transparenz
      backgroundColor: backgroundColor.withValues(alpha: opacity),

      // Aktionen zentrieren
      actionsAlignment: MainAxisAlignment.center,

      title: Text(
        'Exit Level',
        textAlign: TextAlign.center,
        style: textStyle.copyWith(fontWeight: FontWeight.bold, fontSize: fontSize * 1.2),
      ),
      content: Text(
        'Are you sure that you want to exit this level?',
        textAlign: TextAlign.center,
        style: textStyle,
      ),
      actions: [
        // Button 1: Keep Playing (Text Button)
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(); // Schließt nur den Dialog
            onKeepPlaying();
          },
          child: Text(
            'Keep Playing',
            style: textStyle, // Deine Textfarbe (333333)
          ),
        ),

        // Button 2: Exit (Hervorgehoben in Pink)
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop(); // Schließt Dialog
            onExit(); // Führt Exit aus
          },
          style: FilledButton.styleFrom(
            backgroundColor: buttonColor,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: Text(
            'Exit',
            // Schriftfarbe hier auf Schwarz gesetzt
            style: TextStyle(fontSize: fontSize, color: Colors.black),
          ),
        ),
      ],
    );
  }
}