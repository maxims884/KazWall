import 'package:flutter/services.dart';

/// То, чего нет в готовых пакетах Flutter или что должно работать и в фоновых задачах:
/// установка обоев, отправка картинки (в том числе сразу в WhatsApp), открытие ссылок.
class KazwallNative {
  static const _channel = MethodChannel('kazwall_native');

  static const targetHome = 0;
  static const targetLock = 1;
  static const targetBoth = 2;

  static Future<bool> isLockScreenSupported() async =>
      await _channel.invokeMethod<bool>('isLockScreenSupported') ?? false;

  /// Ставит картинку из файла на экран. Работает и без открытого приложения
  static Future<bool> setWallpaper(String path, int target) async =>
      await _channel.invokeMethod<bool>('setWallpaper', {'path': path, 'target': target}) ?? false;

  /// Перекодирует картинку в JPEG: открытка с именем рисуется в PNG, а он слишком тяжёлый для отправки
  static Future<bool> toJpeg(String source, String target, {int quality = 92}) async =>
      await _channel.invokeMethod<bool>('toJpeg', {'source': source, 'target': target, 'quality': quality}) ??
      false;

  /// Окно "Поделиться" или, если просили и он установлен, сразу WhatsApp
  static Future<bool> shareImage(
    String path, {
    required String text,
    required String title,
    bool whatsApp = false,
  }) async =>
      await _channel.invokeMethod<bool>('shareImage', {
        'path': path,
        'text': text,
        'title': title,
        'whatsApp': whatsApp,
      }) ??
      false;

  static Future<bool> openUrl(String url) async =>
      await _channel.invokeMethod<bool>('openUrl', {'url': url}) ?? false;

  /// Страница приложения в Google Play
  static Future<bool> openStore() async => await _channel.invokeMethod<bool>('openStore') ?? false;
}
