import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../config/firebase.dart';
import '../../config/theme.dart';
import '../../services/helpers.dart';
import '../../services/validators.dart';
import '../../services/authentication.dart';
import '../../widgets/box_panel.dart';
import '../../platform/platforms.dart';

class EmailLinkPanel extends HookConsumerWidget {
  const EmailLinkPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final message = ref.read(snackBarMessageProvider.notifier);
    final authUser = ref.watch(authUserProvider).value;
    final email = useTextEditingController(text: authUser?.email ?? '');
    final formKey = useMemoized(GlobalKey<FormState>.new);
    final isFormValid = useState(false);

    Future<void> handleSubmit() async {
      message.clear();
      final result = await sendSignInLinkToEmail(
        auth(),
        LocalStorage(),
        email.text.trim(),
      );
      result.match(
        (error) => message.show("ログイン用のリンクの送信に失敗しました。"),
        (_) => message.show("ログイン用のリンクを送信しました。"),
      );
    }

    return BoxPanel(
      children: [
        Text("ログインのためのリンクをEメールで受信する"),
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
                    helperText: "メールアドレスを入力してください",
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              FilledButton(
                onPressed: validateRequiredEmail(email.text.trim()) == null
                    ? () => handleSubmit()
                    : null,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [Icon(Icons.send), SizedBox(width: 8), Text("送信")],
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
