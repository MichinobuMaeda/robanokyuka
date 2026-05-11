import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:robanokyuka/config/firebase.dart';
import 'package:robanokyuka/config/theme.dart';
import 'package:robanokyuka/models/users.dart';
import 'package:robanokyuka/platform/platforms.dart';
import 'package:robanokyuka/services/authentication.dart';
import 'package:robanokyuka/views/layout.dart';

void main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  await initializeFirebase();
  // await handleGoogleAuthRedirect();
  if (kIsWeb) {
    final url = Uri.base.toString();
    if (await handleEmailLink(auth(), LocalStorage(), url)) {
      await launchUrl(Uri.parse(getBaseUrl(url)), webOnlyWindowName: '_self');
    }
  }
  FlutterNativeSplash.remove();
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
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ja', 'JP')],
      locale: const Locale('ja', 'JP'),
      home: const Layout(),
    );
  }
}
