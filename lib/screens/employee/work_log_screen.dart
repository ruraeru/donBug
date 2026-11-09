import 'package:flutter/material.dart';

import '../../data/app_scope.dart';
import '../../data/format.dart';
import '../../data/payroll.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import 'employee_parts.dart';

/// 일자별 근무 내역 (실제 출퇴근 기록).
class WorkLogScreen extends StatefulWidget {
  const WorkLogScreen({super.key, required this.month});

  final DateTime month;

  @override
  State<WorkLogScreen> createState() => _WorkLogScreenState();
}

class _WorkLogScreenState extends State<WorkLogScreen> {
  late DateTime _month = widget.month;

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final me = store.myStaff!;
    final slip = store.payslip(me.id, _month.year, _month.month);
    final logs = slip.entries.reversed.toList();
    return Scaffold(
      appBar: AppHeader('일자별 근무 내역', actions: [
        MonthNav(month: _month, max: store.today, onChanged: (m) => setState(() => _month = m)),
      ]),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        children: [
          if (logs.isEmpty) const EmptyNote('이 달 출퇴근 기록이 없어요'),
          for (final e in logs) ...[
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
                            Text(md(e.day), style: AppText.style(15, FontWeight.w700)),
                            if (e.isSubstitute) ...[
                              const SizedBox(width: 6),
                              const Pill.accent('대타'),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text('${clock(e.start)}–${clock(e.end)} · ${duration(e.minutes)}',
                            style: AppText.style(12, FontWeight.w400, AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(wonText(payFor(e.minutes, me.wage)), style: AppText.style(15, FontWeight.w700)),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
          AppCard(
            child: Column(
              children: [
                KeyValueRow('${_month.month}월 누적', duration(slip.minutes)),
                const SizedBox(height: 8),
                KeyValueRow('지금까지 실수령액', won(slip.net)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
