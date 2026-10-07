import 'package:flutter/material.dart';

import 'prefs.dart';

/// То, от чего зависит всё приложение целиком: тема, язык и куплено ли отключение рекламы
class AppSettings extends ChangeNotifier {
  AppSettings._();
  static final instance = AppSettings._();

  ThemeMode get themeMode => switch (Prefs.themeMode) {
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    _ => ThemeMode.system,
  };

  set themeMode(ThemeMode mode) {
    Prefs.themeMode = mode.name;
    notifyListeners();
  }

  /// Один из Config.languages или "" — как в системе
  String get language => Prefs.language;

  set language(String value) {
    Prefs.language = value;
    notifyListeners();
  }

  bool get adsRemoved => Prefs.adsRemoved;

  set adsRemoved(bool value) {
    if (Prefs.adsRemoved == value) return;
    Prefs.adsRemoved = value;
    notifyListeners();
  }
}
