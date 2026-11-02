import 'package:flutter/material.dart';

import '../../theme.dart';
import '../../widgets/common.dart';

/// 근태 상세 · 수정 (Figma 47:453).
class AttendanceDetailScreen extends StatelessWidget {
  const AttendanceDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final small = AppText.style(12, FontWeight.w400, AppColors.textSecondary);
    return Scaffold(
      appBar: const AppHeader('근태 상세 · 수정'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        children: [
          AppCard(
            child: Column(
              children: [
                Row(
                  children: [
                    const LetterAvatar('수',
                        color: AppColors.danger, background: AppColors.dangerSoft),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('수빈 · 오픈', style: AppText.style(16, FontWeight.w700)),
                          Text('5/14(수) 예정 10:00 – 16:00', style: small),
                        ],
                      ),
                    ),
                    const Pill('지각 12분',
                        color: AppColors.danger, background: AppColors.dangerSoft),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1, color: AppColors.border),
                const SizedBox(height: 12),
                const KeyValueRow('실제 출근', '10:12'),
                const SizedBox(height: 12),
                const KeyValueRow('실제 퇴근', '16:05'),
                const SizedBox(height: 12),
                const KeyValueRow('인증 방식', 'QR'),
                const SizedBox(height: 12),
                const KeyValueRow('연장 근무', '5분'),
              ],
            ),
          ),
          const SizedBox(height: 14),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('기록 수정',
                    style: AppText.style(14, FontWeight.w700, AppColors.textSecondary)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _timeField('출근', '10:00', small)),
                    const SizedBox(width: 12),
                    Expanded(child: _timeField('퇴근', '16:05', small)),
                  ],
                ),
                const SizedBox(height: 12),
                _greyBox(Text('수정 사유 (필수): 지하철 지연, 사전 연락 받음',
                    style: AppText.style(13, FontWeight.w400, AppColors.textSecondary))),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const NoteBox(
            '수정하면 기록이 MANUAL로 남고 급여가 자동으로 다시 계산돼요.',
            color: AppColors.accent,
            background: AppColors.accentSoft,
          ),
        ],
      ),
      bottomNavigationBar: BottomBar(children: [
        AppButton('수정 저장', onPressed: () => Navigator.pop(context)),
      ]),
    );
  }

  Widget _timeField(String label, String value, TextStyle labelStyle) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: labelStyle),
          const SizedBox(height: 6),
          _greyBox(Text(value, style: AppText.style(15, FontWeight.w700))),
        ],
      );

  Widget _greyBox(Widget child) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.bg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: child,
      );
}
