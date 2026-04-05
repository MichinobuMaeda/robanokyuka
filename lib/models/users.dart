import 'package:flutter/widgets.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'dart:async';

import '../config/firebase.dart';
import '../services/authentication.dart';
import '../services/authorization.dart';

class User {
  final String id;
  final String name;
  final DateTime? disabledAt;

  User({required this.id, required this.name, this.disabledAt});

  factory User.fromDocument(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return User(
      id: doc.id,
      name: "${data['name'] ?? ''}",
      disabledAt: data['disabledAt'] != null
          ? (data['disabledAt'] as Timestamp).toDate()
          : null,
    );
  }
}

final usersRef = FirebaseFirestore.instance.collection('users');

final usersProvider = StreamProvider<List<User>>((ref) {
  final uid = ref.watch(authUserProvider.select(selectUid));
  debugPrint('privilege: ${ref.watch(privilegeProvider).toString()}');
  return switch (ref.watch(privilegeProvider)) {
    Privilege.loading => Stream.value([]),
    Privilege.guest => Stream.value([]),
    Privilege.user =>
      usersRef.doc(uid).snapshots().map((doc) => [User.fromDocument(doc)]),
    Privilege.admin => usersRef.snapshots().map((snapshot) {
      debugPrint('users snapshot.docs: ${snapshot.docs.length}');
      final users = <User>[];
      for (final doc in snapshot.docs) {
        try {
          users.add(User.fromDocument(doc));
        } catch (e, st) {
          debugPrintStack(
            label: 'User.fromDocument error for ${doc.id}: $e',
            stackTrace: st,
          );
        }
      }
      return users;
    }),
  };
});

final recordsProvider = StreamProvider<QuerySnapshot<Map<String, dynamic>>?>((
  ref,
) {
  final uid = ref.watch(authUserProvider.select(selectUid));
  final userRef = usersRef.doc(uid);
  return (uid == null)
      ? Stream.value(null)
      : userRef.collection('records').snapshots();
});

Future<Either<String, Unit>> deleteUserData(String uid) async {
  try {
    final userRef = usersRef.doc(uid);
    await userRef.collection('records').get().then((snapshot) {
      for (final doc in snapshot.docs) {
        doc.reference.delete();
      }
    });
    await userRef.delete();
    return right(unit);
  } catch (error, stackTrace) {
    debugPrintStack(
      label: 'Error deleting user data: $error',
      stackTrace: stackTrace,
    );
    return left('$error');
  }
}

Future<Either<String, Unit>> addUserByAdmin(
  String email, {
  String? name,
}) async {
  try {
    await FirebaseFunctions.instanceFor(region: functionsRegion)
        .httpsCallable('addUser')
        .call(name == null ? {'email': email} : {'email': email, 'name': name});
    return right(unit);
  } catch (error, stackTrace) {
    debugPrintStack(label: 'Error adding user: $error', stackTrace: stackTrace);
    return left('$error');
  }
}

Future<Either<String, Unit>> deleteUserByAdmin(String uid) async {
  try {
    await FirebaseFunctions.instanceFor(
      region: functionsRegion,
    ).httpsCallable('deleteUser').call({'uid': uid});
    return right(unit);
  } catch (error, stackTrace) {
    debugPrintStack(
      label: 'Error deleting user: $error',
      stackTrace: stackTrace,
    );
    return left('$error');
  }
}

Future<Either<String, Unit>> updateUser(String id, String name) async {
  try {
    await usersRef.doc(id).update({
      'name': name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return right(unit);
  } catch (error, stackTrace) {
    debugPrintStack(
      label: 'Error updating user: $error',
      stackTrace: stackTrace,
    );
    return left('$error');
  }
}

Future<Either<String, Unit>> updateUserByAdmin(
  String id,
  String name,
  bool disabled,
) async {
  try {
    await usersRef.doc(id).update({
      'name': name,
      'disabledAt': disabled ? FieldValue.serverTimestamp() : null,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return right(unit);
  } catch (error, stackTrace) {
    debugPrintStack(
      label: 'Error updating user: $error',
      stackTrace: stackTrace,
    );
    return left('$error');
  }
}
