import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:yukyuchecker/config/theme.dart';

import '../../models/record.dart';

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

    final givenLeaves = record?.givenLeaves ?? 0;
    final plannedCount = record?.plannedLeaves.length ?? 0;
    final completionCount =
        record?.usedLeaves
            .where(
              (u) => record.plannedLeaves.any(
                (p) => p.year == u.year && p.month == u.month && p.day == u.day,
              ),
            )
            .length ??
        0;

    final summaryItems = [
      SummaryItem(label: '有給休暇取得予定', value: '$plannedCount / $givenLeaves'),
      SummaryItem(label: '有給休暇取得実績', value: '$completionCount / $givenLeaves'),
      SummaryItem(
        label: 'その他の休暇',
        value: '${(record?.usedLeaves.length ?? 0) - completionCount}',
      ),
    ];

    return SliverGrid.builder(
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 400.0,
        mainAxisSpacing: 1.0,
        crossAxisSpacing: 1.0,
        mainAxisExtent: 32.0,
      ),
      itemCount: summaryItems.length,
      itemBuilder: (context, index) {
        final item = summaryItems[index];
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: panelSpacing),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            spacing: panelSpacing / 2,
            children: [Text(item.label), Text(item.value)],
          ),
        );
      },
    );
  }
}
