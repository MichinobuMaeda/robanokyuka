import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:yukyuchecker/services/validators.dart';

import '../../config/firebase.dart';
import '../../config/theme.dart';
import '../../services/helpers.dart';
import '../../models/gengo.dart';
import '../../models/service.dart';
import '../../models/users.dart';
import '../../widgets/bordered_list_item.dart';
import '../../widgets/date_row.dart';

class HolidaysPanel extends HookConsumerWidget {
  const HolidaysPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedYear = useState(DateTime.now().year);
    final holidays = ref.watch(holidaysProvider);
    final gengos = ref.watch(gengosProvider);
    final showNengo = ref.watch(
      userProvider.select((user) => user?.showNengo == true),
    );

    final years =
        holidays.map((h) => int.parse(h.date.substring(0, 4))).toSet().toList()
          ..sort();
    if (!years.contains(selectedYear.value)) {
      years.add(selectedYear.value);
      years.sort();
    }

    final filtered = holidays
        .where(
          (holiday) =>
              int.parse(holiday.date.substring(0, 4)) == selectedYear.value,
        )
        .toList();

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        switch (index) {
          case 0:
            return BorderedListItem(child: _Header(gengos, showNengo));
          case 1:
            return BorderedListItem(
              child: _Years(
                years,
                selectedYear.value,
                (year) => selectedYear.value = year,
                showNengo,
                gengos,
              ),
            );
          default:
            final itemIndex = index - 2;
            if (itemIndex < filtered.length) {
              return BorderedListItem(
                border: index % 2 == 0,
                child: _Item(filtered[itemIndex], gengos, showNengo),
              );
            } else {
              return BorderedListItem(child: const Divider());
            }
        }
      }, childCount: filtered.length + 3),
    );
  }
}

class _Header extends HookConsumerWidget {
  const _Header(this.gengos, this.showNengo);

  final List<Gengo> gengos;
  final bool showNengo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final message = ref.read(snackBarMessageProvider.notifier);

    Future<void> handleAdd(Holiday holiday) async {
      final result = await setHoliday(db(), holiday);
      result.match(
        (error) => message.show('祝日の追加に失敗しました: $error'),
        (_) => message.show('祝日を追加しました'),
      );
    }

    Future<void> showAddSheet() async {
      final holidays = ref.watch(holidaysProvider);
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (sheetContext) {
          return _AddSheet(
            defaultHoliday,
            holidays,
            showNengo,
            gengos,
            handleAdd,
          );
        },
      );
    }

    return Row(
      children: [
        Expanded(child: Text('祝日', style: panelTitleStyle(context))),
        IconButton.filledTonal(
          onPressed: showAddSheet,
          icon: Icon(Icons.add, color: Theme.of(context).colorScheme.primary),
        ),
      ],
    );
  }
}

class _Years extends StatelessWidget {
  const _Years(
    this.years,
    this.selectedYear,
    this.onSelected,
    this.showNengo,
    this.gengos,
  );

  final List<int> years;
  final int selectedYear;
  final ValueChanged<int> onSelected;
  final bool showNengo;
  final List<Gengo> gengos;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        spacing: 8,
        children: years
            .map(
              (year) => ChoiceChip(
                label: Text(
                  showNengo ? formatNengo(gengos, '$year') : '$year年',
                ),
                selected: selectedYear == year,
                onSelected: (_) => onSelected(year),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _Item extends HookConsumerWidget {
  const _Item(this.holiday, this.gengos, this.showNengo);

  final Holiday holiday;
  final List<Gengo> gengos;
  final bool showNengo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final message = ref.read(snackBarMessageProvider.notifier);

    Future<void> handleDelete() async {
      final result = await deleteHoliday(db(), holiday);
      result.match(
        (error) => message.show('祝日の削除に失敗しました: $error'),
        (_) => message.show('祝日を削除しました'),
      );
    }

    Future<void> handleUpdateName(String name) async {
      final result = await setHoliday(
        db(),
        Holiday(date: holiday.date, name: name),
      );
      result.match(
        (error) => message.show('祝日の更新に失敗しました: $error'),
        (_) => message.show('祝日を更新しました'),
      );
    }

    Future<void> showDeleteConfirmation() async {
      await showModalBottomSheet<void>(
        context: context,
        builder: (sheetContext) {
          return _DeleteSheet(holiday, gengos, showNengo, handleDelete);
        },
      );
    }

    Future<void> showEditSheet() async {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (sheetContext) {
          return _EditSheet(holiday, gengos, showNengo, handleUpdateName);
        },
      );
    }

    return Flex(
      direction: Axis.horizontal,
      spacing: 8,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        IconButton(
          onPressed: showDeleteConfirmation,
          icon: Icon(Icons.delete, color: Theme.of(context).colorScheme.error),
        ),
        SizedBox(
          width: 96,
          child: Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${formatDate(holiday.date, gengos, showNengo)}(${dateToWeekday(holiday.date)})',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        Expanded(
          child: Text(
            holiday.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        IconButton(
          onPressed: showEditSheet,
          icon: Icon(Icons.edit, color: Theme.of(context).colorScheme.primary),
        ),
      ],
    );
  }
}

final defaultHoliday = Holiday(
  date: '${DateTime.now().year + 1}0101',
  name: '',
);

class _DeleteSheet extends HookConsumerWidget {
  const _DeleteSheet(this.holiday, this.gengos, this.showNengo, this.onConfirm);

  final Holiday holiday;
  final VoidCallback onConfirm;
  final List<Gengo> gengos;
  final bool showNengo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: bottomSheetPadding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 16,
        children: [
          Text('祝日を削除', style: Theme.of(context).textTheme.titleLarge),
          Text(
            '${formatDate(holiday.date, gengos, showNengo)} ${holiday.name} を削除しますか？',
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 16.0,
            children: [
              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: Text('キャンセル'),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.pop(context);
                  onConfirm();
                },
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.delete,
                      color: Theme.of(context).colorScheme.onError,
                    ),
                    SizedBox(width: 8),
                    Text(
                      '削除',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onError,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AddSheet extends HookConsumerWidget {
  const _AddSheet(
    this.holiday,
    this.holidays,
    this.showNengo,
    this.gengos,
    this.onConfirm,
  );

  final Holiday holiday;
  final List<Holiday> holidays;
  final bool showNengo;
  final List<Gengo> gengos;
  final ValueChanged<Holiday> onConfirm;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final yearController = useTextEditingController(
      text: showNengo
          ? formatNengo(gengos, holiday.date).replaceAll('年', '')
          : holiday.date.substring(0, 4),
    );
    final monthController = useTextEditingController(
      text: '${int.parse(holiday.date.substring(4, 6))}',
    );
    final dayController = useTextEditingController(
      text: '${int.parse(holiday.date.substring(6, 8))}',
    );
    final nameController = useTextEditingController(text: holiday.name);
    final formKey = useMemoized(GlobalKey<FormState>.new);
    final isFormValid = useState(false);

    String? validateName(String? value) {
      final name = (value ?? '').trim();
      if (name.isEmpty) {
        return '名称を入力してください';
      }
      return null;
    }

    void handleSubmit() {
      if (!(formKey.currentState?.validate() ?? false)) {
        return;
      }

      final newHoliday = Holiday(
        date: joinYmd(
          parseNengo(gengos, yearController.text),
          monthController.text,
          dayController.text,
        ),
        name: nameController.text.trim(),
      );
      Navigator.pop(context);
      onConfirm(newHoliday);
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
          onChanged: () =>
              isFormValid.value = formKey.currentState?.validate() ?? false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 16,
            children: [
              Text('祝日を追加', style: Theme.of(context).textTheme.titleLarge),
              DateRow(
                yearController: yearController,
                monthController: monthController,
                dayController: dayController,
                gengos: gengos,
                extraDayValidator: (year, month, day) =>
                    validateHoliday(holidays, year, month, day),
              ),
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: '名称',
                  helperText: '必須',
                  border: OutlineInputBorder(),
                ),
                validator: validateName,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: 16.0,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('キャンセル'),
                  ),
                  FilledButton(
                    onPressed: isFormValid.value ? handleSubmit : null,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add),
                        SizedBox(width: 8),
                        Text('追加'),
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

class _EditSheet extends HookConsumerWidget {
  const _EditSheet(this.holiday, this.gengos, this.showNengo, this.onConfirm);

  final Holiday holiday;
  final ValueChanged<String> onConfirm;
  final List<Gengo> gengos;
  final bool showNengo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nameController = useTextEditingController(text: holiday.name);
    final formKey = useMemoized(GlobalKey<FormState>.new);
    final isFormValid = useState(holiday.name.trim().isNotEmpty);

    String? validateName(String? value) {
      final name = (value ?? '').trim();
      if (name.isEmpty) {
        return '名称を入力してください';
      }
      return null;
    }

    void handleSubmit() {
      if (!(formKey.currentState?.validate() ?? false)) {
        return;
      }

      Navigator.pop(context);
      onConfirm(nameController.text.trim());
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
          onChanged: () =>
              isFormValid.value = formKey.currentState?.validate() ?? false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 16,
            children: [
              Text('祝日を更新', style: Theme.of(context).textTheme.titleLarge),
              Text(
                formatDate(holiday.date, gengos, showNengo),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: '名称',
                  helperText: '必須',
                  border: OutlineInputBorder(),
                ),
                validator: validateName,
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
                    onPressed: isFormValid.value ? handleSubmit : null,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check),
                        SizedBox(width: 8),
                        Text('更新'),
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
