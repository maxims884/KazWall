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

  /// Сначала картинки, у которых совпали теги, потом совпавшие по категории
  static List<Picture> filter(List<Picture> pictures, String query) {
    final words = _normalize(query).split(' ').where((w) => w.length >= 2).toList();
    if (words.isEmpty) return [];
    final byTags = <Picture>[];
    final byCategory = <Picture>[];
    final byType = {for (final entry in _keywords.entries) entry.key: entry.value.map(_normalize).toList()};
    for (final picture in pictures) {
      final tags = picture.tags.map(_normalize).toList();
      final keywords = byType[picture.type] ?? const [];
      if (words.every((w) => _matches(tags, w))) {
        byTags.add(picture);
      } else if (words.every((w) => _matches(tags, w) || _matches(keywords, w))) {
        byCategory.add(picture);
      }
    }
    return byTags + byCategory;
  }
}
