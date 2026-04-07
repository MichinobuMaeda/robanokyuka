import 'package:flutter/widgets.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fpdart/fpdart.dart';

import '../services/authentication.dart';
import '../models/holidays.dart';

const defaultPublicHolidays = [
  true, // Sunday
  false, // Monday
  false, // Tuesday
  false, // Wednesday
  false, // Thursday
  false, // Friday
  true, // Saturday
  true, // Holiday
];

class CalendarDate {
  final int year;
  final int month;
  final int day;

  CalendarDate({required this.year, required this.month, required this.day});
}

class Record {
  final String id;
  final CalendarDate from;
  final CalendarDate to;
  final List<bool> publicHolidays;
  final List<CalendarDate> companyHolidays;
  final List<CalendarDate> plannedLeaves;
  final List<CalendarDate> usedLeaves;
  final int givenLeaves;
  final int minLeaves;

  Record({
    required this.id,
    required this.from,
    required this.to,
    this.publicHolidays = defaultPublicHolidays,
    this.companyHolidays = const [],
    this.plannedLeaves = const [],
    this.usedLeaves = const [],
    this.givenLeaves = 10,
    this.minLeaves = 5,
  });

  factory Record.fromDocument(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Record(
      id: doc.id,
      from: CalendarDate(
        year: data['from']['year'],
        month: data['from']['month'],
        day: data['from']['day'],
      ),
      to: CalendarDate(
        year: data['to']['year'],
        month: data['to']['month'],
        day: data['to']['day'],
      ),
      publicHolidays: List<bool>.from(
        data['holidays'] ?? defaultPublicHolidays,
      ),
      companyHolidays: List<CalendarDate>.from(
        data['companyHolidays']?.map(
              (holiday) => CalendarDate(
                year: holiday['year'],
                month: holiday['month'],
                day: holiday['day'],
              ),
            ) ??
            [],
      ),
      plannedLeaves: List<CalendarDate>.from(
        data['plannedLeaves']?.map(
              (d) => CalendarDate(
                year: d['year'],
                month: d['month'],
                day: d['day'],
              ),
            ) ??
            [],
      ),
      usedLeaves: List<CalendarDate>.from(
        data['usedLeaves']?.map(
              (d) => CalendarDate(
                year: d['year'],
                month: d['month'],
                day: d['day'],
              ),
            ) ??
            [],
      ),
      givenLeaves: data['givenLeaves'] ?? 10,
      minLeaves: data['minLeaves'] ?? 5,
    );
  }
}

final recordsProvider = StreamProvider<List<Record>?>((ref) {
  final uid = ref.watch(authUserProvider.select(selectUid));
  final userRef = FirebaseFirestore.instance.collection('users').doc(uid);
  return (uid == null)
      ? Stream.value(null)
      : userRef
            .collection('records')
            .snapshots()
            .map(
              (snapshot) =>
                  snapshot.docs
                      .map((doc) => Record.fromDocument(doc))
                      .toList(growable: true)
                    ..sort((a, b) {
                      final ya = a.from.year.compareTo(b.from.year);
                      if (ya != 0) return ya;
                      final ma = a.from.month.compareTo(b.from.month);
                      if (ma != 0) return ma;
                      return a.from.day.compareTo(b.from.day);
                    }),
            );
});

final selectedRecordIndexProvider =
    NotifierProvider<SelectedRecordIndexNotifier, int?>(
      SelectedRecordIndexNotifier.new,
    );

class SelectedRecordIndexNotifier extends Notifier<int?> {
  @override
  int? build() {
    ref.listen(recordsProvider, (previous, next) {
      final records = next.asData?.value;
      if (records == null || records.isEmpty) {
        state = null;
        return;
      }
      final current = state;
      if (current == null || current < 0 || current >= records.length) {
        state = records.length - 1;
      }
    });

    final records = ref.watch(recordsProvider).asData?.value;
    if (records == null || records.isEmpty) return null;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    int index = 0;
    for (int i = 0; i < records.length; i++) {
      final record = records[i];
      if (record.from.year > today.year) break;
      if (record.from.year == today.year && record.from.month > today.month) {
        break;
      }
      if (record.from.year == today.year &&
          record.from.month == today.month &&
          record.from.day > today.day) {
        break;
      }
      index = i;
    }
    return index;
  }

  void set(int? index) {
    state = index;
  }
}

Record getDefaultRecord(List<Record> records) {
  final CalendarDate from;
  final CalendarDate to;

  if (records.isEmpty) {
    final now = DateTime.now();
    from = CalendarDate(year: now.year, month: 4, day: 1);
    to = CalendarDate(year: now.year + 1, month: 3, day: 31);
  } else {
    // find the record with the latest `to` date
    final maxTo = records.map((r) => r.to).reduce((a, b) {
      final da = DateTime(a.year, a.month, a.day);
      final db = DateTime(b.year, b.month, b.day);
      return da.isAfter(db) ? a : b;
    });
    final maxToDate = DateTime(maxTo.year, maxTo.month, maxTo.day);
    final next = maxToDate.add(const Duration(days: 1));
    final oneYearLater = DateTime(maxTo.year + 1, maxTo.month, maxTo.day);
    from = CalendarDate(year: next.year, month: next.month, day: next.day);
    to = CalendarDate(
      year: oneYearLater.year,
      month: oneYearLater.month,
      day: oneYearLater.day,
    );
  }

  return Record(
    id: '',
    from: from,
    to: to,
    publicHolidays: List<bool>.from(defaultPublicHolidays),
    givenLeaves: 10,
    minLeaves: 5,
  );
}

Future<Either<String, Unit>> saveRecord(String uid, Record record) async {
  try {
    final userRef = FirebaseFirestore.instance.collection('users').doc(uid);
    final data = {
      'from': {
        'year': record.from.year,
        'month': record.from.month,
        'day': record.from.day,
      },
      'to': {
        'year': record.to.year,
        'month': record.to.month,
        'day': record.to.day,
      },
      'holidays': record.publicHolidays,
      'companyHolidays': record.companyHolidays
          .map((d) => {'year': d.year, 'month': d.month, 'day': d.day})
          .toList(),
      'plannedLeaves': record.plannedLeaves
          .map((d) => {'year': d.year, 'month': d.month, 'day': d.day})
          .toList(),
      'usedLeaves': record.usedLeaves
          .map((d) => {'year': d.year, 'month': d.month, 'day': d.day})
          .toList(),
      'givenLeaves': record.givenLeaves,
      'minLeaves': record.minLeaves,
    };
    final recordsRef = userRef.collection('records');
    if (record.id.isEmpty) {
      await recordsRef.add({
        ...data,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } else {
      await recordsRef.doc(record.id).update({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    return right(unit);
  } catch (error, stackTrace) {
    debugPrintStack(
      label: 'Error adding record: $error',
      stackTrace: stackTrace,
    );
    return left('$error');
  }
}

bool isHolyday(Record record, List<Holiday> holidays, CalendarDate date) {
  DateTime dt = DateTime(date.year, date.month, date.day);
  return record.publicHolidays[dt.weekday % 7] ||
      (record.publicHolidays[7] &&
          holidays.any(
            (holiday) =>
                holiday.year == date.year &&
                holiday.month == date.month &&
                holiday.day == date.day,
          )) ||
      record.companyHolidays.any(
        (d) =>
            d.year == date.year && d.month == date.month && d.day == date.day,
      );
}

Future<Either<String, Unit>> toggleDayInList(
  String uid,
  String recordId,
  String field,
  CalendarDate day,
  bool currentValue,
) async {
  try {
    final dayMap = {'year': day.year, 'month': day.month, 'day': day.day};
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('records')
        .doc(recordId)
        .update({
          field: currentValue
              ? FieldValue.arrayRemove([dayMap])
              : FieldValue.arrayUnion([dayMap]),
        });
    return right(unit);
  } catch (error, stackTrace) {
    debugPrintStack(
      label: 'Error toggling day: $error',
      stackTrace: stackTrace,
    );
    return left('$error');
  }
}
