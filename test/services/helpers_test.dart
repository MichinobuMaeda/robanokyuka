import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:yukyuchecker/services/helpers.dart';

void main() {
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

    test('short: omits leading zero on hour', () {
      expect(padHhmm('8:5', short: true), '8:05');
      expect(padHhmm('08:30', short: true), '8:30');
    });

    test('short: multi-digit hour is unchanged', () {
      expect(padHhmm('10:05', short: true), '10:05');
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
}
