import 'dart:async';
import 'package:flutter/material.dart';
import '../../../domain/entities/level.dart';
import '../../../data/levels/level_progress.dart';
import '../../../data/levels/level_definitions.dart';
import 'settings/settings_screen.dart';

/// The main entry point for level selection and progression.
///
/// Responsibilities:
/// 1. Navigation: Allows users to scroll through a map and select unlocked levels.
/// 2. Progression: Fetches the highest unlocked level and updates the UI accordingly.
/// 3. Energy System: Manages gold (currency/energy) regeneration via a background timer.
/// 4. Responsiveness: Scales the map coordinates based on a fixed design width (Pixel 8).
class LevelMapScreen extends StatefulWidget {
  const LevelMapScreen({super.key});

  @override
  State<LevelMapScreen> createState() => _LevelMapScreenState();
}

class _LevelMapScreenState extends State<LevelMapScreen> with AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();

  // State variables for progression and UI control if status switches its being rebuild
  //Got to define it in the beginning before the values are being sourced out of level_prpgress.dart (line 58)
  int _highestUnlockedLevel = 1;
  bool _showSettings = false;

  // Gold/Energy System state
  int _currentGold = 10;
  Timer? _regenTimer;
  int _secondsUntilNextGold = 0;

  /// CREATED BY CHATPGPT
  /// Used to calculate a scale factor for absolute positioning on the map.
  /// 393 is modern reference size for width
  static const double _designWidth = 393.0;

  @override
  bool get wantKeepAlive => true; // Prevents the screen from being disposed during tab switches

  /// Toggles the visibility of the settings overlay.
  void _toggleSettings() {
    setState(() {
      _showSettings = !_showSettings;
    });
  }

  /// After app is started get all of the data
  @override
  void initState() {
    super.initState();
    _loadProgress();
    _loadGoldStatus();
  }

  /// Fetches the current gold amount and time until next regeneration from storage.
  Future<void> _loadGoldStatus() async {
    final status = await LevelProgress.getGoldStatus();
    if (!mounted) return;

    setState(() {
      _currentGold = status['gold'];
      _secondsUntilNextGold = status['secondsRemaining'];
    });

    // Start timer if gold is below the maximum (10)
    if (_currentGold < 10 && (_regenTimer == null || !_regenTimer!.isActive)) {
      _startRegenTimer();
    }
  }

  /// Handles the countdown logic for gold regeneration.
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
          // Timer reached zero: fetch updated gold amount
          _loadGoldStatus();
        }
      });





    });
  }

  /// Formats the remaining regeneration time (e.g., "04:59").
  String get _timerString {
    if (_currentGold >= 10) return "";
    final minutes = (_secondsUntilNextGold / 60).floor();
    final seconds = _secondsUntilNextGold % 60;
    return "${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
  }

  /// Loads player progress and handles UI updates.
  Future<void> _loadProgress() async {
    final highest = await LevelProgress.getHighestUnlockedLevel();
    if (mounted) {
      setState(() {
        _highestUnlockedLevel = highest;
      });
    }
  }

  /// DEBUG: Adds gold to the player for testing purposes.
  Future<void> _debugAddGold() async {
    await LevelProgress.debugAddGold(5);
    _loadGoldStatus();
  }

  /// Refreshes all data on the screen.
  void _refreshProgress() {
    _loadProgress();
    _loadGoldStatus();
  }

  /// Handles level selection, gold consumption, and navigation.
  Future<void> _onLevelTap(Level level) async {
    if (level.id > _highestUnlockedLevel) return; // Prevent entering locked levels
    //consumes gold here
    bool success = await LevelProgress.consumeGold();

    if (success) {
      await _loadGoldStatus();
      if (!mounted) return;

      // Navigate to game and refresh when returning
      await Navigator.pushNamed(context, "/game", arguments: level);
      _refreshProgress();
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Not enough gold!",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    // RESPONSIVE SCALING:
    // Calculates how much to scale coordinates and sizes based on current device width.
    final double screenWidth = MediaQuery.of(context).size.width;
    final double scale = screenWidth / _designWidth;

    // XP & PLAYER LEVEL CALCULATION:
    // This logic derives the "Visual Player Level" from the number of completed game levels.
    final int completedLevels = _highestUnlockedLevel - 1;
    const double xpPerLevel = 0.334;
    final double totalXp = completedLevels * xpPerLevel;
    final int playerLevel = 1 + totalXp.floor();
    final double barProgress = (totalXp % 1.0).clamp(0.0, 1.0);

    return Stack(
      children: [
        CustomScrollView(
          controller: _scrollController,
          slivers: [
            // FIXED HEADER: Displays XP bar, Avatar, Gold, and Settings
            SliverAppBar(
              pinned: true,
              expandedHeight: 65,
              collapsedHeight: 65,
              backgroundColor: const Color(0xFFF1CCE6),
              flexibleSpace: SafeArea(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // ===== Level Indicator + XP Progress Bar =====
                    Positioned(
                      left: 10,
                      top: 0,
                      child: SizedBox(
                        width: 155,
                        height: 65,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Positioned(
                              left: 57,
                              top: 25,
                              child: ClipRRect(
                                borderRadius: const BorderRadius.only(
                                  topRight: Radius.circular(8),
                                  bottomRight: Radius.circular(8),
                                ),
                                child: Container(
                                  width: 90,
                                  height: 14,
                                  color: const Color(0xFFF6EBF6),
                                  child: Stack(
                                    children: [
                                      FractionallySizedBox(
                                        widthFactor: barProgress,
                                        heightFactor: 1.0,
                                        child: const ColoredBox(
                                          color: Color(0xFFE3B94E),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  const Image(
                                    image: AssetImage("assets/app_bar/level_background.png"),
                                    width: 65,
                                    height: 65,
                                  ),
                                  Text(
                                    "$playerLevel",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 20,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // ===== Profile Picture + Dynamic Frame (Centered) =====
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: -20,
                      child: Center(
                        child: SizedBox(
                          width: 90,
                          height: 90,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Image.asset(
                                "assets/app_bar/profile_pictures/star.png",
                                width: 60,
                                height: 60,
                              ),
                              // Frame changes based on player level
                              Image.asset(
                                playerLevel >= 6
                                    ? "assets/app_bar/frames/frame4.png"
                                    : playerLevel >= 3
                                    ? "assets/app_bar/frames/frame3.png"
                                    : playerLevel == 2
                                    ? "assets/app_bar/frames/frame2.png"
                                    : "assets/app_bar/frames/frame1.png",
                                width: 90,
                                height: 90,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // ===== Gold Counter =====
                    Positioned(
                      right: 48,
                      top: 5,
                      child: SizedBox(
                        width: 120,
                        height: 53,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
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
                                child: Text("$_currentGold", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              ),
                            ),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Image.asset("assets/app_bar/goldbar.png", width: 60, height: 60),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // ===== Regen Timer =====
                    if (_currentGold < 10)
                      Positioned(
                        top: 43,
                        right: 78,
                        child: Text(_timerString, style: const TextStyle(color: Colors.black, fontSize: 17, fontWeight: FontWeight.bold)),
                      ),

                    // ===== Settings Button =====
                    Positioned(
                      right: 10,
                      top: 4,
                      child: GestureDetector(
                        onTap: _toggleSettings,
                        child: Image.asset("assets/app_bar/settings.png", width: 55, height: 55),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // MAP SECTIONS:
            // The map is divided into background sections. Each section contains a list of levels.
            // Coordinates are based on the original design and multiplied by the 'scale'.
            _buildSliverMapSection(context, scale, [
              _buildLevel(195, 530, LevelDefinitions.getLevelById(37), scale),
              _buildLevel(115, 493, LevelDefinitions.getLevelById(38), scale),
              _buildLevel(243, 420, LevelDefinitions.getLevelById(39), scale),
              _buildLevel(119, 360, LevelDefinitions.getLevelById(40), scale),
              _buildLevel(220, 275, LevelDefinitions.getLevelById(41), scale),
              _buildLevel(110, 200, LevelDefinitions.getLevelById(42), scale),
              _buildLevel(226, 133, LevelDefinitions.getLevelById(43), scale),
              _buildLevel(123, 44,  LevelDefinitions.getLevelById(44), scale),
              _buildLevel(245, 8,   LevelDefinitions.getLevelById(45), scale),
            ]),

            _buildSliverMapSection(context, scale, [
              _buildLevel(195, 530, LevelDefinitions.getLevelById(28), scale),
              _buildLevel(115, 493, LevelDefinitions.getLevelById(29), scale),
              _buildLevel(243, 420, LevelDefinitions.getLevelById(30), scale),
              _buildLevel(119, 360, LevelDefinitions.getLevelById(31), scale),
              _buildLevel(220, 275, LevelDefinitions.getLevelById(32), scale),
              _buildLevel(110, 200, LevelDefinitions.getLevelById(33), scale),
              _buildLevel(226, 133, LevelDefinitions.getLevelById(34), scale),
              _buildLevel(123, 44,  LevelDefinitions.getLevelById(35), scale),
              _buildLevel(245, 8,   LevelDefinitions.getLevelById(36), scale),
            ]),

            _buildSliverMapSection(context, scale, [
              _buildLevel(195, 530, LevelDefinitions.getLevelById(19), scale),
              _buildLevel(115, 493, LevelDefinitions.getLevelById(20), scale),
              _buildLevel(243, 420, LevelDefinitions.getLevelById(21), scale),
              _buildLevel(119, 360, LevelDefinitions.getLevelById(22), scale),
              _buildLevel(220, 275, LevelDefinitions.getLevelById(23), scale),
              _buildLevel(110, 200, LevelDefinitions.getLevelById(24), scale),
              _buildLevel(226, 133, LevelDefinitions.getLevelById(25), scale),
              _buildLevel(123, 44,  LevelDefinitions.getLevelById(26), scale),
              _buildLevel(245, 8,   LevelDefinitions.getLevelById(27), scale),
            ]),

            _buildSliverMapSection(context, scale, [
              _buildLevel(195, 530, LevelDefinitions.getLevelById(10), scale),
              _buildLevel(115, 493, LevelDefinitions.getLevelById(11), scale),
              _buildLevel(243, 420, LevelDefinitions.getLevelById(12), scale),
              _buildLevel(119, 360, LevelDefinitions.getLevelById(13), scale),
              _buildLevel(220, 275, LevelDefinitions.getLevelById(14), scale),
              _buildLevel(110, 200, LevelDefinitions.getLevelById(15), scale),
              _buildLevel(226, 133, LevelDefinitions.getLevelById(16), scale),
              _buildLevel(123, 44,  LevelDefinitions.getLevelById(17), scale),
              _buildLevel(245, 8,   LevelDefinitions.getLevelById(18), scale),
            ]),

            _buildSliverMapSection(context, scale, [
              _buildLevel(195, 530, LevelDefinitions.getLevelById(1), scale),
              _buildLevel(115, 493, LevelDefinitions.getLevelById(2), scale),
              _buildLevel(243, 420, LevelDefinitions.getLevelById(3), scale),
              _buildLevel(119, 360, LevelDefinitions.getLevelById(4), scale),
              _buildLevel(220, 275, LevelDefinitions.getLevelById(5), scale),
              _buildLevel(110, 200, LevelDefinitions.getLevelById(6), scale),
              _buildLevel(226, 133, LevelDefinitions.getLevelById(7), scale),
              _buildLevel(123, 44,  LevelDefinitions.getLevelById(8), scale),
              _buildLevel(245, 8,   LevelDefinitions.getLevelById(9), scale),
            ]),
          ],
        ),

        // Debug Tool
        Positioned(
          right: 10,
          top: 130,
          child: GestureDetector(
            onTap: _debugAddGold,
            child: Container(
              padding: const EdgeInsets.all(4),
              color: Colors.blue.withOpacity(0.8),
              child: const Text("+5 GOLD", style: TextStyle(fontSize: 15, color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ),

        // Settings Dialog Overlay
        if (_showSettings)
          Positioned.fill(
            child: Stack(
              children: [
                GestureDetector(
                  onTap: _toggleSettings,
                  child: Container(color: Colors.transparent),
                ),
                const Center(child: SettingsScreen()),
              ],
            ),
          ),
      ],
    );
  }

  /// Wraps a map background section into a SliverToBoxAdapter.
  Widget _buildSliverMapSection(BuildContext context, double scale, List<Widget> levels) {
    return SliverToBoxAdapter(
      child: _buildMapSection(context, scale, children: levels),
    );
  }

  /// Builds a single background image section with level nodes as children.
  Widget _buildMapSection(BuildContext context, double scale, {required List<Widget> children}) {
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

  /// Creates a clickable level button at a specific coordinate.
  /// Handles visual states for 'locked' vs 'unlocked'.
  Widget _buildLevel(double left, double top, Level level, double scale) {
    final bool isLocked = level.id > _highestUnlockedLevel;
    final double iconSize = 63 * scale;

    return Positioned(
      left: left * scale,
      top: top * scale,
      child: GestureDetector(
        onTap: () async {
          if (isLocked) return;
          _onLevelTap(level);
        },
        child: Stack(
          alignment: Alignment.center,
          children: [
            Image.asset(
              "assets/level_background/normal_level_background.png",
              width: iconSize,
              height: iconSize,
            ),
            // Lock overlay if level is not reachable yet
            if (isLocked)
              Container(
                width: 58 * scale,
                height: 58 * scale,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withOpacity(0.25),
                ),
              ),
            if (isLocked)
              Image.asset(
                "assets/Lock/Lock.png",
                width: 60 * scale,
                height: 60 * scale,
                fit: BoxFit.contain,
              )
            else
              Text(
                level.id.toString(),
                style: TextStyle(
                  fontSize: 20 * scale,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  shadows: const [
                    Shadow(blurRadius: 4, color: Colors.black54, offset: Offset(1, 1)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}