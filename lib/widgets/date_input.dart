import 'package:flutter/material.dart';

import 'package:robanokyuka/config/theme.dart';
import 'package:robanokyuka/models/cal.dart';
import 'package:robanokyuka/models/nengo.dart';
import 'package:robanokyuka/services/validators.dart';

class DateInput extends StatelessWidget {
  const DateInput({
    super.key,
    required this.labelText,
    this.helperText = 'YYYY/M/D',
    required this.dateController,
    required this.nengo,
    this.extraValidator,
  });

  final String labelText;
  final String helperText;
  final TextEditingController dateController;
  final Nengo nengo;

  /// Called after built-in date validation passes. Receives the validated
  /// [Cal] and should return an error string or null.
  final String? Function(Cal date)? extraValidator;

  Future<void> _pickDate(BuildContext context) async {
    final cal = nengo.parseDate(dateController.text);
    final initial = cal != null ? cal.dateTime : DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(DateTime.now().year - 10),
      lastDate: DateTime(DateTime.now().year + 10),
    );

    if (picked != null) {
      dateController.text = nengo.formatShort(
        Cal(picked.year, picked.month, picked.day),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaSize = MediaQuery.sizeOf(context);
    final narrow = mediaSize.width < narrowDeviceWidth;

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: narrow ? 128 : 160),
      child: TextFormField(
        controller: dateController,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: labelText,
          border: const OutlineInputBorder(),
          helperText: helperText,
          suffixIcon: narrow
              ? null
              : IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () => _pickDate(context),
                ),
        ),
        readOnly: narrow,
        onTap: narrow ? () => _pickDate(context) : null,
        validator: (value) {
          final error = validateDate(nengo, value);
          if (error != null) return error;
          if (extraValidator != null) {
            final cal = nengo.parseDate(value ?? '');
            if (cal != null) return extraValidator!(cal);
          }
          return null;
        },
      ),
    );
  }
}
