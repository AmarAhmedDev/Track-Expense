import 'package:intl/intl.dart';

import '../../../core/app_export.dart';

/// Budget progress indicator card.
/// Shows spending vs limit with color-coded warning states:
/// 0-79%: Primary blue, 80-99%: Warning amber, 100%+: Error red
class HomeBudgetProgressWidget extends StatefulWidget {
  final double spent;
  final double limit;
  final bool isLoading;

  const HomeBudgetProgressWidget({
    super.key,
    required this.spent,
    required this.limit,
    required this.isLoading,
  });

  @override
  State<HomeBudgetProgressWidget> createState() =>
      _HomeBudgetProgressWidgetState();
}

class _HomeBudgetProgressWidgetState extends State<HomeBudgetProgressWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeOutCubic),
    );
    if (!widget.isLoading) _progressController.forward();
  }

  @override
  void didUpdateWidget(HomeBudgetProgressWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.isLoading && oldWidget.isLoading) {
      _progressController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  Color _getProgressColor(double percentage) {
    if (percentage >= 1.0) return AppTheme.error;
    if (percentage >= 0.8) return AppTheme.warning;
    return AppTheme.primary;
  }

  String _getStatusText(double percentage) {
    if (percentage >= 1.0) return '🚨 Budget exceeded!';
    if (percentage >= 0.8) return '⚠️ Approaching limit';
    return '✅ On track';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currencyFormat = NumberFormat.currency(
      symbol: SettingsService.instance.currentSymbol,
      decimalDigits: 0,
    );
    final rawPercentage = widget.limit > 0
        ? (widget.spent / widget.limit).clamp(0.0, 1.5)
        : 0.0;
    final displayPercentage = rawPercentage.clamp(0.0, 1.0);
    final progressColor = _getProgressColor(rawPercentage);

    return Container(
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
      child: widget.isLoading
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const LoadingSkeletonWidget(
                  height: 16,
                  width: 120,
                  borderRadius: 6,
                ),
                const SizedBox(height: 12),
                const LoadingSkeletonWidget(height: 12, borderRadius: 6),
                const SizedBox(height: 8),
                const LoadingSkeletonWidget(
                  height: 10,
                  width: 160,
                  borderRadius: 6,
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Monthly Budget',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: progressColor.withAlpha(26),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        _getStatusText(rawPercentage),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: progressColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Animated progress bar
                AnimatedBuilder(
                  animation: _progressAnimation,
                  builder: (context, child) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: displayPercentage * _progressAnimation.value,
                        minHeight: 10,
                        backgroundColor:
                            theme.colorScheme.surfaceContainerHighest,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          progressColor,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${currencyFormat.format(widget.spent)} spent',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    Text(
                      'Limit: ${currencyFormat.format(widget.limit)}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${(displayPercentage * 100).toStringAsFixed(1)}% of budget used',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: progressColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
    );
  }
}
