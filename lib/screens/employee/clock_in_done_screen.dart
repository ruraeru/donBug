import 'package:flutter/material.dart';

import '../../data/app_scope.dart';
import '../../data/format.dart';
import '../../theme.dart';
import '../../widgets/common.dart';

/// 출근 완료 → 홈(근무 중).
class ClockInDoneScreen extends StatelessWidget {
  const ClockInDoneScreen({super.key, required this.attendanceId});

  final String attendanceId;

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final a = store.attendanceById(attendanceId);
    final shift = store.shiftById(a?.shiftId);
    if (a == null || shift == null) return const MissingScreen();
    final late = store.lateMinutes(shift);
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          children: [
            SuccessHero(
                title: '출근이 완료됐어요',
                subtitle: '${clock(DateTime.parse(a.clockIn))} · QR 스캔 인증'),
            const SizedBox(height: 16),
            AppCard(
              child: Column(
                children: [
                  KeyValueRow('오늘 근무', shiftTime(shift)),
                  const SizedBox(height: 12),
                  const KeyValueRow('인증 방식', '매장 POS QR'),
                  const SizedBox(height: 12),
                  KeyValueRow('지각 여부', late > 0 ? '$late분 지각' : '정상 출근',
                      valueColor: late > 0 ? AppColors.danger : AppColors.textPrimary),
                  const SizedBox(height: 12),
                  KeyValueRow('예상 일급', won(store.plannedPay(shift))),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const NoteBox('퇴근도 같은 방법으로 인증하면 근무시간이 자동 계산돼요.',
                color: AppColors.textSecondary, background: AppColors.surface),
          ],
        ),
      ),
      bottomNavigationBar: BottomBar(
        child: AppButton('홈으로 가기', onPressed: () => Navigator.pop(context)),
      ),
    );
  }
}
