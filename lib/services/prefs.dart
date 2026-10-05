import 'package:shared_preferences/shared_preferences.dart';

/// Настройки автосмены обоев, уведомлений и темы. Читаются и из фоновых задач
class Prefs {
  static late SharedPreferences _sp;

  /// В фоновой задаче [reload] обязателен: у неё своя копия настроек в памяти
  static Future<void> init({bool reload = false}) async {
    _sp = await SharedPreferences.getInstance();
    if (reload) await _sp.reload();
  }

  static SharedPreferences get raw => _sp;

  static bool get autoWallpaper => _sp.getBool('autoWallpaper') ?? false;
  static set autoWallpaper(bool value) => _sp.setBool('autoWallpaper', value);

  static bool get autoFromFavorites => _sp.getBool('autoFromFavorites') ?? true;
  static set autoFromFavorites(bool value) => _sp.setBool('autoFromFavorites', value);

  static bool get weekly => _sp.getBool('weekly') ?? true;
  static set weekly(bool value) => _sp.setBool('weekly', value);

  static bool get reminder => _sp.getBool('reminder') ?? true;
  static set reminder(bool value) => _sp.setBool('reminder', value);

  static bool get holidays => _sp.getBool('holidays') ?? true;
  static set holidays(bool value) => _sp.setBool('holidays', value);

  // Ключ "праздник_дата", про который уже напомнили
  static bool isHolidayNotified(String key) => (_sp.getStringList('holidaysNotified') ?? const []).contains(key);
  static Future<void> setHolidayNotified(String key) =>
      _sp.setStringList('holidaysNotified', [...?_sp.getStringList('holidaysNotified'), key]);

  static String? get lastAutoFile => _sp.getString('lastAutoFile');
  static set lastAutoFile(String? value) => _sp.setString('lastAutoFile', value ?? '');

  static bool get notificationsAsked => _sp.getBool('notificationsAsked') ?? false;
  static set notificationsAsked(bool value) => _sp.setBool('notificationsAsked', value);

  /// "system", "light" или "dark"
  static String get themeMode => _sp.getString('themeMode') ?? 'system';
  static set themeMode(String value) => _sp.setString('themeMode', value);

  /// Язык, выбранный в приложении: "ru", "kk", "en" или "" (как в системе)
  static String get language => _sp.getString('language') ?? '';
  static set language(String value) => _sp.setString('language', value);

  static bool get adsRemoved => _sp.getBool('adsRemoved') ?? false;
  static set adsRemoved(bool value) => _sp.setBool('adsRemoved', value);

  // Когда пользователь последний раз открывал приложение и сколько напоминаний получил с тех пор
  static int get lastOpen => _sp.getInt('lastOpen') ?? 0;
  static int get remindersSent => _sp.getInt('remindersSent') ?? 0;
  static set remindersSent(int value) => _sp.setInt('remindersSent', value);
  static void markOpened() {
    _sp.setInt('lastOpen', DateTime.now().millisecondsSinceEpoch);
    _sp.setInt('remindersSent', 0);
  }

  // Время последнего нашего уведомления, чтобы они не шли одно за другим
  static int get lastNotified => _sp.getInt('lastNotified') ?? 0;
  static Future<void> markNotified() => _sp.setInt('lastNotified', DateTime.now().millisecondsSinceEpoch);
}
