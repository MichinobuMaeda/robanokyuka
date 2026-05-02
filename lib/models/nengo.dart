import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../services/helpers.dart';
import 'cal_date.dart';
import 'service.dart';
import 'users.dart';

class Gengo {
  final Cal date;
  final String name;
  final String short;

  Gengo({required this.date, required this.name, required this.short});
}

class Nengo {
  final List<Gengo> gengos;
  final bool showNengo;

  Nengo(this.gengos, this.showNengo);

  String formatYear(Cal cal, {bool short = false}) {
    if (!showNengo) return '${cal.year}';
    for (final gengo in gengos.reversed) {
      if (cal.compareTo(gengo.date) >= 0) {
        return short
            ? '${gengo.short}${cal.year - gengo.date.year + 1}'
            : '${gengo.name}${cal.year - gengo.date.year + 1}';
      }
    }
    return short ? '${cal.year}' : '${cal.year}';
  }

  String formatShort(Cal cal) => formatYear(cal, short: true);

  String format(Cal cal) {
    final year = formatYear(cal);
    return '$year年${cal.month}月${cal.day}日';
  }

  String parseYear(String nengo) {
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
        baseYear = gengo.date.year;
        break;
      }
    }

    if (baseYear == null) return nengo;
    return (baseYear + year - 1).toString();
  }
}

final nengoProvider = Provider<Nengo>((ref) {
  final conf = ref.watch(confProvider);
  if (conf == null || conf.data() == null || conf.data()!['gengos'] is! List) {
    return Nengo([], false);
  }

  final showNengo = ref.watch(userProvider.select((user) => user?.showNengo));

  return Nengo(
    (conf.data()!['gengos'] as List)
        .map(
          (item) => Gengo(
            date: Cal(
              item['year'] as int,
              item['month'] as int,
              item['day'] as int,
            ),
            name: item['name'] as String,
            short: item['short'] as String,
          ),
        )
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date)),
    showNengo == true,
  );
});
