import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

const emailFrom = "noreply@robanokyuka.firebaseapp.com";

const String functionsRegion = 'asia-northeast2';

FirebaseOptions firebaseConfig = FirebaseOptions(
  apiKey: "FIREBASE_API_KEY",
  authDomain: "robanokyuka.firebaseapp.com",
  projectId: "robanokyuka",
  storageBucket: "robanokyuka.firebasestorage.app",
  messagingSenderId: "506698003908",
  appId: "1:506698003908:web:17437702a35ccbfbdf2091",
  measurementId: "G-0YGD503CHF",
);

Future<void> initializeFirebase() async {
  try {
    await Firebase.initializeApp(options: firebaseConfig);
    await FirebaseAuth.instance.setLanguageCode("ja");

    if (kDebugMode) {
      String host = defaultTargetPlatform == TargetPlatform.android
          ? '10.0.2.2'
          : 'localhost';
      await FirebaseAuth.instance.useAuthEmulator(host, 9099);
      FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
      FirebaseFunctions.instanceFor(
        region: functionsRegion,
      ).useFunctionsEmulator(host, 5001);
    }
  } on FirebaseException catch (e) {
    if (e.code != 'duplicate-app') rethrow;
  }
}

FirebaseAuth auth() => FirebaseAuth.instance;
FirebaseFirestore db() => FirebaseFirestore.instance;

final firestoreProvider = Provider<FirebaseFirestore>(
  (ref) => FirebaseFirestore.instance,
);

typedef CallFunction =
    Future<Map<String, dynamic>> Function(
      String name,
      Map<String, dynamic> data,
    );
Future<Map<String, dynamic>> callFunction(
  String name,
  Map<String, dynamic> data,
) async {
  final result = await FirebaseFunctions.instanceFor(
    region: functionsRegion,
  ).httpsCallable(name).call(data);
  return result.data as Map<String, dynamic>;
}
