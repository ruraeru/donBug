import 'package:flutter/material.dart';

import '../../theme.dart';
import '../../widgets/common.dart';
import 'employee_parts.dart';

/// 보건증 등록: 사진 업로드 · 만료일 · 만료 알림.
class HealthCertRegisterScreen extends StatelessWidget {
  const HealthCertRegisterScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: const AppHeader('보건증 등록'),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          children: [
            Container(
              height: 180,
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add, size: 40, color: AppColors.primary),
                  const SizedBox(height: 8),
                  Text('보건증 사진 올리기', style: AppText.style(15, FontWeight.w700)),
                  const SizedBox(height: 8),
                  Text('카메라 촬영 또는 앨범에서 선택',
                      style: AppText.style(12, FontWeight.w400, AppColors.textSecondary)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text('만료일', style: AppText.style(14, FontWeight.w700, AppColors.textSecondary)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text('2027.05.25', style: AppText.style(15)),
            ),
            const SizedBox(height: 16),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('만료 알림 받기',
                      style: AppText.style(14, FontWeight.w700, AppColors.textSecondary)),
                  const SizedBox(height: 14),
                  const CheckLine('D-30', caption: '한 달 전 알림'),
                  const SizedBox(height: 14),
                  const CheckLine('D-14'),
                  const SizedBox(height: 14),
                  const CheckLine('D-7'),
                  const SizedBox(height: 14),
                  const CheckLine('D-Day'),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: BottomBar(
          child: AppButton('등록하기', onPressed: () => Navigator.pop(context)),
        ),
      );
}
