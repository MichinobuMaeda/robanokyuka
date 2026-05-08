import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:robanokyuka/services/validators.dart';

class PasswordFormField extends HookWidget {
  const PasswordFormField({
    super.key,
    required this.controller,
    required this.labelText,
    required this.helperText,
    this.validator,
  });

  final TextEditingController controller;
  final String labelText;
  final String helperText;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    final isVisible = useState(false);

    return TextFormField(
      controller: controller,
      obscureText: !isVisible.value,
      validator: validator ?? (value) => validateRequired(value),
      decoration: InputDecoration(
        labelText: labelText,
        helperText: helperText,
        border: const OutlineInputBorder(),
        suffixIcon: IconButton(
          icon: Icon(
            isVisible.value ? Symbols.visibility_off : Symbols.visibility,
          ),
          onPressed: () {
            isVisible.value = !isVisible.value;
          },
        ),
      ),
    );
  }
}
