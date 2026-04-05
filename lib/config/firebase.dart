import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

const emailFrom = "noreply@yukyuchecker.firebaseapp.com";

const _flutterEnv = String.fromEnvironment('FLUTTER_ENV');

const String functionsRegion = 'asia-northeast2';

FirebaseOptions firebaseConfig = FirebaseOptions(
  apiKey: "FIREBASE_API_KEY",
  authDomain: "yukyuchecker.firebaseapp.com",
  projectId: "yukyuchecker",
  storageBucket: "yukyuchecker.firebasestorage.app",
  messagingSenderId: "823109354081",
  appId: "1:823109354081:web:36d1a10d8e80b0e9d8e020",
  measurementId: "G-5EWNJZNW19",
);

Future<void> initializeFirebase() async {
  await Firebase.initializeApp(options: firebaseConfig);
  await FirebaseAuth.instance.setLanguageCode("ja");

  if (_flutterEnv == 'development') {
    await FirebaseAuth.instance.useAuthEmulator("localhost", 9099);
    FirebaseFirestore.instance.useFirestoreEmulator("localhost", 8080);
    FirebaseFunctions.instanceFor(
      region: functionsRegion,
    ).useFunctionsEmulator("localhost", 5001);
  }
}
