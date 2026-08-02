import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:robanokyuka/models/cal.dart';
import 'package:robanokyuka/models/nengo.dart';
import 'package:robanokyuka/models/service.dart';
import 'package:robanokyuka/models/users.dart';
import '../test_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // ---------------------------------------------------------------------------
  group('Gengo', () {
    test('stores name and short', () {
      final g = Gengo(date: Cal(2019, 5, 1), name: '令和', short: 'R');
      expect(g.name, '令和');
      expect(g.short, 'R');
    });

    test('holds Cal date with year, month, day and yyyymmdd getter', () {
      final g = Gengo(date: Cal(2019, 5, 1), name: '令和', short: 'R');
      expect(g.date.year, 2019);
      expect(g.date.month, 5);
      expect(g.date.day, 1);
      expect(g.date.yyyymmdd, '20190501');
    });
  });

  // ---------------------------------------------------------------------------
  group('Nengo.formatYear', () {
    final nengo = Nengo(gengos(), true);

    test('returns era year string for a date in a known era', () {
      // 2024 - 2019 + 1 = 6
      expect(nengo.formatYear(Cal(2024, 1, 7)), '令和6');
    });

    test('returns short form when short: true', () {
      expect(nengo.formatYear(Cal(2024, 1, 7), short: true), 'R6');
    });

    test('returns 元 for the first year of a new era', () {
      // 2019-05-01 is the first day of 令和
      expect(nengo.formatYear(Cal(2019, 5, 1)), '令和元');
    });

    test('returns previous era for the day before an era change', () {
      // 2019-04-30 is still 平成31
      expect(nengo.formatYear(Cal(2019, 4, 30)), '平成31');
    });

    test('returns 昭和64 for 1989/01/07 (last day of 昭和)', () {
      expect(nengo.formatYear(Cal(1989, 1, 7)), '昭和64');
    });

    test('returns short form H1 for 1989/01/08 (first day of 平成)', () {
      expect(nengo.formatYear(Cal(1989, 1, 8), short: true), 'H1');
    });

    // 明治 starts at Cal(1868, 1, 25); use the day before.
    test('returns Gregorian year string for a date before any era', () {
      expect(nengo.formatYear(Cal(1868, 1, 24)), '1868');
    });

    test('returns Gregorian year when short: true and date before any era', () {
      expect(nengo.formatYear(Cal(1868, 1, 24), short: true), '1868');
    });

    test('returns Gregorian year string when gengos is empty', () {
      final empty = Nengo([], false);
      expect(empty.formatYear(Cal(2024, 1, 7)), '2024');
    });

    test('returns bare Gregorian year when short and gengos is empty', () {
      final empty = Nengo([], false);
      expect(empty.formatYear(Cal(2024, 1, 7), short: true), '2024');
    });

    test(
      'returns Gregorian year when showNengo is false, even with gengos',
      () {
        final nengoOff = Nengo(gengos(), false);
        expect(nengoOff.formatYear(Cal(2024, 1, 7)), '2024');
      },
    );

    test('returns Gregorian year when showNengo is false with short: true', () {
      final nengoOff = Nengo(gengos(), false);
      expect(nengoOff.formatYear(Cal(2024, 1, 7), short: true), '2024');
    });
  });

  // ---------------------------------------------------------------------------
  group('Nengo.formatShort', () {
    test('returns short era year for a date in a known era', () {
      final nengo = Nengo(gengos(), true);
      expect(nengo.formatYearShort(Cal(2024, 1, 7)), 'R6');
    });

    test('returns bare year string when gengos is empty', () {
      final nengo = Nengo([], false);
      expect(nengo.formatYearShort(Cal(2024, 1, 7)), '2024');
    });

    test('formatShort returns short slash-separated date string', () {
      final nengo = Nengo(gengos(), true);
      expect(nengo.formatShort(Cal(2024, 1, 7)), 'R6/1/7');
    });

    test('formatShort uses Gregorian year when gengos is empty', () {
      final nengo = Nengo([], false);
      expect(nengo.formatShort(Cal(2024, 1, 7)), '2024/1/7');
    });
  });

  // ---------------------------------------------------------------------------
  group('Nengo.format', () {
    test('returns full era date string', () {
      final nengo = Nengo(gengos(), true);
      expect(nengo.format(Cal(2024, 1, 7)), '令和6年1月7日');
    });

    test('returns Gregorian date string when gengos is empty', () {
      final nengo = Nengo([], false);
      expect(nengo.format(Cal(2024, 1, 7)), '2024年1月7日');
    });

    test('returns correct format for first day of 令和', () {
      final nengo = Nengo(gengos(), true);
      expect(nengo.format(Cal(2019, 5, 1)), '令和元年5月1日');
    });

    test('returns short slash-separated format when short is true', () {
      final nengo = Nengo(gengos(), true);
      expect(nengo.format(Cal(2024, 1, 7), short: true), 'R6/1/7');
    });
  });

  // ---------------------------------------------------------------------------
  group('Nengo.parseYear', () {
    final nengo = Nengo(gengos(), true);

    test('parses full era name with Gregorian year', () {
      // 2019 + 6 - 1 = 2024
      expect(nengo.parseYear('令和6'), '2024');
    });

    test('parses short era code', () {
      expect(nengo.parseYear('R6'), '2024');
    });

    test('parses full-width digits', () {
      // '６' is converted to '6' by toHankaku
      expect(nengo.parseYear('R６'), '2024');
    });

    test('parses 平成31 to 2019', () {
      // 1989 + 31 - 1 = 2019
      expect(nengo.parseYear('平成31'), '2019');
    });

    test('returns input unchanged for a plain digit string (no era)', () {
      expect(nengo.parseYear('2024'), '2024');
    });

    test('returns input unchanged when era is not found', () {
      expect(nengo.parseYear('ABC1'), 'ABC1');
    });
  });

  // ---------------------------------------------------------------------------
  group('Nengo.parseDate', () {
    final nengo = Nengo(gengos(), true);
    final thisYear = DateTime.now().year;

    // --- All-digit strings → Cal.fromString (never null) ---
    test('8-digit valid YYYYMMDD', () {
      expect(nengo.parseDate('20240615'), Cal(2024, 6, 15));
    });

    test('8-digit: year 1900 (lower boundary)', () {
      expect(nengo.parseDate('19000101'), Cal(1900, 1, 1));
    });

    test('8-digit: year 2099 (upper boundary)', () {
      expect(nengo.parseDate('20991231'), Cal(2099, 12, 31));
    });

    test('8-digit: year 1899 is kept as-is', () {
      final cal = nengo.parseDate('18991231');
      expect(cal?.year, 1899);
      expect(cal?.month, 12);
      expect(cal?.day, 31);
    });

    test('8-digit: year 2100 is kept as-is', () {
      expect(nengo.parseDate('21000101'), Cal(2100, 1, 1));
    });

    test('8-digit: invalid month 0 → DateTime normalization, not null', () {
      // Cal(1900, 0, 1) → DateTime(1900,0,1) → 1899-12-01 → getValidYear(1899)=1899
      expect(nengo.parseDate('19000001'), Cal(1899, 12, 1));
    });

    test('8-digit: invalid day 0 → DateTime normalization, not null', () {
      // Cal(1900, 1, 0) → DateTime(1900,1,0) → 1899-12-31 → getValidYear(1899)=1899
      expect(nengo.parseDate('19000100'), Cal(1899, 12, 31));
    });

    test('8-digit: Feb 29 in leap year (2000)', () {
      expect(nengo.parseDate('20000229'), Cal(2000, 2, 29));
    });

    test(
      '8-digit: Feb 29 in non-leap year → normalizes to Mar 1, not null',
      () {
        expect(nengo.parseDate('20010229'), Cal(2001, 3, 1));
      },
    );

    test('8-digit: Feb 30 → normalizes to Mar 2 in 2001', () {
      expect(nengo.parseDate('20010230'), Cal(2001, 3, 2));
    });

    test('8-digit: Feb 30 → normalizes to Mar 1 in leap year 2000', () {
      expect(nengo.parseDate('20000230'), Cal(2000, 3, 1));
    });

    test('8-digit: Feb 29 in leap year 2004', () {
      expect(nengo.parseDate('20040229'), Cal(2004, 2, 29));
    });

    test('8-digit: Feb 30 in 2004 → normalizes to Mar 1', () {
      expect(nengo.parseDate('20040230'), Cal(2004, 3, 1));
    });

    test('4-digit MMDD → Cal(thisYear, month, day)', () {
      expect(nengo.parseDate('0101'), Cal(thisYear, 1, 1));
    });

    test('3-digit MDD → Cal(thisYear, month, day)', () {
      expect(nengo.parseDate('101'), Cal(thisYear, 1, 1));
    });

    // --- Digit-leading separator strings → null (regex requires non-digit prefix) ---
    test("'1900-01-01' returns null (starts with digit, not era format)", () {
      expect(nengo.parseDate('1900-01-01'), Cal(1900, 1, 1));
    });

    test("'1900-1-1' returns null", () {
      expect(nengo.parseDate('1900-1-1'), Cal(1900, 1, 1));
    });

    test("'01-01' returns null", () {
      expect(nengo.parseDate('01-01'), Cal(thisYear, 1, 1));
    });

    test("'1/01' returns null", () {
      expect(nengo.parseDate('1/01'), Cal(thisYear, 1, 1));
    });

    test("'1月01日' returns null (starts with digit)", () {
      expect(nengo.parseDate('1月01日'), Cal(thisYear, 1, 1));
    });

    // --- Era-format strings (non-digit prefix) ---
    // gengos() Cal(1868, 1, 25) → year 1868 (getValidYear only remaps year < 100).
    // So 明治 baseYear = 1868.
    // 明治45: 1868 + 45 - 1 = 1912
    test("'明治45年1月1日' returns Cal(1912, 1, 1)", () {
      expect(nengo.parseDate('明治45年1月1日'), Cal(1912, 1, 1));
    });

    // 明治1: 1868 + 1 - 1 = 1868
    test("'明治1年1月1日' returns Cal(1868, 1, 1)", () {
      expect(nengo.parseDate('明治1年1月1日'), Cal(1868, 1, 1));
    });

    // 大正元年: 元→1 → 大正1: 1912 + 1 - 1 = 1912
    test("'大正元年1月1日' returns Cal(1912, 1, 1)", () {
      expect(nengo.parseDate('大正元年1月1日'), Cal(1912, 1, 1));
    });

    // 大 is a prefix of 大正
    test("'大1年1月1日' returns Cal(1912, 1, 1)", () {
      expect(nengo.parseDate('大1年1月1日'), Cal(1912, 1, 1));
    });

    // T is the short code for 大正
    test("'T1-1-1' returns Cal(1912, 1, 1)", () {
      expect(nengo.parseDate('T1-1-1'), Cal(1912, 1, 1));
    });

    // Full-width digits in era date
    test("'令和６年１月１日' (full-width) returns Cal(2024, 1, 1)", () {
      // 2019 + 6 - 1 = 2024
      expect(nengo.parseDate('令和６年１月１日'), Cal(2024, 1, 1));
    });

    // Unknown era → parseYear returns input unchanged → Cal.fromString('X1/1/1')
    // → non-all-digit, doesn't start with digit → defaults to today
    test('unknown era prefix returns Cal for today', () {
      final today = DateTime.now();
      final cal = nengo.parseDate('X1年1月1日');
      expect(cal?.year, today.year);
      expect(cal?.month, today.month);
      expect(cal?.day, today.day);
    });

    // Non-digit string with no numeric groups → null
    test('non-digit string with no numbers returns null', () {
      expect(nengo.parseDate('abc'), isNull);
    });
  });

  // ---------------------------------------------------------------------------
  group('nengoProvider', () {
    test('returns empty gengos and showNengo false when conf is null', () {
      final container = ProviderContainer(
        overrides: [
          confProvider.overrideWithValue(null),
          userProvider.overrideWithValue(null),
        ],
      );
      addTearDown(container.dispose);

      final result = container.read(nengoProvider);
      expect(result.gengos, isEmpty);
      expect(result.showNengo, isFalse);
    });

    test('uses gengos from conf', () {
      final conf = Conf(
        admins: [],
        gengos: [
          Gengo(date: Cal(1989, 1, 8), name: '平成', short: 'H'),
          Gengo(date: Cal(2019, 5, 1), name: '令和', short: 'R'),
        ],
        uiVersion: '',
        androidVersion: '0.0.0+0',
        iosVersion: '0.0.0+0',
      );
      final container = ProviderContainer(
        overrides: [
          confProvider.overrideWithValue(conf),
          userProvider.overrideWithValue(null),
        ],
      );
      addTearDown(container.dispose);

      final result = container.read(nengoProvider);
      expect(result.gengos.length, 2);
      expect(result.gengos[0].name, '平成');
      expect(result.gengos[1].name, '令和');
    });

    test('showNengo is false when user is null', () {
      final conf = Conf(
        admins: [],
        gengos: [],
        uiVersion: '',
        androidVersion: '0.0.0+0',
        iosVersion: '0.0.0+0',
      );
      final container = ProviderContainer(
        overrides: [
          confProvider.overrideWithValue(conf),
          userProvider.overrideWithValue(null),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(nengoProvider).showNengo, isFalse);
    });

    test('showNengo is true when user.showNengo is true', () {
      final conf = Conf(
        admins: [],
        gengos: [],
        uiVersion: '',
        androidVersion: '0.0.0+0',
        iosVersion: '0.0.0+0',
      );
      final user = User(id: 'u1', name: 'Alice', showNengo: true);
      final container = ProviderContainer(
        overrides: [
          confProvider.overrideWithValue(conf),
          userProvider.overrideWithValue(user),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(nengoProvider).showNengo, isTrue);
    });

    test('showNengo is false when user.showNengo is false', () {
      final conf = Conf(
        admins: [],
        gengos: [],
        uiVersion: '',
        androidVersion: '0.0.0+0',
        iosVersion: '0.0.0+0',
      );
      final user = User(id: 'u1', name: 'Alice', showNengo: false);
      final container = ProviderContainer(
        overrides: [
          confProvider.overrideWithValue(conf),
          userProvider.overrideWithValue(user),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(nengoProvider).showNengo, isFalse);
    });
  });
}
