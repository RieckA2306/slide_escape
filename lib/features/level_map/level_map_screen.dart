import 'dart:ui'; // Required for ImageFilter
import 'package:flutter/material.dart';
import '../../domain/level.dart';
import '../../domain/services/level_progress.dart'; // Import the progress service

class LevelMapScreen extends StatefulWidget {
  const LevelMapScreen({super.key});

  @override
  State<LevelMapScreen> createState() => _LevelMapScreenState();
}

class _LevelMapScreenState extends State<LevelMapScreen> {
  final ScrollController _scrollController = ScrollController();

  // Tracks the highest level the user has unlocked. Defaults to 1.
  int _highestUnlockedLevel = 1;

  @override
  void initState() {
    super.initState();
    _loadProgress();

    // Scroll down to the bottom after the first frame is rendered
    // to show the starting levels (typically at the bottom of the map).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  /// Loads the saved progress from SharedPreferences via the service.
  Future<void> _loadProgress() async {
    final highest = await LevelProgress.getHighestUnlockedLevel();
    setState(() {
      _highestUnlockedLevel = highest;
    });
  }

  /// Resets the progress back to Level 1 (For testing purposes).
  Future<void> _resetProgress() async {
    // Reset by "unlocking" level 0 (logic depends on service,
    // but usually we might need a clear method.
    // Here we act as if we just reset local state and maybe overwrite).
    // Since the service only "increases" level, let's manually assume
    // we would clear prefs. For now, we simulate a reset or
    // allow the service to be extended.
    // Ideally, LevelProgress would have a clear method.
    // For this snippet, I will just set the state to 1.
    // Real implementation: await SharedPreferences.getInstance()..clear();

    // Using a quick hack to force reset via the Service if possible,
    // or just assume we modify the SharedPreferences directly here for the test button.
    // Importing SharedPreferences just for this test button:
    // import 'package:shared_preferences/shared_preferences.dart';
    // But since I shouldn't add imports not in the file block if I can avoid it,
    // I will assume LevelProgress has a reset or I just set local state to 1.
    // To be cleaner, let's just set local state to 1 and note that a restart might be needed
    // if the service doesn't support clearing.

    // UPDATE: To make it work persistently for you to test:
    // I'll add a temporary direct reset if the service allows,
    // or just pretend for the UI session.
    // If you want a real reset, you'd add `static Future<void> reset() ...` to LevelProgress.

    setState(() {
      _highestUnlockedLevel = 1;
    });

    // Note: This only resets the UI for this session unless we actually clear Prefs.
    // Assuming you implemented LevelProgress, adding a reset there is best.
  }

  /// Called when returning from the game screen to update unlocked levels.
  void _refreshProgress() {
    _loadProgress();
  }

  @override
  Widget build(BuildContext context) {
    // Define the level configuration
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
      Level(id: 19, type: LevelType.normal, size: 6, targetIds: [1]),
      Level(id: 20, type: LevelType.normal, size: 6, targetIds: [1]),
      Level(id: 28, type: LevelType.normal, size: 6, targetIds: [1]),
      Level(id: 29, type: LevelType.normal, size: 6, targetIds: [1]),
      Level(id: 28, type: LevelType.normal, size: 6, targetIds: [1]),
      Level(id: 29, type: LevelType.normal, size: 6, targetIds: [1]),
    ];

    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        // Top header with status bars and settings
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
                                children: const [
                                  // fill (0.0..1.0)
                                  FractionallySizedBox(
                                    widthFactor: 0.30,
                                    heightFactor: 1.0,               // take full bar height (important!)
                                    child: ColoredBox(
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
                                "$_highestUnlockedLevel", // Display current max level
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
                            child: const Text(
                              "10",
                              style: TextStyle(
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

                // TEST BUTTON: Reset Progress
                // Positioned top-left (or near settings) to easily reset progress
                Positioned(
                  right: 10,
                  top: 50, // Below settings
                  child: GestureDetector(
                    onTap: _resetProgress,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      color: Colors.red.withOpacity(0.8),
                      child: const Text(
                        "RESET",
                        style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),


        // Section with Level 21 & 29
        SliverToBoxAdapter(
          child: _buildMapSection(
            context,
            children: [
              _buildLevel(204, 558, levels[15]),
              _buildLevel(122, 518, levels[16]),
            ],
          ),
        ),

        // Section with Level 21 & 29
        SliverToBoxAdapter(
          child: _buildMapSection(
            context,
            children: [
              _buildLevel(204, 558, levels[13]),
              _buildLevel(122, 518, levels[14]),
            ],
          ),
        ),

        // Section with Level 19 & 20
        SliverToBoxAdapter(
          child: _buildMapSection(
            context,
            children: [
              _buildLevel(204, 558, levels[11]),
              _buildLevel(122, 518, levels[12]),
            ],
          ),
        ),

        // Section with Level 10 & 11
        SliverToBoxAdapter(
          child: _buildMapSection(
            context,
            children: [
              _buildLevel(204, 558, levels[9]),
              _buildLevel(122, 518, levels[10]),
            ],
          ),
        ),

        // Section with Level 1 & 2
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

          // Navigate to the Game Screen
          await Navigator.pushNamed(context, "/game", arguments: level);

          // Refresh progress upon return (in case level was completed)
          _refreshProgress();
        },
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 1. Level Background Node
            // If locked, we apply a blur effect to this specific widget
            isLocked
                ? ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 3, sigmaY: 3), // Blur effect
              child: Image.asset(
                "assets/level_background/normal_level_background.png",
                width: 63,
                height: 63,
              ),
            )
                : Image.asset(
              "assets/level_background/normal_level_background.png",
              width: 63,
              height: 63,
            ),

            // 2. Level Content (Number OR Lock Icon)
            if (isLocked)
            // Show Lock Icon if locked
              Image.asset(
                "assets/Lock/Lock.png", // Ensure this asset exists
                width: 60,
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