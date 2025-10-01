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
      Level(id: 3, type: LevelType.normal, size: 6, targetIds: [1]),
      Level(id: 4, type: LevelType.normal, size: 6, targetIds: [1]),
      Level(id: 5, type: LevelType.normal, size: 6, targetIds: [1]),
      Level(id: 6, type: LevelType.normal, size: 6, targetIds: [1]),
      Level(id: 7, type: LevelType.normal, size: 6, targetIds: [1]),
      Level(id: 8, type: LevelType.normal, size: 6, targetIds: [1]),
      Level(id: 9, type: LevelType.normal, size: 6, targetIds: [1]),
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

                // Progress bar
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

                // Frame image + Star inside
                Positioned(
                  left: 161,
                  bottom: -20,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Stern zuerst (hinten)
                      Image.asset(
                        "assets/app_bar/profile_pictures/star.png",
                        width: 60, // ggf. anpassen
                        height: 60,
                      ),
                      // Frame oben drauf
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
                    // Make sure the Stack has enough room: gold size + box width - overlap
                    width: 120,  // tweak as needed
                    height: 53,  // usually your goldbar size
                    child: Stack(
                      clipBehavior: Clip.none, // allow the value box to extend beyond the stack
                      children: [
                        // --- VALUE BOX (behind the goldbar) ---
                        Positioned(
                          // Push the value box to the right so the goldbar overlaps its left edge
                          left: 30,          // overlap amount: smaller = more overlap
                          top: 14, // vertical centering for a 34px-high box (adjust if you change height)
                          child: Container(
                            // >>> Set your box size here <<<
                            width: 70,   // <-- value box width (customizable)
                            height: 25,  // <-- value box height (customizable)
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF6EBF6),      // <-- background color (customizable)
                              borderRadius: BorderRadius.circular(12), // <-- corner radius (customizable)
                              border: Border.all(color: Colors.black26),
                            ),
                            child: const Text(
                              "10", // make dynamic if needed
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),

                        // --- GOLDBAR (in the foreground) ---
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Image.asset(
                            "assets/app_bar/goldbar.png",
                            width: 60,  // goldbar size
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
            Image.asset(
              "assets/level_background/normal_level_background.png",
              width: 63,
              height: 63,
            ),
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
