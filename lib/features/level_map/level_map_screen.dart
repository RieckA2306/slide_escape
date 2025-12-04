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

  // Required by AutomaticKeepAliveClientMixin.
  // Returning true ensures this widget is not destroyed when switching tabs.
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadProgress(initialLoad: true);

    // Initial Scroll Fix:
    // Wait for frames to ensure content height is calculated (images loaded).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _attemptAutoScroll(isInitial: true);
    });
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

  Future<void> _resetProgress() async {
    setState(() {
      _highestUnlockedLevel = 1;
    });
    // Scroll back to bottom after reset
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut
      );
    }
  }

  void _refreshProgress() {
    _loadProgress();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required by AutomaticKeepAliveClientMixin

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