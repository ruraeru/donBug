import 'package:flutter/material.dart';

import '../../theme.dart';
import 'kakao_consent_screen.dart';

const kKakao = Color(0xFFFEE500);

/// A1 로그인 (앱 진입점).
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.surface,
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 88,
                        height: 88,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(28),
                        ),
                        child: Text('₩',
                            style: AppText.style(
                                44, FontWeight.w700, AppColors.onPrimary)),
                      ),
                      const SizedBox(height: 16),
                      Text('돈벌래', style: AppText.style(34, FontWeight.w700)),
                      const SizedBox(height: 16),
                      Text(
                        '사장님의 행정 부담은 덜고,\n알바생의 권리는 지키는\n스마트 매장 관리',
                        textAlign: TextAlign.center,
                        style: AppText.style(
                                16, FontWeight.w400, AppColors.textSecondary)
                            .copyWith(height: 1.5),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 48),
                child: Column(
                  children: [
                    KakaoButton('카카오로 시작하기',
                        onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const KakaoConsentScreen()))),
                    const SizedBox(height: 12),
                    Text('로그인 후 사장님 / 알바생 역할을 선택해요',
                        style: AppText.style(
                            13, FontWeight.w400, AppColors.textTertiary)),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}

/// 카카오 노란 버튼 (radius 14).
class KakaoButton extends StatelessWidget {
  const KakaoButton(this.label, {super.key, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Material(
        color: kKakao,
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
                child: Text(label, style: AppText.style(16, FontWeight.w700))),
          ),
        ),
      );
}
