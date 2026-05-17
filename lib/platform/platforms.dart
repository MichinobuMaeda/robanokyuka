import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'platform_env_stub.dart'
    if (dart.library.js_interop) 'platform_env_web.dart';

enum AppEnvironment { android, ios, web, pwa, other }

AppEnvironment getAppEnvironment() {
  if (kIsWeb) {
    return isStandaloneWebApp ? AppEnvironment.pwa : AppEnvironment.web;
  } else {
    if (Platform.isAndroid) return AppEnvironment.android;
    if (Platform.isIOS) return AppEnvironment.ios;
  }

  return AppEnvironment.other;
}

/// A wrapper around [SharedPreferencesAsync] for testable local storage access.
class LocalStorage {
  LocalStorage({this.test = false});

  final bool test;
  final Map<String, String> _inMemoryStorage = {};
  late final SharedPreferencesAsync _prefs = SharedPreferencesAsync();

  Future<String?> getString(String key) {
    return test ? Future.value(_inMemoryStorage[key]) : _prefs.getString(key);
  }

  Future<void> setString(String key, String value) {
    if (test) {
      _inMemoryStorage[key] = value;
    }
    return test ? Future.value() : _prefs.setString(key, value);
  }

  Future<void> remove(String key) {
    if (test) {
      _inMemoryStorage.remove(key);
    }
    return test ? Future.value() : _prefs.remove(key);
  }
}

void updateApp() => updateAppImpl();

Future<String> getGoogleIdToken() async {
  final googleUser = await GoogleSignIn.instance.authenticate();
  final idToken = googleUser.authentication.idToken;
  if (idToken == null) {
    throw Exception('Failed to retrieve Google ID token.');
  }
  return idToken;
}
