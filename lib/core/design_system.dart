import 'package:flutter/material.dart';

/// Design tokens.
///
/// Every colour, spacing step, radius and duration in the app resolves through
/// this file. Previously each widget hard-coded `Colors.grey[900]` /
/// `Color(0xFF1DB954)` / `0xFF121212` independently, which meant the same
/// "surface" was four different greps depending on which screen you were on.
class AppColors {
  const AppColors._();

  /// Spotify-green brand accent.
  static const Color accent = Color(0xFF1DB954);
  static const Color accentPressed = Color(0xFF14833C);
  static const Color onAccent = Color(0xFF06170C);

  /// Pure black keeps AMOLED panels off while scrolling (Poweramp/Retro do the
  /// same). Every screen background uses this.
  static const Color background = Color(0xFF000000);

  /// Raised surfaces: mini player, cards, sheets, list tiles.
  static const Color surface = Color(0xFF121212);
  static const Color surfaceElevated = Color(0xFF1C1C1C);
  static const Color surfaceHigh = Color(0xFF262626);
  static const Color surfaceHighest = Color(0xFF333333);

  static const Color divider = Color(0x1FFFFFFF);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xB3FFFFFF);
  static const Color textTertiary = Color(0x80FFFFFF);
  static const Color disabled = Color(0x4DFFFFFF);
  static const Color danger = Color(0xFFE5484D);

  /// 하단 네비게이션 배경 (화면보다 밝은 톤)
  static const Color navBarBackground = Color(0xFF0A0A0A);

  /// 네비게이션 선택된 탭의 인디케이터 배경
  static const Color navIndicator = Color(0x1AFFFFFF);

  /// 네비게이션 아이콘/라벨 기본 (비선택)
  static const Color navInactive = Color(0xFF8A8A8A);
}

/// 4pt spacing scale.
class AppSpacing {
  const AppSpacing._();

  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
}

class AppRadius {
  const AppRadius._();

  static const double sm = 8;
  static const double md = 12;
  static const double lg = 20;
  static const double pill = 999;
}

class AppMotion {
  const AppMotion._();

  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 340);
  static const Curve enter = Curves.easeOutCubic;
  static const Curve exit = Curves.easeInCubic;
}

class AppSizes {
  const AppSizes._();

  static const double artworkList = 48;
  static const double artworkMini = 44;
  static const double artworkFull = 320;
  static const double miniBarHeight = 64;
  static const double playButton = 68;
  static const double navBarHeight = 62;
  static const double touchTarget = 48;
}

/// App-wide dark theme.
///
/// `main.dart` previously declared a theme that almost nothing consumed —
/// every screen set `backgroundColor` by hand. Screens now inherit from here.
ThemeData buildAppTheme() {
  const colorScheme = ColorScheme.dark(
    primary: AppColors.accent,
    onPrimary: AppColors.onAccent,
    secondary: AppColors.accent,
    onSecondary: AppColors.onAccent,
    surface: AppColors.surface,
    onSurface: AppColors.textPrimary,
    error: AppColors.danger,
    onError: AppColors.textPrimary,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: AppColors.background,
    canvasColor: AppColors.background,
    splashColor: AppColors.accent.withValues(alpha: 0.10),
    highlightColor: Colors.transparent,
    dividerColor: AppColors.divider,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.textPrimary,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
    ),
    dialogTheme: const DialogThemeData(
      backgroundColor: AppColors.surfaceElevated,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: TextStyle(
        color: AppColors.textPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      contentTextStyle: TextStyle(color: AppColors.textSecondary, fontSize: 14),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.surfaceElevated,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: AppColors.surfaceHighest,
      contentTextStyle: TextStyle(color: AppColors.textPrimary, fontSize: 14),
      behavior: SnackBarBehavior.floating,
      elevation: 0,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.background,
      selectedItemColor: AppColors.accent,
      unselectedItemColor: AppColors.textTertiary,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
    sliderTheme: const SliderThemeData(
      trackHeight: 4,
      activeTrackColor: AppColors.textPrimary,
      inactiveTrackColor: AppColors.surfaceHighest,
      thumbColor: AppColors.textPrimary,
      overlayColor: Color(0x1AFFFFFF),
      thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6),
      overlayShape: RoundSliderOverlayShape(overlayRadius: 16),
    ),
    textTheme: const TextTheme(
      titleLarge: TextStyle(
        color: AppColors.textPrimary,
        fontSize: 22,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
      ),
      titleMedium: TextStyle(
        color: AppColors.textPrimary,
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
      bodyMedium: TextStyle(color: AppColors.textSecondary, fontSize: 14),
      bodySmall: TextStyle(color: AppColors.textTertiary, fontSize: 12),
      labelSmall: TextStyle(
        color: AppColors.textTertiary,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
      ),
    ),
  );
}
