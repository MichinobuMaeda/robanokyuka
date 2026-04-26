import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:yukyuchecker/config/firebase.dart';
import 'package:yukyuchecker/models/gengo.dart';
import 'package:yukyuchecker/models/service.dart';
import 'package:yukyuchecker/services/authentication.dart';
import 'package:yukyuchecker/services/helpers.dart';

List<Gengo> _gengos() => [
  Gengo(date: '18680125', name: '明治', short: 'M'),
  Gengo(date: '19120730', name: '大正', short: 'T'),
  Gengo(date: '19261225', name: '昭和', short: 'S'),
  Gengo(date: '19890108', name: '平成', short: 'H'),
  Gengo(date: '20190501', name: '令和', short: 'R'),
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('getNengo', () {
    final gengos = _gengos();

    test('returns year+年 when gengos is empty', () {
      expect(formatNengo([], '20240101'), '2024年');
    });

    test('returns bare year string when gengos is empty and short is true', () {
      expect(formatNengo([], '20240101', short: true), '2024');
    });

    test('returns Gregorian year before any era', () {
      expect(formatNengo(gengos, '18000101'), '1800年');
    });

    test('returns 令和1年 for 2019/05/01 (start of 令和)', () {
      expect(formatNengo(gengos, '20190501'), '令和1年');
    });

    test('returns 令和6年 for 2024 (2024 - 2019 + 1 = 6)', () {
      expect(formatNengo(gengos, '20240101'), '令和6年');
    });

    test('returns 平成31年 for 2019/04/30 (last day of 平成)', () {
      expect(formatNengo(gengos, '20190430'), '平成31年');
    });

    test('returns 昭和64年 for 1989/01/07 (last day of 昭和)', () {
      expect(formatNengo(gengos, '19890107'), '昭和64年');
    });

    test('returns 平成1年 for 1989/01/08 (start of 平成)', () {
      expect(formatNengo(gengos, '19890108'), '平成1年');
    });

    test('returns short form R6 for 2024 when short is true', () {
      expect(formatNengo(gengos, '20240101', short: true), 'R6');
    });

    test('returns short form H1 for 1989/01/08 when short is true', () {
      expect(formatNengo(gengos, '19890108', short: true), 'H1');
    });

    test('falls back to day 1 when date is a 6-char YYYYMM string', () {
      // '201905' → formatYmd(2019, 5, 1) = '20190501' → 令和1年
      expect(formatNengo(gengos, '201905'), '令和1年');
    });

    test('falls back to Jan 1 when date is a 4-char year string', () {
      // '2024' → formatYmd(2024, 1, 1) = '20240101' → 令和6年
      expect(formatNengo(gengos, '2024'), '令和6年');
    });
  });

  group('pad2', () {
    test('pads single-digit number with leading zero', () {
      expect(pad2(1), '01');
      expect(pad2(9), '09');
    });

    test('does not add padding to two-digit numbers', () {
      expect(pad2(10), '10');
      expect(pad2(31), '31');
    });
  });

  group('yearId', () {
    test('prefixes year with y', () {
      expect(yearId(2024), 'y2024');
      expect(yearId(1989), 'y1989');
    });
  });

  group('mmdd', () {
    test('pads single-digit month and day', () {
      expect(mmdd(1, 5), '0105');
    });

    test('handles two-digit month and day', () {
      expect(mmdd(12, 31), '1231');
    });
  });

  group('Holiday.compareTo', () {
    test('orders earlier date before later date', () {
      final jan1 = Holiday(date: '20240101', name: '元日');
      final may3 = Holiday(date: '20240503', name: '憲法記念日');
      expect(jan1.compareTo(may3), isNegative);
      expect(may3.compareTo(jan1), isPositive);
    });

    test('returns 0 for equal dates', () {
      final a = Holiday(date: '20240101', name: '元日');
      final b = Holiday(date: '20240101', name: '元日');
      expect(a.compareTo(b), 0);
    });
  });

  // ---------------------------------------------------------------------------
  group('adminsProvider', () {
    test('returns empty list when confProvider is null', () {
      final container = ProviderContainer(
        overrides: [confProvider.overrideWithValue(null)],
      );
      addTearDown(container.dispose);

      expect(container.read(adminsProvider), isEmpty);
    });

    test('returns admin uids from conf document', () async {
      final firestore = FakeFirebaseFirestore();
      await firestore.collection('service').doc('conf').set({
        'admins': ['uid1', 'uid2'],
      });
      final snap = await firestore.collection('service').doc('conf').get();
      final container = ProviderContainer(
        overrides: [confProvider.overrideWithValue(snap)],
      );
      addTearDown(container.dispose);

      expect(container.read(adminsProvider), ['uid1', 'uid2']);
    });

    test('returns empty list when admins field is missing', () async {
      final firestore = FakeFirebaseFirestore();
      await firestore.collection('service').doc('conf').set({'uiVersion': '1'});
      final snap = await firestore.collection('service').doc('conf').get();
      final container = ProviderContainer(
        overrides: [confProvider.overrideWithValue(snap)],
      );
      addTearDown(container.dispose);

      expect(container.read(adminsProvider), isEmpty);
    });
  });

  group('uiVersionProvider', () {
    test('returns null when confProvider is null', () {
      final container = ProviderContainer(
        overrides: [confProvider.overrideWithValue(null)],
      );
      addTearDown(container.dispose);

      expect(container.read(uiVersionProvider), isNull);
    });

    test('returns version string from conf document', () async {
      final firestore = FakeFirebaseFirestore();
      await firestore.collection('service').doc('conf').set({
        'uiVersion': '0.2.2+1',
      });
      final snap = await firestore.collection('service').doc('conf').get();
      final container = ProviderContainer(
        overrides: [confProvider.overrideWithValue(snap)],
      );
      addTearDown(container.dispose);

      expect(container.read(uiVersionProvider), '0.2.2+1');
    });

    test('returns null when uiVersion field is missing', () async {
      final firestore = FakeFirebaseFirestore();
      await firestore.collection('service').doc('conf').set({
        'admins': <String>[],
      });
      final snap = await firestore.collection('service').doc('conf').get();
      final container = ProviderContainer(
        overrides: [confProvider.overrideWithValue(snap)],
      );
      addTearDown(container.dispose);

      expect(container.read(uiVersionProvider), isNull);
    });
  });

  group('gengosProvider', () {
    test('returns empty list when confProvider is null', () {
      final container = ProviderContainer(
        overrides: [confProvider.overrideWithValue(null)],
      );
      addTearDown(container.dispose);

      expect(container.read(gengosProvider), isEmpty);
    });

    test('parses valid gengos from conf and sorts ascending', () async {
      final firestore = FakeFirebaseFirestore();
      await firestore.collection('service').doc('conf').set({
        'gengos': [
          {'year': 2019, 'month': 5, 'day': 1, 'name': '令和', 'short': 'R'},
          {'year': 1989, 'month': 1, 'day': 8, 'name': '平成', 'short': 'H'},
        ],
      });
      final snap = await firestore.collection('service').doc('conf').get();
      final container = ProviderContainer(
        overrides: [confProvider.overrideWithValue(snap)],
      );
      addTearDown(container.dispose);

      final gengos = container.read(gengosProvider);
      expect(gengos.length, 2);
      expect(gengos[0].name, '平成'); // sorted: 1989 before 2019
      expect(gengos[1].name, '令和');
    });

    test('skips invalid gengo entries', () async {
      final firestore = FakeFirebaseFirestore();
      await firestore.collection('service').doc('conf').set({
        'gengos': [
          {'year': 2019, 'month': 5, 'day': 1, 'name': '令和', 'short': 'R'},
          {'year': 0, 'month': 5, 'day': 1, 'name': '無効', 'short': 'X'},
          {'missing': 'fields'},
        ],
      });
      final snap = await firestore.collection('service').doc('conf').get();
      final container = ProviderContainer(
        overrides: [confProvider.overrideWithValue(snap)],
      );
      addTearDown(container.dispose);

      final gengos = container.read(gengosProvider);
      expect(gengos.length, 1);
      expect(gengos[0].name, '令和');
    });
  });

  group('holidaysProvider', () {
    test('returns empty list when serviceProvider has null value', () {
      final container = ProviderContainer(
        overrides: [serviceProvider.overrideWith((_) => Stream.value(null))],
      );
      addTearDown(container.dispose);
      container.listen(serviceProvider, (_, _) {});

      expect(container.read(holidaysProvider), isEmpty);
    });

    test('parses holidays from y#### documents', () async {
      final firestore = FakeFirebaseFirestore();
      await firestore.collection('service').doc('y2024').set({
        '0101': '元日',
        '0503': '憲法記念日',
      });
      // Non-holiday document should be ignored
      await firestore.collection('service').doc('conf').set({
        'admins': <String>[],
      });
      final qs = await firestore.collection('service').get();
      final container = ProviderContainer(
        overrides: [serviceProvider.overrideWith((_) => Stream.value(qs))],
      );
      addTearDown(container.dispose);
      container.listen(serviceProvider, (_, _) {});
      await container.read(serviceProvider.future);

      final holidays = container.read(holidaysProvider);
      expect(holidays.length, 2);
      expect(holidays[0].name, '元日');
      expect(holidays[0].date, '20240101');
      expect(holidays[1].name, '憲法記念日');
      expect(holidays[1].date, '20240503');
    });
  });

  group('setHoliday', () {
    test('writes holiday to service collection', () async {
      final firestore = FakeFirebaseFirestore();
      final holiday = Holiday(date: '20240101', name: '元日');

      final result = await setHoliday(firestore, holiday);

      expect(result.isRight(), isTrue);
      final doc = await firestore.collection('service').doc('y2024').get();
      expect(doc.data()!['0101'], '元日');
    });

    test('returns left when Firestore operation throws', () async {
      final firestore = FakeFirebaseFirestore(
        securityRules: '''
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if false;
    }
  }
}''',
      );
      final holiday = Holiday(date: '20240101', name: '元日');

      final result = await setHoliday(firestore, holiday);

      expect(result.isLeft(), isTrue);
    });
  });

  group('deleteHoliday', () {
    test('removes the holiday field from the service document', () async {
      final firestore = FakeFirebaseFirestore();
      await firestore.collection('service').doc('y2024').set({'0101': '元日'});
      final holiday = Holiday(date: '20240101', name: '元日');

      final result = await deleteHoliday(firestore, holiday);

      expect(result.isRight(), isTrue);
      final doc = await firestore.collection('service').doc('y2024').get();
      expect(doc.data()!.containsKey('0101'), isFalse);
    });

    test('returns left when Firestore update fails', () async {
      final firestore = FakeFirebaseFirestore();
      // No document exists — update will throw
      final holiday = Holiday(date: '20240101', name: '元日');

      final result = await deleteHoliday(firestore, holiday);

      expect(result.isLeft(), isTrue);
    });
  });

  group('serviceStream', () {
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
      container.listen(serviceProvider, (_, _) {});
      final snap = await container.read(serviceProvider.future);
      expect(snap, isNull);
    });

    test('emits service collection snapshot when uid is set', () async {
      final firestore = FakeFirebaseFirestore();
      await firestore.collection('service').doc('conf').set({'uiVersion': '1'});
      final container = makeContainer(uid: 'u1', firestore: firestore);
      container.listen(serviceProvider, (_, _) {});
      final snap = await container.read(serviceProvider.future);
      expect(snap, isNotNull);
      expect(snap!.docs.any((d) => d.id == 'conf'), isTrue);
    });
  });

  group('confProvider', () {
    ProviderContainer makeContainer(
      FakeFirebaseFirestore firestore,
      String? uid,
    ) {
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

    test('returns null when service has no conf document', () async {
      final firestore = FakeFirebaseFirestore();
      await firestore.collection('service').doc('other').set({'x': 1});
      final container = makeContainer(firestore, 'u1');
      container.listen(serviceProvider, (_, _) {});
      await container.read(serviceProvider.future);
      expect(container.read(confProvider), isNull);
    });

    test('returns conf document when it exists', () async {
      final firestore = FakeFirebaseFirestore();
      await firestore.collection('service').doc('conf').set({'uiVersion': '2'});
      final container = makeContainer(firestore, 'u1');
      container.listen(serviceProvider, (_, _) {});
      await container.read(serviceProvider.future);
      final conf = container.read(confProvider);
      expect(conf, isNotNull);
      expect(conf!.data()!['uiVersion'], '2');
    });
  });
}
