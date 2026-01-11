import '../../../domain/entities/board.dart';
import '../../../domain/entities/move.dart';

/// Defines why a level was failed.
enum FailReason {
  /// The player used more moves than allowed.
  movesExceeded,
  /// The time ran out (for time-limit levels).
  timeUp
}

/// A custom function type to check if the board is solved.
typedef WinCheck = bool Function(Board);

/// Holds the immutable state of the current game session.
class GameState {
  final Board board;
  final List<Move> history;
  final List<Move> future;
  final bool solved;

  // --- Level Constraints ---
  final int? moveLimit;
  final int? timeLimit;
  final int? timeLeft;

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