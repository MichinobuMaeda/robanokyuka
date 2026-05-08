import 'package:flutter_test/flutter_test.dart';
import 'package:robanokyuka/models/cal_date.dart';

// Asserts that [cal] matches today's year/month/day.
void expectToday(Cal cal) {
  final today = DateTime.now();
  expect(cal.year, today.year);
  expect(cal.month, today.month);
  expect(cal.day, today.day);
}

void main() {
  // ---------------------------------------------------------------------------
  group('getValidYear', () {
    test('year < 100 → year + 2000', () {
      expect(getValidYear(0), 2000);
      expect(getValidYear(24), 2024);
      expect(getValidYear(99), 2099);
    });

    test('100 ≤ year < 1900 → 2000 + (year % 100)', () {
      expect(getValidYear(100), 2000);
      expect(getValidYear(1800), 2000);
      expect(getValidYear(1899), 2099);
    });

    test('1900 ≤ year < 2100 → unchanged', () {
      expect(getValidYear(1900), 1900);
      expect(getValidYear(2000), 2000);
      expect(getValidYear(2099), 2099);
    });

    test('year ≥ 2100 → 2000 + (year % 100)', () {
      expect(getValidYear(2100), 2000);
      expect(getValidYear(2126), 2026);
      expect(getValidYear(2999), 2099);
    });
  });

  // ---------------------------------------------------------------------------
  group('Cal constructor', () {
    test('stores valid year, month, day', () {
      final cal = Cal(2024, 6, 15);
      expect(cal.year, 2024);
      expect(cal.month, 6);
      expect(cal.day, 15);
    });

    test('month underflow: month 0 rolls to Dec of prior year', () {
      // DateTime(2024, 0, 1) → 2023-12-01
      expect(Cal(2024, 0, 1), Cal(2023, 12, 1));
    });

    test('day underflow: day 0 rolls to last day of prior month', () {
      // DateTime(2024, 1, 0) → 2023-12-31
      expect(Cal(2024, 1, 0), Cal(2023, 12, 31));
    });

    test('month overflow: month 13 rolls to Jan of next year', () {
      // DateTime(2024, 13, 1) → 2025-01-01
      expect(Cal(2024, 13, 1), Cal(2025, 1, 1));
    });

    test('day overflow: day 32 in Jan rolls to Feb 1', () {
      // DateTime(2000, 1, 32) → 2000-02-01
      expect(Cal(2000, 1, 32), Cal(2000, 2, 1));
    });

    test('applies getValidYear: 2-digit year 99 → 2099', () {
      expect(Cal(99, 1, 1).year, 2099);
    });

    test('applies getValidYear: year 1899 → 2099', () {
      expect(Cal(1899, 6, 15).year, 2099);
    });

    test('applies getValidYear: year 2100 → 2000', () {
      expect(Cal(2100, 3, 1).year, 2000);
    });
  });

  // ---------------------------------------------------------------------------
  group('Cal.fromString', () {
    final thisYear = DateTime.now().year;

    // 8-digit YYYYMMDD
    test('8-digit: valid YYYYMMDD', () {
      expect(Cal.fromString('20240615'), Cal(2024, 6, 15));
    });

    test('8-digit: round-trips via yyyymmdd', () {
      expect(Cal.fromString('20190501').yyyymmdd, '20190501');
    });

    test('8-digit: year 1900 (lower boundary) is valid', () {
      expect(Cal.fromString('19000101'), Cal(1900, 1, 1));
    });

    test('8-digit: year 2099 (upper boundary) is valid', () {
      expect(Cal.fromString('20991231'), Cal(2099, 12, 31));
    });

    test('8-digit: year < 1900 → getValidYear remaps (1899 → 2099)', () {
      final cal = Cal.fromString('18991231');
      expect(cal.year, 2099);
      expect(cal.month, 12);
      expect(cal.day, 31);
    });

    test('8-digit: year ≥ 2100 → getValidYear remaps (2100 → 2000)', () {
      final cal = Cal.fromString('21000101');
      expect(cal.year, 2000);
      expect(cal.month, 1);
      expect(cal.day, 1);
    });

    // 6-digit YYMMDD
    test('6-digit: 2-digit year gets +2000 via getValidYear', () {
      expect(Cal.fromString('240615'), Cal(2024, 6, 15));
    });

    test('6-digit: year 00 → 2000', () {
      expect(Cal.fromString('000101'), Cal(2000, 1, 1));
    });

    // 4-digit MMDD
    test('4-digit: MMDD uses current year', () {
      expect(Cal.fromString('0615'), Cal(thisYear, 6, 15));
    });

    // 3-digit MDD
    test('3-digit: MDD uses current year', () {
      expect(Cal.fromString('615'), Cal(thisYear, 6, 15));
    });

    test('3-digit: single-digit month', () {
      expect(Cal.fromString('101'), Cal(thisYear, 1, 1));
    });

    // Separator YYYY-M-D (3 numeric groups)
    test('separator: YYYY-MM-DD', () {
      expect(Cal.fromString('2024-06-15'), Cal(2024, 6, 15));
    });

    test('separator: YYYY/MM/DD', () {
      expect(Cal.fromString('2024/06/15'), Cal(2024, 6, 15));
    });

    test('separator: YYYY年MM月DD日', () {
      expect(Cal.fromString('2024年06月15日'), Cal(2024, 6, 15));
    });

    test('separator: 2-digit year → +2000', () {
      expect(Cal.fromString('24-6-15'), Cal(2024, 6, 15));
    });

    test('separator: year 0 → 2000', () {
      expect(Cal.fromString('0-1-1'), Cal(2000, 1, 1));
    });

    // Separator MM-DD (2 numeric groups, uses current year)
    test('separator: MM-DD uses current year', () {
      expect(Cal.fromString('06-15'), Cal(thisYear, 6, 15));
    });

    test('separator: MM月DD日 uses current year', () {
      expect(Cal.fromString('6月15日'), Cal(thisYear, 6, 15));
    });

    // Full-width input
    test('full-width digits are converted before parsing', () {
      expect(Cal.fromString('２０２４０６１５'), Cal(2024, 6, 15));
    });

    // DateTime normalization (overflow/underflow propagated through Cal constructor)
    test('month 0 normalizes to Dec of prior year', () {
      expect(Cal.fromString('20000001'), Cal(1999, 12, 1));
    });

    test('day 0 normalizes to last day of prior month', () {
      expect(Cal.fromString('20000100'), Cal(1999, 12, 31));
    });

    test('day 32 in January normalizes to Feb 1', () {
      expect(Cal.fromString('20000132'), Cal(2000, 2, 1));
    });

    // Unrecognised / unhandled inputs → today
    test('empty string returns today', () {
      expectToday(Cal.fromString(''));
    });

    test('whitespace-only string returns today', () {
      expectToday(Cal.fromString('   '));
    });

    test('non-numeric string returns today', () {
      expectToday(Cal.fromString('abc'));
    });

    test('2-digit numeric string (unhandled length) returns today', () {
      expectToday(Cal.fromString('06'));
    });

    test('5-digit numeric string (unhandled length) returns today', () {
      expectToday(Cal.fromString('06152'));
    });

    test('7-digit numeric string (unhandled length) returns today', () {
      expectToday(Cal.fromString('2024061'));
    });

    test(
      'single numeric group (no separators, no matching length) returns today',
      () {
        // '2024x' → 1 numeric group → no 2-group or 3-group match → today
        expectToday(Cal.fromString('2024x'));
      },
    );
  });

  // ---------------------------------------------------------------------------
  group('Cal.fromDateTime', () {
    test('creates Cal from a DateTime', () {
      expect(Cal.fromDateTime(DateTime(2024, 6, 15)), Cal(2024, 6, 15));
    });

    test('applies getValidYear to the DateTime year', () {
      // DateTime year 2100 → getValidYear → 2000
      expect(Cal.fromDateTime(DateTime(2100, 1, 1)).year, 2000);
    });
  });

  // ---------------------------------------------------------------------------
  group('Cal properties', () {
    test('yyyymmdd returns zero-padded 8-char string', () {
      expect(Cal(2024, 1, 7).yyyymmdd, '20240107');
      expect(Cal(2024, 12, 31).yyyymmdd, '20241231');
    });

    test('yyyy returns the year as a string', () {
      expect(Cal(2024, 6, 15).yyyy, '2024');
    });

    test('mmdd returns zero-padded month+day', () {
      expect(Cal(2024, 1, 7).mmdd, '0107');
      expect(Cal(2024, 12, 31).mmdd, '1231');
    });
  });

  // ---------------------------------------------------------------------------
  group('Cal.compareTo', () {
    test('earlier date is less than later date', () {
      expect(Cal(2024, 1, 1).compareTo(Cal(2024, 12, 31)), isNegative);
      expect(Cal(2024, 12, 31).compareTo(Cal(2024, 1, 1)), isPositive);
    });

    test('same date compares as equal', () {
      expect(Cal(2024, 6, 15).compareTo(Cal(2024, 6, 15)), 0);
    });

    test('orders by year first', () {
      expect(Cal(2023, 12, 31).compareTo(Cal(2024, 1, 1)), isNegative);
    });

    test('orders by month when year is equal', () {
      expect(Cal(2024, 1, 31).compareTo(Cal(2024, 2, 1)), isNegative);
    });

    test('orders by day when year and month are equal', () {
      expect(Cal(2024, 6, 1).compareTo(Cal(2024, 6, 2)), isNegative);
    });

    test('list sorts in ascending date order', () {
      final list = [Cal(2024, 9, 1), Cal(2024, 1, 1), Cal(2024, 6, 1)]..sort();
      expect(list.map((c) => c.yyyymmdd).toList(), [
        '20240101',
        '20240601',
        '20240901',
      ]);
    });
  });

  // ---------------------------------------------------------------------------
  group('Cal.==', () {
    test('equal for same year, month, day', () {
      expect(Cal(2024, 6, 15), Cal(2024, 6, 15));
    });

    test('not equal for different year', () {
      expect(Cal(2023, 6, 15), isNot(Cal(2024, 6, 15)));
    });

    test('not equal for different month', () {
      expect(Cal(2024, 5, 15), isNot(Cal(2024, 6, 15)));
    });

    test('not equal for different day', () {
      expect(Cal(2024, 6, 14), isNot(Cal(2024, 6, 15)));
    });
  });

  // ---------------------------------------------------------------------------
  group('Cal.hashCode', () {
    test('equal dates have equal hashCodes', () {
      expect(Cal(2024, 6, 15).hashCode, Cal(2024, 6, 15).hashCode);
    });

    test('can be used as a map key', () {
      final map = {Cal(2024, 1, 1): 'New Year'};
      expect(map[Cal(2024, 1, 1)], 'New Year');
    });
  });

  // ---------------------------------------------------------------------------
  group('Cal.weekDayLabel', () {
    // 2024-01-07 Sun, 08 Mon, 09 Tue, 10 Wed, 11 Thu, 12 Fri, 13 Sat
    test('Sunday → 日', () => expect(Cal(2024, 1, 7).weekDayLabel, '日'));
    test('Monday → 月', () => expect(Cal(2024, 1, 8).weekDayLabel, '月'));
    test('Tuesday → 火', () => expect(Cal(2024, 1, 9).weekDayLabel, '火'));
    test('Wednesday → 水', () => expect(Cal(2024, 1, 10).weekDayLabel, '水'));
    test('Thursday → 木', () => expect(Cal(2024, 1, 11).weekDayLabel, '木'));
    test('Friday → 金', () => expect(Cal(2024, 1, 12).weekDayLabel, '金'));
    test('Saturday → 土', () => expect(Cal(2024, 1, 13).weekDayLabel, '土'));
  });
}
