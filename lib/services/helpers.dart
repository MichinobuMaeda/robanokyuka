import 'package:hooks_riverpod/hooks_riverpod.dart';

const assetAppLogo = 'assets/logo.png';
const assetGuestMd = 'assets/guest.md';
const assetReauthenticateMd = 'assets/reauthenticate.md';
const assetInfoMd = 'assets/info.md';

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

final snackBarMessageProvider =
    NotifierProvider<SnackBarMessageNotifier, String?>(
      SnackBarMessageNotifier.new,
    );

const weekDays = ['日', '月', '火', '水', '木', '金', '土'];

String dateToWeekday(int year, int month, int day) =>
    weekDays[DateTime(year, month, day).weekday % 7];
