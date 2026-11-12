import 'package:flutter/material.dart';

import '../../data/app_scope.dart';
import '../../data/format.dart';
import '../../theme.dart';
import '../../widgets/common.dart';

/// 대타 승인 완료 (Figma 47:670).
class SubstituteDoneScreen extends StatelessWidget {
  const SubstituteDoneScreen({super.key, required this.requestId});

  final String requestId;

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final r = store.subById(requestId);
    final s = store.shiftById(r?.shiftId);
    if (r == null || s == null) return const MissingScreen();
    final from = store.nameOf(r.requesterId);
    final to = store.nameOf(r.acceptedId);
    final h = hours(s.scheduledMinutes);
    final done = [
      ('근무표 반영 완료', '$to님 일정으로 교체'),
      ('예상 급여 재할당', '$from −$h · $to +$h'),
      ('알림 발송', '두 분께 승인 알림 전송'),
    ];
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          children: [
            SuccessHero(title: '대타가 확정됐어요', subtitle: '${shiftDay(s)} ${shiftTime(s)} · $from → $to'),
            const SizedBox(height: 16),
            AppCard(
              child: Column(
                children: [
                  for (var i = 0; i < done.length; i++) ...[
                    if (i > 0) const SizedBox(height: 16),
                    StepRow(StepStatus.done, done[i].$1, done[i].$2),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            NoteBox('대타 근무는 $to님의 주휴수당 계산에서 제외돼요.',
                color: AppColors.textSecondary, background: AppColors.bg),
          ],
        ),
      ),
      bottomNavigationBar: BottomBar(children: [
        AppButton(
          '대시보드로 이동',
          // 셸(대시보드 탭)까지 되돌아간다.
          onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
        ),
      ]),
    );
  }
}
