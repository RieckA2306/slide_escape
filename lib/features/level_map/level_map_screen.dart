import 'dart:async'; // Required for the timer
import 'package:flutter/material.dart';
import '../../domain/level.dart';
import '../../domain/services/level_progress.dart'; // Import the progress service

class LevelMapScreen extends StatefulWidget {
  const LevelMapScreen({super.key});

  @override
  State<LevelMapScreen> createState() => _LevelMapScreenState();
}

// Added AutomaticKeepAliveClientMixin to preserve state (scroll position)
// when switching tabs (e.g., going to Shop and back).
class _LevelMapScreenState extends State<LevelMapScreen> with AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();

  // Tracks the highest level the user has unlocked. Defaults to 1.
  int _highestUnlockedLevel = 1;
  bool _initialScrollDone = false;

  // --- GOLD & TIMER STATE ---
  int _currentGold = 10;
  Timer? _regenTimer;
  int _secondsUntilNextGold = 0;

  // Required by AutomaticKeepAliveClientMixin.
  // Returning true ensures this widget is not destroyed when switching tabs.
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadProgress(initialLoad: true);

    // Load initial gold status and start timer if needed
    _loadGoldStatus();

    // Initial Scroll Fix:
    // Wait for frames to ensure content height is calculated (images loaded).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _attemptAutoScroll(isInitial: true);
    });
  }

  @override
  void dispose() {
    // Cancel the timer to prevent memory leaks
    _regenTimer?.cancel();
    super.dispose();
  }

  // --- GOLD LOGIC METHODS ---

  Future<void> _loadGoldStatus() async {
    final status = await LevelProgress.getGoldStatus();
    if (!mounted) return;

    setState(() {
      _currentGold = status['gold'];
      _secondsUntilNextGold = status['secondsRemaining'];
    });

    // If gold is not full, start the visual countdown timer
    if (_currentGold < 10 && (_regenTimer == null || !_regenTimer!.isActive)) {
      _startRegenTimer();
    }
  }

  void _startRegenTimer() {
    _regenTimer?.cancel();
    _regenTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        if (_secondsUntilNextGold > 0) {
          _secondsUntilNextGold--;
        } else {
          // Timer finished, reload gold status from service to update count
          _loadGoldStatus();
        }
      });

      // Stop timer if gold is full
      if (_currentGold >= 10) {
        timer.cancel();
      }
    });
  }

  // Formats seconds into MM:SS string
  String get _timerString {
    if (_currentGold >= 10) return "";
    final minutes = (_secondsUntilNextGold / 60).floor();
    final seconds = _secondsUntilNextGold % 60;
    return "${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
  }

  /// Tries to scroll to the current level.
  void _attemptAutoScroll({int retries = 0, bool isInitial = false}) {
    if (!mounted) return;

    // Check if controller is attached and we have a valid scrollable area
    // (greater than 0 means images have loaded and expanded the view)
    if (_scrollController.hasClients && _scrollController.position.maxScrollExtent > 0) {
      // Only scroll if it's the first load OR if we explicitly want to (e.g. level change)
      if (isInitial && !_initialScrollDone) {
        _scrollToCurrentLevel();
        _initialScrollDone = true;
      }
    } else {
      // Retry if content isn't ready
      if (retries < 10) {
        Future.delayed(const Duration(milliseconds: 300), () => _attemptAutoScroll(retries: retries + 1, isInitial: isInitial));
      }
    }
  }

  /// Loads the saved progress.
  Future<void> _loadProgress({bool initialLoad = false}) async {
    final highest = await LevelProgress.getHighestUnlockedLevel();
    if (mounted) {
      final bool hasChanged = highest != _highestUnlockedLevel;

      setState(() {
        _highestUnlockedLevel = highest;
      });

      // If the level changed (e.g. came back from winning a game),
      // we want to scroll to the new position.
      // We do NOT want to scroll if nothing changed (e.g. just refreshing).
      if (hasChanged && !initialLoad && _scrollController.hasClients) {
        // Small delay to let the UI update (unlock animation maybe?) before scrolling
        Future.delayed(const Duration(milliseconds: 100), _scrollToCurrentLevel);
      }
    }
  }

  /// Calculates the approximate scroll position based on the highest unlocked level.
  void _scrollToCurrentLevel() {
    if (!_scrollController.hasClients) return;

    final double maxScroll = _scrollController.position.maxScrollExtent;
    double targetOffset = maxScroll; // Default to bottom (Level 1)

    // Rough estimation logic remains the same
    if (_highestUnlockedLevel >= 15) {
      targetOffset = 0; // Top
    } else if (_highestUnlockedLevel >= 13) {
      targetOffset = maxScroll * 0.25;
    } else if (_highestUnlockedLevel >= 11) {
      targetOffset = maxScroll * 0.50;
    } else if (_highestUnlockedLevel >= 9) {
      targetOffset = maxScroll * 0.75;
    } else {
      targetOffset = maxScroll; // Bottom
    }

    _scrollController.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeOutCubic
    );
  }

  // --- DEBUG FUNCTION ---
  Future<void> _debugAddGold() async {
    await LevelProgress.debugAddGold(5);
    _loadGoldStatus(); // Refresh UI immediately
  }

  void _refreshProgress() {
    _loadProgress();
    _loadGoldStatus(); // Refresh gold when returning from a game
  }

  // Logic to handle level tapping
  Future<void> _onLevelTap(Level level) async {
    // Check if level is locked
    if (level.id > _highestUnlockedLevel) return;

    // Check and consume gold
    bool success = await LevelProgress.consumeGold();

    if (success) {
      // Update UI immediately
      await _loadGoldStatus();

      if (!mounted) return;

      // Navigate to game
      await Navigator.pushNamed(context, "/game", arguments: level);

      // Refresh progress upon return
      _refreshProgress();
    } else {
      // Show error if not enough gold
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Nicht genug Gold! Warte auf Regeneration."),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required by AutomaticKeepAliveClientMixin

    // --- PLAYER XP LOGIC ---
    // Calculate player stats based on unlocked levels
    // Each completed level gives 0.334 XP.
    // Completed levels = highestUnlockedLevel - 1 (since unlocked starts at 1)
    final int completedLevels = _highestUnlockedLevel - 1;
    final double xpPerLevel = 0.334;
    final double totalXp = completedLevels * xpPerLevel;

    // Player level starts at 1 and increases every time totalXp crosses an integer threshold
    final int playerLevel = 1 + totalXp.floor();

    // Progress bar fills up from 0.0 to 1.0 based on the decimal part of totalXp
    // Use modulo 1 to get the fractional part, clamp just to be safe visually
    final double barProgress = (totalXp % 1.0).clamp(0.0, 1.0);

    final levels = [
      Level(id: 1, type: LevelType.normal, size: 6, targetIds: const [],),
      Level(id: 2, type: LevelType.normal, size: 6, targetIds: [1]),
      Level(id: 3, type: LevelType.moveLimit, size: 6, targetIds: const [], moveLimit: 10, parMoves: 10, difficulty: "medium",),
      Level(id: 4, type: LevelType.normal, size: 6, targetIds: [1]),
      Level(id: 5, type: LevelType.normal, size: 6, targetIds: [1]),
      Level(id: 6, type: LevelType.timeLimit, size: 6, targetIds: const [], timeLimit: 15, parMoves: 11, difficulty: "hard",),
      Level(id: 7, type: LevelType.normal, size: 6, targetIds: [1]),
      Level(id: 8, type: LevelType.normal, size: 6, targetIds: [1]),
      Level(id: 9, type: LevelType.boss, size: 6, targetIds: const [], difficulty: "boss",),
      Level(id: 10, type: LevelType.normal, size: 6, targetIds: [1]),
      Level(id: 11, type: LevelType.normal, size: 6, targetIds: [1]),
      Level(id: 12, type: LevelType.normal, size: 6, targetIds: [1]),
      Level(id: 13, type: LevelType.normal, size: 6, targetIds: [1]),
      Level(id: 14, type: LevelType.normal, size: 6, targetIds: [1]),
      Level(id: 15, type: LevelType.normal, size: 6, targetIds: [1]),
      Level(id: 16, type: LevelType.normal, size: 6, targetIds: [1]),
      Level(id: 17, type: LevelType.normal, size: 6, targetIds: [1]),
      Level(id: 18, type: LevelType.normal, size: 6, targetIds: [1]),
      Level(id: 19, type: LevelType.normal, size: 6, targetIds: [1]),
      Level(id: 20, type: LevelType.normal, size: 6, targetIds: [1]),
      Level(id: 21, type: LevelType.normal, size: 6, targetIds: [1]),
      Level(id: 22, type: LevelType.normal, size: 6, targetIds: [1]),
      Level(id: 23, type: LevelType.normal, size: 6, targetIds: [1]),
      Level(id: 24, type: LevelType.normal, size: 6, targetIds: [1]),
      Level(id: 25, type: LevelType.normal, size: 6, targetIds: [1]),
      Level(id: 26, type: LevelType.normal, size: 6, targetIds: [1]),
      Level(id: 27, type: LevelType.normal, size: 6, targetIds: [1]),
      Level(id: 28, type: LevelType.normal, size: 6, targetIds: [1]),
      Level(id: 29, type: LevelType.normal, size: 6, targetIds: [1]),
      Level(id: 30, type: LevelType.normal, size: 6, targetIds: [1]),
      Level(id: 31, type: LevelType.normal, size: 6, targetIds: [1]),
      Level(id: 32, type: LevelType.normal, size: 6, targetIds: [1]),
      Level(id: 33, type: LevelType.normal, size: 6, targetIds: [1]),
      Level(id: 34, type: LevelType.normal, size: 6, targetIds: [1]),
      Level(id: 35, type: LevelType.normal, size: 6, targetIds: [1]),
      Level(id: 36, type: LevelType.normal, size: 6, targetIds: [1]),
      Level(id: 37, type: LevelType.normal, size: 6, targetIds: [1]),
      Level(id: 38, type: LevelType.normal, size: 6, targetIds: [1]),
      Level(id: 39, type: LevelType.normal, size: 6, targetIds: [1]),
      Level(id: 40, type: LevelType.normal, size: 6, targetIds: [1]),
      Level(id: 41, type: LevelType.normal, size: 6, targetIds: [1]),
      Level(id: 42, type: LevelType.normal, size: 6, targetIds: [1]),
      Level(id: 43, type: LevelType.normal, size: 6, targetIds: [1]),
      Level(id: 44, type: LevelType.normal, size: 6, targetIds: [1]),
      Level(id: 45, type: LevelType.normal, size: 6, targetIds: [1]),

    ];

    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        // Top header
        SliverAppBar(
          pinned: true,
          expandedHeight: 65,
          collapsedHeight: 65,
          backgroundColor: const Color(0xFFF1CCE6),
          flexibleSpace: SafeArea(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // ===== Level + Progress (Candy-Crush style, merged block) =====
                Positioned(
                  left: 10,
                  top: 0,
                  child: SizedBox(
                    width: 155,
                    height: 65,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // --- PROGRESS BAR (behind the icon) ---
                        Positioned(
                          left: 57,
                          top: 25,
                          child: ClipRRect(
                            // round ONLY the right corners
                            borderRadius: const BorderRadius.only(
                              topRight: Radius.circular(8),
                              bottomRight: Radius.circular(8),
                            ),
                            child: Container(
                              width: 90,
                              height: 14,
                              color: const Color(0xFFF6EBF6), // track/bg color (HEX)
                              child: Stack(
                                children: [
                                  // fill (0.0..1.0)
                                  FractionallySizedBox(
                                    widthFactor: barProgress, // Dynamic Width
                                    heightFactor: 1.0,        // take full bar height (important!)
                                    child: const ColoredBox(
                                      color: Color(0xFFE3B94E), // fill color (HEX)
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // --- LEVEL ICON (in the foreground) ---
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Displays the current highest level (or current play level)
                              const Image(
                                image: AssetImage("assets/app_bar/level_background.png"),
                                width: 65,
                                height: 65,
                              ),
                              Text(
                                "$playerLevel", // Display Player Level
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 20,
                                  color: Colors.white,
                                  shadows: [
                                    Shadow(
                                      blurRadius: 3,
                                      color: Colors.black54,
                                      offset: Offset(1, 1),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // ===== End: Level + Progress =====

                // Frame image + Star inside
                Positioned(
                  left: 161,
                  bottom: -20,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Star in background
                      Image.asset(
                        "assets/app_bar/profile_pictures/star.png",
                        width: 60,
                        height: 60,
                      ),
                      // Frame on top
                      Image.asset(
                        "assets/app_bar/frames/frame2.png",
                        width: 90,
                        height: 90,
                      ),
                    ],
                  ),
                ),

                // Gold + value (Candy-Crush style)
                Positioned(
                  right: 48,
                  top: 5,
                  child: SizedBox(
                    width: 120,
                    height: 53,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // value box (behind)
                        Positioned(
                          left: 30,
                          top: 14,
                          child: Container(
                            width: 70,
                            height: 25,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF6EBF6),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.black26),
                            ),
                            child: Text(
                              "$_currentGold", // Updated to dynamic gold variable
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                        // goldbar (front)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Image.asset(
                            "assets/app_bar/goldbar.png",
                            width: 60,
                            height: 60,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ===== TIMER DISPLAY (INDEPENDENT POSITION) =====
                // Only show if gold is not full
                if (_currentGold < 10)
                  Positioned(
                    // ADJUST POSITION HERE:
                    // Use 'top' and 'right' to position it exactly where you want relative to the corner.
                    // 'right' is preferred over 'left' here since the Gold bar is right-aligned.
                    top: 43,
                    right: 78,
                      child: Text(
                        _timerString,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),


                // Settings icon
                Positioned(
                  right: 10,
                  top: 4,
                  child: GestureDetector(
                    onTap: () {},
                    child: Image.asset(
                      "assets/app_bar/settings.png",
                      width: 55,
                      height: 55,
                    ),
                  ),
                ),

                // TEST BUTTON: Add 5 Gold (Replaced Reset Button)
                Positioned(
                  right: 10,
                  top: 80, // Below settings
                  child: GestureDetector(
                    onTap: _debugAddGold,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      color: Colors.blue.withOpacity(0.8), // Blue for Add
                      child: const Text(
                        "+5 GOLD",
                        style: TextStyle(fontSize: 15, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),


        // Section with Level 37 to 45
        SliverToBoxAdapter(
          child: _buildMapSection(
            context,
            children: [
              _buildLevel(204, 558, levels[36]),
              _buildLevel(122, 518, levels[37]),
              _buildLevel(256, 438, levels[38]),
              _buildLevel(125, 373, levels[39]),
              _buildLevel(231, 287, levels[40]),
              _buildLevel(118, 207, levels[41]),
              _buildLevel(238, 140, levels[42]),
              _buildLevel(129, 45, levels[43]),
              _buildLevel(256, 8, levels[44]),
            ],
          ),
        ),

        // Section with Level 28 to 36
        SliverToBoxAdapter(
          child: _buildMapSection(
            context,
            children: [
              _buildLevel(204, 558, levels[27]),
              _buildLevel(122, 518, levels[28]),
              _buildLevel(256, 438, levels[29]),
              _buildLevel(125, 373, levels[30]),
              _buildLevel(231, 287, levels[31]),
              _buildLevel(118, 207, levels[32]),
              _buildLevel(238, 140, levels[33]),
              _buildLevel(129, 45, levels[34]),
              _buildLevel(256, 8, levels[35]),
            ],
          ),
        ),

        // Section with Level 19 to 27
        SliverToBoxAdapter(
          child: _buildMapSection(
            context,
            children: [
              _buildLevel(204, 558, levels[18]),
              _buildLevel(122, 518, levels[19]),
              _buildLevel(256, 438, levels[20]),
              _buildLevel(125, 373, levels[21]),
              _buildLevel(231, 287, levels[22]),
              _buildLevel(118, 207, levels[23]),
              _buildLevel(238, 140, levels[24]),
              _buildLevel(129, 45, levels[25]),
              _buildLevel(256, 8, levels[26]),
            ],
          ),
        ),

        // Section with Level 10 to 18
        SliverToBoxAdapter(
          child: _buildMapSection(
            context,
            children: [
              _buildLevel(204, 558, levels[9]),
              _buildLevel(122, 518, levels[10]),
              _buildLevel(256, 438, levels[11]),
              _buildLevel(125, 373, levels[12]),
              _buildLevel(231, 287, levels[13]),
              _buildLevel(118, 207, levels[14]),
              _buildLevel(238, 140, levels[15]),
              _buildLevel(129, 45, levels[16]),
              _buildLevel(256, 8, levels[17]),
            ],
          ),
        ),

        // Section with Level 1 to 9
        SliverToBoxAdapter(
          child: _buildMapSection(
            context,
            children: [
              _buildLevel(204, 558, levels[0]),
              _buildLevel(122, 518, levels[1]),
              _buildLevel(256, 438, levels[2]),
              _buildLevel(125, 373, levels[3]),
              _buildLevel(231, 287, levels[4]),
              _buildLevel(118, 207, levels[5]),
              _buildLevel(238, 140, levels[6]),
              _buildLevel(129, 45, levels[7]),
              _buildLevel(256, 8, levels[8]),
            ],
          ),
        ),
      ],
    );
  }

  /// Helper widget to build a section of the map background.
  Widget _buildMapSection(BuildContext context,
      {required List<Widget> children}) {
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      child: Stack(
        children: [
          Image.asset(
            "assets/map_background/background.jpg",
            width: MediaQuery.of(context).size.width,
            fit: BoxFit.fitWidth,
          ),
          ...children,
        ],
      ),
    );
  }

  /// Helper widget to position a level node on the map.
  /// Handles Locked/Unlocked states with blur effects.
  Widget _buildLevel(double left, double top, Level level) {
    // Determine if the level is locked based on progress
    final bool isLocked = level.id > _highestUnlockedLevel;

    return Positioned(
      left: left,
      top: top,
      child: GestureDetector(
        onTap: () async {
          // Prevent opening locked levels
          if (isLocked) return;

          // Call the gold check logic instead of navigating directly
          _onLevelTap(level);
        },
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 1. Level Background Node (Always clean image)
            Image.asset(
              "assets/level_background/normal_level_background.png",
              width: 63,
              height: 63,
            ),

            // 2. Gray Overlay (Only if locked)
            if (isLocked)
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withOpacity(0.25), // Gray transparent
                ),
              ),

            // 3. Content: Lock Icon OR Level Number
            if (isLocked)
            // Show Lock Icon if locked
              Image.asset(
                "assets/Lock/Lock.png", // Ensure this asset exists
                width: 60, // Reduced size slightly so it fits nicely inside the node
                height: 60,
                fit: BoxFit.contain,
              )
            else
            // Show Level Number if unlocked
              Text(
                level.id.toString(),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      blurRadius: 4,
                      color: Colors.black54,
                      offset: Offset(1, 1),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}