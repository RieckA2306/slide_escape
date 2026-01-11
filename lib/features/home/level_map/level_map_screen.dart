import 'dart:async';
import 'package:flutter/material.dart';

// --- Imports adapted to your structure ---
import '../../../domain/entities/level.dart';
import '../../../data/levels/level_progress.dart';
import '../../../data/levels/level_definitions.dart';

// Import for the Settings Screen
import 'settings/settings_screen.dart';

class LevelMapScreen extends StatefulWidget {
  const LevelMapScreen({super.key});

  @override
  State<LevelMapScreen> createState() => _LevelMapScreenState();
}

class _LevelMapScreenState extends State<LevelMapScreen> with AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();

  int _highestUnlockedLevel = 1;
  bool _initialScrollDone = false;
  bool _showSettings = false;

  int _currentGold = 10;
  Timer? _regenTimer;
  int _secondsUntilNextGold = 0;

  // Design-Referenzbreite vom Pixel 8
  static const double _designWidth = 393.0;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadProgress(initialLoad: true);
    _loadGoldStatus();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _attemptAutoScroll(isInitial: true);
    });
  }

  @override
  void dispose() {
    _regenTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _toggleSettings() {
    setState(() {
      _showSettings = !_showSettings;
    });
  }

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
            "Nicht genug Gold!",
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

    // Calculations of scalefactor for the position of the level nodes
    final double screenWidth = MediaQuery.of(context).size.width;
    final double scale = screenWidth / _designWidth;

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
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    //Frame image + Star (Horizontal zentriert)
                    Positioned(
                    left: 0,
                    right: 0,
                    bottom: -20,
                    child: Center(
                      child: SizedBox(
                        width: 90, // Die widht of the biggest Element (frame2.png)
                        height: 90,
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
                    ),
                  ),
                    // Gold
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
                    if (_currentGold < 10)
                      Positioned(
                        top: 43,
                        right: 78,
                        child: Text(_timerString, style: const TextStyle(color: Colors.black, fontSize: 17, fontWeight: FontWeight.bold)),
                      ),
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

            // MAP SECTIONS (with scale)
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

        // Debug Button
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

        // Settings Overlay
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

  // Hilfsmethode für Slivers, um den Code oben sauberer zu halten
  Widget _buildSliverMapSection(BuildContext context, double scale, List<Widget> levels) {
    return SliverToBoxAdapter(
      child: _buildMapSection(context, scale, children: levels),
    );
  }

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

  Widget _buildLevel(double left, double top, Level level, double scale) {
    final bool isLocked = level.id > _highestUnlockedLevel;

    // ICON GRÖSSE ebenfalls skalieren, damit sie zum Pfad passt
    final double iconSize = 63 * scale;
    //Level Nodes
    return Positioned(
      // scale the positions
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
                  fontSize: 20 * scale, // Text ebenfalls leicht skalieren
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