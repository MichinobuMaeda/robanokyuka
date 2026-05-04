import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:yukyuchecker/config/firebase.dart';
import 'package:yukyuchecker/config/theme.dart';
import 'package:yukyuchecker/services/helpers.dart';
import 'package:yukyuchecker/services/validators.dart';
import 'package:yukyuchecker/services/authentication.dart';
import 'package:yukyuchecker/widgets/box_panel.dart';
import 'package:yukyuchecker/widgets/password_form_field.dart';

class EmailPasswordPanel extends HookConsumerWidget {
  const EmailPasswordPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final message = ref.read(snackBarMessageProvider.notifier);
    final email = useTextEditingController();
    final password = useTextEditingController();
    final formKey = useMemoized(GlobalKey<FormState>.new);
    final isFormValid = useState(false);

    Future<void> handleSubmit() async {
      message.clear();
      final result = await signInWithEmailAndPassword(
        auth(),
        email.text.trim(),
        password.text,
      );
      result.match(
        (error) => message.show("ログインに失敗しました。"),
        (_) => message.show("ログインしました。"),
      );
    }

    return BoxPanel(
      children: [
        Text("メールアドレスとパスワードでログインする"),
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
            children: <Widget>[
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
                child: PasswordFormField(
                  controller: password,
                  labelText: "パスワード",
                  helperText: "入力必須です",
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
        Text(
          "パスワードが未設定の場合、および、設定したパスワードを忘れた場合は、"
          "次の手順でパスワードを再設定してください。",
        ),
      ],
    );
  }
}
