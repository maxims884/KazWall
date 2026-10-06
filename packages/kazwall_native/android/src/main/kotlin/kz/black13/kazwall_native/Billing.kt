package kz.black13.kazwall_native

import android.app.Activity
import android.content.Context
import android.os.Handler
import com.android.billingclient.api.AcknowledgePurchaseParams
import com.android.billingclient.api.BillingClient
import com.android.billingclient.api.BillingClientStateListener
import com.android.billingclient.api.BillingFlowParams
import com.android.billingclient.api.BillingResult
import com.android.billingclient.api.ConsumeParams
import com.android.billingclient.api.PendingPurchasesParams
import com.android.billingclient.api.ProductDetails
import com.android.billingclient.api.Purchase
import com.android.billingclient.api.PurchasesUpdatedListener
import com.android.billingclient.api.QueryProductDetailsParams
import com.android.billingclient.api.QueryPurchasesParams
import io.flutter.plugin.common.MethodChannel

/**
 * Покупки в Google Play (Play Billing 8): разовые товары.
 * Товары из [consumables] можно покупать много раз (пожертвование), остальные — навсегда.
 * О купленном сообщает в Dart вызовами "purchasesOwned" (всё, что есть у пользователя)
 * и "purchasesBought" (только что купленное).
 */
class Billing(
    private val context: Context,
    private val channel: MethodChannel,
    private val main: Handler,
) : PurchasesUpdatedListener {
    private var client: BillingClient? = null
    private var consumables: Set<String> = emptySet()
    private val details = HashMap<String, ProductDetails>()

    private fun ok(result: BillingResult) = result.responseCode == BillingClient.BillingResponseCode.OK

    /** Подключается к Google Play и выполняет [action]; при неудаче — [onFail] */
    private fun connected(onFail: () -> Unit = {}, action: (BillingClient) -> Unit) {
        val current = client ?: BillingClient.newBuilder(context)
            .setListener(this)
            .enablePendingPurchases(PendingPurchasesParams.newBuilder().enableOneTimeProducts().build())
            .enableAutoServiceReconnection()
            .build()
            .also { client = it }
        if (current.isReady) {
            action(current)
            return
        }
        current.startConnection(object : BillingClientStateListener {
            override fun onBillingSetupFinished(result: BillingResult) {
                if (ok(result)) action(current) else onFail()
            }

            override fun onBillingServiceDisconnected() {}
        })
    }

    /** Запрашивает уже сделанные покупки, например после переустановки приложения */
    fun init(consumableIds: List<String>) {
        consumables = consumableIds.toSet()
        connected { billing ->
            val params = QueryPurchasesParams.newBuilder().setProductType(BillingClient.ProductType.INAPP).build()
            billing.queryPurchasesAsync(params) { result, purchases ->
                if (!ok(result)) return@queryPurchasesAsync
                val owned = ArrayList<String>()
                for (purchase in purchases) {
                    if (purchase.purchaseState != Purchase.PurchaseState.PURCHASED) continue
                    finish(billing, purchase)
                    owned.addAll(purchase.products.filter { it !in consumables })
                }
                main.post { channel.invokeMethod("purchasesOwned", owned) }
            }
        }
    }

    /** Товары, которые отдал Google Play: id, название и цена. Пустой список, если магазин недоступен */
    fun products(ids: List<String>, reply: (List<Map<String, String>>) -> Unit) {
        connected(onFail = { main.post { reply(emptyList()) } }) { billing ->
            val products = ids.map {
                QueryProductDetailsParams.Product.newBuilder()
                    .setProductId(it)
                    .setProductType(BillingClient.ProductType.INAPP)
                    .build()
            }
            val params = QueryProductDetailsParams.newBuilder().setProductList(products).build()
            billing.queryProductDetailsAsync(params) { result, response ->
                val found = ArrayList<Map<String, String>>()
                if (ok(result)) {
                    for (product in response.productDetailsList) {
                        details[product.productId] = product
                        found.add(
                            mapOf(
                                "id" to product.productId,
                                "title" to product.name,
                                "price" to (product.oneTimePurchaseOfferDetails?.formattedPrice ?: ""),
                            )
                        )
                    }
                }
                main.post { reply(found) }
            }
        }
    }

    /** Открывает окно оплаты Google Play */
    fun buy(activity: Activity?, id: String): Boolean {
        val product = details[id] ?: return false
        val billing = client ?: return false
        if (activity == null) return false
        val productParams = BillingFlowParams.ProductDetailsParams.newBuilder().setProductDetails(product).build()
        val params = BillingFlowParams.newBuilder().setProductDetailsParamsList(listOf(productParams)).build()
        return ok(billing.launchBillingFlow(activity, params))
    }

    override fun onPurchasesUpdated(result: BillingResult, purchases: MutableList<Purchase>?) {
        val billing = client ?: return
        if (!ok(result) || purchases == null) return
        for (purchase in purchases) {
            if (purchase.purchaseState != Purchase.PurchaseState.PURCHASED) continue
            finish(billing, purchase)
            val bought = ArrayList(purchase.products)
            main.post { channel.invokeMethod("purchasesBought", bought) }
        }
    }

    // Google возвращает деньги за покупку, которую приложение не подтвердило за три дня.
    // Пожертвование "расходуем", чтобы его можно было купить снова
    private fun finish(billing: BillingClient, purchase: Purchase) {
        if (purchase.products.any { it in consumables }) {
            val params = ConsumeParams.newBuilder().setPurchaseToken(purchase.purchaseToken).build()
            billing.consumeAsync(params) { _, _ -> }
        } else if (!purchase.isAcknowledged) {
            val params = AcknowledgePurchaseParams.newBuilder().setPurchaseToken(purchase.purchaseToken).build()
            billing.acknowledgePurchase(params) { }
        }
    }
}
