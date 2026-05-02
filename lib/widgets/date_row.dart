import 'package:flutter/material.dart';

import '../models/nengo.dart';
import '../services/validators.dart';

class DateRow extends StatelessWidget {
  const DateRow({
    super.key,
    required this.yearController,
    required this.monthController,
    required this.dayController,
    required this.nengo,
    this.extraDayValidator,
  });

  final TextEditingController yearController;
  final TextEditingController monthController;
  final TextEditingController dayController;
  final Nengo nengo;

  /// Called after built-in day validation passes. Receives the resolved
  /// (year, month, day) integers and should return an error string or null.
  final String? Function(int year, int month, int day)? extraDayValidator;

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: 8,
      children: [
        SizedBox(
          width: 84,
          child: TextFormField(
            controller: yearController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: '年',
              border: OutlineInputBorder(),
              helperText: '4桁',
            ),
            validator: (value) => validateYear(nengo, value),
          ),
        ),
        SizedBox(
          width: 58,
          child: TextFormField(
            controller: monthController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: '月',
              border: OutlineInputBorder(),
              helperText: '1-12',
            ),
            validator: validateMonth,
          ),
        ),
        SizedBox(
          width: 58,
          child: TextFormField(
            controller: dayController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: '日',
              border: OutlineInputBorder(),
              helperText: '1-31',
            ),
            validator: (value) => validateDay(
              nengo,
              yearController.text,
              monthController.text,
              value,
            ),
          ),
        ),
      ],
    );
  }
}
