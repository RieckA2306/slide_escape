import '../entities/board.dart';
import '../entities/block.dart';

class Rules {
  /// Standard win: the single horizontal target touches the right boundary.
  static bool isSolved(Board b) {
    final t = b.blocks.firstWhere((x) => x.isTarget, orElse: () => b.blocks.first);
    return t.orientation == Orientation2D.h && (t.col + t.length == b.width);
  }

  /// Boss win: both targets must be in place at the same time:
  /// - horizontal target on [exitRow], touching right boundary
  /// - vertical target on [exitCol], touching bottom boundary
  static bool isSolvedBoss(Board b, {required int exitRow, required int exitCol}) {
    Block? hTarget;
    Block? vTarget;
    for (final t in b.blocks.where((x) => x.isTarget)) {
      if (t.orientation == Orientation2D.h) hTarget = t;
      if (t.orientation == Orientation2D.v) vTarget = t;
    }
    if (hTarget == null || vTarget == null) return false;

    final hOk = (hTarget!.row == exitRow) && (hTarget!.col + hTarget!.length == b.width);
    final vOk = (vTarget!.col == exitCol) && (vTarget!.row + vTarget!.length == b.height);
    return hOk && vOk;
  }

  /// Compute legal sliding bounds for a block in board coordinates.
  /// Returns min/max row/col that the block's top-left corner can take.
  static ({int minRow, int maxRow, int minCol, int maxCol}) dragBounds(
      Board board,
      Block block,
      ) {
    final occ = board.occupancy()..removeWhere((cell, id) => id == block.id);

    int minRow = block.row, maxRow = block.row;
    int minCol = block.col, maxCol = block.col;

    if (block.orientation == Orientation2D.h) {
      var c = block.col - 1;
      while (c >= 0 && !_occupied(occ, block.row, c)) {
        minCol = c; c--;
      }
      c = block.col + block.length;
      while (c < board.width && !_occupied(occ, block.row, c)) {
        maxCol = c - block.length + 1; c++;
      }
    } else {
      var r = block.row - 1;
      while (r >= 0 && !_occupied(occ, r, block.col)) {
        minRow = r; r--;
      }
      r = block.row + block.length;
      while (r < board.height && !_occupied(occ, r, block.col)) {
        maxRow = r - block.length + 1; r++;
      }
    }
    return (minRow: minRow, maxRow: maxRow, minCol: minCol, maxCol: maxCol);
  }

  static bool _occupied(Map<(int, int), String> occ, int r, int c) =>
      occ.containsKey((r, c));

  /// Check if placing block's top-left at (newRow,newCol) is legal.
  static bool canPlace(Board board, Block block, int newRow, int newCol) {
    final b = dragBounds(board, block);
    if (block.orientation == Orientation2D.h) {
      return newRow == block.row && newCol >= b.minCol && newCol <= b.maxCol;
    } else {
      return newCol == block.col && newRow >= b.minRow && newRow <= b.maxRow;
    }
  }
}
