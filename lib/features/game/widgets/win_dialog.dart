import 'package:flutter/material.dart';

class WinDialog extends StatelessWidget {
  final int moves;
  final VoidCallback onNext;

  const WinDialog({super.key, required this.moves, required this.onNext});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Level Complete!'),
      content: Text('You solved it in $moves moves.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop();
            onNext();
          },
          child: const Text('Next Level'),
        ),
      ],
    );
  }
}
