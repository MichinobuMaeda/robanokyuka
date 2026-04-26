import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:yukyuchecker/models/gengo.dart';
import 'package:yukyuchecker/services/helpers.dart';

void main() {
  group('dateToWeekday', () {
    test('returns 日 for Sunday', () {
      // 2024-01-07 is a Sunday
      expect(dateToWeekday('20240107'), '日');
    });

    test('returns 月 for Monday', () {
      // 2024-01-08 is a Monday
      expect(dateToWeekday('20240108'), '月');
    });

    test('returns 土 for Saturday', () {
      // 2024-01-06 is a Saturday
      expect(dateToWeekday('20240106'), '土');
    });
  });

  group('padHhmm', () {
    test('returns null for null input', () {
      expect(padHhmm(null), isNull);
    });

    test('returns empty string unchanged', () {
      expect(padHhmm(''), '');
    });

    test('pads single-digit hour and minute', () {
      expect(padHhmm('8:5'), '08:05');
    });

    test('does not double-pad already padded values', () {
      expect(padHhmm('08:30'), '08:30');
    });

    test('parses 4-char hhmm without colon', () {
      expect(padHhmm('0830'), '08:30');
    });

    test('parses 3-char hmm without colon', () {
      expect(padHhmm('830'), '08:30');
    });

    test('returns other no-colon strings unchanged', () {
      expect(padHhmm('8'), '8');
      expect(padHhmm('83'), '83');
    });
  });

  group('toHankaku', () {
    test('converts full-width digits to half-width', () {
      expect(toHankaku('０１２３４５６７８９'), '0123456789');
    });

    test('converts full-width uppercase letters to half-width', () {
      expect(toHankaku('ＡＢＣ'), 'ABC');
    });

    test('converts full-width lowercase letters to half-width', () {
      expect(toHankaku('ａｂｃ'), 'abc');
    });

    test('converts full-width space to half-width space', () {
      expect(toHankaku('　'), ' ');
    });

    test('converts full-width hyphen variants to hyphen', () {
      expect(toHankaku('－'), '-');
      expect(toHankaku('ー'), '-');
    });

    test('passes through already half-width strings unchanged', () {
      expect(toHankaku('abc123'), 'abc123');
    });
  });

  group('parseNengo', () {
    final gengos = [
      Gengo(date: '18680125', name: '明治', short: 'M'),
      Gengo(date: '19120730', name: '大正', short: 'T'),
      Gengo(date: '19261225', name: '昭和', short: 'S'),
      Gengo(date: '19890108', name: '平成', short: 'H'),
      Gengo(date: '20190501', name: '令和', short: 'R'),
    ];

    test('converts 令和6 to 2024', () {
      expect(parseNengo(gengos, '令和6'), '2024');
    });

    test('converts R6 (uppercase short) to 2024', () {
      expect(parseNengo(gengos, 'R6'), '2024');
    });

    test('converts 平成1 to 1989', () {
      expect(parseNengo(gengos, '平成1'), '1989');
    });

    test('converts H1 to 1989', () {
      expect(parseNengo(gengos, 'H1'), '1989');
    });

    test('converts 昭和64 to 1989', () {
      expect(parseNengo(gengos, '昭和64'), '1989');
    });

    test('converts 大正1 to 1912', () {
      expect(parseNengo(gengos, '大正1'), '1912');
    });

    test('converts 明治1 to 1868', () {
      expect(parseNengo(gengos, '明治1'), '1868');
    });

    test('converts full-width 令和６ to 2024 via toHankaku', () {
      expect(parseNengo(gengos, '令和６'), '2024');
    });

    test('returns original string for unknown era', () {
      expect(parseNengo(gengos, '未来1'), '未来1');
    });

    test('returns original string for plain non-era input', () {
      expect(parseNengo(gengos, '2024'), '2024');
    });
  });

  group('SnackBarMessageNotifier', () {
    test('build() returns null by default', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(snackBarMessageProvider), isNull);
    });

    test('show() sets the message', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(snackBarMessageProvider.notifier).show('hello');

      expect(container.read(snackBarMessageProvider), 'hello');
    });

    test('clear() resets to null', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(snackBarMessageProvider.notifier).show('hello');
      container.read(snackBarMessageProvider.notifier).clear();

      expect(container.read(snackBarMessageProvider), isNull);
    });

    test('show() overwrites a previous message', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(snackBarMessageProvider.notifier).show('first');
      container.read(snackBarMessageProvider.notifier).show('second');

      expect(container.read(snackBarMessageProvider), 'second');
    });
  });

  group('formatDate', () {
    final gengos = [
      Gengo(date: '18680125', name: '明治', short: 'M'),
      Gengo(date: '19120730', name: '大正', short: 'T'),
      Gengo(date: '19261225', name: '昭和', short: 'S'),
      Gengo(date: '19890108', name: '平成', short: 'H'),
      Gengo(date: '20190501', name: '令和', short: 'R'),
    ];

    test('returns yyyy年m月d日 when showNengo is false', () {
      expect(formatDate('20240107', gengos, false), '2024年1月7日');
    });

    test('returns nengo year m月d日 when showNengo is true', () {
      // 2024 = 令和6年
      expect(formatDate('20240107', gengos, true), '令和6年1月7日');
    });

    test('returns correct nengo for first day of new era (令和)', () {
      // 2019-05-01 = 令和1年
      expect(formatDate('20190501', gengos, true), '令和1年5月1日');
    });

    test('returns previous era for day before era change', () {
      // 2019-04-30 = 平成31年
      expect(formatDate('20190430', gengos, true), '平成31年4月30日');
    });

    test(
      'returns year string when date predates all gengos and showNengo is true',
      () {
        expect(formatDate('18000101', [], true), '1800年1月1日');
      },
    );

    test('returns date unchanged for invalid date string', () {
      expect(formatDate('', gengos, false), '');
      expect(formatDate('2024010', gengos, false), '2024010');
      expect(formatDate('202401010', gengos, false), '202401010');
      expect(formatDate('2024-01-07', gengos, false), '2024-01-07');
    });
  });

  group('formatYmd', () {
    test('pads single-digit month and day', () {
      expect(formatYmd(2024, 1, 7), '20240107');
    });

    test('pads single-digit month, double-digit day', () {
      expect(formatYmd(2024, 3, 31), '20240331');
    });

    test('pads double-digit month, single-digit day', () {
      expect(formatYmd(2024, 12, 1), '20241201');
    });

    test('no padding needed for double-digit month and day', () {
      expect(formatYmd(2024, 12, 31), '20241231');
    });

    test('works for year boundaries', () {
      expect(formatYmd(2025, 1, 1), '20250101');
    });
  });

  group('joinYmd', () {
    test('pads single-digit month and day', () {
      expect(joinYmd('2024', '1', '7'), '20240107');
    });

    test('strips leading zeros from inputs', () {
      expect(joinYmd('2024', '03', '09'), '20240309');
    });

    test('handles double-digit month and day without padding', () {
      expect(joinYmd('2024', '12', '31'), '20241231');
    });

    test('handles full-width digit strings via int.parse', () {
      expect(joinYmd('2025', '1', '1'), '20250101');
    });
  });
}
