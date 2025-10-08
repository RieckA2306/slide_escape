class Move {
  final String blockId;
  final int fromRow, fromCol;
  final int toRow, toCol;

  const Move({
    required this.blockId,
    required this.fromRow,
    required this.fromCol,
    required this.toRow,
    required this.toCol,
  });

  Move inverted() => Move(
    blockId: blockId,
    fromRow: toRow,
    fromCol: toCol,
    toRow: fromRow,
    toCol: fromCol,
  );
}
