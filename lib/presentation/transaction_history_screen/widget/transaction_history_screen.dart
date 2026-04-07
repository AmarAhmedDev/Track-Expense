import 'package:flutter/services.dart';

import '../../../core/app_export.dart';
import '../../../database/database_helper.dart';
import '../../../models/transaction_model.dart';
import '../../../routes/app_routes.dart';
import './transaction_history_filter_chips_widget.dart';
import './transaction_history_list_widget.dart';
import './transaction_history_search_bar_widget.dart';

/// Transaction History Screen — full scrollable log of all transactions.
/// Features: search, period filters, date-grouped list, swipe-to-delete, sort controls.
class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen>
    with TickerProviderStateMixin {
  // TODO: Replace with Riverpod provider for production
  final DatabaseHelper _db = DatabaseHelper.instance;

  bool _isLoading = true;
  List<TransactionModel> _allTransactions = [];
  List<TransactionModel> _filteredTransactions = [];

  String _searchQuery = '';
  FilterPeriod _selectedFilter = FilterPeriod.all;
  SortOption _selectedSort = SortOption.dateDesc;
  DateTimeRange? _customDateRange;



  late AnimationController _headerController;
  late Animation<double> _headerFadeAnimation;

  @override
  void initState() {
    super.initState();
    _headerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _headerFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _headerController, curve: Curves.easeOutCubic),
    );
    _headerController.forward();
    _loadTransactions();
    DatabaseHelper.instance.onTransactionsChanged.addListener(_loadTransactions);
  }

  @override
  void dispose() {
    DatabaseHelper.instance.onTransactionsChanged.removeListener(_loadTransactions);
    _headerController.dispose();
    super.dispose();
  }

  Future<void> _loadTransactions() async {
    // TODO: Replace with Riverpod stream provider for production
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final transactions = await _db.getAllTransactions();
      if (mounted) {
        setState(() {
          _allTransactions = transactions;
          _isLoading = false;
        });
        _applyFilters();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(
                  "Couldn't load transactions. Pull down to try again.",
                ),
                backgroundColor: AppTheme.error,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          }
        });
      }
    }
  }

  void _applyFilters() {
    // TODO: Replace with Riverpod computed state for production
    List<TransactionModel> result = List.from(_allTransactions);
    final now = DateTime.now();

    // Period filter
    switch (_selectedFilter) {
      case FilterPeriod.today:
        result = result.where((tx) {
          return tx.date.year == now.year &&
              tx.date.month == now.month &&
              tx.date.day == now.day;
        }).toList();
        break;
      case FilterPeriod.week:
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        final weekStartDay = DateTime(
          weekStart.year,
          weekStart.month,
          weekStart.day,
        );
        result = result.where((tx) => tx.date.isAfter(weekStartDay)).toList();
        break;
      case FilterPeriod.month:
        result = result.where((tx) {
          return tx.date.year == now.year && tx.date.month == now.month;
        }).toList();
        break;
      case FilterPeriod.custom:
        if (_customDateRange != null) {
          result = result.where((tx) {
            return tx.date.isAfter(
                  _customDateRange!.start.subtract(const Duration(days: 1)),
                ) &&
                tx.date.isBefore(
                  _customDateRange!.end.add(const Duration(days: 1)),
                );
          }).toList();
        }
        break;
      case FilterPeriod.all:
        break;
    }

    // Search filter
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result.where((tx) {
        return tx.title.toLowerCase().contains(q) ||
            tx.category.toLowerCase().contains(q) ||
            (tx.note?.toLowerCase().contains(q) ?? false);
      }).toList();
    }

    // Sort
    switch (_selectedSort) {
      case SortOption.dateDesc:
        result.sort((a, b) => b.date.compareTo(a.date));
        break;
      case SortOption.dateAsc:
        result.sort((a, b) => a.date.compareTo(b.date));
        break;
      case SortOption.amountDesc:
        result.sort((a, b) => b.amount.compareTo(a.amount));
        break;
      case SortOption.amountAsc:
        result.sort((a, b) => a.amount.compareTo(b.amount));
        break;
    }

    setState(() => _filteredTransactions = result);
  }

  void _onSearchChanged(String query) {
    setState(() => _searchQuery = query);
    _applyFilters();
  }

  void _onFilterChanged(FilterPeriod filter) async {
    HapticFeedback.selectionClick();
    if (filter == FilterPeriod.custom) {
      final range = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2020),
        lastDate: DateTime.now(),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: Theme.of(
                context,
              ).colorScheme.copyWith(primary: AppTheme.primary),
            ),
            child: child!,
          );
        },
      );
      if (range != null) {
        setState(() {
          _customDateRange = range;
          _selectedFilter = FilterPeriod.custom;
        });
        _applyFilters();
      }
      return;
    }
    setState(() => _selectedFilter = filter);
    _applyFilters();
  }

  void _onSortChanged(SortOption sort) {
    HapticFeedback.selectionClick();
    setState(() => _selectedSort = sort);
    _applyFilters();
  }

  Future<void> _deleteTransaction(TransactionModel tx) async {
    HapticFeedback.mediumImpact();
    if (tx.id == null) return;
    await _db.deleteTransaction(tx.id!);
    _loadTransactions();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '${tx.title} deleted',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              InkWell(
                onTap: () async {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  await _db.insertTransaction(tx);
                },
                child: const Text(
                  'Undo',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  void _showSortBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _SortBottomSheet(
        selectedSort: _selectedSort,
        onSortSelected: (sort) {
          Navigator.pop(ctx);
          _onSortChanged(sort);
        },
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width >= 600;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      extendBody: true,
      body: isTablet ? _buildTabletLayout() : _buildPhoneLayout(),
    );
  }

  Widget _buildPhoneLayout() {
    return Column(
      children: [
        // Gradient AppBar
        FadeTransition(
          opacity: _headerFadeAnimation,
          child: _buildGradientHeader(),
        ),
        // Search bar
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: TransactionHistorySearchBarWidget(
            onSearchChanged: _onSearchChanged,
          ),
        ),
        // Filter chips
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: TransactionHistoryFilterChipsWidget(
            selectedFilter: _selectedFilter,
            onFilterChanged: _onFilterChanged,
          ),
        ),
        // Sort + count row
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: _buildSortRow(),
        ),
        const SizedBox(height: 8),
        // Transaction list
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadTransactions,
            color: AppTheme.primary,
            child: TransactionHistoryListWidget(
              transactions: _filteredTransactions,
              isLoading: _isLoading,
              onDelete: _deleteTransaction,
              onAddTransaction: () =>
                  Navigator.pushNamed(context, AppRoutes.addExpenseScreen),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTabletLayout() {
    return Row(
      children: [
        // Left: filters + list
        Expanded(
          flex: 3,
          child: Column(
            children: [
              FadeTransition(
                opacity: _headerFadeAnimation,
                child: _buildGradientHeader(),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: TransactionHistorySearchBarWidget(
                  onSearchChanged: _onSearchChanged,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: TransactionHistoryFilterChipsWidget(
                  selectedFilter: _selectedFilter,
                  onFilterChanged: _onFilterChanged,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                child: _buildSortRow(),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _loadTransactions,
                  color: AppTheme.primary,
                  child: TransactionHistoryListWidget(
                    transactions: _filteredTransactions,
                    isLoading: _isLoading,
                    onDelete: _deleteTransaction,
                    onAddTransaction: () => Navigator.pushNamed(
                      context,
                      AppRoutes.addExpenseScreen,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Right: summary panel on tablet
        Container(
          width: 260,
          margin: const EdgeInsets.fromLTRB(0, 0, 16, 16),
          child: _buildTabletSummaryPanel(),
        ),
      ],
    );
  }

  Widget _buildGradientHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppTheme.headerGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 16, 20),
          child: Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pushNamedAndRemoveUntil(
                  context,
                  AppRoutes.homeScreen,
                  (route) => false,
                ),
                icon: const Icon(
                  Icons.arrow_back_ios_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const Expanded(
                child: Text(
                  'Transaction History',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              // Sort button
              InkWell(
                onTap: _showSortBottomSheet,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(38),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.sort_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSortRow() {
    final theme = Theme.of(context);
    final totalExpense = _filteredTransactions
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (sum, t) => sum + t.amount);
    final totalIncome = _filteredTransactions
        .where((t) => t.type == TransactionType.income)
        .fold(0.0, (sum, t) => sum + t.amount);

    return Row(
      children: [
        Text(
          '${_filteredTransactions.length} transactions',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const Spacer(),
        // Income chip
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.successSurface,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.arrow_downward_rounded,
                size: 12,
                color: AppTheme.income,
              ),
              const SizedBox(width: 3),
              Text(
                '${SettingsService.instance.currentSymbol}${totalIncome.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.income,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        // Expense chip
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.errorSurface,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.arrow_upward_rounded,
                size: 12,
                color: AppTheme.expense,
              ),
              const SizedBox(width: 3),
              Text(
                '${SettingsService.instance.currentSymbol}${totalExpense.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.expense,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTabletSummaryPanel() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final totalExpense = _filteredTransactions
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (sum, t) => sum + t.amount);
    final totalIncome = _filteredTransactions
        .where((t) => t.type == TransactionType.income)
        .fold(0.0, (sum, t) => sum + t.amount);

    // Category breakdown for tablet summary
    final Map<String, double> categoryTotals = {};
    for (final tx in _filteredTransactions.where(
      (t) => t.type == TransactionType.expense,
    )) {
      categoryTotals[tx.category] =
          (categoryTotals[tx.category] ?? 0) + tx.amount;
    }
    final sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topCategories = sortedCategories.take(4).toList();

    return Column(
      children: [
        const SizedBox(height: 120), // Align with content start below header
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(15),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Summary',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              _SummaryRow(
                label: 'Total Income',
                value: '${SettingsService.instance.currentSymbol}${totalIncome.toStringAsFixed(2)}',
                color: AppTheme.income,
              ),
              const SizedBox(height: 8),
              _SummaryRow(
                label: 'Total Expense',
                value: '${SettingsService.instance.currentSymbol}${totalExpense.toStringAsFixed(2)}',
                color: AppTheme.expense,
              ),
              const SizedBox(height: 8),
              _SummaryRow(
                label: 'Net Balance',
                value: '${SettingsService.instance.currentSymbol}${(totalIncome - totalExpense).toStringAsFixed(2)}',
                color: (totalIncome - totalExpense) >= 0
                    ? AppTheme.income
                    : AppTheme.expense,
              ),
              if (topCategories.isNotEmpty) ...[
                const SizedBox(height: 20),
                Text(
                  'Top Categories',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withAlpha(153),
                  ),
                ),
                const SizedBox(height: 12),
                ...topCategories.map((entry) {
                  final pct = totalExpense > 0
                      ? (entry.value / totalExpense * 100)
                      : 0.0;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                entry.key,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 12,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              '${pct.toStringAsFixed(0)}%',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            value: pct / 100,
                            minHeight: 6,
                            backgroundColor:
                                theme.colorScheme.surfaceContainerHighest,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              AppTheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryRow({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: theme.textTheme.bodyMedium),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: color,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

/// Sort bottom sheet modal
class _SortBottomSheet extends StatelessWidget {
  final SortOption selectedSort;
  final Function(SortOption) onSortSelected;

  const _SortBottomSheet({
    required this.selectedSort,
    required this.onSortSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outline.withAlpha(102),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Sort By',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          ...SortOption.values.map((option) {
            final isSelected = selectedSort == option;
            return InkWell(
              onTap: () => onSortSelected(option),
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.primaryMuted
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      _sortIcon(option),
                      size: 20,
                      color: isSelected
                          ? AppTheme.primary
                          : theme.colorScheme.outline,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _sortLabel(option),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w400,
                          color: isSelected
                              ? AppTheme.primary
                              : theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                    if (isSelected)
                      const Icon(
                        Icons.check_rounded,
                        size: 18,
                        color: AppTheme.primary,
                      ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  IconData _sortIcon(SortOption option) {
    switch (option) {
      case SortOption.dateDesc:
        return Icons.calendar_today_rounded;
      case SortOption.dateAsc:
        return Icons.calendar_today_outlined;
      case SortOption.amountDesc:
        return Icons.arrow_downward_rounded;
      case SortOption.amountAsc:
        return Icons.arrow_upward_rounded;
    }
  }

  String _sortLabel(SortOption option) {
    switch (option) {
      case SortOption.dateDesc:
        return 'Newest First';
      case SortOption.dateAsc:
        return 'Oldest First';
      case SortOption.amountDesc:
        return 'Highest Amount';
      case SortOption.amountAsc:
        return 'Lowest Amount';
    }
  }
}

enum FilterPeriod { all, today, week, month, custom }

enum SortOption { dateDesc, dateAsc, amountDesc, amountAsc }
