import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum Currency { tryLira, usd }

extension CurrencyX on Currency {
  String get code => switch (this) {
        Currency.tryLira => 'TRY',
        Currency.usd => 'USD',
      };
  String get symbol => switch (this) {
        Currency.tryLira => '₺',
        Currency.usd => '\$',
      };
  String get label => switch (this) {
        Currency.tryLira => 'Türk Lirası (₺)',
        Currency.usd => 'Amerikan Doları (\$)',
      };
}

class SettingsService extends ChangeNotifier {
  static const _kCurrency = 'settings.currency';
  static const _kTheme = 'settings.theme';
  static const _kIsPro = 'settings.isPro';

  Currency _currency = Currency.tryLira;
  ThemeMode _themeMode = ThemeMode.system;
  bool _isPro = false;

  Currency get currency => _currency;
  ThemeMode get themeMode => _themeMode;
  bool get isPro => _isPro;

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    final c = p.getString(_kCurrency);
    if (c == 'USD') _currency = Currency.usd;
    final t = p.getString(_kTheme);
    _themeMode = switch (t) {
      'dark' => ThemeMode.dark,
      'light' => ThemeMode.light,
      _ => ThemeMode.system,
    };
    _isPro = p.getBool(_kIsPro) ?? false;
    notifyListeners();
  }

  Future<void> setCurrency(Currency c) async {
    _currency = c;
    final p = await SharedPreferences.getInstance();
    await p.setString(_kCurrency, c.code);
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode m) async {
    _themeMode = m;
    final p = await SharedPreferences.getInstance();
    final s = switch (m) {
      ThemeMode.dark => 'dark',
      ThemeMode.light => 'light',
      ThemeMode.system => 'system',
    };
    await p.setString(_kTheme, s);
    notifyListeners();
  }

  Future<void> setPro(bool v) async {
    _isPro = v;
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kIsPro, v);
    notifyListeners();
  }
}
