import '../config.dart';
import '../models/picture.dart';
import 'catalog.dart';

/// Поиск по каталогу на устройстве. Ищет по тегам картинки, а если тегов нет —
/// по словам, связанным с категорией, на трёх языках.
class Search {
  static const prefix = 'search:';

  static const _keywords = Config.uzb ? _uzbekistan : _kazakhstan;

  static const _uzbekistan = <String, List<String>>{
    'nature': [
      'природа', 'пейзаж', 'горы', 'озеро', 'лес', 'река', 'небо', 'закат', 'пустыня', 'цветы',
      'tabiat', 'manzara', 'tog‘', 'ko‘l', 'o‘rmon', 'daryo', 'osmon', 'shafaq', 'cho‘l', 'gul',
      'nature', 'landscape', 'mountains', 'lake', 'forest', 'river', 'sky', 'sunset', 'desert', 'flowers',
    ],
    'animals': [
      'животные', 'лошадь', 'конь', 'верблюд', 'птица', 'аист', 'бабочка',
      'hayvonlar', 'ot', 'tuya', 'qush', 'laylak', 'kapalak',
      'animals', 'horse', 'camel', 'bird', 'stork', 'butterfly',
    ],
    'arch': [
      'архитектура', 'здание', 'город', 'ташкент', 'самарканд', 'бухара', 'хива', 'регистан', 'площадь', 'памятник',
      'me’morchilik', 'bino', 'shahar', 'toshkent', 'samarqand', 'buxoro', 'xiva', 'registon', 'maydon', 'haykal',
      'architecture', 'building', 'city', 'tashkent', 'samarkand', 'bukhara', 'khiva', 'registan', 'square',
    ],
    'relig': [
      'религия', 'мечеть', 'медресе', 'минарет', 'ислам', 'коран', 'намаз', 'мавзолей', 'церковь',
      'din', 'masjid', 'madrasa', 'minora', 'islom', 'qur’on', 'namoz', 'maqbara', 'cherkov',
      'religion', 'mosque', 'madrasah', 'minaret', 'islam', 'quran', 'mausoleum', 'church',
    ],
    'culture': [
      'традиции', 'культура', 'национальный', 'орнамент', 'керамика', 'базар', 'плов', 'ковер', 'сюзане',
      'an’ana', 'madaniyat', 'milliy', 'naqsh', 'kulolchilik', 'bozor', 'osh', 'palov', 'gilam', 'so‘zana',
      'traditions', 'culture', 'traditional', 'ornament', 'ceramics', 'bazaar', 'plov', 'carpet', 'suzani',
    ],
    Catalog.cards: [
      'открытка', 'поздравление', 'праздник', 'хайит', 'навруз', 'жума', 'день рождения',
      'tabriknoma', 'otkritka', 'tabrik', 'bayram', 'hayit', 'navro‘z', 'juma', 'tug‘ilgan kun',
      'card', 'greeting', 'holiday', 'birthday', 'eid', 'navruz', 'friday',
    ],
  };

  static const _kazakhstan = <String, List<String>>{
    'nature': [
      'природа', 'пейзаж', 'горы', 'озеро', 'лес', 'река', 'небо', 'закат', 'степь', 'каньон',
      'табиғат', 'тау', 'көл', 'орман', 'өзен', 'аспан', 'дала', 'шатқал',
      'nature', 'landscape', 'mountains', 'lake', 'forest', 'river', 'sky', 'sunset', 'steppe', 'canyon',
    ],
    'animals': [
      'животные', 'лошадь', 'конь', 'орел', 'беркут', 'барс', 'верблюд', 'сайгак', 'птица',
      'жануарлар', 'жылқы', 'бүркіт', 'барыс', 'түйе', 'ақбөкен', 'құс',
      'animals', 'horse', 'eagle', 'leopard', 'camel', 'saiga', 'bird',
    ],
    'arch': [
      'архитектура', 'здание', 'город', 'астана', 'алматы', 'площадь', 'памятник', 'мост',
      'сәулет', 'ғимарат', 'қала', 'алаң', 'ескерткіш', 'көпір',
      'architecture', 'building', 'city', 'astana', 'almaty', 'square', 'monument', 'bridge',
    ],
    'relig': [
      'религия', 'мечеть', 'ислам', 'коран', 'намаз', 'мавзолей', 'церковь', 'собор',
      'дін', 'мешіт', 'құран', 'кесене', 'шіркеу',
      'religion', 'mosque', 'islam', 'quran', 'mausoleum', 'church', 'cathedral',
    ],
    'culture': [
      'традиции', 'культура', 'юрта', 'национальный', 'орнамент', 'музей', 'домбра',
      'дәстүр', 'мәдениет', 'киіз үй', 'ұлттық', 'ою-өрнек', 'мұражай',
      'traditions', 'culture', 'yurt', 'traditional', 'ornament', 'museum', 'dombra',
    ],
    Catalog.cards: [
      'открытка', 'поздравление', 'праздник', 'айт', 'наурыз', 'жума', 'день рождения',
      'ашық хат', 'құттықтау', 'мереке', 'мейрам', 'жұма', 'туған күн',
      'card', 'greeting', 'holiday', 'birthday', 'eid', 'nauryz', 'friday',
    ],
  };

  // В узбекских словах апостроф набирают по-разному (o‘, o', oʻ) — при сравнении его не учитываем
  static String _normalize(String text) =>
      text.toLowerCase().replaceAll('ё', 'е').replaceAll(RegExp('[\'`‘’ʻʼ]'), '').trim();

  static int _commonPrefix(String a, String b) {
    var i = 0;
    while (i < a.length && i < b.length && a[i] == b[i]) {
      i++;
    }
    return i;
  }

  // "гор" находит "горы", "лошади" находит "лошадь": сравниваем по общему началу слова
  static bool _similar(String a, String b) {
    final common = _commonPrefix(a, b);
    final needed = [a.length, b.length, 4].reduce((x, y) => x < y ? x : y);
    return common >= 2 && common >= needed;
  }

  static bool _matches(List<String> words, String word) => words.any(
    (phrase) => phrase.split(RegExp('[ -]')).any((w) => _similar(w, word)) || phrase.startsWith(word),
  );

  // Сколько картинок показывать, когда точных совпадений нет
  static const _fallbackCount = 30;

  static Set<String> _pairs(String word) => {for (var i = 0; i + 1 < word.length; i++) word.substring(i, i + 2)};

  // Насколько слова похожи, 0…1: доля общих пар соседних букв. "самарканд" и "самаркант" — 0.875
  static double _closeness(String a, String b) {
    final first = _pairs(a), second = _pairs(b);
    if (first.isEmpty || second.isEmpty) return a.isNotEmpty && b.startsWith(a) ? 0.5 : 0;
    return 2 * first.intersection(second).length / (first.length + second.length);
  }

  /// Поиск всегда что-то показывает. Сначала картинки, у которых с запросом совпали теги, потом совпавшие
  /// по категории. Если таких нет — те, где нашлось хотя бы одно слово; нет и их — самые похожие
  /// по написанию (опечатка, другое окончание); а если запрос ни на что не похож — просто новые картинки.
  static List<Picture> filter(List<Picture> pictures, String query) {
    final text = _normalize(query);
    if (text.isEmpty) return [];
    var words = text.split(' ').where((w) => w.length >= 2).toList();
    // Одна буква — тоже запрос
    if (words.isEmpty) words = [text.replaceAll(' ', '')];
    final byTags = <Picture>[];
    final byCategory = <Picture>[];
    final partly = <Picture>[];
    final scores = <Picture, double>{};
    final byType = {for (final entry in _keywords.entries) entry.key: entry.value.map(_normalize).toList()};
    for (final picture in pictures) {
      final tags = picture.tags.map(_normalize).toList();
      final keywords = byType[picture.type] ?? const <String>[];
      if (words.every((w) => _matches(tags, w))) {
        byTags.add(picture);
      } else if (words.every((w) => _matches(tags, w) || _matches(keywords, w))) {
        byCategory.add(picture);
      } else if (words.any((w) => _matches(tags, w) || _matches(keywords, w))) {
        partly.add(picture);
      } else {
        var best = 0.0;
        for (final phrase in [...tags, ...keywords]) {
          for (final known in phrase.split(RegExp('[ -]'))) {
            for (final word in words) {
              final score = _closeness(word, known);
              if (score > best) best = score;
            }
          }
        }
        if (best > 0) scores[picture] = best;
      }
    }
    if (byTags.isNotEmpty || byCategory.isNotEmpty) return byTags + byCategory;
    if (partly.isNotEmpty) return partly;
    if (scores.isNotEmpty) {
      final similar = scores.keys.toList()..sort((a, b) => scores[b]!.compareTo(scores[a]!));
      return similar.take(_fallbackCount).toList();
    }
    final newest = [...pictures]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return newest.take(_fallbackCount).toList();
  }
}
