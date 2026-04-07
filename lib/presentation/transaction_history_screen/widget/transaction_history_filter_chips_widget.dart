
import '../../../core/app_export.dart';
import 'transaction_history_screen.dart';

/// Horizontal scrollable filter chip row for period filtering.
/// Active chip shows gradient fill with white text.
class TransactionHistoryFilterChipsWidget extends StatelessWidget {
  final FilterPeriod selectedFilter;
  final Function(FilterPeriod) onFilterChanged;

  const TransactionHistoryFilterChipsWidget({
    super.key,
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  static const List<_FilterChipData> _filters = [
    _FilterChipData(
      label: 'All',
      period: FilterPeriod.all,
      icon: Icons.list_rounded,
    ),
    _FilterChipData(
      label: 'Today',
      period: FilterPeriod.today,
      icon: Icons.today_rounded,
    ),
    _FilterChipData(
      label: 'This Week',
      period: FilterPeriod.week,
      icon: Icons.date_range_outlined,
    ),
    _FilterChipData(
      label: 'This Month',
      period: FilterPeriod.month,
      icon: Icons.calendar_month_outlined,
    ),
    _FilterChipData(
      label: 'Custom Range',
      period: FilterPeriod.custom,
      icon: Icons.tune_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final isSelected = selectedFilter == filter.period;
          return _FilterChipItem(
            data: filter,
            isSelected: isSelected,
            onTap: () => onFilterChanged(filter.period),
          );
        },
      ),
    );
  }
}

class _FilterChipItem extends StatefulWidget {
  final _FilterChipData data;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChipItem({
    required this.data,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_FilterChipItem> createState() => _FilterChipItemState();
}

class _FilterChipItemState extends State<_FilterChipItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scaleAnim = Tween<double>(
      begin: 1.0,
      end: 0.93,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnim,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            gradient: widget.isSelected ? AppTheme.primaryGradient : null,
            color: widget.isSelected
                ? null
                : isDark
                ? AppTheme.surfaceVariantDark
                : Colors.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: widget.isSelected
                  ? Colors.transparent
                  : isDark
                  ? AppTheme.outlineDark
                  : AppTheme.outlineLight,
            ),
            boxShadow: widget.isSelected
                ? [
                    BoxShadow(
                      color: AppTheme.primary.withAlpha(77),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.data.icon,
                size: 14,
                color: widget.isSelected
                    ? Colors.white
                    : theme.colorScheme.outline,
              ),
              const SizedBox(width: 5),
              Text(
                widget.data.label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: widget.isSelected
                      ? FontWeight.w700
                      : FontWeight.w500,
                  color: widget.isSelected
                      ? Colors.white
                      : theme.colorScheme.onSurface.withAlpha(179),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterChipData {
  final String label;
  final FilterPeriod period;
  final IconData icon;

  const _FilterChipData({
    required this.label,
    required this.period,
    required this.icon,
  });
}
