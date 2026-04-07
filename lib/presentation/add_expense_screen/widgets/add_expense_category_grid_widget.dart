import 'package:flutter/services.dart';

import '../../../core/app_export.dart';

/// Animated category icon grid — 8 categories in a 4-column layout.
/// Selected category shows filled container with gradient glow.
class AddExpenseCategoryGridWidget extends StatelessWidget {
  final String selectedCategory;
  final Function(String name, String icon, String color) onCategorySelected;

  const AddExpenseCategoryGridWidget({
    super.key,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  static const List<_CategoryOption> _categories = [
    _CategoryOption(
      name: 'Food & Dining',
      icon: Icons.restaurant_rounded,
      iconName: 'restaurant',
      color: Color(0xFFF97316),
      colorHex: '#F97316',
    ),
    _CategoryOption(
      name: 'Transport',
      icon: Icons.directions_car_rounded,
      iconName: 'directions_car',
      color: Color(0xFF3B82F6),
      colorHex: '#3B82F6',
    ),
    _CategoryOption(
      name: 'Shopping',
      icon: Icons.shopping_bag_rounded,
      iconName: 'shopping_bag',
      color: Color(0xFFEC4899),
      colorHex: '#EC4899',
    ),
    _CategoryOption(
      name: 'Bills',
      icon: Icons.receipt_rounded,
      iconName: 'receipt',
      color: Color(0xFF8B5CF6),
      colorHex: '#8B5CF6',
    ),
    _CategoryOption(
      name: 'Health',
      icon: Icons.favorite_rounded,
      iconName: 'favorite',
      color: Color(0xFFEF4444),
      colorHex: '#EF4444',
    ),
    _CategoryOption(
      name: 'Education',
      icon: Icons.school_rounded,
      iconName: 'school',
      color: Color(0xFF10B981),
      colorHex: '#10B981',
    ),
    _CategoryOption(
      name: 'Entertainment',
      icon: Icons.movie_rounded,
      iconName: 'movie',
      color: Color(0xFFF59E0B),
      colorHex: '#F59E0B',
    ),
    _CategoryOption(
      name: 'Other',
      icon: Icons.more_horiz_rounded,
      iconName: 'more_horiz',
      color: Color(0xFF6B7280),
      colorHex: '#6B7280',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category',
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.8,
          ),
          itemCount: _categories.length,
          itemBuilder: (context, index) {
            final cat = _categories[index];
            final isSelected = selectedCategory == cat.name;

            return _CategoryTile(
              category: cat,
              isSelected: isSelected,
              onTap: () {
                HapticFeedback.selectionClick();
                onCategorySelected(cat.name, cat.iconName, cat.colorHex);
              },
            );
          },
        ),
      ],
    );
  }
}

class _CategoryTile extends StatefulWidget {
  final _CategoryOption category;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryTile({
    required this.category,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_CategoryTile> createState() => _CategoryTileState();
}

class _CategoryTileState extends State<_CategoryTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.90,
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
        scale: _scaleAnimation,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: widget.isSelected
                ? widget.category.color.withAlpha(31)
                : isDark
                ? AppTheme.surfaceVariantDark
                : AppTheme.surfaceVariantLight,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.isSelected
                  ? widget.category.color
                  : isDark
                  ? AppTheme.outlineDark
                  : AppTheme.outlineLight,
              width: widget.isSelected ? 2 : 1,
            ),
            boxShadow: widget.isSelected
                ? [
                    BoxShadow(
                      color: widget.category.color.withAlpha(64),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : [],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: widget.isSelected
                      ? widget.category.color
                      : widget.category.color.withAlpha(26),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  widget.category.icon,
                  color: widget.isSelected
                      ? Colors.white
                      : widget.category.color,
                  size: 20,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                widget.category.name
                    .split(' ')
                    .first, // Show first word only in grid
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: widget.isSelected
                      ? FontWeight.w700
                      : FontWeight.w500,
                  color: widget.isSelected
                      ? widget.category.color
                      : Theme.of(context).colorScheme.onSurface.withAlpha(179),
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryOption {
  final String name;
  final IconData icon;
  final String iconName;
  final Color color;
  final String colorHex;

  const _CategoryOption({
    required this.name,
    required this.icon,
    required this.iconName,
    required this.color,
    required this.colorHex,
  });
}
