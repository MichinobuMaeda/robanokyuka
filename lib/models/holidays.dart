import 'package:flutter/widgets.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:fpdart/fpdart.dart';

import 'package:robanokyuka/models/cal_date.dart';
import 'package:robanokyuka/models/service.dart';

class Holiday implements Comparable<Holiday> {
  final Cal date;
  final String name;

  Holiday({required this.date, required this.name});

  factory Holiday.fromString(String date, {required String name}) {
    return Holiday(date: Cal.fromString(date), name: name);
  }

  Holiday copyWith({Cal? date, String? name}) {
    return Holiday(date: date ?? this.date, name: name ?? this.name);
  }

  @override
  int compareTo(Holiday other) => date.compareTo(other.date);

  String get yyyymmdd => date.yyyymmdd;
  String get yyyy => date.yyyymmdd.substring(0, 4);
  String get mmdd => date.yyyymmdd.substring(4);
}

final holidaysProvider = Provider<List<Holiday>>((ref) {
  final service = ref.watch(serviceProvider);
  return (service.hasError || service.value == null)
        ? []
        : service.value!.docs
              .where((doc) => RegExp(r'^y[0-9]{4}$').hasMatch(doc.id))
              .map((doc) {
                final year = int.parse(doc.id.substring(1, 5));
                final holidays = doc.data();
                return holidays.entries
                    .where((entry) => RegExp(r'^[0-9]{4}$').hasMatch(entry.key))
                    .map((entry) {
                      return Holiday(
                        date: Cal(
                          year,
                          int.parse(entry.key.substring(0, 2)),
                          int.parse(entry.key.substring(2, 4)),
                        ),
                        name: '${entry.value}',
                      );
                    })
                    .toList();
              })
              .expand((holidays) => holidays)
              .toList()
    ..sort();
});

Future<Either<String, Unit>> setHoliday(
  FirebaseFirestore db,
  Holiday holiday,
) async {
  try {
    await db.collection('service').doc('y${holiday.yyyy}').set({
      holiday.mmdd: holiday.name,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    return right(unit);
  } catch (error, stackTrace) {
    debugPrint('Error setting holiday: $error\n$stackTrace');
    return left('$error');
  }
}

Future<Either<String, Unit>> deleteHoliday(
  FirebaseFirestore db,
  Holiday holiday,
) async {
  try {
    await db.collection('service').doc('y${holiday.yyyy}').update({
      holiday.mmdd: FieldValue.delete(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return right(unit);
  } catch (error, stackTrace) {
    debugPrint('Error deleting holiday: $error\n$stackTrace');
    return left('$error');
  }
}

List<int> selectHolidayYears(List<Holiday> holidays) =>
    holidays.map((h) => int.parse(h.yyyy)).toSet().toList()..sort();
