import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../config.dart';
import '../models/picture.dart';
import 'prefs.dart';

/// Список всех картинок из всех категорий для вкладок, ленты, поиска и фоновых задач.
/// Это один файл catalog.json в ветке content на GitHub: бот дописывает в него новые картинки
/// каждый день. Копия хранится на устройстве, а с сервером сверяется раз в несколько часов —
/// если файл не менялся, GitHub отвечает "304 Not Modified" и ничего не скачивается.
class Catalog {
  static const feed = 'feed';
  static const cards = 'cards';
  static const wallpaperTypes = ['nature', 'animals', 'arch', 'relig', 'culture'];

  static const _file = 'catalog.json';
  // Как часто проверять новые картинки
  static const _checkEvery = Duration(hours: 6);
  // В ленте сверху показываем добавленное за последние дни
  static const _newFor = Duration(days: 3);

  static List<Picture>? _memory;

  /// Адрес, с которого в последний раз удалось получить каталог; с него же грузятся картинки
  static String get base {
    if (Config.contentBaseOverride.isNotEmpty) return Config.contentBaseOverride;
    final saved = Prefs.raw.getString('catalogBase');
    return saved != null && Config.contentBases.contains(saved) ? saved : Config.contentBases.first;
  }

  static List<String> get _bases {
    if (Config.contentBaseOverride.isNotEmpty) return [Config.contentBaseOverride];
    final current = base;
    return [current, ...Config.contentBases.where((b) => b != current)];
  }

  static Future<File> _local() async => File('${(await getApplicationSupportDirectory()).path}/$_file');

  static List<Picture> _parse(String text) {
    final json = jsonDecode(text);
    final items = json is Map ? json['items'] : json;
    if (items is! List) return [];
    final pictures = <Picture>[];
    for (final item in items) {
      final picture = item is Map ? Picture.fromJson(item.cast<String, dynamic>()) : null;
      if (picture != null) pictures.add(picture);
    }
    return pictures;
  }

  /// Картинки, сохранённые на устройстве; пустой список, если их ещё нет
  static Future<List<Picture>> cached() async {
    final memory = _memory;
    if (memory != null) return memory;
    try {
      final file = await _local();
      if (await file.exists()) return _memory = _parse(await file.readAsString());
    } catch (_) {
      // Повреждённый файл — просто скачаем заново
    }
    return [];
  }

  /// Каталог с устройства, при необходимости сверенный с сервером.
  /// [refresh] — пользователь потянул список вниз: проверяем сейчас
  static Future<List<Picture>> load({bool refresh = false}) async {
    final current = await cached();
    final checked = Prefs.raw.getInt('catalogChecked') ?? 0;
    final fresh = DateTime.now().millisecondsSinceEpoch - checked < _checkEvery.inMilliseconds;
    if (current.isNotEmpty && fresh && !refresh) return current;

    for (final base in _bases) {
      try {
        final etag = Prefs.raw.getString('catalogEtag');
        final sameBase = Prefs.raw.getString('catalogBase') == base;
        final response = await http
            .get(
              Uri.parse(base + _file),
              headers: {if (current.isNotEmpty && sameBase && etag != null) 'If-None-Match': etag},
            )
            .timeout(const Duration(seconds: 30));
        if (response.statusCode == 304) {
          await Prefs.raw.setInt('catalogChecked', DateTime.now().millisecondsSinceEpoch);
          return current;
        }
        if (response.statusCode != 200) continue;
        final text = utf8.decode(response.bodyBytes);
        final items = _parse(text);
        if (items.isEmpty) continue;
        await (await _local()).writeAsString(text);
        await Prefs.raw.setInt('catalogChecked', DateTime.now().millisecondsSinceEpoch);
        await Prefs.raw.setString('catalogBase', base);
        final newEtag = response.headers['etag'];
        if (newEtag != null) await Prefs.raw.setString('catalogEtag', newEtag);
        return _memory = items;
      } catch (e) {
        // Нет сети или адрес недоступен — пробуем следующий
        debugPrint('catalog: $base: $e');
      }
    }
    // Нет сети — показываем то, что есть на устройстве
    return current;
  }

  /// Картинки одной категории, новые сверху
  static List<Picture> ofType(List<Picture> pictures, String type) {
    final items = pictures.where((p) => p.type == type).toList();
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }

  /// Порядок ленты: при каждом открытии новый. Свежие картинки (за последние дни) тоже
  /// перемешаны, но идут чаще: каждая третья в начале ленты, пока они не кончатся.
  /// Так новое заметно сразу, но лента не превращается в один и тот же блок новинок.
  static List<Picture> feedOrder(List<Picture> pictures) {
    final border = DateTime.now().millisecondsSinceEpoch - _newFor.inMilliseconds;
    final fresh = pictures.where((p) => p.createdAt > border).toList()..shuffle();
    final rest = pictures.where((p) => p.createdAt <= border).toList()..shuffle();
    // Если свежее вообще всё (первые дни после запуска), делить не на что
    if (rest.isEmpty) return fresh;
    final result = <Picture>[];
    var f = 0, r = 0;
    while (f < fresh.length || r < rest.length) {
      if (f < fresh.length) result.add(fresh[f++]);
      for (var i = 0; i < 2 && r < rest.length; i++) {
        result.add(rest[r++]);
      }
    }
    return result;
  }
}
