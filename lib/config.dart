import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show appFlavor;

/// Всё, что нужно поменять при переезде контента или выпуске под своим аккаунтом.
class Config {
  /// Из одного кода собираются два приложения: flutter run --flavor kaz — «Казахстан обои»,
  /// --flavor uzb — «Узбекистан обои». Без --flavor (например, в тестах) — Казахстан.
  /// Название и иконка — в `android/app/src/<flavor>/res`, пакет и AdMob — в android/app/build.gradle.kts
  static const uzb = appFlavor == 'uzb';

  /// Откуда приложение берёт catalog.json и картинки: ветка content (для Узбекистана — content-uzb)
  /// репозитория на GitHub. Адреса пробуются по очереди; второй — CDN jsDelivr поверх того же репозитория.
  static const contentBases =
      uzb
          ? [
            'https://raw.githubusercontent.com/maxims884/KazWall/content-uzb/',
            'https://cdn.jsdelivr.net/gh/maxims884/KazWall@content-uzb/',
          ]
          : [
            'https://raw.githubusercontent.com/maxims884/KazWall/content/',
            'https://cdn.jsdelivr.net/gh/maxims884/KazWall@content/',
          ];

  /// Языки интерфейса; русский — для всех, у кого телефон на другом языке
  static const languages = uzb ? ['ru', 'uz', 'en'] : ['ru', 'kk', 'en'];

  /// Для отладки: flutter run --dart-define=CONTENT_BASE=http://10.0.2.2:8000/
  static const contentBaseOverride = String.fromEnvironment('CONTENT_BASE');

  /// flutter run --dart-define=NO_ADS=true — без рекламы, например для скриншотов
  static const noAds = bool.fromEnvironment('NO_ADS');

  /// Для скриншотов: текст, уже вписанный в открытку с именем (с adb кириллицу не набрать)
  static const demoName = String.fromEnvironment('DEMO_NAME');

  static const packageName = uzb ? 'uz.black13.uzbwall' : 'kz.black13.kazwall';
  static const storeUrl = 'https://play.google.com/store/apps/details?id=$packageName';

  // Рекламные блоки AdMob. Идентификатор самого приложения — в android/app/build.gradle.kts.
  // В отладочной сборке показываются тестовые блоки Google: за клики по своей рекламе AdMob блокирует аккаунт
  static const _testBanner = 'ca-app-pub-3940256099942544/9214589741';
  static const _testNative = 'ca-app-pub-3940256099942544/2247696110';
  static const _testInterstitial = 'ca-app-pub-3940256099942544/1033173712';
  // У «Узбекистан обои» своих блоков пока нет — стоят тестовые. Перед публикацией завести в AdMob
  // приложение uz.black13.uzbwall и вписать его блоки сюда, а идентификатор — в build.gradle.kts
  static const _uzbBanner = _testBanner;
  static const _uzbNative = _testNative;
  static const _uzbInterstitial = _testInterstitial;

  static const bannerAdUnit =
      !kReleaseMode
          ? _testBanner
          : uzb
          ? _uzbBanner
          : 'ca-app-pub-2230097402282612/2097326436';
  static const nativeAdUnit =
      !kReleaseMode
          ? _testNative
          : uzb
          ? _uzbNative
          : 'ca-app-pub-2230097402282612/9346005929';
  static const interstitialAdUnit =
      !kReleaseMode
          ? _testInterstitial
          : uzb
          ? _uzbInterstitial
          : 'ca-app-pub-2230097402282612/3781943190';

  // Товары в Google Play Console: отключение рекламы и пожертвование
  static const productAdOff = 'ad_off';
  static const productCharity = 'charity';

  /// Альбом в галерее телефона, куда сохраняются картинки
  static const album = uzb ? 'Uzbekistan' : 'Kazakhstan';
}
