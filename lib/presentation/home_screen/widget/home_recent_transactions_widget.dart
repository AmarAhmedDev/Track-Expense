import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../core/app_export.dart';
import '../../../database/database_helper.dart';
import '../../../models/transaction_model.dart';

/// Recent transactions section — last 5 transactions with swipe-to-delete.
/// Uses staggered entrance animation for list items.
class HomeRecentTransactionsWidget extends StatefulWidget {
  final List<TransactionModel> transactions;
  final bool isLoading;
  final VoidCallback onViewAll;
  final VoidCallback onTransactionDeleted;

  const HomeRecentTransactionsWidget({
    super.key,
    required this.transactions,
    required this.isLoading,
    required this.onViewAll,
    required this.onTransactionDeleted,
  });

  @override
  State<HomeRecentTransactionsWidget> createState() =>
      _HomeRecentTransactionsWidgetState();
}

class _HomeRecentTransactionsWidgetState
    extends State<HomeRecentTransactionsWidget>
    with TickerProviderStateMixin {
  late AnimationController _listController;
  late List<Animation<double>> _itemAnimations;

  @override
  void initState() {
    super.initState();
    _listController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _buildAnimations();
    if (!widget.isLoading) _listController.forward();
  }

  void _buildAnimations() {
    final count = widget.transactions.isEmpty ? 5 : widget.transactions.length;
    _itemAnimations = List.generate(count, (i) {
      final start = (i * 0.1).clamp(0.0, 0.8);
      final end = (start + 0.4).clamp(0.0, 1.0);
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _listController,
          curve: Interval(start, end, curve: Curves.easeOutCubic),
        ),
      );
    });
  }

  @override
  void didUpdateWidget(HomeRecentTransactionsWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.isLoading && oldWidget.isLoading) {
      _buildAnimations();
      _listController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _listController.dispose();
    super.dispose();
  }

  Future<void> _deleteTransaction(TransactionModel tx) async {
    HapticFeedback.mediumImpact();
    if (tx.id == null) return;
    await DatabaseHelper.instance.deleteTransaction(tx.id!);
    widget.onTransactionDeleted();
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
                  await DatabaseHelper.instance.insertTransaction(tx);
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Transactions',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            TextButton(
              onPressed: widget.onViewAll,
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.primary,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
              child: const Text(
                'View All',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (widget.isLoading)
          const TransactionSkeletonList(itemCount: 5)
        else if (widget.transactions.isEmpty)
          EmptyStateWidget(
            icon: Icons.receipt_long_outlined,
            title: 'No transactions yet',
            subtitle: 'Start by adding your first expense or income.',
            actionLabel: 'Add Transaction',
            onAction: () {
              Navigator.pushNamed(context, '/add-expense-screen');
            },
          )
        else
          ListView.separated(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: widget.transactions.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final tx = widget.transactions[index];
              final animIndex = index.clamp(0, _itemAnimations.length - 1);
              return FadeTransition(
                opacity: _itemAnimations[animIndex],
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.06, 0),
                    end: Offset.zero,
                  ).animate(_itemAnimations[animIndex]),
                  child: _TransactionListItem(
                    transaction: tx,
                    onDelete: () => _deleteTransaction(tx),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}

class _TransactionListItem extends StatelessWidget {
  final TransactionModel transaction;
  final VoidCallback onDelete;

  const _TransactionListItem({
    required this.transaction,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isExpense = transaction.type == TransactionType.expense;
    final amountColor = isExpense ? AppTheme.expense : AppTheme.income;
    final amountPrefix = isExpense ? '-' : '+';
    final currencyFormat = NumberFormat.currency(
      symbol: SettingsService.instance.currentSymbol,
      decimalDigits: 2,
    );
    final dateFormat = DateFormat('MMM d');

    // Parse category color
    Color categoryColor = AppTheme.primary;
    try {
      final hex = transaction.categoryColor.replaceFirst('#', '');
      categoryColor = Color(int.parse('FF$hex', radix: 16));
    } catch (_) {}

    return Dismissible(
      key: Key('tx_${transaction.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppTheme.errorSurface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(
          Icons.delete_outline_rounded,
          color: AppTheme.error,
          size: 24,
        ),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text('Delete Transaction'),
            content: Text('Remove "${transaction.title}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.error,
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) => onDelete(),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(10),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Category icon container
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: categoryColor.withAlpha(31),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                _iconFromName(transaction.categoryIcon),
                color: categoryColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            // Title + category
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.title,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: categoryColor.withAlpha(26),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          transaction.category,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: categoryColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        dateFormat.format(transaction.date),
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Amount
            Text(
              '$amountPrefix${currencyFormat.format(transaction.amount)}',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: amountColor,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconFromName(String name) {
    const iconMap = {
      'restaurant': Icons.restaurant_rounded,
      'directions_car': Icons.directions_car_rounded,
      'shopping_bag': Icons.shopping_bag_rounded,
      'receipt': Icons.receipt_rounded,
      'favorite': Icons.favorite_rounded,
      'school': Icons.school_rounded,
      'movie': Icons.movie_rounded,
      'more_horiz': Icons.more_horiz_rounded,
      'attach_money': Icons.attach_money_rounded,
      'home': Icons.home_rounded,
    };
    return iconMap[name] ?? Icons.category_rounded;
  }
}
