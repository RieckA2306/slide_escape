import 'package:shared_preferences/shared_preferences.dart';

class LevelProgress {
  static const _key = 'highest_unlocked_level';

  /// Lädt das höchste freigeschaltete Level (Standard ist 1)
  static Future<int> getHighestUnlockedLevel() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_key) ?? 1;
  }

  /// Schaltet das nächste Level frei, falls es noch nicht offen ist
  static Future<void> unlockLevel(int completedLevelId) async {
    final prefs = await SharedPreferences.getInstance();
    final currentHighest = prefs.getInt(_key) ?? 1;

    // Wir schalten das nächste Level frei (completed + 1)
    final nextLevel = completedLevelId + 1;

    // Nur speichern, wenn wir einen neuen Rekord erreicht haben
    if (nextLevel > currentHighest) {
      await prefs.setInt(_key, nextLevel);
    }
  }
}