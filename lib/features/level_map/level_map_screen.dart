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

    // beim ersten Frame nach ganz unten scrollen
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
          // Neuer Header oben
          SliverAppBar(
            pinned: true,
            expandedHeight: 80,
            backgroundColor: Colors.white,
            flexibleSpace: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Links: Kreis + ProgressBar
                    Row(
                      children: [
                        // Kreis mit "1"
                        Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.orange,
                          ),
                          child: const Center(
                            child: Text(
                              "1",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // ProgressBar
                        SizedBox(
                          width: 100,
                          height: 12,
                          child: LinearProgressIndicator(
                            value: 0.4, // Dummy-Wert
                            backgroundColor: Colors.grey,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),

                    // Mitte: Frame-Bild
                    Image.asset(
                      "assets/frames/frame1.png",
                      width: 80,
                      height: 80,
                    ),

                    // Rechts: Gold + Zahl + Zahnrad
                    Row(
                      children: [
                        // Platzhalter für Goldbarren
                        Container(
                          width: 50,
                          height: 30,
                          decoration: BoxDecoration(
                            color: Colors.amber[400],
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Center(
                            child: Text(
                              "10",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Zahnrad
                        IconButton(
                          icon: const Icon(Icons.settings, color: Colors.black),
                          onPressed: () {}, // noch ohne Funktion
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),


          // Abschnitt mit Level 1 & 2 (ganz unten Startpunkt)
          SliverToBoxAdapter(
            child: _buildMapSection(
              context,
              children: [
                _buildLevel(204, 558, levels[0]),
                _buildLevel(122, 518, levels[1]),
              ],
            ),
          ),

          // Abschnitt mit Level 10 & 11 (weiter oben)
          SliverToBoxAdapter(
            child: _buildMapSection(
              context,
              children: [
                _buildLevel(204, 558, levels[2]),
                _buildLevel(122, 518, levels[3]),
              ],
            ),
          ),

          // Abschnitt mit Level 19 & 20 (weiter oben)
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
            // PNG Button
            Image.asset(
              "assets/level_background/normal_level_background.png",
              width: 63,
              height: 63,
            ),

            // Levelnummer mittig
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
