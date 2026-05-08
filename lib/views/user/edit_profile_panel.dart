import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:robanokyuka/config/firebase.dart';
import 'package:robanokyuka/config/theme.dart';
import 'package:robanokyuka/models/users.dart';
import 'package:robanokyuka/services/helpers.dart';
import 'package:robanokyuka/widgets/box_panel.dart';
import 'package:robanokyuka/widgets/toggle_button.dart';

class EditProfilePanel extends HookConsumerWidget {
  const EditProfilePanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final message = ref.read(snackBarMessageProvider.notifier);
    final user = ref.watch(userProvider);

    final nameController = useTextEditingController(text: user?.name ?? '');
    useListenable(nameController);
    final showNengo = useState(user?.showNengo ?? false);
    final themeMode = useState(user?.themeMode ?? ThemeMode.system);
    final formKey = useMemoized(GlobalKey<FormState>.new);
    final isFormValid = useState(false);

    Future<void> handleThemeModeChanged(ThemeMode value) async {
      themeMode.value = value;
      if (user?.id == null) return;
      final result = await updateUserThemeMode(db(), user!.id, value);
      result.match(
        (error) => message.show('テーマモードの更新に失敗しました: $error'),
        (_) => message.show('テーマモードを更新しました'),
      );
    }

    Future<void> handleShowNengoChanged(bool value) async {
      showNengo.value = value;
      if (user?.id == null) return;
      final result = await updateUserShowNengo(db(), user!.id, value);
      result.match(
        (error) => message.show('元号表示の更新に失敗しました: $error'),
        (_) => message.show('元号表示を更新しました'),
      );
    }

    Future<void> handleSubmitName() async {
      if (user?.id == null) return;
      final result = await updateUserName(
        db(),
        user!.id,
        nameController.text.trim(),
      );
      result.match(
        (error) => message.show('名前の更新に失敗しました: $error'),
        (_) => message.show('名前を更新しました'),
      );
    }

    void handleReset() {
      nameController.text = user?.name ?? '';
      showNengo.value = user?.showNengo ?? false;
      themeMode.value = user?.themeMode ?? ThemeMode.system;
      isFormValid.value = false;
    }

    useEffect(() {
      handleReset();
      return null;
    }, [user]);

    return BoxPanel(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: panelSpacing,
          children: [
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: [
                ToggleButton(
                  icon: const Icon(Symbols.brightness_auto),
                  label: '自動',
                  active: themeMode.value == ThemeMode.system,
                  onPressed: () => handleThemeModeChanged(ThemeMode.system),
                ),
                ToggleButton(
                  icon: const Icon(Symbols.light_mode),
                  label: 'ライト',
                  active: themeMode.value == ThemeMode.light,
                  onPressed: () => handleThemeModeChanged(ThemeMode.light),
                ),
                ToggleButton(
                  icon: const Icon(Symbols.dark_mode),
                  label: 'ダーク',
                  active: themeMode.value == ThemeMode.dark,
                  onPressed: () => handleThemeModeChanged(ThemeMode.dark),
                ),
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 8.0,
              children: [
                const Text('西暦'),
                Switch(
                  value: showNengo.value,
                  onChanged: handleShowNengoChanged,
                ),
                const Text('年号'),
              ],
            ),
            Form(
              key: formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              onChanged: () {
                isFormValid.value = formKey.currentState?.validate() ?? false;
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                spacing: 16.0,
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: defaultInputWidth,
                    ),
                    child: TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: '名前',
                        helperText: '必須',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          (value ?? '').trim().isEmpty ? '名前を入力してください' : null,
                    ),
                  ),
                  FilledButton(
                    onPressed:
                        (isFormValid.value &&
                            nameController.text.trim() != (user?.name ?? ''))
                        ? handleSubmitName
                        : null,
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
            ),
          ],
        ),
      ],
    );
  }
}
