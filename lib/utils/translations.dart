import 'package:flutter/material.dart';
import 'constants.dart';

class AppTranslations {
  static String translate(String key, String locale) {
    return AppStrings.translations[locale]?[key] ?? key;
  }

  static const List<String> categories = AppConstants.categories;
  static const List<String> accountTypes = AppConstants.accountTypes;
  static const List<String> units = AppConstants.units;
  static const List<Color> noteColors = AppConstants.noteColors;
}
