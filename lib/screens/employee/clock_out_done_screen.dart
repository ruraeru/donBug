import 'package:flutter/material.dart';

import '../../data/app_scope.dart';
import '../../data/format.dart';
import '../../theme.dart';
import '../../widgets/common.dart';

/// 퇴근 완료: 오늘 근무 요약.
class ClockOutDoneScreen extends StatelessWidget {
  const ClockOutDoneScreen({super.key, required this.attendanceId});

  final String attendanceId;

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final a = store.attendanceById(attendanceId);
    final shift = store.shiftById(a?.shiftId);
    if (a == null || shift == null || a.clockOut == null) return const MissingScreen();
    final over = store.overtimeMinutes(a);
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          children: [
            SuccessHero(title: '오늘도 수고했어요', subtitle: '${shiftDay(shift)} 근무 요약'),
            const SizedBox(height: 16),
            AppCard(
              child: Column(
                children: [
                  KeyValueRow('출근', clock(DateTime.parse(a.clockIn))),
                  const SizedBox(height: 14),
                  KeyValueRow('퇴근', clock(DateTime.parse(a.clockOut!))),
                  const SizedBox(height: 14),
                  KeyValueRow('실근무',
                      '${duration(store.workedMinutes(a))}${shift.breakMin > 0 ? ' (휴게 ${shift.breakMin}분)' : ''}'),
                  const SizedBox(height: 14),
                  KeyValueRow('연장 근무', over > 0 ? duration(over) : '없음'),
                  const SizedBox(height: 14),
                  const Divider(height: 1, color: AppColors.border),
                  const SizedBox(height: 14),
                  KeyValueRow('오늘 일급', won(store.dayPay(a)),
                      valueSize: 20,
                      valueColor: AppColors.primary,
                      labelStyle: AppText.style(15, FontWeight.w700)),
                ],
              ),
            ),
          ],
        ),
      ),
      // true 를 돌려주면 홈이 근무표 탭으로 전환한다.
      bottomNavigationBar: BottomBar(
        child: AppButton('근무표 보기', onPressed: () => Navigator.pop(context, true)),
      ),
    );
  }
}
