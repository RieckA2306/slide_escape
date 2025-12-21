import '../../domain/entities/level.dart';

/// This class holds all static data regarding the levels.
/// It serves as a central database for level configurations.
class LevelDefinitions {

  /// The complete list of all levels.
  static final List<Level> allLevels = [
    Level(id: 1, type: LevelType.normal, targetIds: [1], parMoves: 2 , difficulty: "Normal"),
    Level(id: 2, type: LevelType.normal, targetIds: [1]),
    Level(id: 3, type: LevelType.moveLimit, targetIds: [1], moveLimit: 10, parMoves: 10, difficulty: "Move Limit"),
    Level(id: 4, type: LevelType.normal, targetIds: [1]),
    Level(id: 5, type: LevelType.normal, targetIds: [1]),
    Level(id: 6, type: LevelType.timeLimit, targetIds: [1], timeLimit: 18, parMoves: 11, difficulty: "Time Limit"),
    Level(id: 7, type: LevelType.normal, targetIds: [1]),
    Level(id: 8, type: LevelType.normal, targetIds: [1]),
    Level(id: 9, type: LevelType.boss, targetIds: const [], difficulty: "Boss"),
    Level(id: 10, type: LevelType.normal, targetIds: [1]),
    Level(id: 11, type: LevelType.normal, targetIds: [1]),
    Level(id: 12, type: LevelType.normal, targetIds: [1]),
    Level(id: 13, type: LevelType.normal, targetIds: [1]),
    Level(id: 14, type: LevelType.normal, targetIds: [1]),
    Level(id: 15, type: LevelType.normal, targetIds: [1]),
    Level(id: 16, type: LevelType.normal, targetIds: [1]),
    Level(id: 17, type: LevelType.normal, targetIds: [1]),
    Level(id: 18, type: LevelType.normal, targetIds: [1]),
    Level(id: 19, type: LevelType.normal, targetIds: [1]),
    Level(id: 20, type: LevelType.normal, targetIds: [1]),
    Level(id: 21, type: LevelType.normal, targetIds: [1]),
    Level(id: 22, type: LevelType.normal, targetIds: [1]),
    Level(id: 23, type: LevelType.normal, targetIds: [1]),
    Level(id: 24, type: LevelType.normal, targetIds: [1]),
    Level(id: 25, type: LevelType.normal, targetIds: [1]),
    Level(id: 26, type: LevelType.normal, targetIds: [1]),
    Level(id: 27, type: LevelType.normal, targetIds: [1]),
    Level(id: 28, type: LevelType.normal, targetIds: [1]),
    Level(id: 29, type: LevelType.normal, targetIds: [1]),
    Level(id: 30, type: LevelType.normal, targetIds: [1]),
    Level(id: 31, type: LevelType.normal, targetIds: [1]),
    Level(id: 32, type: LevelType.normal, targetIds: [1]),
    Level(id: 33, type: LevelType.normal, targetIds: [1]),
    Level(id: 34, type: LevelType.normal, targetIds: [1]),
    Level(id: 35, type: LevelType.normal, targetIds: [1]),
    Level(id: 36, type: LevelType.normal, targetIds: [1]),
    Level(id: 37, type: LevelType.normal, targetIds: [1]),
    Level(id: 38, type: LevelType.normal, targetIds: [1]),
    Level(id: 39, type: LevelType.normal, targetIds: [1]),
    Level(id: 40, type: LevelType.normal, targetIds: [1]),
    Level(id: 41, type: LevelType.normal, targetIds: [1]),
    Level(id: 42, type: LevelType.normal, targetIds: [1]),
    Level(id: 43, type: LevelType.normal, targetIds: [1]),
    Level(id: 44, type: LevelType.normal, targetIds: [1]),
    Level(id: 45, type: LevelType.normal, targetIds: [1]),
  ];

  /// Helper function: Returns a level based on its ID.
  /// If the ID does not exist, Level 1 is returned (safety fallback).
  static Level getLevelById(int id) {
    return allLevels.firstWhere(
          (level) => level.id == id,
      orElse: () => allLevels.first,
    );
  }
}

