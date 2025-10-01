import 'package:flutter/material.dart';

/// Enum für die Tabs im Footer
enum FooterTab { shop, map, leaderboard }

class AppFooter extends StatelessWidget {
  final FooterTab activeTab;
  final Function(FooterTab) onTabSelected;

  /// Colors
  final Color backgroundColor;
  final Color activeBackgroundColor;

  const AppFooter({
    super.key,
    required this.activeTab,
    required this.onTabSelected,
    this.backgroundColor = const Color(0xFFF1CCE6),      // Weiß  #F7B4E3
    this.activeBackgroundColor = const Color(0xFFF1AADC) // Rot standard
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor,
      height: 90,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildTab("Shop", "assets/app_footer/shop.png", FooterTab.shop),
          _buildTab("Map", "assets/app_footer/map.png", FooterTab.map),
          _buildTab("Leaderboard", "assets/app_footer/leaderboard.png", FooterTab.leaderboard),
        ],
      ),
    );
  }


  /// Baut einen einzelnen Tab-Button
  Widget _buildTab(String label, String assetPath, FooterTab tab) {
    final isActive = activeTab == tab;

    return Expanded(
      child: InkWell(
        onTap: () => onTabSelected(tab),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          margin: EdgeInsets.only(bottom: isActive ? 8 : 0),
          decoration: BoxDecoration(
            color: isActive ? activeBackgroundColor : backgroundColor,
            borderRadius: BorderRadius.circular(0),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                assetPath,
                width: 48,
                height: 48,
              ),
              if (isActive) ...[
                const SizedBox(height: 4),
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: Colors.black,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
