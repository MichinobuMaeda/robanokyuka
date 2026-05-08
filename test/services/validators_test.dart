import 'package:flutter_test/flutter_test.dart';
import 'package:robanokyuka/models/nengo.dart';
import 'package:robanokyuka/models/holidays.dart';
import 'package:robanokyuka/services/validators.dart';
import '../test_utils.dart';

const requiredError = '入力必須です';

void main() {
  group('validateRequired', () {
    test('returns error for null', () {
      expect(validateRequired(null), requiredError);
    });

    test('returns error for empty string', () {
      expect(validateRequired(''), requiredError);
    });

    test('returns error for whitespace-only string', () {
      expect(validateRequired('  '), requiredError);
    });

    test('returns null for non-empty string', () {
      expect(validateRequired('a'), isNull);
    });
  });

  group('validateRequiredEmail', () {
    test('returns error for empty string', () {
      expect(validateRequiredEmail(''), requiredError);
    });

    test('returns error for null', () {
      expect(validateRequiredEmail(null), requiredError);
    });

    test('returns error for missing @ symbol', () {
      expect(validateRequiredEmail('notanemail'), '無効な形式のメールアドレスです');
    });

    test('returns error for missing domain', () {
      expect(validateRequiredEmail('user@'), '無効な形式のメールアドレスです');
    });

    test('returns null for valid email', () {
      expect(validateRequiredEmail('user@example.com'), isNull);
    });
  });

  group('validateConfirmation', () {
    test('returns error for empty confirmation', () {
      expect(validateConfirmation('abc', ''), requiredError);
    });

    test('returns error for null confirmation', () {
      expect(validateConfirmation('abc', null), requiredError);
    });

    test('returns error when confirmation does not match', () {
      expect(validateConfirmation('abc', 'xyz'), '入力内容が一致しません');
    });

    test('returns null when confirmation matches', () {
      expect(validateConfirmation('abc', 'abc'), isNull);
    });
  });

  group('validateNonNegInt', () {
    test('returns error for null', () {
      expect(validateNonNegInt(null), requiredError);
    });

    test('returns error for non-numeric string', () {
      expect(validateNonNegInt('abc'), '整数で入力してください');
    });

    test('returns error for negative integer', () {
      expect(validateNonNegInt('-1'), '0 以上で入力してください');
    });

    test('returns null for zero', () {
      expect(validateNonNegInt('0'), isNull);
    });

    test('returns null for positive integer', () {
      expect(validateNonNegInt('10'), isNull);
    });
  });

  group('validateHoliday', () {
    final holidays = [Holiday.fromString('20240101', name: '元日')];

    test('returns error when date is already registered', () {
      expect(validateHoliday(holidays, 2024, 1, 1), '登録済みの日付です');
    });

    test('returns null for unregistered date', () {
      expect(validateHoliday(holidays, 2024, 1, 2), isNull);
    });

    test('returns null for empty holidays list', () {
      expect(validateHoliday([], 2024, 1, 1), isNull);
    });
  });

  group('validateDate', () {
    final nengo = Nengo(gengos(), true);

    // --- null / empty → required error ---
    test('returns required error for null', () {
      expect(validateDate(nengo, null), requiredError);
    });

    test('returns required error for empty string', () {
      expect(validateDate(nengo, ''), requiredError);
    });

    test('returns required error for whitespace-only string', () {
      expect(validateDate(nengo, '  '), requiredError);
    });

    // --- Digit-leading strings → always valid (parseDate returns Cal) ---
    test('returns null for 8-digit YYYYMMDD', () {
      expect(validateDate(nengo, '20240615'), isNull);
    });

    test('returns null for 4-digit MMDD', () {
      expect(validateDate(nengo, '0615'), isNull);
    });

    test('returns null for 3-digit MDD', () {
      expect(validateDate(nengo, '615'), isNull);
    });

    test('returns null for all-digit month 00 (normalizes via DateTime)', () {
      expect(validateDate(nengo, '20240001'), isNull);
    });

    test('returns null for YYYY-MM-DD', () {
      expect(validateDate(nengo, '2024-06-15'), isNull);
    });

    test('returns null for MM-DD', () {
      expect(validateDate(nengo, '06-15'), isNull);
    });

    test('returns null for digit-leading date with kanji (6月15日)', () {
      expect(validateDate(nengo, '6月15日'), isNull);
    });

    // --- Non-digit-leading, non-era strings → error ---
    test('returns error for plain text', () {
      expect(validateDate(nengo, 'abc'), '無効な形式の日付です');
    });

    // --- Era-format strings (non-digit prefix + 3 numeric groups) → valid ---
    test('returns null for 令和6年1月7日', () {
      expect(validateDate(nengo, '令和6年1月7日'), isNull);
    });

    test('returns null for 大正元年1月1日', () {
      expect(validateDate(nengo, '大正元年1月1日'), isNull);
    });

    test('returns null for short era code T1-1-1', () {
      expect(validateDate(nengo, 'T1-1-1'), isNull);
    });

    // Era string with only 2 numeric groups → error
    test('returns error for era string with only 2 numeric groups', () {
      expect(validateDate(nengo, '令和6年1月'), '無効な形式の日付です');
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
      expect(validateHhmmOptional('0800'), 'H:MM の形式で入力してください');
    });

    test('returns error for non-numeric parts', () {
      expect(validateHhmmOptional('ab:cd'), 'H:MM の形式で入力してください');
    });

    test('returns error for hours out of range', () {
      expect(validateHhmmOptional('24:00'), '時は 0-23 で入力してください');
    });

    test('returns error for minutes out of range', () {
      expect(validateHhmmOptional('08:61'), '分は 00-60 で入力してください');
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
