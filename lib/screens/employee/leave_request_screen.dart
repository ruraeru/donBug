import 'package:flutter/material.dart';

import '../../data/app_scope.dart';
import '../../data/format.dart';
import '../../data/models.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import 'substitute_done_screen.dart';

/// A4 휴무·대타 신청. [shiftId]가 없으면 가장 가까운 예정 근무를 고른다.
class LeaveRequestScreen extends StatefulWidget {
  const LeaveRequestScreen({super.key, this.shiftId});

  final String? shiftId;

  @override
  State<LeaveRequestScreen> createState() => _LeaveRequestScreenState();
}

class _LeaveRequestScreenState extends State<LeaveRequestScreen> {
  final _reason = TextEditingController();
  bool _notify = true;
  String? _shiftId;

  @override
  void initState() {
    super.initState();
    _shiftId = widget.shiftId;
  }

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  void _submit(List<Shift> candidates) {
    final store = AppScope.read(context);
    final id = _shiftId ?? candidates.firstOrNull?.id;
    if (id == null) return showToast(context, '신청할 근무가 없어요');
    if (_reason.text.trim().isEmpty) return showToast(context, '사유를 입력해 주세요');
    final r = store.requestSubstitute(id, reason: _reason.text.trim(), notifyPeers: _notify);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
          builder: (_) => SubstituteDoneScreen(SubstituteDoneKind.request, requestId: r.id)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    // 앞으로 2주 안의 근무만(목록이 너무 길어지지 않게).
    final until = store.today.add(const Duration(days: 15));
    final candidates = store.myUpcomingShifts
        .where((s) =>
            store.pendingSubFor(s.id) == null &&
            store.shiftStart(s).isAfter(store.now) &&
            store.shiftStart(s).isBefore(until))
        .toList();
    final selected = _shiftId ?? candidates.firstOrNull?.id;
    final peers = store.activeStaff.length - 1;
    final label = AppText.style(14, FontWeight.w500, AppColors.textSecondary);
    return Scaffold(
      appBar: const AppHeader('휴무 신청'),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        children: [
          Text('휴무할 근무', style: label),
          const SizedBox(height: 16),
          if (candidates.isEmpty) const EmptyNote('신청할 수 있는 예정 근무가 없어요'),
          for (final s in candidates) ...[
            _ShiftOption(
              shift: s,
              selected: s.id == selected,
              onTap: () => setState(() => _shiftId = s.id),
            ),
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 6),
          Text('사유', style: label),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                TextField(
                  controller: _reason,
                  maxLines: null,
                  maxLength: 200,
                  style: AppText.style(15),
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration.collapsed(
                          hintText: '예: 치과 진료 예약이 있어서 근무가 어려워요')
                      .copyWith(counterText: ''),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text('${_reason.text.length} / 200',
                      style: AppText.style(12, FontWeight.w400, AppColors.textTertiary)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppCard(
            radius: 16,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('동료에게 대타 알림 보내기', style: AppText.style(15, FontWeight.w500)),
                      const SizedBox(height: 2),
                      Text('같은 매장 근로자 $peers명에게 전송',
                          style: AppText.style(12, FontWeight.w400, AppColors.textSecondary)),
                    ],
                  ),
                ),
                Switch(
                  value: _notify,
                  activeTrackColor: AppColors.primary,
                  onChanged: (v) => setState(() => _notify = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const NoteBox('신청하면 사장님께도 알림이 가요. 대타가 확정되면 근무표가 자동으로 바뀝니다.',
              color: AppColors.textSecondary, background: AppColors.surface),
        ],
      ),
      bottomNavigationBar: BottomBar(
        child: AppButton('휴무 신청하고 대타 구하기', onPressed: () => _submit(candidates)),
      ),
    );
  }
}

class _ShiftOption extends StatelessWidget {
  const _ShiftOption({required this.shift, required this.selected, required this.onTap});

  final Shift shift;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: selected ? AppColors.primarySoft : AppColors.surface,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: selected ? AppColors.primary : AppColors.border),
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${shiftDay(shift)} ${shiftTime(shift)}',
                          style: AppText.style(16, FontWeight.w500)),
                      const SizedBox(height: 2),
                      Text(shiftCaption(shift),
                          style: AppText.style(12, FontWeight.w400, AppColors.textSecondary)),
                    ],
                  ),
                ),
                if (selected) ...[
                  const SizedBox(width: 12),
                  const AppIcon('check', size: 22, color: AppColors.primary),
                ],
              ],
            ),
          ),
        ),
      );
}
