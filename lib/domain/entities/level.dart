enum LevelType { normal, timeLimit, moveLimit, boss }

class Level {
  final int id;
  /// e.g. "LevelType.normal", "LevelType.timelimit",...
  final LevelType type;
  /// Value in seconds how much time your level should have
  final int? timeLimit;
  /// How much moves your level should have
  final int? moveLimit;
  /// Name in Header in game_screen
  final String difficulty;

  Level({
    required this.id,
    required this.type,
    this.timeLimit,
    this.moveLimit,
    this.difficulty = "unknown",
  });
}
