import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

const emailFrom = "noreply@robanokyuka.firebaseapp.com";

const _flutterEnv = String.fromEnvironment('FLUTTER_ENV');

const String functionsRegion = 'asia-northeast2';

FirebaseOptions firebaseConfig = FirebaseOptions(
  apiKey: "FIREBASE_API_KEY",
  authDomain: "robanokyuka.firebaseapp.com",
  projectId: "robanokyuka",
  storageBucket: "robanokyuka.firebasestorage.app",
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
