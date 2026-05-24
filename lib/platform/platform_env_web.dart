import 'package:web/web.dart' as web;

/// Returns true when the web app is running in PWA standalone mode.
bool get isStandaloneWebApp =>
    web.window.matchMedia('(display-mode: standalone)').matches ||
    web.window.navigator.vendor == 'Apple Computer Inc.' &&
        (web.window.navigator as dynamic).standalone == true;

void updateAppImpl() => web.window.location.reload();

Future<String> getGoogleIdTokenImpl() async => '';
