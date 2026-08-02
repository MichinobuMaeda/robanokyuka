import 'package:flutter/widgets.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:fpdart/fpdart.dart';

import 'package:robanokyuka/models/cal.dart';
import 'package:robanokyuka/models/service.dart';

class Holiday {
  Holiday(this.date, this.name);

  final Cal date;
  final String name;

  Holiday copyWith({Cal? date, String? name}) {
    return Holiday(date ?? this.date, name ?? this.name);
  }
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
                        Cal(
                          year,
                          int.parse(entry.key.substring(0, 2)),
                          int.parse(entry.key.substring(2, 4)),
                        ),
                        '${entry.value}',
                      );
                    })
                    .toList();
              })
              .expand((holidays) => holidays)
              .toList()
    ..sort((a, b) => a.date.dateTime.compareTo(b.date.dateTime));
});

Future<Either<String, Unit>> setHoliday(
  FirebaseFirestore db,
  Holiday holiday,
) async {
  try {
    await db.collection('service').doc('y${holiday.date.yyyy}').set({
      holiday.date.mmdd: holiday.name,
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
    await db.collection('service').doc('y${holiday.date.yyyy}').update({
      holiday.date.mmdd: FieldValue.delete(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return right(unit);
  } catch (error, stackTrace) {
    debugPrint('Error deleting holiday: $error\n$stackTrace');
    return left('$error');
  }
}

List<int> selectHolidayYears(List<Holiday> holidays) =>
    holidays.map((h) => int.parse(h.date.yyyy)).toSet().toList()..sort();
