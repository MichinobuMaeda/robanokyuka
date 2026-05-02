import '../config/theme.dart';

String pad2(int n) => n.toString().padLeft(2, '0');

class Cal implements Comparable<Cal> {
  final int year;
  final int month;
  final int day;

  Cal(this.year, this.month, this.day);

  @override
  int compareTo(Cal other) {
    if (year != other.year) return year.compareTo(other.year);
    if (month != other.month) return month.compareTo(other.month);
    return day.compareTo(other.day);
  }

  @override
  bool operator ==(Object other) =>
      other is Cal &&
      year == other.year &&
      month == other.month &&
      day == other.day;

  @override
  int get hashCode => Object.hash(year, month, day);

  String get yyyymmdd => '$year${pad2(month)}${pad2(day)}';

  factory Cal.fromYyyymmdd(String date) => Cal(
    int.parse(date.substring(0, 4)),
    int.parse(date.substring(4, 6)),
    int.parse(date.substring(6, 8)),
  );

  DateTime get dateTime => DateTime(year, month, day);

  factory Cal.fromDateTime(DateTime dt) => Cal(dt.year, dt.month, dt.day);

  String get weekDayLabel => weekdayLabels[dateTime.weekday % 7];
}
