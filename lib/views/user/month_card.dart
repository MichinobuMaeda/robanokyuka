import 'package:flutter/material.dart';
import 'package:fpdart/fpdart.dart';

import 'package:robanokyuka/config/theme.dart';
import 'package:robanokyuka/models/cal.dart';
import 'package:robanokyuka/models/nengo.dart';
import 'package:robanokyuka/models/holidays.dart';
import 'package:robanokyuka/models/record.dart';
import 'package:robanokyuka/views/user/day_cell.dart';

class MonthCard extends StatelessWidget {
  const MonthCard({
    super.key,
    required this.record,
    required this.holidays,
    required this.first,
    required this.nengo,
  });

  final Record record;
  final List<Holiday> holidays;
  final Cal first;
  final Nengo nengo;

  @override
  Widget build(BuildContext context) {
    final startOffset =
        first.dateTime.weekday %
        weekdayLabels.length; // Sun=0, Mon=1, ..., Sat=6
    final daysInMonth = DateUtils.getDaysInMonth(first.year, first.month);
    final colorScheme = Theme.of(context).colorScheme;
    final containerColors = record.holidays
        .map((h) => h ? colorScheme.errorContainer.withAlpha(96) : null)
        .toList();
    final textColors = record.holidays
        .map((h) => h ? colorScheme.onErrorContainer : null)
        .toList();

    return ColoredBox(
      color: panelColor(context, first.month),
      child: Column(
        children: [
          SizedBox(
            height: calHeaderHeight,
            child: Center(
              child: Text('${nengo.formatYear(first)}年${first.month}月'),
            ),
          ),
          SizedBox(
            height: calHeaderHeight,
            child: Row(
              children: weekdayLabels
                  .mapWithIndex(
                    (label, i) => Expanded(
                      child: Container(
                        color: containerColors[i],
                        child: Center(
                          child: Text(
                            label,
                            style: TextStyle(color: textColors[i]),
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          ...[for (int row = 0; row < 6; row++) row].map(
            (row) => Row(
              children: weekdayLabels
                  .mapWithIndex(
                    (label, i) => Expanded(
                      child: Builder(
                        builder: (context) {
                          final day = row * 7 + i - startOffset + 1;
                          return (day < 1 || day > daysInMonth)
                              ? const SizedBox.shrink()
                              : DayCell(
                                  record: record,
                                  date: Cal(first.year, first.month, day),
                                  holidays: holidays,
                                );
                        },
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}
