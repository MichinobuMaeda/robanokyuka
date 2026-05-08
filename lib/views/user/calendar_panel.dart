import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:robanokyuka/config/theme.dart';
import 'package:robanokyuka/models/cal_date.dart';
import 'package:robanokyuka/models/nengo.dart';
import 'package:robanokyuka/models/holidays.dart';
import 'package:robanokyuka/models/record.dart';
import 'package:robanokyuka/views/user/calendar_cell.dart';
import 'package:robanokyuka/widgets/box_panel.dart';

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
    final months = record?.months;
    final nengo = ref.watch(nengoProvider);

    return months == null
        ? const BoxPanel(showDivider: false, children: [Text('表示するデータがありません。')])
        : SliverGrid.builder(
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: calGridWidth,
              mainAxisSpacing: calGridSpacing,
              crossAxisSpacing: calGridSpacing,
              mainAxisExtent: calGridHeight,
            ),
            itemCount: months.length,
            itemBuilder: (context, index) {
              final (year, month) = months[index];
              return _MonthCard(
                record: record!,
                holidays: holidays,
                year: year,
                month: month,
                nengo: nengo,
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
    required this.nengo,
  });

  final Record record;
  final List<Holiday> holidays;
  final int year;
  final int month;
  final Nengo nengo;

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(year, month, 1);
    final startOffset = firstDay.weekday % 7; // Sun=0, Mon=1, ..., Sat=6
    final daysInMonth = DateUtils.getDaysInMonth(year, month);

    return ColoredBox(
      color: panelColor(context, month),
      child: Column(
        children: [
          SizedBox(
            height: calHeaderHeight,
            child: Center(
              child: Text('${nengo.formatYear(Cal(year, month, 1))}年$month月'),
            ),
          ),
          SizedBox(
            height: calHeaderHeight,
            child: Row(
              children: [
                for (int i = 0; i < weekdayLabels.length; i++)
                  Expanded(
                    child: Container(
                      color: record.publicHolidays[i]
                          ? Theme.of(
                              context,
                            ).colorScheme.errorContainer.withAlpha(96)
                          : null,
                      child: Center(
                        child: Text(
                          weekdayLabels[i],
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
                        final date = Cal(year, month, day);
                        return CalendarCell(
                          record: record,
                          date: date,
                          isHolidayWeekDay: record.isHolidayWeekDay(date),
                          holiday: holidays
                              .where((h) => h.date == date)
                              .firstOrNull,
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
