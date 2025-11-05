import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/level.dart';
import '../../data/levels/level_repository.dart';
import '../../domain/entities/board.dart';
import '../../domain/services/rules.dart';

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

  static const bossExitRow = 3; // 0-based (4th row)
  static const bossExitCol = 3; // 0-based (4th col)

  @override
  void initState() {
    super.initState();
    _repo = LevelRepository();
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Next level not wired yet.')),
          );
        },
      ),
    );
  }

  void _showFailDialog({
    required int moves,
    required VoidCallback onRestart,
    required FailReason reason,
  }) {
    final reasonText =
    reason == FailReason.timeUp ? "Time's up" : "Out of moves";
    showDialog(
      context: context,
      builder: (_) => FailDialog(
        title: reasonText,
        moves: moves,
        onRestart: onRestart,
        onExit: () => Navigator.of(context).maybePop(),
      ),
    );
  }

  String _fmtTime(int? secs) {
    if (secs == null) return '--:--';
    final m = secs ~/ 60;
    final s = secs % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
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

        // Decide limits + win condition based on Level metadata
        final int? moveLimit =
        (widget.level.type == LevelType.moveLimit) ? widget.level.moveLimit : null;
        final int? timeLimit =
        (widget.level.type == LevelType.timeLimit) ? widget.level.timeLimit : null;

        final isBoss = widget.level.type == LevelType.boss;
        final winCheck = isBoss
            ? (Board b) => Rules.isSolvedBoss(b, exitRow: bossExitRow, exitCol: bossExitCol)
            : Rules.isSolved;

        return ProviderScope(
          overrides: [
            gameControllerProvider.overrideWith(
                  (ref) => GameController(
                initialBoard,
                moveLimit: moveLimit,
                timeLimit: timeLimit,
                isWin: winCheck,
              ),
            ),
          ],
          child: _GameScaffold(
            level: widget.level,
            initialBoard: initialBoard,
            showWin: _showWinDialog,
            showFail: _showFailDialog,
            fmtTime: _fmtTime,
            isBoss: isBoss,
            bossExitRow: bossExitRow,
            bossExitCol: bossExitCol,
          ),
        );
      },
    );
  }
}

class _GameScaffold extends ConsumerWidget {
  final Level level;
  final Board initialBoard;
  final void Function(int moves) showWin;
  final void Function({
  required int moves,
  required VoidCallback onRestart,
  required FailReason reason,
  }) showFail;
  final String Function(int? secs) fmtTime;

  final bool isBoss;
  final int bossExitRow;
  final int bossExitCol;

  const _GameScaffold({
    required this.level,
    required this.initialBoard,
    required this.showWin,
    required this.showFail,
    required this.fmtTime,
    required this.isBoss,
    required this.bossExitRow,
    required this.bossExitCol,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameControllerProvider);
    final controller = ref.read(gameControllerProvider.notifier);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (state.solved) {
        showWin(state.history.length);
      } else if (state.failed && state.failReason != null) {
        showFail(
          moves: state.history.length,
          onRestart: () => controller.restart(initialBoard),
          reason: state.failReason!,
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text('Level ${level.id} • ${level.difficulty}'),
        actions: [
          if (state.moveLimit != null)
            Center(child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text('🎯 ${state.movesUsed} / ${state.moveLimit}'),
            )),
          if (state.timeLimit != null)
            Center(child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text('⏱ ${fmtTime(state.timeLeft)}'),
            )),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          GameHud(onRestart: () => controller.restart(initialBoard)),
          const SizedBox(height: 8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: BoardView(
                  bossMode: isBoss,
                  bossExitRow: bossExitRow,
                  bossExitCol: bossExitCol,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
