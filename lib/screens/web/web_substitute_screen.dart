import 'package:flutter/material.dart';

import '../../data/app_scope.dart';
import '../../data/app_store.dart';
import '../../data/format.dart';
import '../../data/models.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import '../employer/employer_parts.dart';
import 'web_common.dart';

/// 대타 승인 (웹). 진행 중 요청은 승인 · 거절 · 재알림 · 직접 배정, 아래는 지난 요청.
class WebSubstituteScreen extends StatelessWidget {
  const WebSubstituteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final pending = store.pendingSubs;
    final done = store.storeSubs.where((r) => !r.pending).toList();
    return WebPage(
      title: '대타 승인',
      subtitle: '진행 중 ${pending.length}건 · 승인하면 근무표에 바로 반영돼요',
      children: [
        if (pending.isEmpty)
          const AppCard(child: EmptyNote('진행 중인 대타 요청이 없어요'))
        else
          WebRow(minItemWidth: 360, children: [for (final r in pending) _RequestCard(r)]),
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            webCardTitle('지난 요청'),
            const SizedBox(height: 14),
            if (done.isEmpty) const EmptyNote('지난 요청이 없어요'),
            if (done.isNotEmpty)
              WebTable(
                columns: const ['근무', '요청', '대타', '사유', '상태'],
                flex: const [200, 100, 100, 160, 100],
                rows: [
                  for (final r in done)
                    [
                      webCellText(_shiftText(store, r)),
                      webCellText(store.nameOf(r.requesterId), color: AppColors.textPrimary),
                      webCellText(r.acceptedId == null ? '-' : store.nameOf(r.acceptedId)),
                      webCellText(r.reason),
                      _statusPill(r.status),
                    ],
                ],
              ),
          ]),
        ),
      ],
    );
  }
}

String _shiftText(AppStore store, SubstituteRequest r) {
  final s = store.shiftById(r.shiftId);
  return s == null ? '삭제된 근무' : '${shiftDay(s)} ${shiftTime(s)}';
}

Widget _statusPill(SubStatus s) => switch (s) {
      SubStatus.approved => const Pill('승인'),
      SubStatus.rejected => const Pill('거절', color: AppColors.danger, background: AppColors.dangerSoft),
      SubStatus.cancelled => const Pill('취소', color: AppColors.textSecondary, background: AppColors.bg),
      SubStatus.accepted => const Pill.accent('승인 대기'),
      SubStatus.open => const Pill.accent('지원 대기'),
    };

class _RequestCard extends StatelessWidget {
  const _RequestCard(this.r);

  final SubstituteRequest r;

  Future<void> _approve(BuildContext context) async {
    final store = AppScope.read(context);
    final ok = await showConfirmDialog(
      context,
      title: '대타를 승인할까요?',
      message:
          '${store.nameOf(r.requesterId)}님 근무를 ${store.nameOf(r.acceptedId)}님이 대신해요. 근무표에 바로 반영돼요.',
      confirmLabel: '승인',
    );
    if (!ok || !context.mounted) return;
    store.approveSubstitute(r.id);
    showToast(context, '대타를 승인했어요');
  }

  Future<void> _reject(BuildContext context) async {
    final store = AppScope.read(context);
    final ok = await showConfirmDialog(
      context,
      title: '대타 요청을 거절할까요?',
      message: '${store.nameOf(r.requesterId)}님이 원래대로 근무해요.',
      confirmLabel: '거절하기',
      confirmVariant: AppButtonVariant.danger,
    );
    if (!ok || !context.mounted) return;
    store.rejectSubstitute(r.id);
    showToast(context, '대타 요청을 거절했어요');
  }

  void _resend(BuildContext context) {
    AppScope.read(context).resendSubstitute(r.id);
    showToast(context, '동료들에게 다시 알렸어요');
  }

  Future<void> _assign(BuildContext context) async {
    final store = AppScope.read(context);
    final shift = store.shiftById(r.shiftId)!;
    final candidates = store.activeStaff
        .where((x) => x.id != r.requesterId && store.overlappingShift(x.id, shift) == null)
        .toList();
    final picked = await showWebDialog<Staff>(
      context,
      title: '대타 직접 배정',
      builder: (ctx, _) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('${shiftDay(shift)} ${shiftTime(shift)} · 그 시간에 근무가 없는 직원',
            style: AppText.style(13, FontWeight.w400, AppColors.textSecondary)),
        const SizedBox(height: 12),
        if (candidates.isEmpty) const EmptyNote('배정할 수 있는 직원이 없어요'),
        for (final s in candidates) ...[
          PersonRow(
            avatar: MemberAvatar(s),
            title: store.personOf(s).name,
            subtitle: '${s.kind.label} · ${s.part} · 시급 ${wonText(s.wage)}',
            onTap: () => Navigator.pop(ctx, s),
          ),
          const SizedBox(height: 8),
        ],
      ]),
    );
    if (picked == null || !context.mounted) return;
    store.assignSubstitute(r.id, picked.id);
    showToast(context, '${store.personOf(picked).name}님으로 대타를 확정했어요');
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final s = store.shiftById(r.shiftId);
    final requester = store.staffById(r.requesterId)!;
    final (fg, bg) = partColors(s?.part ?? '');
    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          MemberAvatar(requester, size: 36),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${store.personOf(requester).name}님 요청',
                  style: AppText.style(15, FontWeight.w700)),
              Text('${relative(DateTime.parse(r.createdAt), store.now)} · ${r.reason}',
                  style: AppText.style(12, FontWeight.w400, AppColors.textSecondary)),
            ]),
          ),
          _statusPill(r.status),
        ]),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(12)),
          child: Row(children: [
            if (s != null) ...[
              WebTag(s.part, color: fg, background: bg),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Text(_shiftText(store, r), style: AppText.style(14, FontWeight.w700)),
            ),
          ]),
        ),
        const SizedBox(height: 12),
        Text(
          r.acceptedId != null
              ? '${store.nameOf(r.acceptedId)}님이 수락했어요'
              : r.applicantIds.isEmpty
                  ? '아직 지원한 동료가 없어요'
                  : '지원 ${r.applicantIds.length}명',
          style: AppText.style(13, FontWeight.w500,
              r.acceptedId != null ? AppColors.primary : AppColors.textSecondary),
        ),
        const SizedBox(height: 14),
        Wrap(spacing: 8, runSpacing: 8, children: [
          if (r.status == SubStatus.accepted)
            WebButton('승인', height: 36, onPressed: () => _approve(context))
          else
            WebButton('재알림',
                height: 36, style: WebButtonStyle.soft, onPressed: () => _resend(context)),
          WebButton('직접 배정',
              height: 36, style: WebButtonStyle.outline, onPressed: () => _assign(context)),
          WebButton('거절',
              height: 36, style: WebButtonStyle.danger, onPressed: () => _reject(context)),
        ]),
      ]),
    );
  }
}
