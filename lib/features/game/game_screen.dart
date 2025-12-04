import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/level.dart';
import '../../data/levels/level_repository.dart';
import '../../domain/entities/board.dart';
import '../../domain/services/rules.dart';
import '../../domain/services/level_progress.dart'; // NEW: Service for saving level progress

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
  // Row 3, Col 3 corresponds to the 4th row and 4th column (0-indexed).
  static const bossExitRow = 3;
  static const bossExitCol = 3;

  @override
  void initState() {
    super.initState();
    _repo = LevelRepository();

    // Construct the asset path based on the level ID (e.g., level_001.json)
    _assetPath =
    'assets/levels/level_${widget.level.id.toString().padLeft(3, '0')}.json';

    // Start loading the board configuration asynchronously
    _boardFuture = _repo.load(_assetPath);
  }

  /// Shows the victory dialog when the level is solved.
  void _showWinDialog(int moves) {
    showDialog(
      context: context,
      builder: (_) => WinDialog(
        moves: moves,
        onNext: () {
          // Logic to navigate to the next level or return to map
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

  /// Helper function to format seconds into a MM:SS string.
  String _fmtTime(int? secs) {
    if (secs == null) return '--:--';
    final m = secs ~/ 60;
    final s = secs % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    // Wait for the level data (JSON) to be loaded and parsed into a Board object
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

        // Determine constraints based on the Level metadata (Move Limit vs Time Limit)
        final int? moveLimit = (widget.level.type == LevelType.moveLimit)
            ? widget.level.moveLimit
            : null;
        final int? timeLimit = (widget.level.type == LevelType.timeLimit)
            ? widget.level.timeLimit
            : null;

        // Check if this is a Boss Level to apply special win conditions
        final isBoss = widget.level.type == LevelType.boss;

        // Select the appropriate win condition function
        // Boss levels require the block to reach a specific exit coordinate.
        // Normal levels usually just require the target block to reach the edge.
        final winCheck = isBoss
            ? (Board b) =>
            Rules.isSolvedBoss(b, exitRow: bossExitRow, exitCol: bossExitCol)
            : Rules.isSolved;

        // Initialize the GameController for this specific level using ProviderScope.
        // This creates a scoped instance of the provider, ensuring state is reset
        // when entering a new level.
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

/// The internal scaffold that builds the UI (AppBar, HUD, Board).
/// It listens to the [gameControllerProvider] to react to state changes.
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
    // Watch current game state (e.g., solved, failed, moves count)
    final state = ref.watch(gameControllerProvider);
    // Read controller for actions (restart, etc.)
    final controller = ref.read(gameControllerProvider.notifier);

    // Handle side effects (Win/Loss Dialogs) after the frame renders.
    // This prevents triggering state changes during the build phase.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (state.solved) {
        // --- ACTION: Save Progress ---
        // Unlocks the next level in Shared Preferences
        LevelProgress.unlockLevel(level.id);

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
          // Display Move Limit if active
          if (state.moveLimit != null)
            Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text('🎯 ${state.movesUsed} / ${state.moveLimit}'),
                )),
          // Display Time Limit if active
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

          // HUD: Heads-up display for controls (Undo, Reset, etc.)
          GameHud(onRestart: () => controller.restart(initialBoard)),

          const SizedBox(height: 8),

          // Main Game Board Area
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