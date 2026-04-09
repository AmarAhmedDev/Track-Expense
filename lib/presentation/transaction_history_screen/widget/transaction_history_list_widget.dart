import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../core/app_export.dart';
import '../../../models/transaction_model.dart';

/// Full transaction list with date-grouped sections and swipe-to-delete.
/// Staggered entrance animation per item on load.
class TransactionHistoryListWidget extends StatefulWidget {
  final List<TransactionModel> transactions;
  final bool isLoading;
  final Function(TransactionModel) onDelete;
  final VoidCallback onAddTransaction;

  const TransactionHistoryListWidget({
    super.key,
    required this.transactions,
    required this.isLoading,
    required this.onDelete,
    required this.onAddTransaction,
  });

  @override
  State<TransactionHistoryListWidget> createState() =>
      _TransactionHistoryListWidgetState();
}

class _TransactionHistoryListWidgetState
    extends State<TransactionHistoryListWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _listController;

  @override
  void initState() {
    super.initState();
    _listController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    if (!widget.isLoading) _listController.forward();
  }

  @override
  void didUpdateWidget(TransactionHistoryListWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.isLoading && oldWidget.isLoading) {
      _listController.forward(from: 0);
    } else if (widget.transactions != oldWidget.transactions) {
      _listController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _listController.dispose();
    super.dispose();
  }

  /// Groups transactions by calendar date for sticky section headers
  Map<String, List<TransactionModel>> _groupByDate(
    List<TransactionModel> transactions,
  ) {
    final Map<String, List<TransactionModel>> groups = {};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    for (final tx in transactions) {
      final txDay = DateTime(tx.date.year, tx.date.month, tx.date.day);
      String label;
      if (txDay == today) {
        label = 'Today';
      } else if (txDay == yesterday) {
        label = 'Yesterday';
      } else {
        label = DateFormat('EEEE, MMM d').format(tx.date);
      }
      groups.putIfAbsent(label, () => []).add(tx);
    }
    return groups;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: TransactionSkeletonList(itemCount: 8),
      );
    }

    if (widget.transactions.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.receipt_long_outlined,
        title: 'No transactions found',
        subtitle:
            'No transactions match your current filters. Try adjusting the search or period.',
        actionLabel: 'Add Transaction',
        onAction: widget.onAddTransaction,
      );
    }

    final grouped = _groupByDate(widget.transactions);
    final groupKeys = grouped.keys.toList();

    // Build flat list of items (headers + transaction items) for animation indexing
    final List<_ListItem> flatItems = [];
    for (final key in groupKeys) {
      flatItems.add(_ListItem.header(key));
      for (final tx in grouped[key]!) {
        flatItems.add(_ListItem.transaction(tx));
      }
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 120),
      itemCount: flatItems.length,
      itemBuilder: (context, index) {
        final item = flatItems[index];
        // Stagger: max delay 400ms total across first 10 items
        final animDelay = (index * 0.04).clamp(0.0, 0.7);
        final animEnd = (animDelay + 0.35).clamp(0.0, 1.0);
        final itemAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _listController,
            curve: Interval(animDelay, animEnd, curve: Curves.easeOutCubic),
          ),
        );

        if (item.isHeader) {
          return FadeTransition(
            opacity: itemAnim,
            child: _DateSectionHeader(label: item.headerLabel!),
          );
        }

        return FadeTransition(
          opacity: itemAnim,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.05, 0),
              end: Offset.zero,
            ).animate(itemAnim),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _HistoryTransactionItem(
                transaction: item.transaction!,
                onDelete: () => widget.onDelete(item.transaction!),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Sticky-style date section header
class _DateSectionHeader extends StatelessWidget {
  final String label;
  const _DateSectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 10),
      child: Row(
        children: [
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              height: 1,
              color: theme.colorScheme.outlineVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Individual transaction list item with swipe-to-delete (Dismissible V4).
class _HistoryTransactionItem extends StatelessWidget {
  final TransactionModel transaction;
  final VoidCallback onDelete;

  const _HistoryTransactionItem({
    required this.transaction,
    required this.onDelete,
  });

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isExpense = transaction.type == TransactionType.expense;
    final amountColor = isExpense ? AppTheme.expense : AppTheme.income;
    final amountPrefix = isExpense ? '-' : '+';
    final settings = SettingsService.instance;
    final timeFormat = DateFormat('h:mm a');

    Color categoryColor = AppTheme.primary;
    try {
      final hex = transaction.categoryColor.replaceFirst('#', '');
      categoryColor = Color(int.parse('FF$hex', radix: 16));
    } catch (_) {}

    return Dismissible(
      key: Key('history_tx_${transaction.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: AppTheme.errorSurface,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.delete_outline_rounded,
              color: AppTheme.error,
              size: 22,
            ),
            const SizedBox(height: 4),
            const Text(
              'Delete',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppTheme.error,
              ),
            ),
          ],
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
            content: Text(
              'Are you sure you want to delete "${transaction.title}"? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.error,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) {
        HapticFeedback.mediumImpact();
        onDelete();
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(18),
          // Left accent border for expense vs income
          border: Border(left: BorderSide(color: amountColor, width: 3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(10),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Category icon
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: categoryColor.withAlpha(26),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                _iconFromName(transaction.categoryIcon),
                color: categoryColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            // Title + category + note
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
                      if (transaction.note != null &&
                          transaction.note!.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Icon(
                          Icons.notes_rounded,
                          size: 12,
                          color: theme.colorScheme.outline,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Amount + time
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$amountPrefix${settings.formatAmount(transaction.amount)}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: amountColor,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  timeFormat.format(transaction.date),
                  style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Helper class for flat list rendering
class _ListItem {
  final bool isHeader;
  final String? headerLabel;
  final TransactionModel? transaction;

  const _ListItem.header(String label)
    : isHeader = true,
      headerLabel = label,
      transaction = null;

  const _ListItem.transaction(TransactionModel tx)
    : isHeader = false,
      headerLabel = null,
      transaction = tx;
}
