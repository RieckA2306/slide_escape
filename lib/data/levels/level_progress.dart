import 'package:shared_preferences/shared_preferences.dart';

/// Manages persistent player progress, including level unlocking and the gold/energy system.
/// Uses SharedPreferences to store data locally on the device.
class LevelProgress {
  // Key for storing the highest level the player has reached.
  static const _key = 'highest_unlocked_level';

  // Keys for the gold (energy) system storage.
  static const _goldKey = 'player_gold';
  static const _timestampKey = 'gold_last_update_timestamp';

  // Constants for the gold regeneration logic.
  static const int maxGold = 10;
  static const int regenDurationMinutes = 15;

  // LEVEL UNLOCKING LOGIC ------------------------------------

  /// Retrieves the highest level ID that is currently unlocked.
  /// Defaults to 1 if no data is found (e.g., first time playing).
  static Future<int> getHighestUnlockedLevel() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_key) ?? 1;
  }

  /// Unlocks the level immediately following the completed level.
  static Future<void> unlockLevel(int completedLevelId) async {
    final prefs = await SharedPreferences.getInstance();
    final currentHighest = prefs.getInt(_key) ?? 1;

    final nextLevel = completedLevelId + 1;

    // CRITICAL CHECK: Only update if the new level is actually higher than what we have.
    // Example: If the player has already unlocked level 10 but replays level 3,
    // we do NOT want to reset their progress back to 4. We only save new RECORDS.
    if (nextLevel > currentHighest) {
      await prefs.setInt(_key, nextLevel);
    }
  }

  // GOLD (ENERGY) SYSTEM LOGIC ------------------------------------

  /// Calculates the current gold status based on the time elapsed since the last check.
  /// This simulates "offline regeneration" without running a background process.

  /// Returns a Map containing:
  /// - 'gold': The current amount of gold (int).
  /// - 'secondsRemaining': Seconds left until the next gold piece regenerates (int).
  static Future<Map<String, dynamic>> getGoldStatus() async {
    final prefs = await SharedPreferences.getInstance();

    // Load saved data. Default to max gold (10) if no data exists.
    int currentGold = prefs.getInt(_goldKey) ?? 10;

    // Load the timestamp of the last update. If missing, assume "now".
    int lastTimestamp = prefs.getInt(_timestampKey) ?? DateTime.now().millisecondsSinceEpoch;

    // CASE 1: Gold is already full.
    // No regeneration needed. We report max gold and 0 waiting time.
    if (currentGold >= maxGold) {
      return {'gold': maxGold, 'secondsRemaining': 0};
    }

    // CASE 2: Gold is NOT full. Check if enough time has passed to earn more.
    final now = DateTime.now().millisecondsSinceEpoch;
    final diffMillis = now - lastTimestamp;
    final regenMillis = regenDurationMinutes * 60 * 1000; // 15 minutes in milliseconds

    // Calculate how many FULL regeneration intervals fit into the time passed.
    // Example: If 40 mins passed (regen is 15), (40/15) = 2 gold earned.
    final int goldEarned = (diffMillis / regenMillis).floor();

    if (goldEarned > 0) {
      currentGold += goldEarned;

      // Check if we hit the cap.
      if (currentGold >= maxGold) {
        currentGold = maxGold;
        // It will be reset the next time gold is consumed.
        await prefs.setInt(_goldKey, maxGold);
        return {'gold': maxGold, 'secondsRemaining': 0};
      } else {
        // We earned gold, but are not full yet.
        // IMPORTANT: We do NOT set the timestamp to 'now'.
        // Instead, we shift it forward by the exact time 'paid' for the earned gold.
        // This preserves the 'remainder' time.
        // Example: 20 mins passed (15 needed). 1 Gold earned. 5 mins remain towards the NEXT gold.
        int newTimestamp = lastTimestamp + (goldEarned * regenMillis);

        await prefs.setInt(_goldKey, currentGold);
        await prefs.setInt(_timestampKey, newTimestamp);

        // Update local variable for the next calculation step
        lastTimestamp = newTimestamp;
      }
    }

    // Calculate the time remaining for the NEXT single piece of gold.
    // Formula: Total Interval Duration - Time already passed in this interval.
    final timePassedInCurrentInterval = now - lastTimestamp;
    final timeRemainingMillis = regenMillis - timePassedInCurrentInterval;

    // Convert to seconds for the UI (ceiling ensures we don't show 0s when 0.5s remains).
    final secondsRemaining = (timeRemainingMillis / 1000).ceil();

    return {
      'gold': currentGold,
      'secondsRemaining': secondsRemaining > 0 ? secondsRemaining : 0
    };
  }

  /// Attempts to consume 1 gold to play a level.
  ///
  /// Returns [true] if gold was deducted successfully.
  /// Returns [false] if the player has 0 gold.
  static Future<bool> consumeGold() async {
    final prefs = await SharedPreferences.getInstance();

    // Step 1: Force an update.
    // Maybe a gold piece finished regenerating just now?
    await getGoldStatus();

    int currentGold = prefs.getInt(_goldKey) ?? 10;

    if (currentGold > 0) {
      // Step 2: If we were at MAX capacity, the timer wasn't running.
      // Now that we drop below max, we MUST start the timer by setting the timestamp to NOW.
      if (currentGold == maxGold) {
        await prefs.setInt(_timestampKey, DateTime.now().millisecondsSinceEpoch);
      }

      // Step 3: Deduct gold and save.
      currentGold--;
      await prefs.setInt(_goldKey, currentGold);
      return true;
    }

    // Not enough gold to play.
    return false;
  }

  /// Debug/Cheat function: Adds specific amount of gold.
  static Future<void> debugAddGold(int amount) async {
    print("--- DEBUG: debugAddGold started (Amount: $amount) ---");

    final prefs = await SharedPreferences.getInstance();

    // Ensure state is clean before modification.
    await getGoldStatus();

    int currentGold = prefs.getInt(_goldKey) ?? 10;
    int newGold = currentGold + amount;

    // Cap the value at maxGold (10).
    if (newGold > maxGold) {
      newGold = maxGold;
    }

    // Save the new balance.
    await prefs.setInt(_goldKey, newGold);

    // CRITICAL: If gold is full, stop the regeneration timer.
    // This prevents logical errors when gold is consumed later.
    if (newGold == maxGold) {
      await prefs.remove(_timestampKey);
    }

    print("--- DEBUG: Gold updated from $currentGold to $newGold ---");
  }
}