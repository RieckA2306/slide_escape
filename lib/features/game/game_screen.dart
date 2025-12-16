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

/// The main screen where the gameplay happens.
///
/// Responsibilities:
/// 1. Load level data (JSON) asynchronously.
/// 2. Initialize the GameController with specific level constraints.
/// 3. Wire up the UI (Board, HUD) with the State.
/// 4. Listen for Game Events (Win/Loss) to show dialogs.
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

  // Constants defining the exit point for the 'Boss' block (Target block).
  static const bossExitRow = 3;
  static const bossExitCol = 3;

  @override
  void initState() {
    super.initState();
    _repo = LevelRepository();

    // Construct the asset path dynamically based on the level ID.
    // E.g., ID 5 becomes "assets/levels/level_005.json"
    _assetPath =
    'assets/levels/level_${widget.level.id.toString().padLeft(3, '0')}.json';

    // Start loading the board immediately when the screen opens.
    // We store the Future to use it in the FutureBuilder later.
    _boardFuture = _repo.load(_assetPath);
  }

  /// Displays the "You Won" dialog.
  void _showWinDialog(int moves) {
    // SAFETY CHECK: Before showing a dialog, check if the widget is still on screen.
    // Since we have an async delay (await Future.delayed), the user might have
    // pressed "Back" in the meantime. Trying to show a dialog on a closed screen causes a crash.
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false, // User must click a button to close
      builder: (_) => WinDialog(
        moves: moves,
        onNext: () {
          // Close the dialog and go back to the map
          Navigator.of(context).pop();
        },
      ),
    );
  }

  /// Displays the "Game Over" dialog.
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

  /// Helper to format seconds into MM:SS (e.g., 65s -> "01:05").
  String _fmtTime(int? secs) {
    if (secs == null) return '--:--';
    final m = secs ~/ 60;
    final s = secs % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    // FutureBuilder handles the 3 states of data loading:
    // 1. Loading (Spinner)
    // 2. Error (Text)
    // 3. Success (The actual Game)
    return FutureBuilder<Board>(
      future: _boardFuture,
      builder: (context, snap) {
        // State 1: Loading
        if (snap.connectionState != ConnectionState.done) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }

        // State 2: Error
        if (snap.hasError) {
          return Scaffold(
            appBar: AppBar(title: Text('Level ${widget.level.id}')),
            body: Center(child: Text('Failed to load level: ${snap.error}')),
          );
        }

        // State 3: Success - Data is ready to use
        final initialBoard = snap.data!;

        // Determine limits based on level type
        final int? moveLimit = (widget.level.type == LevelType.moveLimit)
            ? widget.level.moveLimit
            : null;
        final int? timeLimit = (widget.level.type == LevelType.timeLimit)
            ? widget.level.timeLimit
            : null;

        final isBoss = widget.level.type == LevelType.boss;

        // Define the victory condition (Normal vs. Boss)
        final winCheck = isBoss
            ? (Board b) =>
            Rules.isSolvedBoss(b, exitRow: bossExitRow, exitCol: bossExitCol)
            : Rules.isSolved;

        // CRITICAL RIVERPOD PATTERN:
        // We wrap the game UI in a ProviderScope.
        // This allows us to "Override" the generic gameControllerProvider with
        // a specific instance that knows about THIS level's board and rules.
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

/// The internal UI structure.
/// Separated into its own widget so it can access the overridden ProviderScope above.
class _GameScaffold extends ConsumerWidget {
  final Level level;
  final Board initialBoard;

  // Callbacks passed down from the parent to keep logic clean
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
    // Watch for UI updates (rebuilds the widget when state changes)
    final state = ref.watch(gameControllerProvider);
    // Read the controller to call methods (like restart)
    final controller = ref.read(gameControllerProvider.notifier);

    // EVENT LISTENER:
    // 'ref.listen' is used for one-time effects (side effects) like showing dialogs.
    // It does NOT rebuild the UI, it just triggers the code block when state changes.
    ref.listen<GameState>(gameControllerProvider, (previous, next) async {

      // 1. Check Win Condition: Was not solved before, but is solved now?
      if (!(previous?.solved ?? false) && next.solved) {

        // Persistence: Save progress immediately
        LevelProgress.unlockLevel(level.id);

        // UX DELAY: Wait 250ms so the user sees the block hitting the goal
        // before the dialog covers the screen.
        await Future.delayed(const Duration(milliseconds: 250));

        showWin(next.history.length);
      }

      // 2. Check Fail Condition: Was not failed before, but is failed now?
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
          // Show Move Counter if limit exists
          if (state.moveLimit != null)
            Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text('🎯 ${state.movesUsed} / ${state.moveLimit}'),
                )),
          // Show Timer if limit exists
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

          // HUD: Contains Undo/Redo/Restart buttons
          GameHud(onRestart: () => controller.restart(initialBoard)),

          const SizedBox(height: 8),

          // THE BOARD: The main interactive area
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