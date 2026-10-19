import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Charte graphique — Studio TikTok
class AppColors {
  // Couleurs principales
  static const cyan = Color(0xFF00E5FF); // Bleu Cyan
  static const rose = Color(0xFFFF2D55); // Rose TikTok
  static const night = Color(0xFF0B132B); // Bleu Nuit
  static const greyLight = Color(0xFFF3F4F6); // Gris Clair
  static const greyDark = Color(0xFF6B7280); // Gris Foncé

  // Couleurs d'état
  static const success = Color(0xFF10B981);
  static const warning = Color(0xFFF59E0B);
  static const error = Color(0xFFEF4444);
  static const info = Color(0xFF3B82F6);

  // مشتقّات للـdark UI
  static const bg = night;
  static const bgSecondary = Color(0xFF0E1830);
  static const card = Color(0xFF152037);
  static const cardHigh = Color(0xFF1C2A47);
  static const border = Color(0xFF24324F);

  static const textHigh = greyLight;
  static const textMid = Color(0xFF93A0B5);
  static const textLow = greyDark;

  /// gradient رئيسي: Cyan → Rose
  static const brandGradient = LinearGradient(
    colors: [cyan, rose],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  /// gradient الحلقات (نفس هوية البراند)
  static const ringGradient = LinearGradient(
    colors: [cyan, rose],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

ThemeData buildAppTheme() {
  const cs = ColorScheme.dark(
    primary: AppColors.cyan,
    onPrimary: AppColors.night,
    primaryContainer: Color(0xFF0A3A48),
    onPrimaryContainer: AppColors.cyan,
    secondary: AppColors.rose,
    onSecondary: Colors.white,
    tertiary: AppColors.rose,
    onTertiary: Colors.white,
    surface: AppColors.card,
    onSurface: AppColors.textHigh,
    onSurfaceVariant: AppColors.textMid,
    surfaceContainerHighest: AppColors.cardHigh,
    error: AppColors.error,
    onError: Colors.white,
    outline: AppColors.border,
  );

  final base = ThemeData(brightness: Brightness.dark).textTheme;
  final p = GoogleFonts.poppinsTextTheme(base).apply(
    bodyColor: AppColors.textHigh,
    displayColor: AppColors.textHigh,
  );
  // أحجام الـcharte: H1 32/Bold, H2 24/Semibold, H3 20/Semibold, Body 16, Caption 14, Button 16/Medium
  final textTheme = p.copyWith(
    headlineLarge: p.headlineLarge?.copyWith(fontSize: 32, fontWeight: FontWeight.bold),
    headlineMedium: p.headlineMedium?.copyWith(fontSize: 24, fontWeight: FontWeight.w600),
    headlineSmall: p.headlineSmall?.copyWith(fontSize: 20, fontWeight: FontWeight.w600),
    titleLarge: p.titleLarge?.copyWith(fontSize: 20, fontWeight: FontWeight.w600),
    titleMedium: p.titleMedium?.copyWith(fontSize: 16, fontWeight: FontWeight.w600),
    titleSmall: p.titleSmall?.copyWith(fontWeight: FontWeight.w600),
    bodyLarge: p.bodyLarge?.copyWith(fontSize: 16),
    bodyMedium: p.bodyMedium?.copyWith(fontSize: 14),
    labelLarge: p.labelLarge?.copyWith(fontSize: 16, fontWeight: FontWeight.w500),
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: cs,
    scaffoldBackgroundColor: AppColors.bg,
    canvasColor: AppColors.bg,
    textTheme: textTheme,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.bg,
      surfaceTintColor: Colors.transparent,
      foregroundColor: AppColors.textHigh,
      elevation: 0,
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      color: AppColors.card,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppColors.border),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.card,
      selectedColor: AppColors.cyan,
      disabledColor: AppColors.card,
      side: const BorderSide(color: AppColors.border),
      labelStyle: const TextStyle(color: AppColors.textMid, fontWeight: FontWeight.w500),
      secondaryLabelStyle: const TextStyle(color: AppColors.night, fontWeight: FontWeight.w600),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      showCheckmark: false,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.bgSecondary,
      hintStyle: const TextStyle(color: AppColors.textLow),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.cyan, width: 1.6),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.cyan,
        foregroundColor: AppColors.night,
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.cyan,
        side: const BorderSide(color: AppColors.border),
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: AppColors.cyan),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.rose,
      foregroundColor: Colors.white,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? AppColors.night : AppColors.textMid),
      trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? AppColors.cyan : AppColors.card),
      trackOutlineColor: WidgetStateProperty.all(AppColors.border),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.bgSecondary,
      surfaceTintColor: Colors.transparent,
      indicatorColor: AppColors.cyan.withValues(alpha: 0.18),
      labelTextStyle: WidgetStateProperty.all(
        const TextStyle(fontSize: 12, color: AppColors.textMid),
      ),
      iconTheme: WidgetStateProperty.resolveWith((s) => IconThemeData(
            color: s.contains(WidgetState.selected) ? AppColors.cyan : AppColors.textMid,
          )),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.card,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.card,
      surfaceTintColor: Colors.transparent,
    ),
    listTileTheme: const ListTileThemeData(iconColor: AppColors.textMid),
    dividerTheme: const DividerThemeData(color: AppColors.border, thickness: 1),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: AppColors.cardHigh,
      contentTextStyle: TextStyle(color: AppColors.textHigh),
      behavior: SnackBarBehavior.floating,
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(color: AppColors.cyan),
  );
}
