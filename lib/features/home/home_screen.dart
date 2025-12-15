import 'package:flutter/material.dart';
import '../home/shop/shop_screen.dart';
import '../home/level_map/level_map_screen.dart';
import '../home/leaderboard/leaderboard_screen.dart';
import '../../widgets/app_footer.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PageController _pageController = PageController(initialPage: 1);
  FooterTab _activeTab = FooterTab.map;

  void _onTabSelected(FooterTab tab) {
    final index = {
      FooterTab.shop: 0,
      FooterTab.map: 1,
      FooterTab.leaderboard: 2,
    }[tab]!;

    setState(() => _activeTab = tab);

    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _activeTab =
            [FooterTab.shop, FooterTab.map, FooterTab.leaderboard][index];
          });
        },
        children: const [
          ShopScreen(),
          LevelMapScreen(),
          LeaderboardScreen(),
        ],
      ),
      bottomNavigationBar: AppFooter(
        activeTab: _activeTab,
        onTabSelected: _onTabSelected,
      ),
    );
  }
}
