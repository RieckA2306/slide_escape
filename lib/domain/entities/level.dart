enum LevelType { normal, timeLimit, moveLimit, boss }

class Level {
  final int id;
  final LevelType type;
  final List<int> targetIds;
  final int? timeLimit;
  final int? moveLimit;
  final String difficulty;

  Level({
    required this.id,
    required this.type,
    required this.targetIds,
    this.timeLimit,
    this.moveLimit,
    this.difficulty = "unknown",
  });
}
