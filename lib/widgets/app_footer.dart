import 'package:flutter/material.dart';
import '../features/level_map/level_map_screen.dart';
import '../features/shop/shop_screen.dart';
import '../features/leaderboard/leaderboard_screen.dart';

enum FooterTab { shop, map, leaderboard }

class AppFooter extends StatelessWidget {
  final FooterTab activeTab;

  const AppFooter({super.key, required this.activeTab});

  void _navigate(BuildContext context, FooterTab targetTab) {
    if (targetTab == activeTab) return;

    Widget targetScreen;
    switch (targetTab) {
      case FooterTab.shop:
        targetScreen = const ShopScreen();
        break;
      case FooterTab.map:
        targetScreen = const LevelMapScreen();
        break;
      case FooterTab.leaderboard:
        targetScreen = const LeaderboardScreen();
        break;
    }

    // Reihenfolge bestimmen
    final tabOrder = [FooterTab.shop, FooterTab.map, FooterTab.leaderboard];
    final currentIndex = tabOrder.indexOf(activeTab);
    final targetIndex = tabOrder.indexOf(targetTab);

    // Richtung bestimmen
    final isForward = targetIndex > currentIndex;

    // Wenn „überspringen“ (z.B. Shop -> Leaderboard), Animation schneller
    final skip = (currentIndex - targetIndex).abs() > 1;

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: Duration(milliseconds: skip ? 150 : 300),
        pageBuilder: (_, __, ___) => targetScreen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final begin = Offset(isForward ? 1.0 : -1.0, 0.0);
          const end = Offset.zero;
          final tween = Tween(begin: begin, end: end)
              .chain(CurveTween(curve: Curves.easeInOut));

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
      ),
    );
  }

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
              onTap: () => _navigate(context, FooterTab.shop),
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
              onTap: () => _navigate(context, FooterTab.map),
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
              onTap: () => _navigate(context, FooterTab.leaderboard),
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
