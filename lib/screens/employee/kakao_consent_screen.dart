import 'package:flutter/material.dart';

import '../../theme.dart';
import '../../widgets/common.dart';
import 'employee_widgets.dart';
import 'login_screen.dart';
import 'role_select_screen.dart';

/// 카카오 동의.
class KakaoConsentScreen extends StatelessWidget {
  const KakaoConsentScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: const AppHeader('카카오 로그인'),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('돈벌래이(가) 아래 정보에\n접근하려고 해요',
                      style: AppText.style(22, FontWeight.w700)),
                  const SizedBox(height: 6),
                  Text('동의하면 3초 만에 가입돼요',
                      style: AppText.style(
                          14, FontWeight.w400, AppColors.textSecondary)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const AppCard(
              child: Column(
                children: [
                  CheckLine('전체 동의'),
                  SizedBox(height: 16),
                  Divider(height: 1, color: AppColors.border),
                  SizedBox(height: 16),
                  CheckLine('프로필 정보 (닉네임, 프로필 사진)', caption: '필수'),
                  SizedBox(height: 16),
                  CheckLine('카카오계정 (이메일)', caption: '필수'),
                  SizedBox(height: 16),
                  CheckLine('연락처 (전화번호)', caption: '선택 · 대타 알림 연락용'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text('동의 후에도 카카오 계정 설정에서 언제든 철회할 수 있어요.',
                style: AppText.style(12, FontWeight.w400, AppColors.textTertiary)),
          ],
        ),
        bottomNavigationBar: BottomBar(
          child: KakaoButton('동의하고 계속하기',
              onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const RoleSelectScreen()))),
        ),
      );
}
