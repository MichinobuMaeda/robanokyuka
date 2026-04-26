import 'package:flutter/widgets.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fpdart/fpdart.dart';

import '../config/firebase.dart';
import '../services/authentication.dart';
import '../services/helpers.dart';
import '../models/service.dart';

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

const defaultGivenLeaves = 10;
const defaultMinLeaves = 5;
const defaultWorkingHours = '08:00';

class DateRecord {
  final String date;
  final bool companyHoliday;
  final String? plan;
  final String? used;
  final String? sick;
  final String? other;
  final String? note;

  DateRecord({
    required this.date,
    this.companyHoliday = false,
    this.plan,
    this.used,
    this.sick,
    this.other,
    this.note,
  });
}

class Record {
  final String id;
  final String from;
  final String to;
  final List<bool> publicHolidays;
  final int givenLeaves;
  final int minLeaves;
  final bool useLeavesHourly;
  final String workingHours;
  final List<DateRecord> dates;

  Record({
    required this.id,
    required this.from,
    required this.to,
    this.publicHolidays = defaultPublicHolidays,
    this.givenLeaves = defaultGivenLeaves,
    this.minLeaves = defaultMinLeaves,
    this.useLeavesHourly = false,
    this.workingHours = defaultWorkingHours,
    this.dates = const [],
  });

  factory Record.fromDocument(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Record(
      id: doc.id,
      from: data['from'] as String,
      to: data['to'] as String,
      publicHolidays: List<bool>.from(
        data['holidays'] ?? defaultPublicHolidays,
      ),
      givenLeaves: data['givenLeaves'] ?? defaultGivenLeaves,
      minLeaves: data['minLeaves'] ?? defaultMinLeaves,
      useLeavesHourly: data['useLeavesHourly'] ?? false,
      workingHours: (data['workingHours'] as String?) ?? defaultWorkingHours,
      dates:
          (data['dates'] as Map<String, dynamic>?)?.entries
              .map(
                (entry) => DateRecord(
                  date: entry.key,
                  companyHoliday: entry.value['c'] ?? false,
                  plan: entry.value['p'],
                  used: entry.value['u'],
                  sick: entry.value['s'],
                  other: entry.value['o'],
                  note: entry.value['n'],
                ),
              )
              .toList() ??
          [],
    );
  }
}

Stream<List<Record>?> recordsStream(Ref ref) {
  final uid = ref.watch(
    authUserProvider.select((authUser) => authUser.asData?.value?.uid),
  );
  final userRef = ref.watch(firestoreProvider).collection('users').doc(uid);
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
                    ..sort((a, b) => a.from.compareTo(b.from)),
            );
}

final recordsProvider = StreamProvider<List<Record>?>(recordsStream);

final selectedRecordIndexProvider =
    NotifierProvider<SelectedRecordIndexNotifier, int?>(
      SelectedRecordIndexNotifier.new,
    );

class SelectedRecordIndexNotifier extends Notifier<int?> {
  @override
  int? build() {
    ref.listen(recordsProvider, (previous, next) {
      applyRecordsChange(next.asData?.value);
    });

    final records = ref.watch(recordsProvider).asData?.value;
    if (records == null || records.isEmpty) return null;
    final now = DateTime.now();
    final todayStr = formatYmd(now.year, now.month, now.day);
    int index = 0;
    for (int i = 0; i < records.length; i++) {
      final record = records[i];
      if (record.from.compareTo(todayStr) > 0) break;
      index = i;
    }
    return index;
  }

  void set(int? index) {
    state = index;
  }

  @visibleForTesting
  void applyRecordsChange(List<Record>? records) {
    if (records == null || records.isEmpty) {
      state = null;
      return;
    }
    final current = state;
    if (current == null || current < 0 || current >= records.length) {
      state = records.length - 1;
    }
  }
}

Record getDefaultRecord(List<Record> records) {
  final String from;
  final String to;

  if (records.isEmpty) {
    final now = DateTime.now();
    from = '${now.year}0401';
    to = '${now.year + 1}0331';
  } else {
    // find the record with the latest `to` date
    final maxTo = records
        .map((r) => r.to)
        .reduce((a, b) => a.compareTo(b) >= 0 ? a : b);
    final maxToDate = parseYmd(maxTo);
    final next = maxToDate.add(const Duration(days: 1));
    final oneYearLater = DateTime(
      maxToDate.year + 1,
      maxToDate.month,
      maxToDate.day,
    );
    from = formatYmd(next.year, next.month, next.day);
    to = formatYmd(oneYearLater.year, oneYearLater.month, oneYearLater.day);
  }

  return Record(
    id: '',
    from: from,
    to: to,
    publicHolidays: List<bool>.from(defaultPublicHolidays),
    givenLeaves: defaultGivenLeaves,
    minLeaves: defaultMinLeaves,
    useLeavesHourly: false,
    workingHours: defaultWorkingHours,
  );
}

Future<Either<String, Unit>> saveRecord(
  FirebaseFirestore db,
  String uid,
  Record record,
) async {
  try {
    final userRef = db.collection('users').doc(uid);
    final data = {
      'from': record.from,
      'to': record.to,
      'holidays': record.publicHolidays,
      'givenLeaves': record.givenLeaves,
      'minLeaves': record.minLeaves,
      'useLeavesHourly': record.useLeavesHourly,
      'workingHours': padHhmm(record.workingHours),
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
    debugPrint('Error adding record: $error\n$stackTrace');
    return left('$error');
  }
}

Future<Either<String, Unit>> saveDateRecord(
  FirebaseFirestore db,
  String uid,
  String recordId,
  DateRecord dateRecord,
) async {
  try {
    final key = dateRecord.date;
    await db
        .collection('users')
        .doc(uid)
        .collection('records')
        .doc(recordId)
        .update({
          'dates.$key': {
            'c': dateRecord.companyHoliday,
            'p': dateRecord.plan,
            'u': dateRecord.used,
            's': dateRecord.sick,
            'o': dateRecord.other,
            'n': dateRecord.note,
          },
          'updatedAt': FieldValue.serverTimestamp(),
        });
    return right(unit);
  } catch (error, stackTrace) {
    debugPrint('Error saving date record: $error\n$stackTrace');
    return left('$error');
  }
}

bool isHolyday(Record record, List<Holiday> holidays, String date) {
  return record.publicHolidays[parseYmd(date).weekday % 7] ||
      (record.publicHolidays[7] &&
          holidays.any((holiday) => holiday.date == date)) ||
      record.dates.any((item) => item.date == date && item.companyHoliday);
}
