import 'package:flutter/material.dart';

import '../features/level_map/level_map_screen.dart';
import '../features/shop/shop_screen.dart';
import '../features/leaderboard/leaderboard_screen.dart';

enum FooterTab { shop, map, leaderboard }

class AppFooter extends StatelessWidget {
  final FooterTab activeTab;

  const AppFooter({super.key, required this.activeTab});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      height: 80,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Shop
          Expanded(
            child: InkWell(
              onTap: activeTab == FooterTab.shop
                  ? null
                  : () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ShopScreen(),
                  ),
                );
              },
              child: Center(
                child: Text(
                  "Shop",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: activeTab == FooterTab.shop
                        ? Colors.blue
                        : Colors.black,
                  ),
                ),
              ),
            ),
          ),
          // Map
          Expanded(
            child: InkWell(
              onTap: activeTab == FooterTab.map
                  ? null
                  : () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const LevelMapScreen(),
                  ),
                );
              },
              child: Center(
                child: Text(
                  "Map",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: activeTab == FooterTab.map
                        ? Colors.blue
                        : Colors.black,
                  ),
                ),
              ),
            ),
          ),
          // Leaderboard
          Expanded(
            child: InkWell(
              onTap: activeTab == FooterTab.leaderboard
                  ? null
                  : () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const LeaderboardScreen(),
                  ),
                );
              },
              child: Center(
                child: Text(
                  "Leaderboard",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: activeTab == FooterTab.leaderboard
                        ? Colors.blue
                        : Colors.black,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
