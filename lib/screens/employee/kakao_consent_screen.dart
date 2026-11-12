import 'package:flutter/material.dart';

import '../../theme.dart';
import '../../widgets/common.dart';
import 'login_screen.dart';
import 'role_select_screen.dart';
import 'employee_parts.dart';

/// 카카오 동의 (데모: 실제 카카오 연동 없음).
class KakaoConsentScreen extends StatefulWidget {
  const KakaoConsentScreen({super.key});

  @override
  State<KakaoConsentScreen> createState() => _KakaoConsentScreenState();
}

class _KakaoConsentScreenState extends State<KakaoConsentScreen> {
  // 프로필(필수) · 이메일(필수) · 연락처(선택)
  final _on = [true, true, false];

  bool get _all => _on.every((v) => v);

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
                  Text('돈벌래가 아래 정보에\n접근하려고 해요',
                      style: AppText.style(22, FontWeight.w500)),
                  const SizedBox(height: 6),
                  Text('동의하면 3초 만에 가입돼요',
                      style: AppText.style(
                          14, FontWeight.w400, AppColors.textSecondary)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            AppCard(
              child: Column(
                children: [
                  CheckLine('전체 동의',
                      value: _all,
                      onChanged: (v) => setState(() => _on.fillRange(0, _on.length, v))),
                  const SizedBox(height: 16),
                  const Divider(height: 1, color: AppColors.border),
                  const SizedBox(height: 16),
                  CheckLine('프로필 정보 (닉네임, 프로필 사진)',
                      caption: '필수', value: _on[0], onChanged: (v) => setState(() => _on[0] = v)),
                  const SizedBox(height: 16),
                  CheckLine('카카오계정 (이메일)',
                      caption: '필수', value: _on[1], onChanged: (v) => setState(() => _on[1] = v)),
                  const SizedBox(height: 16),
                  CheckLine('연락처 (전화번호)',
                      caption: '선택 · 대타 알림 연락용',
                      value: _on[2],
                      onChanged: (v) => setState(() => _on[2] = v)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text('동의 후에도 카카오 계정 설정에서 언제든 철회할 수 있어요.',
                style: AppText.style(12, FontWeight.w400, AppColors.textTertiary)),
          ],
        ),
        bottomNavigationBar: BottomBar(
          child: KakaoButton('동의하고 계속하기', onPressed: () {
            if (!_on[0] || !_on[1]) return showToast(context, '필수 항목에 동의해 주세요');
            Navigator.push(
                context, MaterialPageRoute(builder: (_) => const RoleSelectScreen()));
          }),
        ),
      );
}
