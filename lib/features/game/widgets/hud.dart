import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controller/game_controller.dart';

class GameHud extends ConsumerWidget {
  final VoidCallback onRestart;

  const GameHud({super.key, required this.onRestart});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameControllerProvider);
    final controller = ref.read(gameControllerProvider.notifier);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        FilledButton.tonal(
          onPressed: state.history.isEmpty ? null : controller.undo,
          child: const Text('Undo'),
        ),
        const SizedBox(width: 12),
        FilledButton.tonal(
          onPressed: state.future.isEmpty ? null : controller.redo,
          child: const Text('Redo'),
        ),
        const SizedBox(width: 12),
        FilledButton(
          onPressed: onRestart,
          child: const Text('Restart'),
        ),
        const SizedBox(width: 24),
        Text('Moves: ${state.history.length}'),
      ],
    );
  }
}
