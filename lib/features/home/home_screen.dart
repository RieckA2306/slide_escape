import 'package:flutter/material.dart';
// Import the specific screens for each tab
import '../home/shop/shop_screen.dart';
import '../home/level_map/level_map_screen.dart';
import '../home/leaderboard/leaderboard_screen.dart';
import '../home/widgets/app_footer.dart'; // Import the custom footer widget

/// The main screen that holds the navigation and the different pages (Shop, Map, Leaderboard).
/// It uses a StatefulWidget to manage the currently active tab and page.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Controller for the PageView, starting at index 1 (the Map).
  final PageController _pageController = PageController(initialPage: 1);

  // Tracks the currently active tab in the bottom navigation bar.
  FooterTab _activeTab = FooterTab.map;

  /// Handles tap events on the bottom navigation footer.
  /// It maps the selected tab to a specific page index and animates to that page.
  void _onTabSelected(FooterTab tab) {
    // Map the enum value to the corresponding integer index for the PageView.
    final index = {
      FooterTab.shop: 0,
      FooterTab.map: 1,
      FooterTab.leaderboard: 2,
    }[tab]!;

    // Update the state to highlight the selected tab in the UI.
    setState(() => _activeTab = tab);

    // Smoothly animate the PageView to the selected page.
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut, // Smooth acceleration and deceleration
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // The body contains the swipeable pages.
      body: PageView(
        controller: _pageController,
        // Callback when the user swipes to a new page.
        // We need to sync the footer tab with the new page index.
        onPageChanged: (index) {
          setState(() {
            _activeTab =
            [FooterTab.shop, FooterTab.map, FooterTab.leaderboard][index];
          });
        },
        // The list of screens to display in the PageView.
        children: const [
          ShopScreen(),        // Index 0
          LevelMapScreen(),    // Index 1
          LeaderboardScreen(), // Index 2
        ],
      ),
      // The custom bottom navigation bar widget.
      bottomNavigationBar: AppFooter(
        activeTab: _activeTab,      // Pass the current tab to highlight it
        onTabSelected: _onTabSelected, // Pass the callback to handle taps
      ),
    );
  }
}