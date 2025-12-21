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
import 'widgets/exit_dialog.dart';

/// The main screen where the gameplay happens.
///
/// This widget acts as the "orchestrator" for a single game session.
///
/// Responsibilities:
/// 1. Data Loading: Fetches the level configuration (JSON) asynchronously.
/// 2. Dependency Injection: Initializes the [GameController] with the loaded board and level rules.
/// 3. UI Composition: Builds the visual hierarchy (Background, AppBar, HUD, Game Board).
/// 4. Event Listening: Monitors the game state for Win/Loss conditions to trigger dialogs.
class GameScreen extends ConsumerStatefulWidget {
  /// The level metadata (ID, difficulty, type) passed from the map screen.
  final Level level;

  const GameScreen({super.key, required this.level});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  late final LevelRepository _repo;

  /// A Future that will hold the initial state of the game board.
  late Future<Board> _boardFuture;

  late String _assetPath;

  // Constants defining the exit point for the 'Boss' block (Target block).
  // In Boss levels, the target might need to reach a specific cell (e.g., row 3, col 3).
  static const bossExitRow = 3;
  static const bossExitCol = 3;

  /// NEW: State variable to control navigation behavior.
  /// If true, the PopScope will allow the screen to close immediately.
  /// If false, the PopScope will block the exit and show the ExitDialog instead.
  bool _forceExit = false;

  @override
  void initState() {
    super.initState();
    _repo = LevelRepository();

    // Construct the asset path dynamically based on the level ID.
    // Example: ID 5 becomes "assets/levels/level_005.json"
    _assetPath =
    'assets/levels/level_${widget.level.id.toString().padLeft(3, '0')}.json';

    // Start loading the board immediately when the screen opens.
    // We store the Future to use it in the FutureBuilder later.
    _boardFuture = _repo.load(_assetPath);
  }

  /// Displays the "You Won" dialog overlay.
  void _showWinDialog(int moves) {
    // SAFETY CHECK: Before showing a dialog, check if the widget is still mounted (on screen).
    // Since we have an async delay (await Future.delayed) before calling this, the user might
    // have pressed "Back" in the meantime. Trying to show a dialog on a closed screen causes a crash.
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false, // Prevents closing by clicking outside the dialog.
      builder: (_) => WinDialog(
        moves: moves,
        // BG color
        backgroundColor: Colors.white,
        opacity: 0.9,
        fontSize: 18.0,
        textColor: const Color(0xFF333333),
        buttonColor: const Color(0xFFF1CCE6),

        onNext: () {
          // Close the dialog and navigate back to the level map.
          Navigator.of(context).pop();
        },
      ),
    );
  }

  /// Displays the "Game Over" dialog overlay.
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
        // Same Style as WinDialog
        backgroundColor: Colors.white,
        opacity: 0.9,
        fontSize: 18.0,
        textColor: const Color(0xFF333333),
        buttonColor: const Color(0xFFF1CCE6),

        onExit: () async {
          // NEW: Handle the specific exit case from the FailDialog.
          // The FailDialog itself is already popped inside its own onPressed method.

          // 1. Update state to allow the PopScope to pass through.
          setState(() {
            _forceExit = true;
          });

          // 2. Wait a brief moment to ensure the state update propagates to the widget tree.
          await Future.delayed(Duration.zero);

          if (!mounted) return;

          // 3. Close the GameScreen. Since _forceExit is true, PopScope allows this.
          Navigator.of(context).pop();
        },
      ),
    );
  }

  /// NEU: Displays the Exit Confirmation Dialog
  void _showExitDialog() {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => ExitDialog(
        // Styles wie bei den anderen Dialogen
        backgroundColor: Colors.white,
        opacity: 0.9,
        fontSize: 18.0,
        textColor: const Color(0xFF333333),
        buttonColor: const Color(0xFFF1CCE6),

        onKeepPlaying: () {
          // Leer lassen! Der Dialog schließt sich bereits selbst.
        },
        onExit: () {
          // Nur 1x pop, um den GameScreen zu schließen.
          // NEW: Also allow force exit here to avoid loop if triggered manually
          setState(() {
            _forceExit = true;
          });
          Navigator.of(context).pop();
        },
      ),
    );
  }

  /// Helper function to format seconds into a "MM:SS" string.
  /// Example: 65 seconds -> "01:05".
  String _fmtTime(int? secs) {
    if (secs == null) return '--:--';
    final m = secs ~/ 60;
    final s = secs % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    // FutureBuilder handles the 3 states of asynchronous data loading:
    // 1. Loading (Waiting for JSON) -> Shows Spinner
    // 2. Error (File not found / Invalid JSON) -> Shows Error Text
    // 3. Success (Data ready) -> Builds the Game UI
    return FutureBuilder<Board>(
      future: _boardFuture,
      builder: (context, snap) {
        // State 1: Loading
        if (snap.connectionState != ConnectionState.done) {
          // We use a Scaffold here to ensure the spinner is shown on a proper background.
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

        // State 3: Success - Data is available
        final initialBoard = snap.data!;

        // Determine specific level constraints based on the LevelType.
        final int? moveLimit = (widget.level.type == LevelType.moveLimit)
            ? widget.level.moveLimit
            : null;
        final int? timeLimit = (widget.level.type == LevelType.timeLimit)
            ? widget.level.timeLimit
            : null;

        final isBoss = widget.level.type == LevelType.boss;

        // Define the victory condition dynamically.
        // - Normal levels: Standard "Target reaches exit" logic.
        // - Boss levels: Custom "Boss reaches specific cell" logic.
        final winCheck = isBoss
            ? (Board b) => Rules.isSolvedBoss(b,
            exitRow: bossExitRow, exitCol: bossExitCol)
            : Rules.isSolved;

        // CRITICAL RIVERPOD PATTERN:
        // We wrap the game UI in a ProviderScope.
        // This allows us to "Override" the generic [gameControllerProvider] with
        // a specific instance that knows about THIS level's loaded board and rules.
        // This is dependency injection in action.
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
            onExitRequest: _showExitDialog,
            fmtTime: _fmtTime,
            isBoss: isBoss,
            bossExitRow: bossExitRow,
            bossExitCol: bossExitCol,
            // NEW: Pass the permission to pop to the UI widget
            allowPop: _forceExit,
          ),
        );
      },
    );
  }
}

/// The internal UI structure of the game.
///
/// It is separated into its own widget so it can access the [gameControllerProvider]
/// that was overridden in the parent [ProviderScope].
class _GameScaffold extends ConsumerWidget {
  final Level level;
  final Board initialBoard;

  // Callbacks passed down from the parent to separate logic from UI building.
  final void Function(int moves) showWin;
  final void Function({
  required int moves,
  required VoidCallback onRestart,
  required FailReason reason,
  }) showFail;

  // Callback if Exit is pressed
  final VoidCallback onExitRequest;

  final String Function(int? secs) fmtTime;

  final bool isBoss;
  final int bossExitRow;
  final int bossExitCol;

  // NEW: Received from parent state
  final bool allowPop;

  const _GameScaffold({
    required this.level,
    required this.initialBoard,
    required this.showWin,
    required this.showFail,
    required this.onExitRequest,
    required this.fmtTime,
    required this.isBoss,
    required this.bossExitRow,
    required this.bossExitCol,
    required this.allowPop,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch for UI updates: Rebuilds this widget whenever the game state changes (e.g., move made).
    final state = ref.watch(gameControllerProvider);
    // Read the controller: Used to trigger actions (like restart) without watching state.
    final controller = ref.read(gameControllerProvider.notifier);

    // --- ANPASSBARE HEADER-EINSTELLUNGEN ---
    const double headerIconSize = 32.0;      // Größe der Bilder (Dartboard & Uhr)
    const double headerFontSize = 18.0;      // Schriftgröße für Züge & Zeit
    const FontWeight headerFontWeight = FontWeight.bold; // Fettschrift
    const double iconTextSpacing = 6.0;      // Abstand zwischen Bild und Text
    const double itemPadding = 12.0;         // Abstand zwischen den Elementen im Header
    // ---------------------------------------

    // EVENT LISTENER:
    // 'ref.listen' is used for side effects. It does NOT rebuild the UI.
    ref.listen<GameState>(gameControllerProvider, (previous, next) async {
      if (!(previous?.solved ?? false) && next.solved) {
        LevelProgress.unlockLevel(level.id);
        await Future.delayed(const Duration(milliseconds: 100));
        showWin(next.history.length);
      } else if (!(previous?.failed ?? false) &&
          next.failed &&
          next.failReason != null) {
        showFail(
          moves: next.history.length,
          onRestart: () => controller.restart(initialBoard),
          reason: next.failReason!,
        );
      }
    });

    return PopScope(
      canPop: allowPop,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        onExitRequest();
      },
      child: Stack(
        children: [
          // LAYER 0: The Background Image
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/game_background/game_background.png"),
                fit: BoxFit.cover,
              ),
            ),
          ),

          // LAYER 1: The Game Interface
          Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              backgroundColor: Colors.white.withValues(alpha: 0.5),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: onExitRequest,
              ),
              title: Text('Level ${level.id} • ${level.difficulty}'),
              actions: [
                // Show Move Counter (Dart Board Image + Text)
                if (state.moveLimit != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: itemPadding),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          "assets/game_header/dart_board.png",
                          width: headerIconSize,
                          height: headerIconSize,
                        ),
                        SizedBox(width: iconTextSpacing),
                        Text(
                          '${state.movesUsed} / ${state.moveLimit}',
                          style: const TextStyle(
                            fontSize: headerFontSize,
                            fontWeight: headerFontWeight,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Show Timer (Clock Image + Text)
                if (state.timeLimit != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: itemPadding),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          "assets/game_header/time_clock.png",
                          width: headerIconSize,
                          height: headerIconSize,
                        ),
                        SizedBox(width: iconTextSpacing),
                        Text(
                          fmtTime(state.timeLeft),
                          style: const TextStyle(
                            fontSize: headerFontSize,
                            fontWeight: headerFontWeight,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            body: Column(
              children: [
                const SizedBox(height: 8),

                // HUD: Contains Undo/Redo/Restart buttons
                GameHud(
                  onRestart: () => controller.restart(initialBoard),
                  buttonColor: const Color(0xFFF1CCE6),
                  activeUndoRedoColor: const Color(0xFFF1CCE6),
                  textColor: const Color(0xFF333333),
                  buttonTextColor: Colors.black,
                  fontSize: 17.0,
                  movesFontSize: 19.0,
                  fontWeight: FontWeight.bold,
                  verticalOffset: 14.0,
                  undoRedoWidth: 100.0,
                  undoRedoHeight: 45.0,
                  restartWidth: 160.0,
                  restartHeight: 45.0,
                ),

                const SizedBox(height: 8),

                // THE BOARD
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: BoardView(
                        bossMode: isBoss,
                        bossExitRow: bossExitRow,
                        bossExitCol: bossExitCol,
                        verticalAlignment: -0.30,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }
}