import 'package:flutter/widgets.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'dart:async';

import '../services/authentication.dart';

final confRef = FirebaseFirestore.instance.collection('service').doc('conf');

void confStateListener(WidgetRef ref) {
  if (ref.watch(confProvider).hasError) {
    debugPrint('Error loading conf: ${ref.watch(confProvider).error}');
    signOut();
  }
}

final uidProvider = Provider<String?>((ref) {
  final user = ref.watch(authUserProvider).asData?.value;
  return user?.uid;
});

final confProvider = StreamProvider<DocumentSnapshot<Map<String, dynamic>>?>((
  ref,
) {
  final uid = ref.watch(uidProvider);
  return (uid == null) ? Stream.value(null) : confRef.snapshots();
});

List<String> selectAdmins(
  AsyncValue<DocumentSnapshot<Map<String, dynamic>>?> conf,
) {
  final data = conf.asData?.value?.data();
  return (data != null && data['admins'] is List)
      ? List<String>.from((data['admins'] as List).whereType<String>())
      : <String>[];
}

String selectUiVersion(
  AsyncValue<DocumentSnapshot<Map<String, dynamic>>?> conf,
) {
  final data = conf.asData?.value?.data();
  return (data != null && data['uiVersion'] is String)
      ? data['uiVersion'] as String
      : '0.0.0+0';
}
