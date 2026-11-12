import 'package:flutter/material.dart';

import '../../data/app_scope.dart';
import '../../data/app_store.dart';
import '../../data/format.dart';
import '../../data/models.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import 'employer_parts.dart';
import 'substitute_done_screen.dart';

/// B4 대타 승인 (Figma 47:573). 진행 중인 요청 전부.
class SubstituteApprovalScreen extends StatelessWidget {
  const SubstituteApprovalScreen({super.key});

  Future<void> _reject(BuildContext context, SubstituteRequest r) async {
    final store = AppScope.read(context);
    final s = store.shiftById(r.shiftId)!;
    final ok = await showConfirmDialog(
      context,
      title: '대타 요청을 거절할까요?',
      message: '${shiftDay(s)} ${shiftTime(s)} 근무는 ${store.nameOf(r.requesterId)}님이 그대로 맡아요. '
          '${r.acceptedId == null ? '' : '${store.nameOf(r.requesterId)}님과 ${store.nameOf(r.acceptedId)}님에게 '}결과를 알려요.',
      confirmLabel: '거절하기',
      confirmVariant: AppButtonVariant.danger,
    );
    if (!ok || !context.mounted) return;
    AppScope.read(context).rejectSubstitute(r.id);
    final messenger = ScaffoldMessenger.of(context);
    Navigator.pop(context);
    showToastOn(messenger, '대타 요청을 거절했어요');
  }

  void _approve(BuildContext context, SubstituteRequest r) {
    AppScope.read(context).approveSubstitute(r.id);
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (_) => SubstituteDoneScreen(requestId: r.id)));
  }

  Future<void> _assign(BuildContext context, SubstituteRequest r) async {
    final store = AppScope.read(context);
    final s = store.shiftById(r.shiftId)!;
    final candidates = store.activeStaff
        .where((x) => x.id != r.requesterId && store.overlappingShift(x.id, s) == null)
        .toList();
    final pick = await pickStaff(context, candidates, title: '${shiftDay(s)} ${shiftTime(s)} 직접 배정');
    if (pick == null || !context.mounted) return;
    AppScope.read(context).assignSubstitute(r.id, pick.id);
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (_) => SubstituteDoneScreen(requestId: r.id)));
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final list = store.pendingSubs;
    final accepted = list.where((r) => r.status == SubStatus.accepted).length;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        titleSpacing: 20,
        title: Text('대타 승인', style: AppText.style(24, FontWeight.w500)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: Center(
                child: _SmallChip('승인 대기 $accepted', AppColors.accent, AppColors.accentSoft)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        children: [
          if (list.isEmpty) const EmptyNote('진행 중인 대타 요청이 없어요'),
          for (final r in list) ...[
            r.status == SubStatus.accepted
                ? _acceptedCard(context, store, r)
                : _waitingCard(context, store, r),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }

  Widget _acceptedCard(BuildContext context, AppStore store, SubstituteRequest r) {
    final s = store.shiftById(r.shiftId)!;
    final tertiary = AppText.style(12, FontWeight.w400, AppColors.textTertiary);
    final secondary = AppText.style(13, FontWeight.w400, AppColors.textSecondary);
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _SmallChip('사장님 승인 필요', AppColors.accent, AppColors.accentSoft),
              const Spacer(),
              Text(relative(DateTime.parse(r.createdAt), store.now), style: tertiary),
            ],
          ),
          const SizedBox(height: 16),
          Text('${shiftDay(s)} ${shiftTime(s)}', style: AppText.style(19, FontWeight.w500)),
          const SizedBox(height: 2),
          Row(children: [
            PartLabel(s.part, style: secondary),
            Text(' · ${duration(s.scheduledMinutes)}', style: secondary),
          ]),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _PersonChip(store.staffById(r.requesterId)!, '요청 · ${r.reason}'),
              ),
              const SizedBox(width: 12),
              const Icon(Icons.arrow_forward_rounded, size: 16, color: AppColors.textTertiary),
              const SizedBox(width: 12),
              Expanded(child: _PersonChip(store.staffById(r.acceptedId)!, '수락')),
            ],
          ),
          const SizedBox(height: 16),
          const _Steps(),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.bg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '승인 전까지는 ${store.nameOf(r.requesterId)}님이 근무 책임을 유지해요. 승인하면 근무표가 자동 변경돼요.',
              style: AppText.style(12, FontWeight.w400, AppColors.textSecondary),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              SizedBox(
                width: 96,
                child: AppButton('거절',
                    variant: AppButtonVariant.outline,
                    verticalPadding: 12,
                    fontSize: 14,
                    onPressed: () => _reject(context, r)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppButton('승인하고 반영',
                    verticalPadding: 12, fontSize: 14, onPressed: () => _approve(context, r)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _waitingCard(BuildContext context, AppStore store, SubstituteRequest r) {
    final s = store.shiftById(r.shiftId)!;
    final peers = store.activeStaff.length - 1;
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _SmallChip('동료 응답 대기', AppColors.info, AppColors.infoSoft),
              const Spacer(),
              Text('알림 ${relative(DateTime.parse(r.notifiedAt), store.now)}',
                  style: AppText.style(12, FontWeight.w400, AppColors.textTertiary)),
            ],
          ),
          const SizedBox(height: 12),
          Text('${shiftDay(s)} ${shiftTime(s)}', style: AppText.style(17, FontWeight.w500)),
          const SizedBox(height: 2),
          Text('${s.part} · ${duration(s.scheduledMinutes)} · 요청 ${store.nameOf(r.requesterId)} (${r.reason})',
              style: AppText.style(13, FontWeight.w400, AppColors.textSecondary)),
          const SizedBox(height: 12),
          Text(
              r.notifyPeers
                  ? '동료 $peers명에게 알림을 보냈고 아직 수락한 사람이 없어요'
                  : '동료 알림 없이 요청됐어요. 직접 배정해 주세요.',
              style: AppText.style(12, FontWeight.w400, AppColors.textTertiary)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: AppButton('다시 알림 보내기',
                    variant: AppButtonVariant.outline,
                    verticalPadding: 12,
                    fontSize: 14, onPressed: () {
                  AppScope.read(context).resendSubstitute(r.id);
                  showToast(context, '동료들에게 다시 알렸어요');
                }),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppButton('직접 배정',
                    variant: AppButtonVariant.outline,
                    verticalPadding: 12,
                    fontSize: 14,
                    onPressed: () => _assign(context, r)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 11px 칩 (Pill 은 12px 고정이라 따로).
class _SmallChip extends StatelessWidget {
  const _SmallChip(this.label, this.color, this.background);

  final String label;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(999)),
        child: Text(label, style: AppText.style(11, FontWeight.w500, color)),
      );
}

class _PersonChip extends StatelessWidget {
  const _PersonChip(this.staff, this.note);

  final Staff staff;
  final String note;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(14)),
        child: Row(
          children: [
            MemberAvatar(staff, size: 30),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppScope.of(context).personOf(staff).name,
                      style: AppText.style(13, FontWeight.w500)),
                  Text(note,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.style(11, FontWeight.w400, AppColors.textTertiary)),
                ],
              ),
            ),
          ],
        ),
      );
}

/// 휴무 신청 → 동료 수락 → 사장님 승인(현재).
class _Steps extends StatelessWidget {
  const _Steps();

  Widget _step(String label, {required bool done}) => Column(
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: done ? AppColors.primary : AppColors.surface,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary, width: 2),
            ),
            child: done
                ? const Icon(Icons.check_rounded, size: 14, color: AppColors.onPrimary)
                : Container(
                    width: 8,
                    height: 8,
                    decoration:
                        const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)),
          ),
          const SizedBox(height: 8),
          Text(label, style: AppText.style(11, done ? FontWeight.w400 : FontWeight.w500)),
        ],
      );

  Widget _line(Color color) => Expanded(
        child: Container(height: 2, margin: const EdgeInsets.only(top: 11), color: color),
      );

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _step('휴무 신청', done: true),
          const SizedBox(width: 8),
          _line(AppColors.primary),
          const SizedBox(width: 8),
          _step('동료 수락', done: true),
          const SizedBox(width: 8),
          _line(AppColors.border),
          const SizedBox(width: 8),
          _step('사장님 승인', done: false),
        ],
      );
}
