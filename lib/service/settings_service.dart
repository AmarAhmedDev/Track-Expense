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

  String getSymbol(String currency) => currencySymbols[currency] ?? 'Br';
  String getName(String currency) => currencyNames[currency] ?? currency;
}
