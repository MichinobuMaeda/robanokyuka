import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:robanokyuka/config/firebase.dart';
import 'package:robanokyuka/config/theme.dart';
import 'package:robanokyuka/services/helpers.dart';
import 'package:robanokyuka/models/cal_date.dart';
import 'package:robanokyuka/models/service.dart';
import 'package:robanokyuka/widgets/bordered_list_item.dart';

class GengosPanel extends HookConsumerWidget {
  const GengosPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gengos = ref.watch(confProvider.select((c) => c?.gengos ?? []));

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        switch (index) {
          case 0:
            return BorderedListItem(child: _Header(gengos));
          default:
            final itemIndex = index - 1;
            if (itemIndex < gengos.length) {
              return BorderedListItem(
                border: index % 2 == 0,
                child: _Item(gengos[itemIndex], gengos),
              );
            } else {
              return BorderedListItem(child: const Divider());
            }
        }
      }, childCount: gengos.length + 2),
    );
  }
}

class _Header extends HookConsumerWidget {
  const _Header(this.gengos);

  final List<Gengo> gengos;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final message = ref.read(snackBarMessageProvider.notifier);

    Future<void> handleAdd(Gengo gengo) async {
      final result = await setGengos(db(), [...gengos, gengo]);
      result.match(
        (error) => message.show('元号の追加に失敗しました: $error'),
        (_) => message.show('元号を追加しました'),
      );
    }

    Future<void> showAddSheet() async {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (_) => _AddSheet(gengos, handleAdd),
      );
    }

    return Row(
      children: [
        Expanded(child: Text('元号', style: panelTitleStyle(context))),
        IconButton.filledTonal(onPressed: showAddSheet, icon: iconAdd),
      ],
    );
  }
}

class _Item extends HookConsumerWidget {
  const _Item(this.gengo, this.gengos);

  final Gengo gengo;
  final List<Gengo> gengos;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final message = ref.read(snackBarMessageProvider.notifier);

    Future<void> handleDelete() async {
      final updated = gengos.where((g) => g != gengo).toList();
      final result = await setGengos(db(), updated);
      result.match(
        (error) => message.show('元号の削除に失敗しました: $error'),
        (_) => message.show('元号を削除しました'),
      );
    }

    Future<void> showDeleteSheet() async {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (_) => _DeleteSheet(gengo, handleDelete),
      );
    }

    Future<void> handleEdit(Gengo updated) async {
      final list = gengos.map((g) => g == gengo ? updated : g).toList();
      final result = await setGengos(db(), list);
      result.match(
        (error) => message.show('元号の更新に失敗しました: $error'),
        (_) => message.show('元号を更新しました'),
      );
    }

    Future<void> showEditSheet() async {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (_) => _EditSheet(gengo, gengos, handleEdit),
      );
    }

    return Flex(
      direction: Axis.horizontal,
      spacing: 8,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        IconButton(
          onPressed: showDeleteSheet,
          icon: iconDelete,
          color: Theme.of(context).colorScheme.error,
        ),
        Expanded(
          child: Text(
            '${gengo.date.year}年 ${gengo.date.month}月 ${gengo.date.day}日 ${gengo.name} (${gengo.short})',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        IconButton(
          onPressed: showEditSheet,
          icon: iconEdit,
          color: Theme.of(context).colorScheme.primary,
        ),
      ],
    );
  }
}

class _DeleteSheet extends HookConsumerWidget {
  const _DeleteSheet(this.gengo, this.onConfirm);

  final Gengo gengo;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: bottomSheetPadding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 16,
        children: [
          Text('元号を削除', style: Theme.of(context).textTheme.titleLarge),
          Text(
            '${gengo.date.year}年 ${gengo.date.month}月 ${gengo.date.day}日 ${gengo.name} (${gengo.short}) を削除しますか？',
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
                onPressed: () {
                  Navigator.pop(context);
                  onConfirm();
                },
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                  foregroundColor: Theme.of(context).colorScheme.onError,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    iconDelete,
                    const SizedBox(width: 8),
                    const Text('削除'),
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

class _EditSheet extends HookConsumerWidget {
  const _EditSheet(this.gengo, this.gengos, this.onConfirm);

  final Gengo gengo;
  final List<Gengo> gengos;
  final ValueChanged<Gengo> onConfirm;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final yearController = useTextEditingController(
      text: gengo.date.year.toString(),
    );
    final monthController = useTextEditingController(
      text: gengo.date.month.toString(),
    );
    final dayController = useTextEditingController(
      text: gengo.date.day.toString(),
    );
    final nameController = useTextEditingController(text: gengo.name);
    final shortController = useTextEditingController(text: gengo.short);
    final formKey = useMemoized(GlobalKey<FormState>.new);
    final isFormValid = useState(true);

    String? validateYear(String? value) {
      final y = int.tryParse((value ?? '').trim());
      if (y == null || y < 1) return '年を入力してください';
      final m = int.tryParse(monthController.text.trim());
      final d = int.tryParse(dayController.text.trim());
      if (m != null && d != null) {
        final alreadyUsed = gengos.any(
          (g) =>
              g != gengo &&
              g.date.year == y &&
              g.date.month == m &&
              g.date.day == d,
        );
        if (alreadyUsed) return '登録済みの日付です';
      }
      return null;
    }

    String? validateMonth(String? value) {
      final m = int.tryParse((value ?? '').trim());
      if (m == null || m < 1 || m > 12) return '1〜12';
      return null;
    }

    String? validateDay(String? value) {
      final d = int.tryParse((value ?? '').trim());
      if (d == null || d < 1 || d > 31) return '1〜31';
      return null;
    }

    String? validateName(String? value) {
      if ((value ?? '').trim().isEmpty) return '元号名を入力してください';
      return null;
    }

    String? validateShort(String? value) {
      if ((value ?? '').trim().isEmpty) return '略称を入力してください';
      return null;
    }

    void handleSubmit() {
      if (!(formKey.currentState?.validate() ?? false)) return;
      final year = int.tryParse(yearController.text.trim());
      final month = int.tryParse(monthController.text.trim());
      final day = int.tryParse(dayController.text.trim());
      if (year == null || month == null || day == null) return;
      Navigator.pop(context);
      onConfirm(
        Gengo(
          date: Cal(year, month, day),
          name: nameController.text.trim(),
          short: shortController.text.trim(),
        ),
      );
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
              Text('元号を編集', style: Theme.of(context).textTheme.titleLarge),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 8,
                children: [
                  SizedBox(
                    width: 88,
                    child: TextFormField(
                      controller: yearController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: '年',
                        helperText: ' ',
                        border: OutlineInputBorder(),
                      ),
                      validator: validateYear,
                    ),
                  ),
                  SizedBox(
                    width: 64,
                    child: TextFormField(
                      controller: monthController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: '月',
                        helperText: ' ',
                        border: OutlineInputBorder(),
                      ),
                      validator: validateMonth,
                    ),
                  ),
                  SizedBox(
                    width: 64,
                    child: TextFormField(
                      controller: dayController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: '日',
                        helperText: ' ',
                        border: OutlineInputBorder(),
                      ),
                      validator: validateDay,
                    ),
                  ),
                ],
              ),
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: '元号名',
                  helperText: '必須',
                  border: OutlineInputBorder(),
                ),
                validator: validateName,
              ),
              TextFormField(
                controller: shortController,
                decoration: const InputDecoration(
                  labelText: '略称',
                  helperText: '必須（例: R）',
                  border: OutlineInputBorder(),
                ),
                validator: validateShort,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: 16.0,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('キャンセル'),
                  ),
                  FilledButton.icon(
                    onPressed: isFormValid.value ? handleSubmit : null,
                    icon: iconEdit,
                    label: const Text('更新'),
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

class _AddSheet extends HookConsumerWidget {
  const _AddSheet(this.gengos, this.onConfirm);

  final List<Gengo> gengos;
  final ValueChanged<Gengo> onConfirm;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final yearController = useTextEditingController(
      text: DateTime.now().year.toString(),
    );
    final monthController = useTextEditingController(text: '1');
    final dayController = useTextEditingController(text: '1');
    final nameController = useTextEditingController();
    final shortController = useTextEditingController();
    final formKey = useMemoized(GlobalKey<FormState>.new);
    final isFormValid = useState(false);

    String? validateYear(String? value) {
      final y = int.tryParse((value ?? '').trim());
      if (y == null || y < 1) return '年を入力してください';
      final m = int.tryParse(monthController.text.trim());
      final d = int.tryParse(dayController.text.trim());
      if (m != null && d != null) {
        final alreadyUsed = gengos.any(
          (g) => g.date.year == y && g.date.month == m && g.date.day == d,
        );
        if (alreadyUsed) return '登録済みの日付です';
      }
      return null;
    }

    String? validateMonth(String? value) {
      final m = int.tryParse((value ?? '').trim());
      if (m == null || m < 1 || m > 12) return '1〜12';
      return null;
    }

    String? validateDay(String? value) {
      final d = int.tryParse((value ?? '').trim());
      if (d == null || d < 1 || d > 31) return '1〜31';
      return null;
    }

    String? validateName(String? value) {
      if ((value ?? '').trim().isEmpty) return '元号名を入力してください';
      return null;
    }

    String? validateShort(String? value) {
      if ((value ?? '').trim().isEmpty) return '略称を入力してください';
      return null;
    }

    void handleSubmit() {
      if (!(formKey.currentState?.validate() ?? false)) return;
      final year = int.tryParse(yearController.text.trim());
      final month = int.tryParse(monthController.text.trim());
      final day = int.tryParse(dayController.text.trim());
      if (year == null || month == null || day == null) return;
      Navigator.pop(context);
      onConfirm(
        Gengo(
          date: Cal(year, month, day),
          name: nameController.text.trim(),
          short: shortController.text.trim(),
        ),
      );
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
              Text('元号を追加', style: Theme.of(context).textTheme.titleLarge),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 8,
                children: [
                  SizedBox(
                    width: 88,
                    child: TextFormField(
                      controller: yearController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: '年',
                        helperText: ' ',
                        border: OutlineInputBorder(),
                      ),
                      validator: validateYear,
                    ),
                  ),
                  SizedBox(
                    width: 64,
                    child: TextFormField(
                      controller: monthController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: '月',
                        helperText: ' ',
                        border: OutlineInputBorder(),
                      ),
                      validator: validateMonth,
                    ),
                  ),
                  SizedBox(
                    width: 64,
                    child: TextFormField(
                      controller: dayController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: '日',
                        helperText: ' ',
                        border: OutlineInputBorder(),
                      ),
                      validator: validateDay,
                    ),
                  ),
                ],
              ),
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: '元号名',
                  helperText: '必須',
                  border: OutlineInputBorder(),
                ),
                validator: validateName,
              ),
              TextFormField(
                controller: shortController,
                decoration: const InputDecoration(
                  labelText: '略称',
                  helperText: '必須（例: R）',
                  border: OutlineInputBorder(),
                ),
                validator: validateShort,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: 16.0,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('キャンセル'),
                  ),
                  FilledButton.icon(
                    onPressed: isFormValid.value ? handleSubmit : null,
                    icon: Icon(Symbols.add),
                    label: const Text('追加'),
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
