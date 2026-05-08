import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:robanokyuka/config/firebase.dart';
import 'package:robanokyuka/models/cal_date.dart';
import 'package:robanokyuka/models/service.dart';
import 'package:robanokyuka/services/authentication.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // ---------------------------------------------------------------------------
  group('Conf.fromDocument', () {
    Future<Conf> makeConf(Map<String, dynamic> data) async {
      final firestore = FakeFirebaseFirestore();
      await firestore.collection('service').doc('conf').set(data);
      final snap = await firestore.collection('service').doc('conf').get();
      return Conf.fromDocument(snap);
    }

    test('parses admins list', () async {
      final conf = await makeConf({
        'admins': ['uid1', 'uid2'],
      });
      expect(conf.admins, ['uid1', 'uid2']);
    });

    test('defaults admins to empty when field is missing', () async {
      final conf = await makeConf({'uiVersion': '1'});
      expect(conf.admins, isEmpty);
    });

    test('parses uiVersion', () async {
      final conf = await makeConf({'uiVersion': '0.2.2+1'});
      expect(conf.uiVersion, '0.2.2+1');
    });

    test('defaults uiVersion to empty string when field is missing', () async {
      final conf = await makeConf({'admins': []});
      expect(conf.uiVersion, '');
    });

    test('parses gengos sorted ascending by date', () async {
      final conf = await makeConf({
        'gengos': [
          {'year': 2019, 'month': 5, 'day': 1, 'name': '令和', 'short': 'R'},
          {'year': 1989, 'month': 1, 'day': 8, 'name': '平成', 'short': 'H'},
        ],
      });
      expect(conf.gengos.length, 2);
      expect(conf.gengos[0].name, '平成'); // 1989 before 2019
      expect(conf.gengos[0].date, Cal(1989, 1, 8));
      expect(conf.gengos[1].name, '令和');
      expect(conf.gengos[1].date, Cal(2019, 5, 1));
    });

    test('defaults gengos to empty when field is missing', () async {
      final conf = await makeConf({'admins': []});
      expect(conf.gengos, isEmpty);
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
      expect(conf!.uiVersion, '2');
      expect(conf.admins, isEmpty);
      expect(conf.gengos, isEmpty);
    });
  });
}
