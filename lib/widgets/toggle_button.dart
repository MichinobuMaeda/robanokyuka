import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

class ToggleButton extends StatelessWidget {
  const ToggleButton({
    super.key,
    this.icon,
    this.iconActive,
    required this.label,
    required this.active,
    required this.onPressed,
    this.width,
    this.alignment,
  });

  final Widget? icon;
  final Widget? iconActive;
  final String? label;
  final bool active;
  final VoidCallback? onPressed;
  final double? width;
  final AlignmentGeometry? alignment;

  @override
  Widget build(BuildContext context) {
    final bgColor = active
        ? Theme.of(context).colorScheme.secondary
        : Theme.of(context).colorScheme.secondaryContainer;
    final fgColor = active
        ? Theme.of(context).colorScheme.onSecondary
        : Theme.of(context).colorScheme.onSecondaryContainer;

    final style = FilledButton.styleFrom(
      backgroundColor: bgColor,
      foregroundColor: fgColor,
      alignment: alignment,
      shape: active
          ? const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            )
          : null,
    );

    final icon = active ? (iconActive ?? this.icon) : this.icon;
    final button = label != null && icon != null
        ? FilledButton.icon(
            onPressed: onPressed,
            icon: icon,
            label: Text(label!),
            style: style,
          )
        : label != null
        ? FilledButton(onPressed: onPressed, style: style, child: Text(label!))
        : FilledButton(
            onPressed: onPressed,
            style: style,
            child: icon ?? const Icon(Symbols.square_rounded),
          );

    if (width != null) {
      return SizedBox(width: width, child: button);
    }
    return button;
  }
}
