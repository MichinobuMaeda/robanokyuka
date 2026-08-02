import 'package:flutter/widgets.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:robanokyuka/config/firebase.dart';

import 'package:robanokyuka/platform/platforms.dart';
import 'package:robanokyuka/services/helpers.dart';

const keyEmailForSignIn = 'robanokyuka_email_for_sign_in';

enum FederatedProvider {
  google,
  apple;

  String get name => switch (this) {
    FederatedProvider.google => 'Google',
    FederatedProvider.apple => 'Apple',
  };
}

AuthProvider getProvider(FederatedProvider provider) => switch (provider) {
  // https://www.googleapis.com/auth/userinfo.email and
  // https://www.googleapis.com/auth/userinfo.profile are included by default,
  // so we don't need to add them explicitly.
  FederatedProvider.google => GoogleAuthProvider(),
  FederatedProvider.apple => AppleAuthProvider(),
};

class FirebaseAuthNotifier extends Notifier<FirebaseAuth?> {
  @override
  FirebaseAuth? build() => null;

  void setAuth(FirebaseAuth? auth) {
    debugPrint("FirebaseAuthNotifier ${auth != null ? "set" : "reset"}");
    state = auth;
  }
}

final firebaseAuthProvider =
    NotifierProvider<FirebaseAuthNotifier, FirebaseAuth?>(
      FirebaseAuthNotifier.new,
    );

@visibleForTesting
Future<void> sendEmailVerification(Ref ref, User authUser) async {
  await authUser.sendEmailVerification();
  final message = ref.read(snackBarMessageProvider.notifier);
  message.show("メールアドレスの確認のためのメールを送信しました。");
  await ref.read(authProvider).signOut();
}

@visibleForTesting
User? checkEmailVerification(Ref ref, User? user) {
  debugPrint("checkEmailVerification: user=${user?.uid}");
  if (user != null && !user.emailVerified) {
    sendEmailVerification(ref, user);
    return null;
  }
  return user;
}

final authUserProvider = StreamProvider<User?>(
  (ref) =>
      ref
          .watch(firebaseAuthProvider)
          ?.authStateChanges()
          .map((user) => checkEmailVerification(ref, user)) ??
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

Future<Either<String, Unit>> signOut(FirebaseAuth auth) async {
  try {
    await auth.signOut();
    return right(unit);
  } catch (error, stackTrace) {
    debugPrint('Error signing out: $error\n$stackTrace');
    return left('$error');
  }
}

Future<Either<String, Unit>> registerNewUser(
  FirebaseAuth auth,
  String email,
  String password,
) async {
  try {
    await auth.createUserWithEmailAndPassword(email: email, password: password);
    return right(unit);
  } catch (error, stackTrace) {
    debugPrint('Error registering user: $error\n$stackTrace');
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

Future<OAuthCredential> signInWithGoogle(
  FirebaseAuth auth,
  Future<String> Function() getGoogleIdToken,
) async {
  final idToken = await getGoogleIdToken();
  return GoogleAuthProvider.credential(idToken: idToken);
}

Future<Either<String, Unit>> signInWithProvider(
  FirebaseAuth auth,
  FederatedProvider provider,
  AppEnvironment environment, {
  @visibleForTesting Future<String> Function()? getGoogleIdTokenFn,
}) async {
  try {
    switch (environment) {
      case AppEnvironment.web || AppEnvironment.pwa:
        await auth.signInWithPopup(getProvider(provider));
        break;
      case AppEnvironment.android || AppEnvironment.ios:
        switch (provider) {
          case FederatedProvider.google:
            final credential = await signInWithGoogle(
              auth,
              getGoogleIdTokenFn ?? getGoogleIdToken,
            );
            await auth.signInWithCredential(credential);
            break;
          case FederatedProvider.apple:
            await FirebaseAuth.instance.signInWithProvider(getProvider(provider));
            break;
        }
        break;
      default:
        throw UnsupportedError('Unsupported platform for federated sign-in');
    }
    return right(unit);
  } catch (error, stackTrace) {
    debugPrint('Error signing in with ${provider.name}: $error\n$stackTrace');
    return left('$error');
  }
}

Future<Either<String, Unit>> reauthenticateWithProvider(
  FirebaseAuth auth,
  FederatedProvider provider,
  AppEnvironment environment, {
  @visibleForTesting Future<String> Function()? getGoogleIdTokenFn,
}) async {
  try {
    final user = auth.currentUser;
    if (user == null) {
      return left('No authenticated user.');
    }
    switch (environment) {
      case AppEnvironment.web || AppEnvironment.pwa:
        await user.reauthenticateWithPopup(getProvider(provider));
        break;
      case AppEnvironment.android || AppEnvironment.ios:
        switch (provider) {
          case FederatedProvider.google:
            final credential = await signInWithGoogle(
              auth,
              getGoogleIdTokenFn ?? getGoogleIdToken,
            );
            await user.reauthenticateWithCredential(credential);
            break;
          case FederatedProvider.apple:
            final credential = await FirebaseAuth.instance.signInWithProvider(
              getProvider(provider),
            );
            if (credential.credential != null) {
              await user.reauthenticateWithCredential(credential.credential!);
            }
            break;
        }
        break;
      default:
        throw UnsupportedError('Unsupported platform for federated sign-in');
    }
    return right(unit);
  } catch (error, stackTrace) {
    debugPrint(
      'Error reauthenticating with ${provider.name}: $error\n$stackTrace',
    );
    return left('$error');
  }
}
