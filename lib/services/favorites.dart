import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../models/picture.dart';
import 'prefs.dart';

class Favorites {
  static const type = 'favorites';
  static const _key = 'favorites';
  static List<Picture>? _cache;

  /// Меняется при каждом добавлении и удалении: по нему обновляются сердечки в сетке
  static final changes = ValueNotifier<int>(0);

  static List<Picture> _items() {
    final cache = _cache;
    if (cache != null) return cache;
    final items = <Picture>[];
    try {
      for (final item in jsonDecode(Prefs.raw.getString(_key) ?? '[]') as List) {
        final picture = Picture.fromJson((item as Map).cast<String, dynamic>());
        if (picture != null) items.add(picture);
      }
    } catch (_) {
      // Повреждённая запись — начинаем с пустого списка
    }
    return _cache = items;
  }

  // Новые избранные лежат в начале списка
  static List<Picture> getAll() => List.of(_items());

  static bool isFavorite(Picture picture) => _items().any((p) => p.file == picture.file);

  /// Возвращает true, если картинка теперь в избранном
  static bool toggle(Picture picture) {
    final items = _items();
    final before = items.length;
    items.removeWhere((p) => p.file == picture.file);
    final removed = items.length != before;
    if (!removed) items.insert(0, picture);
    Prefs.raw.setString(_key, jsonEncode([for (final p in items) p.toJson()]));
    changes.value++;
    return !removed;
  }
}
