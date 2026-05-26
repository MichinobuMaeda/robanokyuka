import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:robanokyuka/config/version.dart';
import 'package:robanokyuka/platform/platforms.dart';
import 'package:robanokyuka/models/service.dart';
import 'package:robanokyuka/services/helpers.dart';

class UpdateAvailablePanel extends HookConsumerWidget {
  const UpdateAvailablePanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uiVersion = ref.watch(
      confProvider.select(
        (Conf? conf) => switch (getAppEnvironment()) {
          AppEnvironment.android => conf?.androidVersion,
          AppEnvironment.ios => conf?.iosVersion,
          _ => conf?.uiVersion,
        },
      ),
    );

    if (!isUpdateAvailable(packageVersion, uiVersion)) {
      return SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.all(4.0),
        child: FilledButton(
          onPressed: updateApp,
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.errorContainer,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            spacing: 4.0,
            children: [
              Icon(
                Symbols.sync,
                color: Theme.of(context).colorScheme.onErrorContainer,
              ),
              Text(
                'アプリをアップデートしてください',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onErrorContainer,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
