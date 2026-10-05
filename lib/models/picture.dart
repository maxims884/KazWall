import '../services/catalog.dart';

class Picture {
  Picture({
    required this.id,
    required this.type,
    required this.file,
    required this.thumb,
    this.tags = const [],
    this.author,
    this.license,
    this.sourceUrl,
    this.createdAt = 0,
    this.textAt,
  });

  final String id;
  final String type;

  /// Пути внутри папки контента: "images/nature/….jpg"
  final String file;
  final String thumb;

  /// Теги для поиска
  final List<String> tags;

  /// Автор и лицензия: для фото с Wikimedia Commons их обязательно показывать
  final String? author;
  final String? license;
  final String? sourceUrl;

  /// Когда картинка добавлена, миллисекунды
  final int createdAt;

  /// Для открыток: где поздравление, "top" или "bottom". Имя получателя ставится на другую половину
  final String? textAt;

  String get url => Catalog.base + file;
  String get thumbUrl => Catalog.base + thumb;

  bool get isCard => type == Catalog.cards;

  /// Подпись под картинкой: "© автор · лицензия", если она нужна
  String? get credit {
    final a = author;
    if (a == null || a.trim().isEmpty) return null;
    final l = license;
    return '© $a${l == null || l.trim().isEmpty ? '' : ' · $l'}';
  }

  static String? _text(Object? value) {
    final text = value?.toString() ?? '';
    return text.isEmpty ? null : text;
  }

  static Picture? fromJson(Map<String, dynamic> json) {
    final file = _text(json['file']);
    if (file == null) return null;
    final tags = json['tags'];
    return Picture(
      id: _text(json['id']) ?? file,
      type: _text(json['type']) ?? '',
      file: file,
      thumb: _text(json['thumb']) ?? file,
      tags: tags is List ? tags.map((t) => t.toString().trim()).where((t) => t.isNotEmpty).toList() : const [],
      author: _text(json['author']),
      license: _text(json['license']),
      sourceUrl: _text(json['sourceUrl']),
      createdAt: json['createdAt'] is num ? (json['createdAt'] as num).toInt() : 0,
      textAt: _text(json['textAt']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'file': file,
    'thumb': thumb,
    if (tags.isNotEmpty) 'tags': tags,
    if (author != null) 'author': author,
    if (license != null) 'license': license,
    if (sourceUrl != null) 'sourceUrl': sourceUrl,
    'createdAt': createdAt,
    if (textAt != null) 'textAt': textAt,
  };
}
