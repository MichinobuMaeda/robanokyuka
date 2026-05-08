import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

const appName = 'ロバの休暇';
const seedColor = Color.fromARGB(255, 0x73, 0x42, 0x26);
const defaultFont = 'NotoSansJP';
const navDrawerWidth = 256.0;
const contentMaxWidth = 1024.0;
const buttonHeight = 48.0;
const panelPadding = EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0.0);
const bottomSheetPadding = EdgeInsets.all(16.0);
const panelSpacing = 16.0;
const defaultInputWidth = 512.0;
TextStyle? panelTitleStyle(BuildContext context) =>
    Theme.of(context).textTheme.headlineSmall;

ThemeData generateThemeData(Brightness brightness) {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: seedColor,
    brightness: brightness,
  );

  final commonButtonStyle = ButtonStyle(
    minimumSize: WidgetStateProperty.all(Size.square(buttonHeight)),
    textStyle: WidgetStateProperty.all(TextStyle(fontFamily: defaultFont)),
  );

  return ThemeData(
    useMaterial3: true,
    fontFamily: defaultFont,
    colorScheme: colorScheme,
    textTheme: Typography.material2021().black.apply(
      fontFamily: defaultFont,
      bodyColor: colorScheme.onSurface,
      displayColor: colorScheme.onSurface,
    ),
    filledButtonTheme: FilledButtonThemeData(style: commonButtonStyle),
    outlinedButtonTheme: OutlinedButtonThemeData(style: commonButtonStyle),
    elevatedButtonTheme: ElevatedButtonThemeData(style: commonButtonStyle),
    navigationDrawerTheme: NavigationDrawerThemeData(
      backgroundColor: colorScheme.surfaceContainerLow,
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: colorScheme.surfaceContainer,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: colorScheme.surfaceContainer,
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: colorScheme.surfaceContainer,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      showCloseIcon: true,
      contentTextStyle: TextStyle(
        fontFamily: defaultFont,
        color: colorScheme.onInverseSurface,
      ),
    ),
  );
}

final iconAdd = Icon(Symbols.add);
final iconEdit = Icon(Symbols.edit);
final iconDelete = Icon(Symbols.delete);
final iconClose = Icon(Symbols.close);
final iconWorked = Icon(Symbols.work, fill: 0);
final iconCompanyHoliday = Icon(Symbols.work_off, fill: 1.0);
final iconPaidFull = Icon(Symbols.battery_android_frame_full);
final iconPaidHalf = Icon(Symbols.battery_android_frame_4);
final iconPaidEmpty = Icon(Symbols.battery_android_0);
final iconSickFull = Icon(Symbols.home_health, fill: 1.0);
final iconSickHalf = Icon(Symbols.home_health, fill: 0.0);
final iconSickEmpty = Icon(Symbols.health_cross, fill: 0.0);
final iconOtherFull = Icon(Symbols.star, fill: 1.0);
final iconOtherHalf = Icon(Symbols.star_half);
final iconOtherEmpty = Icon(Symbols.star, fill: 0.0);

const weekdayLabels = ['日', '月', '火', '水', '木', '金', '土'];

const calHeaderHeight = 24.0;
const calCellHeight = 48.0;
const calGridWidth = 400.0;
const calGridHeight = calHeaderHeight * 2 + calCellHeight * 6;
const calGridSpacing = 1.0;

Color panelColor(BuildContext context, int month) {
  return switch (month % 4) {
    0 => Theme.of(context).colorScheme.surfaceContainerLowest,
    1 => Theme.of(context).colorScheme.surfaceContainerLow.withAlpha(168),
    2 => Theme.of(context).colorScheme.surfaceContainerLow.withAlpha(64),
    _ => Theme.of(context).colorScheme.surfaceContainerLow.withAlpha(252),
  };
}
