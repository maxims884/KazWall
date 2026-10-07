import 'package:flutter/services.dart';

/// То, чего нет в готовых пакетах Flutter или что должно работать и в фоновых задачах:
/// установка обоев, отправка картинки (в том числе сразу в WhatsApp), открытие ссылок.
class KazwallNative {
  static final _channel = MethodChannel('kazwall_native')..setMethodCallHandler(_onNativeCall);

  /// Всё, что куплено у пользователя в Google Play (приходит после [purchasesInit])
  static void Function(List<String> productIds)? onPurchasesOwned;

  /// Только что купленные товары
  static void Function(List<String> productIds)? onPurchasesBought;

  static Future<void> _onNativeCall(MethodCall call) async {
    final ids = (call.arguments as List? ?? const []).map((id) => id.toString()).toList();
    if (call.method == 'purchasesOwned') onPurchasesOwned?.call(ids);
    if (call.method == 'purchasesBought') onPurchasesBought?.call(ids);
  }

  /// Подключается к Google Play и запрашивает сделанные раньше покупки.
  /// [consumables] — товары, которые можно покупать много раз
  static Future<void> purchasesInit({List<String> consumables = const []}) =>
      _channel.invokeMethod('purchasesInit', {'consumables': consumables});

  /// Товары с названием и ценой из Google Play; пустой список, если магазин недоступен
  static Future<List<StoreProduct>> purchasesProducts(List<String> ids) async {
    final found = await _channel.invokeMethod<List<Object?>>('purchasesProducts', {'ids': ids}) ?? const [];
    return [
      for (final item in found)
        if (item is Map)
          StoreProduct(
            id: item['id']?.toString() ?? '',
            title: item['title']?.toString() ?? '',
            price: item['price']?.toString() ?? '',
          ),
    ];
  }

  /// Открывает окно оплаты; товар должен быть получен через [purchasesProducts]
  static Future<bool> purchasesBuy(String id) async =>
      await _channel.invokeMethod<bool>('purchasesBuy', {'id': id}) ?? false;

  static const targetHome = 0;
  static const targetLock = 1;
  static const targetBoth = 2;

  static Future<bool> isLockScreenSupported() async =>
      await _channel.invokeMethod<bool>('isLockScreenSupported') ?? false;

  /// Ставит картинку из файла на экран. Работает и без открытого приложения.
  /// [crop] — какую часть картинки взять, в её пикселях. Без него берётся середина
  /// с пропорциями экрана: иначе Android сам обрезает широкие картинки по левому краю
  static Future<bool> setWallpaper(String path, int target, {Rect? crop}) async =>
      await _channel.invokeMethod<bool>('setWallpaper', {
        'path': path,
        'target': target,
        if (crop != null)
          'crop': [crop.left.round(), crop.top.round(), crop.width.round(), crop.height.round()],
      }) ??
      false;

  /// Перекодирует картинку в JPEG: открытка с именем рисуется в PNG, а он слишком тяжёлый для отправки
  static Future<bool> toJpeg(String source, String target, {int quality = 92}) async =>
      await _channel.invokeMethod<bool>('toJpeg', {'source': source, 'target': target, 'quality': quality}) ??
      false;

  /// Окно "Поделиться" или, если просили и он установлен, сразу WhatsApp
  static Future<bool> shareImage(
    String path, {
    required String text,
    required String title,
    String name = 'kazakhstan',
    bool whatsApp = false,
  }) async =>
      await _channel.invokeMethod<bool>('shareImage', {
        'path': path,
        'text': text,
        'title': title,
        'name': name,
        'whatsApp': whatsApp,
      }) ??
      false;

  static Future<bool> openUrl(String url) async =>
      await _channel.invokeMethod<bool>('openUrl', {'url': url}) ?? false;

  /// Страница приложения в Google Play
  static Future<bool> openStore() async => await _channel.invokeMethod<bool>('openStore') ?? false;
}

/// Товар Google Play: название и цена приходят из магазина уже на языке пользователя
class StoreProduct {
  const StoreProduct({required this.id, required this.title, required this.price});

  final String id;
  final String title;
  final String price;
}
