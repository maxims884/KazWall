import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kazwall/screens/wallpaper_crop_screen.dart';

void main() {
  const image = Size(3000, 2000); // широкая картинка
  const screen = Size(400, 800); // экран телефона 1:2
  final area = WallpaperCropScreenState.visibleArea;

  test('пока картинку не трогали, берётся середина во всю высоту', () {
    final r = area(image, screen, null, Offset.zero);
    expect(r, const Rect.fromLTWH(1000, 0, 1000, 2000));
  });

  test('картинку сдвинули вправо — на экране её левая часть', () {
    // Масштаб 0.4: картинка 1200x800 на экране, сдвиг на 400 вправо — до упора
    final r = area(image, screen, 0.4, const Offset(400, 0));
    expect(r, const Rect.fromLTWH(0, 0, 1000, 2000));
  });

  test('увеличение вдвое показывает четверть области', () {
    final r = area(image, screen, 0.8, Offset.zero);
    expect(r, const Rect.fromLTWH(1250, 500, 500, 1000));
  });

  test('область не выходит за края картинки', () {
    final r = area(image, screen, 0.4, const Offset(-5000, 300));
    expect(r.right, lessThanOrEqualTo(3000));
    expect(r.top, greaterThanOrEqualTo(0));
    expect(r.width / r.height, closeTo(0.5, 0.001));
  });
}
