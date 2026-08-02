import 'package:flutter/material.dart';
// import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
// import 'package:material_symbols_icons/symbols.dart';

// import 'package:robanokyuka/config/firebase.dart';
// import 'package:robanokyuka/config/theme.dart';
import 'package:robanokyuka/models/cal.dart';
// import 'package:robanokyuka/models/nengo.dart';
import 'package:robanokyuka/models/record.dart';
import 'package:robanokyuka/models/holidays.dart';
// import 'package:robanokyuka/services/authentication.dart';
// import 'package:robanokyuka/services/helpers.dart';
// import 'package:robanokyuka/services/validators.dart';
import 'package:robanokyuka/widgets/box_panel.dart';
// import 'package:robanokyuka/widgets/time_input.dart';

class EditDayPanel extends HookConsumerWidget {
  const EditDayPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final editing = ref.watch(editingDateProvider);

    if (editing == null) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return _EditForm(
      key: ValueKey(editing.date),
      record: editing.record,
      date: editing.date,
      holidays: editing.holidays,
    );
  }
}

class _EditForm extends HookConsumerWidget {
  const _EditForm({
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
    // final recordId = record.id;
    // final useLeavesHourly = record.useLeavesHourly;
    // final dateRecord =
    //     record.dates.where((d) => d.date == date).firstOrNull ??
    //     DateRecord(
    //       date,
    //       record.workingHours,
    //       companyHoliday: false,
    //       holidayWork: false,
    //       plan: Leave(),
    //       used: Leave(),
    //       sick: Leave(),
    //       other: Leave(),
    //     );

    // final uid = ref.read(authUserProvider.select((u) => u.asData?.value?.uid));
    // final message = ref.read(snackBarMessageProvider.notifier);
    // final db = ref.read(firestoreProvider);
    // final nengo = ref.watch(nengoProvider);

    // final formKey = useMemoized(() => GlobalKey<FormState>());
    // final companyHoliday = useState(dateRecord.companyHoliday);
    // final holidayWork = useState(dateRecord.holidayWork);

    // final plan = useState(dateRecord.plan);
    // final used = useState(dateRecord.used);
    // final sick = useState(dateRecord.sick);
    // final other = useState(dateRecord.other);

    // final usedAll = used.value.all == true;
    // final sickAll = sick.value.all == true;
    // final otherAll = other.value.all == true;
    // final disabled = companyHoliday.value || usedAll || sickAll || otherAll;
    // final noteCtrl = useTextEditingController(text: dateRecord.note ?? '');

    // final workingFromC = useTextEditingController(
    //   text: dateRecord.workingHours.from.format() ?? '',
    // );
    // final workingToC = useTextEditingController(
    //   text: dateRecord.workingHours.to.format() ?? '',
    // );
    // final breaks = useState(dateRecord.workingHours.breaks);

    // final holidayName = holiday?.name;
    // final title =
    //     '${nengo.format(date)}(${date.weekDayLabel})'
    //     '${holidayName != null ? '  $holidayName' : ''}';

    // final workingHours = useState(
    //   Time(dateRecord.workingHours.seconds).format() ?? '--:--',
    // );

    // void listener() => updateWorkingHours(
    //   workingHours,
    //   record,
    //   date,
    //   Cal.today(),
    //   generateWorkingHours(workingFromC.text, workingToC.text, breaks.value),
    // );

    // useEffect(() {
    //   workingFromC.addListener(listener);
    //   workingToC.addListener(listener);

    //   return () {
    //     workingFromC.removeListener(listener);
    //     workingToC.removeListener(listener);
    //   };
    // }, const []);

    // Future<void> handleSubmit() async {
    //   if (uid == null) return;
    //   if (!(formKey.currentState?.validate() ?? true)) return;
    //   final newRecord = DateRecord(
    //     date,
    //     TimeSpanWithBreaks(
    //       from: Time.fromString(workingFromC.text),
    //       to: Time.fromString(workingToC.text),
    //       breaks: breaks.value,
    //     ),
    //     companyHoliday: companyHoliday.value,
    //     holidayWork: holidayWork.value,
    //     plan: plan.value,
    //     used: used.value,
    //     sick: sick.value,
    //     other: other.value,
    //     note: noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim(),
    //   );
    //   final result = await saveDateRecord(db, uid, recordId, newRecord);
    //   if (context.mounted) {
    //     result.match(
    //       (error) => message.show('保存に失敗しました: $error'),
    //       (_) => ref.read(editingDateProvider.notifier).close(),
    //     );
    //   }
    // }

    return BoxPanel(
      showDivider: false,
      children: [
        const SizedBox.shrink(),
        // Form(
        //   key: formKey,
        //   child: Wrap(
        //     spacing: panelSpacing,
        //     runSpacing: panelSpacing,
        //     children: [
        //       ConstrainedBox(
        //         constraints: const BoxConstraints(
        //           minWidth: columnWidth,
        //           maxWidth: columnWidth * 1.2,
        //         ),
        //         child: Column(
        //           mainAxisSize: MainAxisSize.min,
        //           crossAxisAlignment: CrossAxisAlignment.start,
        //           spacing: panelSpacing,
        //           children: [
        //             Text(title, style: Theme.of(context).textTheme.titleMedium),
        //             Row(
        //               spacing: panelSpacing,
        //               children: [
        //                 TimeInput(
        //                   labelText: '始業',
        //                   timeController: workingFromC,
        //                   disabled: disabled,
        //                 ),
        //                 TimeInput(
        //                   labelText: '終業',
        //                   timeController: workingToC,
        //                   disabled: disabled,
        //                 ),
        //               ],
        //             ),
        //             BreaksInput(
        //               breaks: breaks.value,
        //               onChanged: (v) {
        //                 breaks.value = v;
        //                 listener();
        //               },
        //             ),
        //           ],
        //         ),
        //       ),
        //       ConstrainedBox(
        //         constraints: const BoxConstraints(
        //           minWidth: columnWidth,
        //           maxWidth: columnWidth * 1.2,
        //         ),
        //         child: Column(
        //           mainAxisSize: MainAxisSize.min,
        //           crossAxisAlignment: CrossAxisAlignment.start,
        //           spacing: panelSpacing,
        //           children: [
        //             Text('労働時間: ${workingHours.value}'),
        //             SwitchListTile(
        //               value: companyHoliday.value,
        //               onChanged: usedAll || sickAll || otherAll
        //                   ? null
        //                   : (value) => companyHoliday.value = value,
        //               title: Row(
        //                 spacing: itemSpacing,
        //                 children: [
        //                   companyHoliday.value
        //                       ? iconCompanyHoliday
        //                       : iconWorked,
        //                   Text('休業日'),
        //                 ],
        //               ),
        //             ),
        //             SwitchListTile(
        //               value: holidayWork.value,
        //               onChanged: (value) => holidayWork.value = value,
        //               title: Row(
        //                 spacing: itemSpacing,
        //                 children: [
        //                   holidayWork.value ? iconOvertime : Icon(iconHoliday),
        //                   Text('休日出勤'),
        //                 ],
        //               ),
        //             ),
        //             LeaveInput(
        //               label: '有休予定',
        //               leave: plan.value,
        //               iconOff: iconPaidEmpty,
        //               iconPartial: iconPaidHalf,
        //               iconAll: iconPaidFull,
        //               enablePartial: useLeavesHourly,
        //               onChanged: disabled ? null : (l) => plan.value = l,
        //             ),
        //             LeaveInput(
        //               label: '有休実績',
        //               leave: used.value,
        //               iconOff: iconPaidEmpty,
        //               iconPartial: iconPaidHalf,
        //               iconAll: iconPaidFull,
        //               enablePartial: useLeavesHourly,
        //               onChanged: companyHoliday.value || sickAll || otherAll
        //                   ? null
        //                   : (l) => used.value = l,
        //             ),
        //             LeaveInput(
        //               label: '病欠',
        //               leave: sick.value,
        //               iconOff: iconSickEmpty,
        //               iconPartial: iconSickHalf,
        //               iconAll: iconSickFull,
        //               onChanged: companyHoliday.value || usedAll || otherAll
        //                   ? null
        //                   : (l) => sick.value = l,
        //             ),
        //             LeaveInput(
        //               label: 'その他',
        //               leave: other.value,
        //               iconOff: iconOtherEmpty,
        //               iconPartial: iconOtherHalf,
        //               iconAll: iconOtherFull,
        //               onChanged: companyHoliday.value || usedAll || sickAll
        //                   ? null
        //                   : (l) => other.value = l,
        //             ),
        //           ],
        //         ),
        //       ),
        //     ],
        //   ),
        // ),
        // ConstrainedBox(
        //   constraints: const BoxConstraints(maxWidth: columnWidth * 2),
        //   child: Column(
        //     crossAxisAlignment: CrossAxisAlignment.start,
        //     spacing: panelSpacing,
        //     children: [
        //       TextField(
        //         controller: noteCtrl,
        //         decoration: InputDecoration(
        //           border: const OutlineInputBorder(),
        //           labelText: '備考',
        //         ),
        //         maxLength: maxNoteLength,
        //       ),
        //       Align(
        //         alignment: Alignment.centerRight,
        //         child: Wrap(
        //           spacing: panelSpacing,
        //           runSpacing: panelSpacing,
        //           children: [
        //             OutlinedButton(
        //               onPressed: () =>
        //                   ref.read(editingDateProvider.notifier).close(),
        //               child: const Text('キャンセル'),
        //             ),
        //             FilledButton(
        //               onPressed: handleSubmit,
        //               child: const Row(
        //                 spacing: itemSpacing,
        //                 mainAxisSize: MainAxisSize.min,
        //                 children: [Icon(Symbols.check), Text('保存')],
        //               ),
        //             ),
        //           ],
        //         ),
        //       ),
        //     ],
        //   ),
        // ),
      ],
    );
  }
}
