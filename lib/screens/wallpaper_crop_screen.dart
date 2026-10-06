import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photo_view/photo_view.dart';

import '../l10n/strings.dart';
import '../theme.dart';

/// Выбор области картинки для обоев: картинка заполняет весь экран так же, как будет стоять
/// на телефоне, её можно двигать и увеличивать. Возвращает выбранную область в пикселях картинки
/// или null, если пользователь передумал.
class WallpaperCropScreen extends StatefulWidget {
  const WallpaperCropScreen({super.key, required this.file});

  final File file;

  @override
  State<WallpaperCropScreen> createState() => WallpaperCropScreenState();
}

class WallpaperCropScreenState extends State<WallpaperCropScreen> {
  final _controller = PhotoViewController();
  Size? _imageSize;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _readSize();
  }

  // Размер картинки нужен, чтобы перевести положение на экране в пиксели файла
  Future<void> _readSize() async {
    try {
      final buffer = await ui.ImmutableBuffer.fromFilePath(widget.file.path);
      final descriptor = await ui.ImageDescriptor.encoded(buffer);
      final size = Size(descriptor.width.toDouble(), descriptor.height.toDouble());
      descriptor.dispose();
      buffer.dispose();
      if (mounted) setState(() => _imageSize = size);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Часть картинки, которая сейчас видна на экране
  static Rect visibleArea(Size image, Size viewport, double? scale, Offset position) {
    // Пока картинку не трогали, она заполняет экран целиком и стоит по центру
    final covered = [viewport.width / image.width, viewport.height / image.height].reduce((a, b) => a > b ? a : b);
    final s = scale == null || scale < covered ? covered : scale;
    final width = (viewport.width / s).clamp(1.0, image.width);
    final height = (viewport.height / s).clamp(1.0, image.height);
    // position — на сколько центр картинки сдвинут от центра экрана
    final left = (image.width / 2 - position.dx / s - width / 2).clamp(0.0, image.width - width);
    final top = (image.height / 2 - position.dy / s - height / 2).clamp(0.0, image.height - height);
    return Rect.fromLTWH(left, top, width, height);
  }

  void _done(Size viewport) {
    final image = _imageSize;
    if (image == null) return;
    Navigator.of(context).pop(visibleArea(image, viewport, _controller.scale, _controller.position));
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.black,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Theme(
        data: buildTheme(Brightness.dark),
        child: Scaffold(
          backgroundColor: Colors.black,
          body: LayoutBuilder(
            builder: (context, box) {
              final viewport = box.biggest;
              return Stack(
                children: [
                  if (_imageSize != null)
                    Positioned.fill(
                      child: ClipRect(
                        child: PhotoView(
                          controller: _controller,
                          imageProvider: FileImage(widget.file),
                          backgroundDecoration: const BoxDecoration(color: Colors.black),
                          // Меньше экрана картинку не сделать: на обоях не должно быть пустых полей
                          minScale: PhotoViewComputedScale.covered,
                          initialScale: PhotoViewComputedScale.covered,
                          maxScale: PhotoViewComputedScale.covered * 4,
                        ),
                      ),
                    )
                  else
                    Center(
                      child:
                          _failed
                              ? Text(s['image_load_failed'], style: const TextStyle(color: Colors.white70))
                              : const CircularProgressIndicator(color: Colors.white),
                    ),
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: DecoratedBox(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xAA000000), Colors.transparent],
                        ),
                      ),
                      child: SafeArea(
                        bottom: false,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(4, 4, 16, 28),
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.arrow_back, color: Colors.white),
                                tooltip: s['back'],
                                onPressed: () => Navigator.of(context).pop(),
                              ),
                              Expanded(
                                child: Text(
                                  s['crop_hint'],
                                  style: const TextStyle(color: Colors.white, fontSize: 15),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 0,
                    child: SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: SizedBox(
                          height: 56,
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF0091AD),
                              foregroundColor: Colors.white,
                              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                            onPressed: _imageSize == null ? null : () => _done(viewport),
                            icon: const Icon(Icons.wallpaper, size: 20),
                            label: Text(s['set_wallpaper']),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
