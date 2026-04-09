import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import '../../theme/app_theme.dart';

import '../../database/database_helper.dart';
import '../../service/settings_service.dart';
import '../../main.dart' show themeNotifier;
import '../lock_screen/lock_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with SingleTickerProviderStateMixin {
  String _selectedCurrency = SettingsService.defaultCurrency;
  bool _isLoading = true;
  bool _isLockEnabled = false;
  bool _isBiometricEnabled = false;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _loadSettings();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final currency = await SettingsService.instance.getCurrency();
    
    if (mounted) {
      setState(() {
        _selectedCurrency = currency;
        _isLockEnabled = SettingsService.instance.isLockEnabled;
        _isBiometricEnabled = SettingsService.instance.isBiometricEnabled;
        _isLoading = false;
      });
      _fadeController.forward();
    }
  }

  Future<void> _toggleDarkMode(bool value) async {
    final mode = value ? ThemeMode.dark : ThemeMode.light;
    await SettingsService.instance.setThemeMode(mode);
    themeNotifier.value = mode;
  }

  Future<void> _selectCurrency(String currency) async {
    setState(() => _selectedCurrency = currency);
    await SettingsService.instance.setCurrency(currency);
  }

  Future<void> _toggleAppLock(bool value) async {
    if (value) {
      // Navigate to lock screen setup
      final result = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => const LockScreen(isSettingUp: true),
        ),
      );
      if (result == true && mounted) {
        setState(() => _isLockEnabled = true);
      }
    } else {
      // Disable lock
      await SettingsService.instance.setAppLockEnabled(false);
      await SettingsService.instance.setAppPin(null);
      await SettingsService.instance.setBiometricEnabled(false);
      if (mounted) {
        setState(() {
          _isLockEnabled = false;
          _isBiometricEnabled = false;
        });
      }
    }
  }

  Future<void> _toggleBiometric(bool value) async {
    await SettingsService.instance.setBiometricEnabled(value);
    if (mounted) {
      setState(() => _isBiometricEnabled = value);
    }
  }

  Future<void> _changePin() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const LockScreen(isChangingPin: true),
      ),
    );
    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'PIN changed successfully.',
            style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w500),
          ),
          backgroundColor: AppTheme.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _showResetConfirmationDialog() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppTheme.errorSurface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: AppTheme.error,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Reset All Data',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? AppTheme.onSurfaceDark
                    : AppTheme.onSurfaceLight,
              ),
            ),
          ],
        ),
        content: Text(
          'This will permanently delete all your transactions and budget data. This action cannot be undone.',
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: isDark
                ? AppTheme.onSurfaceMutedDark
                : AppTheme.onSurfaceMutedLight,
            height: 1.5,
          ),
        ),
        actionsPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Cancel',
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppTheme.onSurfaceMutedDark
                    : AppTheme.onSurfaceMutedLight,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await _resetAllData();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: Text(
              'Reset Data',
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _resetAllData() async {
    await DatabaseHelper.instance.clearAllData();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'All data has been reset successfully.',
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          backgroundColor: AppTheme.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          // ── Gradient Header ──────────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 22.h,
            child: Container(
              decoration: const BoxDecoration(
                gradient: AppTheme.headerGradient,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // ── App Bar ──────────────────────────────────
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 4.w,
                    vertical: 1.5.h,
                  ),
                  child: Row(
                    children: [
                      Text(
                        'Settings',
                        style: GoogleFonts.outfit(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(30),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.settings_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Content ───────────────────────────────────
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : FadeTransition(
                          opacity: _fadeAnimation,
                          child: SingleChildScrollView(
                            padding: EdgeInsets.fromLTRB(4.w, 1.h, 4.w, 12.h),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // ── Appearance Section ────────
                                _SectionHeader(
                                  label: 'Appearance',
                                  icon: Icons.palette_outlined,
                                  isDark: isDark,
                                ),
                                SizedBox(height: 1.h),
                                _SettingsCard(
                                  isDark: isDark,
                                  child: _DarkModeRow(
                                    isDark: isDark,
                                    value: isDark,
                                    onChanged: _toggleDarkMode,
                                  ),
                                ),

                                SizedBox(height: 2.5.h),

                                // ── Currency Section ──────────
                                _SectionHeader(
                                  label: 'Currency',
                                  icon: Icons.attach_money_rounded,
                                  isDark: isDark,
                                ),
                                SizedBox(height: 1.h),
                                _SettingsCard(
                                  isDark: isDark,
                                  child: Column(
                                    children: SettingsService
                                        .supportedCurrencies
                                        .asMap()
                                        .entries
                                        .map((entry) {
                                          final idx = entry.key;
                                          final currency = entry.value;
                                          final isLast =
                                              idx ==
                                              SettingsService
                                                      .supportedCurrencies
                                                      .length -
                                                  1;
                                          return Column(
                                            children: [
                                              _CurrencyRow(
                                                currency: currency,
                                                symbol: SettingsService.instance
                                                    .getSymbol(currency),
                                                name: SettingsService.instance
                                                    .getName(currency),
                                                isSelected:
                                                    _selectedCurrency ==
                                                    currency,
                                                isDark: isDark,
                                                onTap: () =>
                                                    _selectCurrency(currency),
                                              ),
                                              if (!isLast)
                                                Divider(
                                                  height: 1,
                                                  thickness: 1,
                                                  color: isDark
                                                      ? AppTheme.outlineDark
                                                      : AppTheme.outlineLight,
                                                ),
                                            ],
                                          );
                                        })
                                        .toList(),
                                  ),
                                ),

                                SizedBox(height: 2.5.h),

                                // ── Security Section ──────────
                                _SectionHeader(
                                  label: 'Security',
                                  icon: Icons.shield_outlined,
                                  isDark: isDark,
                                ),
                                SizedBox(height: 1.h),
                                _SettingsCard(
                                  isDark: isDark,
                                  child: Column(
                                    children: [
                                      _AppLockRow(
                                        isDark: isDark,
                                        value: _isLockEnabled,
                                        onChanged: _toggleAppLock,
                                      ),
                                      Divider(
                                        height: 1,
                                        thickness: 1,
                                        color: isDark
                                            ? AppTheme.outlineDark
                                            : AppTheme.outlineLight,
                                      ),
                                      _BiometricRow(
                                        isDark: isDark,
                                        value: _isBiometricEnabled,
                                        onChanged: _isLockEnabled ? _toggleBiometric : null,
                                      ),
                                      Divider(
                                        height: 1,
                                        thickness: 1,
                                        color: isDark
                                            ? AppTheme.outlineDark
                                            : AppTheme.outlineLight,
                                      ),
                                      _ChangePinRow(
                                        isDark: isDark,
                                        onTap: _isLockEnabled ? _changePin : null,
                                      ),
                                    ],
                                  ),
                                ),

                                SizedBox(height: 2.5.h),

                                // ── Data Section ──────────────
                                _SectionHeader(
                                  label: 'Data',
                                  icon: Icons.storage_outlined,
                                  isDark: isDark,
                                ),
                                SizedBox(height: 1.h),
                                _SettingsCard(
                                  isDark: isDark,
                                  child: _ResetDataRow(
                                    isDark: isDark,
                                    onTap: _showResetConfirmationDialog,
                                  ),
                                ),

                                SizedBox(height: 2.h),

                                // ── App Info ──────────────────
                                Center(
                                  child: Text(
                                    'SmartExpense Tracker v1.0.0',
                                    style: GoogleFonts.outfit(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w400,
                                      color: isDark
                                          ? AppTheme.mutedDark
                                          : AppTheme.mutedLight,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),

        ],
      ),
    );
  }
}

// ── Section Header ─────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isDark;

  const _SectionHeader({
    required this.label,
    required this.icon,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.primary),
        const SizedBox(width: 6),
        Text(
          label.toUpperCase(),
          style: GoogleFonts.outfit(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            color: AppTheme.primary,
          ),
        ),
      ],
    );
  }
}

// ── Settings Card ──────────────────────────────────────────────────────────

class _SettingsCard extends StatelessWidget {
  final Widget child;
  final bool isDark;

  const _SettingsCard({required this.child, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppTheme.outlineDark : AppTheme.outlineLight,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 30 : 10),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

// ── Dark Mode Row ──────────────────────────────────────────────────────────

class _DarkModeRow extends StatelessWidget {
  final bool isDark;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _DarkModeRow({
    required this.isDark,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isDark
                  ? AppTheme.surfaceVariantDark
                  : AppTheme.surfaceVariantLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              value ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
              size: 20,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dark Mode',
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppTheme.onSurfaceDark
                        : AppTheme.onSurfaceLight,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value ? 'Dark theme enabled' : 'Light theme enabled',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: isDark
                        ? AppTheme.onSurfaceMutedDark
                        : AppTheme.onSurfaceMutedLight,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppTheme.primary,
            activeTrackColor: AppTheme.primaryMuted,
          ),
        ],
      ),
    );
  }
}

// ── Currency Row ───────────────────────────────────────────────────────────

class _CurrencyRow extends StatelessWidget {
  final String currency;
  final String symbol;
  final String name;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _CurrencyRow({
    required this.currency,
    required this.symbol,
    required this.name,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.primaryMuted
                    : isDark
                    ? AppTheme.surfaceVariantDark
                    : AppTheme.surfaceVariantLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  symbol,
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isSelected
                        ? AppTheme.primary
                        : isDark
                        ? AppTheme.onSurfaceMutedDark
                        : AppTheme.onSurfaceMutedLight,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    currency,
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppTheme.onSurfaceDark
                          : AppTheme.onSurfaceLight,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    name,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: isDark
                          ? AppTheme.onSurfaceMutedDark
                          : AppTheme.onSurfaceMutedLight,
                    ),
                  ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? AppTheme.primary : Colors.transparent,
                border: Border.all(
                  color: isSelected
                      ? AppTheme.primary
                      : isDark
                      ? AppTheme.outlineDark
                      : AppTheme.outlineLight,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check_rounded,
                      size: 14,
                      color: Colors.white,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Reset Data Row ─────────────────────────────────────────────────────────

class _ResetDataRow extends StatelessWidget {
  final bool isDark;
  final VoidCallback onTap;

  const _ResetDataRow({required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.errorSurface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.delete_sweep_rounded,
                size: 20,
                color: AppTheme.error,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Reset All Data',
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.error,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Permanently delete all transactions & budgets',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: isDark
                          ? AppTheme.onSurfaceMutedDark
                          : AppTheme.onSurfaceMutedLight,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: AppTheme.error.withAlpha(180),
            ),
          ],
        ),
      ),
    );
  }
}

// ── App Lock Row ───────────────────────────────────────────────────────────

class _AppLockRow extends StatelessWidget {
  final bool isDark;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _AppLockRow({
    required this.isDark,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isDark
                  ? AppTheme.surfaceVariantDark
                  : AppTheme.surfaceVariantLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              value ? Icons.lock_rounded : Icons.lock_open_rounded,
              size: 20,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'App Lock',
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppTheme.onSurfaceDark
                        : AppTheme.onSurfaceLight,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value ? 'PIN protection enabled' : 'No lock set',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: isDark
                        ? AppTheme.onSurfaceMutedDark
                        : AppTheme.onSurfaceMutedLight,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppTheme.primary,
            activeTrackColor: AppTheme.primaryMuted,
          ),
        ],
      ),
    );
  }
}

// ── Biometric Row ──────────────────────────────────────────────────────────

class _BiometricRow extends StatelessWidget {
  final bool isDark;
  final bool value;
  final ValueChanged<bool>? onChanged;

  const _BiometricRow({
    required this.isDark,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    bool isEnabled = onChanged != null;
    return Opacity(
      opacity: isEnabled ? 1.0 : 0.5,
      child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isDark
                  ? AppTheme.surfaceVariantDark
                  : AppTheme.surfaceVariantLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.fingerprint_rounded,
              size: 20,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Biometric Unlock',
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppTheme.onSurfaceDark
                        : AppTheme.onSurfaceLight,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value ? 'Fingerprint / Face enabled' : 'Use fingerprint or face',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: isDark
                        ? AppTheme.onSurfaceMutedDark
                        : AppTheme.onSurfaceMutedLight,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppTheme.primary,
            activeTrackColor: AppTheme.primaryMuted,
          ),
        ],
      ),
    ));
  }
}

// ── Change PIN Row ─────────────────────────────────────────────────────────

class _ChangePinRow extends StatelessWidget {
  final bool isDark;
  final VoidCallback? onTap;

  const _ChangePinRow({required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    bool isEnabled = onTap != null;
    return Opacity(
      opacity: isEnabled ? 1.0 : 0.5,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isDark
                    ? AppTheme.surfaceVariantDark
                    : AppTheme.surfaceVariantLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.pin_rounded,
                size: 20,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Change PIN',
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppTheme.onSurfaceDark
                          : AppTheme.onSurfaceLight,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Update your 4-digit PIN',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: isDark
                          ? AppTheme.onSurfaceMutedDark
                          : AppTheme.onSurfaceMutedLight,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: isDark
                  ? AppTheme.onSurfaceMutedDark
                  : AppTheme.onSurfaceMutedLight,
            ),
          ],
        ),
      ),
    ));
  }
}
