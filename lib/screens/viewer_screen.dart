import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kazwall_native/kazwall_native.dart';
import 'package:photo_view/photo_view.dart';

import '../l10n/strings.dart';
import '../models/picture.dart';
import '../services/ads.dart';
import '../services/favorites.dart';
import '../services/picture_actions.dart';
import '../theme.dart';
import 'card_editor_screen.dart';

/// Открывает просмотр картинки поверх сетки. Фон прозрачный: при свайпе вниз сквозь него видна сетка
void openViewer(BuildContext context, List<Picture> pictures, int index) {
  Ads.onPictureOpened();
  Navigator.of(context).push(
    PageRouteBuilder(
      opaque: false,
      transitionDuration: const Duration(milliseconds: 180),
      reverseTransitionDuration: const Duration(milliseconds: 150),
      pageBuilder: (_, _, _) => ViewerScreen(pictures: pictures, index: index),
      transitionsBuilder: (_, animation, _, child) => FadeTransition(opacity: animation, child: child),
    ),
  );
}

class ViewerScreen extends StatefulWidget {
  const ViewerScreen({super.key, required this.pictures, required this.index});

  final List<Picture> pictures;
  final int index;

  @override
  State<ViewerScreen> createState() => _ViewerScreenState();
}

class _ViewerScreenState extends State<ViewerScreen> with SingleTickerProviderStateMixin {
  late final _pages = PageController(initialPage: widget.index);
  late int _index = widget.index;
  // Увеличенную картинку пользователь двигает, а не закрывает
  bool _zoomed = false;
  bool _busy = false;
  // Насколько картинку утянули вниз, в пикселях
  double _drag = 0;
  late final _settle = AnimationController(vsync: this, duration: const Duration(milliseconds: 180));
  Animation<double>? _settleTo;

  Picture get _picture => widget.pictures[_index];

  @override
  void initState() {
    super.initState();
    _settle.addListener(() => setState(() => _drag = _settleTo?.value ?? 0));
  }

  @override
  void dispose() {
    _settle.dispose();
    _pages.dispose();
    super.dispose();
  }

  void _toast(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text), duration: const Duration(seconds: 2)));
  }

  // Свайп вниз закрывает просмотр: фон светлеет, кнопки исчезают
  void _onDragEnd(DragEndDetails details, double height) {
    final far = _drag > height * 0.2;
    final fast = (details.primaryVelocity ?? 0) > 1000;
    final target = far || fast ? height : 0.0;
    _settleTo = Tween(begin: _drag, end: target).animate(_settle);
    _settle.forward(from: 0).whenComplete(() {
      if (target > 0 && mounted) Navigator.of(context).pop();
    });
  }

  /// Скачивает картинку и выполняет действие, показывая на это время индикатор
  Future<void> _withFile(Future<void> Function(File file) action) async {
    if (_busy) return;
    final s = S.of(context);
    setState(() => _busy = true);
    final file = await PictureActions.file(_picture);
    if (file == null) {
      _toast(s['image_load_failed']);
    } else {
      await action(file);
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _chooseWallpaperTarget() async {
    final s = S.of(context);
    final target = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder:
          (context) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(s['set_wallpaper_title'], style: Theme.of(context).textTheme.titleLarge),
                  ),
                ),
                for (final (icon, title, value) in [
                  (Icons.home_outlined, s['target_home'], KazwallNative.targetHome),
                  (Icons.lock_outline, s['target_lock'], KazwallNative.targetLock),
                  (Icons.smartphone, s['target_both'], KazwallNative.targetBoth),
                ])
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                    leading: Icon(icon),
                    title: Text(title),
                    onTap: () => Navigator.of(context).pop(value),
                  ),
                const SizedBox(height: 8),
              ],
            ),
          ),
    );
    if (target == null || !mounted) return;
    if (target != KazwallNative.targetHome && !await KazwallNative.isLockScreenSupported()) {
      _toast(s['lock_not_supported']);
      return;
    }
    await _withFile((file) async {
      final done = await KazwallNative.setWallpaper(file.path, target);
      _toast(done ? s['wallpaper_set'] : s['wallpaper_failed']);
      if (done) Ads.afterAction();
    });
  }

  Future<void> _save() async {
    final s = S.of(context);
    await _withFile((file) async {
      final result = await PictureActions.saveToGallery(file);
      _toast(switch (result) {
        SaveResult.saved => s['image_saved'],
        SaveResult.denied => s['storage_permission_denied'],
        SaveResult.failed => s['image_save_failed'],
      });
      if (result == SaveResult.saved) Ads.afterAction();
    });
  }

  Future<void> _share({required bool whatsApp}) async {
    final s = S.of(context);
    await _withFile((file) async {
      // Если подошла очередь рекламы, окно отправки откроется после неё
      Ads.afterAction(() => PictureActions.share(file, s, whatsApp: whatsApp));
    });
  }

  void _toggleFavorite() {
    final s = S.of(context);
    final added = Favorites.toggle(_picture);
    _toast(added ? s['favorite_added'] : s['favorite_removed']);
    setState(() {});
  }

  void _openEditor() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => CardEditorScreen(picture: _picture)));
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final height = MediaQuery.sizeOf(context).height;
    final progress = (_drag / height).clamp(0.0, 1.0);
    final controlsOpacity = (1 - progress * 3).clamp(0.0, 1.0);
    final picture = _picture;
    final card = picture.isCard;
    final credit = picture.credit;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      // Просмотр картинки всегда на чёрном фоне, независимо от темы
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.black,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Theme(
        data: buildTheme(Brightness.dark),
        child: Scaffold(
          backgroundColor: Colors.black.withValues(alpha: 1 - progress),
          body: Stack(
            children: [
              GestureDetector(
                onVerticalDragUpdate:
                    _zoomed ? null : (d) => setState(() => _drag = (_drag + d.delta.dy).clamp(0.0, height)),
                onVerticalDragEnd: _zoomed ? null : (d) => _onDragEnd(d, height),
                child: Transform.translate(
                  offset: Offset(0, _drag),
                  // Картинка слегка уменьшается, пока её тянут
                  child: Transform.scale(
                    scale: 1 - progress * 0.3,
                    child: PageView.builder(
                      controller: _pages,
                      itemCount: widget.pictures.length,
                      onPageChanged:
                          (index) => setState(() {
                            _index = index;
                            _zoomed = false;
                          }),
                      itemBuilder: (context, index) {
                        final p = widget.pictures[index];
                        return PhotoView(
                          key: ValueKey(p.file),
                          imageProvider: CachedNetworkImageProvider(p.url, cacheKey: p.file),
                          backgroundDecoration: const BoxDecoration(color: Colors.transparent),
                          minScale: PhotoViewComputedScale.contained,
                          maxScale: PhotoViewComputedScale.covered * 3,
                          scaleStateChangedCallback: (state) {
                            if (index == _index) setState(() => _zoomed = state != PhotoViewScaleState.initial);
                          },
                          // Миниатюра уже в кэше, показываем её, пока грузится сама картинка
                          loadingBuilder:
                              (_, _) => Center(
                                child: CachedNetworkImage(
                                  imageUrl: p.thumbUrl,
                                  cacheKey: p.thumb,
                                  fit: BoxFit.contain,
                                  width: double.infinity,
                                  height: double.infinity,
                                ),
                              ),
                          errorBuilder:
                              (_, _, _) => Center(
                                child: Text(s['image_load_failed'], style: const TextStyle(color: Colors.white70)),
                              ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              if (controlsOpacity > 0) ...[
                Positioned(
                  top: 0,
                  left: 0,
                  child: SafeArea(
                    child: Opacity(
                      opacity: controlsOpacity,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: _CircleButton(
                          icon: Icons.arrow_back,
                          label: s['back'],
                          onTap: () => Navigator.of(context).pop(),
                        ),
                      ),
                    ),
                  ),
                ),
                // Панель действий с картинкой
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Opacity(
                    opacity: controlsOpacity,
                    child: DecoratedBox(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Color(0xCC000000)],
                        ),
                      ),
                      child: SafeArea(
                        top: false,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 40),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Автор и лицензия фото: для Wikimedia Commons это обязательное условие
                              if (credit != null)
                                InkWell(
                                  onTap:
                                      picture.sourceUrl == null ? null : () => KazwallNative.openUrl(picture.sourceUrl!),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                    child: Text(
                                      credit,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(color: Color(0xB3FFFFFF), fontSize: 12),
                                    ),
                                  ),
                                ),
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    _ActionButton(
                                      icon: Favorites.isFavorite(picture) ? Icons.favorite : Icons.favorite_border,
                                      color: Favorites.isFavorite(picture) ? brandGold : null,
                                      label: s['favorite'],
                                      onTap: _toggleFavorite,
                                    ),
                                    // У открытки вместо сохранения — открытка с именем
                                    if (card)
                                      _ActionButton(icon: Icons.edit_outlined, label: s['card_with_name'], onTap: _openEditor)
                                    else
                                      _ActionButton(icon: Icons.download_outlined, label: s['save'], onTap: _save),
                                    _ActionButton(
                                      icon: Icons.share_outlined,
                                      label: s['share'],
                                      onTap: () => _share(whatsApp: false),
                                    ),
                                    // У открытки главная кнопка отправляет её в WhatsApp, у обоев — ставит на экран
                                    Expanded(
                                      child: SizedBox(
                                        height: 56,
                                        child: FilledButton.icon(
                                          style: FilledButton.styleFrom(
                                            backgroundColor: card ? whatsAppGreen : const Color(0xFF0091AD),
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(horizontal: 12),
                                            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                          ),
                                          onPressed: card ? () => _share(whatsApp: true) : _chooseWallpaperTarget,
                                          icon: Icon(card ? Icons.send : Icons.wallpaper, size: 20),
                                          // На узких экранах надпись уменьшается, а не обрезается
                                          label: FittedBox(
                                            fit: BoxFit.scaleDown,
                                            child: Text(card ? 'WhatsApp' : s['set_wallpaper'], maxLines: 1),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
              if (_busy) const Center(child: CircularProgressIndicator(color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.4),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(width: 44, height: 44, child: Icon(icon, color: Colors.white, semanticLabel: label)),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.icon, required this.label, required this.onTap, this.color});

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: SizedBox(
        width: 52,
        height: 52,
        child: IconButton.filledTonal(
          style: IconButton.styleFrom(
            backgroundColor: const Color(0xFF2B3237),
            foregroundColor: color ?? Colors.white,
          ),
          tooltip: label,
          onPressed: onTap,
          icon: Icon(icon, size: 24),
        ),
      ),
    );
  }
}
