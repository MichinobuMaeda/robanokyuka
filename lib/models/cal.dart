import 'package:flutter/material.dart';

import 'package:robanokyuka/config/theme.dart';
import 'package:robanokyuka/services/helpers.dart';

@visibleForTesting
int getValidYear(int year) => (year < 100) ? year + 2000 : year;

class Cal implements Comparable<Cal> {
  late int _year;
  late int _month;
  late int _day;

  int get year => _year;
  int get month => _month;
  int get day => _day;

  Cal(int year, int month, int day) {
    final dt = DateTime(year, month, day);
    _year = getValidYear(dt.year);
    _month = dt.month;
    _day = dt.day;
  }

  @override
  int compareTo(Cal other) {
    if (year != other.year) return year.compareTo(other.year);
    if (month != other.month) return month.compareTo(other.month);
    return day.compareTo(other.day);
  }

  String get yyyy => '$year';
  String get mmdd =>
      '${month.toString().padLeft(2, '0')}${day.toString().padLeft(2, '0')}';
  String get yyyymmdd => '$yyyy$mmdd';

  factory Cal.today() =>
      Cal(DateTime.now().year, DateTime.now().month, DateTime.now().day);

  factory Cal.fromString(String date) {
    final str = toHankaku(date).toUpperCase().trim();
    final now = DateTime.now();
    int year = now.year;
    int month = now.month;
    int day = now.day;

    if (RegExp(r'^\d+$').hasMatch(str)) {
      switch (str.length) {
        case 8:
          year = int.parse(str.substring(0, 4));
          month = int.parse(str.substring(4, 6));
          day = int.parse(str.substring(6, 8));
          break;
        case 6:
          year = int.parse(str.substring(0, 2));
          month = int.parse(str.substring(2, 4));
          day = int.parse(str.substring(4, 6));
          break;
        case 4:
          month = int.parse(str.substring(0, 2));
          day = int.parse(str.substring(2, 4));
          break;
        case 3:
          month = int.parse(str.substring(0, 1));
          day = int.parse(str.substring(1, 3));
          break;
        default:
      }
    } else {
      final ydm = RegExp(r'^(\d+)\D+(\d+)\D+(\d+)').firstMatch(str);
      if (ydm != null) {
        year = int.parse(ydm.group(1)!);
        month = int.parse(ydm.group(2)!);
        day = int.parse(ydm.group(3)!);
      } else {
        final ydm = RegExp(r'^(\d+)\D+(\d+)').firstMatch(str);
        if (ydm != null) {
          month = int.parse(ydm.group(1)!);
          day = int.parse(ydm.group(2)!);
        }
      }
    }

    return Cal(year, month, day);
  }

  DateTime get dateTime => DateTime(year, month, day);

  factory Cal.fromDateTime(DateTime dt) => Cal(dt.year, dt.month, dt.day);

  factory Cal.next(Cal cal) =>
      Cal.fromDateTime(cal.dateTime.add(Duration(days: 1)));

  String get weekDayLabel => weekdayLabels[dateTime.weekday % 7];

  @override
  bool operator ==(Object other) =>
      other is Cal &&
      year == other.year &&
      month == other.month &&
      day == other.day;

  @override
  int get hashCode => Object.hash(year, month, day);
}
