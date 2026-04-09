import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persistent settings service backed by SharedPreferences.
/// Manages dark mode toggle and selected currency.
class SettingsService {
  static final SettingsService instance = SettingsService._internal();
  SettingsService._internal();

  static const String _keyDarkMode = 'dark_mode';
  static const String _keyCurrency = 'currency';

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

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _cachedCurrency = prefs.getString(_keyCurrency) ?? defaultCurrency;
  }

  Future<bool> getDarkMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyDarkMode) ?? false;
  }

  Future<void> setDarkMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyDarkMode, value);
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
