import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:yukyuchecker/config/firebase.dart';
import 'package:yukyuchecker/services/helpers.dart';
import 'package:yukyuchecker/services/authentication.dart';
import 'package:yukyuchecker/widgets/box_panel.dart';

class GoogleAuthPanel extends HookConsumerWidget {
  const GoogleAuthPanel({super.key, this.reauthentication = false});

  final bool reauthentication;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final message = ref.read(snackBarMessageProvider.notifier);

    Future<void> handleSubmit() async {
      message.clear();
      if (reauthentication) {
        final result = await reauthenticateWithGoogle(auth());
        result.match(
          (error) => message.show("Googleでの再認証に失敗しました。"),
          (_) => message.show("Googleでの再認証に成功しました。"),
        );
      } else {
        final result = await signInWithGoogle(auth());
        result.match(
          (error) => message.show("Googleでのログインに失敗しました。"),
          (_) => message.show("Googleでのログインに成功しました。"),
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
              Text(reauthentication ? "Googleで再認証する" : "Googleでログインする"),
            ],
          ),
        ),
      ],
    );
  }
}
