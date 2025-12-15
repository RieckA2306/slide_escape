import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/level.dart';
import '../../data/levels/level_repository.dart';
import '../../domain/entities/board.dart';
import '../../domain/services/rules.dart';
import '../../data/levels/level_progress.dart';

import 'controller/game_controller.dart';
import 'widgets/board_view.dart';
import 'widgets/hud.dart';
import 'widgets/win_dialog.dart';
import 'widgets/fail_dialog.dart';

/// The main screen for playing a level.
/// It handles loading the level data, setting up the game controller,
/// and displaying the UI (Board, HUD, Dialogs).
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

  // Constants defining the exit point for the 'Boss' block.
  static const bossExitRow = 3;
  static const bossExitCol = 3;

  @override
  void initState() {
    super.initState();
    _repo = LevelRepository();

    // Construct the asset path based on the level ID
    _assetPath =
    'assets/levels/level_${widget.level.id.toString().padLeft(3, '0')}.json';

    _boardFuture = _repo.load(_assetPath);
  }

  /// Shows the victory dialog when the level is solved.
  void _showWinDialog(int moves) {
    // SAFETY CHECK: Ensure the widget is still on screen before showing the dialog.
    // This is important because of the 0.2s delay.
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false, // Prevent closing by clicking outside
      builder: (_) => WinDialog(
        moves: moves,
        onNext: () {
          Navigator.of(context).pop();
        },
      ),
    );
  }

  /// Shows the failure dialog when the player runs out of moves or time.
  void _showFailDialog({
    required int moves,
    required VoidCallback onRestart,
    required FailReason reason,
  }) {
    if (!mounted) return;

    final reasonText =
    reason == FailReason.timeUp ? "Time's up" : "Out of moves";
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => FailDialog(
        title: reasonText,
        moves: moves,
        onRestart: onRestart,
        onExit: () => Navigator.of(context).maybePop(),
      ),
    );
  }

  /// Helper function to format seconds into a MM:SS string.
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
        // 1. Loading State
        if (snap.connectionState != ConnectionState.done) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }

        // 2. Error State
        if (snap.hasError) {
          return Scaffold(
            appBar: AppBar(title: Text('Level ${widget.level.id}')),
            body: Center(child: Text('Failed to load level: ${snap.error}')),
          );
        }

        // 3. Success State: Data is ready
        final initialBoard = snap.data!;

        final int? moveLimit = (widget.level.type == LevelType.moveLimit)
            ? widget.level.moveLimit
            : null;
        final int? timeLimit = (widget.level.type == LevelType.timeLimit)
            ? widget.level.timeLimit
            : null;

        final isBoss = widget.level.type == LevelType.boss;

        final winCheck = isBoss
            ? (Board b) =>
            Rules.isSolvedBoss(b, exitRow: bossExitRow, exitCol: bossExitCol)
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

/// The internal scaffold that builds the UI.
/// Optimized to react immediately to state changes using ref.listen.
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

    // We make the callback 'async' to use 'await Future.delayed'
    ref.listen<GameState>(gameControllerProvider, (previous, next) async {
      // 1. Check Win Condition
      if (!(previous?.solved ?? false) && next.solved) {

        // Save in background immediately
        LevelProgress.unlockLevel(level.id);

        // ADDED DELAY: Wait 0.2 seconds (200ms) for better UX
        await Future.delayed(const Duration(milliseconds: 300));

        // Show dialog after the short pause
        showWin(next.history.length);
      }
      // 2. Check Fail Condition
      else if (!(previous?.failed ?? false) && next.failed && next.failReason != null) {
        showFail(
          moves: next.history.length,
          onRestart: () => controller.restart(initialBoard),
          reason: next.failReason!,
        );
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
                )),
          if (state.timeLimit != null)
            Center(
                child: Padding(
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