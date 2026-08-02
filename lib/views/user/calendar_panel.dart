import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:robanokyuka/config/theme.dart';
import 'package:robanokyuka/models/nengo.dart';
import 'package:robanokyuka/models/holidays.dart';
import 'package:robanokyuka/models/record.dart';
import 'package:robanokyuka/services/helpers.dart';
import 'package:robanokyuka/views/user/month_card.dart';
import 'package:robanokyuka/widgets/box_panel.dart';

class CalendarPanel extends HookConsumerWidget {
  const CalendarPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final records = ref.watch(recordsProvider).asData?.value ?? [];
    final selectedIndex = ref.watch(selectedRecordIndexProvider);
    final record = selectedIndex != null && selectedIndex < records.length
        ? records[selectedIndex]
        : null;

    if (record == null) {
      return const BoxPanel(
        showDivider: false,
        children: [Text('表示するデータがありません。')],
      );
    }

    final months = generateMonthList(record.from, record.to);
    final holidays = ref.watch(holidaysProvider);
    final nengo = ref.watch(nengoProvider);

    return SliverGrid.builder(
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: calGridWidth,
        mainAxisSpacing: calGridSpacing,
        crossAxisSpacing: calGridSpacing,
        mainAxisExtent: calGridHeight,
      ),
      itemCount: months.length,
      itemBuilder: (context, index) {
        return MonthCard(
          record: record,
          holidays: holidays,
          first: months[index],
          nengo: nengo,
        );
      },
    );
  }
}
