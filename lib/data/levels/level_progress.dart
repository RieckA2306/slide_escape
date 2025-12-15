import 'package:shared_preferences/shared_preferences.dart';

class LevelProgress {
  static const _key = 'highest_unlocked_level';

  // New keys for gold system
  static const _goldKey = 'player_gold';
  static const _timestampKey = 'gold_last_update_timestamp';

  static const int maxGold = 10;
  static const int regenDurationMinutes = 15;

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

  // ================= GOLD SYSTEM LOGIC =================

  /// Calculates the current gold amount based on the time passed since the last update.
  /// Returns a Map with 'gold' (int) and 'secondsRemaining' (int) until next gold.
  static Future<Map<String, dynamic>> getGoldStatus() async {
    final prefs = await SharedPreferences.getInstance();
    int currentGold = prefs.getInt(_goldKey) ?? 10; // Default starts at 10
    int lastTimestamp = prefs.getInt(_timestampKey) ?? DateTime.now().millisecondsSinceEpoch;

    // If gold is already full, no calculation needed
    if (currentGold >= maxGold) {
      return {'gold': maxGold, 'secondsRemaining': 0};
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    final diffMillis = now - lastTimestamp;
    final regenMillis = regenDurationMinutes * 60 * 1000;

    // Calculate how many full 15-minute intervals have passed
    final int goldEarned = (diffMillis / regenMillis).floor();

    if (goldEarned > 0) {
      currentGold += goldEarned;
      if (currentGold >= maxGold) {
        currentGold = maxGold;
        // Gold is full, we don't need to track the timestamp precisely anymore
        await prefs.setInt(_goldKey, maxGold);
        return {'gold': maxGold, 'secondsRemaining': 0};
      } else {
        // Update gold and shift timestamp forward by the time consumed
        // This preserves "partial" time towards the next gold
        int newTimestamp = lastTimestamp + (goldEarned * regenMillis);
        await prefs.setInt(_goldKey, currentGold);
        await prefs.setInt(_timestampKey, newTimestamp);

        lastTimestamp = newTimestamp;
      }
    }

    // Calculate time remaining for the next gold piece
    final timePassedInCurrentInterval = now - lastTimestamp;
    final timeRemainingMillis = regenMillis - timePassedInCurrentInterval;
    final secondsRemaining = (timeRemainingMillis / 1000).ceil();

    return {
      'gold': currentGold,
      'secondsRemaining': secondsRemaining > 0 ? secondsRemaining : 0
    };
  }

  /// Consumes 1 gold. Returns true if successful, false if not enough gold.
  static Future<bool> consumeGold() async {
    final prefs = await SharedPreferences.getInstance();

    // Ensure status is up-to-date before deducting (in case time passed)
    await getGoldStatus();

    int currentGold = prefs.getInt(_goldKey) ?? 10;

    if (currentGold > 0) {
      // If we are dropping from max gold, we need to start the timer (set timestamp)
      if (currentGold == maxGold) {
        await prefs.setInt(_timestampKey, DateTime.now().millisecondsSinceEpoch);
      }

      currentGold--;
      await prefs.setInt(_goldKey, currentGold);
      return true;
    }
    return false;
  }

  /// Debug function: Adds gold directly (capped at maxGold).
  static Future<void> debugAddGold(int amount) async {
    final prefs = await SharedPreferences.getInstance();
    int currentGold = prefs.getInt(_goldKey) ?? 10;

    currentGold += amount;
    if (currentGold > maxGold) {
      currentGold = maxGold;
    }

    await prefs.setInt(_goldKey, currentGold);
  }
}