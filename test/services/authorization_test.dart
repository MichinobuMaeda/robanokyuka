import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:robanokyuka/models/service.dart';
import 'package:robanokyuka/services/authentication.dart';
import 'package:robanokyuka/services/authorization.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Returns a [ProviderContainer] with [authUserProvider], [serviceProvider],
/// and [confProvider] all overridden so no Firebase calls are made.
ProviderContainer _makeContainer({
  required AsyncValue<User?> authUser,
  AsyncValue<QuerySnapshot<Map<String, dynamic>>?> service = const AsyncData(
    null,
  ),
  List<String> admins = const [],
}) {
  final container = ProviderContainer(
    overrides: [
      authUserProvider.overrideWith(
        (_) => Stream.value(authUser.asData?.value),
      ),
      serviceProvider.overrideWith((_) => Stream.value(service.asData?.value)),
      confProvider.overrideWithValue(
        admins.isEmpty
            ? null
            : Conf(
                admins: admins,
                gengos: [],
                uiVersion: '',
                androidVersion: '0.0.0+0',
                iosVersion: '0.0.0+0',
              ),
      ),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

/// Waits for [authUserProvider] and [serviceProvider] to emit their first
/// value so that [privilegeProvider] (a sync [Provider]) sees [AsyncData].
Future<void> _settle(ProviderContainer container) async {
  container.listen(authUserProvider, (_, _) {});
  container.listen(serviceProvider, (_, _) {});
  await container.read(authUserProvider.future);
  await container.read(serviceProvider.future);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // -------------------------------------------------------------------------
  group('PageItem.privileges', () {
    test('guest is only available to Privilege.guest', () {
      expect(PageItem.guest.privileges, equals([Privilege.guest]));
    });

    test('home is available to user and admin', () {
      expect(
        PageItem.home.privileges,
        containsAll([Privilege.user, Privilege.admin]),
      );
      expect(PageItem.home.privileges, isNot(contains(Privilege.guest)));
    });

    test('settings is available to user and admin', () {
      expect(
        PageItem.settings.privileges,
        containsAll([Privilege.user, Privilege.admin]),
      );
      expect(PageItem.settings.privileges, isNot(contains(Privilege.guest)));
    });

    test('admin is only available to Privilege.admin', () {
      expect(PageItem.admin.privileges, equals([Privilege.admin]));
    });

    test('info is available to all privileges', () {
      expect(PageItem.info.privileges, containsAll(Privilege.values));
    });
  });

  // -------------------------------------------------------------------------
  group('privilegeProvider', () {
    test('returns Privilege.loading while authUser is loading', () {
      // Use a stream that never emits so the provider stays in AsyncLoading.
      final container = ProviderContainer(
        overrides: [
          authUserProvider.overrideWith((_) => const Stream.empty()),
          serviceProvider.overrideWith((_) => const Stream.empty()),
        ],
      );
      addTearDown(container.dispose);

      // First read: stream providers are still in AsyncLoading.
      expect(container.read(privilegeProvider), Privilege.loading);
    });

    test('returns Privilege.guest when authUser is null', () async {
      final container = _makeContainer(authUser: const AsyncData(null));
      await _settle(container);

      expect(container.read(privilegeProvider), Privilege.guest);
    });

    test('returns Privilege.user for a signed-in non-admin user', () async {
      final mockUser = MockUser(uid: 'u1', email: 'user@example.com');
      final container = _makeContainer(
        authUser: AsyncData(mockUser),
        admins: ['other-uid'],
      );
      await _settle(container);

      expect(container.read(privilegeProvider), Privilege.user);
    });

    test('returns Privilege.admin when uid is in admins list', () async {
      final mockUser = MockUser(uid: 'admin-uid', email: 'admin@example.com');
      final container = _makeContainer(
        authUser: AsyncData(mockUser),
        admins: ['admin-uid'],
      );
      await _settle(container);

      expect(container.read(privilegeProvider), Privilege.admin);
    });
  });

  // -------------------------------------------------------------------------
  group('pagesProvider', () {
    test('loading privilege yields only info page', () {
      final container = ProviderContainer(
        overrides: [
          authUserProvider.overrideWith((_) => const Stream.empty()),
          serviceProvider.overrideWith((_) => const Stream.empty()),
        ],
      );
      addTearDown(container.dispose);

      final pages = container.read(pagesProvider);

      // Privilege.loading: only 'info' (which allows all privileges) is shown.
      expect(pages.map((p) => p.name), equals(['info']));
    });

    test('guest privilege yields only guest and info pages', () async {
      final container = _makeContainer(authUser: const AsyncData(null));
      await _settle(container);

      final pages = container.read(pagesProvider);

      expect(pages.map((p) => p.name), containsAll(['guest', 'info']));
      expect(pages.map((p) => p.name), isNot(contains('home')));
      expect(pages.map((p) => p.name), isNot(contains('admin')));
    });

    test(
      'user privilege yields home, settings and info but not admin',
      () async {
        final mockUser = MockUser(uid: 'u1');
        final container = _makeContainer(
          authUser: AsyncData(mockUser),
          admins: [],
        );
        await _settle(container);

        final pages = container.read(pagesProvider);
        final names = pages.map((p) => p.name).toList();

        expect(names, containsAll(['home', 'settings', 'info']));
        expect(names, isNot(contains('admin')));
        expect(names, isNot(contains('guest')));
      },
    );

    test('admin privilege yields home, settings, admin and info', () async {
      final mockUser = MockUser(uid: 'admin-uid');
      final container = _makeContainer(
        authUser: AsyncData(mockUser),
        admins: ['admin-uid'],
      );
      await _settle(container);

      final pages = container.read(pagesProvider);
      final names = pages.map((p) => p.name).toList();

      expect(names, containsAll(['home', 'settings', 'admin', 'info']));
      expect(names, isNot(contains('guest')));
    });
  });
}
