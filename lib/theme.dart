import 'package:flutter/material.dart';

import 'config.dart';

/// Цвета флага Казахстана: небесно-бирюзовый и золотой.
/// У «Узбекистан обои» — цвета флага Узбекистана: голубой, зелёный и красный
const uzBlue = Color(0xFF0099B5);
const uzGreen = Color(0xFF1EB53A);
const uzRed = Color(0xFFCE1126);

/// Отмеченное сердечко избранного
const brandGold = Config.uzb ? Color(0xFFFF4D5E) : Color(0xFFFFC72C);
const whatsAppGreen = Color(0xFF25D366);

/// Главная кнопка поверх картинки ("Установить")
const brandButton = Config.uzb ? Color(0xFF17973A) : Color(0xFF0091AD);

ThemeData buildTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final seed = ColorScheme.fromSeed(
    seedColor: Config.uzb ? uzBlue : const Color(0xFF00A3C4),
    brightness: brightness,
  );
  final brand =
      Config.uzb
          ? seed.copyWith(
            primary: dark ? const Color(0xFF4CC4DC) : const Color(0xFF007C94),
            onPrimary: dark ? const Color(0xFF00363F) : Colors.white,
            primaryContainer: dark ? const Color(0xFF004E5C) : const Color(0xFFC3EEF7),
            onPrimaryContainer: dark ? const Color(0xFFC3EEF7) : const Color(0xFF00363F),
            // Зелёный флага — второй цвет: полоска под выбранной вкладкой и кнопка "Установить"
            secondary: dark ? const Color(0xFF5FD97A) : const Color(0xFF17973A),
            onSecondary: dark ? const Color(0xFF00390F) : Colors.white,
            error: dark ? const Color(0xFFFF8A93) : uzRed,
          )
          : seed.copyWith(
            primary: dark ? const Color(0xFF3CC8E0) : const Color(0xFF007F99),
            onPrimary: dark ? const Color(0xFF00363F) : Colors.white,
            primaryContainer: dark ? const Color(0xFF004E5C) : const Color(0xFFC5F0F8),
            onPrimaryContainer: dark ? const Color(0xFFC5F0F8) : const Color(0xFF00363F),
          );
  final scheme = brand.copyWith(
    surface: dark ? const Color(0xFF1A1D20) : Colors.white,
    surfaceContainerHigh: dark ? const Color(0xFF25292D) : const Color(0xFFE7ECEF),
    onSurface: dark ? const Color(0xFFF1F3F4) : const Color(0xFF1A1C1E),
    onSurfaceVariant: dark ? const Color(0xFFA7AEB4) : const Color(0xFF5B646B),
    outline: dark ? const Color(0xFF3A4046) : const Color(0xFFC5CDD3),
  );
  final background = dark ? const Color(0xFF0F1113) : const Color(0xFFF3F6F8);

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: background,
    appBarTheme: AppBarTheme(
      backgroundColor: background,
      foregroundColor: scheme.onSurface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: TextStyle(color: scheme.onSurface, fontSize: 20, fontWeight: FontWeight.w700),
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: scheme.primary,
      unselectedLabelColor: scheme.onSurfaceVariant,
      indicatorColor: Config.uzb ? scheme.secondary : scheme.primary,
      dividerColor: Colors.transparent,
      labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      unselectedLabelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? scheme.primary : Colors.transparent,
        ),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) return scheme.onSurfaceVariant.withValues(alpha: 0.5);
          return states.contains(WidgetState.selected) ? scheme.onPrimary : scheme.onSurface;
        }),
      ),
    ),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    bottomSheetTheme: BottomSheetThemeData(backgroundColor: scheme.surface, surfaceTintColor: Colors.transparent),
    dialogTheme: DialogThemeData(backgroundColor: scheme.surface, surfaceTintColor: Colors.transparent),
  );
}
