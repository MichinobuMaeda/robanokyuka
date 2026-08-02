import 'package:robanokyuka/models/holidays.dart';
import 'package:robanokyuka/services/helpers.dart';

import 'package:robanokyuka/models/cal.dart';
import 'package:robanokyuka/models/nengo.dart';

final _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
final minPasswordLength = 10;
final maxPasswordLength = 4096;
final maxNoteLength = 100;

String? validateRequired(String? value) {
  if (value == null || value.trim().isEmpty) {
    return "入力必須です";
  }
  return null;
}

String? validateRequiredEmail(String? value) {
  final requiredError = validateRequired(value);
  if (requiredError != null) {
    return requiredError;
  }

  if (!_emailPattern.hasMatch(value!)) {
    return "無効な形式のメールアドレスです";
  }
  return null;
}

String? validateRequiredPassword(String? value) {
  final requiredError = validateRequired(value);
  if (requiredError != null) {
    return requiredError;
  }
  if (value!.length < minPasswordLength) {
    return "$minPasswordLength 文字以上で入力してください";
  }
  if (value.length > maxPasswordLength) {
    return "$maxPasswordLength 文字以下で入力してください";
  }
  if (!RegExp(r'[A-Z]').hasMatch(value)) {
    return "英大文字を含めてください";
  }
  if (!RegExp(r'[a-z]').hasMatch(value)) {
    return "英小文字を含めてください";
  }
  if (!RegExp(r'[0-9]').hasMatch(value)) {
    return "数字を含めてください";
  }
  if (!RegExp(r'[^A-Za-z0-9]').hasMatch(value)) {
    return "記号を含めてください";
  }
  return null;
}

String? validateConfirmation(String? original, String? value) {
  final requiredError = validateRequired(value);
  if (requiredError != null) {
    return requiredError;
  }
  if (value != original) {
    return "入力内容が一致しません";
  }
  return null;
}

String? validateNonNegInt(String? value) {
  final requiredError = validateRequired(value);
  if (requiredError != null) {
    return requiredError;
  }
  final n = int.tryParse(value ?? '');
  if (n == null) return '整数で入力してください';
  if (n < 0) return '0 以上で入力してください';
  return null;
}

String? validateDate(Nengo nengo, String? value) {
  final requiredError = validateRequired(value);
  if (requiredError != null) {
    return requiredError;
  }
  return (nengo.parseDate(value!) == null ? '無効な形式の日付です' : null);
}

String? validateHoliday(List<Holiday> holidays, int year, int month, int day) {
  final date = Cal(year, month, day);
  if (holidays.any((h) => h.date == date)) {
    return '登録済みの日付です';
  }
  return null;
}

String? validateHhmmOptional(String? value) {
  if (value == null || value.trim().isEmpty) return null;
  final str = toHankaku(value);
  final parts = str.split(':');
  if (parts.length != 2) return 'H:MM の形式で入力してください';
  final hh = int.tryParse(parts[0]);
  final mm = int.tryParse(parts[1]);
  if (hh == null || mm == null) return 'H:MM の形式で入力してください';
  if (hh < 0 || hh > 47) return '時は 0-47 で入力してください';
  if (mm < 0 || mm > 59) return '分は 00-59 で入力してください';
  return null;
}
