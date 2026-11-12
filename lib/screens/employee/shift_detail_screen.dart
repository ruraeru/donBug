import 'package:flutter/material.dart';

import '../../data/app_scope.dart';
import '../../data/format.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import '../employer/employer_parts.dart';
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
    final (status, _, statusBg) = shiftStatus(store, s);
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
            alert: statusBg != Colors.transparent,
            time: shiftTime(s),
            caption: shiftCaption(s) + (s.isSubstitute ? ' · 대타 근무' : ''),
          ),
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('같은 시간 근무자',
                    style: AppText.style(14, FontWeight.w500, AppColors.textSecondary)),
                if (coworkers.isEmpty) const EmptyNote('같은 시간에 근무하는 동료가 없어요'),
                for (final c in coworkers) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      MemberAvatar(store.staffById(c.staffId)!),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Row(children: [
                          Text(store.nameOf(c.staffId),
                              style: AppText.style(15, FontWeight.w500)),
                          const SizedBox(width: 8),
                          Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                  color: partColors(c.part).$1, shape: BoxShape.circle)),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text('${c.part} ${shiftTime(c)}',
                                overflow: TextOverflow.ellipsis,
                                style: AppText.style(15, FontWeight.w400, AppColors.textSecondary)),
                          ),
                        ]),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          const NoteBox('근무 2일 전까지 신청하면 동료에게 먼저 알림이 가요.',
              color: AppColors.textSecondary, background: AppColors.surface),
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

