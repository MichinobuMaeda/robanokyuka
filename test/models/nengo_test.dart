import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:yukyuchecker/models/cal_date.dart';
import 'package:yukyuchecker/models/nengo.dart';
import 'package:yukyuchecker/models/service.dart';
import 'package:yukyuchecker/models/users.dart';
import '../test_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // ---------------------------------------------------------------------------
  group('Gengo', () {
    test('stores name and short', () {
      final g = Gengo(date: Cal(2019, 5, 1), name: '令和', short: 'R');
      expect(g.name, '令和');
      expect(g.short, 'R');
    });

    test('holds Cal date with year, month, day and yyyymmdd getter', () {
      final g = Gengo(date: Cal(2019, 5, 1), name: '令和', short: 'R');
      expect(g.date.year, 2019);
      expect(g.date.month, 5);
      expect(g.date.day, 1);
      expect(g.date.yyyymmdd, '20190501');
    });
  });

  // ---------------------------------------------------------------------------
  group('Nengo.formatYear', () {
    final nengo = Nengo(gengos(), true);

    test('returns era year string for a date in a known era', () {
      // 2024 - 2019 + 1 = 6
      expect(nengo.formatYear(Cal(2024, 1, 7)), '令和6');
    });

    test('returns short form when short: true', () {
      expect(nengo.formatYear(Cal(2024, 1, 7), short: true), 'R6');
    });

    test('returns era 1 for the first day of a new era', () {
      // 2019-05-01 is the first day of 令和
      expect(nengo.formatYear(Cal(2019, 5, 1)), '令和1');
    });

    test('returns previous era for the day before an era change', () {
      // 2019-04-30 is still 平成31
      expect(nengo.formatYear(Cal(2019, 4, 30)), '平成31');
    });

    test('returns 昭和64 for 1989/01/07 (last day of 昭和)', () {
      expect(nengo.formatYear(Cal(1989, 1, 7)), '昭和64');
    });

    test('returns short form H1 for 1989/01/08 (first day of 平成)', () {
      expect(nengo.formatYear(Cal(1989, 1, 8), short: true), 'H1');
    });

    test('returns Gregorian year string for a date before any era', () {
      expect(nengo.formatYear(Cal(1800, 1, 1)), '1800');
    });

    test('returns Gregorian year when short: true and date before any era', () {
      expect(nengo.formatYear(Cal(1800, 1, 1), short: true), '1800');
    });

    test('returns Gregorian year string when gengos is empty', () {
      final empty = Nengo([], false);
      expect(empty.formatYear(Cal(2024, 1, 7)), '2024');
    });

    test('returns bare Gregorian year when short and gengos is empty', () {
      final empty = Nengo([], false);
      expect(empty.formatYear(Cal(2024, 1, 7), short: true), '2024');
    });

    test(
      'returns Gregorian year when showNengo is false, even with gengos',
      () {
        final nengoOff = Nengo(gengos(), false);
        expect(nengoOff.formatYear(Cal(2024, 1, 7)), '2024');
      },
    );

    test('returns Gregorian year when showNengo is false with short: true', () {
      final nengoOff = Nengo(gengos(), false);
      expect(nengoOff.formatYear(Cal(2024, 1, 7), short: true), '2024');
    });
  });

  // ---------------------------------------------------------------------------
  group('Nengo.formatShort', () {
    test('returns short era year for a date in a known era', () {
      final nengo = Nengo(gengos(), true);
      expect(nengo.formatShort(Cal(2024, 1, 7)), 'R6');
    });

    test('returns bare year string when gengos is empty', () {
      final nengo = Nengo([], false);
      expect(nengo.formatShort(Cal(2024, 1, 7)), '2024');
    });
  });

  // ---------------------------------------------------------------------------
  group('Nengo.format', () {
    test('returns full era date string', () {
      final nengo = Nengo(gengos(), true);
      expect(nengo.format(Cal(2024, 1, 7)), '令和6年1月7日');
    });

    test('returns Gregorian date string when gengos is empty', () {
      final nengo = Nengo([], false);
      expect(nengo.format(Cal(2024, 1, 7)), '2024年1月7日');
    });

    test('returns correct format for first day of 令和', () {
      final nengo = Nengo(gengos(), true);
      expect(nengo.format(Cal(2019, 5, 1)), '令和1年5月1日');
    });
  });

  // ---------------------------------------------------------------------------
  group('Nengo.parseYear', () {
    final nengo = Nengo(gengos(), true);

    test('parses full era name with Gregorian year', () {
      // 2019 + 6 - 1 = 2024
      expect(nengo.parseYear('令和6'), '2024');
    });

    test('parses short era code', () {
      expect(nengo.parseYear('R6'), '2024');
    });

    test('parses full-width digits', () {
      // '６' is converted to '6' by toHankaku
      expect(nengo.parseYear('R６'), '2024');
    });

    test('parses 平成31 to 2019', () {
      // 1989 + 31 - 1 = 2019
      expect(nengo.parseYear('平成31'), '2019');
    });

    test('returns input unchanged for a plain digit string (no era)', () {
      expect(nengo.parseYear('2024'), '2024');
    });

    test('returns input unchanged when era is not found', () {
      expect(nengo.parseYear('ABC1'), 'ABC1');
    });
  });

  // ---------------------------------------------------------------------------
  group('nengoProvider', () {
    test('returns empty gengos and showNengo false when conf is null', () {
      final container = ProviderContainer(
        overrides: [
          confProvider.overrideWithValue(null),
          userProvider.overrideWithValue(null),
        ],
      );
      addTearDown(container.dispose);

      final result = container.read(nengoProvider);
      expect(result.gengos, isEmpty);
      expect(result.showNengo, isFalse);
    });

    test('parses gengos from conf and sorts ascending by date', () async {
      final firestore = FakeFirebaseFirestore();
      await firestore.collection('service').doc('conf').set({
        'gengos': [
          {'year': 2019, 'month': 5, 'day': 1, 'name': '令和', 'short': 'R'},
          {'year': 1989, 'month': 1, 'day': 8, 'name': '平成', 'short': 'H'},
        ],
      });
      final snap = await firestore.collection('service').doc('conf').get();
      final container = ProviderContainer(
        overrides: [
          confProvider.overrideWithValue(snap),
          userProvider.overrideWithValue(null),
        ],
      );
      addTearDown(container.dispose);

      final result = container.read(nengoProvider);
      expect(result.gengos.length, 2);
      expect(result.gengos[0].name, '平成'); // 1989 before 2019
      expect(result.gengos[1].name, '令和');
    });

    test('showNengo is false when user is null', () async {
      final firestore = FakeFirebaseFirestore();
      await firestore.collection('service').doc('conf').set({'gengos': []});
      final snap = await firestore.collection('service').doc('conf').get();
      final container = ProviderContainer(
        overrides: [
          confProvider.overrideWithValue(snap),
          userProvider.overrideWithValue(null),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(nengoProvider).showNengo, isFalse);
    });

    test('showNengo is true when user.showNengo is true', () async {
      final firestore = FakeFirebaseFirestore();
      await firestore.collection('service').doc('conf').set({'gengos': []});
      final snap = await firestore.collection('service').doc('conf').get();
      final user = User(id: 'u1', name: 'Alice', showNengo: true);
      final container = ProviderContainer(
        overrides: [
          confProvider.overrideWithValue(snap),
          userProvider.overrideWithValue(user),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(nengoProvider).showNengo, isTrue);
    });

    test('showNengo is false when user.showNengo is false', () async {
      final firestore = FakeFirebaseFirestore();
      await firestore.collection('service').doc('conf').set({'gengos': []});
      final snap = await firestore.collection('service').doc('conf').get();
      final user = User(id: 'u1', name: 'Alice', showNengo: false);
      final container = ProviderContainer(
        overrides: [
          confProvider.overrideWithValue(snap),
          userProvider.overrideWithValue(user),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(nengoProvider).showNengo, isFalse);
    });
  });
}
