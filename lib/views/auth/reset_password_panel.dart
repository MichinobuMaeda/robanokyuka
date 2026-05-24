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

class ResetPasswordPanel extends HookConsumerWidget {
  const ResetPasswordPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final message = ref.read(snackBarMessageProvider.notifier);
    final authUser = ref.watch(authUserProvider).value;
    final email = useTextEditingController(text: authUser?.email ?? '');
    useListenable(email);
    final formKey = useMemoized(GlobalKey<FormState>.new);
    final isFormValid = useState(false);

    void handleReset() {
      email.text = authUser?.email ?? '';
      isFormValid.value = validateRequiredEmail(email.text.trim()) == null;
    }

    Future<void> handleSubmit() async {
      final result = await sendPasswordResetEmail(
        ref.read(authProvider),
        email.text.trim(),
      );
      result.match(
        (error) => message.show("パスワード設定用のリンクの送信に失敗しました。"),
        (_) => message.show("パスワード設定用のリンクを送信しました。"),
      );
    }

    return BoxPanel(
      children: [
        Text("パスワード設定のためのリンクをEメールで受信する"),
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
                    suffixIcon: email.text == (authUser?.email ?? '')
                        ? null
                        : IconButton(
                            icon: const Icon(Symbols.clear),
                            onPressed: handleReset,
                          ),
                  ),
                ),
              ),
              FilledButton(
                onPressed: validateRequiredEmail(email.text.trim()) == null
                    ? () => handleSubmit()
                    : null,
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
