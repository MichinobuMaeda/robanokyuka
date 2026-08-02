import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:robanokyuka/models/cal.dart';
import 'package:robanokyuka/models/record.dart';

const assetAppLogo = 'assets/logo.svg';
const assetGuestMd = 'assets/guest.md';
const assetReauthenticateMd = 'assets/reauthenticate.md';
const assetInfoMd = 'assets/info.md';

/// A [Notifier] that holds a nullable string message for displaying
/// in a SnackBar.
class SnackBarMessageNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void show(String message) {
    state = message;
  }

  void clear() {
    state = null;
  }
}

/// A [NotifierProvider] that provides a [SnackBarMessageNotifier]
/// for managing SnackBar messages.
final snackBarMessageProvider =
    NotifierProvider<SnackBarMessageNotifier, String?>(
      SnackBarMessageNotifier.new,
    );

String toHankaku(String str) {
  return str
      .split('')
      .map((char) {
        if (char == '　') {
          return ' ';
        }

        if (char == 'ー') {
          return '-';
        }

        int code = char.codeUnitAt(0);

        if (code >= 0xFF01 && code <= 0xFF5E) {
          return String.fromCharCode(code - 0xFEE0);
        }

        return char;
      })
      .join('');
}

bool isUpdateAvailable(String? currentVersion, String? latestVersion) {
  if (currentVersion == null || latestVersion == null) {
    return false;
  }

  List<int> parse(String version) {
    final parts = version.split('+');
    final build = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
    final versionParts = parts[0]
        .split('.')
        .map((p) => int.tryParse(p) ?? 0)
        .toList();
    while (versionParts.length < 3) {
      versionParts.add(0);
    }
    return [...versionParts, build];
  }

  final current = parse(currentVersion);
  final latest = parse(latestVersion);

  for (var i = 0; i < current.length; i++) {
    if (current[i] < latest[i]) return true;
    if (current[i] > latest[i]) return false;
  }
  return false;
}

List<Cal> generateMonthList(Cal from, Cal to) => [
  for (
    var m = Cal(from.year, from.month, 1);
    m.year < to.year || (m.year <= to.year && m.month <= to.month);
    m = m.month < 12 ? Cal(m.year, m.month + 1, 1) : Cal(m.year + 1, 1, 1)
  )
    m,
];
