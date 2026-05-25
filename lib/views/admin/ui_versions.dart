import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:robanokyuka/config/firebase.dart';
import 'package:robanokyuka/config/theme.dart';
import 'package:robanokyuka/models/service.dart';
import 'package:robanokyuka/services/helpers.dart';

const inputWidth = 128.0;

class UiVersionsPanel extends HookConsumerWidget {
  const UiVersionsPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conf = ref.watch(confProvider);

    if (conf == null) {
      return SliverToBoxAdapter(child: SizedBox.shrink());
    }

    final savedUi = conf.uiVersion;
    final savedAndroid = conf.androidVersion;
    final savedIos = conf.iosVersion;

    final uiCtrl = useTextEditingController();
    final androidCtrl = useTextEditingController();
    final iosCtrl = useTextEditingController();

    useEffect(() {
      uiCtrl.text = savedUi;
      androidCtrl.text = savedAndroid;
      iosCtrl.text = savedIos;
      return null;
    }, [savedUi, savedAndroid, savedIos]);

    useListenable(uiCtrl);
    useListenable(androidCtrl);
    useListenable(iosCtrl);

    final isDirty =
        uiCtrl.text != savedUi ||
        androidCtrl.text != savedAndroid ||
        iosCtrl.text != savedIos;

    final message = ref.read(snackBarMessageProvider.notifier);

    Future<void> handleSave() async {
      final result = await setVersions(
        ref.read(firestoreProvider),
        uiVersion: uiCtrl.text.trim(),
        androidVersion: androidCtrl.text.trim(),
        iosVersion: iosCtrl.text.trim(),
      );
      result.match(
        (error) => message.show('バージョンの更新に失敗しました: $error'),
        (_) => message.show('バージョンを更新しました'),
      );
    }

    void handleCancel() {
      uiCtrl.text = savedUi;
      androidCtrl.text = savedAndroid;
      iosCtrl.text = savedIos;
    }

    return SliverToBoxAdapter(
      child: Padding(
        padding: panelPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: panelSpacing,
          children: [
            Text('UIバージョン', style: panelTitleStyle(context)),
            Wrap(
              spacing: panelSpacing,
              runSpacing: panelSpacing,
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: inputWidth),
                  child: TextField(
                    controller: uiCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Web',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: inputWidth),
                  child: TextField(
                    controller: androidCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Android',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: inputWidth),
                  child: TextField(
                    controller: iosCtrl,
                    decoration: const InputDecoration(
                      labelText: 'iOS',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            Row(
              spacing: 16,
              children: [
                OutlinedButton(
                  onPressed: isDirty ? handleCancel : null,
                  child: const Text('キャンセル'),
                ),
                FilledButton(
                  onPressed: isDirty ? handleSave : null,
                  child: const Text('保存'),
                ),
              ],
            ),
            const Divider(),
          ],
        ),
      ),
    );
  }
}
