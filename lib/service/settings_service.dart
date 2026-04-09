import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

/// Persistent settings service backed by SharedPreferences.
/// Manages dark mode toggle and selected currency.
class SettingsService {
  static final SettingsService instance = SettingsService._internal();
  SettingsService._internal();

  static const String _keyDarkMode = 'dark_mode';
  static const String _keyCurrency = 'currency';
  static const String _keyAppLockEnabled = 'app_lock_enabled';
  static const String _keyAppPin = 'app_pin';
  static const String _keyBiometricEnabled = 'biometric_enabled';

  static const String defaultCurrency = 'ETB';
  static const List<String> supportedCurrencies = ['ETB', 'USD', 'EUR'];

  static const Map<String, String> currencySymbols = {
    'ETB': 'Br',
    'USD': '\$',
    'EUR': '€',
  };

  static const Map<String, String> currencyNames = {
    'ETB': 'Ethiopian Birr',
    'USD': 'US Dollar',
    'EUR': 'Euro',
  };

  String _cachedCurrency = defaultCurrency;
  String get cachedCurrency => _cachedCurrency;
  String get currentSymbol => getSymbol(_cachedCurrency);

  bool _isLockEnabled = false;
  String? _appPin;
  bool _isBiometricEnabled = false;

  bool get isLockEnabled => _isLockEnabled;
  String? get appPin => _appPin;
  bool get isBiometricEnabled => _isBiometricEnabled;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _cachedCurrency = prefs.getString(_keyCurrency) ?? defaultCurrency;
    _isLockEnabled = prefs.getBool(_keyAppLockEnabled) ?? false;
    _appPin = prefs.getString(_keyAppPin);
    _isBiometricEnabled = prefs.getBool(_keyBiometricEnabled) ?? false;
  }

  Future<bool> getDarkMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyDarkMode) ?? false;
  }

  Future<void> setDarkMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyDarkMode, value);
  }

  Future<ThemeMode> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final mode = prefs.getString('theme_mode');
    if (mode == 'dark') return ThemeMode.dark;
    if (mode == 'light') return ThemeMode.light;
    return ThemeMode.system;
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    String str = 'system';
    if (mode == ThemeMode.dark) str = 'dark';
    if (mode == ThemeMode.light) str = 'light';
    await prefs.setString('theme_mode', str);
  }

  Future<String> getCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    _cachedCurrency = prefs.getString(_keyCurrency) ?? defaultCurrency;
    return _cachedCurrency;
  }

  Future<void> setCurrency(String currency) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyCurrency, currency);
    _cachedCurrency = currency;
  }

  Future<void> setAppLockEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyAppLockEnabled, value);
    _isLockEnabled = value;
  }

  Future<void> setAppPin(String? pin) async {
    final prefs = await SharedPreferences.getInstance();
    if (pin == null) {
      await prefs.remove(_keyAppPin);
    } else {
      await prefs.setString(_keyAppPin, pin);
    }
    _appPin = pin;
  }

  Future<void> setBiometricEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyBiometricEnabled, value);
    _isBiometricEnabled = value;
  }

  /// Currencies where the symbol appears after the amount (suffix position)
  static const Set<String> _suffixCurrencies = {'ETB'};

  String getSymbol(String currency) => currencySymbols[currency] ?? 'Br';
  String getName(String currency) => currencyNames[currency] ?? currency;

  /// Format an amount with the correct currency symbol placement.
  /// For ETB: "3,000.00 Br" (suffix with space)
  /// For USD: "$3,000.00" (prefix, no space)
  /// For EUR: "€3,000.00" (prefix, no space)
  String formatAmount(double amount, {int decimalDigits = 2}) {
    final symbol = currentSymbol;
    final numberFormat = NumberFormat.decimalPatternDigits(
      decimalDigits: decimalDigits,
    );
    final formatted = numberFormat.format(amount);
    if (_suffixCurrencies.contains(_cachedCurrency)) {
      return '$formatted $symbol';
    }
    return '$symbol$formatted';
  }
}
