import 'package:flutter/material.dart';

// import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fpdart/fpdart.dart';
// import 'package:path/path.dart';

import 'package:robanokyuka/config/firebase.dart';
import 'package:robanokyuka/models/cal.dart';
import 'package:robanokyuka/models/holidays.dart';
import 'package:robanokyuka/services/authentication.dart';
import 'package:robanokyuka/services/helpers.dart';

const defaultHolidays = [
  true, // Sunday
  false, // Monday
  false, // Tuesday
  false, // Wednesday
  false, // Thursday
  false, // Friday
  true, // Saturday
  true, // Public Holidays
];

const defaultGivenLeaves = 10;
const defaultMinLeaves = 5;
ScheduleList getDefauiltSchedule() => ScheduleList.fromMapList([
  {"time": "9:00", "status": "w"},
  {"time": "12:00", "status": "r"},
  {"time": "13:00", "status": "w"},
  {"time": "18:00", "status": "e"},
]);

enum WorkStatus {
  w(label: "勤務", short: "勤"),
  h(label: "休日", short: "休"),
  c(label: "非営", short: "非"),
  p(label: "有休", short: "有"),
  s(label: "病欠", short: "病"),
  o(label: "他休", short: "他"),
  f(label: "休出", short: "出"),
  r(label: "休憩", short: "憩"),
  e(label: "退勤", short: "退");

  const WorkStatus({required this.label, required this.short});

  final String label;
  final String short;

  static WorkStatus? fromString(String? str) =>
      str == null || str.trim().isEmpty
      ? null
      : WorkStatus.values
            .where((e) => e.name == str.trim().substring(0, 1).toLowerCase())
            .singleOrNull;

  static Map<WorkStatus, int> toSumMap() => Map.fromEntries(
    WorkStatus.values
        .where((e) => e != WorkStatus.e)
        .map((e) => MapEntry(e, 0)),
  );
}

int? parseTime(String? str) {
  final match = RegExp(r'^-?(\d+):(\d+)$').firstMatch(str ?? '');
  return (match == null)
      ? null
      : (str!.startsWith('-') ? -1 : 1) *
            (int.tryParse(match.group(1)!)! * 3600 +
                int.tryParse(match.group(2)!)! * 60);
}

String formatTime(int sec, [int? workingSeconds]) =>
    workingSeconds == null || workingSeconds == 0
    ? '${sec < 0 ? '-' : ''}'
          '${(sec.abs() ~/ 3600)}'
          ':${((sec.abs() % 3600) ~/ 60).toString().padLeft(2, '0')}'
    : (sec.abs() % workingSeconds > 0
          ? '${sec < 0 ? '-' : ''}'
                '${(sec.abs() ~/ workingSeconds)} ${((sec.abs() % workingSeconds) ~/ 3600)}'
                ':${((sec.abs() % 3600) ~/ 60).toString().padLeft(2, '0')}'
          : '${sec < 0 ? '-' : ''}'
                '${(sec.abs() ~/ workingSeconds)}');

class ScheduleItem {
  const ScheduleItem(this.time, this.status);

  final int time;
  final WorkStatus status;

  static ScheduleItem? fromMap(dynamic item) =>
      (item is! Map ||
          !item.keys.contains("time") ||
          !item.keys.contains("status"))
      ? null
      : () {
          final time = parseTime(item["time"]);
          final status = WorkStatus.fromString(item["status"]);
          return (time == null || status == null)
              ? null
              : ScheduleItem(time, status);
        }();

  Map<String, String> toMap() =>
      ({"time": formatTime(time).padLeft(5, '0'), "status": status.name});
}

class ScheduleList {
  const ScheduleList([this.sch = const []]);

  final List<ScheduleItem> sch;

  factory ScheduleList.sorted([List<ScheduleItem> sch = const []]) =>
      ScheduleList([...sch]..sort((a, b) => a.time - b.time));

  static ScheduleList fromMapList(dynamic sch) => ScheduleList.sorted(
    (sch is List ? sch : [])
        .map((item) => ScheduleItem.fromMap(item))
        .nonNulls
        .toList(),
  );

  List<Map<String, String>> toMapList() =>
      sch.map((item) => item.toMap()).toList();

  Map<WorkStatus, int> sum() => sch.foldLeftWithIndex(
    WorkStatus.toSumMap(),
    (ret, cur, i) => (i < (sch.length - 1) && cur.status != WorkStatus.e)
        ? {
            ...ret,
            cur.status: (ret[cur.status] ?? 0) + sch[i + 1].time - cur.time,
          }
        : ret,
  );
}

class DateRecord extends ScheduleList {
  DateRecord(this.status, super.sch, [this.note]);

  WorkStatus? status;
  String? note;

  static DateRecord fromMap(Map val) => DateRecord(
    WorkStatus.fromString(val["status"]),
    ScheduleList.fromMapList(val["sch"]).sch,
    val["note"],
  );

  Map<String, dynamic> toMap() => Map.fromEntries([
    MapEntry("status", status?.name),
    MapEntry("sch", toMapList()),
    if (note != null) MapEntry("note", note),
  ]);
}

Map<WorkStatus, int> sumDateRecord(DateRecord dateRecord, int workingSeconds) =>
    [WorkStatus.p, WorkStatus.s, WorkStatus.o].contains(dateRecord.status)
    ? {...WorkStatus.toSumMap(), dateRecord.status!: workingSeconds}
    : dateRecord.sum();

List<bool> mergeBoolList(List<bool> base, dynamic val) => val is List
    ? [...base]
          .mapWithIndex<bool>(
            (item, i) => (i < val.length && val[i] is bool) ? val[i] : item,
          )
          .toList()
    : [...base];

int? getIntValue(dynamic val) => val is int
    ? val
    : (val is double
          ? val.round()
          : (val is String ? double.tryParse(val)?.round() : null));

class Record {
  Record({
    required this.id,
    required this.from,
    required this.to,
    List<bool>? holidays,
    this.givenLeaves = defaultGivenLeaves,
    this.minLeaves = defaultMinLeaves,
    this.useLeavesHourly = false,
    ScheduleList? sch,
    this.dates = const {},
  }) : holidays = mergeBoolList(defaultHolidays, holidays),
       sch = sch ?? getDefauiltSchedule();

  final String id;
  final Cal from;
  final Cal to;
  final List<bool> holidays;
  final int givenLeaves;
  final int minLeaves;
  final bool useLeavesHourly;
  final ScheduleList sch;
  final Map<Cal, DateRecord> dates;

  factory Record.fromDocument(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Record(
      id: doc.id,
      from: Cal.fromString("${data['from']}"),
      to: Cal.fromString("${data['to']}"),
      holidays: mergeBoolList(defaultHolidays, data['holidays']),
      givenLeaves: getIntValue(data['givenLeaves']) ?? defaultGivenLeaves,
      minLeaves: getIntValue(data['minLeaves']) ?? defaultMinLeaves,
      useLeavesHourly: data['useLeavesHourly'] == true,
      sch: data['sch'] is List
          ? ScheduleList.fromMapList(data['sch'])
          : getDefauiltSchedule(),
      dates: Map.fromEntries(
        (data['dates'] is Map
            ? (data['dates'] as Map).entries.map(
                (etntry) => MapEntry(
                  Cal.fromString(etntry.key),
                  DateRecord.fromMap(etntry.value),
                ),
              )
            : []),
      ),
    );
  }

  Map<String, dynamic> toMap() => ({
    "id": id,
    "data": {
      "from": from.yyyymmdd,
      "to": to.yyyymmdd,
      "holidays": mergeBoolList(defaultHolidays, holidays),
      "givenLeaves": givenLeaves,
      "minLeaves": minLeaves,
      "useLeavesHourly": useLeavesHourly,
      "sch": sch.toMapList(),
      "dates": Map.fromEntries(
        dates.entries.map(
          (etntry) => MapEntry(etntry.key.yyyymmdd, etntry.value.toMap()),
        ),
      ),
    },
  });

  factory Record.next(List<Record> records) {
    if (records.isEmpty) {
      final year = DateTime.now().year;
      return Record(id: '', from: Cal(year, 4, 1), to: Cal(year + 1, 3, 31));
    } else {
      records.sort((a, b) => a.to.dateTime.compareTo(b.to.dateTime));
      final last = records.last;
      return Record(
        id: '',
        from: Cal.fromDateTime(last.to.dateTime.add(const Duration(days: 1))),
        to: Cal(last.to.year + 1, last.to.month, last.to.day),
        holidays: last.holidays,
        givenLeaves: last.givenLeaves,
        minLeaves: last.minLeaves,
        useLeavesHourly: last.useLeavesHourly,
        sch: ScheduleList.sorted(last.sch.sch),
      );
    }
  }

  int get workingSeconds => sch.sum()[WorkStatus.w] ?? 0;

  Map<Cal, Map<WorkStatus, int>> sum([Cal? today]) => Map.fromEntries(
    generateMonthList(from, to).map(
      (first) => MapEntry(
        first,
        [
          for (
            Cal date = first;
            date.year == first.year && date.month == first.month;
            date = Cal.next(date)
          )
            date,
        ].fold(
          WorkStatus.toSumMap(),
          (ret, date) =>
              ((today != null && !date.dateTime.isBefore(today.dateTime)) ||
                  dates[date] == null)
              ? ret
              : Map.fromEntries(
                  ret.entries.map(
                    (entry) => MapEntry(
                      entry.key,
                      entry.value +
                          (sumDateRecord(
                                dates[date]!,
                                workingSeconds,
                              )[entry.key] ??
                              0),
                    ),
                  ),
                ),
        ),
      ),
    ),
  );

  bool fill(Cal today, List<Holiday> holidays) {
    bool changed = false;

    for (
      Cal date = Cal.fromDateTime(from.dateTime);
      !date.dateTime.isAfter(to.dateTime);
      date = Cal.next(date)
    ) {
      final status = this.holidays[date.dateTime.weekday % 7]
          ? WorkStatus.h
          : (this.holidays.last &&
                    holidays.where((h) => h.date == date).isNotEmpty
                ? WorkStatus.h
                : WorkStatus.w);
      if (!dates.keys.contains(date)) {
        dates[date] = DateRecord(status, []);
        changed = true;
      } else {
        if (dates[date]!.status != status) {
          if (status == WorkStatus.h) {
            dates[date] = DateRecord(
              status,
              dates[date]!.sch
                  .map(
                    (item) => ScheduleItem(
                      item.time,
                      item.status == WorkStatus.w ? WorkStatus.f : item.status,
                    ),
                  )
                  .toList(),
            );
            changed = true;
          } else if (dates[date]!.status == WorkStatus.h &&
              status == WorkStatus.w) {
            dates[date] = DateRecord(
              status,
              dates[date]!.sch
                  .map(
                    (item) => ScheduleItem(
                      item.time,
                      item.status == WorkStatus.f ? WorkStatus.w : item.status,
                    ),
                  )
                  .toList(),
            );
            changed = true;
          }
        }
      }

      if (date.dateTime.isBefore(today.dateTime)) {
        if (dates[date]!.status == WorkStatus.w && dates[date]!.sch.isEmpty) {
          dates[date] = DateRecord(
            dates[date]!.status,
            [...sch.sch]..sort((a, b) => a.time - b.time),
          );
          changed = true;
        }
      }
    }

    return changed;
  }
}

Stream<List<Record>?> recordsStream(Ref ref) {
  final uid = ref.watch(
    authUserProvider.select((authUser) => authUser.asData?.value?.uid),
  );
  if (uid == null) return Stream.value(null);
  final userRef = ref.watch(firestoreProvider).collection('users').doc(uid);
  return userRef
      .collection('records')
      .snapshots()
      .map(
        (snapshot) =>
            snapshot.docs
                .map((doc) => Record.fromDocument(doc))
                .toList(growable: true)
              ..sort((a, b) => a.from.dateTime.compareTo(b.from.dateTime)),
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
      if (next.asData == null) return;
      state = applyRecordsChange(next.asData!.value, state);
    });
    return null;
  }

  @visibleForTesting
  void set(int? index) => state = index;

  void goPrevious() {
    final records = ref.read(recordsProvider).asData?.value;
    state = (records == null || records.isEmpty)
        ? state
        : ((state != null && 0 < state!) ? state! - 1 : 0);
  }

  void goNext() {
    final records = ref.read(recordsProvider).asData?.value;
    state = (records == null || records.isEmpty)
        ? state
        : ((state != null && state! < records.length - 1)
              ? state! + 1
              : records.length - 1);
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

final editingRecordProvider = NotifierProvider<EditingRecordNotifier, Record?>(
  EditingRecordNotifier.new,
);

class EditingRecordNotifier extends Notifier<Record?> {
  @override
  Record? build() => null;

  void edit(Record record) => state = record;

  void close() => state = null;
}

class EditingDate {
  final Record record;
  final Cal date;
  final List<Holiday> holidays;

  EditingDate({
    required this.record,
    required this.date,
    required this.holidays,
  });
}

final editingDateProvider = NotifierProvider<EditingDateNotifier, EditingDate?>(
  EditingDateNotifier.new,
);

class EditingDateNotifier extends Notifier<EditingDate?> {
  @override
  EditingDate? build() => null;

  void edit(EditingDate editing) => state = editing;

  void close() => state = null;
}

Future<Either<String, Unit>> saveRecord(
  FirebaseFirestore db,
  String uid,
  Record record,
) async {
  try {
    final recordsRef = db.collection('users').doc(uid).collection('records');
    final val = record.toMap();

    if (record.id.isEmpty) {
      await recordsRef.add({
        ...val['data'],
        'createdAt': FieldValue.serverTimestamp(),
      });
    } else {
      await recordsRef.doc(val['id']).update({
        ...val['data'],
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
  String id,
  Cal date,
  DateRecord dateRecord,
) async {
  try {
    await db.collection('users').doc(uid).collection('records').doc(id).update({
      'dates.${date.yyyymmdd}': dateRecord.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return right(unit);
  } catch (error, stackTrace) {
    debugPrint('Error saving date record: $error\n$stackTrace');
    return left('$error');
  }
}
