import 'package:flutter/material.dart';

import '../../theme.dart';
import '../../widgets/common.dart';
import '../../widgets/demo_menu.dart';

/// 매장 설정.
class StoreSettingsScreen extends StatefulWidget {
  const StoreSettingsScreen({super.key});

  @override
  State<StoreSettingsScreen> createState() => _StoreSettingsScreenState();
}

class _StoreSettingsScreenState extends State<StoreSettingsScreen> {
  final _on = [true, true, true];

  static const _toggles = [
    ('5인 미만 사업장', '가산수당·연차 계산 기준에 반영'),
    ('공지 필독 기본 설정', '새 공지는 기본으로 필독 지정'),
    ('대타 알림 푸시', '동료 알바생에게 자동 알림'),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: const AppHeader('매장 설정'),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          children: [
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('카페 커푸치노', style: AppText.style(18, FontWeight.w700)),
                  const SizedBox(height: 12),
                  Text('서울특별시 마포구 와우산로 94',
                      style: AppText.style(
                          13, FontWeight.w400, AppColors.textSecondary)),
                  const SizedBox(height: 12),
                  const Divider(height: 1, color: AppColors.border),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Text('매장 코드',
                            style: AppText.style(
                                14, FontWeight.w400, AppColors.textSecondary)),
                      ),
                      Text('CAFE-8K2D',
                          style: AppText.style(
                              15, FontWeight.w700, AppColors.primary)),
                    ],
                  ),
                ],
              ),
            ),
            for (var i = 0; i < _toggles.length; i++) ...[
              const SizedBox(height: 12),
              AppCard(
                radius: 16,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                onTap: () => setState(() => _on[i] = !_on[i]),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_toggles[i].$1,
                              style: AppText.style(15, FontWeight.w700)),
                          const SizedBox(height: 2),
                          Text(_toggles[i].$2,
                              style: AppText.style(12, FontWeight.w400,
                                  AppColors.textSecondary)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    _Toggle(_on[i]),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            PersonRow(
              avatar: const LetterAvatar('로',
                  color: AppColors.textSecondary, background: AppColors.bg),
              title: '로그아웃',
              trailing: Text('›',
                  style:
                      AppText.style(22, FontWeight.w400, AppColors.textTertiary)),
              onTap: () => logoutToLogin(context),
            ),
            const SizedBox(height: 24),
            const DemoMenu(),
          ],
        ),
      );
}

/// Figma 토글(48x28, primary 트랙). 탭은 감싼 카드가 처리.
class _Toggle extends StatelessWidget {
  const _Toggle(this.on);

  final bool on;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 48,
        height: 28,
        padding: const EdgeInsets.all(3),
        alignment: on ? Alignment.centerRight : Alignment.centerLeft,
        decoration: BoxDecoration(
          color: on ? AppColors.primary : AppColors.border,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Container(
          width: 22,
          height: 22,
          decoration: const BoxDecoration(
            color: AppColors.surface,
            shape: BoxShape.circle,
          ),
        ),
      );
}
