import 'package:flutter/material.dart';

import '../../data/app_scope.dart';
import '../../data/format.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import 'employee_parts.dart';
import 'leave_request_screen.dart';
import 'substitute_status_screen.dart';

/// 근무 상세: 같은 시간 근무자 · 휴무·대타 신청.
class ShiftDetailScreen extends StatelessWidget {
  const ShiftDetailScreen({super.key, required this.shiftId});

  final String shiftId;

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final s = store.shiftById(shiftId);
    if (s == null) return const MissingScreen(title: '근무 상세');
    final (status, _, _) = shiftStatus(store, s);
    final coworkers = store.shiftsOn(parseYmd(s.date)).where((x) =>
        x.staffId != s.staffId &&
        store.shiftStart(x).isBefore(store.shiftEnd(s)) &&
        store.shiftEnd(x).isAfter(store.shiftStart(s)));
    final req = store.pendingSubFor(s.id);
    final canRequest = req == null &&
        store.attendanceFor(s.id) == null &&
        store.shiftStart(s).isAfter(store.now);
    return Scaffold(
      appBar: const AppHeader('근무 상세'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        children: [
          ShiftHeroCard(
            date: shiftDay(s),
            chip: status,
            time: shiftTime(s),
            caption: shiftCaption(s) + (s.isSubstitute ? ' · 대타 근무' : ''),
          ),
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('같은 시간 근무자',
                    style: AppText.style(14, FontWeight.w700, AppColors.textSecondary)),
                if (coworkers.isEmpty) const EmptyNote('같은 시간에 근무하는 동료가 없어요'),
                for (final c in coworkers) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      MemberAvatar(store.staffById(c.staffId)!),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text('${store.nameOf(c.staffId)} · ${c.part} ${shiftTime(c)}',
                            style: AppText.style(15, FontWeight.w700)),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          const NoteBox('근무 2일 전까지 신청하면 동료에게 먼저 알림이 가요.',
              color: AppColors.info, background: AppColors.infoSoft),
        ],
      ),
      bottomNavigationBar: BottomBar(
        children: [
          if (canRequest)
            AppButton(
              '휴무 · 대타 신청',
              onPressed: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => LeaveRequestScreen(shiftId: s.id)),
              ),
            ),
          if (req != null)
            AppButton(
              '대타 요청 현황 보기',
              onPressed: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const SubstituteStatusScreen()),
              ),
            ),
          AppButton('닫기',
              variant: AppButtonVariant.outline, onPressed: () => Navigator.pop(context)),
        ],
      ),
    );
  }
}

