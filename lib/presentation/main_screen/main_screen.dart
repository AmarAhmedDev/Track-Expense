import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/app_export.dart';
import '../../routes/app_routes.dart';
import '../home_screen/home_screen.dart';
import '../transaction_history_screen/widget/transaction_history_screen.dart';
import '../analytics_screen/analytics_screen.dart';
import '../settings_screen/settings_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late PageController _pageController;
  int _currentNavIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNavTap(int index) {
    if (index == 2) {
      HapticFeedback.lightImpact();
      Navigator.pushNamed(context, AppRoutes.addExpenseScreen);
      return;
    }
    
    // Map nav index (0,1,3,4) to page index (0,1,2,3)
    int pageIndex = index > 2 ? index - 1 : index;
    
    _pageController.animateToPage(
      pageIndex,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: PageView(
        controller: _pageController,
        onPageChanged: (pageIndex) {
          int navIndex = pageIndex >= 2 ? pageIndex + 1 : pageIndex;
          setState(() {
             _currentNavIndex = navIndex;
          });
        },
        physics: const BouncingScrollPhysics(),
        children: const [
          HomeScreen(),
          TransactionHistoryScreen(),
          AnalyticsScreen(),
          SettingsScreen(),
        ],
      ),
      bottomNavigationBar: AppNavigation(
        currentIndex: _currentNavIndex,
        onTap: _onNavTap,
      ),
    );
  }
}
