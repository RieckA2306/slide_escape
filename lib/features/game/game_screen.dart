import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/level.dart';
import '../../data/levels/level_repository.dart';
import '../../domain/entities/board.dart';

import 'controller/game_controller.dart';
import 'widgets/board_view.dart';
import 'widgets/hud.dart';
import 'widgets/win_dialog.dart';
import 'widgets/fail_dialog.dart';

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
    // Map Level.id -> asset: assets/levels/level_XXX.json
    _assetPath = 'assets/levels/level_${widget.level.id.toString().padLeft(3, '0')}.json';
    _boardFuture = _repo.load(_assetPath);
  }

  void _showWinDialog(int moves) {
    showDialog(
      context: context,
      builder: (_) => WinDialog(
        moves: moves,
        onNext: () {
          // TODO: wire this to your level select / next level navigation
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Next level not wired yet.')),
          );
        },
      ),
    );
  }

  void _showFailDialog(int moves, void Function() onRestart) {
    showDialog(
      context: context,
      builder: (_) => FailDialog(
        moves: moves,
        onRestart: onRestart,
        onExit: () => Navigator.of(context).maybePop(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Board>(
      future: _boardFuture,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snap.hasError) {
          return Scaffold(
            appBar: AppBar(title: Text('Level ${widget.level.id}')),
            body: Center(child: Text('Failed to load level: ${snap.error}')),
          );
        }

        final initialBoard = snap.data!;

        // Decide move limit from Level metadata:
        // If Level.type == moveLimit and a moveLimit is provided, we enforce it.
        final int? moveLimit = (widget.level.type == LevelType.moveLimit)
            ? widget.level.moveLimit
            : null;

        return ProviderScope(
          overrides: [
            gameControllerProvider.overrideWith(
                  (ref) => GameController(initialBoard, moveLimit: moveLimit),
            ),
          ],
          child: _GameScaffold(
            level: widget.level,
            initialBoard: initialBoard,
            onWin: _showWinDialog,
            onFail: _showFailDialog,
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
  final void Function(int moves, void Function() onRestart) onFail;

  const _GameScaffold({
    required this.level,
    required this.initialBoard,
    required this.onWin,
    required this.onFail,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameControllerProvider);
    final controller = ref.read(gameControllerProvider.notifier);

    // Show win/fail dialog once state flips.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (state.solved) {
        onWin(state.history.length);
      } else if (state.failed) {
        onFail(state.history.length, () => controller.restart(initialBoard));
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text('Level ${level.id} • ${level.difficulty}'),
        actions: [
          if (state.moveLimit != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text('🎯 ${state.movesUsed} / ${state.moveLimit}'),
              ),
            ),
          if (level.timeLimit != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text('⏱️ ${level.timeLimit}s'),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          GameHud(
            onRestart: () => controller.restart(initialBoard),
          ),
          const SizedBox(height: 8),
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
