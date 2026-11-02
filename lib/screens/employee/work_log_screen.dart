import 'package:flutter/material.dart';

import '../../theme.dart';
import '../../widgets/common.dart';

/// 일자별 근무 내역.
class WorkLogScreen extends StatelessWidget {
  const WorkLogScreen({super.key});

  static const _logs = [
    ('5/14 수', '14:00–20:00 · 5시간 33분', '55,667원', false),
    ('5/12 월', '10:00–16:00 · 5시간 30분', '55,165원', false),
    ('5/10 토', '18:00–22:00 · 4시간', '40,120원', true),
    ('5/08 목', '14:00–20:00 · 5시간 30분', '55,165원', false),
    ('5/06 화', '10:00–16:00 · 5시간 30분', '55,165원', false),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppHeader('일자별 근무 내역', actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: Center(
              child: Text('5월',
                  style: AppText.style(14, FontWeight.w700, AppColors.primary)),
            ),
          ),
        ]),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          children: [
            for (final (date, time, pay, substitute) in _logs) ...[
              AppCard(
                radius: 16,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(date, style: AppText.style(15, FontWeight.w700)),
                              if (substitute) ...[
                                const SizedBox(width: 6),
                                const Pill.accent('대타'),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(time,
                              style: AppText.style(
                                  12, FontWeight.w400, AppColors.textSecondary)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(pay, style: AppText.style(15, FontWeight.w700)),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],
            const AppCard(
              child: Column(
                children: [
                  KeyValueRow('이번 달 누적', '62시간'),
                  SizedBox(height: 8),
                  KeyValueRow('이번 달 예상 실수령액', '₩842,257'),
                ],
              ),
            ),
          ],
        ),
      );
}
