import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/board.dart';
import '../../../domain/entities/block.dart';
import '../../../domain/entities/move.dart';
import '../../../domain/services/rules.dart';
import '../state/game_state.dart';

/// The GameController is the "Brain" of the puzzle.
///
/// It extends [StateNotifier] to manage an immutable [GameState].
/// It handles:
/// 1. Movement Validation: Can a block move to a target coordinate?
/// 2. History Management: Recording moves for Undo/Redo functionality.
/// 3. Condition Checking: Evaluating if the level is won or failed.
/// 4. Time Management: Controlling the countdown timer for timed levels.
class GameController extends StateNotifier<GameState> {
  /// A functional callback to check if the current board configuration is a win.
  /// This allows different logic for "Normal" vs "Boss" levels.
  final WinCheck _isWin;

  Timer? _timer;
  bool _timerRunning = false;

  GameController(
      Board initial, {
        int? moveLimit,
        int? timeLimit,
        WinCheck? isWin,
      })  : _isWin = isWin ?? Rules.isSolved,
        super(
        GameState(
          board: initial,
          solved: (isWin ?? Rules.isSolved)(initial),
          moveLimit: moveLimit,
          timeLimit: timeLimit,
          timeLeft: timeLimit,
        ),
      ) {
    // Automatically start the countdown if the level has a time constraint.
    _startTimerIfNeeded();
  }

  /// Simple getter to access the current board layout from the state.
  Board get board => state.board;

  /// Calculates the maximum allowed movement area for a specific block.
  /// This is used by the UI to constrain the drag gesture.
  ({int minRow, int maxRow, int minCol, int maxCol}) boundsFor(Block b) =>
      Rules.dragBounds(board, b);

  /// Attempts to move a block.
  /// If the move is valid, it updates the board and checks for win/fail conditions.
  void tryMove(Block b, {required int toRow, required int toCol}) {
    // Input Guard: Stop interactions if the game is already over.
    if (state.solved || state.failed) return;

    // Logic Guard: Validate the move against the physical board constraints.
    if (!Rules.canPlace(board, b, toRow, toCol)) return;

    // Create a new board instance with the moved block.
    final movedBoard = board.applyMove(b.id, toRow, toCol);

    // Record the move details for the history stack.
    final mv = Move(
      blockId: b.id,
      fromRow: b.row,
      fromCol: b.col,
      toRow: toRow,
      toCol: toCol,
    );

    // Create a new history list (maintaining immutability).
    final newHistory = [...state.history, mv];

    bool nowFailed = state.failed;
    FailReason? reason = state.failReason;

    // Check if the user has run out of moves.
    if (state.moveLimit != null && newHistory.length > state.moveLimit!) {
      nowFailed = true;
      reason = FailReason.movesExceeded;
    }

    final nowSolved = _isWin(movedBoard);

    // Update the state. Riverpod will notify all listeners (the UI) to rebuild.
    state = state.copy(
      board: movedBoard,
      history: newHistory,
      // Whenever a new move is made, the "Redo" stack (future) must be cleared.
      future: const [],
      solved: nowSolved,
      failed: nowFailed,
      failReason: reason,
    );

    // Stop the timer if a terminal state is reached.
    if (state.solved || state.failed) _stopTimer();
  }

  /// Reverts the board to the state before the last move.
  void undo() {
    // Cannot undo if history is empty or if the game failed (prevents "cheating" after loss).
    if (state.history.isEmpty || state.failed) return;

    final last = state.history.last;
    final newBoard = board.applyMove(last.blockId, last.fromRow, last.fromCol);

    state = state.copy(
      board: newBoard,
      // Remove the last move from history.
      history: [...state.history]..removeLast(),
      // Add that move to the "future" stack so we can Redo it.
      future: [last, ...state.future],
      solved: _isWin(newBoard),
    );
  }

  /// Re-applies a move that was previously undone.
  void redo() {
    if (state.future.isEmpty || state.failed) return;

    final next = state.future.first;
    final newBoard = board.applyMove(next.blockId, next.toRow, next.toCol);
    final newHistory = [...state.history, next];

    bool nowFailed = state.failed;
    FailReason? reason = state.failReason;
    if (state.moveLimit != null && newHistory.length > state.moveLimit!) {
      nowFailed = true;
      reason = FailReason.movesExceeded;
    }

    state = state.copy(
      board: newBoard,
      history: newHistory,
      // Remove the move from the "future" stack as it is now part of history again.
      future: [...state.future]..removeAt(0),
      solved: _isWin(newBoard),
      failed: nowFailed,
      failReason: reason,
    );

    if (state.solved || state.failed) _stopTimer();
  }

  /// Resets the game to its initial state.
  void restart(Board original) {
    _stopTimer();
    state = GameState(
      board: original,
      moveLimit: state.moveLimit,
      timeLimit: state.timeLimit,
      timeLeft: state.timeLimit,
    );
    _startTimerIfNeeded();
  }

  /// Internal logic to manage the 1-second interval countdown.
  void _startTimerIfNeeded() {
    if (state.timeLimit == null || _timerRunning) return;

    _timerRunning = true;
    _timer?.cancel(); // Safety cleanup.

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      // Guard: Stop ticking if the game ended elsewhere.
      if (state.solved || state.failed) {
        _stopTimer();
        return;
      }

      final cur = state.timeLeft ?? state.timeLimit!;
      final next = cur - 1;

      if (next <= 0) {
        // Handle Timeout failure.
        state = state.copy(timeLeft: 0, failed: true, failReason: FailReason.timeUp);
        _stopTimer();
      } else {
        // Update countdown.
        state = state.copy(timeLeft: next);
      }
    });
  }

  /// Stops the active timer and updates the internal tracking flag.
  void _stopTimer() {
    _timer?.cancel();
    _timerRunning = false;
  }

  /// Standard lifecycle cleanup to prevent memory leaks.
  @override
  void dispose() {
    _stopTimer();
    super.dispose();
  }
}

/// A global provider for the GameController.
///
/// Note: We throw an [UnimplementedError] here because this provider
/// MUST be overridden in the [GameScreen] with level-specific data.
final gameControllerProvider =
StateNotifierProvider<GameController, GameState>((ref) {
  throw UnimplementedError('Override in screen with a concrete GameController.');
});