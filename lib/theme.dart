import 'package:flutter/material.dart';

import 'models.dart';

const roomBlue = Color(0xFF2563EB);
const roomGreen = Color(0xFF16A34A);
const roomOrange = Color(0xFFEA580C);
const cream = Color(0xFFF3EEE4);
const ink = Color(0xFF1C1917);

Color roomColor(int roomId, [HouseProfile? house]) {
  final named = house?.roomById(roomId);
  if (named != null) return Color(named.colorValue);
  return switch (roomId) {
    1 => roomBlue,
    2 => roomGreen,
    3 => roomOrange,
    _ => const Color(0xFF78716C),
  };
}

Color roomFill(int roomId, Brightness brightness, [HouseProfile? house]) {
  final c = roomColor(roomId, house);
  return c.withValues(alpha: brightness == Brightness.dark ? 0.24 : 0.14);
}

const glassTabContentPadding = EdgeInsets.fromLTRB(16, 8, 16, 32);

class HouseGlassBackground extends StatelessWidget {
  const HouseGlassBackground({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: dark
              ? const [Color(0xFF0E1418), Color(0xFF12201C), Color(0xFF1A1612)]
              : const [cream, Color(0xFFE7F3F0), Color(0xFFF6EDE3)],
        ),
      ),
    );
  }
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
