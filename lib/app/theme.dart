import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

ThemeData buildAppTheme() {
  const bg = Color(0xFF0D0D0D);
  const surface = Color(0xFF161616);
  const textPrimary = Color(0xFFEFEFEF);
  const textSecondary = Color(0xFFB5B5B5);
  const divider = Color(0xFF2A2A2A);

  final textTheme = GoogleFonts.vazirmatnTextTheme().apply(
    bodyColor: textPrimary,
    displayColor: textPrimary,
  );

  final colorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: Colors.white,
    onPrimary: Colors.black,
    secondary: Colors.white,
    onSecondary: Colors.black,
    surface: surface,
    onSurface: textPrimary,
    error: Colors.redAccent,
    onError: Colors.white,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: bg,
    canvasColor: bg,
    textTheme: textTheme,
    appBarTheme: const AppBarTheme(
        backgroundColor: bg,
        elevation: 0,
        surfaceTintColor: Colors.transparent),
    dividerColor: divider,
    cardColor: surface,
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF1C1C1C),
      border: OutlineInputBorder(
          borderSide: const BorderSide(color: divider),
          borderRadius: BorderRadius.circular(10)),
      enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: divider),
          borderRadius: BorderRadius.circular(10)),
      focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.white70),
          borderRadius: BorderRadius.circular(10)),
      hintStyle: const TextStyle(color: textSecondary),
      labelStyle: const TextStyle(color: textSecondary),
    ),
    listTileTheme: const ListTileThemeData(
        iconColor: textSecondary, textColor: textPrimary),
    snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Color(0xFF222222),
        contentTextStyle: TextStyle(color: Colors.white)),
    iconTheme: const IconThemeData(color: textSecondary),
    elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)))),
    filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)))),
    outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: const BorderSide(color: Colors.white30),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)))),
    chipTheme: ChipThemeData(
        backgroundColor: surface,
        labelStyle: const TextStyle(color: textPrimary),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: divider))),
  );
}
