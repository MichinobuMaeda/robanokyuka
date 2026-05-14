import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:robanokyuka/config/firebase.dart';
import 'package:robanokyuka/services/helpers.dart';
import 'package:robanokyuka/services/authentication.dart';
import 'package:robanokyuka/widgets/box_panel.dart';

class FederatedAuthPanel extends HookConsumerWidget {
  const FederatedAuthPanel({super.key, this.reauthentication = false});

  final bool reauthentication;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final message = ref.read(snackBarMessageProvider.notifier);

    Future<void> handleSubmit(FederatedProvider provider) async {
      message.clear();
      if (reauthentication) {
        final result = await reauthenticateWithProvider(auth(), provider);
        result.match(
          (error) => message.show("${provider.name}での再認証に失敗しました。"),
          (_) => message.show("${provider.name}での再認証に成功しました。"),
        );
      } else {
        final result = await signInWithProvider(auth(), provider);
        result.match(
          (error) => message.show("${provider.name}でのログインに失敗しました。"),
          (_) => message.show("${provider.name}でのログインに成功しました。"),
        );
      }
    }

    return FederatedProvider.values.isEmpty
        ? BoxPanel(showDivider: false, children: [SizedBox.shrink()])
        : BoxPanel(
            children: [
              Wrap(
                spacing: 16.0,
                runSpacing: 16.0,
                children: FederatedProvider.values
                    .map(
                      (provider) => FilledButton(
                        onPressed: () => handleSubmit(provider),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Symbols.send),
                            SizedBox(width: 8),
                            Text(
                              reauthentication
                                  ? "${provider.name}で再認証する"
                                  : "${provider.name}でログインする",
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          );
  }
}
