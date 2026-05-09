import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:robanokyuka/config/firebase.dart';
import 'package:robanokyuka/services/helpers.dart';
import 'package:robanokyuka/services/authentication.dart';
import 'package:robanokyuka/widgets/box_panel.dart';

class MicrosoftAuthPanel extends HookConsumerWidget {
  const MicrosoftAuthPanel({super.key, this.reauthentication = false});

  final bool reauthentication;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final message = ref.read(snackBarMessageProvider.notifier);

    Future<void> handleSubmit() async {
      message.clear();
      if (reauthentication) {
        final result = await reauthenticateWithMicrosoft(auth());
        result.match(
          (error) => message.show("Microsoftでの再認証に失敗しました。"),
          (_) => message.show("Microsoftでの再認証に成功しました。"),
        );
      } else {
        final result = await signInWithMicrosoft(auth());
        result.match(
          (error) => message.show("Microsoftでのログインに失敗しました。"),
          (_) => message.show("Microsoftでのログインに成功しました。"),
        );
      }
    }

    return BoxPanel(
      children: [
        FilledButton(
          onPressed: () => handleSubmit(),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Symbols.send),
              SizedBox(width: 8),
              Text(reauthentication ? "Microsoftで再認証する" : "Microsoftでログインする"),
            ],
          ),
        ),
      ],
    );
  }
}
