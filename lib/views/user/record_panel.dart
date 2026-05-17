import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:robanokyuka/services/authentication.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:robanokyuka/config/firebase.dart';
import 'package:robanokyuka/config/theme.dart';
import 'package:robanokyuka/models/nengo.dart';
import 'package:robanokyuka/models/record.dart';
import 'package:robanokyuka/services/helpers.dart';
import 'package:robanokyuka/services/validators.dart';
import 'package:robanokyuka/widgets/box_panel.dart';
import 'package:robanokyuka/widgets/date_input.dart';

const _publicHolidaysLabels = [...weekdayLabels, '祝日'];

class RecordPanel extends HookConsumerWidget {
  const RecordPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final message = ref.read(snackBarMessageProvider.notifier);
    final uid = ref.read(
      authUserProvider.select((authUser) => authUser.asData?.value?.uid),
    );
    final selectedIndex = ref.watch(selectedRecordIndexProvider);
    final records = ref.watch(recordsProvider).asData?.value ?? [];
    final record = selectedIndex == null ? null : records[selectedIndex];
    final nengo = ref.watch(nengoProvider);

    Future<void> handleSave(Record newRecord) async {
      if (uid == null) return;
      final result = await saveRecord(db(), uid, newRecord);
      result.match(
        (error) => message.show('期間の保存に失敗しました: $error'),
        (_) => message.show('期間を保存しました'),
      );
    }

    Future<void> showEditSheet() async {
      if (record == null) return;
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (sheetContext) =>
            _EditSheet(onConfirm: handleSave, record: record, nengo: nengo),
      );
    }

    Future<void> showAddSheet() async {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (sheetContext) => _EditSheet(
          onConfirm: handleSave,
          record: Record.next(records),
          nengo: nengo,
        ),
      );
    }

    return record == null
        ? BoxPanel(
            showDivider: false,
            children: [
              FilledButton.icon(
                onPressed: showAddSheet,
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
                    onPressed: showEditSheet,
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
                              ? () => ref
                                    .read(selectedRecordIndexProvider.notifier)
                                    .goPrevious()
                              : null,
                          icon: Icon(Symbols.arrow_back_ios_new),
                        ),
                        IconButton(
                          onPressed:
                              selectedIndex != null &&
                                  selectedIndex < records.length - 1
                              ? () => ref
                                    .read(selectedRecordIndexProvider.notifier)
                                    .goNext()
                              : null,
                          icon: Icon(Symbols.arrow_forward_ios),
                        ),
                      ],
                    ),
                  ),
                  IconButton.filledTonal(
                    onPressed: showAddSheet,
                    icon: iconAdd,
                  ),
                ],
              ),
            ],
          );
  }
}

class _EditSheet extends HookWidget {
  const _EditSheet({
    required this.onConfirm,
    required this.record,
    required this.nengo,
  });

  final Record record;
  final void Function(Record record) onConfirm;
  final Nengo nengo;

  @override
  Widget build(BuildContext context) {
    final fromC = useTextEditingController(
      text: nengo.formatShort(record.from),
    );
    final toC = useTextEditingController(text: nengo.formatShort(record.to));
    final givenLeavesC = useTextEditingController(
      text: '${record.givenLeaves}',
    );
    final minLeavesC = useTextEditingController(text: '${record.minLeaves}');
    final publicHolidays = useState(List<bool>.from(record.publicHolidays));
    final useLeavesHourly = useState(!!record.useLeavesHourly);
    final workingHours = useTextEditingController(
      text: formatTimeShort(record.workingHours),
    );
    final formKey = useMemoized(GlobalKey<FormState>.new);

    void handleSubmit() {
      if (!(formKey.currentState?.validate() ?? false)) return;
      final from = nengo.parseDate(fromC.text)!;
      final to = nengo.parseDate(toC.text)!;
      final updated = Record(
        id: record.id,
        from: from,
        to: to,
        publicHolidays: List<bool>.from(publicHolidays.value),
        givenLeaves: int.parse(givenLeavesC.text),
        minLeaves: int.parse(minLeavesC.text),
        useLeavesHourly: useLeavesHourly.value,
        stdSeconds: parseTime(workingHours.text),
      );
      Navigator.pop(context);
      onConfirm(updated);
    }

    return Padding(
      padding: EdgeInsets.only(
        left: bottomSheetPadding.left,
        right: bottomSheetPadding.right,
        top: bottomSheetPadding.top,
        bottom:
            bottomSheetPadding.bottom +
            MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 16,
            children: [
              Text(
                record.id.isEmpty ? '期間を追加' : '期間を更新',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              LayoutBuilder(
                builder: (context, constraints) {
                  final rows = [
                    ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: 192),
                      child: DateInput(
                        labelText: '開始日',
                        dateController: fromC,
                        nengo: nengo,
                      ),
                    ),
                    Row(
                      spacing: 8,
                      children: [
                        Text('〜'),
                        ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: 192),
                          child: DateInput(
                            labelText: '終了日',
                            dateController: toC,
                            nengo: nengo,
                          ),
                        ),
                      ],
                    ),
                  ];
                  if (constraints.maxWidth >= 520) {
                    return Row(spacing: 8, children: rows);
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 16,
                    children: rows,
                  );
                },
              ),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  Row(
                    spacing: 16,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 112,
                        child: TextFormField(
                          controller: givenLeavesC,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: '有休付与日数',
                            border: OutlineInputBorder(),
                          ),
                          validator: validateNonNegInt,
                        ),
                      ),
                      SizedBox(
                        width: 112,
                        child: TextFormField(
                          controller: minLeavesC,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: '最小取得日数',
                            border: OutlineInputBorder(),
                          ),
                          validator: validateNonNegInt,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    spacing: 16,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 112,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Checkbox(
                              value: useLeavesHourly.value,
                              onChanged: (v) =>
                                  useLeavesHourly.value = v == true,
                            ),
                            const Text('時間有休'),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: 112,
                        child: TextFormField(
                          controller: workingHours,
                          decoration: const InputDecoration(
                            labelText: '所定労働時間',
                            hintText: '8:00',
                            border: OutlineInputBorder(),
                          ),
                          validator: validateHhmmOptional,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 8,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: List.generate(
                      _publicHolidaysLabels.length + 1,
                      (i) => i == 0
                          ? Text(
                              '休日',
                              style: Theme.of(context).textTheme.labelLarge,
                            )
                          : FilterChip(
                              label: Text(_publicHolidaysLabels[i - 1]),
                              selected: publicHolidays.value[i - 1],
                              onSelected: (v) {
                                publicHolidays.value = [...publicHolidays.value]
                                  ..[i - 1] = v;
                              },
                            ),
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: 16.0,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('キャンセル'),
                  ),
                  FilledButton(
                    onPressed: handleSubmit,
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Symbols.check),
                        SizedBox(width: 8),
                        Text('保存'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
