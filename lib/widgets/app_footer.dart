import 'package:flutter/material.dart';

/// Enum für die Tabs im Footer
enum FooterTab { shop, map, leaderboard }

/// Footer mit drei Tabs (Shop, Map, Leaderboard).
/// Funktioniert zusammen mit einem PageView im HomeScreen.
/// Navigation läuft über den Callback [onTabSelected].
class AppFooter extends StatelessWidget {
  final FooterTab activeTab;
  final Function(FooterTab) onTabSelected;

  const AppFooter({
    super.key,
    required this.activeTab,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      height: 80,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildTab("Shop", FooterTab.shop),
          _buildTab("Map", FooterTab.map),
          _buildTab("Leaderboard", FooterTab.leaderboard),
        ],
      ),
    );
  }

  /// Baut einen einzelnen Tab-Button
  Widget _buildTab(String label, FooterTab tab) {
    final isActive = activeTab == tab;
    return Expanded(
      child: InkWell(
        onTap: () => onTabSelected(tab),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: isActive ? Colors.blue : Colors.black,
            ),
          ),
        ),
      ),
    );
  }
}
