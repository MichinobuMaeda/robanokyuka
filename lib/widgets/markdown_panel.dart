import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:url_launcher/url_launcher.dart';

import 'package:robanokyuka/config/theme.dart';
import 'package:robanokyuka/widgets/box_panel.dart';

const loadingIndicatorSize = 48.0;

final markdownStyle = MarkdownStyleSheet(
  p: TextStyle(fontFamily: defaultFont),
  h1: TextStyle(fontFamily: defaultFont, fontSize: 32),
  h2: TextStyle(fontFamily: defaultFont, fontSize: 28),
  h3: TextStyle(fontFamily: defaultFont, fontSize: 24),
  h4: TextStyle(fontFamily: defaultFont, fontSize: 20),
  h5: TextStyle(fontFamily: defaultFont, fontSize: 18),
  h6: TextStyle(
    fontFamily: defaultFont,
    fontSize: 16,
    decoration: TextDecoration.underline,
  ),
);

// autoLink を無効にする。
final markdownExtensionSetWithoutAutolink = md.ExtensionSet(
  md.ExtensionSet.gitHubFlavored.blockSyntaxes,
  md.ExtensionSet.gitHubFlavored.inlineSyntaxes
      .where((syntax) => syntax is! md.AutolinkExtensionSyntax)
      .toList(growable: false),
);

class MarkdownPanel extends HookConsumerWidget {
  const MarkdownPanel({
    super.key,
    required this.asset,
    this.showDivider = true,
  });

  final String asset;
  final bool showDivider;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final source = useFuture(
      useMemoized(() => rootBundle.loadString(asset), [asset]),
    );

    final errorTextStyle = TextStyle(
      color: Theme.of(context).colorScheme.error,
    );

    return BoxPanel(
      showDivider: showDivider,
      children: [
        switch (source.connectionState) {
          ConnectionState.done when source.hasData => MarkdownBody(
            styleSheet: markdownStyle,
            selectable: true,
            extensionSet: markdownExtensionSetWithoutAutolink,
            onTapLink: (text, href, title) {
              if (href != null) {
                launchUrl(
                  Uri.parse(href),
                  mode: LaunchMode.externalApplication,
                );
              }
            },
            data: source.data!,
          ),
          ConnectionState.done => Flex(
            direction: Axis.vertical,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                (source.error ?? 'Unknown error').toString(),
                style: errorTextStyle,
              ),
              if (source.stackTrace != null)
                Text(source.stackTrace.toString(), style: errorTextStyle),
            ],
          ),
          _ => const Center(
            child: CircularProgressIndicator(
              constraints: BoxConstraints(
                maxHeight: loadingIndicatorSize,
                maxWidth: loadingIndicatorSize,
              ),
              // ignore: deprecated_member_use
              year2023: true,
            ),
          ),
        },
      ],
    );
  }
}
