import 'dart:io';

import 'package:kazwall_native/kazwall_native.dart';

import '../config.dart';
import 'app_settings.dart';

/// Покупки в Google Play: отключение рекламы и пожертвование.
/// Сама работа с Play Billing — в Kotlin (packages/kazwall_native, Billing.kt)
class Purchases {
  static bool _started = false;

  /// Слушает покупки и восстанавливает сделанные раньше (например, после переустановки)
  static Future<void> init() async {
    if (!Platform.isAndroid || _started) return;
    _started = true;
    // Google Play сообщил всё, что куплено. Если отключения рекламы там нет
    // (покупку вернули), реклама включается обратно
    KazwallNative.onPurchasesOwned = (ids) => AppSettings.instance.adsRemoved = ids.contains(Config.productAdOff);
    KazwallNative.onPurchasesBought = (ids) {
      if (ids.contains(Config.productAdOff)) AppSettings.instance.adsRemoved = true;
    };
    try {
      // Пожертвование можно делать много раз, отключение рекламы покупается навсегда
      await KazwallNative.purchasesInit(consumables: [Config.productCharity]);
    } catch (_) {
      // На устройстве нет Google Play — приложение работает без покупок
    }
  }

  /// Товары, которые отдал Google Play; пустой список, если магазин недоступен
  static Future<List<StoreProduct>> products() async {
    if (!Platform.isAndroid) return [];
    try {
      return await KazwallNative.purchasesProducts([Config.productAdOff, Config.productCharity]);
    } catch (_) {
      return [];
    }
  }

  static Future<void> buy(StoreProduct product) => KazwallNative.purchasesBuy(product.id);
}
