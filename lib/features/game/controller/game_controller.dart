import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/board.dart';
import '../../../domain/entities/block.dart';
import '../../../domain/entities/move.dart';
import '../../../domain/services/rules.dart';

/// Reason why a run failed.
enum FailReason { movesExceeded, timeUp }

class GameState {
  final Board board;
  final List<Move> history;
  final List<Move> future;
  final bool solved;

  /// Hard cap on number of moves (null = no limit)
  final int? moveLimit;

  /// Time limit in seconds (null = no limit)
  final int? timeLimit;

  /// Remaining time in seconds (null if no time limit)
  final int? timeLeft;

  /// True once the player exceeds any limit (moves or time)
  final bool failed;

  /// Why the run failed (null if not failed)
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

  int get movesUsed => history.length;
  int? get movesLeft =>
      moveLimit == null ? null : (moveLimit! - movesUsed).clamp(0, moveLimit!);

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

class GameController extends StateNotifier<GameState> {
  Timer? _timer;
  bool _timerRunning = false;

  GameController(
      Board initial, {
        int? moveLimit,
        int? timeLimit, // seconds
      }) : super(
    GameState(
      board: initial,
      solved: Rules.isSolved(initial),
      moveLimit: moveLimit,
      timeLimit: timeLimit,
      timeLeft: timeLimit, // initialize countdown
    ),
  ) {
    _startTimerIfNeeded();
  }

  Board get board => state.board;

  ({int minRow, int maxRow, int minCol, int maxCol}) boundsFor(Block b) =>
      Rules.dragBounds(board, b);

  void tryMove(Block b, {required int toRow, required int toCol}) {
    // Prevent interaction after solved or failed
    if (state.solved || state.failed) return;

    if (!Rules.canPlace(board, b, toRow, toCol)) return;
    final movedBoard = board.applyMove(b.id, toRow, toCol);
    final mv = Move(
      blockId: b.id,
      fromRow: b.row,
      fromCol: b.col,
      toRow: toRow,
      toCol: toCol,
    );

    final newHistory = [...state.history, mv];
    final nowSolved = Rules.isSolved(movedBoard);

    // Move-limit check
    bool nowFailed = state.failed;
    FailReason? reason = state.failReason;
    if (state.moveLimit != null && newHistory.length > state.moveLimit!) {
      nowFailed = true;
      reason = FailReason.movesExceeded;
    }

    // Commit state
    state = state.copy(
      board: movedBoard,
      history: newHistory,
      future: const [],
      solved: nowSolved,
      failed: nowFailed,
      failReason: reason,
    );

    // Stop timer on terminal states
    if (state.solved || state.failed) _stopTimer();
  }

  void undo() {
    if (state.history.isEmpty || state.failed) return;
    final last = state.history.last;
    final newBoard = board.applyMove(last.blockId, last.fromRow, last.fromCol);
    state = state.copy(
      board: newBoard,
      history: [...state.history]..removeLast(),
      future: [last, ...state.future],
      solved: Rules.isSolved(newBoard),
    );
  }

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
      future: [...state.future]..removeAt(0),
      solved: Rules.isSolved(newBoard),
      failed: nowFailed,
      failReason: reason,
    );

    if (state.solved || state.failed) _stopTimer();
  }

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

  void _startTimerIfNeeded() {
    if (state.timeLimit == null || _timerRunning) return;
    _timerRunning = true;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.solved || state.failed) {
        _stopTimer();
        return;
      }
      final cur = state.timeLeft ?? state.timeLimit!;
      final next = cur - 1;
      if (next <= 0) {
        // Time up
        state = state.copy(
          timeLeft: 0,
          failed: true,
          failReason: FailReason.timeUp,
        );
        _stopTimer();
      } else {
        state = state.copy(timeLeft: next);
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timerRunning = false;
  }

  @override
  void dispose() {
    _stopTimer();
    super.dispose();
  }
}

final gameControllerProvider =
StateNotifierProvider<GameController, GameState>((ref) {
  throw UnimplementedError('Override in screen with a concrete GameController.');
});
