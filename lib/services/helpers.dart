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

/// Pads single-digit HH or MM parts in a "H:MM", "HH:M", or "H:M" string.
/// Also accepts no-colon inputs: 4-char 'hhmm' or 3-char 'hmm'.
String? padHhmm(String? hhmm, {bool short = false}) {
  if (hhmm == null || hhmm.isEmpty) return hhmm;
  if (!hhmm.contains(':')) {
    if (hhmm.length == 4) {
      return '${hhmm.substring(0, 2)}:${hhmm.substring(2)}';
    } else if (hhmm.length == 3) {
      return '0${hhmm.substring(0, 1)}:${hhmm.substring(1)}';
    } else {
      return hhmm;
    }
  }
  final parts = hhmm.split(':');
  final hh = short ? int.parse(parts[0]).toString() : parts[0].padLeft(2, '0');
  final mm = parts.length > 1 ? parts[1].padLeft(2, '0') : '00';
  return '$hh:$mm';
}

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
