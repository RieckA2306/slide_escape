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
          // Sticky Header oben
          SliverAppBar(
            pinned: true,
            expandedHeight: 70,
            backgroundColor: Colors.white,
            flexibleSpace: const Center(
              child: Text(
                "Level Map",
                style: TextStyle(fontSize: 22, color: Colors.black),
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
              width: 63,   // <- hier kannst du die Größe anpassen
              height: 63,  // gleichmäßig halten
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
