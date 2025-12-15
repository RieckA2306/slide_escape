enum LevelType { normal, timeLimit, moveLimit, boss }

class Level {
  final int id;
  final LevelType type;
  final int size; // Board-Größe (z. B. 6)
  final List<int> targetIds;
  final int? timeLimit;
  final int? moveLimit;
  final int parMoves;
  final String difficulty;

  Level({
    required this.id,
    required this.type,
    required this.size,
    required this.targetIds,
    this.timeLimit,
    this.moveLimit,
    this.parMoves = 0,
    this.difficulty = "unknown",
  });
}
