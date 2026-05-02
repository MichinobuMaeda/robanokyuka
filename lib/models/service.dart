import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../config/firebase.dart';
import '../services/authentication.dart';

Stream<QuerySnapshot<Map<String, dynamic>>?> serviceStream(Ref ref) {
  final uid = ref.watch(
    authUserProvider.select((authUser) => authUser.asData?.value?.uid),
  );
  return (uid == null)
      ? Stream.value(null)
      : ref.watch(firestoreProvider).collection('service').snapshots();
}

final serviceProvider = StreamProvider<QuerySnapshot<Map<String, dynamic>>?>(
  serviceStream,
);

final confProvider = Provider<DocumentSnapshot<Map<String, dynamic>>?>((ref) {
  final service = ref.watch(serviceProvider);
  return service.asData?.value?.docs.any((doc) => doc.id == 'conf') == true
      ? service.asData?.value?.docs.firstWhere((doc) => doc.id == 'conf')
      : null;
});

final adminsProvider = Provider<List<String>>((ref) {
  final conf = ref.watch(confProvider);
  final data = conf?.data();
  return (data != null && data['admins'] is List)
      ? List<String>.from((data['admins'] as List).whereType<String>())
      : <String>[];
});

final uiVersionProvider = Provider<String?>((ref) {
  final conf = ref.watch(confProvider);
  final data = conf?.data();
  return (data != null && data['uiVersion'] is String)
      ? data['uiVersion'] as String
      : null;
});
