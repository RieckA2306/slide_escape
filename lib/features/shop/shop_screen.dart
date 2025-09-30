import 'package:flutter/material.dart';
import '../../widgets/app_footer.dart';

class ShopScreen extends StatelessWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          "Hier kommt später der Shop",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
      bottomNavigationBar: AppFooter(activeTab: FooterTab.shop),
    );
  }
}
