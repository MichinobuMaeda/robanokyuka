import 'package:google_sign_in/google_sign_in.dart';

import 'package:robanokyuka/config/google_server_client_id.dart';

/// Non-web stub: standalone mode is never detected on native platforms.
bool get isStandaloneWebApp => false;

void updateAppImpl() {}

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
