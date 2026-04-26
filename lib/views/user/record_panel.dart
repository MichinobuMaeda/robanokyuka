import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:yukyuchecker/services/authentication.dart';

import '../../config/firebase.dart';
import '../../config/theme.dart';
import '../../models/gengo.dart';
import '../../models/service.dart';
import '../../models/users.dart';
import '../../models/record.dart';
import '../../services/helpers.dart';
import '../../services/validators.dart';
import '../../widgets/box_panel.dart';
import '../../widgets/date_row.dart';

const _publicHolidaysLabels = ['日', '月', '火', '水', '木', '金', '土', '祝日'];

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
    final gengos = ref.watch(gengosProvider);
    final showNengo = ref.watch(
      userProvider.select((user) => user?.showNengo == true),
    );

    final label = record != null
        ? '${formatDate(record.from, gengos, showNengo)}〜'
        : '期間を追加してください';
    final currentIndex = selectedIndex ?? -1;

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
        builder: (sheetContext) => _EditSheet(
          onConfirm: handleSave,
          record: record,
          showNengo: showNengo,
          gengos: gengos,
        ),
      );
    }

    Future<void> showAddSheet() async {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (sheetContext) => _EditSheet(
          onConfirm: handleSave,
          record: getDefaultRecord(records),
          showNengo: showNengo,
          gengos: gengos,
        ),
      );
    }

    return BoxPanel(
      showDivider: false,
      children: [
        Row(
          spacing: 8.0,
          children: [
            if (record != null)
              IconButton(
                onPressed: showEditSheet,
                icon: Icon(
                  Icons.edit,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                spacing: 8.0,
                children: [
                  Text(label),
                  if (record != null)
                    IconButton(
                      onPressed: currentIndex > 0
                          ? () => ref
                                .read(selectedRecordIndexProvider.notifier)
                                .set(currentIndex - 1)
                          : null,
                      icon: Icon(Icons.arrow_back_ios_new),
                    ),
                  if (record != null)
                    IconButton(
                      onPressed:
                          currentIndex >= 0 && currentIndex < records.length - 1
                          ? () => ref
                                .read(selectedRecordIndexProvider.notifier)
                                .set(currentIndex + 1)
                          : null,
                      icon: Icon(Icons.arrow_forward_ios),
                    ),
                ],
              ),
            ),
            IconButton.filledTonal(
              onPressed: showAddSheet,
              icon: Icon(
                Icons.add,
                color: Theme.of(context).colorScheme.primary,
              ),
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
    required this.showNengo,
    required this.gengos,
  });

  final Record record;
  final void Function(Record record) onConfirm;
  final bool showNengo;
  final List<Gengo> gengos;

  @override
  Widget build(BuildContext context) {
    final fromYearC = useTextEditingController(
      text: showNengo
          ? formatNengo(gengos, record.from).replaceAll('年', '')
          : record.from.substring(0, 4),
    );
    final fromMonthC = useTextEditingController(
      text: int.parse(record.from.substring(4, 6)).toString(),
    );
    final fromDayC = useTextEditingController(
      text: int.parse(record.from.substring(6, 8)).toString(),
    );
    final toYearC = useTextEditingController(
      text: showNengo
          ? formatNengo(gengos, record.to).replaceAll('年', '')
          : record.to.substring(0, 4),
    );
    final toMonthC = useTextEditingController(
      text: int.parse(record.to.substring(4, 6)).toString(),
    );
    final toDayC = useTextEditingController(
      text: int.parse(record.to.substring(6, 8)).toString(),
    );
    final givenLeavesC = useTextEditingController(
      text: '${record.givenLeaves}',
    );
    final minLeavesC = useTextEditingController(text: '${record.minLeaves}');
    final publicHolidays = useState(List<bool>.from(record.publicHolidays));
    final useLeavesHourly = useState(!!record.useLeavesHourly);
    final workingHours = useTextEditingController(text: record.workingHours);
    final formKey = useMemoized(GlobalKey<FormState>.new);

    void handleSubmit() {
      if (!(formKey.currentState?.validate() ?? false)) return;
      final updated = Record(
        id: record.id,
        from: formatYmd(
          int.parse(parseNengo(gengos, fromYearC.text)),
          int.parse(fromMonthC.text),
          int.parse(fromDayC.text),
        ),
        to: formatYmd(
          int.parse(parseNengo(gengos, toYearC.text)),
          int.parse(toMonthC.text),
          int.parse(toDayC.text),
        ),
        publicHolidays: List<bool>.from(publicHolidays.value),
        givenLeaves: int.parse(givenLeavesC.text),
        minLeaves: int.parse(minLeavesC.text),
        useLeavesHourly: useLeavesHourly.value,
        workingHours: workingHours.text,
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
                    DateRow(
                      yearController: fromYearC,
                      monthController: fromMonthC,
                      dayController: fromDayC,
                      gengos: gengos,
                    ),
                    Row(
                      spacing: 8,
                      children: [
                        Text('〜'),
                        DateRow(
                          yearController: toYearC,
                          monthController: toMonthC,
                          dayController: toDayC,
                          gengos: gengos,
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
                            hintText: '08:00',
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
                        Icon(Icons.check),
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
