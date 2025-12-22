import 'package:flutter/material.dart';

class WinDialog extends StatelessWidget {
  final int moves;
  final VoidCallback onNext;

  // Parameter für Anpassbarkeit
  final Color backgroundColor;
  final double opacity;
  final Color buttonColor;
  final Color textColor;
  final double fontSize;

  const WinDialog({
    super.key,
    required this.moves,
    required this.onNext,
    this.backgroundColor = Colors.white, // Standardwert
    this.opacity = 1.0,                  // Standardwert
    this.buttonColor = Colors.blue,      // Standardwert
    this.textColor = Colors.black,       // Standardwert
    this.fontSize = 16.0,                // Standardwert
  });

  @override
  Widget build(BuildContext context) {
    // Basis-Style für den Text
    final textStyle = TextStyle(
      color: textColor,
      fontSize: fontSize,
    );

    return AlertDialog(
      // Farbe und Transparenz anwenden
      backgroundColor: backgroundColor.withValues(alpha: opacity),

      // Buttons zentrieren
      actionsAlignment: MainAxisAlignment.center,

      title: Text(
        'Level Complete!',
        textAlign: TextAlign.center,
        // Titel a bit bigger than the rest
        style: textStyle.copyWith(fontWeight: FontWeight.bold, fontSize: fontSize * 1.2),
      ),
      content: Text(
        'You solved it in $moves moves.',
        textAlign: TextAlign.center,
        style: textStyle,
      ),
      actions: [
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop();
            onNext();
          },
          style: FilledButton.styleFrom(
            backgroundColor: buttonColor,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: Text(
            'Next Level',
            // Schriftfarbe hier auf Schwarz gesetzt
            style: TextStyle(fontSize: fontSize, color: Colors.black),
          ),
        ),
      ],
    );
  }
}