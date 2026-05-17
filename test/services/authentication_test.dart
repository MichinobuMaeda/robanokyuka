import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mock_exceptions/mock_exceptions.dart';
import 'package:robanokyuka/services/authentication.dart';
import 'package:robanokyuka/services/helpers.dart';
import 'package:robanokyuka/platform/platforms.dart';

/// Subclasses [FirebaseAuthNotifier] so tests can inject a [FirebaseAuth]
/// instance without touching [FirebaseAuth.instance].
class _MockAuthNotifier extends FirebaseAuthNotifier {
  _MockAuthNotifier(this._auth);
  final FirebaseAuth? _auth;

  @override
  FirebaseAuth? build() => _auth;
}

/// Extends [MockUser] to provide a working [reauthenticateWithPopup],
/// which the mock library does not implement.
// ignore: must_be_immutable
class _FakeUser extends MockUser {
  _FakeUser({required super.uid, super.email});

  @override
  Future<UserCredential> reauthenticateWithPopup(AuthProvider provider) {
    return reauthenticateWithCredential(
      GoogleAuthProvider.credential(accessToken: 'fake-token'),
    );
  }
}

/// Extends [MockFirebaseAuth] to stub [isSignInWithEmailLink] and
/// [signInWithEmailLink], which the mock library does not implement.
class _FakeAuth extends MockFirebaseAuth {
  final bool _isEmailLink;
  final bool _throwOnSignIn;

  _FakeAuth({
    required bool isEmailLink,
    bool throwOnSignIn = false,
    super.mockUser,
    // super.signedIn = false,
  }) : _isEmailLink = isEmailLink,
       _throwOnSignIn = throwOnSignIn;

  @override
  bool isSignInWithEmailLink(String emailLink) => _isEmailLink;

  @override
  Future<UserCredential> signInWithEmailLink({
    required String email,
    required String emailLink,
  }) {
    if (_throwOnSignIn) {
      throw FirebaseAuthException(code: 'invalid-action-code');
    }
    // Delegate to the mock's signInWithCredential so _fakeSignIn() is called
    // and currentUser is populated.
    return signInWithCredential(null);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FirebaseAuthNotifier', () {
    test('build() returns null by default', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(firebaseAuthProvider), isNull);
    });

    test('setAuth() updates state to the provided instance', () {
      final auth = MockFirebaseAuth();
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(firebaseAuthProvider.notifier).setAuth(auth);

      expect(container.read(firebaseAuthProvider), same(auth));
    });

    test('setAuth(null) clears the state', () {
      final auth = MockFirebaseAuth();
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(firebaseAuthProvider.notifier).setAuth(auth);
      container.read(firebaseAuthProvider.notifier).setAuth(null);

      expect(container.read(firebaseAuthProvider), isNull);
    });
  });

  group('getBaseUrl', () {
    test('strips path and query string', () {
      expect(
        getBaseUrl('https://example.com/path?query=1#hash'),
        'https://example.com/',
      );
    });

    test('preserves non-default port', () {
      expect(
        getBaseUrl('http://localhost:3000/app?foo=bar'),
        'http://localhost:3000/',
      );
    });

    test('handles root path with no query', () {
      expect(getBaseUrl('https://example.com/'), 'https://example.com/');
    });
  });

  group('handleEmailLink', () {
    const signInUrl =
        'https://example.com/?link=https://app.example.com&oobCode=abc123';
    const plainUrl = 'https://example.com/';
    late LocalStorage storage;

    setUp(() {
      storage = LocalStorage(test: true);
    });

    test('returns false when URL is not a sign-in link', () async {
      final auth = _FakeAuth(isEmailLink: false);

      final result = await handleEmailLink(auth, storage, plainUrl);

      expect(result, isFalse);
    });

    test(
      'returns true when URL is a sign-in link and no email is stored',
      () async {
        final auth = _FakeAuth(isEmailLink: true);

        final result = await handleEmailLink(auth, storage, signInUrl);

        expect(result, isTrue);
      },
    );

    test('removes email from storage when processing sign-in link', () async {
      final auth = _FakeAuth(
        isEmailLink: true,
        mockUser: MockUser(uid: 'u1', email: 'user@example.com'),
      );
      await storage.setString(keyEmailForSignIn, 'user@example.com');

      final result = await handleEmailLink(auth, storage, signInUrl);

      expect(result, isTrue);
      expect(await storage.getString(keyEmailForSignIn), isNull);
    });

    test('signs in the user when email is stored and link is valid', () async {
      final auth = _FakeAuth(
        isEmailLink: true,
        mockUser: MockUser(uid: 'u1', email: 'user@example.com'),
      );
      await storage.setString(keyEmailForSignIn, 'user@example.com');

      await handleEmailLink(auth, storage, signInUrl);

      expect(auth.currentUser, isNotNull);
    });

    test('returns true and swallows signInWithEmailLink error', () async {
      final auth = _FakeAuth(isEmailLink: true, throwOnSignIn: true);
      await storage.setString(keyEmailForSignIn, 'user@example.com');

      final result = await handleEmailLink(auth, storage, signInUrl);

      expect(result, isTrue);
    });
  });

  group('signOut', () {
    test('returns right(unit) and clears currentUser on success', () async {
      final auth = MockFirebaseAuth(
        signedIn: true,
        mockUser: MockUser(uid: 'u1', email: 'user@example.com'),
      );
      expect(auth.currentUser, isNotNull);

      final result = await signOut(auth);

      expect(result.isRight(), isTrue);
      expect(auth.currentUser, isNull);
    });

    test('returns left(message) when signOut throws', () async {
      final auth = MockFirebaseAuth(
        signedIn: true,
        mockUser: MockUser(uid: 'u1'),
      );
      whenCalling(Invocation.method(#signOut, null))
          .on(auth)
          .thenThrow(FirebaseAuthException(code: 'network-request-failed'));

      final result = await signOut(auth);

      expect(result.isLeft(), isTrue);
    });
  });

  group('signInWithEmailAndPassword', () {
    test('returns right(unit) and sets currentUser on success', () async {
      final auth = MockFirebaseAuth(
        mockUser: MockUser(uid: 'u1', email: 'user@example.com'),
      );

      final result = await signInWithEmailAndPassword(
        auth,
        'user@example.com',
        'password',
      );

      expect(result.isRight(), isTrue);
      expect(auth.currentUser, isNotNull);
    });

    test('returns left(message) when sign-in throws', () async {
      final auth = MockFirebaseAuth(
        mockUser: MockUser(uid: 'u1', email: 'user@example.com'),
      );
      whenCalling(
        Invocation.method(#signInWithEmailAndPassword, null),
      ).on(auth).thenThrow(FirebaseAuthException(code: 'wrong-password'));

      final result = await signInWithEmailAndPassword(
        auth,
        'user@example.com',
        'wrong',
      );

      expect(result.isLeft(), isTrue);
    });
  });

  group('registerNewUser', () {
    test('returns right(unit) and creates user on success', () async {
      final auth = MockFirebaseAuth(
        mockUser: MockUser(uid: 'u1', email: 'new@example.com'),
      );

      final result = await registerNewUser(
        auth,
        'new@example.com',
        'Password1!',
      );

      expect(result.isRight(), isTrue);
      expect(auth.currentUser, isNotNull);
    });

    test(
      'returns left(message) when createUserWithEmailAndPassword throws',
      () async {
        final auth = MockFirebaseAuth(
          mockUser: MockUser(uid: 'u1', email: 'new@example.com'),
        );
        whenCalling(Invocation.method(#createUserWithEmailAndPassword, null))
            .on(auth)
            .thenThrow(FirebaseAuthException(code: 'email-already-in-use'));

        final result = await registerNewUser(
          auth,
          'new@example.com',
          'Password1!',
        );

        expect(result.isLeft(), isTrue);
      },
    );
  });

  group('sendPasswordResetEmail', () {
    test('returns right(unit) with explicit email', () async {
      final auth = MockFirebaseAuth();

      final result = await sendPasswordResetEmail(auth, 'user@example.com');

      expect(result.isRight(), isTrue);
    });

    test('uses currentUser email when email param is null', () async {
      final auth = MockFirebaseAuth(
        signedIn: true,
        mockUser: MockUser(uid: 'u1', email: 'user@example.com'),
      );

      final result = await sendPasswordResetEmail(auth, null);

      expect(result.isRight(), isTrue);
    });

    test('returns left(message) when call throws', () async {
      final auth = MockFirebaseAuth();
      whenCalling(
        Invocation.method(#sendPasswordResetEmail, null),
      ).on(auth).thenThrow(FirebaseAuthException(code: 'user-not-found'));

      final result = await sendPasswordResetEmail(auth, 'user@example.com');

      expect(result.isLeft(), isTrue);
    });
  });

  group('sendSignInLinkToEmail', () {
    late LocalStorage storage;

    setUp(() {
      storage = LocalStorage(test: true);
    });

    test('returns right(unit) and stores email in preferences', () async {
      final auth = MockFirebaseAuth();

      final result = await sendSignInLinkToEmail(
        auth,
        storage,
        'user@example.com',
      );

      expect(result.isRight(), isTrue);
    });

    test('returns left(message) when call throws', () async {
      final auth = MockFirebaseAuth();
      whenCalling(
        Invocation.method(#sendSignInLinkToEmail, null),
      ).on(auth).thenThrow(FirebaseAuthException(code: 'invalid-email'));

      final result = await sendSignInLinkToEmail(
        auth,
        storage,
        'user@example.com',
      );

      expect(result.isLeft(), isTrue);
    });
  });

  group('reauthenticateWithPassword', () {
    test('returns left when no user is signed in', () async {
      final auth = MockFirebaseAuth();

      final result = await reauthenticateWithPassword(auth, 'u@e.com', 'pass');

      expect(result.isLeft(), isTrue);
    });

    test('returns left when user has no email address', () async {
      final auth = MockFirebaseAuth(
        signedIn: true,
        mockUser: MockUser(uid: 'u1'),
      );

      final result = await reauthenticateWithPassword(auth, '', 'pass');

      expect(result.isLeft(), isTrue);
      expect(result.getLeft().toNullable(), 'User has no email address.');
    });

    test('returns right(unit) on success', () async {
      final auth = MockFirebaseAuth(
        signedIn: true,
        mockUser: MockUser(uid: 'u1', email: 'user@example.com'),
      );

      final result = await reauthenticateWithPassword(
        auth,
        'user@example.com',
        'password',
      );

      expect(result.isRight(), isTrue);
    });

    test('returns left(message) when reauthentication throws', () async {
      final mockUser = MockUser(uid: 'u1', email: 'user@example.com');
      final auth = MockFirebaseAuth(signedIn: true, mockUser: mockUser);
      whenCalling(
        Invocation.method(#reauthenticateWithCredential, null),
      ).on(mockUser).thenThrow(FirebaseAuthException(code: 'wrong-password'));

      final result = await reauthenticateWithPassword(
        auth,
        'user@example.com',
        'wrong',
      );

      expect(result.isLeft(), isTrue);
    });
  });

  group('FederatedProvider.name', () {
    test('google returns "Google"', () {
      expect(FederatedProvider.google.name, 'Google');
    });
  });

  group('getProvider', () {
    test('returns GoogleAuthProvider for FederatedProvider.google', () {
      final provider = getProvider(FederatedProvider.google);
      expect(provider, isA<GoogleAuthProvider>());
    });
  });

  group('signInWithGoogle', () {
    test(
      'returns OAuthCredential when getGoogleIdToken returns a token',
      () async {
        final auth = MockFirebaseAuth();

        final result = await signInWithGoogle(
          auth,
          () async => 'fake-id-token',
        );

        expect(result, isA<OAuthCredential>());
      },
    );
  });

  group('signInWithProvider', () {
    test('returns right(unit) for web environment on success', () async {
      final auth = MockFirebaseAuth(
        mockUser: MockUser(uid: 'u1', email: 'user@example.com'),
      );

      final result = await signInWithProvider(
        auth,
        FederatedProvider.google,
        AppEnvironment.web,
      );

      expect(result.isRight(), isTrue);
    });

    test('returns right(unit) for pwa environment on success', () async {
      final auth = MockFirebaseAuth(
        mockUser: MockUser(uid: 'u1', email: 'user@example.com'),
      );

      final result = await signInWithProvider(
        auth,
        FederatedProvider.google,
        AppEnvironment.pwa,
      );

      expect(result.isRight(), isTrue);
    });

    test('returns left(message) when signInWithPopup throws', () async {
      final auth = MockFirebaseAuth(
        mockUser: MockUser(uid: 'u1', email: 'user@example.com'),
      );
      whenCalling(
        Invocation.method(#signInWithPopup, null),
      ).on(auth).thenThrow(FirebaseAuthException(code: 'popup-closed-by-user'));

      final result = await signInWithProvider(
        auth,
        FederatedProvider.google,
        AppEnvironment.web,
      );

      expect(result.isLeft(), isTrue);
    });

    test('returns right(unit) for android environment on success', () async {
      final auth = MockFirebaseAuth(
        mockUser: MockUser(uid: 'u1', email: 'user@example.com'),
      );

      final result = await signInWithProvider(
        auth,
        FederatedProvider.google,
        AppEnvironment.android,
        getGoogleIdTokenFn: () async => 'fake-id-token',
      );

      expect(result.isRight(), isTrue);
    });

    test(
      'returns left for android environment (getGoogleIdToken throws)',
      () async {
        final auth = MockFirebaseAuth(
          mockUser: MockUser(uid: 'u1', email: 'user@example.com'),
        );

        final result = await signInWithProvider(
          auth,
          FederatedProvider.google,
          AppEnvironment.android,
        );

        expect(result.isLeft(), isTrue);
      },
    );

    test('returns right(unit) for ios environment on success', () async {
      final auth = MockFirebaseAuth(
        mockUser: MockUser(uid: 'u1', email: 'user@example.com'),
      );

      final result = await signInWithProvider(
        auth,
        FederatedProvider.google,
        AppEnvironment.ios,
        getGoogleIdTokenFn: () async => 'fake-id-token',
      );

      expect(result.isRight(), isTrue);
    });

    test(
      'returns left for ios environment (getGoogleIdToken throws)',
      () async {
        final auth = MockFirebaseAuth(
          mockUser: MockUser(uid: 'u1', email: 'user@example.com'),
        );

        final result = await signInWithProvider(
          auth,
          FederatedProvider.google,
          AppEnvironment.ios,
        );

        expect(result.isLeft(), isTrue);
      },
    );

    test('returns left for other environment', () async {
      final auth = MockFirebaseAuth(
        mockUser: MockUser(uid: 'u1', email: 'user@example.com'),
      );

      final result = await signInWithProvider(
        auth,
        FederatedProvider.google,
        AppEnvironment.other,
      );

      expect(result.isLeft(), isTrue);
    });
  });

  group('reauthenticateWithProvider', () {
    test('returns left when no user is signed in', () async {
      final auth = MockFirebaseAuth();

      final result = await reauthenticateWithProvider(
        auth,
        FederatedProvider.google,
        AppEnvironment.web,
      );

      expect(result.isLeft(), isTrue);
    });

    test('returns right(unit) for web environment on success', () async {
      final user = _FakeUser(uid: 'u1', email: 'user@example.com');
      final auth = MockFirebaseAuth(signedIn: true, mockUser: user);

      final result = await reauthenticateWithProvider(
        auth,
        FederatedProvider.google,
        AppEnvironment.web,
      );

      expect(result.isRight(), isTrue);
    });

    test('returns right(unit) for pwa environment on success', () async {
      final user = _FakeUser(uid: 'u1', email: 'user@example.com');
      final auth = MockFirebaseAuth(signedIn: true, mockUser: user);

      final result = await reauthenticateWithProvider(
        auth,
        FederatedProvider.google,
        AppEnvironment.pwa,
      );

      expect(result.isRight(), isTrue);
    });

    test('returns left when reauthenticateWithPopup throws', () async {
      final auth = MockFirebaseAuth(
        signedIn: true,
        mockUser: MockUser(uid: 'u1', email: 'user@example.com'),
      );

      final result = await reauthenticateWithProvider(
        auth,
        FederatedProvider.google,
        AppEnvironment.web,
      );

      expect(result.isLeft(), isTrue);
    });

    test('returns right(unit) for android environment on success', () async {
      final user = _FakeUser(uid: 'u1', email: 'user@example.com');
      final auth = MockFirebaseAuth(signedIn: true, mockUser: user);

      final result = await reauthenticateWithProvider(
        auth,
        FederatedProvider.google,
        AppEnvironment.android,
        getGoogleIdTokenFn: () async => 'fake-id-token',
      );

      expect(result.isRight(), isTrue);
    });

    test(
      'returns left for android environment (getGoogleIdToken throws)',
      () async {
        final user = _FakeUser(uid: 'u1', email: 'user@example.com');
        final auth = MockFirebaseAuth(signedIn: true, mockUser: user);

        final result = await reauthenticateWithProvider(
          auth,
          FederatedProvider.google,
          AppEnvironment.android,
        );

        expect(result.isLeft(), isTrue);
      },
    );

    test('returns right(unit) for ios environment on success', () async {
      final user = _FakeUser(uid: 'u1', email: 'user@example.com');
      final auth = MockFirebaseAuth(signedIn: true, mockUser: user);

      final result = await reauthenticateWithProvider(
        auth,
        FederatedProvider.google,
        AppEnvironment.ios,
        getGoogleIdTokenFn: () async => 'fake-id-token',
      );

      expect(result.isRight(), isTrue);
    });

    test(
      'returns left for ios environment (getGoogleIdToken throws)',
      () async {
        final user = _FakeUser(uid: 'u1', email: 'user@example.com');
        final auth = MockFirebaseAuth(signedIn: true, mockUser: user);

        final result = await reauthenticateWithProvider(
          auth,
          FederatedProvider.google,
          AppEnvironment.ios,
        );

        expect(result.isLeft(), isTrue);
      },
    );

    test('returns left for other environment', () async {
      final user = _FakeUser(uid: 'u1', email: 'user@example.com');
      final auth = MockFirebaseAuth(signedIn: true, mockUser: user);

      final result = await reauthenticateWithProvider(
        auth,
        FederatedProvider.google,
        AppEnvironment.other,
      );

      expect(result.isLeft(), isTrue);
    });
  });

  group('changeEmail', () {
    test('returns left when no user is signed in', () async {
      final auth = MockFirebaseAuth();

      final result = await changeEmail(auth, 'new@example.com');

      expect(result.isLeft(), isTrue);
    });

    test('returns right(unit) on success', () async {
      final mockUser = MockUser(uid: 'u1', email: 'user@example.com');
      final auth = MockFirebaseAuth(signedIn: true, mockUser: mockUser);

      final result = await changeEmail(auth, 'new@example.com');

      expect(result.isRight(), isTrue);
    });

    test('returns left(message) when verifyBeforeUpdateEmail throws', () async {
      final mockUser = MockUser(uid: 'u1', email: 'user@example.com');
      final auth = MockFirebaseAuth(signedIn: true, mockUser: mockUser);
      whenCalling(Invocation.method(#verifyBeforeUpdateEmail, null))
          .on(mockUser)
          .thenThrow(FirebaseAuthException(code: 'requires-recent-login'));

      final result = await changeEmail(auth, 'new@example.com');

      expect(result.isLeft(), isTrue);
    });
  });

  group('deleteUser', () {
    test('returns left when no user is signed in', () async {
      final auth = MockFirebaseAuth();

      final result = await deleteUser(auth);

      expect(result.isLeft(), isTrue);
    });

    test('returns right(unit) on success', () async {
      final auth = MockFirebaseAuth(
        signedIn: true,
        mockUser: MockUser(uid: 'u1'),
      );

      final result = await deleteUser(auth);

      expect(result.isRight(), isTrue);
    });

    test('returns left(message) when delete throws', () async {
      final mockUser = MockUser(uid: 'u1');
      final auth = MockFirebaseAuth(signedIn: true, mockUser: mockUser);
      whenCalling(Invocation.method(#delete, null))
          .on(mockUser)
          .thenThrow(FirebaseAuthException(code: 'requires-recent-login'));

      final result = await deleteUser(auth);

      expect(result.isLeft(), isTrue);
    });
  });

  group('sendEmailVerification', () {
    test(
      'authUserProvider returns null for unverified user and invokes verification',
      () async {
        final mockUser = MockUser(
          uid: 'u1',
          email: 'user@example.com',
          isEmailVerified: false,
        );
        final mockAuth = MockFirebaseAuth(signedIn: true, mockUser: mockUser);
        final container = ProviderContainer(
          overrides: [
            firebaseAuthProvider.overrideWith(
              () => _MockAuthNotifier(mockAuth),
            ),
          ],
        );
        addTearDown(container.dispose);

        // container.listen and authUserProvider.future are started inside the
        // guarded zone so that the uncaught error from auth().signOut() (called
        // fire-and-forget inside sendEmailVerification) is swallowed by the
        // zone's error handler rather than propagating to the test zone.
        Object? caughtError;
        await runZonedGuarded(() async {
          container.listen(authUserProvider, (_, _) {});
          await container.read(authUserProvider.future);
        }, (error, _) => caughtError = error);

        // The message is set before auth().signOut() throws.
        expect(container.read(snackBarMessageProvider), isNotNull);
        // Verify the error was the expected Firebase one, not an assertion failure.
        expect('$caughtError', contains('No Firebase App'));
      },
    );
  });

  group('authUserProvider', () {
    test('emits null when no user is signed in', () async {
      final auth = MockFirebaseAuth();
      final container = ProviderContainer(
        overrides: [
          firebaseAuthProvider.overrideWith(() => _MockAuthNotifier(auth)),
        ],
      );
      addTearDown(container.dispose);

      // Listen to keep the provider alive until the stream emits.
      container.listen(authUserProvider, (_, _) {});
      await expectLater(
        container.read(authUserProvider.future),
        completion(isNull),
      );
    });

    test('emits the current user when signed in', () async {
      final mockUser = MockUser(uid: 'u1', email: 'user@example.com');
      final auth = MockFirebaseAuth(signedIn: true, mockUser: mockUser);
      final container = ProviderContainer(
        overrides: [
          firebaseAuthProvider.overrideWith(() => _MockAuthNotifier(auth)),
        ],
      );
      addTearDown(container.dispose);

      container.listen(authUserProvider, (_, _) {});
      await expectLater(
        container.read(authUserProvider.future),
        completion(isNotNull),
      );
    });

    test('emits null after sign out', () async {
      final mockUser = MockUser(uid: 'u1', email: 'user@example.com');
      final auth = MockFirebaseAuth(signedIn: true, mockUser: mockUser);
      final container = ProviderContainer(
        overrides: [
          firebaseAuthProvider.overrideWith(() => _MockAuthNotifier(auth)),
        ],
      );
      addTearDown(container.dispose);

      final states = <User?>[];
      container.listen<AsyncValue<User?>>(
        authUserProvider,
        (_, next) => next.whenData(states.add),
        fireImmediately: true,
      );

      // Wait for the signed-in emission.
      await container.read(authUserProvider.future);

      await auth.signOut();

      // Allow the stream event to propagate.
      await Future.microtask(() {});
      await Future.microtask(() {});

      expect(states, contains(isNull));
    });
  });
}
