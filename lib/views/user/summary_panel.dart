import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:yukyuchecker/config/theme.dart';

import 'package:yukyuchecker/models/record.dart';

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

    final summaryItems = record == null
        ? []
        : [
            SummaryItem(
              label: '有給休暇取得予定: ',
              value: '${record.plannedLeaves} / ${record.givenLeaves}',
            ),
            SummaryItem(
              label: '有給休暇取得実績: ',
              value: '${record.usedLeaves} / ${record.givenLeaves}',
            ),
            SummaryItem(label: '病欠: ', value: record.sickLeaves),
            SummaryItem(label: 'その他: ', value: record.otherLeaves),
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
