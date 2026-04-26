import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../config/firebase.dart';
import '../../config/theme.dart';
import '../../services/authentication.dart';
import '../../services/helpers.dart';
import '../../widgets/box_panel.dart';

class SignOutPanel extends HookConsumerWidget {
  const SignOutPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final message = ref.read(snackBarMessageProvider.notifier);
    final confirm = useState(false);

    Future<void> handleSubmit() async {
      final result = await signOut(auth());
      result.match(
        (error) => message.show("ログアウトに失敗しました。"),
        (_) => message.show("ログアウトに成功しました。"),
      );
    }

    return BoxPanel(
      children: confirm.value
          ? [
              Text('本当にログアウトしますか？'),
              Wrap(
                direction: Axis.horizontal,
                spacing: panelSpacing,
                runSpacing: panelSpacing,
                children: [
                  OutlinedButton(
                    onPressed: () => confirm.value = false,
                    child: Text("キャンセル"),
                  ),
                  FilledButton(
                    onPressed: () => handleSubmit(),
                    style: FilledButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.onError,
                      backgroundColor: Theme.of(context).colorScheme.error,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.logout),
                        SizedBox(width: 8),
                        Text("ログアウト"),
                      ],
                    ),
                  ),
                ],
              ),
            ]
          : [
              Text('通常の利用方法でログアウトは必要ありません。'),
              OutlinedButton(
                onPressed: () => confirm.value = true,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                  side: BorderSide(color: Theme.of(context).colorScheme.error),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.logout),
                    SizedBox(width: 8),
                    Text("ログアウト"),
                  ],
                ),
              ),
            ],
    );
  }
}
