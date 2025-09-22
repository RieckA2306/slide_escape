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
    ];

    return Scaffold(
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // Sticky Header oben
          SliverAppBar(
            pinned: true,
            expandedHeight: 80,
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
                _buildLevel(212, 565, levels[0], Colors.blue),
                _buildLevel(125, 520, levels[1], Colors.red),
              ],
            ),
          ),

          // Abschnitt mit Level 10 & 11 (weiter oben)
          SliverToBoxAdapter(
            child: _buildMapSection(
              context,
              children: [
                _buildLevel(200, 560, levels[2], Colors.green),
                _buildLevel(100, 510, levels[3], Colors.orange),
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

  Widget _buildLevel(double left, double top, Level level, Color color) {
    return Positioned(
      left: left,
      top: top,
      child: GestureDetector(
        onTap: () {
          Navigator.pushNamed(context, "/game", arguments: level);
        },
        child: CircleAvatar(
          radius: 26,
          backgroundColor: color,
          child: Text(level.id.toString()),
        ),
      ),
    );
  }
}
