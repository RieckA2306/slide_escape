import 'package:flutter/material.dart';
import '../../domain/level.dart';

class LevelMapScreen extends StatefulWidget {
  const LevelMapScreen({super.key});

  @override
  State<LevelMapScreen> createState() => _LevelMapScreenState();
}

class _LevelMapScreenState extends State<LevelMapScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    // Scroll down to the bottom after the first frame is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final levels = [
      Level(id: 1, type: LevelType.normal, size: 6, targetIds: [1]),
      Level(id: 2, type: LevelType.normal, size: 6, targetIds: [1]),
      Level(id: 10, type: LevelType.normal, size: 6, targetIds: [1]),
      Level(id: 11, type: LevelType.normal, size: 6, targetIds: [1]),
      Level(id: 19, type: LevelType.normal, size: 6, targetIds: [1]),
      Level(id: 20, type: LevelType.normal, size: 6, targetIds: [1]),
    ];

    return Scaffold(
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // Top header
          SliverAppBar(
            pinned: true,
            expandedHeight: 65,
            collapsedHeight: 65,
            backgroundColor: Colors.white,
            flexibleSpace: SafeArea(
              child: Stack(
                clipBehavior: Clip.none, // allow children to overflow
                children: [
                  // Left: level background + number
                  Positioned(
                    left: 10,
                    top: 0,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Image.asset(
                          "assets/app_bar/level_background.png",
                          width: 65,
                          height: 65,
                        ),
                        const Text(
                          "1",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
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

                  // Progress bar next to level indicator
                  Positioned(
                    left: 67,
                    top: 27,
                    child: SizedBox(
                      width: 90,
                      height: 12,
                      child: LinearProgressIndicator(
                        value: 0.4,
                        backgroundColor: Colors.grey[300],
                        color: Colors.green,
                      ),
                    ),
                  ),

                  // Center: frame image (overhanging)
                  Positioned(
                    left: 161,
                    bottom: -20, // negative value makes it overhang below AppBar
                    child: Image.asset(
                      "assets/app_bar/frames/frame1.png",
                      width: 90,
                      height: 90,
                    ),
                  ),

                  // Right: gold bar + value
                  Positioned(
                    right: 72,
                    top: 6,
                    child: Row(
                      children: [
                        Image.asset(
                          "assets/app_bar/goldbar.png",
                          width: 50,
                          height: 50,
                        ),
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.black26),
                          ),
                          child: const Text(
                            "10",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Far right: settings icon
                  Positioned(
                    right: 10,
                    top: 4,
                    child: GestureDetector(
                      onTap: () {}, // no function yet
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

          // Section with Level 1 & 2 (bottom start point)
          SliverToBoxAdapter(
            child: _buildMapSection(
              context,
              children: [
                _buildLevel(204, 558, levels[0]),
                _buildLevel(122, 518, levels[1]),
              ],
            ),
          ),

          // Section with Level 10 & 11 (further up)
          SliverToBoxAdapter(
            child: _buildMapSection(
              context,
              children: [
                _buildLevel(204, 558, levels[2]),
                _buildLevel(122, 518, levels[3]),
              ],
            ),
          ),

          // Section with Level 19 & 20 (further up)
          SliverToBoxAdapter(
            child: _buildMapSection(
              context,
              children: [
                _buildLevel(204, 558, levels[4]),
                _buildLevel(122, 518, levels[5]),
              ],
            ),
          ),
        ],
      ),

      // Footer / Bottom Navigation Bar
      bottomNavigationBar: Container(
        color: Colors.white,
        height: 80,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: const [
            Expanded(
              child: Center(
                child: Text(
                  "Shop",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: Text(
                  "Map",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: Text(
                  "Leaderboard",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

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

  Widget _buildLevel(double left, double top, Level level) {
    return Positioned(
      left: left,
      top: top,
      child: GestureDetector(
        onTap: () {
          Navigator.pushNamed(context, "/game", arguments: level);
        },
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Level background image (button style)
            Image.asset(
              "assets/level_background/normal_level_background.png",
              width: 63,
              height: 63,
            ),

            // Level number text in the center
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
