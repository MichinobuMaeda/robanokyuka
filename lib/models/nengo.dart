import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:robanokyuka/services/helpers.dart';
import 'package:robanokyuka/models/cal_date.dart';
import 'package:robanokyuka/models/service.dart';
import 'package:robanokyuka/models/users.dart';

class Nengo {
  final List<Gengo> gengos;
  final bool showNengo;

  Nengo(this.gengos, this.showNengo);

  String formatYear(Cal cal, {bool short = false}) {
    if (!showNengo) return '${cal.year}';
    for (final gengo in gengos.reversed) {
      if (cal.compareTo(gengo.date) >= 0) {
        final eraYear = cal.year - gengo.date.year + 1;
        return short
            ? '${gengo.short}$eraYear'
            : '${gengo.name}${eraYear == 1 ? '元' : eraYear}';
      }
    }
    return short ? '${cal.year}' : '${cal.year}';
  }

  String formatYearShort(Cal cal) => formatYear(cal, short: true);

  String format(Cal cal, {bool short = false}) {
    final year = formatYear(cal, short: short);
    return short
        ? '$year/${cal.month}/${cal.day}'
        : '$year年${cal.month}月${cal.day}日';
  }

  String formatShort(Cal cal) => format(cal, short: true);

  String parseYear(String nengo) {
    final str = toHankaku(nengo)
        .toUpperCase()
        .replaceAll(' ', '')
        .replaceAll('年', '')
        .replaceAll('元', '1');
    final match = RegExp(r'([^\d]+)(\d+)').firstMatch(str);
    if (match == null) return nengo;
    final era = match.group(1)!;
    final year = int.parse(match.group(2)!);

    int? baseYear;

    for (var gengo in gengos) {
      if (gengo.name.startsWith(era) || gengo.short == era) {
        baseYear = gengo.date.year;
        break;
      }
    }

    if (baseYear == null) return nengo;
    return (baseYear + year - 1).toString();
  }

  Cal? parseDate(String date) {
    final str = toHankaku(date).toUpperCase().replaceAll('元', '1').trim();

    if (RegExp(r'^\d').hasMatch(str)) {
      return Cal.fromString(str);
    } else {
      final match = RegExp(r'^(\D+\d+)\D+(\d+)\D+(\d+)').firstMatch(str);
      if (match != null) {
        final year = parseYear(match.group(1)!);
        final month = match.group(2)!;
        final day = match.group(3)!;
        return Cal.fromString('$year/$month/$day');
      } else {
        return null;
      }
    }
  }
}

final nengoProvider = Provider<Nengo>((ref) {
  final conf = ref.watch(confProvider);
  if (conf == null) {
    return Nengo([], false);
  }

  final showNengo = ref.watch(userProvider.select((user) => user?.showNengo));

  return Nengo(conf.gengos, showNengo == true);
});
