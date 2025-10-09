import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/board.dart';
import '../../../domain/entities/block.dart';
import '../../../domain/entities/move.dart';
import '../../../domain/services/rules.dart';

class GameState {
  final Board board;
  final List<Move> history;
  final List<Move> future;
  final bool solved;

  /// Optional hard cap on number of moves (null = no limit)
  final int? moveLimit;

  /// True once the player exceeds the move limit
  final bool failed;

  const GameState({
    required this.board,
    this.history = const [],
    this.future = const [],
    this.solved = false,
    this.moveLimit,
    this.failed = false,
  });

  int get movesUsed => history.length;
  int? get movesLeft => moveLimit == null ? null : (moveLimit! - movesUsed).clamp(0, moveLimit!);

  GameState copy({
    Board? board,
    List<Move>? history,
    List<Move>? future,
    bool? solved,
    int? moveLimit,
    bool? failed,
  }) =>
      GameState(
        board: board ?? this.board,
        history: history ?? this.history,
        future: future ?? this.future,
        solved: solved ?? this.solved,
        moveLimit: moveLimit ?? this.moveLimit,
        failed: failed ?? this.failed,
      );
}

class GameController extends StateNotifier<GameState> {
  GameController(Board initial, {int? moveLimit})
      : super(GameState(
    board: initial,
    solved: Rules.isSolved(initial),
    moveLimit: moveLimit,
  ));

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

    // Move-limit check: exceeding the limit marks the run as failed
    bool nowFailed = state.failed;
    if (state.moveLimit != null && newHistory.length > state.moveLimit!) {
      nowFailed = true;
    }

    state = state.copy(
      board: movedBoard,
      history: newHistory,
      future: const [],
      solved: nowSolved,
      failed: nowFailed,
    );
  }

  void undo() {
    if (state.history.isEmpty || state.failed) return; // allow undo after fail? choose policy
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
    if (state.moveLimit != null && newHistory.length > state.moveLimit!) {
      nowFailed = true;
    }

    state = state.copy(
      board: newBoard,
      history: newHistory,
      future: [...state.future]..removeAt(0),
      solved: Rules.isSolved(newBoard),
      failed: nowFailed,
    );
  }

  void restart(Board original) {
    state = GameState(board: original, moveLimit: state.moveLimit);
  }
}

final gameControllerProvider =
StateNotifierProvider<GameController, GameState>((ref) {
  throw UnimplementedError('Override in screen with a concrete GameController.');
});
