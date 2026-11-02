import 'package:flutter/material.dart';

import '../../theme.dart';
import '../../widgets/common.dart';
import 'attendance_detail_screen.dart';
import 'employer_widgets.dart';

/// 오늘 근태 현황 (Figma 47:402).
class AttendanceScreen extends StatelessWidget {
  const AttendanceScreen({super.key});

  static const _rows = [
    (initial: '지', name: '지민', sub: '10:00 출근 · 정상', status: '출근', color: AppColors.primary, bg: AppColors.primarySoft),
    (initial: '수', name: '수빈', sub: '10:12 출근 · 12분 지각', status: '지각', color: EmpColors.danger, bg: EmpColors.dangerSoft),
    (initial: '태', name: '태우', sub: '14:02 출근 · 근무 중', status: '근무 중', color: EmpColors.info, bg: EmpColors.infoSoft),
    (initial: '하', name: '하윤', sub: '18:00 출근 예정', status: '대기', color: AppColors.accent, bg: AppColors.accentSoft),
  ];

  static const _summary = [
    (label: '출근', count: '2', color: AppColors.primary, bg: AppColors.primarySoft),
    (label: '지각', count: '1', color: EmpColors.danger, bg: EmpColors.dangerSoft),
    (label: '대기', count: '1', color: AppColors.accent, bg: AppColors.accentSoft),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppHeader('오늘 근태', actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: Center(
              child: Text('5/14',
                  style: AppText.style(14, FontWeight.w700, AppColors.primary)),
            ),
          ),
        ]),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          children: [
            Row(
              children: [
                for (var i = 0; i < _summary.length; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: _summary[i].bg,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Text(_summary[i].label,
                              style: AppText.style(
                                  12, FontWeight.w400, _summary[i].color)),
                          const SizedBox(height: 2),
                          Text(_summary[i].count,
                              style: AppText.style(
                                  22, FontWeight.w700, _summary[i].color)),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
            for (final r in _rows) ...[
              const SizedBox(height: 10),
              PersonRow(
                avatar: InitialAvatar(r.initial, color: r.color, background: r.bg),
                title: r.name,
                subtitle: r.sub,
                trailing: Pill(r.status, color: r.color, background: r.bg),
                // 더미: 상세 화면은 수빈(지각) 기록만 있다.
                onTap: r.name == '수빈'
                    ? () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const AttendanceDetailScreen()),
                        )
                    : null,
              ),
            ],
          ],
        ),
      );
}
