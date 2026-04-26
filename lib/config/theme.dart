import 'package:flutter/material.dart';

const appName = '有休チェッカー';
const seedColor = Color.fromARGB(255, 0x6A, 0xB0, 0x7F);
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
