import 'package:flutter/material.dart';

import '../../theme.dart';
import '../../widgets/common.dart';
import 'employee_parts.dart';
import 'employee_widgets.dart';
import 'leave_request_screen.dart';

/// 근무 상세.
class ShiftDetailScreen extends StatelessWidget {
  const ShiftDetailScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: const AppHeader('근무 상세'),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          children: [
            const ShiftHeroCard(
              date: '5/16(금)',
              chip: 'D-2',
              time: '10:00 – 16:00',
              caption: '6시간 · 홀 서빙 · 휴게 30분',
            ),
            const SizedBox(height: 16),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('같은 시간 근무자',
                      style: AppText.style(14, FontWeight.w700, AppColors.textSecondary)),
                  const SizedBox(height: 12),
                  _coworker('지', '지민 · 오픈', AppColors.primary, AppColors.primarySoft),
                  const SizedBox(height: 12),
                  _coworker('하', '하윤 · 미들', kInfo, kInfoSoft),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const NoteBox('근무 2일 전까지 신청하면 동료에게 먼저 알림이 가요.',
                color: kInfo, background: kInfoSoft),
          ],
        ),
        bottomNavigationBar: BottomBar(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppButton(
                '휴무 · 대타 신청',
                onPressed: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LeaveRequestScreen()),
                ),
              ),
              const SizedBox(height: 10),
              AppButton(
                '닫기',
                variant: AppButtonVariant.outline,
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      );

  Widget _coworker(String letter, String name, Color fg, Color bg) => Row(
        children: [
          LetterAvatar(letter, color: fg, background: bg),
          const SizedBox(width: 12),
          Expanded(child: Text(name, style: AppText.style(15, FontWeight.w700))),
        ],
      );
}
