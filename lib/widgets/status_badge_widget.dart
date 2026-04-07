import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Semantic colored badge for transaction types and status indicators.
/// Uses BoxDecoration container — never plain Text with color.
class StatusBadgeWidget extends StatelessWidget {
  final String label;
  final StatusBadgeType type;

  const StatusBadgeWidget({super.key, required this.label, required this.type});

  @override
  Widget build(BuildContext context) {
    final config = _getConfig();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: config.backgroundColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: config.borderColor, width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: config.textColor,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  _BadgeConfig _getConfig() {
    switch (type) {
      case StatusBadgeType.income:
        return _BadgeConfig(
          backgroundColor: AppTheme.successSurface,
          borderColor: AppTheme.success.withAlpha(77),
          textColor: AppTheme.success,
        );
      case StatusBadgeType.expense:
        return _BadgeConfig(
          backgroundColor: AppTheme.errorSurface,
          borderColor: AppTheme.error.withAlpha(77),
          textColor: AppTheme.error,
        );
      case StatusBadgeType.warning:
        return _BadgeConfig(
          backgroundColor: AppTheme.warningSurface,
          borderColor: AppTheme.warning.withAlpha(77),
          textColor: AppTheme.warning,
        );
      case StatusBadgeType.neutral:
        return _BadgeConfig(
          backgroundColor: const Color(0xFFF1F5F9),
          borderColor: const Color(0xFFE2E8F0),
          textColor: const Color(0xFF64748B),
        );
    }
  }
}

enum StatusBadgeType { income, expense, warning, neutral }

class _BadgeConfig {
  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;
  _BadgeConfig({
    required this.backgroundColor,
    required this.borderColor,
    required this.textColor,
  });
}
