import 'package:flutter/material.dart';

import '../../data/app_scope.dart';
import '../../data/app_store.dart';
import '../../data/format.dart';
import '../../data/models.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import 'substitute_detail_screen.dart';
import 'substitute_done_screen.dart';

/// 대타 요청 현황: 내 요청 / 지원 가능 세그먼트.
class SubstituteStatusScreen extends StatefulWidget {
  const SubstituteStatusScreen({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  State<SubstituteStatusScreen> createState() => _SubstituteStatusScreenState();
}

class _SubstituteStatusScreenState extends State<SubstituteStatusScreen> {
  late int _tab = widget.initialTab;

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    return Scaffold(
      appBar: const AppHeader('대타'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Expanded(child: _segment(0, '내 요청')),
                const SizedBox(width: 4),
                Expanded(child: _segment(1, '지원 가능 ${store.subsAvailableToMe.length}')),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (_tab == 0) ..._myRequests(context, store) else ..._available(context, store),
        ],
      ),
    );
  }

  Widget _segment(int i, String label) {
    final selected = _tab == i;
    return Material(
      color: selected ? AppColors.primary : Colors.transparent,
      borderRadius: BorderRadius.circular(11),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => setState(() => _tab = i),
        child: SizedBox(
          height: 40,
          child: Center(
            child: Text(
              label,
              style: AppText.style(
                  14, FontWeight.w500, selected ? AppColors.onPrimary : AppColors.textTertiary),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _myRequests(BuildContext context, AppStore store) {
    final list = store.mySubs;
    if (list.isEmpty) return [const EmptyNote('보낸 대타 요청이 없어요')];
    return [
      for (final r in list) ...[
        _RequestCard(request: r),
        const SizedBox(height: 12),
      ],
    ];
  }

  List<Widget> _available(BuildContext context, AppStore store) {
    final list = store.subsAvailableToMe;
    if (list.isEmpty) return [const EmptyNote('지금 지원할 수 있는 대타 요청이 없어요')];
    return [
      for (final r in list) ...[
        PersonRow(
          avatar: MemberAvatar(store.staffById(r.requesterId)!),
          title: '${shiftDay(store.shiftById(r.shiftId)!)} ${shiftTime(store.shiftById(r.shiftId)!)}',
          subtitle: '${store.nameOf(r.requesterId)}님의 요청 · ${r.reason}',
          trailing: const Pill.accent('대타 구해요'),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => SubstituteDetailScreen(requestId: r.id)),
          ),
        ),
        const SizedBox(height: 12),
      ],
    ];
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.request});

  final SubstituteRequest request;

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final r = request;
    final s = store.shiftById(r.shiftId);
    if (s == null) return const SizedBox.shrink();
    final approved = r.status == SubStatus.approved;
    final rejected = r.status == SubStatus.rejected;
    final accepted = r.acceptedId != null;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('${shiftDay(s)} ${shiftTime(s)}',
                    style: AppText.style(17, FontWeight.w500)),
              ),
              Pill.accent(subStatusLabel(r)),
            ],
          ),
          const SizedBox(height: 16),
          Text('사유: ${r.reason}',
              style: AppText.style(13, FontWeight.w400, AppColors.textSecondary)),
          const SizedBox(height: 16),
          StepRow(StepStatus.done, '요청 전송',
              relative(DateTime.parse(r.createdAt), store.now)),
          const SizedBox(height: 16),
          StepRow(
            accepted ? StepStatus.done : (r.pending ? StepStatus.current : StepStatus.pending),
            '동료 수락',
            accepted ? '${store.nameOf(r.acceptedId)}님이 수락했어요' : '지원 대기 중',
          ),
          const SizedBox(height: 16),
          StepRow(
            approved || rejected
                ? StepStatus.done
                : (r.status == SubStatus.accepted ? StepStatus.current : StepStatus.pending),
            '사장님 승인',
            approved ? '승인됨' : (rejected ? '거절됨 · 근무는 그대로예요' : '대기'),
          ),
          const SizedBox(height: 16),
          StepRow(approved ? StepStatus.done : StepStatus.pending, '근무표 반영',
              approved ? '${store.nameOf(s.staffId)}님 근무로 바뀌었어요' : '승인 후 자동 반영'),
          if (r.pending) ...[
            const SizedBox(height: 16),
            if (r.status == SubStatus.open) ...[
              AppButton(
                '동료 수락 (데모)',
                variant: AppButtonVariant.soft,
                onPressed: () {
                  final ok = AppScope.read(context).simulatePeerAccept(r.id);
                  showToast(context, ok ? '동료가 대타를 수락했어요' : '수락할 수 있는 동료가 없어요');
                },
              ),
              const SizedBox(height: 10),
            ],
            AppButton(
              '요청 취소',
              variant: AppButtonVariant.danger,
              onPressed: () async {
                final ok = await showConfirmDialog(context,
                    title: '대타 요청을 취소할까요?',
                    message: '${shiftDay(s)} 근무는 원래대로 내가 해요.',
                    confirmLabel: '요청 취소',
                    confirmVariant: AppButtonVariant.danger);
                if (ok && context.mounted) AppScope.read(context).cancelSubstitute(r.id);
              },
            ),
          ],
        ],
      ),
    );
  }
}
