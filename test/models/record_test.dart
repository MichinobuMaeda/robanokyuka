import 'dart:async';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:robanokyuka/config/firebase.dart';
import 'package:robanokyuka/models/cal_date.dart';
import 'package:robanokyuka/models/record.dart';

import 'package:robanokyuka/services/authentication.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('WorkTime', () {
    test(
      'toString returns empty string when seconds is 0 and all is false',
      () {
        expect(WorkTime(0).toString(), '');
      },
    );

    test('toString returns allString when all is true', () {
      expect(WorkTime(0, true).toString(), WorkTime.allString);
    });

    test('toString returns HH:MM string for non-zero seconds', () {
      expect(WorkTime(3600 * 8).toString(), '08:00');
    });

    test('hashCode is equal for equal WorkTime instances', () {
      expect(WorkTime(3600).hashCode, WorkTime(3600).hashCode);
    });

    test('hashCode differs for different WorkTime instances', () {
      expect(WorkTime(3600).hashCode, isNot(WorkTime(7200).hashCode));
    });
  });

  group('formatTime', () {
    test('returns HH:MM with leading zero for single-digit hours', () {
      expect(formatTime(8 * 3600), '08:00');
    });

    test('returns HH:MM for double-digit hours', () {
      expect(formatTime(10 * 3600 + 30 * 60), '10:30');
    });

    test('short: true returns H:MM without leading zero', () {
      expect(formatTime(8 * 3600, short: true), '8:00');
    });
  });

  group('formatTimeShort', () {
    test('returns H:MM without leading zero for single-digit hours', () {
      expect(formatTimeShort(8 * 3600), '8:00');
    });

    test('returns H:MM for zero hours', () {
      expect(formatTimeShort(30 * 60), '0:30');
    });

    test('returns H:MM for double-digit hours', () {
      expect(formatTimeShort(10 * 3600 + 30 * 60), '10:30');
    });
  });

  group('DateRecord', () {
    test('stores date, companyHoliday and note', () {
      final dr = DateRecord(
        Cal.fromString('20240101'),
        false,
        null,
        plan: WorkTime(0),
        used: WorkTime(0),
        sick: WorkTime(0),
        other: WorkTime(0),
      );
      expect(dr.companyHoliday, isFalse);
      expect(dr.plan, WorkTime(0));
      expect(dr.used, WorkTime(0));
      expect(dr.sick, WorkTime(0));
      expect(dr.other, WorkTime(0));
      expect(dr.note, isNull);
    });

    test('stores all explicitly provided fields', () {
      final dr = DateRecord(
        Cal.fromString('20240615'),
        true,
        'memo',
        plan: WorkTime.parse('08:00'),
        used: WorkTime.parse('04:00'),
        sick: WorkTime.parse('02:00'),
        other: WorkTime.parse('01:00'),
      );
      expect(dr.date.yyyymmdd, '20240615');
      expect(dr.companyHoliday, isTrue);
      expect(dr.plan, WorkTime.parse('08:00'));
      expect(dr.used, WorkTime.parse('04:00'));
      expect(dr.sick, WorkTime.parse('02:00'));
      expect(dr.other, WorkTime.parse('01:00'));
      expect(dr.note, 'memo');
    });
  });

  group('Record', () {
    test('defaults all optional fields', () {
      final r = Record(
        id: 'r1',
        from: Cal.fromString('20240401'),
        to: Cal.fromString('20250331'),
      );
      expect(r.publicHolidays, defaultPublicHolidays);
      expect(r.givenLeaves, defaultGivenLeaves);
      expect(r.minLeaves, defaultMinLeaves);
      expect(r.useLeavesHourly, isFalse);
      expect(r.workingHours, defaultWorkingHours);
      expect(r.dates, isEmpty);
    });

    test('stores all explicitly provided fields', () {
      final customHolidays = [
        false,
        true,
        true,
        true,
        true,
        true,
        false,
        false,
      ];
      final dr = DateRecord(
        Cal.fromString('20240615'),
        false,
        null,
        plan: WorkTime.parse('08:00'),
        used: WorkTime(0),
        sick: WorkTime(0),
        other: WorkTime(0),
      );
      final r = Record(
        id: 'custom',
        from: Cal.fromString('20240101'),
        to: Cal.fromString('20241231'),
        publicHolidays: customHolidays,
        givenLeaves: 20,
        minLeaves: 10,
        useLeavesHourly: true,
        stdSeconds: parseTime('09:00'),
        dates: [dr],
      );
      expect(r.id, 'custom');
      expect(r.publicHolidays, customHolidays);
      expect(r.givenLeaves, 20);
      expect(r.minLeaves, 10);
      expect(r.useLeavesHourly, isTrue);
      expect(r.workingHours, parseTime('09:00'));
    });
  });

  group('Record.fromDefault', () {
    test(
      'with empty list: from = current year/04/01, to = next year/03/31',
      () {
        final result = Record.next([]);
        final now = DateTime.now();
        expect(result.id, '');
        expect(result.from.yyyymmdd, '${now.year}0401');
        expect(result.to.yyyymmdd, '${now.year + 1}0331');
      },
    );

    test(
      'with one record: from = day after its to, to = one year after its to',
      () {
        final existing = Record(
          id: 'r1',
          from: Cal.fromString('20240401'),
          to: Cal.fromString('20250331'),
        );
        final result = Record.next([existing]);
        expect(result.from.yyyymmdd, '20250401');
        expect(result.to.yyyymmdd, '20260331');
      },
    );

    test('picks the record with the latest to date when multiple exist', () {
      final records = [
        Record(
          id: 'r1',
          from: Cal.fromString('20230401'),
          to: Cal.fromString('20240331'),
        ),
        Record(
          id: 'r2',
          from: Cal.fromString('20240401'),
          to: Cal.fromString('20250331'),
        ),
      ];
      final result = Record.next(records);
      expect(result.from.yyyymmdd, '20250401');
    });

    test(
      'uses default values for leaves, workingHours, and publicHolidays',
      () {
        final result = Record.next([]);
        expect(result.givenLeaves, defaultGivenLeaves);
        expect(result.minLeaves, defaultMinLeaves);
        expect(result.workingHours, defaultWorkingHours);
        expect(result.publicHolidays, defaultPublicHolidays);
        expect(result.useLeavesHourly, isFalse);
      },
    );
  });

  group('Record.monthList', () {
    test('returns all months within a single year', () {
      final r = Record(
        id: 'r',
        from: Cal.fromString('20240401'),
        to: Cal.fromString('20240630'),
      );
      expect(r.months, [(2024, 4), (2024, 5), (2024, 6)]);
    });

    test('spans a year boundary correctly', () {
      final r = Record(
        id: 'r',
        from: Cal.fromString('20241001'),
        to: Cal.fromString('20250331'),
      );
      expect(r.months, [
        (2024, 10),
        (2024, 11),
        (2024, 12),
        (2025, 1),
        (2025, 2),
        (2025, 3),
      ]);
    });

    test(
      'returns a single-element list when from and to are the same month',
      () {
        final r = Record(
          id: 'r',
          from: Cal.fromString('20240101'),
          to: Cal.fromString('20240131'),
        );
        expect(r.months, [(2024, 1)]);
      },
    );
  });

  // ---------------------------------------------------------------------------
  group('Record.summary', () {
    Record makeRecord({int? workingHours}) => Record(
      id: 'r',
      from: Cal.fromString('20240401'),
      to: Cal.fromString('20250331'),
      stdSeconds: workingHours ?? defaultWorkingHours, // 8h = 28800s
    );

    test('returns 0 for empty list', () {
      expect(makeRecord().summary([]), '0');
    });

    test('counts an "all" entry as one workingHours worth of seconds', () {
      // 1 × 28800s = 1 day exactly → no remainder
      expect(makeRecord().summary([WorkTime(0, true)]), '1');
    });

    test('sums plain seconds and formats remainder as d(h:mm)', () {
      // 4.5h = 16200s → 0 days, 4:30 remaining
      expect(makeRecord().summary([WorkTime(4 * 3600 + 30 * 60)]), '0(4:30)');
    });

    test('mixes all and plain seconds', () {
      // 28800 + 3600 = 32400s → 1 day + 3600s = 1(1:00)
      expect(
        makeRecord().summary([WorkTime(0, true), WorkTime(3600)]),
        '1(1:00)',
      );
    });

    test('minutes are zero-padded to two digits', () {
      expect(makeRecord().summary([WorkTime(5 * 60)]), '0(0:05)');
    });

    test('multiple all entries accumulate', () {
      // 2 × 28800 = 57600s → 2 days, no remainder
      expect(makeRecord().summary([WorkTime(0, true), WorkTime(0, true)]), '2');
    });
  });

  // ---------------------------------------------------------------------------
  group('Record.plannedLeaves / usedLeaves / sickLeaves / otherLeaves', () {
    // Build a record with one DateRecord that has distinct values per field.
    // plan=8h (all), used=4h, sick=2h, other=1h — workingHours=8h (28800s)
    final date = Cal.fromString('20240615');
    final dr = DateRecord(
      date,
      false,
      null,
      plan: WorkTime(0, true), // all → 1 workingHours = 8h
      used: WorkTime(4 * 3600), // 4h
      sick: WorkTime(2 * 3600), // 2h
      other: WorkTime(3600), // 1h
    );
    final record = Record(
      id: 'r',
      from: Cal.fromString('20240401'),
      to: Cal.fromString('20250331'),
      stdSeconds: defaultWorkingHours, // 8h = 28800s
      dates: [dr],
    );

    test('plannedLeaves sums plan field across all dates', () {
      // all → 28800s → 1 day, no remainder
      expect(record.plannedLeaves, '1');
    });

    test('usedLeaves sums used field across all dates', () {
      // 4h = 14400s → 0d, 4:00 remaining
      expect(record.usedLeaves, '0(4:00)');
    });

    test('sickLeaves sums sick field across all dates', () {
      // 2h = 7200s → 0d, 2:00 remaining
      expect(record.sickLeaves, '0(2:00)');
    });

    test('otherLeaves sums other field across all dates', () {
      // 1h = 3600s → 0d, 1:00 remaining
      expect(record.otherLeaves, '0(1:00)');
    });

    test('returns 0 for each field when dates is empty', () {
      final empty = Record(
        id: 'r',
        from: Cal.fromString('20240401'),
        to: Cal.fromString('20250331'),
      );
      expect(empty.plannedLeaves, '0');
      expect(empty.usedLeaves, '0');
      expect(empty.sickLeaves, '0');
      expect(empty.otherLeaves, '0');
    });

    test('accumulates across multiple dates', () {
      final dr2 = DateRecord(
        Cal.fromString('20240616'),
        false,
        null,
        plan: WorkTime(0, true), // another all day
        used: WorkTime(4 * 3600),
        sick: WorkTime(0),
        other: WorkTime(0),
      );
      final r2 = Record(
        id: 'r2',
        from: Cal.fromString('20240401'),
        to: Cal.fromString('20250331'),
        stdSeconds: defaultWorkingHours,
        dates: [dr, dr2],
      );
      // plan: 2 × all → 2 × 28800 = 57600s → 2 days, no remainder
      expect(r2.plannedLeaves, '2');
      // used: 4h + 4h = 8h = 28800s → 1 day, no remainder
      expect(r2.usedLeaves, '1');
    });
  });

  // ---------------------------------------------------------------------------
  group('Record.isHolidayWeekDay', () {
    Record makeRecord({List<bool>? publicHolidays}) => Record(
      id: 'r',
      from: Cal.fromString('20240101'),
      to: Cal.fromString('20241231'),
      publicHolidays: publicHolidays ?? List<bool>.from(defaultPublicHolidays),
    );

    // 2024-01-07 is a Sunday  (weekday % 7 == 0)
    // 2024-01-08 is a Monday  (weekday % 7 == 1)
    // 2024-01-09 is a Tuesday (weekday % 7 == 2)
    // 2024-01-13 is a Saturday(weekday % 7 == 6)

    test('returns true for Sunday with default holidays', () {
      expect(makeRecord().isHolidayWeekDay(Cal.fromString('20240107')), isTrue);
    });

    test('returns false for Monday with default holidays', () {
      expect(
        makeRecord().isHolidayWeekDay(Cal.fromString('20240108')),
        isFalse,
      );
    });

    test('returns false for Tuesday with default holidays', () {
      expect(
        makeRecord().isHolidayWeekDay(Cal.fromString('20240109')),
        isFalse,
      );
    });

    test('returns true for Saturday with default holidays', () {
      expect(makeRecord().isHolidayWeekDay(Cal.fromString('20240113')), isTrue);
    });

    test('returns false for Sunday when Sunday is not a holiday', () {
      final holidays = List<bool>.from(defaultPublicHolidays)..[0] = false;
      expect(
        makeRecord(
          publicHolidays: holidays,
        ).isHolidayWeekDay(Cal.fromString('20240107')),
        isFalse,
      );
    });

    test('returns true for Monday when Monday is set as a holiday', () {
      final holidays = List<bool>.from(defaultPublicHolidays)..[1] = true;
      expect(
        makeRecord(
          publicHolidays: holidays,
        ).isHolidayWeekDay(Cal.fromString('20240108')),
        isTrue,
      );
    });
  });

  // ---------------------------------------------------------------------------
  group('Record.fromDocument', () {
    test('parses all top-level fields from Firestore', () async {
      final firestore = FakeFirebaseFirestore();
      await firestore
          .collection('users')
          .doc('u1')
          .collection('records')
          .doc('r1')
          .set({
            'from': '20240401',
            'to': '20250331',
            'holidays': [true, false, false, false, false, false, true, true],
            'givenLeaves': 15,
            'minLeaves': 7,
            'useLeavesHourly': true,
            'workingHours': '09:00',
          });
      final doc = await firestore
          .collection('users')
          .doc('u1')
          .collection('records')
          .doc('r1')
          .get();

      final record = Record.fromDocument(doc);

      expect(record.id, 'r1');
      expect(record.from.yyyymmdd, '20240401');
      expect(record.to.yyyymmdd, '20250331');
      expect(record.givenLeaves, 15);
      expect(record.minLeaves, 7);
      expect(record.useLeavesHourly, isTrue);
      expect(record.workingHours, parseTime('09:00'));
      expect(record.dates, isEmpty);
    });

    test('uses defaults when optional fields are absent', () async {
      final firestore = FakeFirebaseFirestore();
      await firestore
          .collection('users')
          .doc('u1')
          .collection('records')
          .doc('r2')
          .set({'from': '20240401', 'to': '20250331'});
      final doc = await firestore
          .collection('users')
          .doc('u1')
          .collection('records')
          .doc('r2')
          .get();

      final record = Record.fromDocument(doc);

      expect(record.publicHolidays, defaultPublicHolidays);
      expect(record.givenLeaves, defaultGivenLeaves);
      expect(record.minLeaves, defaultMinLeaves);
      expect(record.useLeavesHourly, isFalse);
      expect(record.workingHours, defaultWorkingHours);
    });

    test('parses dates map into DateRecord list', () async {
      final firestore = FakeFirebaseFirestore();
      await firestore
          .collection('users')
          .doc('u1')
          .collection('records')
          .doc('r3')
          .set({
            'from': '20240401',
            'to': '20250331',
            'dates': {
              '20240615': {
                'c': true,
                'p': '08:00',
                'u': '04:00',
                's': '02:00',
                'o': '01:00',
                'n': 'memo',
              },
            },
          });
      final doc = await firestore
          .collection('users')
          .doc('u1')
          .collection('records')
          .doc('r3')
          .get();

      final record = Record.fromDocument(doc);

      expect(record.dates.length, 1);
      expect(record.dates[0].date.yyyymmdd, '20240615');
      expect(record.dates[0].companyHoliday, isTrue);
      expect(record.dates[0].plan, WorkTime.parse('08:00'));
      expect(record.dates[0].used, WorkTime.parse('04:00'));
      expect(record.dates[0].sick, WorkTime.parse('02:00'));
      expect(record.dates[0].other, WorkTime.parse('01:00'));
      expect(record.dates[0].note, 'memo');
    });
  });

  group('saveDateRecord', () {
    test('saves DateRecord fields under dates.<yyyymmdd> key', () async {
      final firestore = FakeFirebaseFirestore();
      await firestore
          .collection('users')
          .doc('u1')
          .collection('records')
          .doc('r1')
          .set({'from': '20240401', 'to': '20250331'});
      final dr = DateRecord(
        Cal.fromString('20240615'),
        true,
        'memo',
        plan: WorkTime.parse('06:00'),
        used: WorkTime.parse('04:00'),
        sick: WorkTime.parse('02:00'),
        other: WorkTime.parse('01:00'),
      );

      final result = await saveDateRecord(firestore, 'u1', 'r1', dr);

      expect(result.isRight(), isTrue);
      final doc = await firestore
          .collection('users')
          .doc('u1')
          .collection('records')
          .doc('r1')
          .get();
      final dates = doc.data()!['dates'] as Map<String, dynamic>;
      expect(dates.containsKey('20240615'), isTrue);
      final entry = dates['20240615'] as Map<String, dynamic>;
      expect(entry['c'], isTrue);
      expect(entry['p'], '06:00');
      expect(entry['u'], '04:00');
      expect(entry['s'], '02:00');
      expect(entry['o'], '01:00');
      expect(entry['n'], 'memo');
      expect(entry.containsKey('date'), isFalse);
    });

    test('returns left when record does not exist', () async {
      final firestore = FakeFirebaseFirestore();
      final dr = DateRecord(
        Cal.fromString('20240615'),
        false,
        null,
        plan: WorkTime(0),
        used: WorkTime(0),
        sick: WorkTime(0),
        other: WorkTime(0),
      );

      final result = await saveDateRecord(firestore, 'u1', 'nonexistent', dr);

      expect(result.isLeft(), isTrue);
    });
  });

  group('saveRecord', () {
    test('adds a new document when record id is empty', () async {
      final firestore = FakeFirebaseFirestore();
      final record = Record(
        id: '',
        from: Cal.fromString('20240401'),
        to: Cal.fromString('20250331'),
      );

      final result = await saveRecord(firestore, 'u1', record);

      expect(result.isRight(), isTrue);
      final docs = await firestore
          .collection('users')
          .doc('u1')
          .collection('records')
          .get();
      expect(docs.docs.length, 1);
      expect(docs.docs[0].data()['from'], '20240401');
    });

    test('updates existing document when record id is non-empty', () async {
      final firestore = FakeFirebaseFirestore();
      await firestore
          .collection('users')
          .doc('u1')
          .collection('records')
          .doc('r1')
          .set({'from': '20230401', 'to': '20240331'});
      final record = Record(
        id: 'r1',
        from: Cal.fromString('20240401'),
        to: Cal.fromString('20250331'),
        givenLeaves: 20,
      );

      final result = await saveRecord(firestore, 'u1', record);

      expect(result.isRight(), isTrue);
      final doc = await firestore
          .collection('users')
          .doc('u1')
          .collection('records')
          .doc('r1')
          .get();
      expect(doc.data()!['from'], '20240401');
      expect(doc.data()!['givenLeaves'], 20);
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

    test('sets state to null when records is null', () {
      final container = makeContainer();
      final notifier = container.read(selectedRecordIndexProvider.notifier);
      notifier.set(0);

      notifier.applyRecordsChange(null);

      expect(container.read(selectedRecordIndexProvider), isNull);
    });

    test('sets state to null when records is empty', () {
      final container = makeContainer();
      final notifier = container.read(selectedRecordIndexProvider.notifier);
      notifier.set(0);

      notifier.applyRecordsChange([]);

      expect(container.read(selectedRecordIndexProvider), isNull);
    });

    test('resets to last index when current is null', () {
      final container = makeContainer();
      final notifier = container.read(selectedRecordIndexProvider.notifier);
      // state is null from build()

      notifier.applyRecordsChange([record(2020), record(2021)]);

      expect(container.read(selectedRecordIndexProvider), 1);
    });

    test('resets to last index when current is negative', () {
      final container = makeContainer();
      final notifier = container.read(selectedRecordIndexProvider.notifier);
      notifier.set(-1);

      notifier.applyRecordsChange([record(2020), record(2021)]);

      expect(container.read(selectedRecordIndexProvider), 1);
    });

    test('resets to last index when current is out of bounds', () {
      final container = makeContainer();
      final notifier = container.read(selectedRecordIndexProvider.notifier);
      notifier.set(5);

      notifier.applyRecordsChange([record(2020)]);

      expect(container.read(selectedRecordIndexProvider), 0);
    });

    test('keeps current index when it is in bounds', () {
      final container = makeContainer();
      final notifier = container.read(selectedRecordIndexProvider.notifier);
      notifier.set(1);

      notifier.applyRecordsChange([record(2020), record(2021), record(2022)]);

      expect(container.read(selectedRecordIndexProvider), 1);
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

  group('parseYmd', () {
    test('parses a valid yyyymmdd string into a DateTime', () {
      final cal = Cal.fromString('20240107');
      expect(cal.year, 2024);
      expect(cal.month, 1);
      expect(cal.day, 7);
    });

    test('returns correct weekday', () {
      // 2024-01-07 is a Sunday (weekday == 7)
      final cal1 = Cal.fromString('20240107');
      expect(DateTime(cal1.year, cal1.month, cal1.day).weekday, 7);
      // 2024-01-08 is a Monday (weekday == 1)
      final cal2 = Cal.fromString('20240108');
      expect(DateTime(cal2.year, cal2.month, cal2.day).weekday, 1);
    });
  });
}
