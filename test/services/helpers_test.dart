import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:robanokyuka/models/cal.dart';
import 'package:robanokyuka/services/helpers.dart';

void main() {
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

  group('isUpdateAvailable', () {
    test('returns false when currentVersion is null', () {
      expect(isUpdateAvailable(null, '1.0.0+1'), isFalse);
    });

    test('returns false when latestVersion is null', () {
      expect(isUpdateAvailable('1.0.0+1', null), isFalse);
    });

    test('returns false when both are null', () {
      expect(isUpdateAvailable(null, null), isFalse);
    });

    test('returns false when versions are equal', () {
      expect(isUpdateAvailable('1.0.0+1', '1.0.0+1'), isFalse);
    });

    test('returns true when patch is newer (same major and minor)', () {
      expect(isUpdateAvailable('1.0.0+1', '1.0.1+1'), isTrue);
      expect(isUpdateAvailable('1.0.1+1', '1.0.2+1'), isTrue);
      expect(isUpdateAvailable('1.0.9+1', '1.0.10+1'), isTrue);
    });

    test('returns false when patch is older (same major and minor)', () {
      expect(isUpdateAvailable('1.0.1+1', '1.0.0+1'), isFalse);
      expect(isUpdateAvailable('1.0.10+1', '1.0.9+1'), isFalse);
    });

    test('returns false when patch is equal (same major and minor)', () {
      expect(isUpdateAvailable('1.0.1+1', '1.0.1+1'), isFalse);
    });

    test('returns true when minor is newer (same major)', () {
      expect(isUpdateAvailable('1.0.0+1', '1.1.0+1'), isTrue);
      expect(isUpdateAvailable('1.1.0+1', '1.2.0+1'), isTrue);
      expect(isUpdateAvailable('1.9.0+1', '1.10.0+1'), isTrue);
    });

    test('returns false when minor is older (same major)', () {
      expect(isUpdateAvailable('1.1.0+1', '1.0.0+1'), isFalse);
      expect(isUpdateAvailable('1.10.0+1', '1.9.0+1'), isFalse);
    });

    test('returns false when minor is equal (same major)', () {
      expect(isUpdateAvailable('1.1.0+1', '1.1.0+1'), isFalse);
    });

    test('returns true when major is newer', () {
      expect(isUpdateAvailable('1.0.0+1', '2.0.0+1'), isTrue);
    });

    test('returns true when build number is newer', () {
      expect(isUpdateAvailable('1.0.0+1', '1.0.0+2'), isTrue);
    });

    test('returns false when current is newer than latest', () {
      expect(isUpdateAvailable('2.0.0+1', '1.0.0+1'), isFalse);
    });

    test('major takes precedence over minor and patch', () {
      expect(isUpdateAvailable('2.9.9+9', '3.0.0+1'), isTrue);
      expect(isUpdateAvailable('3.0.0+1', '2.9.9+9'), isFalse);
      expect(isUpdateAvailable('10.0.0+1', '9.9.9+9'), isFalse);
    });

    test(
      'handles versions with fewer than 3 parts (missing parts default to 0)',
      () {
        expect(isUpdateAvailable('1.0', '1.0.1+1'), isTrue);
        expect(isUpdateAvailable('1', '1.0.0+1'), isTrue);
        expect(isUpdateAvailable('1.0', '1.0'), isFalse);
      },
    );
  });

  test('generateMonthList returns List of Cal between from and to', () {
    expect(generateMonthList(Cal(2024, 4, 1), Cal(2025, 3, 31)), [
      Cal(2024, 4, 1),
      Cal(2024, 5, 1),
      Cal(2024, 6, 1),
      Cal(2024, 7, 1),
      Cal(2024, 8, 1),
      Cal(2024, 9, 1),
      Cal(2024, 10, 1),
      Cal(2024, 11, 1),
      Cal(2024, 12, 1),
      Cal(2025, 1, 1),
      Cal(2025, 2, 1),
      Cal(2025, 3, 1),
    ]);
    expect(generateMonthList(Cal(2024, 4, 1), Cal(2024, 3, 31)), []);
  });
}
