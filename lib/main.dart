import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import 'config/firebase.dart';
import 'config/theme.dart';
import 'models/users.dart';
import 'services/authentication.dart';
import 'platform/platforms.dart';
import 'views/layout.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeFirebase();
  // await handleGoogleAuthRedirect();
  final url = Uri.base.toString();
  if (await handleEmailLink(auth(), LocalStorage(), url)) {
    await launchUrl(Uri.parse(getBaseUrl(url)), webOnlyWindowName: '_self');
  }
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends HookConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Future(() => ref.read(firebaseAuthProvider.notifier).setAuth(auth()));
    final themeMode = ref.watch(
      userProvider.select((user) => user?.themeMode ?? ThemeMode.system),
    );

    return MaterialApp(
      title: appName,
      themeMode: themeMode,
      theme: generateThemeData(Brightness.light),
      darkTheme: generateThemeData(Brightness.dark),
      home: const Layout(),
    );
  }
}
