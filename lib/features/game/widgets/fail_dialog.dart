import 'package:flutter/material.dart';

class FailDialog extends StatelessWidget {
  final int moves;
  final VoidCallback onRestart;
  final VoidCallback? onExit;

  const FailDialog({
    super.key,
    required this.moves,
    required this.onRestart,
    this.onExit,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Out of moves'),
      content: Text('You used $moves moves. The limit is reached.'),
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
