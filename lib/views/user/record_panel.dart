import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:robanokyuka/config/theme.dart';
import 'package:robanokyuka/models/nengo.dart';
import 'package:robanokyuka/models/record.dart';
import 'package:robanokyuka/widgets/box_panel.dart';

class RecordPanel extends HookConsumerWidget {
  const RecordPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(selectedRecordIndexProvider);
    final selectedIndexState = ref.read(selectedRecordIndexProvider.notifier);
    final records = ref.watch(recordsProvider).asData?.value ?? [];
    final record = selectedIndex != null && selectedIndex < records.length
        ? records[selectedIndex]
        : null;
    final nengo = ref.watch(nengoProvider);
    final editing = ref.read(editingRecordProvider.notifier);

    return record == null
        ? BoxPanel(
            showDivider: false,
            children: [
              FilledButton.icon(
                onPressed: () => editing.edit(Record.next(records)),
                icon: iconAdd,
                label: Text('期間を追加'),
              ),
            ],
          )
        : BoxPanel(
            showDivider: false,
            children: [
              Row(
                spacing: 8.0,
                children: [
                  IconButton(
                    onPressed: () => editing.edit(record),
                    icon: iconEdit,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      spacing: 8.0,
                      children: [
                        Text('${nengo.format(record.from)}〜'),
                        IconButton(
                          onPressed: selectedIndex != null && selectedIndex > 0
                              ? () => selectedIndexState.goPrevious()
                              : null,
                          icon: Icon(Symbols.arrow_back_ios_new),
                        ),
                        IconButton(
                          onPressed:
                              selectedIndex != null &&
                                  selectedIndex < records.length - 1
                              ? () => selectedIndexState.goNext()
                              : null,
                          icon: Icon(Symbols.arrow_forward_ios),
                        ),
                      ],
                    ),
                  ),
                  IconButton.filledTonal(
                    onPressed: () => editing.edit(Record.next(records)),
                    icon: iconAdd,
                  ),
                ],
              ),
            ],
          );
  }
}
