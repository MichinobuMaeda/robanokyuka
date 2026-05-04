import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:yukyuchecker/config/firebase.dart';
import 'package:yukyuchecker/config/theme.dart';
import 'package:yukyuchecker/models/cal_date.dart';
import 'package:yukyuchecker/models/nengo.dart';
import 'package:yukyuchecker/models/record.dart';
import 'package:yukyuchecker/models/holidays.dart';
import 'package:yukyuchecker/services/authentication.dart';
import 'package:yukyuchecker/services/helpers.dart';
import 'package:yukyuchecker/services/validators.dart';
import 'package:yukyuchecker/widgets/toggle_button.dart';

class CalendarCell extends StatelessWidget {
  const CalendarCell({
    super.key,
    required this.record,
    required this.date,
    required this.isHolidayWeekDay,
    this.holiday,
  });

  final Record record;
  final Cal date;
  final bool isHolidayWeekDay;
  final Holiday? holiday;

  @override
  Widget build(BuildContext context) {
    final dateRecord =
        record.dates.where((d) => d.date == date).firstOrNull ??
        DateRecord(
          date,
          false,
          null,
          plan: WorkTime(0, false),
          used: WorkTime(0, false),
          sick: WorkTime(0, false),
          other: WorkTime(0, false),
        );
    final today = Cal.fromDateTime(DateTime.now());
    final isPastOrToday = !date.dateTime.isAfter(today.dateTime);
    final isPublicHoliday =
        isHolidayWeekDay || (record.publicHolidays[7] && holiday != null);

    return InkWell(
      onTap: () => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (sheetContext) => _DayCellSheet(
          recordId: record.id,
          date: date,
          dateRecord: dateRecord,
          holiday: holiday,
          useLeavesHourly: record.useLeavesHourly,
          workingHours: record.workingHours,
        ),
      ),
      child: Container(
        height: calCellHeight,
        color: isPublicHoliday
            ? Theme.of(context).colorScheme.errorContainer.withAlpha(96)
            : null,
        child: Column(
          spacing: 4.0,
          children: [
            Center(
              child: Text(
                '${date.day}',
                style: TextStyle(
                  color: isPublicHoliday
                      ? Theme.of(context).colorScheme.onErrorContainer
                      : null,
                ),
              ),
            ),
            if (isPublicHoliday)
              Icon(
                Symbols.cottage,
                color: Theme.of(context).colorScheme.onErrorContainer,
              )
            else if (dateRecord.other.all)
              iconOtherFull
            else if (dateRecord.other.seconds > 0)
              iconOtherHalf
            else if (dateRecord.sick.all)
              iconSickFull
            else if (dateRecord.sick.seconds > 0)
              iconSickHalf
            else if (dateRecord.used.all)
              iconPaidFull
            else if (dateRecord.used.seconds > 0)
              iconPaidHalf
            else if (dateRecord.plan.seconds > 0)
              iconPaidEmpty
            else if (dateRecord.companyHoliday)
              iconCompanyHoliday
            else if (isPastOrToday)
              iconWorked,
          ],
        ),
      ),
    );
  }
}

class _DayCellSheet extends HookConsumerWidget {
  const _DayCellSheet({
    required this.recordId,
    required this.date,
    required this.dateRecord,
    this.holiday,
    this.useLeavesHourly = false,
    required this.workingHours,
  });

  final String recordId;
  final Cal date;
  final DateRecord dateRecord;
  final Holiday? holiday;
  final bool useLeavesHourly;
  final int workingHours;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.read(authUserProvider.select((u) => u.asData?.value?.uid));
    final message = ref.read(snackBarMessageProvider.notifier);
    final db = ref.read(firestoreProvider);
    final nengo = ref.watch(nengoProvider);

    final formKey = useMemoized(() => GlobalKey<FormState>());
    final companyHoliday = useState(dateRecord.companyHoliday);

    final planAll = useState(dateRecord.plan.all);
    final planCtrl = useTextEditingController(
      text: !dateRecord.plan.all && dateRecord.plan.seconds > 0
          ? formatTimeShort(dateRecord.plan.seconds)
          : '',
    );
    final usedAll = useState(dateRecord.used.all);
    final usedCtrl = useTextEditingController(
      text: !dateRecord.used.all && dateRecord.used.seconds > 0
          ? formatTimeShort(dateRecord.used.seconds)
          : '',
    );
    final sickAll = useState(dateRecord.sick.all);
    final sickCtrl = useTextEditingController(
      text: !dateRecord.sick.all && dateRecord.sick.seconds > 0
          ? formatTimeShort(dateRecord.sick.seconds)
          : '',
    );
    final otherAll = useState(dateRecord.other.all);
    final otherCtrl = useTextEditingController(
      text: !dateRecord.other.all && dateRecord.other.seconds > 0
          ? formatTimeShort(dateRecord.other.seconds)
          : '',
    );
    final noteCtrl = useTextEditingController(text: dateRecord.note ?? '');

    final holidayName = holiday?.name;
    final title =
        '${nengo.format(date)}(${date.weekDayLabel})'
        '${holidayName != null ? '  $holidayName' : ''}';

    WorkTime fieldValue(bool all, String time) {
      if (all) return WorkTime(0, true);
      final text = time.trim();
      if (text.isEmpty || text == '0:00' || text == '00:00') {
        return WorkTime(0, false);
      }
      return WorkTime(parseTime(text), false);
    }

    Future<void> handleSave() async {
      if (uid == null) return;
      if (!(formKey.currentState?.validate() ?? true)) return;
      final newRecord = DateRecord(
        date,
        companyHoliday.value,
        noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim(),
        plan: fieldValue(planAll.value, planCtrl.text),
        used: fieldValue(usedAll.value, usedCtrl.text),
        sick: fieldValue(sickAll.value, sickCtrl.text),
        other: fieldValue(otherAll.value, otherCtrl.text),
      );
      final result = await saveDateRecord(db, uid, recordId, newRecord);
      if (context.mounted) {
        result.match(
          (error) => message.show('保存に失敗しました: $error'),
          (_) => Navigator.of(context).pop(),
        );
      }
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
      child: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 8.0,
          children: [
            Wrap(
              spacing: 16.0,
              runSpacing: 8.0,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                ToggleButton(
                  iconActive: iconCompanyHoliday,
                  icon: iconWorked,
                  label: '休業日',
                  active: companyHoliday.value,
                  onPressed: () => companyHoliday.value = !companyHoliday.value,
                ),
                ConstrainedBox(
                  constraints: const BoxConstraints(
                    minWidth: 168,
                    maxWidth: 288,
                  ),
                  child: TextField(
                    controller: noteCtrl,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: '備考',
                    ),
                  ),
                ),
              ],
            ),
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: [
                useLeavesHourly
                    ? _LeaveTimeRange(
                        label: '有休予定',
                        allDay: planAll,
                        controller: planCtrl,
                        disabled: companyHoliday.value,
                        icon: iconPaidEmpty,
                        iconHalf: iconPaidHalf,
                        iconAll: iconPaidFull,
                      )
                    : Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: ToggleButton(
                          iconActive: iconPaidFull,
                          icon: iconPaidEmpty,
                          label: '有休予定',
                          active: planAll.value,
                          onPressed: companyHoliday.value
                              ? null
                              : () => planAll.value = !planAll.value,
                          width: 144,
                          alignment: Alignment.centerLeft,
                        ),
                      ),
                useLeavesHourly
                    ? _LeaveTimeRange(
                        label: '有休実績',
                        allDay: usedAll,
                        controller: usedCtrl,
                        disabled: companyHoliday.value,
                        icon: iconPaidEmpty,
                        iconHalf: iconPaidHalf,
                        iconAll: iconPaidFull,
                      )
                    : Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: ToggleButton(
                          iconActive: iconPaidFull,
                          icon: iconPaidEmpty,
                          label: '有休実績',
                          active: usedAll.value,
                          onPressed: companyHoliday.value
                              ? null
                              : () => usedAll.value = !usedAll.value,
                          width: 144,
                          alignment: Alignment.centerLeft,
                        ),
                      ),
                _LeaveTimeRange(
                  label: '病欠',
                  allDay: sickAll,
                  controller: sickCtrl,
                  disabled: companyHoliday.value,
                  icon: iconSickEmpty,
                  iconHalf: iconSickHalf,
                  iconAll: iconSickFull,
                ),
                _LeaveTimeRange(
                  label: 'その他',
                  allDay: otherAll,
                  controller: otherCtrl,
                  disabled: companyHoliday.value,
                  icon: iconOtherEmpty,
                  iconHalf: iconOtherHalf,
                  iconAll: iconOtherFull,
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
                  onPressed: handleSave,
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
    );
  }
}

class _LeaveTimeRange extends HookWidget {
  const _LeaveTimeRange({
    required this.label,
    required this.allDay,
    required this.controller,
    required this.icon,
    required this.iconHalf,
    required this.iconAll,
    this.disabled = false,
  });

  final String label;
  final ValueNotifier<bool> allDay;
  final TextEditingController controller;
  final Widget icon;
  final Widget iconHalf;
  final Widget iconAll;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    useListenable(allDay);
    useListenable(controller);

    final initialStep = useMemoized(() {
      if (allDay.value) return 2;
      if (controller.text.trim().isNotEmpty) return 1;
      return 0;
    });
    final step = useState(initialStep);

    void onIconTap() {
      final next = (step.value + 1) % 3;
      if (next == 0) {
        allDay.value = false;
        controller.clear();
      } else if (next == 1) {
        allDay.value = false;
        controller.text = '0:00';
      } else {
        controller.clear();
        allDay.value = true;
      }
      step.value = next;
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 144),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: IconButton(
              icon: switch (step.value) {
                0 => icon,
                1 => iconHalf,
                _ => iconAll,
              },
              onPressed: onIconTap,
            ),
          ),
          Expanded(
            child: TextFormField(
              controller: controller,
              enabled: !disabled && step.value == 1,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: label,
                helperText: 'H:MM',
              ),
              validator: validateHhmmOptional,
            ),
          ),
        ],
      ),
    );
  }
}
