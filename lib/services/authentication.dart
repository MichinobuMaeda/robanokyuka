import 'package:flutter/widgets.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:fpdart/fpdart.dart';

const keyEmailForSignIn = 'yukyuchecker_email_for_sign_in';

final authUserProvider = StreamProvider<User?>(
  (_) => FirebaseAuth.instance.authStateChanges(),
);

String? selectUid(AsyncValue<User?> authUser) => authUser.asData?.value?.uid;

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

Future<void> handleEmailLink() async {
  final url = Uri.base.toString();
  debugPrint(url);

  if (FirebaseAuth.instance.isSignInWithEmailLink(url)) {
    try {
      final prefs = SharedPreferencesAsync();
      final email = await prefs.getString(keyEmailForSignIn);
      await prefs.remove(keyEmailForSignIn);

      if (email == null) {
        debugPrint('No email found in shared preferences for sign-in.');
      } else {
        debugPrint('Attempting to sign in with email: $email and link: $url');
        await FirebaseAuth.instance.signInWithEmailLink(
          email: email,
          emailLink: url,
        );
      }
    } catch (error, stackTrace) {
      debugPrintStack(
        label: 'Error signing in with email link: $error',
        stackTrace: stackTrace,
      );
    } finally {
      final redirectUrl = getBaseUrl(url);
      debugPrint('Launching URL without query string: $redirectUrl');
      await launchUrl(Uri.parse(redirectUrl), webOnlyWindowName: '_self');
    }
  }
}

Future<Either<String, Unit>> sendSignInLinkToEmail(String email) async {
  try {
    await FirebaseAuth.instance.sendSignInLinkToEmail(
      email: email,
      actionCodeSettings: ActionCodeSettings(
        url: getBaseUrl(Uri.base.toString()),
        handleCodeInApp: true,
      ),
    );
    final prefs = SharedPreferencesAsync();
    await prefs.setString(keyEmailForSignIn, email);
    return right(unit);
  } catch (error, stackTrace) {
    debugPrintStack(
      label: 'Error sending sign-in link: $error',
      stackTrace: stackTrace,
    );
    return left('$error');
  }
}

Future<Either<String, Unit>> sendPasswordResetEmail(String? email) async {
  try {
    await FirebaseAuth.instance.sendPasswordResetEmail(
      email: email ?? FirebaseAuth.instance.currentUser?.email ?? '',
      actionCodeSettings: ActionCodeSettings(
        url: getBaseUrl(Uri.base.toString()),
        handleCodeInApp: false,
      ),
    );
    return right(unit);
  } catch (error, stackTrace) {
    debugPrintStack(
      label: 'Error sending password reset email: $error',
      stackTrace: stackTrace,
    );
    return left('$error');
  }
}

Future<Either<String, Unit>> signInWithEmailAndPassword(
  String email,
  String password,
) async {
  try {
    await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return right(unit);
  } catch (error, stackTrace) {
    debugPrintStack(
      label: 'Error signing in with email and password: $error',
      stackTrace: stackTrace,
    );
    return left('$error');
  }
}

Future<Either<String, Unit>> signInWithGoogle() async {
  try {
    final googleProvider = GoogleAuthProvider();

    googleProvider.addScope(
      'https://www.googleapis.com/auth/contacts.readonly',
    );
    await FirebaseAuth.instance.signInWithPopup(googleProvider);
    return right(unit);
  } catch (error, stackTrace) {
    debugPrintStack(
      label: 'Error signing in with Google: $error',
      stackTrace: stackTrace,
    );
    return left('$error');
  }
}

Future<Either<String, Unit>> signOut() async {
  try {
    await FirebaseAuth.instance.signOut();
    return right(unit);
  } catch (error, stackTrace) {
    debugPrintStack(label: 'Error signing out: $error', stackTrace: stackTrace);
    return left('$error');
  }
}

Future<Either<String, Unit>> reauthenticateWithPassword(
  String email,
  String password,
) async {
  try {
    final user = FirebaseAuth.instance.currentUser;
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
    debugPrintStack(
      label: 'Error reauthenticating with password: $error',
      stackTrace: stackTrace,
    );
    return left('$error');
  }
}

Future<Either<String, Unit>> reauthenticateWithGoogle() async {
  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return left('No authenticated user.');
    }
    final googleProvider = GoogleAuthProvider();
    await user.reauthenticateWithPopup(googleProvider);
    return right(unit);
  } catch (error, stackTrace) {
    debugPrintStack(
      label: 'Error reauthenticating with Google: $error',
      stackTrace: stackTrace,
    );
    return left('$error');
  }
}

Future<Either<String, Unit>> changeEmail(String email) async {
  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return left('No authenticated user.');
    }
    await user.verifyBeforeUpdateEmail(email);
    return right(unit);
  } catch (error, stackTrace) {
    debugPrintStack(
      label: 'Error changing email: $error',
      stackTrace: stackTrace,
    );
    return left('$error');
  }
}

Future<Either<String, Unit>> deleteUser() async {
  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return left('No authenticated user.');
    }

    await user.delete();
    return right(unit);
  } catch (error, stackTrace) {
    debugPrintStack(
      label: 'Error deleting user: $error',
      stackTrace: stackTrace,
    );
    return left('$error');
  }
}
