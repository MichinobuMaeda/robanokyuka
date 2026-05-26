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
import 'package:robanokyuka/widgets/password_form_field.dart';

class RegisterPanel extends HookConsumerWidget {
  const RegisterPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final message = ref.read(snackBarMessageProvider.notifier);
    final email = useTextEditingController();
    final confirmEmail = useTextEditingController();
    final password = useTextEditingController();
    final confirmPassword = useTextEditingController();
    final formKey = useMemoized(GlobalKey<FormState>.new);
    final isFormValid = useState(false);

    Future<void> handleSubmit() async {
      message.clear();
      final result = await registerNewUser(
        ref.read(authProvider),
        email.text.trim(),
        password.text,
      );
      result.match((error) => message.show("登録に失敗しました。"), (_) {
        password.clear();
        confirmPassword.clear();
        message.show("登録しました。");
      });
    }

    return BoxPanel(
      children: [
        Text("メールアドレスとパスワードで登録する"),
        Text("「送信」ボタンで確認のためのメールを送信します。"),
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
                    helperText: "入力必須です",
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: defaultInputWidth),
                child: PasswordFormField(
                  controller: password,
                  labelText: "パスワード",
                  helperText: "入力必須です",
                  validator: validateRequiredPassword,
                ),
              ),
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: defaultInputWidth),
                child: PasswordFormField(
                  controller: confirmPassword,
                  labelText: "パスワード（確認）",
                  helperText: "入力必須です",
                  validator: (value) =>
                      validateConfirmation(password.text, value),
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
      ],
    );
  }
}
