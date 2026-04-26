import 'package:flutter/widgets.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:fpdart/fpdart.dart';

import '../config/firebase.dart';
import '../services/authentication.dart';
import '../services/helpers.dart';
import './gengo.dart';

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

final gengosProvider = Provider<List<Gengo>>((ref) {
  final conf = ref.watch(confProvider);
  final data = conf?.data();
  if (data != null && data['gengos'] is List) {
    return (data['gengos'] as List)
        .whereType<Map<String, dynamic>>()
        .where(
          (item) =>
              item.containsKey('year') &&
              item.containsKey('month') &&
              item.containsKey('day') &&
              item.containsKey('name') &&
              item.containsKey('short') &&
              item['year'] is int &&
              item['month'] is int &&
              item['day'] is int &&
              item['name'] is String &&
              item['short'] is String &&
              item['year'] > 0 &&
              item['month'] >= 1 &&
              item['month'] <= 12 &&
              item['day'] >= 1 &&
              item['day'] <= 31 &&
              item['name'].isNotEmpty &&
              item['short'].isNotEmpty,
        )
        .map((item) {
          final y = item['year'] as int;
          final m = item['month'] as int;
          final d = item['day'] as int;
          return Gengo(
            date: formatYmd(y, m, d),
            name: item['name'] as String,
            short: item['short'] as String,
          );
        })
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }
  return [];
});

class Holiday implements Comparable<Holiday> {
  final String date;
  final String name;

  Holiday({required this.date, required this.name});

  @override
  int compareTo(Holiday other) {
    return date.compareTo(other.date);
  }
}

final holidaysProvider = Provider<List<Holiday>>((ref) {
  final service = ref.watch(serviceProvider);
  return (service.hasError || service.value == null)
        ? []
        : service.value!.docs
              .where((doc) => RegExp(r'^y[0-9]{4}$').hasMatch(doc.id))
              .map((doc) {
                final year = int.parse(doc.id.substring(1, 5));
                final holidays = doc.data();
                return holidays.entries
                    .where((entry) => RegExp(r'^[0-9]{4}$').hasMatch(entry.key))
                    .map((entry) {
                      return Holiday(
                        date: '$year${entry.key}',
                        name: '${entry.value}',
                      );
                    })
                    .toList();
              })
              .expand((holidays) => holidays)
              .toList()
    ..sort();
});

String pad2(int n) => n.toString().padLeft(2, '0');
String yearId(int year) => 'y$year';
String mmdd(int month, int day) => pad2(month) + pad2(day);

Future<Either<String, Unit>> setHoliday(
  FirebaseFirestore db,
  Holiday holiday,
) async {
  try {
    final id = yearId(int.parse(holiday.date.substring(0, 4)));
    final key = holiday.date.substring(4);
    await db.collection('service').doc(id).set({
      key: holiday.name,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    return right(unit);
  } catch (error, stackTrace) {
    debugPrint('Error setting holiday: $error\n$stackTrace');
    return left('$error');
  }
}

Future<Either<String, Unit>> deleteHoliday(
  FirebaseFirestore db,
  Holiday holiday,
) async {
  try {
    final id = yearId(int.parse(holiday.date.substring(0, 4)));
    final key = holiday.date.substring(4);
    await db.collection('service').doc(id).update({
      key: FieldValue.delete(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return right(unit);
  } catch (error, stackTrace) {
    debugPrint('Error deleting holiday: $error\n$stackTrace');
    return left('$error');
  }
}
