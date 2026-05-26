import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:robanokyuka/config/firebase.dart';
import 'package:robanokyuka/config/theme.dart';
import 'package:robanokyuka/services/helpers.dart';
import 'package:robanokyuka/services/validators.dart';
import 'package:robanokyuka/services/authentication.dart';
import 'package:robanokyuka/widgets/box_panel.dart';

class ChangeEmailPanel extends HookConsumerWidget {
  const ChangeEmailPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final message = ref.read(snackBarMessageProvider.notifier);
    final email = useTextEditingController();
    final confirmEmail = useTextEditingController();
    final formKey = useMemoized(GlobalKey<FormState>.new);
    final isFormValid = useState(false);

    Future<void> handleSubmit() async {
      final result = await changeEmail(
        ref.read(authProvider),
        email.text.trim(),
      );
      result.match(
        (error) => message.show("メールアドレスの変更に失敗しました。"),
        (_) => message.show("メールアドレスの変更に成功しました。確認メールを送信しました。"),
      );
    }

    return BoxPanel(
      children: [
        Text("メールアドレスを変更する"),
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
                constraints: BoxConstraints(maxWidth: defaultInputWidth),
                child: TextFormField(
                  controller: email,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) =>
                      validateRequiredEmail(value?.trim() ?? ''),
                  decoration: InputDecoration(
                    labelText: "メールアドレス",
                    helperText: "入力必須です",
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: defaultInputWidth),
                child: TextFormField(
                  controller: confirmEmail,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) =>
                      validateConfirmation(email.text.trim(), value?.trim()),
                  decoration: InputDecoration(
                    labelText: "メールアドレス（確認）",
                    helperText: "確認のため同じ入力必須です",
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              FilledButton(
                onPressed: isFormValid.value ? () => handleSubmit() : null,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Symbols.send),
                    SizedBox(width: 8),
                    Text("送信"),
                  ],
                ),
              ),
            ],
          ),
        ),
        Text("【注意】 $emailFrom からのメールが受信できるようにしてください。"),
      ],
    );
  }
}
