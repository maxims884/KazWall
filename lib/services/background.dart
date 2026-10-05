import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:kazwall_native/kazwall_native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:workmanager/workmanager.dart';

import '../l10n/strings.dart';
import '../models/picture.dart';
import 'catalog.dart';
import 'favorites.dart';
import 'holidays.dart';
import 'prefs.dart';

const _auto = 'auto_wallpaper';
const _weekly = 'weekly_wallpaper';
const _reminder = 'reminder';
const _holidays = 'holidays';

/// Точка входа фоновых задач: Android запускает её без открытого приложения
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, _) async {
    WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized();
    await Prefs.init(reload: true);
    try {
      return switch (task) {
        _auto => await _autoWallpaper(),
        _weekly => await _weeklyWallpaper(),
        _reminder => await _remind(),
        _holidays => await _holiday(),
        _ => true,
      };
    } catch (_) {
      // false — Android повторит задачу позже
      return task != _reminder ? false : true;
    }
  });
}

class Scheduler {
  static Future<void> init() => Workmanager().initialize(callbackDispatcher);

  /// Приводит фоновые задачи в соответствие с настройками
  static Future<void> sync() async {
    // Автосмена: первый запуск сразу после включения, дальше раз в сутки
    await _schedule(_auto, Prefs.autoWallpaper, const Duration(days: 1), Duration.zero);
    await _schedule(_weekly, Prefs.weekly, const Duration(days: 7), const Duration(days: 7));
    // Раз в сутки проверяем, давно ли пользователь заходил
    await _schedule(_reminder, Prefs.reminder, const Duration(days: 1), const Duration(days: 1));
    // Праздники проверяем каждые 6 часов, чтобы попасть в дневное время
    await _schedule(_holidays, Prefs.holidays, const Duration(hours: 6), Duration.zero);
  }

  static Future<void> _schedule(String name, bool enabled, Duration every, Duration delay) async {
    if (!enabled) {
      await Workmanager().cancelByUniqueName(name);
      return;
    }
    await Workmanager().registerPeriodicTask(
      name,
      name,
      frequency: every,
      // Окно запуска равно всему периоду: тогда первый раз задача выполняется сразу (после initialDelay),
      // а не в конце периода, как делает пакет по умолчанию
      flexInterval: every,
      initialDelay: delay,
      constraints: Constraints(networkType: NetworkType.connected),
      // Уже запланированную задачу не трогаем, иначе отсчёт начинался бы заново при каждом запуске
      existingWorkPolicy: ExistingWorkPolicy.keep,
    );
  }
}

Picture? _pickRandom(List<Picture> pictures, String? exceptFile) {
  final others = pictures.where((p) => p.file != exceptFile).toList();
  final from = others.isEmpty ? pictures : others;
  return from.isEmpty ? null : from[Random().nextInt(from.length)];
}

/// Случайные обои (не открытка)
Future<Picture?> _randomWallpaper(String? exceptFile) async {
  final all = await Catalog.load();
  return _pickRandom(all.where((p) => Catalog.wallpaperTypes.contains(p.type)).toList(), exceptFile);
}

Future<File?> _download(String url, String name) async {
  final response = await http.get(Uri.parse(url)).timeout(const Duration(minutes: 2));
  if (response.statusCode != 200) return null;
  final file = File('${(await getTemporaryDirectory()).path}/$name');
  await file.writeAsBytes(response.bodyBytes);
  return file;
}

Future<bool> _autoWallpaper() async {
  final last = Prefs.lastAutoFile;
  final favorites = Favorites.getAll().where((p) => !p.isCard).toList();
  final picture =
      Prefs.autoFromFavorites && favorites.isNotEmpty ? _pickRandom(favorites, last) : await _randomWallpaper(last);
  if (picture == null) return false;
  final file = await _download(picture.url, 'auto_wallpaper.jpg');
  if (file == null || !await KazwallNative.setWallpaper(file.path, KazwallNative.targetBoth)) return false;
  Prefs.lastAutoFile = picture.file;
  return true;
}

Future<bool> _weeklyWallpaper() async {
  if (!await Notifications.isAllowed()) return true;
  return _showRandomWallpaper(1, 'weekly', 'weekly_channel', 'weekly_title', 'weekly_text');
}

/// Напоминание тем, кто давно не заходил: одно через 5 дней и ещё одно через 14.
/// Счётчик сбрасывается при каждом открытии приложения.
Future<bool> _remind() async {
  const firstAfter = Duration(days: 5);
  const secondAfter = Duration(days: 14);
  // Не чаще одного нашего уведомления в три дня, считая "Обои недели"
  const minGap = Duration(days: 3);

  final now = DateTime.now().millisecondsSinceEpoch;
  final lastOpen = Prefs.lastOpen;
  if (lastOpen == 0 || !await Notifications.isAllowed()) return true;

  final idle = now - lastOpen;
  final sent = Prefs.remindersSent;
  final due =
      (sent == 0 && idle >= firstAfter.inMilliseconds) || (sent == 1 && idle >= secondAfter.inMilliseconds);
  if (!due || now - Prefs.lastNotified < minGap.inMilliseconds) return true;

  final shown = await _showRandomWallpaper(2, 'reminder', 'reminder_channel', 'reminder_title', 'reminder_text');
  if (shown) Prefs.remindersSent = sent + 1;
  return true;
}

/// За день до праздника (или утром в сам праздник) напоминает про открытки.
/// На каждый праздник приходит одно уведомление, и только днём.
Future<bool> _holiday() async {
  final now = DateTime.now();
  if (now.hour < 9 || now.hour >= 21 || !await Notifications.isAllowed()) return true;

  final upcoming = Holidays.upcoming(now);
  if (upcoming == null) return true;
  final (holiday, date) = upcoming;
  final key = '${holiday.id}_$date';
  if (Prefs.isHolidayNotified(key)) return true;

  final s = S.forLanguage(Prefs.language);
  // В уведомлении показываем открытку, если они уже есть
  final cards = (await Catalog.load()).where((p) => p.isCard).toList();
  final shown = await Notifications.show(
    3,
    'holidays',
    s['holiday_channel'],
    s.holidayTitle(s['holiday_${holiday.id}']),
    s['holiday_text'],
    _pickRandom(cards, null),
    Catalog.cards,
  );
  if (shown) await Prefs.setHolidayNotified(key);
  return true;
}

/// Уведомление со случайными обоями; нажатие открывает их в приложении
Future<bool> _showRandomWallpaper(int id, String channel, String channelName, String title, String text) async {
  final picture = await _randomWallpaper(null);
  if (picture == null) return false;
  // Тексты уведомления на языке, выбранном в приложении
  final s = S.forLanguage(Prefs.language);
  return Notifications.show(id, channel, s[channelName], s[title], s[text], picture, null);
}

class Notifications {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _ready = false;

  // Если человек не заходит дольше месяца, перестаём его беспокоить совсем
  static const _giveUpAfter = Duration(days: 30);

  /// Что открыть по нажатию на уведомление: {"openType": "cards"} или {"picture": {...}}
  static void Function(Map<String, dynamic> payload)? onOpen;

  static AndroidFlutterLocalNotificationsPlugin? get _android =>
      _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

  static Future<void> _init() async {
    if (_ready) return;
    _ready = true;
    await _plugin.initialize(
      const InitializationSettings(android: AndroidInitializationSettings('ic_stat_wallpaper')),
      onDidReceiveNotificationResponse: (response) => _open(response.payload),
    );
  }

  static void _open(String? payload) {
    if (payload == null || payload.isEmpty) return;
    try {
      onOpen?.call((jsonDecode(payload) as Map).cast<String, dynamic>());
    } catch (_) {
      // Уведомление от старой версии с другим форматом — просто открываем приложение
    }
  }

  /// Вызывается при запуске приложения: если его открыли нажатием на уведомление, сработает [onOpen]
  static Future<void> handleLaunch() async {
    if (!Platform.isAndroid) return;
    await _init();
    final details = await _plugin.getNotificationAppLaunchDetails();
    if (details?.didNotificationLaunchApp ?? false) _open(details?.notificationResponse?.payload);
  }

  static Future<bool> hasPermission() async {
    if (!Platform.isAndroid) return false;
    await _init();
    return await _android?.areNotificationsEnabled() ?? false;
  }

  static Future<bool> requestPermission() async {
    if (!Platform.isAndroid) return false;
    await _init();
    return await _android?.requestNotificationsPermission() ?? false;
  }

  static Future<bool> isAllowed() async {
    if (!await hasPermission()) return false;
    final lastOpen = Prefs.lastOpen;
    return lastOpen == 0 || DateTime.now().millisecondsSinceEpoch - lastOpen < _giveUpAfter.inMilliseconds;
  }

  /// Уведомление с картинкой. Нажатие открывает вкладку [openType], а если её нет — саму картинку
  static Future<bool> show(
    int id,
    String channel,
    String channelName,
    String title,
    String text,
    Picture? picture,
    String? openType,
  ) async {
    await _init();
    // Миниатюры хватает: в уведомлении картинка маленькая
    final image = picture == null ? null : await _download(picture.thumbUrl, 'notification_$id.jpg');
    final bitmap = image == null ? null : FilePathAndroidBitmap(image.path);
    final payload = openType != null ? {'openType': openType} : {'picture': picture?.toJson()};

    await _plugin.show(
      id,
      title,
      text,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channel,
          channelName,
          // Без звука: это не срочные уведомления
          importance: Importance.low,
          priority: Priority.low,
          autoCancel: true,
          largeIcon: bitmap,
          styleInformation:
              bitmap == null
                  ? null
                  : BigPictureStyleInformation(bitmap, hideExpandedLargeIcon: true, contentTitle: title, summaryText: text),
        ),
      ),
      payload: jsonEncode(payload),
    );
    await Prefs.markNotified();
    return true;
  }
}
