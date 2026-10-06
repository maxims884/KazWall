import 'package:flutter/foundation.dart';

/// Всё, что нужно поменять при переезде контента или выпуске под своим аккаунтом.
class Config {
  /// Откуда приложение берёт catalog.json и картинки: ветка content репозитория на GitHub.
  /// Адреса пробуются по очереди; второй — CDN jsDelivr поверх того же репозитория.
  static const contentBases = [
    'https://raw.githubusercontent.com/maxims884/KazWall/content/',
    'https://cdn.jsdelivr.net/gh/maxims884/KazWall@content/',
  ];

  /// Для отладки: flutter run --dart-define=CONTENT_BASE=http://10.0.2.2:8000/
  static const contentBaseOverride = String.fromEnvironment('CONTENT_BASE');

  /// flutter run --dart-define=NO_ADS=true — без рекламы, например для скриншотов
  static const noAds = bool.fromEnvironment('NO_ADS');

  /// Для скриншотов: текст, уже вписанный в открытку с именем (с adb кириллицу не набрать)
  static const demoName = String.fromEnvironment('DEMO_NAME');

  static const packageName = 'kz.black13.kazwall';
  static const storeUrl = 'https://play.google.com/store/apps/details?id=$packageName';

  // Рекламные блоки AdMob. Идентификатор самого приложения — в android/app/src/main/AndroidManifest.xml.
  // В отладочной сборке показываются тестовые блоки Google: за клики по своей рекламе AdMob блокирует аккаунт
  static const bannerAdUnit =
      kReleaseMode ? 'ca-app-pub-2230097402282612/2097326436' : 'ca-app-pub-3940256099942544/9214589741';
  static const nativeAdUnit =
      kReleaseMode ? 'ca-app-pub-2230097402282612/9346005929' : 'ca-app-pub-3940256099942544/2247696110';
  static const interstitialAdUnit =
      kReleaseMode ? 'ca-app-pub-2230097402282612/3781943190' : 'ca-app-pub-3940256099942544/1033173712';

  // Товары в Google Play Console: отключение рекламы и пожертвование
  static const productAdOff = 'ad_off';
  static const productCharity = 'charity';

  /// Альбом в галерее телефона, куда сохраняются картинки
  static const album = 'Kazakhstan';
}
