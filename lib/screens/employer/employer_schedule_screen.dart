import 'package:flutter/material.dart';

import '../../theme.dart';
import '../../widgets/common.dart';
import 'schedule_template_screen.dart';
import 'shift_add_screen.dart';

/// 주간 근무표 편집 (Figma 47:211). 탭 루트: 하단 탭바 없음.
class EmployerScheduleScreen extends StatefulWidget {
  const EmployerScheduleScreen({super.key});

  @override
  State<EmployerScheduleScreen> createState() => _EmployerScheduleScreenState();
}

class _EmployerScheduleScreenState extends State<EmployerScheduleScreen> {
  static const _days = ['월', '화', '수', '목', '금', '토', '일'];
  static const _shifts = [
    (part: '오픈', color: AppColors.primary, bg: AppColors.primarySoft, time: '10:00 – 16:00', need: '필요 2명 · 충족', short: false, staff: '지민 · 수빈'),
    (part: '미들', color: AppColors.info, bg: AppColors.infoSoft, time: '14:00 – 20:00', need: '필요 2명 · 충족', short: false, staff: '태우 · 서연'),
    (part: '마감', color: AppColors.accent, bg: AppColors.accentSoft, time: '18:00 – 22:00', need: '필요 2명 · 1명 부족', short: true, staff: '하윤'),
  ];

  int _selected = 2;

  void _push(Widget page) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => page));

  @override
  Widget build(BuildContext context) => SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
          children: [
            Row(
              children: [
                Expanded(
                    child: Text('근무표', style: AppText.style(24, FontWeight.w700))),
                GestureDetector(
                  onTap: () => _push(const ScheduleTemplateScreen()),
                  child: Text('템플릿',
                      style: AppText.style(14, FontWeight.w700, AppColors.primary)),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                for (var i = 0; i < _days.length; i++) ...[
                  if (i > 0) const SizedBox(width: 6),
                  Expanded(child: _dayChip(i)),
                ],
              ],
            ),
            for (final s in _shifts) ...[
              const SizedBox(height: 12),
              AppCard(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Pill(s.part, color: s.color, background: s.bg),
                        const SizedBox(width: 8),
                        Expanded(
                            child:
                                Text(s.time, style: AppText.style(16, FontWeight.w700))),
                        Text(
                          s.need,
                          style: AppText.style(12, FontWeight.w400,
                              s.short ? AppColors.danger : AppColors.textSecondary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(s.staff,
                        style: AppText.style(
                            14, FontWeight.w400, AppColors.textSecondary)),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            AppButton('+ 근무 추가', onPressed: () => _push(const ShiftAddScreen())),
          ],
        ),
      );

  Widget _dayChip(int i) {
    final on = i == _selected;
    return GestureDetector(
      onTap: () => setState(() => _selected = i),
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: on ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_days[i],
                style: AppText.style(11, FontWeight.w400,
                    on ? AppColors.onPrimary : AppColors.textTertiary)),
            Text('${12 + i}',
                style: AppText.style(15, FontWeight.w700,
                    on ? AppColors.onPrimary : AppColors.textPrimary)),
          ],
        ),
      ),
    );
  }
}
