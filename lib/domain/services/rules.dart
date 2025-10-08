import '../entities/board.dart';
import '../entities/block.dart';

class Rules {
  /// True when the target's right edge touches the right boundary.
  static bool isSolved(Board b) {
    final t = b.target;
    return t.orientation == Orientation2D.h && (t.col + t.length == b.width);
  }

  /// Compute legal sliding bounds for a block in board coordinates.
  /// Returns min/max row/col that the block's top-left corner can take.
  static ({int minRow, int maxRow, int minCol, int maxCol}) dragBounds(
      Board board,
      Block block,
      ) {
    // Occupancy except current block
    final occ = board.occupancy()..removeWhere((cell, id) => id == block.id);

    int minRow = block.row, maxRow = block.row;
    int minCol = block.col, maxCol = block.col;

    if (block.orientation == Orientation2D.h) {
      // Scan to the left
      var c = block.col - 1;
      while (c >= 0 && !_occupied(occ, block.row, c)) {
        minCol = c;
        c--;
      }
      // Scan to the right (check the cell after the tail)
      c = block.col + block.length;
      while (c < board.width && !_occupied(occ, block.row, c)) {
        maxCol = c - block.length + 1;
        c++;
      }
    } else {
      // Scan upwards
      var r = block.row - 1;
      while (r >= 0 && !_occupied(occ, r, block.col)) {
        minRow = r;
        r--;
      }
      // Scan downwards (check the cell after the tail)
      r = block.row + block.length;
      while (r < board.height && !_occupied(occ, r, block.col)) {
        maxRow = r - block.length + 1;
        r++;
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
      return newRow == block.row &&
          newCol >= b.minCol &&
          newCol <= b.maxCol;
    } else {
      return newCol == block.col &&
          newRow >= b.minRow &&
          newRow <= b.maxRow;
    }
  }
}
