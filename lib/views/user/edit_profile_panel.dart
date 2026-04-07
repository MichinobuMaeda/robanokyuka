import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../config/theme.dart';
import '../../models/conf.dart';
import '../../models/users.dart';
import '../../services/helpers.dart';
import '../../widgets/box_panel.dart';

class EditProfilePanel extends HookConsumerWidget {
  const EditProfilePanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final message = ref.read(snackBarMessageProvider.notifier);
    final uid = ref.watch(uidProvider);
    final usersAsync = ref.watch(usersProvider);
    final currentUser = usersAsync.asData?.value.firstOrNull;

    final nameController = useTextEditingController(
      text: currentUser?.name ?? '',
    );
    final formKey = useMemoized(GlobalKey<FormState>.new);
    final isFormValid = useState(false);

    Future<void> handleSubmit() async {
      if (uid == null) return;
      final result = await updateUser(uid, nameController.text.trim());
      result.match(
        (error) => message.show('名前の更新に失敗しました: $error'),
        (_) => message.show('名前を更新しました'),
      );
    }

    return BoxPanel(
      children: [
        Form(
          key: formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          onChanged: () {
            isFormValid.value = formKey.currentState?.validate() ?? false;
          },
          child: Wrap(
            direction: Axis.horizontal,
            alignment: WrapAlignment.start,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: panelSpacing,
            runSpacing: panelSpacing,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: defaultInputWidth),
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
                onPressed: isFormValid.value ? handleSubmit : null,
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [Icon(Icons.check), SizedBox(width: 8), Text('保存')],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
