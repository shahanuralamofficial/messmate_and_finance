import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'auth_provider.dart';

class SettingsProvider extends ChangeNotifier {
  final SharedPreferences _prefs;

  // Changed default locale to English
  Locale _locale = const Locale('en', 'US');
  String _currency = 'USD';
  String _currencySymbol = '\$';
  bool _pinEnabled = false;
  String? _pinCode;
  bool _biometricEnabled = false;
  bool _notificationsEnabled = true;

  SettingsProvider(this._prefs) {
    _loadSettings();
  }

  Locale get locale => _locale;
  String get currency => _currency;
  String get currencySymbol => _currencySymbol;
  bool get pinEnabled => _pinEnabled;
  String? get pinCode => _pinCode;
  bool get biometricEnabled => _biometricEnabled;
  bool get notificationsEnabled => _notificationsEnabled;

  Future<void> _loadSettings() async {
    // Changed default language to 'en'
    final language = _prefs.getString('language') ?? 'en';
    _locale = Locale(language, language == 'bn' ? 'BD' : 'US');
    _currency = _prefs.getString('currency') ?? 'USD';
    _currencySymbol = _prefs.getString('currencySymbol') ?? '\$';
    _pinEnabled = _prefs.getBool('pinEnabled') ?? false;
    _pinCode = _prefs.getString('pinCode');
    _biometricEnabled = _prefs.getBool('biometricEnabled') ?? false;
    _notificationsEnabled = _prefs.getBool('notificationsEnabled') ?? true;
    notifyListeners();
  }

  Future<void> setLanguage(String languageCode, [BuildContext? context]) async {
    await _prefs.setString('language', languageCode);
    _locale = Locale(languageCode, languageCode == 'bn' ? 'BD' : 'US');

    if (context != null) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.isAuthenticated) {
        await authProvider.updateUserSettings({
          'language': languageCode,
        });
      }
    }

    notifyListeners();
  }

  Future<void> setCurrency(String currency, String symbol, [BuildContext? context]) async {
    await _prefs.setString('currency', currency);
    await _prefs.setString('currencySymbol', symbol);
    _currency = currency;
    _currencySymbol = symbol;

    if (context != null) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.isAuthenticated) {
        await authProvider.updateUserSettings({
          'currency': currency,
          'currencySymbol': symbol,
        });
      }
    }

    notifyListeners();
  }

  Future<void> setPin(String pin) async {
    await _prefs.setString('pinCode', pin);
    await _prefs.setBool('pinEnabled', true);
    _pinCode = pin;
    _pinEnabled = true;
    notifyListeners();
  }

  Future<void> disablePin() async {
    await _prefs.remove('pinCode');
    await _prefs.setBool('pinEnabled', false);
    _pinCode = null;
    _pinEnabled = false;
    notifyListeners();
  }

  Future<void> setBiometricEnabled(bool value) async {
    await _prefs.setBool('biometricEnabled', value);
    _biometricEnabled = value;
    notifyListeners();
  }

  Future<void> setNotificationsEnabled(bool value) async {
    await _prefs.setBool('notificationsEnabled', value);
    _notificationsEnabled = value;
    notifyListeners();
  }
}
