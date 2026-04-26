import 'package:flutter/material.dart';

class BorderedListItem extends StatelessWidget {
  const BorderedListItem({
    super.key,
    this.height = 48.0,
    this.border = false,
    required this.child,
  });

  final bool border;
  final double height;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ColoredBox(
        color: border
            ? Theme.of(context).colorScheme.surfaceContainerLow.withAlpha(168)
            : Theme.of(context).colorScheme.surfaceContainerLowest,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: child,
        ),
      ),
    );
  }
}
