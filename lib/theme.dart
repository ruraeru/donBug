import 'package:flutter/material.dart';

/// Figma 변수(앱 디자인 v2)와 1:1 대응하는 색상 토큰.
class AppColors {
  static const primary = Color(0xFF1F8A5B);
  static const primarySoft = Color(0xFFE6F4EE);
  static const onPrimary = Color(0xFFFFFFFF);
  static const accent = Color(0xFFF5A524);
  static const accentSoft = Color(0xFFFFF4DE);
  static const surface = Color(0xFFFFFFFF);
  static const bg = Color(0xFFF4F5F7);
  static const border = Color(0xFFE5E8EB);
  static const textPrimary = Color(0xFF191F28);
  static const textSecondary = Color(0xFF6B7684);
  static const textTertiary = Color(0xFFA0A8B3);
}

/// Figma 텍스트는 전부 line-height 1.4. 예: `AppText.style(15, FontWeight.w700)`.
class AppText {
  static TextStyle style(
    double size, [
    FontWeight weight = FontWeight.w400,
    Color color = AppColors.textPrimary,
  ]) =>
      TextStyle(fontSize: size, fontWeight: weight, color: color, height: 1.4);
}

final appTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    primary: AppColors.primary,
    surface: AppColors.surface,
  ),
  scaffoldBackgroundColor: AppColors.bg,
  fontFamily: 'Noto Sans KR',
  dividerColor: AppColors.border,
);
