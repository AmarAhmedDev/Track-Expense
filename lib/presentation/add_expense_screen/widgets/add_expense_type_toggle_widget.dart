import 'package:flutter/services.dart';

import '../../../core/app_export.dart';
import '../../../models/transaction_model.dart';

/// Animated income/expense type toggle.
/// Sliding indicator moves between the two options with spring animation.
class AddExpenseTypeToggleWidget extends StatelessWidget {
  final TransactionType selectedType;
  final Function(TransactionType) onTypeChanged;

  const AddExpenseTypeToggleWidget({
    super.key,
    required this.selectedType,
    required this.onTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isExpense = selectedType == TransactionType.expense;

    return Container(
      height: 52,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark
            ? AppTheme.surfaceVariantDark
            : AppTheme.surfaceVariantLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppTheme.outlineDark : AppTheme.outlineLight,
        ),
      ),
      child: Stack(
        children: [
          // Animated sliding indicator
          AnimatedAlign(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            alignment: isExpense ? Alignment.centerRight : Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              child: Container(
                decoration: BoxDecoration(
                  gradient: isExpense
                      ? AppTheme.expenseGradient
                      : AppTheme.incomeGradient,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: (isExpense ? AppTheme.expense : AppTheme.income)
                          .withAlpha(77),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Tap targets
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onTypeChanged(TransactionType.income);
                  },
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            Icons.arrow_downward_rounded,
                            key: ValueKey(!isExpense),
                            size: 16,
                            color: !isExpense
                                ? Colors.white
                                : theme.colorScheme.outline,
                          ),
                        ),
                        const SizedBox(width: 6),
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: !isExpense
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: !isExpense
                                ? Colors.white
                                : theme.colorScheme.outline,
                          ),
                          child: const Text('Income'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: InkWell(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onTypeChanged(TransactionType.expense);
                  },
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            Icons.arrow_upward_rounded,
                            key: ValueKey(isExpense),
                            size: 16,
                            color: isExpense
                                ? Colors.white
                                : theme.colorScheme.outline,
                          ),
                        ),
                        const SizedBox(width: 6),
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isExpense
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: isExpense
                                ? Colors.white
                                : theme.colorScheme.outline,
                          ),
                          child: const Text('Expense'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
