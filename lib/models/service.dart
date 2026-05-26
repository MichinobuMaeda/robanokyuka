import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart' show debugPrint;
import 'package:fpdart/fpdart.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:robanokyuka/config/firebase.dart';
import 'package:robanokyuka/services/authentication.dart';
import 'package:robanokyuka/models/cal_date.dart';

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

class Gengo {
  final Cal date;
  final String name;
  final String short;

  Gengo({required this.date, required this.name, required this.short});
}

class Conf {
  final List<String> admins;
  final List<Gengo> gengos;
  final String uiVersion;
  final String androidVersion;
  final String iosVersion;

  Conf({
    required this.admins,
    required this.gengos,
    required this.uiVersion,
    required this.androidVersion,
    required this.iosVersion,
  });

  factory Conf.fromDocument(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Conf(
      admins: List<String>.from(
        (data['admins'] ?? []) as List,
      ).whereType<String>().toList(),
      gengos:
          ((data['gengos'] ?? []) as List)
              .map(
                (item) => Gengo(
                  date: Cal(
                    item['year'] as int,
                    item['month'] as int,
                    item['day'] as int,
                  ),
                  name: item['name'] as String,
                  short: item['short'] as String,
                ),
              )
              .toList()
            ..sort((a, b) => a.date.compareTo(b.date)),
      uiVersion: data['uiVersion'] ?? '',
      androidVersion: data['androidVersion'] ?? '0.0.0+0',
      iosVersion: data['iosVersion'] ?? '0.0.0+0',
    );
  }
}

final confProvider = Provider<Conf?>((ref) {
  final service = ref.watch(serviceProvider);
  return service.asData?.value?.docs.any((doc) => doc.id == 'conf') == true
      ? Conf.fromDocument(
          service.asData!.value!.docs.firstWhere((doc) => doc.id == 'conf'),
        )
      : null;
});

List<String> selectAdmins(Conf? conf) => conf?.admins ?? [];

Future<Either<String, Unit>> setVersions(
  FirebaseFirestore db, {
  required String uiVersion,
  required String androidVersion,
  required String iosVersion,
}) async {
  try {
    await db.collection('service').doc('conf').update({
      'uiVersion': uiVersion,
      'androidVersion': androidVersion,
      'iosVersion': iosVersion,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return right(unit);
  } catch (error, stackTrace) {
    debugPrint('Error setting versions: $error\n$stackTrace');
    return left('$error');
  }
}

Future<Either<String, Unit>> setGengos(
  FirebaseFirestore db,
  List<Gengo> gengos,
) async {
  try {
    final data = (gengos..sort((a, b) => a.date.compareTo(b.date)))
        .map(
          (g) => {
            'year': g.date.year,
            'month': g.date.month,
            'day': g.date.day,
            'name': g.name,
            'short': g.short,
          },
        )
        .toList();
    await db.collection('service').doc('conf').update({
      'gengos': data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return right(unit);
  } catch (error, stackTrace) {
    debugPrint('Error setting gengos: $error\n$stackTrace');
    return left('$error');
  }
}
