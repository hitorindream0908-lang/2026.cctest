import 'package:flutter/material.dart';

/// SPEC.md「デザイン仕様」の色。ここ以外で色の値を直接書かない。
class AppColors {
  AppColors._();

  // ライト
  static const background = Color(0xFFF5F5F7);
  static const surface = Color(0xFFFFFFFF);
  static const text = Color(0xFF1D1D1F);
  static const subText = Color(0xFF6E6E73);

  // ダーク
  static const backgroundDark = Color(0xFF000000);
  static const surfaceDark = Color(0xFF1D1D1F);
  static const textDark = Color(0xFFF5F5F7);
  static const subTextDark = Color(0xFFA1A1A6);

  // 共通
  static const accentBlue = Color(0xFF0071E3);

  /// 今日の天気の主役になる黒い面（ライト・ダーク共通）
  static const hero = Color(0xFF000000);
  static const onHero = Color(0xFFFFFFFF);

  /// プレミアム要素だけに使う控えめな金色
  static const premiumGold = Color(0xFFB08D57);
}

/// テーマごとに切り替わる色をまとめて取り出すための拡張。
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.background,
    required this.surface,
    required this.text,
    required this.subText,
  });

  final Color background;
  final Color surface;
  final Color text;
  final Color subText;

  static const light = AppPalette(
    background: AppColors.background,
    surface: AppColors.surface,
    text: AppColors.text,
    subText: AppColors.subText,
  );

  static const dark = AppPalette(
    background: AppColors.backgroundDark,
    surface: AppColors.surfaceDark,
    text: AppColors.textDark,
    subText: AppColors.subTextDark,
  );

  static AppPalette of(BuildContext context) =>
      Theme.of(context).extension<AppPalette>()!;

  @override
  AppPalette copyWith({
    Color? background,
    Color? surface,
    Color? text,
    Color? subText,
  }) {
    return AppPalette(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      text: text ?? this.text,
      subText: subText ?? this.subText,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      text: Color.lerp(text, other.text, t)!,
      subText: Color.lerp(subText, other.subText, t)!,
    );
  }
}
