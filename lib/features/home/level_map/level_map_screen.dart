import 'dart:async'; // Required for the timer
import 'package:flutter/material.dart';

// --- Imports adapted to your structure ---
import '../../../domain/entities/level.dart';
// The Import for our shared-prefernces and Goldtimer
import '../../../data/levels/level_progress.dart';
// The Import for the Definitions-Document:
import '../../../data/levels/level_definitions.dart';

//Import for the Settings Screen
import 'settings/settings_screen.dart';

class LevelMapScreen extends StatefulWidget {
  const LevelMapScreen({super.key});

  @override
  State<LevelMapScreen> createState() => _LevelMapScreenState();
}

class _LevelMapScreenState extends State<LevelMapScreen> with AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();

  // Tracks the highest level the user has unlocked. Defaults to 1.
  int _highestUnlockedLevel = 1;
  bool _initialScrollDone = false;

  // State to control the visibility of the settings overlay
  bool _showSettings = false;

  // --- GOLD & TIMER STATE ---
  int _currentGold = 10;
  Timer? _regenTimer;
  int _secondsUntilNextGold = 0;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadProgress(initialLoad: true);
    _loadGoldStatus();

    // Initial Scroll Fix
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _attemptAutoScroll(isInitial: true);
    });
  }

  @override
  void dispose() {
    _regenTimer?.cancel();
    super.dispose();
  }

  // Toggles the settings overlay on or off
  void _toggleSettings() {
    setState(() {
      _showSettings = !_showSettings;
    });
  }

  // --- GOLD LOGIC METHODS ---

  Future<void> _loadGoldStatus() async {
    final status = await LevelProgress.getGoldStatus();
    if (!mounted) return;

    setState(() {
      _currentGold = status['gold'];
      _secondsUntilNextGold = status['secondsRemaining'];
    });

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
          _loadGoldStatus();
        }
      });

      if (_currentGold >= 10) {
        timer.cancel();
      }
    });
  }

  String get _timerString {
    if (_currentGold >= 10) return "";
    final minutes = (_secondsUntilNextGold / 60).floor();
    final seconds = _secondsUntilNextGold % 60;
    return "${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
  }

  void _attemptAutoScroll({int retries = 0, bool isInitial = false}) {
    if (!mounted) return;

    if (_scrollController.hasClients && _scrollController.position.maxScrollExtent > 0) {
      if (isInitial && !_initialScrollDone) {
        _scrollToCurrentLevel();
        _initialScrollDone = true;
      }
    } else {
      if (retries < 10) {
        Future.delayed(const Duration(milliseconds: 300), () => _attemptAutoScroll(retries: retries + 1, isInitial: isInitial));
      }
    }
  }

  Future<void> _loadProgress({bool initialLoad = false}) async {
    final highest = await LevelProgress.getHighestUnlockedLevel();
    if (mounted) {
      final bool hasChanged = highest != _highestUnlockedLevel;

      setState(() {
        _highestUnlockedLevel = highest;
      });

      if (hasChanged && !initialLoad && _scrollController.hasClients) {
        Future.delayed(const Duration(milliseconds: 100), _scrollToCurrentLevel);
      }
    }
  }

  void _scrollToCurrentLevel() {
    if (!_scrollController.hasClients) return;

    final double maxScroll = _scrollController.position.maxScrollExtent;
    double targetOffset = maxScroll;

    if (_highestUnlockedLevel >= 15) {
      targetOffset = 0;
    } else if (_highestUnlockedLevel >= 13) {
      targetOffset = maxScroll * 0.25;
    } else if (_highestUnlockedLevel >= 11) {
      targetOffset = maxScroll * 0.50;
    } else if (_highestUnlockedLevel >= 9) {
      targetOffset = maxScroll * 0.75;
    } else {
      targetOffset = maxScroll;
    }

    _scrollController.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeOutCubic
    );
  }

  Future<void> _debugAddGold() async {
    await LevelProgress.debugAddGold(5);
    _loadGoldStatus();
  }

  void _refreshProgress() {
    _loadProgress();
    _loadGoldStatus();
  }

  Future<void> _onLevelTap(Level level) async {
    if (level.id > _highestUnlockedLevel) return;

    bool success = await LevelProgress.consumeGold();

    if (success) {
      await _loadGoldStatus();
      if (!mounted) return;

      await Navigator.pushNamed(context, "/game", arguments: level);
      _refreshProgress();
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Not enough Gold! Wait for regeneration.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18.0,
              fontWeight: FontWeight.bold,
            ),
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

    // --- PLAYER XP LOGIC ---
    final int completedLevels = _highestUnlockedLevel - 1;
    const double xpPerLevel = 0.334;
    final double totalXp = completedLevels * xpPerLevel;
    final int playerLevel = 1 + totalXp.floor();
    final double barProgress = (totalXp % 1.0).clamp(0.0, 1.0);

    // Wrap the CustomScrollView in a Stack to allow the Settings Overlay and the Debug Button to sit on top
    return Stack(
      children: [
        // LAYER 0: The Main Map Content (CustomScrollView)
        CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverAppBar(
              pinned: true,
              expandedHeight: 65,
              collapsedHeight: 65,
              backgroundColor: const Color(0xFFF1CCE6),
              flexibleSpace: SafeArea(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // ===== Level + Progress =====
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

                    // Frame image + Star
                    Positioned(
                      left: 161,
                      bottom: -20,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Image.asset(
                            "assets/app_bar/profile_pictures/star.png",
                            width: 60,
                            height: 60,
                          ),
                          Image.asset(
                            "assets/app_bar/frames/frame2.png",
                            width: 90,
                            height: 90,
                          ),
                        ],
                      ),
                    ),

                    // Gold + value
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
                                child: Text(
                                  "$_currentGold",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            ),
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

                    // TIMER
                    if (_currentGold < 10)
                      Positioned(
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

                    // Settings icon (Top: 4)
                    Positioned(
                      right: 10,
                      top: 4,
                      child: GestureDetector(
                        onTap: _toggleSettings,
                        child: Image.asset(
                          "assets/app_bar/settings.png",
                          width: 55,
                          height: 55,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // --- MAP SECTIONS ---
            // Section with Level 37 to 45
            SliverToBoxAdapter(
              child: _buildMapSection(
                context,
                children: [
                  _buildLevel(204, 558, LevelDefinitions.getLevelById(37)),
                  _buildLevel(122, 518, LevelDefinitions.getLevelById(38)),
                  _buildLevel(256, 438, LevelDefinitions.getLevelById(39)),
                  _buildLevel(125, 373, LevelDefinitions.getLevelById(40)),
                  _buildLevel(231, 287, LevelDefinitions.getLevelById(41)),
                  _buildLevel(118, 207, LevelDefinitions.getLevelById(42)),
                  _buildLevel(238, 140, LevelDefinitions.getLevelById(43)),
                  _buildLevel(129, 45,  LevelDefinitions.getLevelById(44)),
                  _buildLevel(256, 8,   LevelDefinitions.getLevelById(45)),
                ],
              ),
            ),

            // Section with Level 28 to 36
            SliverToBoxAdapter(
              child: _buildMapSection(
                context,
                children: [
                  _buildLevel(204, 558, LevelDefinitions.getLevelById(28)),
                  _buildLevel(122, 518, LevelDefinitions.getLevelById(29)),
                  _buildLevel(256, 438, LevelDefinitions.getLevelById(30)),
                  _buildLevel(125, 373, LevelDefinitions.getLevelById(31)),
                  _buildLevel(231, 287, LevelDefinitions.getLevelById(32)),
                  _buildLevel(118, 207, LevelDefinitions.getLevelById(33)),
                  _buildLevel(238, 140, LevelDefinitions.getLevelById(34)),
                  _buildLevel(129, 45,  LevelDefinitions.getLevelById(35)),
                  _buildLevel(256, 8,   LevelDefinitions.getLevelById(36)),
                ],
              ),
            ),

            // Section with Level 19 to 27
            SliverToBoxAdapter(
              child: _buildMapSection(
                context,
                children: [
                  _buildLevel(204, 558, LevelDefinitions.getLevelById(19)),
                  _buildLevel(122, 518, LevelDefinitions.getLevelById(20)),
                  _buildLevel(256, 438, LevelDefinitions.getLevelById(21)),
                  _buildLevel(125, 373, LevelDefinitions.getLevelById(22)),
                  _buildLevel(231, 287, LevelDefinitions.getLevelById(23)),
                  _buildLevel(118, 207, LevelDefinitions.getLevelById(24)),
                  _buildLevel(238, 140, LevelDefinitions.getLevelById(25)),
                  _buildLevel(129, 45,  LevelDefinitions.getLevelById(26)),
                  _buildLevel(256, 8,   LevelDefinitions.getLevelById(27)),
                ],
              ),
            ),

            // Section with Level 10 to 18
            SliverToBoxAdapter(
              child: _buildMapSection(
                context,
                children: [
                  _buildLevel(204, 558, LevelDefinitions.getLevelById(10)),
                  _buildLevel(122, 518, LevelDefinitions.getLevelById(11)),
                  _buildLevel(256, 438, LevelDefinitions.getLevelById(12)),
                  _buildLevel(125, 373, LevelDefinitions.getLevelById(13)),
                  _buildLevel(231, 287, LevelDefinitions.getLevelById(14)),
                  _buildLevel(118, 207, LevelDefinitions.getLevelById(15)),
                  _buildLevel(238, 140, LevelDefinitions.getLevelById(16)),
                  _buildLevel(129, 45,  LevelDefinitions.getLevelById(17)),
                  _buildLevel(256, 8,   LevelDefinitions.getLevelById(18)),
                ],
              ),
            ),

            // Section with Level 1 to 9
            SliverToBoxAdapter(
              child: _buildMapSection(
                context,
                children: [
                  _buildLevel(204, 558, LevelDefinitions.getLevelById(1)),
                  _buildLevel(122, 518, LevelDefinitions.getLevelById(2)),
                  _buildLevel(256, 438, LevelDefinitions.getLevelById(3)),
                  _buildLevel(125, 373, LevelDefinitions.getLevelById(4)),
                  _buildLevel(231, 287, LevelDefinitions.getLevelById(5)),
                  _buildLevel(118, 207, LevelDefinitions.getLevelById(6)),
                  _buildLevel(238, 140, LevelDefinitions.getLevelById(7)),
                  _buildLevel(129, 45,  LevelDefinitions.getLevelById(8)),
                  _buildLevel(256, 8,   LevelDefinitions.getLevelById(9)),
                ],
              ),
            ),
          ],
        ),

        // LAYER 1:  BUTTON for Gold one layer up. This was nessecary due to a bug where the button did´nt reacted to a click.
        Positioned(
          right: 10,
          top: 130,
          child: GestureDetector(
            onTap: _debugAddGold,
            child: Container(
              padding: const EdgeInsets.all(4),
              color: Colors.blue.withValues(alpha: 0.8),
              child: const Text(
                "+5 GOLD",
                style: TextStyle(fontSize: 15, color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),


        // LAYER 2: Settings Overlay
        if (_showSettings)
          Positioned.fill(
            child: Stack(
              children: [
                // 1.1 The Barrier (Transparent carpet)
                GestureDetector(
                  onTap: _toggleSettings,
                  child: Container(
                    color: Colors.transparent,
                  ),
                ),

                // 1.2 The Settings Dialog
                const Center(
                  child: SettingsScreen(),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildMapSection(BuildContext context, {required List<Widget> children}) {
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

  Widget _buildLevel(double left, double top, Level level) {
    final bool isLocked = level.id > _highestUnlockedLevel;

    return Positioned(
      left: left,
      top: top,
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
              width: 63,
              height: 63,
            ),
            if (isLocked)
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withValues(alpha: 0.25),
                ),
              ),
            if (isLocked)
              Image.asset(
                "assets/Lock/Lock.png",
                width: 60,
                height: 60,
                fit: BoxFit.contain,
              )
            else
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