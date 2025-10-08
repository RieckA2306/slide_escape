enum Orientation2D { h, v }

class Block {
  /// Unique block identifier, e.g., "T" for target
  final String id;
  /// Top-left row (0-based)
  final int row;
  /// Top-left col (0-based)
  final int col;
  /// Length in cells along the orientation (2 or 3; target is 2)
  final int length;
  /// Horizontal (h) or vertical (v)
  final Orientation2D orientation;
  /// True if this is the target block (the red one)
  final bool isTarget;

  const Block({
    required this.id,
    required this.row,
    required this.col,
    required this.length,
    required this.orientation,
    this.isTarget = false,
  });

  Block copyWith({int? row, int? col}) => Block(
    id: id,
    row: row ?? this.row,
    col: col ?? this.col,
    length: length,
    orientation: orientation,
    isTarget: isTarget,
  );

  /// Iterator of occupied cells by this block
  Iterable<(int r, int c)> cells() sync* {
    for (var i = 0; i < length; i++) {
      if (orientation == Orientation2D.h) {
        yield (row, col + i);
      } else {
        yield (row + i, col);
      }
    }
  }
}
