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

  const GameState({
    required this.board,
    this.history = const [],
    this.future = const [],
    this.solved = false,
  });

  GameState copy({
    Board? board,
    List<Move>? history,
    List<Move>? future,
    bool? solved,
  }) =>
      GameState(
        board: board ?? this.board,
        history: history ?? this.history,
        future: future ?? this.future,
        solved: solved ?? this.solved,
      );
}

class GameController extends StateNotifier<GameState> {
  GameController(Board initial)
      : super(GameState(board: initial, solved: Rules.isSolved(initial)));

  Board get board => state.board;

  ({int minRow, int maxRow, int minCol, int maxCol}) boundsFor(Block b) =>
      Rules.dragBounds(board, b);

  void tryMove(Block b, {required int toRow, required int toCol}) {
    if (!Rules.canPlace(board, b, toRow, toCol)) return;
    final moved = board.applyMove(b.id, toRow, toCol);
    final mv = Move(
      blockId: b.id,
      fromRow: b.row,
      fromCol: b.col,
      toRow: toRow,
      toCol: toCol,
    );
    state = state.copy(
      board: moved,
      history: [...state.history, mv],
      future: const [],
      solved: Rules.isSolved(moved),
    );
  }

  void undo() {
    if (state.history.isEmpty) return;
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
    if (state.future.isEmpty) return;
    final next = state.future.first;
    final newBoard = board.applyMove(next.blockId, next.toRow, next.toCol);
    state = state.copy(
      board: newBoard,
      history: [...state.history, next],
      future: [...state.future]..removeAt(0),
      solved: Rules.isSolved(newBoard),
    );
  }

  void restart(Board original) {
    state = GameState(board: original);
  }
}

final gameControllerProvider =
StateNotifierProvider<GameController, GameState>((ref) {
  throw UnimplementedError(
      'Override this provider in the screen with a concrete GameController.');
});
