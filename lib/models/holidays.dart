import 'package:flutter/widgets.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'dart:async';

import '../services/authorization.dart';

final holidaysRef = FirebaseFirestore.instance.collection('holidays');

class Holiday implements Comparable<Holiday> {
  final int year;
  final int month;
  final int day;
  final String name;

  Holiday({
    required this.year,
    required this.month,
    required this.day,
    required this.name,
  });

  factory Holiday.fromDocument(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Holiday(
      year: int.parse(doc.id.substring(0, 4)),
      month: int.parse(doc.id.substring(4, 6)),
      day: int.parse(doc.id.substring(6, 8)),
      name: "${data['name'] ?? ''}",
    );
  }

  @override
  int compareTo(Holiday other) {
    final yearComparison = year.compareTo(other.year);
    if (yearComparison != 0) {
      return yearComparison;
    }

    final monthComparison = month.compareTo(other.month);
    if (monthComparison != 0) {
      return monthComparison;
    }

    return day.compareTo(other.day);
  }
}

final holidaysProvider = StreamProvider<List<Holiday>>((ref) {
  return switch (ref.watch(privilegeProvider)) {
    Privilege.loading => Stream.value([]),
    Privilege.guest => Stream.value([]),
    _ => holidaysRef.snapshots().map(
      (snapshot) => snapshot.docs.map(Holiday.fromDocument).toList()..sort(),
    ),
  };
});

String _holidayId(int year, int month, int day) {
  return '$year${month.toString().padLeft(2, '0')}${day.toString().padLeft(2, '0')}';
}

Future<Either<String, Unit>> setHoliday(Holiday holiday) async {
  try {
    final id = _holidayId(holiday.year, holiday.month, holiday.day);
    await holidaysRef.doc(id).set({'name': holiday.name});
    return right(unit);
  } catch (error, stackTrace) {
    debugPrintStack(
      label: 'Error setting holiday: $error',
      stackTrace: stackTrace,
    );
    return left('$error');
  }
}

Future<Either<String, Unit>> deleteHoliday(Holiday holiday) async {
  try {
    final id = _holidayId(holiday.year, holiday.month, holiday.day);
    await holidaysRef.doc(id).delete();
    return right(unit);
  } catch (error, stackTrace) {
    debugPrintStack(
      label: 'Error deleting holiday: $error',
      stackTrace: stackTrace,
    );
    return left('$error');
  }
}
