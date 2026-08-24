import 'package:flutter/material.dart';

const roomBlue = Color(0xFF2563EB);
const roomGreen = Color(0xFF16A34A);
const roomOrange = Color(0xFFEA580C);
const cream = Color(0xFFF3EEE4);
const ink = Color(0xFF1C1917);

Color roomColor(int roomId) => switch (roomId) {
  1 => roomBlue,
  2 => roomGreen,
  3 => roomOrange,
  _ => const Color(0xFF78716C),
};

Color roomFill(int roomId, Brightness brightness) {
  final c = roomColor(roomId);
  return c.withValues(alpha: brightness == Brightness.dark ? 0.24 : 0.14);
}

ThemeData buildTheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  const seed = Color(0xFF0F766E);
  final scheme = ColorScheme.fromSeed(seedColor: seed, brightness: brightness);
  final surface = isDark ? const Color(0xFF121417) : cream;
  final card = isDark ? const Color(0xFF1C2228) : Colors.white;
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: surface,
    appBarTheme: AppBarTheme(
      centerTitle: false,
      backgroundColor: surface,
      foregroundColor: scheme.onSurface,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: scheme.onSurface,
        letterSpacing: -0.3,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: card,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: isDark ? const Color(0xFF2A323A) : const Color(0xFFE6DDD0),
        ),
      ),
    ),
    chipTheme: ChipThemeData(
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: isDark ? const Color(0xFF161A1E) : Colors.white,
      indicatorColor: seed.withValues(alpha: isDark ? 0.35 : 0.16),
      elevation: 0,
      height: 68,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return TextStyle(
          fontSize: 12,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        );
      }),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}
