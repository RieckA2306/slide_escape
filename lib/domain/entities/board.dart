import 'block.dart';

class Board {
  /// Board width in cells (typically 6)
  final int width;
  /// Board height in cells (typically 6)
  final int height;
  /// Immutable list of blocks
  final List<Block> blocks;

  const Board({required this.width, required this.height, required this.blocks});

  Block get target => blocks.firstWhere((b) => b.isTarget);

  /// Returns a new board with the block moved to the new top-left row/col.
  Board applyMove(String blockId, int newRow, int newCol) {
    final moved = blocks
        .map((b) => b.id == blockId ? b.copyWith(row: newRow, col: newCol) : b)
        .toList(growable: false);
    return Board(width: width, height: height, blocks: moved);
  }

  /// Map of occupied cells to block id
  Map<(int r, int c), String> occupancy() {
    final map = <(int, int), String>{};
    for (final b in blocks) {
      for (final cell in b.cells()) {
        map[cell] = b.id;
      }
    }
    return map;
  }

  /// Helper: find a block by id
  Block? blockById(String id) => blocks.cast<Block?>().firstWhere(
        (b) => b!.id == id,
    orElse: () => null,
  );
}
