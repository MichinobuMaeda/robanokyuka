import 'package:yukyuchecker/models/service.dart';

import '../models/gengo.dart';
import '../services/helpers.dart';

final _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

String? validateRequiredEmail(String? value) {
  if (value == null || value.isEmpty) {
    return "メールアドレスを入力してください";
  }

  if (!_emailPattern.hasMatch(value)) {
    return "有効なメールアドレスを入力してください";
  }
  return null;
}

String? validateRequiredPassword(String? value) {
  if (value == null || value.isEmpty) {
    return "パスワードを入力してください";
  }
  return null;
}

String? validateConfirmation(String? original, String? value) {
  if (value == null || value.isEmpty) {
    return "確認のため再度入力してください";
  }
  if (value != original) {
    return "確認の入力内容が一致しません";
  }
  return null;
}

String? validateNonNegInt(String? value) {
  final n = int.tryParse(value ?? '');
  if (n == null) return '整数で入力してください';
  if (n < 0) return '0 以上で入力してください';
  return null;
}

String? validateYear(List<Gengo> gengos, String? value) {
  final yearParsed = parseNengo(gengos, value ?? '');
  if (yearParsed.isEmpty) return '必須項目です';
  final year = int.tryParse(yearParsed);
  if (year == null) return '数値で入力してください';
  if (year < 1900) return '1900年以降を入力してください';
  return null;
}

String? validateMonth(String? value) {
  final month = int.tryParse(value ?? '');
  if (month == null) return '数値で入力してください';
  if (month < 1 || month > 12) return '1-12 で入力してください';
  return null;
}

int maxDayOfMonth(String? yyyy, String? mm) {
  final year = yyyy != null ? int.tryParse(yyyy) : null;
  final month = mm != null ? int.tryParse(mm) : null;
  if (year == null || month == null) {
    return 31; // Fallback to max possible days
  }
  final nextMonth = month == 12
      ? DateTime(year + 1, 1)
      : DateTime(year, month + 1);
  return nextMonth.subtract(const Duration(days: 1)).day;
}

String? validateDay(
  List<Gengo> gengos,
  String? yearText,
  String? monthText,
  String? value,
) {
  final day = int.tryParse(value ?? '');
  if (day == null) return '数値で入力してください';
  final maxDoM = maxDayOfMonth(yearText, monthText);
  if (day < 1 || day > maxDoM) return '1-$maxDoM で入力してください';
  final year = yearText != null
      ? int.tryParse(parseNengo(gengos, yearText))
      : null;
  final month = monthText != null ? int.tryParse(monthText) : null;
  if (year != null && month != null) {
    final date = DateTime(year, month, day);
    if (date.year != year || date.month != month || date.day != day) {
      return '存在しない日付です';
    }
  }
  return null;
}

String? validateHoliday(List<Holiday> holidays, int year, int month, int day) {
  final key = formatYmd(year, month, day);
  if (holidays.any((h) => h.date == key)) {
    return 'この日付は既に登録されています';
  }
  return null;
}

String? validateHhmmOptional(String? value) {
  if (value == null || value.isEmpty) return null;
  final parts = value.split(':');
  if (parts.length != 2) return 'HH:MM の形式で入力してください';
  final hh = int.tryParse(parts[0]);
  final mm = int.tryParse(parts[1]);
  if (hh == null || mm == null) return 'HH:MM の形式で入力してください';
  if (hh < 0 || hh > 23) return '時は 0-23 で入力してください';
  if (mm < 0 || mm > 60) return '分は 00-60 で入力してください';
  return null;
}
