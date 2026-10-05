/// Праздники, к которым присылаем уведомление "открытки готовы"
class Holiday {
  const Holiday(this.id, this.dates);

  /// Название — строка "holiday_" + id в l10n/strings.dart
  final String id;

  /// "MM-dd" для праздников с постоянной датой или "yyyy-MM-dd" для айтов.
  /// Даты айтов считаются по лунному календарю и каждый год объявляются муфтиятом (ДУМК) заново,
  /// поэтому их надо проверять и дописывать на следующие годы. Те же даты — в content_bot/texts.py
  final List<String> dates;
}

class Holidays {
  static const list = [
    Holiday('new_year', ['01-01']),
    Holiday('mar8', ['03-08']),
    Holiday('nauryz', ['03-21']),
    Holiday('unity', ['05-01']),
    Holiday('defender', ['05-07']),
    Holiday('victory', ['05-09']),
    Holiday('capital', ['07-06']),
    Holiday('constitution', ['08-30']),
    Holiday('republic', ['10-25']),
    Holiday('independence', ['12-16']),
    Holiday('oraza_ait', ['2027-03-10', '2028-02-27', '2029-02-14', '2030-02-05']),
    Holiday('kurban_ait', ['2027-05-16', '2028-05-05', '2029-04-24', '2030-04-13']),
  ];

  static String _two(int n) => n.toString().padLeft(2, '0');

  /// Праздник сегодня или завтра и его дата "yyyy-MM-dd", иначе null
  static (Holiday, String)? upcoming(DateTime now) {
    for (var shift = 0; shift <= 1; shift++) {
      final day = DateTime(now.year, now.month, now.day + shift);
      final short = '${_two(day.month)}-${_two(day.day)}';
      final date = '${day.year}-$short';
      for (final holiday in list) {
        if (holiday.dates.contains(date) || holiday.dates.contains(short)) return (holiday, date);
      }
    }
    return null;
  }
}
