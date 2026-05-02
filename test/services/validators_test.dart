import 'package:flutter_test/flutter_test.dart';
import 'package:yukyuchecker/models/nengo.dart';
import 'package:yukyuchecker/models/holidays.dart';
import 'package:yukyuchecker/services/validators.dart';
import '../test_utils.dart';

void main() {
  group('validateRequiredEmail', () {
    test('returns error for empty string', () {
      expect(validateRequiredEmail(''), isNotNull);
    });

    test('returns error for null', () {
      expect(validateRequiredEmail(null), isNotNull);
    });

    test('returns error for missing @ symbol', () {
      expect(validateRequiredEmail('notanemail'), isNotNull);
    });

    test('returns error for missing domain', () {
      expect(validateRequiredEmail('user@'), isNotNull);
    });

    test('returns null for valid email', () {
      expect(validateRequiredEmail('user@example.com'), isNull);
    });
  });

  group('validateRequiredPassword', () {
    test('returns error for empty string', () {
      expect(validateRequiredPassword(''), isNotNull);
    });

    test('returns error for null', () {
      expect(validateRequiredPassword(null), isNotNull);
    });

    test('returns null for non-empty password', () {
      expect(validateRequiredPassword('secret'), isNull);
    });
  });

  group('validateConfirmation', () {
    test('returns error for empty confirmation', () {
      expect(validateConfirmation('abc', ''), isNotNull);
    });

    test('returns error for null confirmation', () {
      expect(validateConfirmation('abc', null), isNotNull);
    });

    test('returns error when confirmation does not match', () {
      expect(validateConfirmation('abc', 'xyz'), isNotNull);
    });

    test('returns null when confirmation matches', () {
      expect(validateConfirmation('abc', 'abc'), isNull);
    });
  });

  group('validateNonNegInt', () {
    test('returns error for null', () {
      expect(validateNonNegInt(null), isNotNull);
    });

    test('returns error for non-numeric string', () {
      expect(validateNonNegInt('abc'), isNotNull);
    });

    test('returns error for negative integer', () {
      expect(validateNonNegInt('-1'), isNotNull);
    });

    test('returns null for zero', () {
      expect(validateNonNegInt('0'), isNull);
    });

    test('returns null for positive integer', () {
      expect(validateNonNegInt('10'), isNull);
    });
  });

  group('validateYear', () {
    final nengo = Nengo(gengos(), false);

    test('returns error for empty string', () {
      expect(validateYear(nengo, ''), isNotNull);
    });

    test('returns error for null', () {
      expect(validateYear(nengo, null), isNotNull);
    });

    test('returns error for year before 1900', () {
      expect(validateYear(nengo, '1899'), isNotNull);
    });

    test('returns null for valid Gregorian year', () {
      expect(validateYear(nengo, '2024'), isNull);
    });

    test('returns null for valid nengo year (令和6)', () {
      expect(validateYear(nengo, '令和6'), isNull);
    });
  });

  group('validateMonth', () {
    test('returns error for null', () {
      expect(validateMonth(null), isNotNull);
    });

    test('returns error for 0', () {
      expect(validateMonth('0'), isNotNull);
    });

    test('returns error for 13', () {
      expect(validateMonth('13'), isNotNull);
    });

    test('returns null for 1', () {
      expect(validateMonth('1'), isNull);
    });

    test('returns null for 12', () {
      expect(validateMonth('12'), isNull);
    });
  });

  group('maxDayOfMonth', () {
    test('returns 31 for January', () {
      expect(maxDayOfMonth('2024', '1'), 31);
    });

    test('returns 28 for February in non-leap year', () {
      expect(maxDayOfMonth('2023', '2'), 28);
    });

    test('returns 29 for February in leap year', () {
      expect(maxDayOfMonth('2024', '2'), 29);
    });

    test('returns 30 for April', () {
      expect(maxDayOfMonth('2024', '4'), 30);
    });

    test('returns 31 for December', () {
      expect(maxDayOfMonth('2024', '12'), 31);
    });

    test('returns 31 (fallback) for null year', () {
      expect(maxDayOfMonth(null, '1'), 31);
    });

    test('returns 31 (fallback) for null month', () {
      expect(maxDayOfMonth('2024', null), 31);
    });
  });

  group('validateDay', () {
    final nengo = Nengo(gengos(), false);

    test('returns error for null', () {
      expect(validateDay(nengo, '2024', '1', null), isNotNull);
    });

    test('returns error for 0', () {
      expect(validateDay(nengo, '2024', '1', '0'), isNotNull);
    });

    test('returns error for day exceeding month max', () {
      expect(
        validateDay(nengo, '2023', '2', '29'),
        isNotNull,
      ); // 2023 is not a leap year
    });

    test('returns null for valid day', () {
      expect(validateDay(nengo, '2024', '1', '31'), isNull);
    });

    test('returns null for Feb 29 in leap year', () {
      expect(validateDay(nengo, '2024', '2', '29'), isNull);
    });
  });

  group('validateHoliday', () {
    final holidays = [Holiday.fromString('20240101', name: '元日')];

    test('returns error when date is already registered', () {
      expect(validateHoliday(holidays, 2024, 1, 1), isNotNull);
    });

    test('returns null for unregistered date', () {
      expect(validateHoliday(holidays, 2024, 1, 2), isNull);
    });

    test('returns null for empty holidays list', () {
      expect(validateHoliday([], 2024, 1, 1), isNull);
    });
  });

  group('validateHhmmOptional', () {
    test('returns null for null (optional)', () {
      expect(validateHhmmOptional(null), isNull);
    });

    test('returns null for empty string (optional)', () {
      expect(validateHhmmOptional(''), isNull);
    });

    test('returns error for string without colon', () {
      expect(validateHhmmOptional('0800'), isNotNull);
    });

    test('returns error for non-numeric parts', () {
      expect(validateHhmmOptional('ab:cd'), isNotNull);
    });

    test('returns error for hours out of range', () {
      expect(validateHhmmOptional('24:00'), isNotNull);
    });

    test('returns error for minutes out of range', () {
      expect(validateHhmmOptional('08:61'), isNotNull);
    });

    test('returns null for valid "08:00"', () {
      expect(validateHhmmOptional('08:00'), isNull);
    });

    test('returns null for "00:00"', () {
      expect(validateHhmmOptional('00:00'), isNull);
    });

    test('returns null for "23:60" (boundary)', () {
      expect(validateHhmmOptional('23:60'), isNull);
    });
  });
}
