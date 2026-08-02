import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
// import 'package:markdown/markdown.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:robanokyuka/config/firebase.dart';
import 'package:robanokyuka/models/cal.dart';
import 'package:robanokyuka/models/holidays.dart';
import 'package:robanokyuka/models/record.dart';

import 'package:robanokyuka/services/authentication.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('WorkStatus', () {
    test('fromString parse String to emum WorkStatus', () {
      expect(WorkStatus.fromString('w'), WorkStatus.w);
      expect(WorkStatus.fromString('h'), WorkStatus.h);
      expect(WorkStatus.fromString('c'), WorkStatus.c);
      expect(WorkStatus.fromString('p'), WorkStatus.p);
      expect(WorkStatus.fromString('s'), WorkStatus.s);
      expect(WorkStatus.fromString('o'), WorkStatus.o);
      expect(WorkStatus.fromString('f'), WorkStatus.f);
      expect(WorkStatus.fromString('r'), WorkStatus.r);
      expect(WorkStatus.fromString('e'), WorkStatus.e);
    });

    test('fromString parse the lowercase of first char', () {
      expect(WorkStatus.fromString('Wx'), WorkStatus.w);
      expect(WorkStatus.fromString('Hx'), WorkStatus.h);
      expect(WorkStatus.fromString('Cx'), WorkStatus.c);
      expect(WorkStatus.fromString('Px'), WorkStatus.p);
      expect(WorkStatus.fromString('Sx'), WorkStatus.s);
      expect(WorkStatus.fromString('Ox'), WorkStatus.o);
      expect(WorkStatus.fromString('Fx'), WorkStatus.f);
      expect(WorkStatus.fromString('Rx'), WorkStatus.r);
      expect(WorkStatus.fromString('Ex'), WorkStatus.e);
    });

    test('fromString ignore spaces', () {
      expect(WorkStatus.fromString('  w'), WorkStatus.w);
      expect(WorkStatus.fromString('h  '), WorkStatus.h);
      expect(WorkStatus.fromString(' c '), WorkStatus.c);
    });

    test('fromString return null for invalid param', () {
      expect(WorkStatus.fromString(''), null);
      expect(WorkStatus.fromString(' '), null);
      expect(WorkStatus.fromString(null), null);
      expect(WorkStatus.fromString('1'), null);
    });
  });

  group('parseTime', () {
    test('parseTime parses H:MM', () {
      expect(parseTime('-9:00'), -9 * 3600);
      expect(parseTime('0:00'), 0);
      expect(parseTime('9:00'), 9 * 3600);
    });

    test('parseTime parses HH:MM with minutes', () {
      expect(parseTime('-00:01'), -1 * 60);
      expect(parseTime('00:00'), 0);
      expect(parseTime('08:30'), 8 * 3600 + 30 * 60);
      expect(parseTime('24:01'), 24 * 3600 + 1 * 60);
    });

    test('parseTime returns null for null', () {
      expect(parseTime(null), isNull);
    });

    test('parseTime returns null for string without colon', () {
      expect(parseTime('900'), isNull);
    });
  });

  group('formatTime', () {
    test('formatTime format zero', () {
      expect(formatTime(0), '0:00');
    });

    test('formatTime format positive number', () {
      expect(formatTime(60), '0:01');
      expect(formatTime(9 * 3600 + 0 * 60), '9:00');
      expect(formatTime(24 * 3600 + 1 * 60), '24:01');
    });

    test('formatTime format nagative number', () {
      expect(formatTime(-60), '-0:01');
      expect(formatTime(-(9 * 3600 + 0 * 60)), '-9:00');
      expect(formatTime(-(24 * 3600 + 1 * 60)), '-24:01');
    });
  });

  group('ScheduleItem', () {
    test('fromMap return null for invalid data', () {
      expect(ScheduleItem.fromMap({}), null);
      expect(ScheduleItem.fromMap({"time": "9:00"}), null);
      expect(ScheduleItem.fromMap({"status": "w"}), null);
      expect(ScheduleItem.fromMap({"time": "", "status": "w"}), null);
      expect(ScheduleItem.fromMap({"time": "9:00", "status": ""}), null);
    });

    test('fromMap return ScheduleItem from valid data', () {
      final i1 = ScheduleItem.fromMap({"time": "9:00", "status": "w"});
      expect(i1!.time, 9 * 3600);
      expect(i1.status, WorkStatus.w);

      final i2 = ScheduleItem.fromMap({"time": "-0:01", "status": "e"});
      expect(i2!.time, -60);
      expect(i2.status, WorkStatus.e);
    });

    test('toMap return {"time": "h:mm", "status": "s"}', () {
      expect(ScheduleItem(9 * 3600, WorkStatus.w).toMap(), {
        "time": "09:00",
        "status": "w",
      });
      expect(ScheduleItem(-60, WorkStatus.e).toMap(), {
        "time": "-0:01",
        "status": "e",
      });
    });
  });

  group('ScheduleList', () {
    test('default has empty', () {
      expect(ScheduleList().sch, []);
    });

    test('sorted create sorted List of ScheculeItem', () {
      expect(
        ScheduleList.sorted([
          ScheduleItem(10 * 3600, WorkStatus.e),
          ScheduleItem(9 * 3600, WorkStatus.w),
        ]).toMapList(),
        [
          {"time": "09:00", "status": "w"},
          {"time": "10:00", "status": "e"},
        ],
      );
    });

    test('fromMapList create sorted List of ScheculeItem', () {
      expect(
        ScheduleList.fromMapList([
          {"time": "10:00", "status": "e"},
          {"time": "9:00", "status": "w"},
        ]).toMapList(),
        [
          {"time": "09:00", "status": "w"},
          {"time": "10:00", "status": "e"},
        ],
      );
    });

    test('sum retun calculated time in seconds of each WorkStats', () {
      expect(
        ScheduleList.fromMapList([
          {"time": "9:00", "status": "w"},
          {"time": "12:00", "status": "r"},
          {"time": "13:00", "status": "w"},
          {"time": "16:00", "status": "s"},
          {"time": "18:00", "status": "e"},
        ]).sum(),
        {
          WorkStatus.w: 6 * 3600,
          WorkStatus.h: 0,
          WorkStatus.c: 0,
          WorkStatus.p: 0,
          WorkStatus.s: 2 * 3600,
          WorkStatus.o: 0,
          WorkStatus.f: 0,
          WorkStatus.r: 1 * 3600,
        },
      );
    });
  });

  group('DateRecord', () {
    test('fromMap initialize with map data', () {
      expect(DateRecord.fromMap({}).toMap(), {"status": null, "sch": []});
      expect(
        DateRecord.fromMap({
          "status": "w",
          "sch": [
            {"time": "9:00", "status": "w"},
            {"time": "10:00", "status": "e"},
          ],
        }).toMap(),
        {
          "status": "w",
          "sch": [
            {"time": "09:00", "status": "w"},
            {"time": "10:00", "status": "e"},
          ],
        },
      );
      expect(
        DateRecord.fromMap({
          "status": "w",
          "sch": [
            {"time": "9:00", "status": "w"},
            {"time": "10:00", "status": "e"},
          ],
          "note": "Test",
        }).toMap(),
        {
          "status": "w",
          "sch": [
            {"time": "09:00", "status": "w"},
            {"time": "10:00", "status": "e"},
          ],
          "note": "Test",
        },
      );
    });
  });

  test('mergeBoolList', () {
    expect(mergeBoolList([], null), []);
    expect(mergeBoolList([], []), []);
    expect(mergeBoolList([true, false], null), [true, false]);
    expect(mergeBoolList([true, false], []), [true, false]);
    expect(mergeBoolList([true, false], [false]), [false, false]);
    expect(mergeBoolList([true, false], [false, null]), [false, false]);
    expect(mergeBoolList([true, false], [null, true]), [true, true]);
    expect(mergeBoolList([true, false], [false, true]), [false, true]);
  });

  test('getIntValue', () {
    expect(getIntValue(null), null);
    expect(getIntValue(''), null);
    expect(getIntValue(1), 1);
    expect(getIntValue(1.0), 1);
    expect(getIntValue(1.01), 1);
    expect(getIntValue("1"), 1);
    expect(getIntValue("1.0"), 1);
    expect(getIntValue("1.01"), 1);
  });

  group('Record', () {
    final firestore = FakeFirebaseFirestore();
    final ref = firestore
        .collection('users')
        .doc('u1')
        .collection('records')
        .doc('r1');

    test('default has empty dates', () async {
      expect(
        Record(
          id: 'record_id',
          from: Cal.fromString('20250401'),
          to: Cal.fromString('20260331'),
        ).toMap(),
        {
          "id": 'record_id',
          "data": {
            "from": '20250401',
            "to": '20260331',
            "holidays": defaultHolidays,
            "givenLeaves": defaultGivenLeaves,
            "minLeaves": defaultMinLeaves,
            "useLeavesHourly": false,
            "sch": getDefauiltSchedule().toMapList(),
            "dates": {},
          },
        },
      );
    });

    test('fromDocument create instance from Firestore Document', () async {
      await ref.set({'from': '20250401', 'to': '20260331'});
      final doc1 = await ref.get();
      expect(Record.fromDocument(doc1).toMap(), {
        "id": 'r1',
        "data": {
          "from": '20250401',
          "to": '20260331',
          "holidays": defaultHolidays,
          "givenLeaves": defaultGivenLeaves,
          "minLeaves": defaultMinLeaves,
          "useLeavesHourly": false,
          "sch": getDefauiltSchedule().toMapList(),
          "dates": {},
        },
      });

      await ref.set({
        'from': '20240401',
        'to': '20250331',
        'holidays': [true, false, false, false, false, false, true, false],
        "givenLeaves": 11,
        "minLeaves": 6,
        "useLeavesHourly": true,
        "sch": [
          {"time": "17:00", "status": "e"},
          {"time": "10:00", "status": "w"},
        ],
        "dates": {
          '20240403': {'status': null},
          '20240402': {'status': 'h', "sch": []},
          '20240401': {
            'status': 'w',
            "sch": [
              {"time": "18:00", "status": "e"},
              {"time": "09:00", "status": "w"},
            ],
          },
        },
      });
      final doc2 = await ref.get();
      expect(Record.fromDocument(doc2).toMap(), {
        "id": 'r1',
        "data": {
          "from": '20240401',
          "to": '20250331',
          "holidays": [true, false, false, false, false, false, true, false],
          "givenLeaves": 11,
          "minLeaves": 6,
          "useLeavesHourly": true,
          "sch": [
            {"time": "10:00", "status": "w"},
            {"time": "17:00", "status": "e"},
          ],
          "dates": {
            '20240401': {
              'status': 'w',
              "sch": [
                {"time": "09:00", "status": "w"},
                {"time": "18:00", "status": "e"},
              ],
            },
            '20240402': {'status': 'h', "sch": []},
            '20240403': {'status': null, "sch": []},
          },
        },
      });
    });

    test('next create copy of the last record with next period', () async {
      final records = [
        Record(
          id: 'record_id',
          from: Cal.fromString('20250401'),
          to: Cal.fromString('20260331'),
          holidays: [true, false, false, false, false, false, true, false],
          givenLeaves: 11,
          minLeaves: 6,
          useLeavesHourly: true,
          sch: ScheduleList.fromMapList([
            {"time": "17:00", "status": "e"},
            {"time": "10:00", "status": "w"},
          ]),
          dates: {
            Cal(2024, 4, 3): DateRecord(null, []),
            Cal(2024, 4, 2): DateRecord(WorkStatus.h, []),
            Cal(2024, 4, 1): DateRecord(WorkStatus.w, [
              ScheduleItem.fromMap({"time": "18:00", "status": "e"})!,
              ScheduleItem.fromMap({"time": "09:00", "status": "w"})!,
            ]),
          },
        ),
        Record(
          id: 'record_id',
          from: Cal.fromString('20240401'),
          to: Cal.fromString('20250331'),
        ),
      ];
      expect(Record.next(records).toMap(), {
        'id': '',
        'data': {
          'from': '20260401',
          'to': '20270331',
          'holidays': [true, false, false, false, false, false, true, false],
          "givenLeaves": 11,
          "minLeaves": 6,
          "useLeavesHourly": true,
          "sch": [
            {"time": "10:00", "status": "w"},
            {"time": "17:00", "status": "e"},
          ],
          "dates": {},
        },
      });

      final year = DateTime.now().year;
      expect(Record.next([]).toMap(), {
        'id': '',
        'data': {
          'from': Cal(year, 4, 1).yyyymmdd,
          'to': Cal(year + 1, 3, 31).yyyymmdd,
          'holidays': defaultHolidays,
          "givenLeaves": defaultGivenLeaves,
          "minLeaves": defaultMinLeaves,
          "useLeavesHourly": false,
          "sch": getDefauiltSchedule().toMapList(),
          "dates": {},
        },
      });
    });

    test('fill return true if it added or updated some data', () async {
      final today = Cal(2025, 4, 4);
      final holidays = [Holiday(Cal(2025, 4, 3), 'Name')];
      final record = Record(
        id: 'r1',
        from: Cal(2025, 4, 1),
        to: Cal(2025, 4, 5),
        holidays: [true, false, false, false, false, false, true, false],
        givenLeaves: 11,
        minLeaves: 6,
        useLeavesHourly: true,
        sch: ScheduleList.fromMapList([
          {"time": "17:15", "status": "e"},
          {"time": "9:00", "status": "w"},
          {"time": "12:00", "status": "r"},
          {"time": "12:45", "status": "w"},
        ]),
        dates: {},
      );
      expect(record.fill(today, holidays), true);
      expect(record.toMap(), {
        "id": 'r1',
        "data": {
          "from": '20250401',
          "to": '20250405',
          "holidays": [true, false, false, false, false, false, true, false],
          "givenLeaves": 11,
          "minLeaves": 6,
          "useLeavesHourly": true,
          "sch": [
            {"time": "09:00", "status": "w"},
            {"time": "12:00", "status": "r"},
            {"time": "12:45", "status": "w"},
            {"time": "17:15", "status": "e"},
          ],
          "dates": {
            '20250401': {
              'status': 'w',
              "sch": [
                {"time": "09:00", "status": "w"},
                {"time": "12:00", "status": "r"},
                {"time": "12:45", "status": "w"},
                {"time": "17:15", "status": "e"},
              ],
            },
            '20250402': {
              'status': 'w',
              "sch": [
                {"time": "09:00", "status": "w"},
                {"time": "12:00", "status": "r"},
                {"time": "12:45", "status": "w"},
                {"time": "17:15", "status": "e"},
              ],
            },
            '20250403': {
              'status': 'w',
              "sch": [
                {"time": "09:00", "status": "w"},
                {"time": "12:00", "status": "r"},
                {"time": "12:45", "status": "w"},
                {"time": "17:15", "status": "e"},
              ],
            },
            '20250404': {'status': 'w', 'sch': []},
            '20250405': {'status': 'h', 'sch': []},
          },
        },
      });
      record.holidays[record.holidays.length - 1] = true;
      expect(record.fill(today, holidays), true);
      expect(record.toMap(), {
        "id": 'r1',
        "data": {
          "from": '20250401',
          "to": '20250405',
          "holidays": [true, false, false, false, false, false, true, true],
          "givenLeaves": 11,
          "minLeaves": 6,
          "useLeavesHourly": true,
          "sch": [
            {"time": "09:00", "status": "w"},
            {"time": "12:00", "status": "r"},
            {"time": "12:45", "status": "w"},
            {"time": "17:15", "status": "e"},
          ],
          "dates": {
            '20250401': {
              'status': 'w',
              "sch": [
                {"time": "09:00", "status": "w"},
                {"time": "12:00", "status": "r"},
                {"time": "12:45", "status": "w"},
                {"time": "17:15", "status": "e"},
              ],
            },
            '20250402': {
              'status': 'w',
              "sch": [
                {"time": "09:00", "status": "w"},
                {"time": "12:00", "status": "r"},
                {"time": "12:45", "status": "w"},
                {"time": "17:15", "status": "e"},
              ],
            },
            '20250403': {
              'status': 'h',
              "sch": [
                {"time": "09:00", "status": "f"},
                {"time": "12:00", "status": "r"},
                {"time": "12:45", "status": "f"},
                {"time": "17:15", "status": "e"},
              ],
            },
            '20250404': {'status': 'w', 'sch': []},
            '20250405': {'status': 'h', 'sch': []},
          },
        },
      });
      record.holidays[record.holidays.length - 1] = false;
      expect(record.fill(Cal(2025, 4, 6), holidays), true);
      expect(record.toMap(), {
        "id": 'r1',
        "data": {
          "from": '20250401',
          "to": '20250405',
          "holidays": [true, false, false, false, false, false, true, false],
          "givenLeaves": 11,
          "minLeaves": 6,
          "useLeavesHourly": true,
          "sch": [
            {"time": "09:00", "status": "w"},
            {"time": "12:00", "status": "r"},
            {"time": "12:45", "status": "w"},
            {"time": "17:15", "status": "e"},
          ],
          "dates": {
            '20250401': {
              'status': 'w',
              "sch": [
                {"time": "09:00", "status": "w"},
                {"time": "12:00", "status": "r"},
                {"time": "12:45", "status": "w"},
                {"time": "17:15", "status": "e"},
              ],
            },
            '20250402': {
              'status': 'w',
              "sch": [
                {"time": "09:00", "status": "w"},
                {"time": "12:00", "status": "r"},
                {"time": "12:45", "status": "w"},
                {"time": "17:15", "status": "e"},
              ],
            },
            '20250403': {
              'status': 'w',
              "sch": [
                {"time": "09:00", "status": "w"},
                {"time": "12:00", "status": "r"},
                {"time": "12:45", "status": "w"},
                {"time": "17:15", "status": "e"},
              ],
            },
            '20250404': {
              'status': 'w',
              'sch': [
                {"time": "09:00", "status": "w"},
                {"time": "12:00", "status": "r"},
                {"time": "12:45", "status": "w"},
                {"time": "17:15", "status": "e"},
              ],
            },
            '20250405': {'status': 'h', 'sch': []},
          },
        },
      });
    });
  });

  group('recordsStream', () {
    ProviderContainer makeContainer({
      required String? uid,
      required FakeFirebaseFirestore firestore,
    }) {
      final container = ProviderContainer(
        overrides: [
          firestoreProvider.overrideWithValue(firestore),
          authUserProvider.overrideWith(
            (_) => Stream.value(
              uid == null ? null : MockUser(uid: uid, email: 'u@example.com'),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);
      return container;
    }

    test('emits null when uid is null', () async {
      final container = makeContainer(
        uid: null,
        firestore: FakeFirebaseFirestore(),
      );
      container.listen(recordsProvider, (_, _) {});
      final records = await container.read(recordsProvider.future);
      expect(records, isNull);
    });

    test('emits empty list when user has no records', () async {
      final firestore = FakeFirebaseFirestore();
      await firestore.collection('users').doc('u1').set({'name': 'Alice'});
      final container = makeContainer(uid: 'u1', firestore: firestore);
      container.listen(recordsProvider, (_, _) {});
      final records = await container.read(recordsProvider.future);
      expect(records, isEmpty);
    });

    test('emits parsed and sorted records', () async {
      final firestore = FakeFirebaseFirestore();
      final userRef = firestore.collection('users').doc('u1');
      await userRef.collection('records').doc('r2').set({
        'from': '20241001',
        'to': '20250331',
      });
      await userRef.collection('records').doc('r1').set({
        'from': '20240401',
        'to': '20240930',
      });
      final container = makeContainer(uid: 'u1', firestore: firestore);
      container.listen(recordsProvider, (_, _) {});
      final records = await container.read(recordsProvider.future);
      expect(records, hasLength(2));
      expect(
        records![0].from.yyyymmdd.substring(4, 6),
        '04',
      ); // sorted: April before October
      expect(records[1].from.yyyymmdd.substring(4, 6), '10');
    });
  });

  group('recordsProvider sort order', () {
    test('sorts by month when years are equal', () async {
      final firestore = FakeFirebaseFirestore();
      final userRef = firestore.collection('users').doc('u1');
      // Insert in reverse month order
      await userRef.collection('records').doc('r2').set({
        'from': '20241001',
        'to': '20250331',
      });
      await userRef.collection('records').doc('r1').set({
        'from': '20240401',
        'to': '20240930',
      });

      final qs = await userRef.collection('records').get();
      final records =
          qs.docs.map((doc) => Record.fromDocument(doc)).toList(growable: true)
            ..sort((a, b) => a.from.compareTo(b.from));

      expect(
        records[0].from.yyyymmdd.substring(4, 6),
        '04',
      ); // April before October
      expect(records[1].from.yyyymmdd.substring(4, 6), '10');
    });
  });

  group('SelectedRecordIndexNotifier', () {
    List<Record> records(List<List<int>> fromDates) => fromDates
        .map(
          (d) => Record(
            id: 'r${d[0]}',
            from: Cal(d[0], d[1], d[2]),
            to: Cal(d[0] + 1, 3, 31),
          ),
        )
        .toList();

    test('returns null when records stream emits null', () async {
      final container = ProviderContainer(
        overrides: [recordsProvider.overrideWith((_) => Stream.value(null))],
      );
      addTearDown(container.dispose);
      container.listen(selectedRecordIndexProvider, (_, _) {});
      container.listen(recordsProvider, (_, _) {});
      await container.read(recordsProvider.future);
      await Future.microtask(() {});

      expect(container.read(selectedRecordIndexProvider), isNull);
    });

    test('returns null when records list is empty', () async {
      final container = ProviderContainer(
        overrides: [recordsProvider.overrideWith((_) => Stream.value([]))],
      );
      addTearDown(container.dispose);
      container.listen(selectedRecordIndexProvider, (_, _) {});
      container.listen(recordsProvider, (_, _) {});
      await container.read(recordsProvider.future);
      await Future.microtask(() {});

      expect(container.read(selectedRecordIndexProvider), isNull);
    });

    test('selects last record when all from-dates are in the past', () async {
      final recs = records([
        [2020, 4, 1],
        [2021, 4, 1],
        [2022, 4, 1],
      ]);
      final container = ProviderContainer(
        overrides: [recordsProvider.overrideWith((_) => Stream.value(recs))],
      );
      addTearDown(container.dispose);
      container.listen(selectedRecordIndexProvider, (_, _) {});
      container.listen(recordsProvider, (_, _) {});
      await container.read(recordsProvider.future);
      await Future.microtask(() {});

      expect(container.read(selectedRecordIndexProvider), 2);
    });

    test('selects first record when only it is before today', () async {
      final recs = records([
        [2020, 4, 1],
        [2099, 4, 1],
      ]);
      final container = ProviderContainer(
        overrides: [recordsProvider.overrideWith((_) => Stream.value(recs))],
      );
      addTearDown(container.dispose);
      container.listen(selectedRecordIndexProvider, (_, _) {});
      container.listen(recordsProvider, (_, _) {});
      await container.read(recordsProvider.future);
      await Future.microtask(() {});

      expect(container.read(selectedRecordIndexProvider), 0);
    });

    test('set() updates the index', () async {
      final recs = records([
        [2020, 4, 1],
        [2021, 4, 1],
        [2022, 4, 1],
      ]);
      final container = ProviderContainer(
        overrides: [recordsProvider.overrideWith((_) => Stream.value(recs))],
      );
      addTearDown(container.dispose);
      container.listen(selectedRecordIndexProvider, (_, _) {});
      container.listen(recordsProvider, (_, _) {});
      await container.read(recordsProvider.future);
      await Future.microtask(() {});

      container.read(selectedRecordIndexProvider.notifier).set(1);

      expect(container.read(selectedRecordIndexProvider), 1);
    });

    test(
      'listener resets to last index when current is out of bounds',
      () async {
        // Start with 3 records, set index to 2, then emit a shorter list
        final StreamController<List<Record>?> controller =
            StreamController<List<Record>?>();
        final records3 = records([
          [2020, 4, 1],
          [2021, 4, 1],
          [2022, 4, 1],
        ]);
        final records1 = records([
          [2020, 4, 1],
        ]);
        controller.add(records3);

        final container = ProviderContainer(
          overrides: [recordsProvider.overrideWith((_) => controller.stream)],
        );
        addTearDown(() {
          container.dispose();
          controller.close();
        });
        container.listen(selectedRecordIndexProvider, (_, _) {});
        container.listen(recordsProvider, (_, _) {});
        await container.read(recordsProvider.future);
        await Future.microtask(() {});

        // index is now 2 (last of 3); shrink to 1 record
        controller.add(records1);
        await Future.delayed(Duration.zero);

        // listener should have reset index to 0 (records1.length - 1)
        expect(container.read(selectedRecordIndexProvider), 0);
      },
    );

    test('breaks before a record starting later in the current month', () async {
      final now = DateTime.now();
      // First record is well in the past; second starts tomorrow (same month).
      final records = [
        Record(
          id: 'past',
          from: Cal.fromString('20200401'),
          to: Cal.fromString('20210331'),
        ),
        Record(
          id: 'future',
          from: Cal(now.year, now.month, now.day + 1),
          to: Cal(now.year + 1, now.month, now.day),
        ),
      ];
      final container = ProviderContainer(
        overrides: [recordsProvider.overrideWith((_) => Stream.value(records))],
      );
      addTearDown(container.dispose);
      container.listen(selectedRecordIndexProvider, (_, _) {});
      container.listen(recordsProvider, (_, _) {});
      await container.read(recordsProvider.future);
      await Future.microtask(() {});

      // Only the past record should be selected.
      expect(container.read(selectedRecordIndexProvider), 0);
    });

    test('listener keeps index when it is still in bounds', () async {
      final controller = StreamController<List<Record>?>();
      final recs = records([
        [2020, 4, 1],
        [2021, 4, 1],
      ]);

      final container = ProviderContainer(
        overrides: [recordsProvider.overrideWith((_) => controller.stream)],
      );
      addTearDown(() {
        container.dispose();
        controller.close();
      });
      container.listen(selectedRecordIndexProvider, (_, _) {});
      container.listen(recordsProvider, (_, _) {});

      // First emission — build() picks index 1 (both records in the past).
      controller.add(recs);
      await container.read(recordsProvider.future);
      await Future.microtask(() {});
      expect(container.read(selectedRecordIndexProvider), 1);

      // Second emission of same records — listener fires, current=1 is still
      // in bounds (1 < 2), so the listener must NOT reset the index.
      controller.add(recs);
      await Future.delayed(Duration.zero);

      expect(container.read(selectedRecordIndexProvider), 1);
    });
  });

  group('SelectedRecordIndexNotifier.goPrevious / goNext', () {
    List<Record> makeRecords(int count) => List.generate(
      count,
      (i) => Record(
        id: 'r$i',
        from: Cal(2020 + i, 4, 1),
        to: Cal(2021 + i, 3, 31),
      ),
    );

    ProviderContainer makeContainer(List<Record> recs) {
      final container = ProviderContainer(
        overrides: [recordsProvider.overrideWith((_) => Stream.value(recs))],
      );
      addTearDown(container.dispose);
      return container;
    }

    Future<void> prime(ProviderContainer container) async {
      container.listen(selectedRecordIndexProvider, (_, _) {});
      container.listen(recordsProvider, (_, _) {});
      await container.read(recordsProvider.future);
      await Future.microtask(() {});
    }

    test('goPrevious does nothing when records is empty', () async {
      final container = ProviderContainer(
        overrides: [recordsProvider.overrideWith((_) => Stream.value([]))],
      );
      addTearDown(container.dispose);
      await prime(container);

      container.read(selectedRecordIndexProvider.notifier).goPrevious();

      expect(container.read(selectedRecordIndexProvider), isNull);
    });

    test('goPrevious does nothing when records is null', () async {
      final container = ProviderContainer(
        overrides: [recordsProvider.overrideWith((_) => Stream.value(null))],
      );
      addTearDown(container.dispose);
      await prime(container);

      container.read(selectedRecordIndexProvider.notifier).goPrevious();

      expect(container.read(selectedRecordIndexProvider), isNull);
    });

    test('goPrevious sets index to 0 when current is null', () async {
      final container = ProviderContainer(
        overrides: [
          recordsProvider.overrideWith((_) => Stream.value(makeRecords(3))),
        ],
      );
      addTearDown(container.dispose);
      container.listen(selectedRecordIndexProvider, (_, _) {});
      container.listen(recordsProvider, (_, _) {});
      await container.read(recordsProvider.future);
      await Future.microtask(() {});
      container.read(selectedRecordIndexProvider.notifier).set(null);

      container.read(selectedRecordIndexProvider.notifier).goPrevious();

      expect(container.read(selectedRecordIndexProvider), 0);
    });

    test('goPrevious decrements index when current > 0', () async {
      final container = makeContainer(makeRecords(3));
      await prime(container);
      container.read(selectedRecordIndexProvider.notifier).set(2);

      container.read(selectedRecordIndexProvider.notifier).goPrevious();

      expect(container.read(selectedRecordIndexProvider), 1);
    });

    test('goPrevious does not go below 0', () async {
      final container = makeContainer(makeRecords(3));
      await prime(container);
      container.read(selectedRecordIndexProvider.notifier).set(0);

      container.read(selectedRecordIndexProvider.notifier).goPrevious();

      expect(container.read(selectedRecordIndexProvider), 0);
    });

    test('goNext does nothing when records is empty', () async {
      final container = ProviderContainer(
        overrides: [recordsProvider.overrideWith((_) => Stream.value([]))],
      );
      addTearDown(container.dispose);
      await prime(container);

      container.read(selectedRecordIndexProvider.notifier).goNext();

      expect(container.read(selectedRecordIndexProvider), isNull);
    });

    test('goNext does nothing when records is null', () async {
      final container = ProviderContainer(
        overrides: [recordsProvider.overrideWith((_) => Stream.value(null))],
      );
      addTearDown(container.dispose);
      await prime(container);

      container.read(selectedRecordIndexProvider.notifier).goNext();

      expect(container.read(selectedRecordIndexProvider), isNull);
    });

    test('goNext sets index to last when current is null', () async {
      final container = ProviderContainer(
        overrides: [
          recordsProvider.overrideWith((_) => Stream.value(makeRecords(3))),
        ],
      );
      addTearDown(container.dispose);
      container.listen(selectedRecordIndexProvider, (_, _) {});
      container.listen(recordsProvider, (_, _) {});
      await container.read(recordsProvider.future);
      await Future.microtask(() {});
      container.read(selectedRecordIndexProvider.notifier).set(null);

      container.read(selectedRecordIndexProvider.notifier).goNext();

      expect(container.read(selectedRecordIndexProvider), 2);
    });

    test('goNext increments index when current < last', () async {
      final container = makeContainer(makeRecords(3));
      await prime(container);
      container.read(selectedRecordIndexProvider.notifier).set(0);

      container.read(selectedRecordIndexProvider.notifier).goNext();

      expect(container.read(selectedRecordIndexProvider), 1);
    });

    test('goNext does not go beyond last index', () async {
      final container = makeContainer(makeRecords(3));
      await prime(container);
      container.read(selectedRecordIndexProvider.notifier).set(2);

      container.read(selectedRecordIndexProvider.notifier).goNext();

      expect(container.read(selectedRecordIndexProvider), 2);
    });
  });

  group('SelectedRecordIndexNotifier.applyRecordsChange', () {
    ProviderContainer makeContainer() {
      final container = ProviderContainer(
        overrides: [recordsProvider.overrideWith((_) => Stream.value(null))],
      );
      addTearDown(container.dispose);
      return container;
    }

    Record record(int year) =>
        Record(id: 'r$year', from: Cal(year, 4, 1), to: Cal(year + 1, 3, 31));

    test('returns null when records is null', () {
      final notifier = makeContainer().read(
        selectedRecordIndexProvider.notifier,
      );
      expect(notifier.applyRecordsChange(null, 0), isNull);
    });

    test('returns null when records is empty', () {
      final notifier = makeContainer().read(
        selectedRecordIndexProvider.notifier,
      );
      expect(notifier.applyRecordsChange([], 0), isNull);
    });

    test('selects last past record when current is null', () {
      final notifier = makeContainer().read(
        selectedRecordIndexProvider.notifier,
      );
      // Both records are in the past → last index returned
      expect(
        notifier.applyRecordsChange([record(2020), record(2021)], null),
        1,
      );
    });

    test('returns last index when current is negative', () {
      final notifier = makeContainer().read(
        selectedRecordIndexProvider.notifier,
      );
      expect(notifier.applyRecordsChange([record(2020), record(2021)], -1), 1);
    });

    test('returns last index when current exceeds bounds', () {
      final notifier = makeContainer().read(
        selectedRecordIndexProvider.notifier,
      );
      expect(notifier.applyRecordsChange([record(2020)], 5), 0);
    });

    test('returns current index when it is in bounds', () {
      final notifier = makeContainer().read(
        selectedRecordIndexProvider.notifier,
      );
      expect(
        notifier.applyRecordsChange([
          record(2020),
          record(2021),
          record(2022),
        ], 1),
        1,
      );
    });
  });

  group('EditingRecordNotifier', () {
    ProviderContainer makeContainer() {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      return container;
    }

    test('initial state is null', () {
      expect(makeContainer().read(editingRecordProvider), isNull);
    });

    test('edit sets the record', () {
      final container = makeContainer();
      final record = Record(
        id: 'r1',
        from: Cal.fromString('20240401'),
        to: Cal.fromString('20250331'),
      );
      container.read(editingRecordProvider.notifier).edit(record);
      expect(container.read(editingRecordProvider), same(record));
    });

    test('close resets state to null', () {
      final container = makeContainer();
      final record = Record(
        id: 'r1',
        from: Cal.fromString('20240401'),
        to: Cal.fromString('20250331'),
      );
      container.read(editingRecordProvider.notifier).edit(record);
      container.read(editingRecordProvider.notifier).close();
      expect(container.read(editingRecordProvider), isNull);
    });
  });

  group('EditingDateNotifier', () {
    late Record record;

    setUp(() {
      record = Record(
        id: 'r1',
        from: Cal.fromString('20240401'),
        to: Cal.fromString('20250331'),
      );
    });

    ProviderContainer makeContainer() {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      return container;
    }

    test('initial state is null', () {
      expect(makeContainer().read(editingDateProvider), isNull);
    });

    test('edit sets the EditingDate without holiday', () {
      final container = makeContainer();
      final editing = EditingDate(
        record: record,
        date: Cal.fromString('20240615'),
      );
      container.read(editingDateProvider.notifier).edit(editing);
      final state = container.read(editingDateProvider)!;
      expect(state.record, same(record));
      expect(state.date.yyyymmdd, '20240615');
      expect(state.holiday, isNull);
    });

    test('edit stores holiday when provided', () {
      final container = makeContainer();
      final holiday = Holiday(Cal.fromString('20240615'), 'Test Holiday');
      container
          .read(editingDateProvider.notifier)
          .edit(
            EditingDate(
              record: record,
              date: Cal.fromString('20240615'),
              holiday: holiday,
            ),
          );
      expect(container.read(editingDateProvider)!.holiday, same(holiday));
    });

    test('close resets state to null', () {
      final container = makeContainer();
      container
          .read(editingDateProvider.notifier)
          .edit(EditingDate(record: record, date: Cal.fromString('20240615')));
      container.read(editingDateProvider.notifier).close();
      expect(container.read(editingDateProvider), isNull);
    });
  });

  group('saveRecord', () {
    test('adds a new document when record id is empty', () async {
      final firestore = FakeFirebaseFirestore();
      final record = Record(
        id: '',
        from: Cal.fromString('20240401'),
        to: Cal.fromString('20250331'),
        sch: ScheduleList.fromMapList([
          {"time": "8:30", "status": "w"},
          {"time": "12:00", "status": "r"},
          {"time": "13:00", "status": "w"},
          {"time": "17:30", "status": "e"},
        ]),
      );

      final result = await saveRecord(firestore, 'u1', record);

      expect(result.isRight(), isTrue);
      final docs = await firestore
          .collection('users')
          .doc('u1')
          .collection('records')
          .get();
      expect(docs.docs.length, 1);
      expect(docs.docs[0].id, isNotEmpty);
      expect(docs.docs[0].data(), {
        ...record.toMap()['data'],
        'createdAt': anything,
      });
    });

    test('updates existing document when record id is non-empty', () async {
      final firestore = FakeFirebaseFirestore();
      await firestore
          .collection('users')
          .doc('u1')
          .collection('records')
          .doc('r1')
          .set({
            'from': '20230401',
            'to': '20240331',
            'createdAt': FieldValue.serverTimestamp(),
          });
      final record = Record(
        id: 'r1',
        from: Cal.fromString('20240401'),
        to: Cal.fromString('20250331'),
        givenLeaves: 20,
      );

      final result = await saveRecord(firestore, 'u1', record);

      expect(result.isRight(), isTrue);
      final docs = await firestore
          .collection('users')
          .doc('u1')
          .collection('records')
          .get();
      expect(docs.docs.length, 1);
      expect(docs.docs[0].id, 'r1');
      expect(docs.docs[0].data(), {
        ...record.toMap()['data'],
        'createdAt': anything,
        'updatedAt': anything,
      });
    });
  });

  group('saveRecord error path', () {
    test(
      'returns left when Firestore update fails on nonexistent doc',
      () async {
        final firestore = FakeFirebaseFirestore();
        final record = Record(
          id: 'nonexistent',
          from: Cal.fromString('20240401'),
          to: Cal.fromString('20250331'),
        );

        final result = await saveRecord(firestore, 'u1', record);

        expect(result.isLeft(), isTrue);
      },
    );
  });

  group('saveDateRecord', () {
    test('saves DateRecord fields under dates.<yyyymmdd> key', () async {
      final firestore = FakeFirebaseFirestore();
      await firestore
          .collection('users')
          .doc('u1')
          .collection('records')
          .doc('r1')
          .set({
            'from': '20240401',
            'to': '20250331',
            'createdAt': FieldValue.serverTimestamp(),
          });
      final dr = DateRecord(null, [
        ScheduleItem(9 * 3600, WorkStatus.w),
        ScheduleItem(18 * 3600, WorkStatus.e),
      ]);

      final result = await saveDateRecord(
        firestore,
        'u1',
        'r1',
        Cal.fromString('20240615'),
        dr,
      );

      expect(result.isRight(), isTrue);
      final doc = await firestore
          .collection('users')
          .doc('u1')
          .collection('records')
          .doc('r1')
          .get();
      expect(doc.data(), {
        'from': '20240401',
        'to': '20250331',
        'dates': {
          '20240615': {
            'status': null,
            'sch': [
              {'time': "09:00", 'status': 'w'},
              {'time': "18:00", 'status': 'e'},
            ],
          },
        },
        'createdAt': anything,
        'updatedAt': anything,
      });
    });

    test('returns left when record does not exist', () async {
      final firestore = FakeFirebaseFirestore();
      final dr = DateRecord(WorkStatus.w, []);

      final result = await saveDateRecord(
        firestore,
        'u1',
        'nonexistent',
        Cal.fromString('20240615'),
        dr,
      );

      expect(result.isLeft(), isTrue);
    });
  });
}
