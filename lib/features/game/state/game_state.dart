import '../../../domain/entities/board.dart';
import '../../../domain/entities/move.dart';

/// Represents the specific reason why a player did not complete the level.
/// Using an enum is much safer than strings as it prevents typos and
/// allows the UI to use 'switch' statements for localized error messages.
enum FailReason {
  /// Triggered when the moves history exceeds the level's moveLimit.
  movesExceeded,
  /// Triggered when the timer reaches zero in time-restricted levels.
  timeUp
}

/// A signature for a function that takes a [Board] and returns true if it's solved.
/// This allows us to inject different winning logic (e.g., "Normal" vs "Boss")
/// without changing the GameController itself.
typedef WinCheck = bool Function(Board);

/// An immutable representation of the game at a specific point in time.
///
/// IMPORTANT: In Riverpod, we never "modify" this object. Instead, we create
/// a brand new instance using the [copy] method. This allows Riverpod to
/// detect changes by comparing object references (OldState != NewState).
class GameState {
  /// The current arrangement of blocks on the grid.
  final Board board;

  /// The 'Undo' stack: A list of moves already performed.
  final List<Move> history;

  /// The 'Redo' stack: Moves that were undone and can be reapplied.
  final List<Move> future;

  /// Whether the current board configuration meets the win requirements.
  final bool solved;

  // --- Level Constraints ---

  /// The maximum number of moves allowed (null means infinite).
  final int? moveLimit;

  /// The initial countdown time in seconds (null means no limit).
  final int? timeLimit;

  /// The current clock value remaining.
  final int? timeLeft;

  // --- Failure State ---

  /// True if the player lost (either ran out of time or moves).
  final bool failed;

  /// Provides details on why the failure occurred.
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

  /// **Derived State**: Calculates moves used based on history length.
  /// This ensures the move count is always "in sync" with the actual moves list.
  int get movesUsed => history.length;

  /// **Derived State**: Calculates remaining moves.
  /// Uses [.clamp] to ensure the UI doesn't display negative numbers if
  /// the limit is exceeded by one move before the "Fail" screen pops up.
  int? get movesLeft =>
      moveLimit == null ? null : (moveLimit! - movesUsed).clamp(0, moveLimit!);

  /// The "Copy-With" pattern.
  ///
  /// Since all fields in this class are 'final', we cannot change them.
  /// This method takes the existing values and replaces only the ones
  /// provided in the arguments, returning a fresh [GameState] object.
  ///
  /// Example: `state = state.copy(solved: true);`
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