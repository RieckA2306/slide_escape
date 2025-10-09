import 'package:flutter/material.dart';

class FailDialog extends StatelessWidget {
  final String title;        // e.g., "Time's up" or "Out of moves"
  final int moves;           // moves used
  final VoidCallback onRestart;
  final VoidCallback? onExit;

  const FailDialog({
    super.key,
    required this.title,
    required this.moves,
    required this.onRestart,
    this.onExit,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Text('You used $moves moves. Try again!'),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            if (onExit != null) onExit!();
          },
          child: const Text('Exit'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop();
            onRestart();
          },
          child: const Text('Restart'),
        ),
      ],
    );
  }
}
