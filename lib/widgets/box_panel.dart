import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:robanokyuka/config/theme.dart';

class BoxPanel extends HookConsumerWidget {
  const BoxPanel({super.key, required this.children, this.showDivider = true});

  final List<Widget> children;
  final bool showDivider;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: panelPadding,
        child: Flex(
          direction: Axis.vertical,
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: panelSpacing,
          children: [...children, if (showDivider) Divider()],
        ),
      ),
    );
  }
}
