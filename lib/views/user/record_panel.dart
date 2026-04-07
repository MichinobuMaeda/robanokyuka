import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../config/theme.dart';
import '../../models/conf.dart';
import '../../models/record.dart';
import '../../services/helpers.dart';
import '../../widgets/box_panel.dart';

const _publicHolidaysLabels = ['日', '月', '火', '水', '木', '金', '土', '祝日'];

class RecordPanel extends HookConsumerWidget {
  const RecordPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final message = ref.read(snackBarMessageProvider.notifier);
    final uid = ref.read(uidProvider);
    final selectedIndex = ref.watch(selectedRecordIndexProvider);
    final records = ref.watch(recordsProvider).asData?.value ?? [];
    final record = selectedIndex == null ? null : records[selectedIndex];

    final label = record != null
        ? '${record.from.year}年${record.from.month}月${record.from.day}日〜'
        : '期間を追加してください';
    final currentIndex = selectedIndex ?? -1;

    Future<void> handleSave(Record newRecord) async {
      if (uid == null) return;
      final result = await saveRecord(uid, newRecord);
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
            _EditSheet(onConfirm: handleSave, record: record),
      );
    }

    Future<void> showAddSheet() async {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (sheetContext) => _EditSheet(
          onConfirm: handleSave,
          record: getDefaultRecord(records),
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
  const _EditSheet({required this.onConfirm, required this.record});

  final Record record;
  final void Function(Record record) onConfirm;

  @override
  Widget build(BuildContext context) {
    final fromYearC = useTextEditingController(text: '${record.from.year}');
    final fromMonthC = useTextEditingController(text: '${record.from.month}');
    final fromDayC = useTextEditingController(text: '${record.from.day}');
    final toYearC = useTextEditingController(text: '${record.to.year}');
    final toMonthC = useTextEditingController(text: '${record.to.month}');
    final toDayC = useTextEditingController(text: '${record.to.day}');
    final givenLeavesC = useTextEditingController(
      text: '${record.givenLeaves}',
    );
    final minLeavesC = useTextEditingController(text: '${record.minLeaves}');
    final holidays = useState(List<bool>.from(record.publicHolidays));
    final formKey = useMemoized(GlobalKey<FormState>.new);

    String? validateYear(String? value) {
      final year = int.tryParse(value ?? '');
      if (year == null) return '年を数値で入力してください';
      if (year < 1900) return '1900 以上で入力してください';
      return null;
    }

    String? validateMonth(String? value) {
      final month = int.tryParse(value ?? '');
      if (month == null) return '月を数値で入力してください';
      if (month < 1 || month > 12) return '1〜12 で入力してください';
      return null;
    }

    String? validateDay(
      TextEditingController yearC,
      TextEditingController monthC,
      String? value,
    ) {
      final day = int.tryParse(value ?? '');
      if (day == null) return '日を数値で入力してください';
      if (day < 1 || day > 31) return '1〜31 で入力してください';
      final year = int.tryParse(yearC.text);
      final month = int.tryParse(monthC.text);
      if (year != null && month != null) {
        final date = DateTime(year, month, day);
        if (date.year != year || date.month != month || date.day != day) {
          return '存在しない日付です';
        }
      }
      return null;
    }

    String? validateNonNegInt(String? value) {
      final n = int.tryParse(value ?? '');
      if (n == null) return '整数で入力してください';
      if (n < 0) return '0 以上で入力してください';
      return null;
    }

    Widget dateRow(
      TextEditingController yearC,
      TextEditingController monthC,
      TextEditingController dayC,
      String? prefix,
    ) {
      return Row(
        spacing: 8,
        children: [
          if (prefix != null) Text(prefix),
          SizedBox(
            width: 84,
            child: TextFormField(
              controller: yearC,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: '年',
                border: OutlineInputBorder(),
              ),
              validator: validateYear,
            ),
          ),
          SizedBox(
            width: 64,
            child: TextFormField(
              controller: monthC,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: '月',
                border: OutlineInputBorder(),
              ),
              validator: validateMonth,
            ),
          ),
          SizedBox(
            width: 64,
            child: TextFormField(
              controller: dayC,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: '日',
                border: OutlineInputBorder(),
              ),
              validator: (v) => validateDay(yearC, monthC, v),
            ),
          ),
        ],
      );
    }

    void handleSubmit() {
      if (!(formKey.currentState?.validate() ?? false)) return;
      final updated = Record(
        id: record.id,
        from: CalendarDate(
          year: int.parse(fromYearC.text),
          month: int.parse(fromMonthC.text),
          day: int.parse(fromDayC.text),
        ),
        to: CalendarDate(
          year: int.parse(toYearC.text),
          month: int.parse(toMonthC.text),
          day: int.parse(toDayC.text),
        ),
        publicHolidays: List<bool>.from(holidays.value),
        givenLeaves: int.parse(givenLeavesC.text),
        minLeaves: int.parse(minLeavesC.text),
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
              dateRow(fromYearC, fromMonthC, fromDayC, null),
              dateRow(toYearC, toMonthC, toDayC, '〜'),
              Row(
                spacing: 16,
                children: [
                  SizedBox(
                    width: 136,
                    child: TextFormField(
                      controller: givenLeavesC,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: '有給休暇付与日数',
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 8,
                children: [
                  Text('休日', style: Theme.of(context).textTheme.labelLarge),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: List.generate(
                      _publicHolidaysLabels.length,
                      (i) => FilterChip(
                        label: Text(_publicHolidaysLabels[i]),
                        selected: holidays.value[i],
                        onSelected: (v) {
                          holidays.value = [...holidays.value]..[i] = v;
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
