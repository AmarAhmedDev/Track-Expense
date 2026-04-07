import 'package:intl/intl.dart';

import '../../../core/app_export.dart';

/// KPI row — Income and Expense cards with gradient accent styling.
/// Family D, Card V4: Gradient Accent with left border + background tint.
class HomeKpiCardsWidget extends StatefulWidget {
  final double totalIncome;
  final double totalExpense;
  final bool isLoading;

  const HomeKpiCardsWidget({
    super.key,
    required this.totalIncome,
    required this.totalExpense,
    required this.isLoading,
  });

  @override
  State<HomeKpiCardsWidget> createState() => _HomeKpiCardsWidgetState();
}

class _HomeKpiCardsWidgetState extends State<HomeKpiCardsWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Animation<double>> _cardAnimations;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _cardAnimations = List.generate(2, (i) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(i * 0.15, 0.6 + i * 0.15, curve: Curves.easeOutBack),
        ),
      );
    });
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: FadeTransition(
            opacity: _cardAnimations[0],
            child: ScaleTransition(
              scale: _cardAnimations[0],
              child: _KpiCard(
                title: 'Income',
                amount: widget.totalIncome,
                icon: Icons.arrow_downward_rounded,
                gradient: AppTheme.incomeGradient,
                accentColor: AppTheme.income,
                isLoading: widget.isLoading,
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: FadeTransition(
            opacity: _cardAnimations[1],
            child: ScaleTransition(
              scale: _cardAnimations[1],
              child: _KpiCard(
                title: 'Expenses',
                amount: widget.totalExpense,
                icon: Icons.arrow_upward_rounded,
                gradient: AppTheme.expenseGradient,
                accentColor: AppTheme.expense,
                isLoading: widget.isLoading,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String title;
  final double amount;
  final IconData icon;
  final LinearGradient gradient;
  final Color accentColor;
  final bool isLoading;

  const _KpiCard({
    required this.title,
    required this.amount,
    required this.icon,
    required this.gradient,
    required this.accentColor,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currencyFormat = NumberFormat.currency(
      symbol: SettingsService.instance.currentSymbol,
      decimalDigits: 2,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border(left: BorderSide(color: accentColor, width: 4)),
        boxShadow: [
          BoxShadow(
            color: accentColor.withAlpha(31),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withAlpha(153),
                ),
              ),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Colors.white, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 10),
          isLoading
              ? const LoadingSkeletonWidget(
                  height: 22,
                  width: 100,
                  borderRadius: 6,
                )
              : TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: amount),
                  duration: const Duration(milliseconds: 900),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, _) {
                    return Text(
                      currencyFormat.format(value),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: accentColor,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    );
                  },
                ),
          const SizedBox(height: 4),
          Text(
            'This month',
            style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
          ),
        ],
      ),
    );
  }
}
