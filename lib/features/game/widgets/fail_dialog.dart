import 'package:flutter/material.dart';

class FailDialog extends StatelessWidget {
  final String title;        // e.g., "Time's up" or "Out of moves"
  final int moves;           // moves used
  final VoidCallback onExit; // Nur noch Exit Callback

  // Anpassungs-Parameter (wie beim WinDialog)
  final Color backgroundColor;
  final double opacity;
  final Color buttonColor;
  final Color textColor;
  final double fontSize;

  const FailDialog({
    super.key,
    required this.title,
    required this.moves,
    required this.onExit,
    // Standardwerte setzen
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
        title,
        textAlign: TextAlign.center, // Zentriert
        style: textStyle.copyWith(fontWeight: FontWeight.bold, fontSize: fontSize * 1.2),
      ),
      content: Text(
        'You used $moves moves. Try again!',
        textAlign: TextAlign.center, // Zentriert
        style: textStyle,
      ),
      actions: [
        // Nur noch der Exit Button als FilledButton (wie gewünscht)
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop();
            onExit();
          },
          style: FilledButton.styleFrom(
            backgroundColor: buttonColor,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: Text(
            'Exit',
            style: TextStyle(fontSize: fontSize),
          ),
        ),
      ],
    );
  }
}