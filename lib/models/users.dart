import 'dart:async';

import 'package:flutter/material.dart' show ThemeMode, debugPrint;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:fpdart/fpdart.dart';

import 'package:robanokyuka/config/firebase.dart';
import 'package:robanokyuka/services/authentication.dart';
import 'package:robanokyuka/services/authorization.dart';

class User {
  final String id;
  final String name;
  final bool showNengo;
  final ThemeMode themeMode;
  final DateTime? disabledAt;

  User({
    required this.id,
    required this.name,
    this.showNengo = false,
    this.themeMode = ThemeMode.system,
    this.disabledAt,
  });

  factory User.fromDocument(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return User(
      id: doc.id,
      name: "${data['name'] ?? ''}",
      showNengo: data['showNengo'] ?? false,
      themeMode: ThemeMode.values.firstWhere(
        (e) => e.name == (data['themeMode'] ?? 'system'),
        orElse: () => ThemeMode.system,
      ),
      disabledAt: data['disabledAt'] != null
          ? (data['disabledAt'] as Timestamp).toDate()
          : null,
    );
  }
}

Stream<List<User>> usersStream(Ref ref) {
  final uid = ref.watch(
    authUserProvider.select((authUser) => authUser.asData?.value?.uid),
  );
  debugPrint('privilege: ${ref.watch(privilegeProvider).toString()}');
  final usersRef = ref.watch(firestoreProvider).collection('users');

  return switch (ref.watch(privilegeProvider)) {
    Privilege.loading => Stream.value([]),
    Privilege.guest => Stream.value([]),
    Privilege.user =>
      usersRef.doc(uid).snapshots().map((doc) => [User.fromDocument(doc)]),
    Privilege.admin => usersRef.snapshots().map(
      (snapshot) => snapshot.docs
          .map((doc) => User.fromDocument(doc))
          .toList(growable: false),
    ),
  };
}

final usersProvider = StreamProvider<List<User>>(usersStream);

final userProvider = Provider<User?>((ref) {
  final uid = ref.watch(
    authUserProvider.select((authUser) => authUser.asData?.value?.uid),
  );
  if (uid == null) return null;
  final users = ref.watch(usersProvider).asData?.value ?? [];
  return users.where((u) => u.id == uid).firstOrNull;
});

Future<Either<String, Unit>> updateUser(
  FirebaseFirestore db,
  String id,
  Map<String, dynamic> data,
) async {
  try {
    await db.collection('users').doc(id).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return right(unit);
  } catch (error, stackTrace) {
    debugPrint('Error updating user: $error\n$stackTrace');
    return left('$error');
  }
}

Future<Either<String, Unit>> updateUserName(
  FirebaseFirestore db,
  String id,
  String name,
) async => updateUser(db, id, {'name': name});

Future<Either<String, Unit>> updateUserShowNengo(
  FirebaseFirestore db,
  String id,
  bool showNengo,
) async => updateUser(db, id, {'showNengo': showNengo});

Future<Either<String, Unit>> updateUserThemeMode(
  FirebaseFirestore db,
  String id,
  ThemeMode themeMode,
) async =>
    updateUser(db, id, {'themeMode': themeMode.toString().split('.').last});

Future<Either<String, Unit>> deleteUserData(
  FirebaseFirestore db,
  String uid,
) async {
  try {
    final userRef = db.collection('users').doc(uid);
    await userRef.collection('records').get().then((snapshot) {
      for (final doc in snapshot.docs) {
        doc.reference.delete();
      }
    });
    await userRef.delete();
    return right(unit);
  } catch (error, stackTrace) {
    debugPrint('Error deleting user data: $error\n$stackTrace');
    return left('$error');
  }
}

Future<Either<String, Unit>> addUserByAdmin(
  CallFunction callFunction,
  String email, {
  String? name,
}) async {
  try {
    await callFunction(
      'addUser',
      name == null ? {'email': email} : {'email': email, 'name': name},
    );
    return right(unit);
  } catch (error, stackTrace) {
    debugPrint('Error adding user: $error\n$stackTrace');
    return left('$error');
  }
}

Future<Either<String, Unit>> updateUserByAdmin(
  FirebaseFirestore db,
  String id,
  String name,
  bool disabled,
) async {
  try {
    await db.collection('users').doc(id).update({
      'name': name,
      'disabledAt': disabled ? FieldValue.serverTimestamp() : null,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return right(unit);
  } catch (error, stackTrace) {
    debugPrint('Error updating user by admin: $error\n$stackTrace');
    return left('$error');
  }
}

Future<Either<String, Unit>> deleteUserByAdmin(
  CallFunction callFunction,
  String uid,
) async {
  try {
    await callFunction('deleteUser', {'uid': uid});
    return right(unit);
  } catch (error, stackTrace) {
    debugPrint('Error deleting user: $error\n$stackTrace');
    return left('$error');
  }
}
