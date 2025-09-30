import 'package:flutter/material.dart';
import '../../widgets/app_footer.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          "Hier kommt später das Leaderboard",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
      bottomNavigationBar: AppFooter(activeTab: FooterTab.leaderboard),
    );
  }
}
