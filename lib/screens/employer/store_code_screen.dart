import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme.dart';
import '../../widgets/common.dart';
import 'staff_approval_screen.dart';
import 'employer_parts.dart';

/// 매장 코드 공유 (Figma 47:78).
class StoreCodeScreen extends StatelessWidget {
  const StoreCodeScreen({super.key});

  static const _code = 'CAFE-8K2D';

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            children: [
              const SuccessHero(
                title: '매장이 만들어졌어요',
                subtitle: '직원에게 매장 코드를 알려주세요',
              ),
              const SizedBox(height: 16),
              AppCard(
                child: Column(
                  children: [
                    Text('매장 코드',
                        style: AppText.style(
                            13, FontWeight.w400, AppColors.textSecondary)),
                    const SizedBox(height: 12),
                    Text(_code,
                        style: AppText.style(
                            32, FontWeight.w700, AppColors.primary)),
                    const SizedBox(height: 12),
                    Container(
                      width: 140,
                      height: 140,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.bg,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text('QR',
                          style: AppText.style(
                              28, FontWeight.w700, AppColors.textTertiary)),
                    ),
                    const SizedBox(height: 12),
                    SmallButton(
                      '코드 복사',
                      background: AppColors.primarySoft,
                      color: AppColors.primary,
                      onPressed: () => Clipboard.setData(
                          const ClipboardData(text: _code)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: BottomBar(children: [
          AppButton(
            '직원 승인하러 가기',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const StaffApprovalScreen()),
            ),
          ),
          Material(
            color: AppColors.kakao,
            borderRadius: BorderRadius.circular(14),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () {},
              child: Container(
                height: 54,
                alignment: Alignment.center,
                child: Text('카카오톡으로 코드 공유',
                    style: AppText.style(16, FontWeight.w700)),
              ),
            ),
          ),
        ]),
      );
}
