import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:robanokyuka/config/theme.dart';
import 'package:robanokyuka/models/cal.dart';
import 'package:robanokyuka/models/record.dart';
import 'package:robanokyuka/models/holidays.dart';

class DayCell extends ConsumerWidget {
  const DayCell({
    super.key,
    required this.record,
    required this.date,
    required this.holidays,
  });

  final Record record;
  final Cal date;
  final List<Holiday> holidays;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateRecord = record.dates[date];
    final isPublicHoliday =
        record.holidays[date.dateTime.weekday % 7] ||
        holidays.where((h) => h.date == date).isNotEmpty;
    final colorScheme = Theme.of(context).colorScheme;
    final containerColor = isPublicHoliday
        ? colorScheme.errorContainer.withAlpha(96)
        : null;
    final textColor = isPublicHoliday ? colorScheme.onErrorContainer : null;

    return InkWell(
      onTap: () => ref
          .read(editingDateProvider.notifier)
          .edit(EditingDate(record: record, date: date, holidays: holidays)),
      child: Container(
        height: calCellHeight,
        color: containerColor,
        child: Column(
          spacing: 4.0,
          children: [
            Center(
              child: Text('${date.day}', style: TextStyle(color: textColor)),
            ),
            Center(
              child: Text(
                dateRecord?.status?.name ?? '',
                style: TextStyle(color: textColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
