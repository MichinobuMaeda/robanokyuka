import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:yukyuchecker/config/firebase.dart';
import 'package:yukyuchecker/models/users.dart';
import 'package:yukyuchecker/services/authentication.dart';
import 'package:yukyuchecker/services/authorization.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('User', () {
    test('defaults showNengo to false', () {
      final user = User(id: 'u1', name: '山田太郎');
      expect(user.showNengo, isFalse);
    });

    test('stores id, name, and showNengo', () {
      final user = User(id: 'u2', name: '佐藤花子', showNengo: true);
      expect(user.id, 'u2');
      expect(user.name, '佐藤花子');
      expect(user.showNengo, isTrue);
    });

    test('stores disabledAt when provided', () {
      final dt = DateTime(2024, 6, 1);
      final user = User(id: 'u3', name: 'test', disabledAt: dt);
      expect(user.disabledAt, dt);
    });
  });

  group('User.fromDocument', () {
    test('parses all fields from a Firestore document', () async {
      final firestore = FakeFirebaseFirestore();
      final disabledAt = DateTime(2024, 6, 1);
      await firestore.collection('users').doc('u1').set({
        'name': '山田太郎',
        'showNengo': true,
        'disabledAt': Timestamp.fromDate(disabledAt),
      });
      final doc = await firestore.collection('users').doc('u1').get();

      final user = User.fromDocument(doc);

      expect(user.id, 'u1');
      expect(user.name, '山田太郎');
      expect(user.showNengo, isTrue);
      expect(user.disabledAt, disabledAt);
    });

    test(
      'defaults showNengo to false and disabledAt to null when absent',
      () async {
        final firestore = FakeFirebaseFirestore();
        await firestore.collection('users').doc('u2').set({'name': '佐藤花子'});
        final doc = await firestore.collection('users').doc('u2').get();

        final user = User.fromDocument(doc);

        expect(user.id, 'u2');
        expect(user.showNengo, isFalse);
        expect(user.disabledAt, isNull);
      },
    );

    test('uses empty string for missing name field', () async {
      final firestore = FakeFirebaseFirestore();
      await firestore.collection('users').doc('u3').set({'showNengo': false});
      final doc = await firestore.collection('users').doc('u3').get();

      final user = User.fromDocument(doc);

      expect(user.name, '');
    });
  });

  group('userProvider', () {
    test('returns null when uid is null', () async {
      final container = ProviderContainer(
        overrides: [
          authUserProvider.overrideWith((_) => Stream.value(null)),
          usersProvider.overrideWith((_) => Stream.value([])),
        ],
      );
      addTearDown(container.dispose);
      container.listen(authUserProvider, (_, _) {});
      await container.read(authUserProvider.future);

      expect(container.read(userProvider), isNull);
    });

    test('returns the matching user from usersProvider', () async {
      final alice = User(id: 'u1', name: 'Alice');
      final bob = User(id: 'u2', name: 'Bob');
      final container = ProviderContainer(
        overrides: [
          authUserProvider.overrideWith(
            (_) => Stream.value(MockUser(uid: 'u1', email: 'a@example.com')),
          ),
          usersProvider.overrideWith((_) => Stream.value([alice, bob])),
        ],
      );
      addTearDown(container.dispose);
      container.listen(authUserProvider, (_, _) {});
      container.listen(usersProvider, (_, _) {});
      await container.read(authUserProvider.future);
      await container.read(usersProvider.future);

      expect(container.read(userProvider), alice);
    });

    test('returns null when uid does not match any user', () async {
      final alice = User(id: 'u1', name: 'Alice');
      final container = ProviderContainer(
        overrides: [
          authUserProvider.overrideWith(
            (_) =>
                Stream.value(MockUser(uid: 'unknown', email: 'x@example.com')),
          ),
          usersProvider.overrideWith((_) => Stream.value([alice])),
        ],
      );
      addTearDown(container.dispose);
      container.listen(authUserProvider, (_, _) {});
      container.listen(usersProvider, (_, _) {});
      await container.read(authUserProvider.future);
      await container.read(usersProvider.future);

      expect(container.read(userProvider), isNull);
    });
  });

  group('deleteUserData', () {
    test('deletes records subcollection and user document', () async {
      final firestore = FakeFirebaseFirestore();
      final userRef = firestore.collection('users').doc('u1');
      await userRef.set({'name': 'Alice'});
      await userRef.collection('records').doc('r1').set({'from': '20240401'});
      await userRef.collection('records').doc('r2').set({'from': '20250401'});

      final result = await deleteUserData(firestore, 'u1');

      expect(result.isRight(), isTrue);
      final userSnap = await userRef.get();
      expect(userSnap.exists, isFalse);
      final records = await userRef.collection('records').get();
      expect(records.docs, isEmpty);
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

      final result = await deleteUserData(firestore, 'u1');

      expect(result.isLeft(), isTrue);
    });
  });

  group('updateUser', () {
    test('updates name and showNengo in Firestore', () async {
      final firestore = FakeFirebaseFirestore();
      await firestore.collection('users').doc('u1').set({
        'name': 'Old Name',
        'showNengo': false,
      });

      final result = await updateUser(
        firestore,
        'u1',
        'New Name',
        showNengo: true,
      );

      expect(result.isRight(), isTrue);
      final doc = await firestore.collection('users').doc('u1').get();
      expect(doc.data()!['name'], 'New Name');
      expect(doc.data()!['showNengo'], isTrue);
    });

    test('returns left when Firestore update fails', () async {
      final firestore = FakeFirebaseFirestore();
      final result = await updateUser(
        firestore,
        'nonexistent',
        'Name',
        showNengo: false,
      );
      expect(result.isLeft(), isTrue);
    });
  });

  group('updateUserByAdmin', () {
    test('updates name and clears disabledAt when disabled is false', () async {
      final firestore = FakeFirebaseFirestore();
      await firestore.collection('users').doc('u1').set({
        'name': 'Old Name',
        'disabledAt': Timestamp.now(),
      });

      final result = await updateUserByAdmin(
        firestore,
        'u1',
        'New Name',
        false,
      );

      expect(result.isRight(), isTrue);
      final doc = await firestore.collection('users').doc('u1').get();
      expect(doc.data()!['name'], 'New Name');
      expect(doc.data()!['disabledAt'], isNull);
    });

    test('sets disabledAt when disabled is true', () async {
      final firestore = FakeFirebaseFirestore();
      await firestore.collection('users').doc('u1').set({'name': 'Alice'});

      final result = await updateUserByAdmin(firestore, 'u1', 'Alice', true);

      expect(result.isRight(), isTrue);
      final doc = await firestore.collection('users').doc('u1').get();
      expect(doc.data()!['disabledAt'], isNotNull);
    });

    test('returns left when Firestore update fails', () async {
      final firestore = FakeFirebaseFirestore();
      final result = await updateUserByAdmin(
        firestore,
        'nonexistent',
        'Name',
        false,
      );
      expect(result.isLeft(), isTrue);
    });
  });

  // ---------------------------------------------------------------------------
  group('addUserByAdmin', () {
    Future<Map<String, dynamic>> Function(String, Map<String, dynamic>)
    makeCallFn({
      bool throws = false,
      List<(String, Map<String, dynamic>)>? log,
    }) {
      return (String name, Map<String, dynamic> data) async {
        log?.add((name, data));
        if (throws) throw Exception('functions error');
        return <String, dynamic>{};
      };
    }

    test('calls addUser callable and returns right on success', () async {
      final log = <(String, Map<String, dynamic>)>[];
      final result = await addUserByAdmin(
        makeCallFn(log: log),
        'test@example.com',
      );
      expect(result.isRight(), isTrue);
      expect(log, hasLength(1));
      expect(log[0].$1, 'addUser');
      expect(log[0].$2, {'email': 'test@example.com'});
    });

    test('includes name in params when provided', () async {
      final log = <(String, Map<String, dynamic>)>[];
      await addUserByAdmin(makeCallFn(log: log), 'a@b.com', name: 'Alice');
      expect(log[0].$2, {'email': 'a@b.com', 'name': 'Alice'});
    });

    test('returns left when callable throws', () async {
      final result = await addUserByAdmin(
        makeCallFn(throws: true),
        'test@example.com',
      );
      expect(result.isLeft(), isTrue);
    });
  });

  group('deleteUserByAdmin', () {
    Future<Map<String, dynamic>> Function(String, Map<String, dynamic>)
    makeCallFn({
      bool throws = false,
      List<(String, Map<String, dynamic>)>? log,
    }) {
      return (String name, Map<String, dynamic> data) async {
        log?.add((name, data));
        if (throws) throw Exception('functions error');
        return <String, dynamic>{};
      };
    }

    test('calls deleteUser callable and returns right on success', () async {
      final log = <(String, Map<String, dynamic>)>[];
      final result = await deleteUserByAdmin(makeCallFn(log: log), 'u1');
      expect(result.isRight(), isTrue);
      expect(log[0].$1, 'deleteUser');
      expect(log[0].$2, {'uid': 'u1'});
    });

    test('returns left when callable throws', () async {
      final result = await deleteUserByAdmin(makeCallFn(throws: true), 'u1');
      expect(result.isLeft(), isTrue);
    });
  });

  // ---------------------------------------------------------------------------
  group('usersProviderImplementation / usersProvider', () {
    ProviderContainer makeContainer(
      FakeFirebaseFirestore firestore,
      Privilege privilege, {
      String? uid,
    }) {
      final container = ProviderContainer(
        overrides: [
          firestoreProvider.overrideWithValue(firestore),
          privilegeProvider.overrideWithValue(privilege),
          authUserProvider.overrideWith(
            (_) => Stream.value(
              uid == null
                  ? null
                  : MockUser(uid: uid, email: 'test@example.com'),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);
      return container;
    }

    test('emits [] for Privilege.loading', () async {
      final container = makeContainer(
        FakeFirebaseFirestore(),
        Privilege.loading,
      );
      container.listen(usersProvider, (_, _) {});
      final users = await container.read(usersProvider.future);
      expect(users, isEmpty);
    });

    test('emits [] for Privilege.guest', () async {
      final container = makeContainer(FakeFirebaseFirestore(), Privilege.guest);
      container.listen(usersProvider, (_, _) {});
      final users = await container.read(usersProvider.future);
      expect(users, isEmpty);
    });

    test('emits the signed-in user for Privilege.user', () async {
      final firestore = FakeFirebaseFirestore();
      await firestore.collection('users').doc('u1').set({
        'name': 'Alice',
        'showNengo': true,
      });
      final container = makeContainer(firestore, Privilege.user, uid: 'u1');
      container.listen(usersProvider, (_, _) {});
      final users = await container.read(usersProvider.future);
      expect(users, hasLength(1));
      expect(users[0].id, 'u1');
      expect(users[0].name, 'Alice');
      expect(users[0].showNengo, isTrue);
    });

    test('emits all users for Privilege.admin', () async {
      final firestore = FakeFirebaseFirestore();
      await firestore.collection('users').doc('u1').set({
        'name': 'Alice',
        'showNengo': false,
      });
      await firestore.collection('users').doc('u2').set({
        'name': 'Bob',
        'showNengo': false,
      });
      final container = makeContainer(firestore, Privilege.admin, uid: 'u1');
      container.listen(usersProvider, (_, _) {});
      final users = await container.read(usersProvider.future);
      expect(users, hasLength(2));
      final names = users.map((u) => u.name).toList()..sort();
      expect(names, ['Alice', 'Bob']);
    });
  });
}
