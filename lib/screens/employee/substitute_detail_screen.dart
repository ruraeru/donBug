import 'package:flutter/material.dart';

import '../../data/app_scope.dart';
import '../../data/format.dart';
import '../../data/models.dart';
import '../../data/payroll.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import 'employee_parts.dart';
import 'substitute_done_screen.dart';

/// 동료 대타 상세 ("대타 구해요").
class SubstituteDetailScreen extends StatelessWidget {
  const SubstituteDetailScreen({super.key, required this.requestId});

  final String requestId;

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final r = store.subById(requestId);
    final s = store.shiftById(r?.shiftId);
    final me = store.myStaff;
    if (r == null || s == null || me == null) return const MissingScreen(title: '대타 구해요');
    final overlap = store.overlappingShift(me.id, s);
    final monday = mondayOf(parseYmd(s.date));
    final weekMinutes = store.myShifts
        .where((x) {
          final d = parseYmd(x.date);
          return !d.isBefore(monday) && d.isBefore(monday.add(const Duration(days: 7)));
        })
        .fold(0, (sum, x) => sum + x.scheduledMinutes);
    final applied = r.applicantIds.contains(me.id);
    final closed = r.status != SubStatus.open;

    final Widget button;
    if (applied) {
      button = const AppButton('지원 완료 · 승인 대기', variant: AppButtonVariant.outline);
    } else if (closed) {
      button = AppButton('마감된 요청 · ${subStatusLabel(r)}', variant: AppButtonVariant.outline);
    } else if (overlap != null) {
      button = const AppButton('근무 시간이 겹쳐 지원할 수 없어요', variant: AppButtonVariant.outline);
    } else {
      button = AppButton(
        '지원하기',
        onPressed: () {
          AppScope.read(context).applySubstitute(r.id);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (_) => SubstituteDoneScreen(SubstituteDoneKind.apply, requestId: r.id)),
          );
        },
      );
    }

    return Scaffold(
      appBar: const AppHeader('대타 구해요'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        children: [
          ShiftHeroCard(
            date: shiftDay(s),
            chip: '대타 구해요',
            time: shiftTime(s),
            caption: shiftCaption(s),
          ),
          const SizedBox(height: 16),
          AppCard(
            child: Row(
              children: [
                MemberAvatar(store.staffById(r.requesterId)!),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${store.nameOf(r.requesterId)}님의 요청',
                          style: AppText.style(15, FontWeight.w500)),
                      const SizedBox(height: 1),
                      Text('사유: ${r.reason} · ${relative(DateTime.parse(r.createdAt), store.now)}',
                          style: AppText.style(12, FontWeight.w400, AppColors.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('내 상황 확인',
                    style: AppText.style(14, FontWeight.w500, AppColors.textSecondary)),
                const SizedBox(height: 12),
                KeyValueRow('이 시간 내 근무', overlap == null ? '없음' : '있음 · ${shiftTime(overlap)}',
                    valueColor: overlap == null ? AppColors.textPrimary : AppColors.danger),
                const SizedBox(height: 12),
                KeyValueRow('예상 수입', won(payFor(s.scheduledMinutes, me.wage))),
                const SizedBox(height: 12),
                KeyValueRow('그 주 내 근무', hours(weekMinutes)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const NoteBox('대타 근무는 주휴수당 계산에서 제외돼요. 사장님 승인 후 확정됩니다.',
              color: AppColors.accent, background: AppColors.accentSoft),
        ],
      ),
      bottomNavigationBar: BottomBar(child: button),
    );
  }
}
