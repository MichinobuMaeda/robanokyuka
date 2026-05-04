import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:yukyuchecker/config/firebase.dart';
import 'package:yukyuchecker/config/theme.dart';
import 'package:yukyuchecker/services/helpers.dart';
import 'package:yukyuchecker/services/validators.dart';
import 'package:yukyuchecker/services/authentication.dart';
import 'package:yukyuchecker/widgets/password_form_field.dart';
import 'package:yukyuchecker/widgets/box_panel.dart';

class PasswordReauthenticatePanel extends HookConsumerWidget {
  const PasswordReauthenticatePanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final message = ref.read(snackBarMessageProvider.notifier);
    final authUser = ref.watch(authUserProvider).value;
    final password = useTextEditingController();
    final formKey = useMemoized(GlobalKey<FormState>.new);
    final isFormValid = useState(false);

    if (authUser?.email == null) {
      return BoxPanel(
        children: [
          Text(
            "ユーザーのメールアドレスが見つからないため、"
            "パスワードによる再認証ができません。",
          ),
        ],
      );
    }

    Future<void> handleSubmit() async {
      message.clear();
      final value = password.text;
      password.value = TextEditingValue.empty;
      final result = await reauthenticateWithPassword(
        auth(),
        authUser!.email!,
        value,
      );
      result.match(
        (error) => message.show("再認証に失敗しました。"),
        (_) => message.show("再認証に成功しました。"),
      );
    }

    return BoxPanel(
      children: [
        Text("パスワードで再認証する"),
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
                child: PasswordFormField(
                  controller: password,
                  labelText: "パスワード",
                  helperText: "入力必須です",
                  validator: (value) => validateRequired(value),
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
