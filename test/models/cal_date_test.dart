import 'package:flutter_test/flutter_test.dart';
import 'package:yukyuchecker/models/cal_date.dart';

void main() {
  group('Cal', () {
    test('stores year, month, day', () {
      final cal = Cal(2024, 6, 15);
      expect(cal.year, 2024);
      expect(cal.month, 6);
      expect(cal.day, 15);
    });

    test('date returns zero-padded yyyymmdd string', () {
      expect(Cal(2024, 1, 7).yyyymmdd, '20240107');
      expect(Cal(2024, 12, 31).yyyymmdd, '20241231');
    });
  });

  group('Cal.fromString', () {
    test('parses a yyyymmdd string', () {
      final cal = Cal.fromYyyymmdd('20240615');
      expect(cal.year, 2024);
      expect(cal.month, 6);
      expect(cal.day, 15);
    });

    test('date round-trips correctly', () {
      const date = '20190501';
      expect(Cal.fromYyyymmdd(date).yyyymmdd, date);
    });
  });

  group('Cal.compareTo', () {
    test('earlier date is less than later date', () {
      final jan = Cal.fromYyyymmdd('20240101');
      final dec = Cal.fromYyyymmdd('20241231');
      expect(jan.compareTo(dec), isNegative);
      expect(dec.compareTo(jan), isPositive);
    });

    test('same date compares as equal', () {
      final a = Cal.fromYyyymmdd('20240615');
      final b = Cal.fromYyyymmdd('20240615');
      expect(a.compareTo(b), 0);
    });

    test('orders by year first', () {
      final y2023 = Cal(2023, 12, 31);
      final y2024 = Cal(2024, 1, 1);
      expect(y2023.compareTo(y2024), isNegative);
    });

    test('orders by month when year is equal', () {
      final jan = Cal(2024, 1, 31);
      final feb = Cal(2024, 2, 1);
      expect(jan.compareTo(feb), isNegative);
    });

    test('orders by day when year and month are equal', () {
      final d1 = Cal(2024, 6, 1);
      final d2 = Cal(2024, 6, 2);
      expect(d1.compareTo(d2), isNegative);
    });

    test('list sorts in ascending date order', () {
      final list = [
        Cal.fromYyyymmdd('20240901'),
        Cal.fromYyyymmdd('20240101'),
        Cal.fromYyyymmdd('20240601'),
      ]..sort();
      expect(list.map((c) => c.yyyymmdd).toList(), [
        '20240101',
        '20240601',
        '20240901',
      ]);
    });
  });

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

  group('Cal.hashCode', () {
    test('equal dates have equal hashCodes', () {
      final a = Cal(2024, 6, 15);
      final b = Cal(2024, 6, 15);
      expect(a.hashCode, b.hashCode);
    });

    test('can be used as a map key', () {
      final map = {Cal(2024, 1, 1): 'New Year'};
      expect(map[Cal(2024, 1, 1)], 'New Year');
    });
  });

  group('Cal.weekDayLabel', () {
    // 2024/01/07 is Sunday  (weekday 7, 7 % 7 = 0 → '日')
    // 2024/01/08 is Monday  (weekday 1, 1 % 7 = 1 → '月')
    // 2024/01/09 is Tuesday (weekday 2, 2 % 7 = 2 → '火')
    // 2024/01/10 is Wednesday (weekday 3 → '水')
    // 2024/01/11 is Thursday  (weekday 4 → '木')
    // 2024/01/12 is Friday    (weekday 5 → '金')
    // 2024/01/13 is Saturday  (weekday 6 → '土')
    test('Sunday returns 日', () {
      expect(Cal(2024, 1, 7).weekDayLabel, '日');
    });

    test('Monday returns 月', () {
      expect(Cal(2024, 1, 8).weekDayLabel, '月');
    });

    test('Tuesday returns 火', () {
      expect(Cal(2024, 1, 9).weekDayLabel, '火');
    });

    test('Wednesday returns 水', () {
      expect(Cal(2024, 1, 10).weekDayLabel, '水');
    });

    test('Thursday returns 木', () {
      expect(Cal(2024, 1, 11).weekDayLabel, '木');
    });

    test('Friday returns 金', () {
      expect(Cal(2024, 1, 12).weekDayLabel, '金');
    });

    test('Saturday returns 土', () {
      expect(Cal(2024, 1, 13).weekDayLabel, '土');
    });
  });
}
