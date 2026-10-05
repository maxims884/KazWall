import 'dart:async';
import 'dart:io';

import 'package:in_app_purchase/in_app_purchase.dart';

import '../config.dart';
import 'app_settings.dart';

/// Покупки в Google Play: отключение рекламы и пожертвование
class Purchases {
  static StreamSubscription<List<PurchaseDetails>>? _subscription;

  /// Слушает покупки и восстанавливает сделанные раньше (например, после переустановки)
  static Future<void> init() async {
    if (!Platform.isAndroid || _subscription != null) return;
    try {
      final iap = InAppPurchase.instance;
      _subscription = iap.purchaseStream.listen(_onPurchases, onError: (_) {});
      if (await iap.isAvailable()) await iap.restorePurchases();
    } catch (_) {
      // На устройстве нет Google Play — приложение работает без покупок
    }
  }

  static Future<void> _onPurchases(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      final bought =
          purchase.status == PurchaseStatus.purchased || purchase.status == PurchaseStatus.restored;
      if (bought && purchase.productID == Config.productAdOff) AppSettings.instance.adsRemoved = true;
      if (purchase.pendingCompletePurchase) await InAppPurchase.instance.completePurchase(purchase);
    }
  }

  /// Товары, которые отдал Google Play; пустой список, если магазин недоступен
  static Future<List<ProductDetails>> products() async {
    if (!Platform.isAndroid) return [];
    try {
      final iap = InAppPurchase.instance;
      if (!await iap.isAvailable()) return [];
      final response = await iap.queryProductDetails({Config.productAdOff, Config.productCharity});
      return response.productDetails;
    } catch (_) {
      return [];
    }
  }

  static Future<void> buy(ProductDetails product) async {
    final param = PurchaseParam(productDetails: product);
    // Пожертвование можно делать много раз, отключение рекламы покупается навсегда
    if (product.id == Config.productCharity) {
      await InAppPurchase.instance.buyConsumable(purchaseParam: param);
    } else {
      await InAppPurchase.instance.buyNonConsumable(purchaseParam: param);
    }
  }
}
