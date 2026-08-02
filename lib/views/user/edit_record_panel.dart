import 'package:flutter/material.dart';
// import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
// import 'package:material_symbols_icons/symbols.dart';

// import 'package:robanokyuka/config/firebase.dart';
// import 'package:robanokyuka/config/theme.dart';
import 'package:robanokyuka/models/nengo.dart';
import 'package:robanokyuka/models/record.dart';
// import 'package:robanokyuka/services/authentication.dart';
// import 'package:robanokyuka/services/helpers.dart';
// import 'package:robanokyuka/services/validators.dart';
import 'package:robanokyuka/widgets/box_panel.dart';
// import 'package:robanokyuka/widgets/date_input.dart';
// import 'package:robanokyuka/widgets/time_input.dart';

// const _publicHolidaysLabels = [...weekdayLabels, '祝日'];

class EditRecordPanel extends HookConsumerWidget {
  const EditRecordPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final record = ref.watch(editingRecordProvider);
    final nengo = ref.watch(nengoProvider);

    if (record == null) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return _EditForm(key: ValueKey(record.id), record: record, nengo: nengo);
  }
}

class _EditForm extends HookConsumerWidget {
  const _EditForm({super.key, required this.record, required this.nengo});

  final Record record;
  final Nengo nengo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // final uid = ref.read(
    //   authUserProvider.select((authUser) => authUser.asData?.value?.uid),
    // );

    // if (uid == null) {
    //   return const SliverToBoxAdapter(child: SizedBox.shrink());
    // }

    // final message = ref.read(snackBarMessageProvider.notifier);
    // final fromC = useTextEditingController(
    //   text: nengo.formatShort(record.from),
    // );
    // final toC = useTextEditingController(text: nengo.formatShort(record.to));
    // final givenLeavesC = useTextEditingController(
    //   text: '${record.givenLeaves}',
    // );
    // final minLeavesC = useTextEditingController(text: '${record.minLeaves}');
    // final publicHolidays = useState(List<bool>.from(record.holidays));
    // final useLeavesHourly = useState(!!record.useLeavesHourly);
    // final workingFromC = useTextEditingController(
    //   text: record.workingHours.from.format() ?? '',
    // );
    // final workingToC = useTextEditingController(
    //   text: record.workingHours.to.format() ?? '',
    // );
    // final breaks = useState(record.workingHours.breaks);
    // final workingHours = useState<TimeSpanWithBreaks?>(record.workingHours);

    // String formatWorkingHours() => workingHours.value == null
    //     ? "-:--"
    //     : Time(workingHours.value!.seconds).format() ?? "0:00";

    // final formKey = useMemoized(GlobalKey<FormState>.new);

    // void listener() {
    //   final span = generateWorkingHours(
    //     workingFromC.text,
    //     workingToC.text,
    //     breaks.value,
    //   );
    //   workingHours.value = span;
    // }

    // useEffect(() {
    //   workingFromC.addListener(listener);
    //   workingToC.addListener(listener);

    //   return () {
    //     workingFromC.removeListener(listener);
    //     workingToC.removeListener(listener);
    //   };
    // }, const []);

    // Future<void> Function()? handleSubmit() =>
    //     (formKey.currentState?.validate() != true ||
    //             workingHours.value == null) &&
    //         record.id.isNotEmpty
    //     ? null
    //     : () async {
    //         final db = ref.read(firestoreProvider);
    //         final updated = Record(
    //           id: record.id,
    //           from: nengo.parseDate(fromC.text)!, // Validated
    //           to: nengo.parseDate(toC.text)!, // Validated
    //           holidays: List<bool>.from(publicHolidays.value),
    //           givenLeaves: int.parse(givenLeavesC.text),
    //           minLeaves: int.parse(minLeavesC.text),
    //           useLeavesHourly: useLeavesHourly.value,
    //           workingHours: workingHours.value!,
    //         );
    //         ref.read(editingRecordProvider.notifier).close();
    //         final result = await saveRecord(db, uid, updated);
    //         result.match(
    //           (error) => message.show('期間の保存に失敗しました: $error'),
    //           (_) => message.show('期間を保存しました'),
    //         );
    //       };

    return BoxPanel(
      showDivider: false,
      children: [
        const SizedBox.shrink(),
        // Form(
        //   key: formKey,
        //   autovalidateMode: AutovalidateMode.onUserInteraction,
        //   child: Column(
        //     mainAxisSize: MainAxisSize.min,
        //     crossAxisAlignment: CrossAxisAlignment.start,
        //     spacing: panelSpacing,
        //     children: [
        //       Text(
        //         record.id.isEmpty ? '期間を追加' : '期間を更新',
        //         style: Theme.of(context).textTheme.titleLarge,
        //       ),
        //       Wrap(
        //         spacing: panelSpacing,
        //         runSpacing: panelSpacing,
        //         children: [
        //           DateInput(
        //             labelText: '開始日',
        //             dateController: fromC,
        //             nengo: nengo,
        //           ),
        //           DateInput(
        //             labelText: '終了日',
        //             dateController: toC,
        //             nengo: nengo,
        //           ),
        //         ],
        //       ),
        //       Wrap(
        //         spacing: itemSpacing,
        //         runSpacing: itemSpacing,
        //         crossAxisAlignment: WrapCrossAlignment.center,
        //         children: List.generate(
        //           _publicHolidaysLabels.length + 1,
        //           (i) => i == 0
        //               ? Text(
        //                   '定休日',
        //                   style: Theme.of(context).textTheme.labelLarge,
        //                 )
        //               : FilterChip(
        //                   label: Text(_publicHolidaysLabels[i - 1]),
        //                   selected: publicHolidays.value[i - 1],
        //                   onSelected: (v) {
        //                     publicHolidays.value = [...publicHolidays.value]
        //                       ..[i - 1] = v;
        //                   },
        //                 ),
        //         ),
        //       ),
        //       Wrap(
        //         spacing: panelSpacing,
        //         runSpacing: panelSpacing,
        //         children: [
        //           SizedBox(
        //             width: 112,
        //             child: TextFormField(
        //               controller: givenLeavesC,
        //               keyboardType: TextInputType.number,
        //               decoration: const InputDecoration(
        //                 labelText: '有休付与日数',
        //                 border: OutlineInputBorder(),
        //                 helperText: '1以上',
        //               ),
        //               validator: validateNonNegInt,
        //             ),
        //           ),
        //           SizedBox(
        //             width: 112,
        //             child: TextFormField(
        //               controller: minLeavesC,
        //               keyboardType: TextInputType.number,
        //               decoration: const InputDecoration(
        //                 labelText: '最小取得日数',
        //                 border: OutlineInputBorder(),
        //                 helperText: '1以上',
        //               ),
        //               validator: validateNonNegInt,
        //             ),
        //           ),
        //           SizedBox(
        //             width: 200,
        //             child: SwitchListTile(
        //               value: useLeavesHourly.value,
        //               onChanged: (v) => useLeavesHourly.value = v == true,
        //               title: const Text('時間有休可'),
        //             ),
        //           ),
        //         ],
        //       ),
        //       Wrap(
        //         spacing: panelSpacing,
        //         runSpacing: panelSpacing,
        //         crossAxisAlignment: WrapCrossAlignment.center,
        //         children: [
        //           TimeInput(labelText: '始業', timeController: workingFromC),
        //           TimeInput(labelText: '終業', timeController: workingToC),
        //         ],
        //       ),
        //       BreaksInput(
        //         breaks: breaks.value,
        //         onChanged: (v) {
        //           breaks.value = v;
        //           listener();
        //         },
        //       ),
        //       Text('所定労働時間: ${formatWorkingHours()}'),
        //       ConstrainedBox(
        //         constraints: const BoxConstraints(maxWidth: columnWidth * 2),
        //         child: Align(
        //           alignment: Alignment.centerRight,
        //           child: Wrap(
        //             spacing: panelSpacing,
        //             runSpacing: panelSpacing,
        //             children: [
        //               OutlinedButton(
        //                 onPressed: () =>
        //                     ref.read(editingRecordProvider.notifier).close(),
        //                 child: const Text('キャンセル'),
        //               ),
        //               FilledButton(
        //                 onPressed: handleSubmit(),
        //                 child: const Row(
        //                   spacing: itemSpacing,
        //                   mainAxisSize: MainAxisSize.min,
        //                   children: [
        //                     Icon(Symbols.check),
        //                     SizedBox(width: 8),
        //                     Text('保存'),
        //                   ],
        //                 ),
        //               ),
        //             ],
        //           ),
        //         ),
        //       ),
        //     ],
        //   ),
        // ),
      ],
    );
  }
}
