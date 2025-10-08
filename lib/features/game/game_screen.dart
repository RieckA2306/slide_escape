import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/level.dart';
import '../../data/levels/level_repository.dart';
import '../../domain/entities/board.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'controller/game_controller.dart';
import 'widgets/board_view.dart';
import 'widgets/hud.dart';
import 'widgets/win_dialog.dart';

class GameScreen extends ConsumerStatefulWidget {
  final Level level;

  const GameScreen({super.key, required this.level});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  late final LevelRepository _repo;
  late Future<Board> _boardFuture;
  late String _assetPath;

  @override
  void initState() {
    super.initState();
    _repo = LevelRepository();
    // Map your Level.id -> asset file, e.g., "assets/levels/level_001.json"
    _assetPath =
    'assets/levels/level_${widget.level.id.toString().padLeft(3, '0')}.json';
    _boardFuture = _repo.load(_assetPath);
  }

  void _showWinDialog(int moves) {
    showDialog(
      context: context,
      builder: (_) => WinDialog(
        moves: moves,
        onNext: () {
          // TODO: wire to your level map flow (navigate to next Level)
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Next level not wired yet.')),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _boardFuture,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snap.hasError) {
          return Scaffold(
            body: Center(child: Text('Failed to load level: ${snap.error}')),
          );
        }
        final initialBoard = snap.data as Board;

        return ProviderScope(
          overrides: [
            gameControllerProvider.overrideWith((ref) => GameController(initialBoard)),
          ],
          child: _GameScaffold(
            level: widget.level,
            initialBoard: initialBoard,
            onWin: _showWinDialog,
          ),
        );
      },
    );
  }
}

class _GameScaffold extends ConsumerWidget {
  final Level level;
  final Board initialBoard;
  final void Function(int moves) onWin;

  const _GameScaffold({
    required this.level,
    required this.initialBoard,
    required this.onWin,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameControllerProvider);
    final controller = ref.read(gameControllerProvider.notifier);

    // Show win dialog when solved
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (state.solved) onWin(state.history.length);
    });

    return Scaffold(
      appBar: AppBar(
        title: Text("Level ${level.id} • ${level.difficulty}"),
        actions: [
          if (level.timeLimit != null)
            Center(child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text('⏱️ ${level.timeLimit}s'),
            )),
          if (level.moveLimit != null)
            Center(child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text('🎯 ${level.moveLimit}'),
            )),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          GameHud(
            onRestart: () => controller.restart(initialBoard),
          ),
          const SizedBox(height: 8),
          // The board expands and keeps a square layout
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: const BoardView(),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
