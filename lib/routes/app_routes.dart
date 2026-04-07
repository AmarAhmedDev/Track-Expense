import 'package:flutter/material.dart';
import '../presentation/home_screen/home_screen.dart';
import '../presentation/main_screen/main_screen.dart';
import '../presentation/add_expense_screen/add_expense_screen.dart';
import '../presentation/transaction_history_screen/widget/transaction_history_screen.dart';
import '../presentation/analytics_screen/analytics_screen.dart';
import '../presentation/settings_screen/settings_screen.dart';

/// Centralized route registry for SmartExpenseTracker.
/// All navigation uses pushNamed — never direct widget instantiation.
class AppRoutes {
  static const String initial = '/';
  static const String homeScreen = '/home-screen';
  static const String addExpenseScreen = '/add-expense-screen';
  static const String transactionHistoryScreen = '/transaction-history-screen';
  static const String analyticsScreen = '/analytics-screen';
  static const String settingsScreen = '/settings-screen';

  static Map<String, WidgetBuilder> routes = {
    initial: (context) => const MainScreen(),
    homeScreen: (context) => const HomeScreen(),
    addExpenseScreen: (context) => const AddExpenseScreen(),
    transactionHistoryScreen: (context) => const TransactionHistoryScreen(),
    analyticsScreen: (context) => const AnalyticsScreen(),
    settingsScreen: (context) => const SettingsScreen(),
  };
}
