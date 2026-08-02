import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import 'firebase_config.dart';

const String emailFrom = "noreply@robanokyuka.firebaseapp.com";
const String functionsRegion = 'asia-northeast2';
final String emulatorHost = kIsWeb
    ? 'localhost'
    : (Platform.isAndroid ? '10.0.2.2' : 'localhost');
const int emulatorAuthPort = 9099;
const int emulatorFirestorePort = 8080;
const int emulatorFunctionsPort = 5001;

Future<void> initializeFirebase() async {
  try {
    debugPrint("Firebase.initializeApp()");
    await Firebase.initializeApp(
      options: FirebaseOptions(
        apiKey: firebaseConfig['apiKey']!,
        authDomain: firebaseConfig['authDomain']!,
        projectId: firebaseConfig['projectId']!,
        storageBucket: firebaseConfig['storageBucket']!,
        messagingSenderId: firebaseConfig['messagingSenderId']!,
        appId: firebaseConfig['appId']!,
        measurementId: firebaseConfig['measurementId']!,
      ),
    );
  } on FirebaseException catch (e) {
    if (e.code != 'duplicate-app') {
      debugPrint("initializeFirebase: ${e.toString()}");
    }
  } finally {
    debugPrint("setLanguageCode('ja')");
    await FirebaseAuth.instance.setLanguageCode("ja");

    debugPrint("kDebugMode: $kDebugMode");
    if (kDebugMode) {
      try {
        await FirebaseAuth.instance.useAuthEmulator(
          emulatorHost,
          emulatorAuthPort,
        );
        debugPrint("Auth Emulator: $emulatorHost:$emulatorAuthPort");
        FirebaseFirestore.instance.useFirestoreEmulator(
          emulatorHost,
          emulatorFirestorePort,
        );
        debugPrint("Firestore Emulator: $emulatorHost:$emulatorFirestorePort");
        FirebaseFunctions.instanceFor(
          region: functionsRegion,
        ).useFunctionsEmulator(emulatorHost, emulatorFunctionsPort);
        debugPrint("Functions Emulator: $emulatorHost:$emulatorFunctionsPort");
      } catch (e) {
        debugPrint("initializeFirebase: ${e.toString()}");
      }
    }
  }
}

final authProvider = Provider<FirebaseAuth>((ref) => FirebaseAuth.instance);

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
