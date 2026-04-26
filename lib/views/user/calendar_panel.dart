import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

// import '../../config/theme.dart';
import '../../models/gengo.dart';
import '../../models/service.dart';
import '../../models/users.dart';
import '../../models/record.dart';
import '../../services/helpers.dart';

const _weekdayLabels = ['日', '月', '火', '水', '木', '金', '土'];

const headerHeight = 24.0;
const cellHeight = 48.0;
const iconSize = 20.0;

class CalendarPanel extends HookConsumerWidget {
  const CalendarPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final holidays = ref.watch(holidaysProvider);
    final selectedIndex = ref.watch(selectedRecordIndexProvider);
    final records = ref.watch(recordsProvider).asData?.value ?? [];
    final record = selectedIndex != null && selectedIndex < records.length
        ? records[selectedIndex]
        : null;
    final gengos = ref.watch(gengosProvider);
    final showNengo = ref.watch(
      userProvider.select((user) => user?.showNengo == true),
    );

    final months = <(int, int)>[];
    if (record != null) {
      var year = int.parse(record.from.substring(0, 4));
      var month = int.parse(record.from.substring(4, 6));
      final toYear = int.parse(record.to.substring(0, 4));
      final toMonth = int.parse(record.to.substring(4, 6));
      while (year < toYear || (year == toYear && month <= toMonth)) {
        months.add((year, month));
        month++;
        if (month > 12) {
          month = 1;
          year++;
        }
      }
    }

    return SliverGrid.builder(
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 400.0,
        mainAxisSpacing: 1.0,
        crossAxisSpacing: 1.0,
        mainAxisExtent: headerHeight * 2 + cellHeight * 6,
      ),
      itemCount: months.length,
      itemBuilder: (context, index) {
        final (year, month) = months[index];
        return _MonthCard(
          record: record!,
          holidays: holidays,
          year: year,
          month: month,
          showNengo: showNengo,
          gengos: gengos,
        );
      },
    );
  }
}

class _MonthCard extends StatelessWidget {
  const _MonthCard({
    required this.record,
    required this.holidays,
    required this.year,
    required this.month,
    required this.showNengo,
    required this.gengos,
  });

  final Record record;
  final List<Holiday> holidays;
  final int year;
  final int month;
  final bool showNengo;
  final List<Gengo> gengos;

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(year, month, 1);
    final startOffset = firstDay.weekday % 7; // Sun=0, Mon=1, ..., Sat=6
    final daysInMonth = DateUtils.getDaysInMonth(year, month);

    return ColoredBox(
      color: switch (month % 4) {
        0 => Theme.of(context).colorScheme.surfaceContainerLowest,
        1 => Theme.of(context).colorScheme.surfaceContainerLow.withAlpha(168),
        2 => Theme.of(context).colorScheme.surfaceContainerLow.withAlpha(64),
        _ => Theme.of(context).colorScheme.surfaceContainerLow.withAlpha(252),
      },
      child: Column(
        children: [
          SizedBox(
            height: headerHeight,
            child: Center(
              child: Text(
                showNengo
                    ? '${formatNengo(gengos, formatYmd(year, month, 1))}$month月'
                    : '$year年$month月',
              ),
            ),
          ),
          SizedBox(
            height: headerHeight,
            child: Row(
              children: [
                for (int i = 0; i < _weekdayLabels.length; i++)
                  Expanded(
                    child: Container(
                      color: record.publicHolidays[i]
                          ? Theme.of(context).colorScheme.errorContainer
                          : null,
                      child: Center(
                        child: Text(
                          _weekdayLabels[i],
                          style: TextStyle(
                            color: record.publicHolidays[i]
                                ? Theme.of(context).colorScheme.onErrorContainer
                                : null,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          for (int row = 0; row < 6; row++)
            Row(
              children: [
                for (int col = 0; col < 7; col++)
                  Expanded(
                    child: Builder(
                      builder: (context) {
                        final day = row * 7 + col - startOffset + 1;
                        if (day < 1 || day > daysInMonth) {
                          return const SizedBox.shrink();
                        }
                        bool isHoliday = isHolyday(
                          record,
                          holidays,
                          formatYmd(year, month, day),
                        );
                        return _DayCell(
                          record: record,
                          day: formatYmd(year, month, day),
                          isHoliday: isHoliday,
                        );
                      },
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.record,
    required this.day,
    required this.isHoliday,
  });

  final Record record;
  final String day;
  final bool isHoliday;

  @override
  Widget build(BuildContext context) {
    // final isPlannedLeave = record.plannedLeaves.any(
    //   (d) => d == day,
    // );
    // final isUsedLeave = record.usedLeaves.any(
    //   (d) => d == day,
    // );

    return InkWell(
      onTap: () => showModalBottomSheet<void>(
        context: context,
        builder: (sheetContext) => Text(''),
        // _DayCellSheet(recordId: record.id, date: day),
      ),
      child: Container(
        height: cellHeight,
        color: isHoliday ? Theme.of(context).colorScheme.errorContainer : null,
        child: Column(
          spacing: 4.0,
          children: [
            Center(
              child: Text(
                '${int.parse(day.substring(6, 8))}',
                style: TextStyle(
                  color: isHoliday
                      ? Theme.of(context).colorScheme.onErrorContainer
                      : null,
                ),
              ),
            ),
            // if (isPlannedLeave && isUsedLeave)
            //   Icon(Icons.check_box_outlined, size: iconSize)
            // else if (isPlannedLeave)
            //   Icon(Icons.check_box_outline_blank, size: iconSize)
            // else if (isUsedLeave)
            //   Icon(Icons.check, size: iconSize)
            // else
            if (isHoliday)
              Icon(
                Icons.cottage_outlined,
                size: iconSize,
                color: Theme.of(context).colorScheme.onErrorContainer,
              ),
          ],
        ),
      ),
    );
  }
}

// class _DayCellSheet extends ConsumerWidget {
//   const _DayCellSheet({required this.recordId, required this.date});

//   final String recordId;
//   final CalendarDate date;

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final uid = ref.read(uidProvider);
//     final message = ref.read(snackBarMessageProvider.notifier);
//     final holidays = ref.watch(holidaysProvider);
//     final selectedIndex = ref.watch(selectedRecordIndexProvider);
//     final records = ref.watch(recordsProvider).asData?.value ?? [];
//     final record = selectedIndex != null && selectedIndex < records.length
//         ? records[selectedIndex]
//         : null;

//     if (record == null || record.id != recordId) {
//       return const SizedBox.shrink();
//     }

//     final holidayName = holidays
//         .where((h) => h.date == date)
//         .map((h) => h.name)
//         .firstOrNull;

//     final isCompanyHoliday = record.companyHolidays.any((d) => d == date);
//     final isPlannedLeave = record.plannedLeaves.any((d) => d == date);
//     final isUsedLeave = record.usedLeaves.any((d) => d == date);

//     Future<void> toggle(String field, bool current) async {
//       if (uid == null) return;
//       final result = await toggleDayInList(
//         uid,
//         record.id,
//         field,
//         date,
//         current,
//       );
//       result.match((error) => message.show('保存に失敗しました: $error'), (_) {});
//     }

//     return Padding(
//       padding: bottomSheetPadding,
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Text(
//             '${date.year}年${date.month}月${date.day}日${holidayName != null ? ' $holidayName' : ''}',
//           ),
//           SwitchListTile(
//             title: const Text('土日祝日等以外の非営業日'),
//             value: isCompanyHoliday,
//             onChanged: (_) => toggle('companyHolidays', isCompanyHoliday),
//           ),
//           SwitchListTile(
//             title: const Text('有給休暇取得予定'),
//             value: isPlannedLeave,
//             onChanged: (_) => toggle('plannedLeaves', isPlannedLeave),
//           ),
//           SwitchListTile(
//             title: const Text('休暇取得実績'),
//             value: isUsedLeave,
//             onChanged: (_) => toggle('usedLeaves', isUsedLeave),
//           ),
//         ],
//       ),
//     );
//   }
// }
