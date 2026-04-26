import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../config/firebase.dart';
import '../../config/theme.dart';
import '../../models/users.dart';
import '../../services/helpers.dart';
import '../../widgets/box_panel.dart';

class EditProfilePanel extends HookConsumerWidget {
  const EditProfilePanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final message = ref.read(snackBarMessageProvider.notifier);
    final user = ref.watch(userProvider);

    final nameController = useTextEditingController(text: user?.name ?? '');
    final showNengo = useState(user?.showNengo ?? false);
    final formKey = useMemoized(GlobalKey<FormState>.new);
    final isFormValid = useState(false);

    Future<void> handleSubmit() async {
      if (user?.id == null) return;
      final result = await updateUser(
        db(),
        user!.id,
        nameController.text.trim(),
        showNengo: showNengo.value,
      );
      result.match(
        (error) => message.show('名前の更新に失敗しました: $error'),
        (_) => message.show('名前を更新しました'),
      );
    }

    void handleReset() {
      nameController.text = user?.name ?? '';
      showNengo.value = user?.showNengo ?? false;
      isFormValid.value = false;
    }

    useEffect(() {
      handleReset();
      return null;
    }, [user]);

    return BoxPanel(
      children: [
        Form(
          key: formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          onChanged: () {
            isFormValid.value = formKey.currentState?.validate() ?? false;
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: panelSpacing,
            children: [
              Wrap(
                direction: Axis.horizontal,
                alignment: WrapAlignment.start,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: panelSpacing,
                runSpacing: panelSpacing,
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
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    spacing: 8.0,
                    children: [
                      const Text('西暦'),
                      Switch(
                        value: showNengo.value,
                        onChanged: (v) {
                          showNengo.value = v;
                          isFormValid.value =
                              formKey.currentState?.validate() ?? false;
                        },
                      ),
                      const Text('年号'),
                    ],
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                spacing: 16.0,
                children: [
                  OutlinedButton(
                    onPressed: handleReset,
                    child: const Text('リセット'),
                  ),
                  FilledButton(
                    onPressed: isFormValid.value ? handleSubmit : null,
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
      ],
    );
  }
}
