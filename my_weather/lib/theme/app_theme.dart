import 'package:flutter/material.dart';

import 'app_colors.dart';

/// SPEC.md「デザイン仕様」をテーマとして定義する。
///
/// - 枠線と影は使わない（elevation 0、境界線なし）
/// - カードの角丸は28
/// - 主要ボタンはAppleブルーのピル型
/// - フォントは端末標準（fontFamilyを指定しない）
class AppTheme {
  AppTheme._();

  static const double cardRadius = 28;
  static const double cardPadding = 24;
  static const double pagePadding = 20;

  static ThemeData get light => _build(Brightness.light, AppPalette.light);
  static ThemeData get dark => _build(Brightness.dark, AppPalette.dark);

  static ThemeData _build(Brightness brightness, AppPalette p) {
    final scheme = ColorScheme(
      brightness: brightness,
      primary: AppColors.accentBlue,
      onPrimary: Colors.white,
      secondary: p.text,
      onSecondary: p.background,
      error: const Color(0xFFD70015),
      onError: Colors.white,
      surface: p.surface,
      onSurface: p.text,
      onSurfaceVariant: p.subText,
      outline: Colors.transparent,
      outlineVariant: Colors.transparent,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: p.background,
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
    );

    final text = base.textTheme.apply(bodyColor: p.text, displayColor: p.text);

    return base.copyWith(
      extensions: [p],
      textTheme: text.copyWith(
        // 画面タイトル（大きな見出し）
        headlineLarge: text.headlineLarge?.copyWith(
          fontSize: 34,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        titleLarge: text.titleLarge?.copyWith(
          fontSize: 22,
          fontWeight: FontWeight.w700,
        ),
        bodyMedium: text.bodyMedium?.copyWith(fontSize: 15, height: 1.5),
        bodySmall: text.bodySmall?.copyWith(fontSize: 13, color: p.subText),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: p.background,
        foregroundColor: p.text,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: p.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(cardRadius)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.accentBlue,
          foregroundColor: Colors.white,
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
          elevation: 0,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.accentBlue,
          shape: const StadiumBorder(),
        ),
      ),
      // 選択中のチップは黒と白のモノクロ
      chipTheme: ChipThemeData(
        backgroundColor: p.surface,
        selectedColor: p.text,
        labelStyle: TextStyle(color: p.text, fontSize: 15),
        secondaryLabelStyle: TextStyle(color: p.background, fontSize: 15),
        side: BorderSide.none,
        shape: const StadiumBorder(),
        showCheckmark: false,
        elevation: 0,
        pressElevation: 0,
      ),
      dividerTheme: const DividerThemeData(
        color: Colors.transparent,
        thickness: 0,
        space: 0,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(cardRadius)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(cardRadius)),
        ),
      ),
      listTileTheme: ListTileThemeData(iconColor: p.text, textColor: p.text),
    );
  }
}
