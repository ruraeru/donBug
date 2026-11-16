import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../theme.dart';
import 'web_common.dart';

/// 서버 모드 웹 로그인. 카카오 로그인 페이지로 보낸다.
class WebLoginScreen extends StatelessWidget {
  const WebLoginScreen({super.key, required this.onKakao, this.error});

  final VoidCallback onKakao;
  final String? error;

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.bg,
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: SvgPicture.asset('assets/images/app_icon.svg', width: 72, height: 72),
                ),
                const SizedBox(height: 20),
                Text('돈벌래', style: AppText.style(28, FontWeight.w700)),
                const SizedBox(height: 6),
                Text('사장님 웹 · 스마트 매장 관리',
                    style: AppText.style(14, FontWeight.w400, AppColors.textSecondary)),
                const SizedBox(height: 32),
                if (error != null) ...[
                  Text(error!,
                      textAlign: TextAlign.center,
                      style: AppText.style(13, FontWeight.w500, AppColors.danger)),
                  const SizedBox(height: 12),
                ],
                WebButton('카카오로 로그인',
                    style: WebButtonStyle.dark, height: 50, expand: true, onPressed: onKakao),
              ]),
            ),
          ),
        ),
      );
}
