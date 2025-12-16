import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/board.dart';
import '../../../domain/entities/block.dart';
import '../../../domain/entities/move.dart';
import '../../../domain/services/rules.dart';

/// Defines why a level was failed.
enum FailReason {
  /// The player used more moves than allowed.
  movesExceeded,
  /// The time ran out (for time-limit levels).
  timeUp
}

/// A custom function type to check if the board is solved.
/// Default is checking if the target block reached the exit, but bosses might have different rules.
typedef WinCheck = bool Function(Board);

// ================= GAME STATE =================

/// Holds the immutable state of the current game session.
/// "Immutable" means fields cannot be changed. We create a new GameState object for every change.
class GameState {
  /// The current arrangement of blocks on the grid.
  final Board board;

  /// Stack of past moves (allows Undo).
  final List<Move> history;

  /// Stack of undone moves (allows Redo).
  final List<Move> future;

  /// True if the level is successfully completed.
  final bool solved;

  // --- Level Constraints ---
  final int? moveLimit; // Null means no limit
  final int? timeLimit; // Null means no limit
  final int? timeLeft;  // Seconds remaining (if timeLimit is set)

  // --- Failure State ---
  final bool failed;
  final FailReason? failReason;

  const GameState({
    required this.board,
    this.history = const [],
    this.future = const [],
    this.solved = false,
    this.moveLimit,
    this.timeLimit,
    this.timeLeft,
    this.failed = false,
    this.failReason,
  });

  /// Helper: Returns the number of moves currently made.
  int get movesUsed => history.length;

  /// Helper: Returns moves remaining or null if infinite. Clamped to 0 to avoid negative numbers.
  int? get movesLeft =>
      moveLimit == null ? null : (moveLimit! - movesUsed).clamp(0, moveLimit!);

  /// Creates a copy of this state with updated fields.
  /// This is crucial for Riverpod to detect changes and rebuild the UI.
  GameState copy({
    Board? board,
    List<Move>? history,
    List<Move>? future,
    bool? solved,
    int? moveLimit,
    int? timeLimit,
    int? timeLeft,
    bool? failed,
    FailReason? failReason,
  }) {
    return GameState(
      board: board ?? this.board,
      history: history ?? this.history,
      future: future ?? this.future,
      solved: solved ?? this.solved,
      moveLimit: moveLimit ?? this.moveLimit,
      timeLimit: timeLimit ?? this.timeLimit,
      timeLeft: timeLeft ?? this.timeLeft,
      failed: failed ?? this.failed,
      failReason: failReason ?? this.failReason,
    );
  }
}

// ================= GAME CONTROLLER =================

/// Manages the game logic, handles user input, and updates the state.
class GameController extends StateNotifier<GameState> {
  final WinCheck _isWin;       // The logic to determine if the player won.
  Timer? _timer;               // Handles the countdown.
  bool _timerRunning = false;  // Prevents multiple timers from starting.

  GameController(
      Board initial, {
        int? moveLimit,
        int? timeLimit,  // in seconds
        WinCheck? isWin, // Optional: inject custom win logic (e.g., for Boss levels)
      })  : _isWin = isWin ?? Rules.isSolved, // Use standard rules if no custom logic provided
        super(
        // Set initial state
        GameState(
          board: initial,
          solved: (isWin ?? Rules.isSolved)(initial), // Check if it's already solved
          moveLimit: moveLimit,
          timeLimit: timeLimit,
          timeLeft: timeLimit,
        ),
      ) {
    // Start the countdown immediately if a time limit exists
    _startTimerIfNeeded();
  }

  /// Shortcut to access the current board.
  Board get board => state.board;

  /// Calculates how far a specific block can be dragged in its orientation.
  /// Used by the UI to constrain the drag gesture.
  ({int minRow, int maxRow, int minCol, int maxCol}) boundsFor(Block b) =>
      Rules.dragBounds(board, b);

  /// Attempts to move a block to a new position.
  /// This is the CORE function of the gameplay loop.
  void tryMove(Block b, {required int toRow, required int toCol}) {
    // 1. Guard Clause: Don't allow moves if game is over.
    if (state.solved || state.failed) return;

    // 2. Rule Check: Is the target position valid and empty?
    if (!Rules.canPlace(board, b, toRow, toCol)) return;

    // 3. Apply Logic: Create a new board with the moved block.
    final movedBoard = board.applyMove(b.id, toRow, toCol);

    // 4. Record History: Create a move object for Undo functionality.
    final mv = Move(
      blockId: b.id, fromRow: b.row, fromCol: b.col, toRow: toRow, toCol: toCol,
    );
    final newHistory = [...state.history, mv];

    // 5. Check Limits: Did we exceed the move limit?
    bool nowFailed = state.failed;
    FailReason? reason = state.failReason;
    if (state.moveLimit != null && newHistory.length > state.moveLimit!) {
      nowFailed = true;
      reason = FailReason.movesExceeded;
    }

    // 6. Check Victory: Did this move solve the puzzle?
    final nowSolved = _isWin(movedBoard);

    // 7. Update State: This triggers the UI rebuild.
    // Note: 'future' is cleared because we branched off the history.
    state = state.copy(
      board: movedBoard,
      history: newHistory,
      future: const [],
      solved: nowSolved,
      failed: nowFailed,
      failReason: reason,
    );

    // Stop the timer if the game ended.
    if (state.solved || state.failed) _stopTimer();
  }

  /// Reverts the last move.
  void undo() {
    // Cannot undo if history is empty or game is lost.
    if (state.history.isEmpty || state.failed) return;

    final last = state.history.last;

    // Calculate the previous board state.
    final newBoard = board.applyMove(last.blockId, last.fromRow, last.fromCol);

    // Update State:
    // - Remove last move from history
    // - Add it to future (so we can Redo)
    state = state.copy(
      board: newBoard,
      history: [...state.history]..removeLast(),
      future: [last, ...state.future],
      solved: _isWin(newBoard), // Re-check win condition (usually false after undo)
    );
  }

  /// Re-applies a previously undone move.
  void redo() {
    // Cannot redo if there is no future or game is lost.
    if (state.future.isEmpty || state.failed) return;

    final next = state.future.first;

    // Apply the move again.
    final newBoard = board.applyMove(next.blockId, next.toRow, next.toCol);
    final newHistory = [...state.history, next];

    // Check move limit again (in case redo pushes us over the limit).
    bool nowFailed = state.failed;
    FailReason? reason = state.failReason;
    if (state.moveLimit != null && newHistory.length > state.moveLimit!) {
      nowFailed = true; reason = FailReason.movesExceeded;
    }

    // Update State:
    // - Add to history
    // - Remove from future
    state = state.copy(
      board: newBoard,
      history: newHistory,
      future: [...state.future]..removeAt(0),
      solved: _isWin(newBoard),
      failed: nowFailed,
      failReason: reason,
    );

    if (state.solved || state.failed) _stopTimer();
  }

  /// Restarts the current level.
  void restart(Board original) {
    _stopTimer(); // Reset timer logic

    // Reset state to initial values, but keep level constraints (limits).
    state = GameState(
      board: original,
      moveLimit: state.moveLimit,
      timeLimit: state.timeLimit,
      timeLeft: state.timeLimit,
    );

    _startTimerIfNeeded();
  }

  // --- TIMER LOGIC ---

  void _startTimerIfNeeded() {
    // If no time limit or timer already running, do nothing.
    if (state.timeLimit == null || _timerRunning) return;

    _timerRunning = true;
    _timer?.cancel();

    // Tick every second
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.solved || state.failed) {
        _stopTimer();
        return;
      }

      final cur = state.timeLeft ?? state.timeLimit!;
      final next = cur - 1;

      if (next <= 0) {
        // Time ran out!
        state = state.copy(timeLeft: 0, failed: true, failReason: FailReason.timeUp);
        _stopTimer();
      } else {
        // Just update the time
        state = state.copy(timeLeft: next);
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timerRunning = false;
  }

  /// Called when the provider is destroyed (e.g., user leaves the screen).
  @override
  void dispose() {
    _stopTimer();
    super.dispose();
  }
}

// ================= PROVIDER =================

/// The global definition of the provider.
/// It throws an error by default because it MUST be overridden in the UI
/// (e.g., in GameScreen) where the specific Level data is available.
final gameControllerProvider =
StateNotifierProvider<GameController, GameState>((ref) {
  throw UnimplementedError('Override in screen with a concrete GameController.');
});