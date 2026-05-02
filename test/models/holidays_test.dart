import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:yukyuchecker/models/cal_date.dart';
import 'package:yukyuchecker/models/service.dart';
import 'package:yukyuchecker/models/holidays.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Holiday.compareTo', () {
    test('orders earlier date before later date', () {
      final jan1 = Holiday.fromString('20240101', name: '元日');
      final may3 = Holiday.fromString('20240503', name: '憲法記念日');
      expect(jan1.compareTo(may3), isNegative);
      expect(may3.compareTo(jan1), isPositive);
    });

    test('returns 0 for equal dates', () {
      final a = Holiday.fromString('20240101', name: '元日');
      final b = Holiday.fromString('20240101', name: '元日');
      expect(a.compareTo(b), 0);
    });
  });

  // ---------------------------------------------------------------------------
  group('Holiday.copyWith', () {
    final base = Holiday.fromString('20240503', name: '憲法記念日');

    test('returns an equal holiday when nothing is overridden', () {
      final copy = base.copyWith();
      expect(copy.yyyymmdd, base.yyyymmdd);
      expect(copy.name, base.name);
    });

    test('overrides name only', () {
      final copy = base.copyWith(name: '祝日');
      expect(copy.yyyymmdd, '20240503');
      expect(copy.name, '祝日');
    });

    test('overrides year only', () {
      final copy = base.copyWith(
        date: Cal(2025, base.date.month, base.date.day),
      );
      expect(copy.date.year, 2025);
      expect(copy.date.month, base.date.month);
      expect(copy.date.day, base.date.day);
      expect(copy.name, base.name);
    });

    test('overrides month and day', () {
      final copy = base.copyWith(date: Cal(base.date.year, 1, 1));
      expect(copy.yyyymmdd, '20240101');
      expect(copy.name, base.name);
    });

    test('overrides all fields', () {
      final copy = base.copyWith(date: Cal(2025, 1, 1), name: '元日');
      expect(copy.yyyymmdd, '20250101');
      expect(copy.name, '元日');
    });

    test('does not mutate the original', () {
      base.copyWith(
        date: Cal(2099, base.date.month, base.date.day),
        name: 'other',
      );
      expect(base.yyyymmdd, '20240503');
      expect(base.name, '憲法記念日');
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
      expect(holidays[0].yyyymmdd, '20240101');
      expect(holidays[1].name, '憲法記念日');
      expect(holidays[1].yyyymmdd, '20240503');
    });
  });

  group('setHoliday', () {
    test('writes holiday to service collection', () async {
      final firestore = FakeFirebaseFirestore();
      final holiday = Holiday.fromString('20240101', name: '元日');

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
      final holiday = Holiday.fromString('20240101', name: '元日');

      final result = await setHoliday(firestore, holiday);

      expect(result.isLeft(), isTrue);
    });
  });

  group('deleteHoliday', () {
    test('removes the holiday field from the service document', () async {
      final firestore = FakeFirebaseFirestore();
      await firestore.collection('service').doc('y2024').set({'0101': '元日'});
      final holiday = Holiday.fromString('20240101', name: '元日');

      final result = await deleteHoliday(firestore, holiday);

      expect(result.isRight(), isTrue);
      final doc = await firestore.collection('service').doc('y2024').get();
      expect(doc.data()!.containsKey('0101'), isFalse);
    });

    test('returns left when Firestore update fails', () async {
      final firestore = FakeFirebaseFirestore();
      // No document exists — update will throw
      final holiday = Holiday.fromString('20240101', name: '元日');

      final result = await deleteHoliday(firestore, holiday);

      expect(result.isLeft(), isTrue);
    });
  });
}
