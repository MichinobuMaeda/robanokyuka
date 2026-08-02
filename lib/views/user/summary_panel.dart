import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:robanokyuka/config/theme.dart';

import 'package:robanokyuka/models/cal.dart';
import 'package:robanokyuka/models/record.dart';

class SummaryItem {
  final String label;
  final String value;

  SummaryItem({required this.label, required this.value});
}

class SummaryPanel extends ConsumerWidget {
  const SummaryPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(selectedRecordIndexProvider);
    final records = ref.watch(recordsProvider).asData?.value ?? [];
    final record = selectedIndex != null && selectedIndex < records.length
        ? records[selectedIndex]
        : null;

    final plan = (record?.sum() ?? {}).values
        .map(((v) => v))
        .fold(
          WorkStatus.toSumMap(),
          (ret, v) => Map.fromEntries(
            ret.entries.map((entry) => MapEntry(entry.key, entry.value)),
          ),
        );
    final actual = (record?.sum(Cal.today()) ?? {}).values
        .map(((v) => v))
        .fold(
          WorkStatus.toSumMap(),
          (ret, v) => Map.fromEntries(
            ret.entries.map((entry) => MapEntry(entry.key, entry.value)),
          ),
        );

    final summaryItems = record == null
        ? []
        : [
            SummaryItem(
              label: '有休実績/予定/付与: ',
              value:
                  '${formatTime(plan[WorkStatus.p] ?? 0, record.workingSeconds)} / '
                  '${formatTime(actual[WorkStatus.p] ?? 0, record.workingSeconds)} / '
                  '${record.givenLeaves}',
            ),
            SummaryItem(
              label: '病欠: ',
              value: formatTime(plan[WorkStatus.s] ?? 0, record.workingSeconds),
            ),
            SummaryItem(
              label: 'その他: ',
              value: formatTime(plan[WorkStatus.o] ?? 0, record.workingSeconds),
            ),
          ];

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(panelSpacing),
        child: Wrap(
          direction: Axis.horizontal,
          spacing: panelSpacing,
          runSpacing: panelSpacing,
          children: summaryItems
              .map((item) => Text('${item.label}${item.value}'))
              .toList(),
        ),
      ),
    );
  }
}
