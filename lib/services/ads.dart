import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../config.dart';
import '../l10n/strings.dart';
import 'app_settings.dart';

class Ads {
  // Межстраничная — только после завершённого действия с картинкой (установка, сохранение,
  // отправка): каждое 3-е действие и не чаще раза в 3 минуты. При открытии картинки её больше
  // не показываем: она появлялась под пальцем пользователя, и AdMob считал такие клики недействительными
  static const _actionsPerAd = 3;
  static const _minInterval = Duration(minutes: 3);

  static InterstitialAd? _interstitial;
  static bool _initialized = false;
  static int _actionCount = 0;
  // Отсчёт с запуска приложения: в первые минуты межстраничной рекламы нет
  static DateTime _lastShown = DateTime.now();

  static bool get enabled => !Config.noAds && Platform.isAndroid && !AppSettings.instance.adsRemoved;

  static Future<void> init() async {
    if (!enabled || _initialized) return;
    _initialized = true;
    await MobileAds.instance.initialize();
    _loadInterstitial();
  }

  static void _loadInterstitial() {
    if (!enabled) return;
    InterstitialAd.load(
      adUnitId: Config.interstitialAdUnit,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => _interstitial = ad,
        onAdFailedToLoad: (_) => _interstitial = null,
      ),
    );
  }

  /// Вызывать после действия с картинкой. [onDone] выполнится сразу или после закрытия рекламы
  static void afterAction([VoidCallback? onDone]) {
    _actionCount++;
    if (_actionCount % _actionsPerAd == 0 && DateTime.now().difference(_lastShown) > _minInterval) {
      _show(onDone);
    } else {
      onDone?.call();
    }
  }

  static void _show(VoidCallback? onDone) {
    final ad = _interstitial;
    if (ad == null || !enabled) {
      onDone?.call();
      return;
    }
    _interstitial = null;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _loadInterstitial();
        onDone?.call();
      },
      onAdFailedToShowFullScreenContent: (ad, _) {
        ad.dispose();
        _loadInterstitial();
        onDone?.call();
      },
    );
    _lastShown = DateTime.now();
    ad.show();
  }
}

/// Адаптивный баннер на всю ширину экрана внизу главного экрана
class BannerAdBox extends StatefulWidget {
  const BannerAdBox({super.key});

  @override
  State<BannerAdBox> createState() => _BannerAdBoxState();
}

class _BannerAdBoxState extends State<BannerAdBox> {
  BannerAd? _ad;
  bool _loaded = false;
  bool _requested = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_requested && Ads.enabled) {
      _requested = true;
      _load(MediaQuery.sizeOf(context).width.truncate());
    }
  }

  Future<void> _load(int width) async {
    await Ads.init();
    final size = await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(width);
    if (size == null || !mounted) return;
    final ad = BannerAd(
      adUnitId: Config.bannerAdUnit,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, _) => ad.dispose(),
      ),
    );
    _ad = ad;
    await ad.load();
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ad = _ad;
    if (ad == null || !_loaded || !Ads.enabled) return const SizedBox.shrink();
    return SizedBox(width: ad.size.width.toDouble(), height: ad.size.height.toDouble(), child: AdWidget(ad: ad));
  }
}

/// Нативная реклама на всю ширину сетки. Пока не загрузилась — места не занимает
class NativeAdTile extends StatefulWidget {
  const NativeAdTile({super.key});

  @override
  State<NativeAdTile> createState() => _NativeAdTileState();
}

class _NativeAdTileState extends State<NativeAdTile> with AutomaticKeepAliveClientMixin {
  NativeAd? _ad;
  bool _loaded = false;

  // Иначе при прокрутке туда-обратно реклама каждый раз загружалась бы заново
  @override
  bool get wantKeepAlive => true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_ad != null || !Ads.enabled) return;
    final colors = Theme.of(context).colorScheme;
    final ad = NativeAd(
      adUnitId: Config.nativeAdUnit,
      request: const AdRequest(),
      listener: NativeAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, _) => ad.dispose(),
      ),
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: TemplateType.medium,
        mainBackgroundColor: colors.surface,
        cornerRadius: 16,
        callToActionTextStyle: NativeTemplateTextStyle(
          textColor: colors.onPrimary,
          backgroundColor: colors.primary,
          size: 15,
        ),
        primaryTextStyle: NativeTemplateTextStyle(textColor: colors.onSurface, size: 15),
        secondaryTextStyle: NativeTemplateTextStyle(textColor: colors.onSurfaceVariant, size: 13),
        tertiaryTextStyle: NativeTemplateTextStyle(textColor: colors.onSurfaceVariant, size: 13),
      ),
    );
    _ad = ad;
    Ads.init().then((_) => ad.load());
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final ad = _ad;
    if (ad == null || !_loaded || !Ads.enabled) return const SizedBox.shrink();
    final colors = Theme.of(context).colorScheme;
    // Реклама заметно отличается от картинок: своя подложка с рамкой, подпись "Реклама" и отступы
    // сверху и снизу, чтобы её нельзя было нажать вместо соседней картинки
    return Container(
      margin: const EdgeInsets.fromLTRB(6, 18, 6, 18),
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Row(
              children: [
                Icon(Icons.campaign_outlined, size: 16, color: colors.onSurfaceVariant),
                const SizedBox(width: 6),
                Text(
                  S.of(context)['ad_badge'],
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colors.onSurfaceVariant),
                ),
              ],
            ),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 320, maxHeight: 360),
              child: AdWidget(ad: ad),
            ),
          ),
        ],
      ),
    );
  }
}
