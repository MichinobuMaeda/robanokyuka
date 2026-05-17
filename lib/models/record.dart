import 'package:flutter/widgets.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fpdart/fpdart.dart';

import 'package:robanokyuka/config/firebase.dart';
import 'package:robanokyuka/models/cal_date.dart';
import 'package:robanokyuka/services/authentication.dart';

int parseTime(String hhmm) {
  final parts = hhmm.split(':');
  if (parts.length != 2) throw FormatException('Invalid time format');
  final hours = int.tryParse(parts[0]) ?? 0;
  final minutes = int.tryParse(parts[1]) ?? 0;
  return hours * 3600 + minutes * 60;
}

String formatTime(int seconds, {bool short = false}) {
  final hours = seconds ~/ 3600;
  final minutes = (seconds % 3600) ~/ 60;
  return '${short ? hours : hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
}

String formatTimeShort(int seconds) {
  return formatTime(seconds, short: true);
}

class WorkTime {
  static const allString = 'all';

  WorkTime(this.seconds, [this.all = false]);

  final int seconds;
  final bool all;

  factory WorkTime.parse(String? value) {
    final str = value?.trim().toLowerCase();
    if (str == null || str.isEmpty) return WorkTime(0, false);
    if (str == allString) return WorkTime(0, true);

    final parts = str.split(':');
    if (parts.length != 2) return WorkTime(0, false);
    final hours = int.tryParse(parts[0]) ?? 0;
    final minutes = int.tryParse(parts[1]) ?? 0;
    return WorkTime(hours * 3600 + minutes * 60, false);
  }

  String? toRecord() {
    if (all) return allString;
    if (seconds == 0) return null;
    return formatTime(seconds);
  }

  @override
  String toString() => toRecord() ?? '';

  @override
  bool operator ==(Object other) {
    return other is WorkTime && seconds == other.seconds && all == other.all;
  }

  @override
  int get hashCode => Object.hash(seconds, all);
}

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
final defaultWorkingHours = 3600 * 8;

class DateRecord {
  final Cal date;
  final bool companyHoliday;
  final WorkTime plan;
  final WorkTime used;
  final WorkTime sick;
  final WorkTime other;
  final String? note;

  DateRecord(
    this.date,
    this.companyHoliday,
    this.note, {
    required this.plan,
    required this.used,
    required this.sick,
    required this.other,
  });
}

class Record implements Comparable<Record> {
  final String id;
  final Cal from;
  final Cal to;
  final List<bool> publicHolidays;
  final int givenLeaves;
  final int minLeaves;
  final bool useLeavesHourly;
  final int workingHours;
  final List<DateRecord> dates;

  Record({
    required this.id,
    required this.from,
    required this.to,
    this.publicHolidays = defaultPublicHolidays,
    this.givenLeaves = defaultGivenLeaves,
    this.minLeaves = defaultMinLeaves,
    this.useLeavesHourly = false,
    int? stdSeconds,
    this.dates = const [],
  }) : workingHours = stdSeconds ?? defaultWorkingHours;

  factory Record.fromDocument(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    final whString = (data['workingHours'] as String?);
    final workingHours = whString != null
        ? parseTime(whString)
        : defaultWorkingHours;
    return Record(
      id: doc.id,
      from: Cal.fromString(data['from'] as String),
      to: Cal.fromString(data['to'] as String),
      publicHolidays: List<bool>.from(
        data['holidays'] ?? defaultPublicHolidays,
      ),
      givenLeaves: data['givenLeaves'] ?? defaultGivenLeaves,
      minLeaves: data['minLeaves'] ?? defaultMinLeaves,
      useLeavesHourly: data['useLeavesHourly'] ?? false,
      stdSeconds: workingHours,
      dates: () {
        return (data['dates'] as Map<String, dynamic>?)?.entries
                .map(
                  (entry) => DateRecord(
                    Cal.fromString(entry.key),
                    entry.value['c'] ?? false,
                    entry.value['n'] as String?,
                    plan: WorkTime.parse(entry.value['p'] as String?),
                    used: WorkTime.parse(entry.value['u'] as String?),
                    sick: WorkTime.parse(entry.value['s'] as String?),
                    other: WorkTime.parse(entry.value['o'] as String?),
                  ),
                )
                .toList() ??
            [];
      }(),
    );
  }

  List<(int, int)>? get months {
    final months = <(int, int)>[];
    var year = from.year;
    var month = from.month;
    while (year < to.year || (year == to.year && month <= to.month)) {
      months.add((year, month));
      month++;
      if (month > 12) {
        month = 1;
        year++;
      }
    }
    return months;
  }

  factory Record.next(List<Record> records) {
    final Cal from;
    final Cal to;

    if (records.isEmpty) {
      final year = DateTime.now().year;
      from = Cal(year, 4, 1);
      to = Cal(year + 1, 3, 31);
    } else {
      // find the record with the latest `to` date
      final maxTo = records
          .map((r) => r.to)
          .reduce((a, b) => a.compareTo(b) >= 0 ? a : b)
          .dateTime;
      from = Cal.fromDateTime(maxTo.add(const Duration(days: 1)));
      to = Cal(maxTo.year + 1, maxTo.month, maxTo.day);
    }

    return Record(
      id: '',
      from: from,
      to: to,
      publicHolidays: List<bool>.from(defaultPublicHolidays),
      givenLeaves: defaultGivenLeaves,
      minLeaves: defaultMinLeaves,
      useLeavesHourly: false,
      stdSeconds: defaultWorkingHours,
    );
  }

  bool isHolidayWeekDay(Cal date) => publicHolidays[date.dateTime.weekday % 7];

  @visibleForTesting
  String summary(List<WorkTime> wt) {
    final seconds = wt.fold<int>(
      0,
      (v, w) => v + (w.all ? workingHours : w.seconds),
    );
    final days = workingHours > 0 ? seconds ~/ workingHours : 0;
    final remaining = workingHours > 0 ? seconds % workingHours : seconds;
    final hours = remaining ~/ 3600;
    final minutes = (remaining % 3600) ~/ 60;
    return remaining == 0
        ? '$days'
        : '$days($hours:${minutes.toString().padLeft(2, '0')})';
  }

  String get plannedLeaves => summary(dates.map((d) => d.plan).toList());
  String get usedLeaves => summary(dates.map((d) => d.used).toList());
  String get sickLeaves => summary(dates.map((d) => d.sick).toList());
  String get otherLeaves => summary(dates.map((d) => d.other).toList());

  @override
  int compareTo(Record other) => from.compareTo(other.from);
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
                    ..sort(),
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
      state = applyRecordsChange(next.asData?.value, state);
    });
    return null;
  }

  @visibleForTesting
  void set(int? index) => state = index;

  void goPrevious() {
    debugPrint('SelectedRecordIndexNotifier: goPrevious called');
    final records = ref.read(recordsProvider).asData?.value;
    if (records == null || records.isEmpty) return;
    final current = state;
    if (current == null) {
      state = 0;
    } else if (current > 0) {
      state = current - 1;
    }
  }

  void goNext() {
    debugPrint('SelectedRecordIndexNotifier: goNext called');
    final records = ref.read(recordsProvider).asData?.value;
    if (records == null || records.isEmpty) return;
    final current = state;
    if (current == null) {
      state = 0;
    } else if (current < records.length - 1) {
      state = current + 1;
    }
  }

  @visibleForTesting
  int? applyRecordsChange(List<Record>? records, int? current) {
    debugPrint(
      'SelectedRecordIndexNotifier: applyRecordsChange records: ${records?.length}, current: $current',
    );
    if (records == null || records.isEmpty) {
      return null;
    }
    if (current == null) {
      final today = Cal.fromDateTime(DateTime.now());
      int index = 0;
      for (int i = 0; i < records.length; i++) {
        final record = records[i];
        if (record.from.compareTo(today) > 0) break;
        index = i;
      }
      return index;
    } else if (current < 0 || current >= records.length) {
      return records.length - 1;
    }
    return current;
  }
}

Future<Either<String, Unit>> saveRecord(
  FirebaseFirestore db,
  String uid,
  Record record,
) async {
  try {
    final userRef = db.collection('users').doc(uid);
    final data = {
      'from': record.from.yyyymmdd,
      'to': record.to.yyyymmdd,
      'holidays': record.publicHolidays,
      'givenLeaves': record.givenLeaves,
      'minLeaves': record.minLeaves,
      'useLeavesHourly': record.useLeavesHourly,
      'workingHours': formatTime(record.workingHours),
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
    final key = dateRecord.date.yyyymmdd;
    await db
        .collection('users')
        .doc(uid)
        .collection('records')
        .doc(recordId)
        .update({
          'dates.$key': {
            'c': dateRecord.companyHoliday,
            'p': dateRecord.plan.toRecord(),
            'u': dateRecord.used.toRecord(),
            's': dateRecord.sick.toRecord(),
            'o': dateRecord.other.toRecord(),
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
