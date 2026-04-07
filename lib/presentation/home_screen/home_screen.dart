

import '../../core/app_export.dart';
import '../../database/database_helper.dart';
import '../../models/transaction_model.dart';
import '../../routes/app_routes.dart';
import './widget/home_budget_progress_widget.dart';
import './widget/home_header_widget.dart';
import './widget/home_kpi_cards_widget.dart';
import './widget/home_recent_transactions_widget.dart';

/// Home Screen — Dashboard entry point for SmartExpenseTracker.
/// Shows greeting, KPI summary cards, budget progress, and recent transactions.
/// Floating pill FAB triggers the Add Expense flow.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // TODO: Replace with Riverpod provider for production
  final DatabaseHelper _db = DatabaseHelper.instance;

  bool _isLoading = true;
  double _totalIncome = 0;
  double _totalExpense = 0;
  double _budgetLimit = 1500;
  List<TransactionModel> _recentTransactions = [];



  @override
  void initState() {
    super.initState();
    _loadData();
    DatabaseHelper.instance.onTransactionsChanged.addListener(_loadData);
  }

  @override
  void dispose() {
    DatabaseHelper.instance.onTransactionsChanged.removeListener(_loadData);
    super.dispose();
  }

  Future<void> _loadData() async {
    // TODO: Replace with Riverpod stream provider for production
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final now = DateTime.now();
      final income = await _db.getTotalByType(
        TransactionType.income,
        month: now,
      );
      final expense = await _db.getTotalByType(
        TransactionType.expense,
        month: now,
      );
      final budget = await _db.getCurrentBudget();
      final all = await _db.getAllTransactions();

      if (mounted) {
        setState(() {
          _totalIncome = income;
          _totalExpense = expense;
          _budgetLimit = budget?.monthlyLimit ?? 1500;
          _recentTransactions = all.take(5).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Couldn't load data. Pull down to try again."),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }



  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width >= 600;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      extendBody: true, // Allows content to flow under floating nav bar
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: AppTheme.primary,
        displacement: 60,
        child: isTablet ? _buildTabletLayout() : _buildPhoneLayout(),
      ),
    );
  }

  Widget _buildPhoneLayout() {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        // Gradient header with greeting + balance
        SliverToBoxAdapter(
          child: HomeHeaderWidget(
            totalIncome: _totalIncome,
            totalExpense: _totalExpense,
            isLoading: _isLoading,
          ),
        ),
        // KPI metric cards row
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: HomeKpiCardsWidget(
              totalIncome: _totalIncome,
              totalExpense: _totalExpense,
              isLoading: _isLoading,
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 20)),
        // Budget progress strip
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: HomeBudgetProgressWidget(
              spent: _totalExpense,
              limit: _budgetLimit,
              isLoading: _isLoading,
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 20)),
        // Recent transactions section
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: HomeRecentTransactionsWidget(
              transactions: _recentTransactions,
              isLoading: _isLoading,
              onViewAll: () => Navigator.pushNamed(
                context,
                AppRoutes.transactionHistoryScreen,
              ),
              onTransactionDeleted: _loadData,
            ),
          ),
        ),
        // Bottom padding for floating nav bar
        const SliverToBoxAdapter(child: SizedBox(height: 120)),
      ],
    );
  }

  Widget _buildTabletLayout() {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: HomeHeaderWidget(
            totalIncome: _totalIncome,
            totalExpense: _totalExpense,
            isLoading: _isLoading,
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left column — main content
                Expanded(
                  flex: 3,
                  child: Column(
                    children: [
                      HomeKpiCardsWidget(
                        totalIncome: _totalIncome,
                        totalExpense: _totalExpense,
                        isLoading: _isLoading,
                      ),
                      const SizedBox(height: 20),
                      HomeRecentTransactionsWidget(
                        transactions: _recentTransactions,
                        isLoading: _isLoading,
                        onViewAll: () => Navigator.pushNamed(
                          context,
                          AppRoutes.transactionHistoryScreen,
                        ),
                        onTransactionDeleted: _loadData,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                // Right column — budget sidebar
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: HomeBudgetProgressWidget(
                      spent: _totalExpense,
                      limit: _budgetLimit,
                      isLoading: _isLoading,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 120)),
      ],
    );
  }

}
