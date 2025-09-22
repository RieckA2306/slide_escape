enum Orientation { horizontal, vertical }

class Block {
  final int id;
  int x;
  int y;
  final int length;
  final Orientation orientation;
  final bool movable;
  final bool moveOnce;
  bool hasMoved;

  Block({
    required this.id,
    required this.x,
    required this.y,
    required this.length,
    required this.orientation,
    this.movable = true,
    this.moveOnce = false,
    this.hasMoved = false,
  });
}
