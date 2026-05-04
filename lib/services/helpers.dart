import 'package:hooks_riverpod/hooks_riverpod.dart';

const assetAppLogo = 'assets/logo.png';
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
