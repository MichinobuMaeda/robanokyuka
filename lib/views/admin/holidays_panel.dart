import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../config/theme.dart';
import '../../services/helpers.dart';
import '../../models/holidays.dart';
import '../../widgets/bordered_list_item.dart';

class HolidaysPanel extends HookConsumerWidget {
  const HolidaysPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedYear = useState(DateTime.now().year);
    final holidays = ref.watch(holidaysProvider).asData?.value ?? [];

    final years = holidays.map((h) => h.year).toSet().toList()..sort();
    if (!years.contains(selectedYear.value)) {
      years.add(selectedYear.value);
      years.sort();
    }

    final filtered = holidays
        .where((holiday) => holiday.year == selectedYear.value)
        .toList();

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        switch (index) {
          case 0:
            return BorderedListItem(child: _Header());
          case 1:
            return BorderedListItem(
              child: _Years(
                years: years,
                selectedYear: selectedYear.value,
                onSelected: (year) => selectedYear.value = year,
              ),
            );
          default:
            final itemIndex = index - 2;
            if (itemIndex < filtered.length) {
              return BorderedListItem(
                border: index % 2 == 0,
                child: _Item(holiday: filtered[itemIndex]),
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
  const _Header();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final message = ref.read(snackBarMessageProvider.notifier);

    Future<void> handleAdd(Holiday holiday) async {
      final result = await setHoliday(holiday);
      result.match(
        (error) => message.show('祝日の追加に失敗しました: $error'),
        (_) => message.show('祝日を追加しました'),
      );
    }

    Future<void> showAddSheet() async {
      final holidays = ref.watch(holidaysProvider).asData?.value ?? [];
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (sheetContext) {
          return _AddSheet(
            holiday: defaultHoliday,
            holidays: holidays,
            onConfirm: (holiday) {
              handleAdd(holiday);
            },
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
  const _Years({
    required this.years,
    required this.selectedYear,
    required this.onSelected,
  });

  final List<int> years;
  final int selectedYear;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        spacing: 8,
        children: years
            .map(
              (year) => ChoiceChip(
                label: Text('$year年'),
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
  const _Item({required this.holiday});

  final Holiday holiday;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final message = ref.read(snackBarMessageProvider.notifier);

    Future<void> handleDelete() async {
      final result = await deleteHoliday(holiday);
      result.match(
        (error) => message.show('祝日の削除に失敗しました: $error'),
        (_) => message.show('祝日を削除しました'),
      );
    }

    Future<void> handleUpdateName(String name) async {
      final result = await setHoliday(
        Holiday(
          year: holiday.year,
          month: holiday.month,
          day: holiday.day,
          name: name,
        ),
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
          return _DeleteSheet(
            holiday: holiday,
            onConfirm: () {
              handleDelete();
            },
          );
        },
      );
    }

    Future<void> showEditSheet() async {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (sheetContext) {
          return _EditSheet(holiday: holiday, onConfirm: handleUpdateName);
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
              '${holiday.month}月${holiday.day}日(${dateToWeekday(holiday.year, holiday.month, holiday.day)})',
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
  year: DateTime.now().year + 1,
  month: 1,
  day: 1,
  name: '',
);

class _DeleteSheet extends StatelessWidget {
  const _DeleteSheet({required this.holiday, required this.onConfirm});

  final Holiday holiday;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: bottomSheetPadding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${holiday.month}月${holiday.day}日 ${holiday.name} を削除しますか？'),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('キャンセル'),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  onConfirm();
                },
                child: const Text('削除'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AddSheet extends HookConsumerWidget {
  const _AddSheet({
    required this.holiday,
    required this.holidays,
    required this.onConfirm,
  });

  final Holiday holiday;
  final List<Holiday> holidays;
  final ValueChanged<Holiday> onConfirm;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final yearController = useTextEditingController(text: '${holiday.year}');
    final monthController = useTextEditingController(text: '${holiday.month}');
    final dayController = useTextEditingController(text: '${holiday.day}');
    final nameController = useTextEditingController(text: holiday.name);
    final formKey = useMemoized(GlobalKey<FormState>.new);

    String? validateYear(String? value) {
      String? error;
      final year = int.tryParse(value ?? '');

      if (year == null) {
        error = '年を数値で入力してください';
      } else if (year < 1900) {
        error = '年は 1900 以上を入力してください';
      }
      return error;
    }

    String? validateMonth(String? value) {
      String? error;
      final month = int.tryParse(value ?? '');
      if (month == null) {
        error = '月を数値で入力してください';
      } else if (month < 1 || month > 12) {
        error = '月は 1 から 12 で入力してください';
      }
      return error;
    }

    String? validateDay(String? value) {
      final year = int.tryParse(yearController.text);
      final month = int.tryParse(monthController.text);
      String? error;
      final day = int.tryParse(value ?? '');
      if (day == null) {
        error = '日を数値で入力してください';
      } else if (day < 1 || day > 31) {
        error = '日は 1 から 31 で入力してください';
      } else if (year != null && month != null) {
        final date = DateTime(year, month, day);
        if (date.year != year || date.month != month || date.day != day) {
          error = '存在しない日付です';
        } else if (holidays.any(
          (h) => h.year == year && h.month == month && h.day == day,
        )) {
          error = 'この日付はすでに登録されています';
        }
      }
      return error;
    }

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
        year: int.parse(yearController.text),
        month: int.parse(monthController.text),
        day: int.parse(dayController.text),
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 16,
            children: [
              Text('祝日を追加', style: Theme.of(context).textTheme.titleLarge),
              TextFormField(
                controller: yearController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: '年',
                  helperText: '必須',
                  border: OutlineInputBorder(),
                ),
                validator: validateYear,
              ),
              TextFormField(
                controller: monthController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: '月',
                  helperText: '必須',
                  border: OutlineInputBorder(),
                ),
                validator: validateMonth,
              ),
              TextFormField(
                controller: dayController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: '日',
                  helperText: '必須',
                  border: OutlineInputBorder(),
                ),
                validator: validateDay,
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
                    onPressed: handleSubmit,
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

class _EditSheet extends HookWidget {
  const _EditSheet({required this.holiday, required this.onConfirm});

  final Holiday holiday;
  final ValueChanged<String> onConfirm;

  @override
  Widget build(BuildContext context) {
    final nameController = useTextEditingController(text: holiday.name);
    final formKey = useMemoized(GlobalKey<FormState>.new);

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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 16,
            children: [
              Text('祝日を更新', style: Theme.of(context).textTheme.titleLarge),
              Text(
                '${holiday.year}年${holiday.month}月${holiday.day}日',
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
                    onPressed: handleSubmit,
                    child: const Text('更新'),
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
