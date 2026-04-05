import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../config/theme.dart';
import '../../services/authentication.dart';
import '../../services/helpers.dart';
import '../../models/users.dart';
import '../../widgets/box_panel.dart';

const _aboutAccountDeletion = 'アカウントを削除するとすべてのデータが失われ、元に戻すことができません。';
const _confirmAccountDeletion = '本当にアカウントを削除しますか？';

class DeleteUserPanel extends HookConsumerWidget {
  const DeleteUserPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final message = ref.read(snackBarMessageProvider.notifier);
    final confirm = useState(false);

    Future<void> handleSubmit() async {
      {
        final uid = ref.watch(authUserProvider.select(selectUid));
        if (uid == null) {
          message.show("認証されたユーザーが見つかりません。");
          return;
        }
        final result = await deleteUserData(uid);
        result.match(
          (error) => message.show("ユーザーデータの削除に失敗しました。"),
          (_) => debugPrint("User data deleted successfully."),
        );
      }
      {
        final result = await deleteUser();
        result.match(
          (error) => message.show("アカウントの削除に失敗しました。"),
          (_) => message.show("アカウントを削除しました。"),
        );
      }
    }

    return BoxPanel(
      children: confirm.value
          ? [
              Text(_aboutAccountDeletion),
              Text(_confirmAccountDeletion),
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
                    onPressed: () {
                      confirm.value = false;
                      showBottomSheet(
                        context: context,
                        builder: (context) => _ConfirmationSheet(
                          onCancel: () => Navigator.pop(context),
                          onConfirm: () {
                            Navigator.pop(context);
                            handleSubmit();
                          },
                        ),
                      );
                    },
                    style: FilledButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.onError,
                      backgroundColor: Theme.of(context).colorScheme.error,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.delete),
                        SizedBox(width: 8),
                        Text("アカウント削除"),
                      ],
                    ),
                  ),
                ],
              ),
            ]
          : [
              Text(_aboutAccountDeletion),
              OutlinedButton(
                onPressed: () => confirm.value = true,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                  side: BorderSide(color: Theme.of(context).colorScheme.error),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.delete),
                    SizedBox(width: 8),
                    Text("アカウント削除"),
                  ],
                ),
              ),
            ],
    );
  }
}

class _ConfirmationSheet extends StatelessWidget {
  const _ConfirmationSheet({required this.onCancel, required this.onConfirm});

  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: bottomSheetPadding,
      child: Flex(
        direction: Axis.vertical,
        mainAxisSize: MainAxisSize.min,
        spacing: panelSpacing,
        children: [
          Text(_aboutAccountDeletion),
          Divider(),
          Text(_confirmAccountDeletion),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: panelSpacing,
            runSpacing: panelSpacing,
            children: [
              OutlinedButton(onPressed: onCancel, child: Text('キャンセル')),
              FilledButton(
                onPressed: onConfirm,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.delete),
                    SizedBox(width: 8),
                    Text('削除する'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
