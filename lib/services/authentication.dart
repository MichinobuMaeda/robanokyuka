import 'package:flutter/widgets.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import '../platform/platforms.dart';

const keyEmailForSignIn = 'yukyuchecker_email_for_sign_in';

class FirebaseAuthNotifier extends Notifier<FirebaseAuth?> {
  @override
  FirebaseAuth? build() => null;

  void setAuth(FirebaseAuth? auth) {
    state = auth;
  }
}

final firebaseAuthProvider =
    NotifierProvider<FirebaseAuthNotifier, FirebaseAuth?>(
      FirebaseAuthNotifier.new,
    );

final authUserProvider = StreamProvider<User?>(
  (ref) =>
      ref.watch(firebaseAuthProvider)?.authStateChanges() ??
      const Stream.empty(),
);

String getBaseUrl(String url) {
  final uri = Uri.parse(url);
  final normalized = Uri(
    scheme: uri.scheme,
    host: uri.host,
    port: uri.hasPort ? uri.port : null,
    path: '/',
  );
  return normalized.toString();
}

/// Returns true if the URL was a sign-in link and was handled, false otherwise.
Future<bool> handleEmailLink(
  FirebaseAuth auth,
  LocalStorage storage,
  String url,
) async {
  debugPrint(url);
  bool isEmailLink = auth.isSignInWithEmailLink(url);

  if (isEmailLink) {
    try {
      final email = await storage.getString(keyEmailForSignIn);
      await storage.remove(keyEmailForSignIn);

      if (email == null) {
        debugPrint('No email found in shared preferences for sign-in.');
      } else {
        debugPrint('Attempting to sign in with email: $email and link: $url');
        await auth.signInWithEmailLink(email: email, emailLink: url);
      }
    } catch (error, stackTrace) {
      debugPrint('Error signing in with email link: $error\n$stackTrace');
    }
  }

  return isEmailLink;
}

Future<Either<String, Unit>> sendSignInLinkToEmail(
  FirebaseAuth auth,
  LocalStorage storage,
  String email,
) async {
  try {
    await auth.sendSignInLinkToEmail(
      email: email,
      actionCodeSettings: ActionCodeSettings(
        url: getBaseUrl(Uri.base.toString()),
        handleCodeInApp: true,
      ),
    );
    await storage.setString(keyEmailForSignIn, email);
    return right(unit);
  } catch (error, stackTrace) {
    debugPrint('Error sending sign-in link: $error\n$stackTrace');
    return left('$error');
  }
}

Future<Either<String, Unit>> sendPasswordResetEmail(
  FirebaseAuth auth,
  String? email,
) async {
  try {
    await auth.sendPasswordResetEmail(
      email: email ?? auth.currentUser?.email ?? '',
      actionCodeSettings: ActionCodeSettings(
        url: getBaseUrl(Uri.base.toString()),
        handleCodeInApp: false,
      ),
    );
    return right(unit);
  } catch (error, stackTrace) {
    debugPrint('Error sending password reset email: $error\n$stackTrace');
    return left('$error');
  }
}

Future<Either<String, Unit>> signInWithEmailAndPassword(
  FirebaseAuth auth,
  String email,
  String password,
) async {
  try {
    await auth.signInWithEmailAndPassword(email: email, password: password);
    return right(unit);
  } catch (error, stackTrace) {
    debugPrint('Error signing in with email and password: $error\n$stackTrace');
    return left('$error');
  }
}

Future<Either<String, Unit>> signInWithGoogle(FirebaseAuth auth) async {
  try {
    final googleProvider = GoogleAuthProvider();

    googleProvider.addScope(
      'https://www.googleapis.com/auth/contacts.readonly',
    );
    await auth.signInWithPopup(googleProvider);
    return right(unit);
  } catch (error, stackTrace) {
    debugPrint('Error signing in with Google: $error\n$stackTrace');
    return left('$error');
  }
}

Future<Either<String, Unit>> signOut(FirebaseAuth auth) async {
  try {
    await auth.signOut();
    return right(unit);
  } catch (error, stackTrace) {
    debugPrint('Error signing out: $error\n$stackTrace');
    return left('$error');
  }
}

Future<Either<String, Unit>> reauthenticateWithPassword(
  FirebaseAuth auth,
  String email,
  String password,
) async {
  try {
    final user = auth.currentUser;
    if (user == null) {
      return left('No authenticated user.');
    }
    final email = user.email;
    if (email == null) {
      return left('User has no email address.');
    }
    final credential = EmailAuthProvider.credential(
      email: email,
      password: password,
    );
    await user.reauthenticateWithCredential(credential);
    return right(unit);
  } catch (error, stackTrace) {
    debugPrint('Error reauthenticating with password: $error\n$stackTrace');
    return left('$error');
  }
}

Future<Either<String, Unit>> reauthenticateWithGoogle(FirebaseAuth auth) async {
  try {
    final user = auth.currentUser;
    if (user == null) {
      return left('No authenticated user.');
    }
    final googleProvider = GoogleAuthProvider();
    await user.reauthenticateWithPopup(googleProvider);
    return right(unit);
  } catch (error, stackTrace) {
    debugPrint('Error reauthenticating with Google: $error\n$stackTrace');
    return left('$error');
  }
}

Future<Either<String, Unit>> changeEmail(
  FirebaseAuth auth,
  String email,
) async {
  try {
    final user = auth.currentUser;
    if (user == null) {
      return left('No authenticated user.');
    }
    await user.verifyBeforeUpdateEmail(email);
    return right(unit);
  } catch (error, stackTrace) {
    debugPrint('Error changing email: $error\n$stackTrace');
    return left('$error');
  }
}

Future<Either<String, Unit>> deleteUser(FirebaseAuth auth) async {
  try {
    final user = auth.currentUser;
    if (user == null) {
      return left('No authenticated user.');
    }

    await user.delete();
    return right(unit);
  } catch (error, stackTrace) {
    debugPrint('Error deleting user: $error\n$stackTrace');
    return left('$error');
  }
}
