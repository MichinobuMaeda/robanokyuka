import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:robanokyuka/config/firebase.dart';
import 'package:robanokyuka/config/theme.dart';
import 'package:robanokyuka/models/service.dart';
import 'package:robanokyuka/models/users.dart';
import 'package:robanokyuka/services/helpers.dart';
import 'package:robanokyuka/services/validators.dart';
import 'package:robanokyuka/widgets/bordered_list_item.dart';

class UsersPanel extends HookConsumerWidget {
  const UsersPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final users = ref.watch(usersProvider).asData?.value ?? [];
    final admins = ref.watch(confProvider.select(selectAdmins));

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        switch (index) {
          case 0:
            return BorderedListItem(child: _Header());
          default:
            final itemIndex = index - 1;
            if (itemIndex < users.length) {
              return BorderedListItem(
                border: index % 2 == 1,
                child: _Item(user: users[itemIndex], admins: admins),
              );
            } else {
              return BorderedListItem(child: const Divider());
            }
        }
      }, childCount: users.length + 2),
    );
  }
}

class _Header extends HookConsumerWidget {
  const _Header();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final message = ref.read(snackBarMessageProvider.notifier);

    Future<void> handleAdd(String email, String name, bool isDisabled) async {
      final result = await addUserByAdmin(
        callFunction,
        email,
        name: name.isEmpty ? null : name,
      );
      await result.match(
        (error) async => message.show('利用者の追加に失敗しました: $error'),
        (_) async {
          message.show('利用者を追加しました');
        },
      );
    }

    Future<void> showAddSheet() async {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (sheetContext) {
          return _AddSheet(onConfirm: handleAdd);
        },
      );
    }

    return Row(
      children: [
        Expanded(child: Text('利用者', style: panelTitleStyle(context))),
        IconButton.filledTonal(onPressed: showAddSheet, icon: iconAdd),
      ],
    );
  }
}

class _Item extends HookConsumerWidget {
  const _Item({required this.user, required this.admins});

  final User user;
  final List<String> admins;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final message = ref.read(snackBarMessageProvider.notifier);

    Future<void> handleUpdate(String name, bool isDisabled) async {
      final result = await updateUserByAdmin(db(), user.id, name, isDisabled);
      result.match(
        (error) => message.show('利用者の更新に失敗しました: $error'),
        (_) => message.show('利用者を更新しました'),
      );
    }

    Future<void> handleDelete() async {
      final result = await deleteUserByAdmin(callFunction, user.id);
      result.match(
        (error) => message.show('利用者の削除に失敗しました: $error'),
        (_) => message.show('利用者を削除しました'),
      );
    }

    Future<void> showEditSheet() async {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (sheetContext) {
          return _EditSheet(
            user: user,
            onConfirm: handleUpdate,
            onDelete: handleDelete,
          );
        },
      );
    }

    return Flex(
      direction: Axis.horizontal,
      spacing: 8,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        IconButton(
          onPressed: showEditSheet,
          icon: iconEdit,
          color: Theme.of(context).colorScheme.primary,
        ),
        user.disabledAt != null
            ? Icon(Symbols.block, color: Theme.of(context).colorScheme.error)
            : (admins.contains(user.id)
                  ? Icon(Symbols.admin_panel_settings)
                  : Icon(Symbols.person)),
        Expanded(
          child: Text(
            user.name.isEmpty ? '--' : user.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _AddSheet extends HookWidget {
  const _AddSheet({required this.onConfirm});

  final void Function(String email, String name, bool disabled) onConfirm;

  @override
  Widget build(BuildContext context) {
    final emailController = useTextEditingController();
    final nameController = useTextEditingController();
    final disabled = useState(false);
    final formKey = useMemoized(GlobalKey<FormState>.new);

    useListenable(emailController);
    final isValid = validateRequiredEmail(emailController.text.trim()) == null;

    void handleSubmit() {
      if (!(formKey.currentState?.validate() ?? false)) return;
      Navigator.pop(context);
      onConfirm(
        emailController.text.trim(),
        nameController.text.trim(),
        disabled.value,
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 16,
            children: [
              Text('利用者を追加', style: Theme.of(context).textTheme.titleLarge),
              TextFormField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'メールアドレス',
                  helperText: '必須',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => validateRequiredEmail(value?.trim()),
              ),
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: '名前',
                  border: OutlineInputBorder(),
                ),
              ),
              SwitchListTile(
                value: disabled.value,
                onChanged: (v) => disabled.value = v,
                title: const Text('無効'),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
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
                    onPressed: isValid ? handleSubmit : null,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        iconAdd,
                        const SizedBox(width: 8),
                        const Text('追加'),
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
  const _EditSheet({
    required this.user,
    required this.onConfirm,
    required this.onDelete,
  });

  final User user;
  final void Function(String name, bool disabled) onConfirm;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final nameController = useTextEditingController(text: user.name);
    final disabled = useState(user.disabledAt != null);
    final formKey = useMemoized(GlobalKey<FormState>.new);

    void handleSubmit() {
      if (!(formKey.currentState?.validate() ?? false)) return;
      Navigator.pop(context);
      onConfirm(nameController.text.trim(), disabled.value);
    }

    Future<void> showDeleteConfirmation() async {
      await showModalBottomSheet<void>(
        context: context,
        builder: (sheetContext) {
          return _DeleteSheet(
            user: user,
            onConfirm: () {
              Navigator.pop(context); // close edit sheet too
              onDelete();
            },
          );
        },
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 16,
            children: [
              Text('利用者を更新', style: Theme.of(context).textTheme.titleLarge),
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: '名前',
                  helperText: '必須',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    (value ?? '').trim().isEmpty ? '名前を入力してください' : null,
              ),
              SwitchListTile(
                value: disabled.value,
                onChanged: (v) => disabled.value = v,
                title: const Text('無効'),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
              ),
              if (user.disabledAt != null)
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    onPressed: showDeleteConfirmation,
                    icon: iconDelete,
                    label: Text('利用者を削除'),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: Theme.of(context).colorScheme.error,
                      ),
                      foregroundColor: Theme.of(context).colorScheme.error,
                    ),
                  ),
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

class _DeleteSheet extends StatelessWidget {
  const _DeleteSheet({required this.user, required this.onConfirm});

  final User user;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: bottomSheetPadding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 24,
        children: [
          Text(
            '${user.name.isEmpty ? '利用者' : user.name} を削除しますか？',
            style: Theme.of(context).textTheme.titleLarge,
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
                child: const Text('削除'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
