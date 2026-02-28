import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppTheme { light, dark, system }

class ThemeProvider extends ChangeNotifier {
  final SharedPreferences _prefs;
  AppTheme _currentTheme = AppTheme.system;

  ThemeProvider(this._prefs) {
    _loadTheme();
  }

  AppTheme get currentTheme => _currentTheme;
  ThemeMode get themeMode {
    switch (_currentTheme) {
      case AppTheme.light:
        return ThemeMode.light;
      case AppTheme.dark:
        return ThemeMode.dark;
      case AppTheme.system:
        return ThemeMode.system;
    }
  }

  ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: Colors.blueAccent,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blueAccent,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: const Color(0xFFF5F7FA),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: const Color(0xFF1E88E5),
      scaffoldBackgroundColor: const Color(0xFF0F172A), // Deep Navy Blue Black
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF38BDF8), // Sky Blue
        secondary: Color(0xFF818CF8), // Indigo
        surface: Color(0xFF1E293B), // Slate Blue-Gray
        onPrimary: Colors.white,
        onSurface: Color(0xFFF1F5F9),
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Color(0xFF0F172A),
        foregroundColor: Colors.white,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: const Color(0xFF1E293B), // Soft Slate
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFF334155),
        thickness: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: const Color(0xFF1E293B),
        hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
      ),
    );
  }

  Future<void> _loadTheme() async {
    final themeIndex = _prefs.getInt('theme') ?? 2;
    if (themeIndex < AppTheme.values.length) {
      _currentTheme = AppTheme.values[themeIndex];
    }
    notifyListeners();
  }

  Future<void> setTheme(AppTheme theme) async {
    _currentTheme = theme;
    await _prefs.setInt('theme', theme.index);
    notifyListeners();
  }

  bool get isDarkMode {
    if (_currentTheme == AppTheme.system) {
      final brightness = PlatformDispatcher.instance.platformBrightness;
      return brightness == Brightness.dark;
    }
    return _currentTheme == AppTheme.dark;
  }
}
