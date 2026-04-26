import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../models/gengo.dart';

const assetAppLogo = 'assets/logo.png';
const assetGuestMd = 'assets/guest.md';
const assetReauthenticateMd = 'assets/reauthenticate.md';
const assetInfoMd = 'assets/info.md';
const weekDays = ['日', '月', '火', '水', '木', '金', '土'];

/// A [Notifier] that holds a nullable string message for displaying in a SnackBar.
class SnackBarMessageNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void show(String message) {
    state = message;
  }

  void clear() {
    state = null;
  }
}

/// A [NotifierProvider] that provides a [SnackBarMessageNotifier] for managing SnackBar messages.
final snackBarMessageProvider =
    NotifierProvider<SnackBarMessageNotifier, String?>(
      SnackBarMessageNotifier.new,
    );

/// Converts a date string (yyyymmdd) to its corresponding weekday in Japanese.
String dateToWeekday(String date) {
  return weekDays[parseYmd(date).weekday % 7];
}

/// Pads single-digit HH or MM parts in a "H:MM", "HH:M", or "H:M" string.
/// Also accepts no-colon inputs: 4-char 'hhmm' or 3-char 'hmm'.
String? padHhmm(String? hhmm) {
  if (hhmm == null || hhmm.isEmpty) return hhmm;
  if (!hhmm.contains(':')) {
    if (hhmm.length == 4) {
      return '${hhmm.substring(0, 2)}:${hhmm.substring(2)}';
    } else if (hhmm.length == 3) {
      return '0${hhmm.substring(0, 1)}:${hhmm.substring(1)}';
    } else {
      return hhmm;
    }
  }
  final parts = hhmm.split(':');
  final hh = parts[0].padLeft(2, '0');
  final mm = parts.length > 1 ? parts[1].padLeft(2, '0') : '00';
  return '$hh:$mm';
}

String parseNengo(List<Gengo> gengos, String nengo) {
  final str = toHankaku(
    nengo,
  ).toUpperCase().replaceAll(' ', '').replaceAll('年', '');
  final match = RegExp(r'([^\d]+)(\d+)').firstMatch(str);
  if (match == null) return nengo;
  final era = match.group(1)!;
  final year = int.parse(match.group(2)!);

  int? baseYear;

  for (var gengo in gengos) {
    if (gengo.name.startsWith(era) || gengo.short == era) {
      baseYear = int.parse(gengo.date.substring(0, 4));
      break;
    }
  }

  if (baseYear == null) return nengo;
  return (baseYear + year - 1).toString();
}

String formatNengo(List<Gengo> gengos, String date, {bool short = false}) {
  final String ymd = date.length == 8
      ? date
      : (date.length == 6
            ? formatYmd(
                int.parse(date.substring(0, 4)),
                int.parse(date.substring(4, 6)),
                1,
              )
            : formatYmd(
                int.parse(date.substring(0, 4)),
                1,
                1,
              )); // Fallback to Jan 1 if only year is given
  final year = int.parse(ymd.substring(0, 4));
  for (final gengo in gengos.reversed) {
    if (ymd.compareTo(gengo.date) >= 0) {
      return short
          ? '${gengo.short}${year - int.parse(gengo.date.substring(0, 4)) + 1}'
          : '${gengo.name}${year - int.parse(gengo.date.substring(0, 4)) + 1}年';
    }
  }
  return short ? '$year' : '$year年';
}

String formatDate(String date, List<Gengo> gengos, bool showNengo) {
  if (!RegExp(r'^\d{8}$').hasMatch(date)) return date;
  final year = int.parse(date.substring(0, 4));
  final month = int.parse(date.substring(4, 6));
  final day = int.parse(date.substring(6, 8));
  final nengo = formatNengo(gengos, date);
  return showNengo ? '$nengo$month月$day日' : '$year年$month月$day日';
}

String formatYmd(int year, int month, int day) {
  return '$year${month.toString().padLeft(2, '0')}${day.toString().padLeft(2, '0')}';
}

String joinYmd(String year, String month, String day) {
  return '${int.parse(year)}${int.parse(month).toString().padLeft(2, '0')}${int.parse(day).toString().padLeft(2, '0')}';
}

DateTime parseYmd(String ymd) {
  final year = int.parse(ymd.substring(0, 4));
  final month = int.parse(ymd.substring(4, 6));
  final day = int.parse(ymd.substring(6, 8));
  return DateTime(year, month, day);
}

String toHankaku(String str) => str
    .replaceAll('　', ' ')
    .replaceAll('＠', '@')
    .replaceAll('．', '.')
    .replaceAll('。', '.')
    .replaceAll('，', ',')
    .replaceAll('、', ',')
    .replaceAll('＿', '_')
    .replaceAll('－', '-')
    .replaceAll('ー', '-')
    .replaceAll('０', '0')
    .replaceAll('１', '1')
    .replaceAll('２', '2')
    .replaceAll('３', '3')
    .replaceAll('４', '4')
    .replaceAll('５', '5')
    .replaceAll('６', '6')
    .replaceAll('７', '7')
    .replaceAll('８', '8')
    .replaceAll('９', '9')
    .replaceAll('Ａ', 'A')
    .replaceAll('Ｂ', 'B')
    .replaceAll('Ｃ', 'C')
    .replaceAll('Ｄ', 'D')
    .replaceAll('Ｅ', 'E')
    .replaceAll('Ｆ', 'F')
    .replaceAll('Ｇ', 'G')
    .replaceAll('Ｈ', 'H')
    .replaceAll('Ｉ', 'I')
    .replaceAll('Ｊ', 'J')
    .replaceAll('Ｋ', 'K')
    .replaceAll('Ｌ', 'L')
    .replaceAll('Ｍ', 'M')
    .replaceAll('Ｎ', 'N')
    .replaceAll('Ｏ', 'O')
    .replaceAll('Ｐ', 'P')
    .replaceAll('Ｑ', 'Q')
    .replaceAll('Ｒ', 'R')
    .replaceAll('Ｓ', 'S')
    .replaceAll('Ｔ', 'T')
    .replaceAll('Ｕ', 'U')
    .replaceAll('Ｖ', 'V')
    .replaceAll('Ｗ', 'W')
    .replaceAll('Ｘ', 'X')
    .replaceAll('Ｙ', 'Y')
    .replaceAll('Ｚ', 'Z')
    .replaceAll('ａ', 'a')
    .replaceAll('ｂ', 'b')
    .replaceAll('ｃ', 'c')
    .replaceAll('ｄ', 'd')
    .replaceAll('ｅ', 'e')
    .replaceAll('ｆ', 'f')
    .replaceAll('ｇ', 'g')
    .replaceAll('ｈ', 'h')
    .replaceAll('ｉ', 'i')
    .replaceAll('ｊ', 'j')
    .replaceAll('ｋ', 'k')
    .replaceAll('ｌ', 'l')
    .replaceAll('ｍ', 'm')
    .replaceAll('ｎ', 'n')
    .replaceAll('ｏ', 'o')
    .replaceAll('ｐ', 'p')
    .replaceAll('ｑ', 'q')
    .replaceAll('ｒ', 'r')
    .replaceAll('ｓ', 's')
    .replaceAll('ｔ', 't')
    .replaceAll('ｕ', 'u')
    .replaceAll('ｖ', 'v')
    .replaceAll('ｗ', 'w')
    .replaceAll('ｘ', 'x')
    .replaceAll('ｙ', 'y')
    .replaceAll('ｚ', 'z');
