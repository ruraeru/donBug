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
  static const danger = Color(0xFFE5484D);
  static const dangerSoft = Color(0xFFFDECEC);
  static const info = Color(0xFF3B82F6);
  static const infoSoft = Color(0xFFE8F0FE);

  /// 직원(유동) 근무 · 매니저 칩.
  static const purple = Color(0xFF8B5CF6);
  static const purpleSoft = Color(0xFFF0EAFE);
  static const kakao = Color(0xFFFEE500);
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
  // 키보드 포커스 · 마우스 hover 가 보이도록 초록 계열로 지정 (기본은 12% · 4% 검정).
  focusColor: AppColors.primary.withValues(alpha: 0.16),
  hoverColor: AppColors.primarySoft,
  highlightColor: AppColors.primary.withValues(alpha: 0.08),
);
