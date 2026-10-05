import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:kazwall_native/kazwall_native.dart';
import 'package:path_provider/path_provider.dart';

import '../config.dart';
import '../l10n/strings.dart';
import '../models/picture.dart';
import '../services/ads.dart';
import '../services/picture_actions.dart';
import '../theme.dart';

/// Открытка с именем: пользователь пишет текст поверх картинки, двигает его пальцем,
/// выбирает цвет и размер и отправляет готовую картинку.
class CardEditorScreen extends StatefulWidget {
  const CardEditorScreen({super.key, required this.picture});

  final Picture picture;

  @override
  State<CardEditorScreen> createState() => _CardEditorScreenState();
}

class _CardEditorScreenState extends State<CardEditorScreen> {
  static const _colors = [Colors.white, Color(0xFFFFD54F), Color(0xFFE53935), Color(0xFF212121)];

  final _cardKey = GlobalKey();
  ui.Image? _image;
  bool _failed = false;
  bool _sending = false;
  // Пока идёт снимок открытки, подсказку "Ваш текст" прячем
  bool _capturing = false;

  final _input = TextEditingController(text: Config.demoName);
  late String _text = _input.text;
  Color _color = Colors.white;
  // Размер шрифта, как если бы открытка была шириной 360
  double _size = 28;
  // Левый верхний угол текста в долях открытки. Пока текст не двигали — держим его по центру
  // той половины открытки, где нет поздравления
  Offset? _position;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    final file = await PictureActions.file(widget.picture);
    ui.Image? image;
    if (file != null) {
      try {
        image = await decodeImageFromList(await file.readAsBytes());
      } catch (_) {
        // Файл повреждён
      }
    }
    if (!mounted) return;
    setState(() {
      _image = image;
      _failed = image == null;
    });
    if (image == null) _toast(S.of(context)['image_load_failed']);
  }

  @override
  void dispose() {
    _image?.dispose();
    _input.dispose();
    super.dispose();
  }

  void _toast(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text), duration: const Duration(seconds: 2)));
  }

  TextStyle _style(double frameWidth) => TextStyle(
    color: _color,
    fontSize: _size * frameWidth / 360,
    fontWeight: FontWeight.w700,
    height: 1.2,
    // Тёмный текст лучше читается со светлой тенью
    shadows: [
      Shadow(
        color: _color == _colors.last ? const Color(0xCCFFFFFF) : const Color(0xCC000000),
        blurRadius: 6 * frameWidth / 360,
        offset: Offset(0, 2 * frameWidth / 360),
      ),
    ],
  );

  Future<void> _send({required bool whatsApp}) async {
    final image = _image;
    if (image == null || _sending) return;
    final s = S.of(context);
    setState(() {
      _sending = true;
      _capturing = true;
    });
    File? file;
    try {
      await WidgetsBinding.instance.endOfFrame;
      final boundary = _cardKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      // Снимок в размере исходной картинки, а не в размере превью на экране
      final shot = await boundary.toImage(pixelRatio: image.width / boundary.size.width);
      final png = await shot.toByteData(format: ui.ImageByteFormat.png);
      shot.dispose();
      final dir = (await getTemporaryDirectory()).path;
      final source = File('$dir/card.png');
      await source.writeAsBytes(png!.buffer.asUint8List());
      if (await KazwallNative.toJpeg(source.path, '$dir/card.jpg')) file = File('$dir/card.jpg');
    } catch (_) {
      // Не хватило памяти или места — сообщим ниже
    }
    if (!mounted) return;
    setState(() {
      _sending = false;
      _capturing = false;
    });
    final ready = file;
    if (ready == null) {
      _toast(s['image_load_failed']);
      return;
    }
    Ads.afterAction(() => PictureActions.share(ready, s, whatsApp: whatsApp));
  }

  // Рамка открытки повторяет пропорции картинки и вписывается в свободное место
  Widget _preview(S s, BoxConstraints box) {
    final image = _image!;
    final scale = [box.maxWidth / image.width, box.maxHeight / image.height].reduce((a, b) => a < b ? a : b);
    final frame = Size(image.width * scale, image.height * scale);

    final style = _style(frame.width);
    final shown = _text.isEmpty ? s['card_text_placeholder'] : _text;
    final painter = TextPainter(
      text: TextSpan(text: shown, style: style),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: frame.width * 0.9);
    final textSize = painter.size;
    painter.dispose();

    // Текст не должен уезжать за края открытки
    final maxX = (frame.width - textSize.width).clamp(0.0, double.infinity);
    final maxY = (frame.height - textSize.height).clamp(0.0, double.infinity);
    final position = _position;
    final x = position == null ? maxX / 2 : (position.dx * frame.width).clamp(0.0, maxX);
    final y =
        position == null
            ? (frame.height * (widget.picture.textAt == 'top' ? 0.85 : 0.15) - textSize.height / 2).clamp(0.0, maxY)
            : (position.dy * frame.height).clamp(0.0, maxY);

    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_capturing ? 0 : 12),
        child: RepaintBoundary(
          key: _cardKey,
          child: SizedBox(
            width: frame.width,
            height: frame.height,
            child: Stack(
              children: [
                Positioned.fill(child: RawImage(image: image, fit: BoxFit.fill)),
                if (_text.isNotEmpty || !_capturing)
                  Positioned(
                    left: x,
                    top: y,
                    width: textSize.width,
                    child: GestureDetector(
                      onPanUpdate:
                          (d) => setState(() {
                            _position = Offset(
                              ((x + d.delta.dx).clamp(0.0, maxX)) / frame.width,
                              ((y + d.delta.dy).clamp(0.0, maxY)) / frame.height,
                            );
                          }),
                      child: Text(
                        shown,
                        textAlign: TextAlign.center,
                        style: _text.isEmpty ? style.copyWith(color: Colors.white.withValues(alpha: 0.67)) : style,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(s['card_with_name'])),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child:
                    _image == null
                        ? Center(child: _failed ? const Icon(Icons.broken_image_outlined) : const CircularProgressIndicator())
                        : LayoutBuilder(builder: (context, box) => _preview(s, box)),
              ),
            ),
            Container(
              color: colors.surface,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _input,
                    maxLines: 2,
                    minLines: 1,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: s['card_name_hint'],
                      filled: true,
                      fillColor: colors.surfaceContainerHigh,
                      isDense: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                    onChanged: (text) => setState(() => _text = text.trim()),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      for (final color in _colors)
                        Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: GestureDetector(
                            onTap: () => setState(() => _color = color),
                            child: Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: _color == color ? colors.primary : colors.outline,
                                  width: _color == color ? 3 : 1,
                                ),
                              ),
                            ),
                          ),
                        ),
                      Expanded(
                        child: Semantics(
                          label: s['card_text_size'],
                          child: Slider(
                            value: _size,
                            min: 16,
                            max: 56,
                            onChanged: (value) => setState(() => _size = value),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(s['card_drag_hint'], style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      SizedBox(
                        width: 52,
                        height: 52,
                        child: IconButton.filledTonal(
                          tooltip: s['share'],
                          onPressed: _sending ? null : () => _send(whatsApp: false),
                          icon: const Icon(Icons.share_outlined),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SizedBox(
                          height: 52,
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: whatsAppGreen,
                              foregroundColor: Colors.white,
                              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                            onPressed: _sending ? null : () => _send(whatsApp: true),
                            icon:
                                _sending
                                    ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                    : const Icon(Icons.send, size: 20),
                            label: const Text('WhatsApp'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
