import 'dart:async';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:yukyuchecker/config/firebase.dart';
import 'package:yukyuchecker/models/record.dart';
import 'package:yukyuchecker/models/service.dart';
import 'package:yukyuchecker/services/authentication.dart';
import 'package:yukyuchecker/services/helpers.dart';

Record _makeRecord({
  List<bool> publicHolidays = defaultPublicHolidays,
  List<DateRecord> dates = const [],
}) {
  return Record(
    id: 'test',
    from: '20240401',
    to: '20250331',
    publicHolidays: publicHolidays,
    dates: dates,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DateRecord', () {
    test('defaults all optional fields', () {
      final dr = DateRecord(date: '20240101');
      expect(dr.companyHoliday, isFalse);
      expect(dr.plan, isNull);
      expect(dr.used, isNull);
      expect(dr.sick, isNull);
      expect(dr.other, isNull);
      expect(dr.note, isNull);
    });

    test('stores all explicitly provided fields', () {
      final dr = DateRecord(
        date: '20240615',
        companyHoliday: true,
        plan: '08:00',
        used: '04:00',
        sick: '02:00',
        other: '01:00',
        note: 'memo',
      );
      expect(dr.date, '20240615');
      expect(dr.companyHoliday, isTrue);
      expect(dr.plan, '08:00');
      expect(dr.used, '04:00');
      expect(dr.sick, '02:00');
      expect(dr.other, '01:00');
      expect(dr.note, 'memo');
    });
  });

  group('Record', () {
    test('defaults all optional fields', () {
      final r = Record(id: 'r1', from: '20240401', to: '20250331');
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
      final dr = DateRecord(date: '20240615', plan: '08:00');
      final r = Record(
        id: 'custom',
        from: '20240101',
        to: '20241231',
        publicHolidays: customHolidays,
        givenLeaves: 20,
        minLeaves: 10,
        useLeavesHourly: true,
        workingHours: '09:00',
        dates: [dr],
      );
      expect(r.id, 'custom');
      expect(r.publicHolidays, customHolidays);
      expect(r.givenLeaves, 20);
      expect(r.minLeaves, 10);
      expect(r.useLeavesHourly, isTrue);
      expect(r.workingHours, '09:00');
      expect(r.dates, [dr]);
    });
  });

  group('isHolyday', () {
    // 2024/01/07 is a Sunday  → weekday 7, 7 % 7 = 0, publicHolidays[0] = true
    // 2024/01/06 is a Saturday → weekday 6, 6 % 7 = 6, publicHolidays[6] = true
    // 2024/01/08 is a Monday  → weekday 1, 1 % 7 = 1, publicHolidays[1] = false

    test('Sunday returns true with default publicHolidays', () {
      expect(isHolyday(_makeRecord(), [], '20240107'), isTrue);
    });

    test('Saturday returns true with default publicHolidays', () {
      expect(isHolyday(_makeRecord(), [], '20240106'), isTrue);
    });

    test('Monday returns false with default publicHolidays', () {
      expect(isHolyday(_makeRecord(), [], '20240108'), isFalse);
    });

    test(
      'returns true for national holiday when publicHolidays[7] is true',
      () {
        const date = '20240108'; // Monday
        final holiday = Holiday(date: date, name: '成人の日');
        final record = _makeRecord(
          publicHolidays: [true, false, false, false, false, false, true, true],
        );
        expect(isHolyday(record, [holiday], date), isTrue);
      },
    );

    test(
      'returns false for national holiday when publicHolidays[7] is false',
      () {
        const date = '20240108'; // Monday
        final holiday = Holiday(date: '20240108', name: '成人の日');
        final record = _makeRecord(
          publicHolidays: [
            true,
            false,
            false,
            false,
            false,
            false,
            true,
            false,
          ],
        );
        expect(isHolyday(record, [holiday], date), isFalse);
      },
    );

    test('returns true for company holiday (companyHoliday: true)', () {
      const date = '20240108'; // Monday
      final dateRecord = DateRecord(date: '20240108', companyHoliday: true);
      expect(isHolyday(_makeRecord(dates: [dateRecord]), [], date), isTrue);
    });

    test('returns false for DateRecord with companyHoliday: false', () {
      const date = '20240108'; // Monday
      final dateRecord = DateRecord(date: '20240108', companyHoliday: false);
      expect(isHolyday(_makeRecord(dates: [dateRecord]), [], date), isFalse);
    });
  });

  group('getDefaultRecord', () {
    test(
      'with empty list: from = current year/04/01, to = next year/03/31',
      () {
        final result = getDefaultRecord([]);
        final now = DateTime.now();
        expect(result.id, '');
        expect(result.from, '${now.year}0401');
        expect(result.to, '${now.year + 1}0331');
      },
    );

    test(
      'with one record: from = day after its to, to = one year after its to',
      () {
        final existing = Record(id: 'r1', from: '20240401', to: '20250331');
        final result = getDefaultRecord([existing]);
        expect(result.from, '20250401');
        expect(result.to, '20260331');
      },
    );

    test('picks the record with the latest to date when multiple exist', () {
      final records = [
        Record(id: 'r1', from: '20230401', to: '20240331'),
        Record(id: 'r2', from: '20240401', to: '20250331'),
      ];
      final result = getDefaultRecord(records);
      expect(result.from, '20250401');
    });

    test(
      'uses default values for leaves, workingHours, and publicHolidays',
      () {
        final result = getDefaultRecord([]);
        expect(result.givenLeaves, defaultGivenLeaves);
        expect(result.minLeaves, defaultMinLeaves);
        expect(result.workingHours, defaultWorkingHours);
        expect(result.publicHolidays, defaultPublicHolidays);
        expect(result.useLeavesHourly, isFalse);
      },
    );
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
      expect(record.from, '20240401');
      expect(record.to, '20250331');
      expect(record.givenLeaves, 15);
      expect(record.minLeaves, 7);
      expect(record.useLeavesHourly, isTrue);
      expect(record.workingHours, '09:00');
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
      expect(record.dates[0].date, '20240615');
      expect(record.dates[0].companyHoliday, isTrue);
      expect(record.dates[0].plan, '08:00');
      expect(record.dates[0].used, '04:00');
      expect(record.dates[0].sick, '02:00');
      expect(record.dates[0].other, '01:00');
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
        date: '20240615',
        companyHoliday: true,
        plan: '08:00',
        used: '04:00',
        sick: '02:00',
        other: '01:00',
        note: 'memo',
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
      expect(entry['p'], '08:00');
      expect(entry['u'], '04:00');
      expect(entry['s'], '02:00');
      expect(entry['o'], '01:00');
      expect(entry['n'], 'memo');
      expect(entry.containsKey('date'), isFalse);
    });

    test('returns left when record does not exist', () async {
      final firestore = FakeFirebaseFirestore();
      final dr = DateRecord(date: '20240615');

      final result = await saveDateRecord(firestore, 'u1', 'nonexistent', dr);

      expect(result.isLeft(), isTrue);
    });
  });

  group('saveRecord', () {
    test('adds a new document when record id is empty', () async {
      final firestore = FakeFirebaseFirestore();
      final record = Record(id: '', from: '20240401', to: '20250331');

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
        from: '20240401',
        to: '20250331',
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
            from: formatYmd(d[0], d[1], d[2]),
            to: '${d[0] + 1}0331',
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
        Record(id: 'past', from: '20200401', to: '20210331'),
        Record(
          id: 'future',
          from: formatYmd(now.year, now.month, now.day + 1),
          to: formatYmd(now.year + 1, now.month, now.day),
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
        Record(id: 'r$year', from: '${year}0401', to: '${year + 1}0331');

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
          from: '20240401',
          to: '20250331',
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

      expect(records[0].from.substring(4, 6), '04'); // April before October
      expect(records[1].from.substring(4, 6), '10');
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
        records![0].from.substring(4, 6),
        '04',
      ); // sorted: April before October
      expect(records[1].from.substring(4, 6), '10');
    });
  });

  group('parseYmd', () {
    test('parses a valid yyyymmdd string into a DateTime', () {
      final dt = parseYmd('20240107');
      expect(dt.year, 2024);
      expect(dt.month, 1);
      expect(dt.day, 7);
    });

    test('returns correct weekday', () {
      // 2024-01-07 is a Sunday (weekday == 7)
      expect(parseYmd('20240107').weekday, 7);
      // 2024-01-08 is a Monday (weekday == 1)
      expect(parseYmd('20240108').weekday, 1);
    });
  });
}
