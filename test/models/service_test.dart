import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:yukyuchecker/config/firebase.dart';
import 'package:yukyuchecker/models/service.dart';
import 'package:yukyuchecker/services/authentication.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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
