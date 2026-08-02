import 'package:flutter/material.dart';

import 'package:robanokyuka/config/theme.dart';
import 'package:robanokyuka/services/validators.dart';

class TimeInput extends StatelessWidget {
  const TimeInput({
    super.key,
    required this.labelText,
    this.helperText = 'H:MM',
    required this.timeController,
    this.disabled = false,
    this.extraValidator,
  });

  final String labelText;
  final String helperText;
  final TextEditingController timeController;

  /// Called after built-in time validation passes. Receives the validated
  /// [TimeOfDay] and should return an error string or null.
  final bool disabled;
  final String? Function(TimeOfDay time)? extraValidator;

  TimeOfDay? _parse(String value) {
    final parts = value.trim().split(':');
    if (parts.length != 2) return null;
    final hh = int.tryParse(parts[0]);
    final mm = int.tryParse(parts[1]);
    if (hh == null || mm == null) return null;
    if (hh < 0 || hh > 47) return null;
    if (mm < 0 || mm > 59) return null;
    return TimeOfDay(hour: hh, minute: mm);
  }

  Future<void> _pickTime(BuildContext context) async {
    final current = _parse(timeController.text);
    final initial = current ?? TimeOfDay.now();

    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );

    if (picked != null) {
      timeController.text =
          '${picked.hour}:${picked.minute.toString().padLeft(2, '0')}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaSize = MediaQuery.sizeOf(context);
    final narrow = mediaSize.width < narrowDeviceWidth;

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: narrow ? 96 : 128),
      child: TextFormField(
        controller: timeController,
        enabled: !disabled,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: labelText,
          border: const OutlineInputBorder(),
          helperText: helperText,
          suffixIcon: narrow || disabled
              ? null
              : IconButton(
                  icon: const Icon(Icons.access_time),
                  onPressed: () => _pickTime(context),
                ),
        ),
        readOnly: narrow,
        onTap: narrow && !disabled ? () => _pickTime(context) : null,
        validator: (value) {
          final error = validateHhmmOptional(value);
          if (error != null) return error;
          if (extraValidator != null) {
            final time = _parse(value ?? '');
            if (time != null) return extraValidator!(time);
          }
          return null;
        },
      ),
    );
  }
}
