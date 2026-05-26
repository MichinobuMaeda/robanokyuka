import 'dart:io' show Platform;

import 'package:google_sign_in/google_sign_in.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:robanokyuka/config/google_server_client_id.dart';

const appHomepageUrl = 'https://robanokyuka.michinobu.jp/docs/';
const androidPackageId = 'jp.michinobu.robanokyuka';
const iosAppStoreId = '0000000000'; // TODO: replace with real App Store ID

/// Non-web stub: standalone mode is never detected on native platforms.
bool get isStandaloneWebApp => false;

void updateAppImpl() {
  if (Platform.isAndroid) {
    launchUrl(
      Uri.parse('market://details?id=$androidPackageId'),
      mode: LaunchMode.externalApplication,
    ).catchError((_) {
      launchUrl(
        Uri.parse(
          'https://play.google.com/store/apps/details?id=$androidPackageId',
        ),
        mode: LaunchMode.externalApplication,
      );
      return false;
    });
  } else if (Platform.isIOS) {
    launchUrl(
      Uri.parse('itms-apps://itunes.apple.com/app/id$iosAppStoreId'),
      mode: LaunchMode.externalApplication,
    ).catchError((_) {
      launchUrl(
        Uri.parse('https://apps.apple.com/app/id$iosAppStoreId'),
        mode: LaunchMode.externalApplication,
      );
      return false;
    });
  } else {
    launchUrl(Uri.parse(appHomepageUrl), mode: LaunchMode.externalApplication);
  }
}

bool _googleSignInInitialized = false;

Future<String> getGoogleIdTokenImpl() async {
  if (!_googleSignInInitialized) {
    await GoogleSignIn.instance.initialize(
      serverClientId: googleServerClientId,
    );
    _googleSignInInitialized = true;
  }
  final googleUser = await GoogleSignIn.instance.authenticate();
  final idToken = googleUser.authentication.idToken;
  if (idToken == null) {
    throw Exception('Failed to retrieve Google ID token.');
  }
  return idToken;
}
