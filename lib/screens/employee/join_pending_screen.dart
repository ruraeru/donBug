import 'package:flutter/material.dart';

import '../../data/app_scope.dart';
import '../../data/format.dart';
import '../../data/models.dart';
import '../../data/payroll.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import 'join_approved_screen.dart';

/// 가입 승인 대기. '새로고침'은 실제 승인 여부를 확인한다.
class JoinPendingScreen extends StatelessWidget {
  const JoinPendingScreen({super.key, required this.storeId});

  final String storeId;

  void _approved(BuildContext context) => Navigator.pushReplacement(
      context, MaterialPageRoute(builder: (_) => JoinApprovedScreen(storeId: storeId)));

  void _refresh(BuildContext context) {
    final store = AppScope.read(context);
    final m = store.state.staff
        .where((s) => s.personId == store.session.employeeId && s.storeId == storeId)
        .lastOrNull;
    if (m?.status == StaffStatus.active) return _approved(context);
    if (m?.status == StaffStatus.rejected) {
      return showToast(context, '가입이 거절됐어요. 사장님께 확인해 주세요');
    }
    showToast(context, '아직 승인 전이에요');
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final st = store.storeById(storeId);
    final m = store.membership(store.session.employeeId, storeId);
    if (st == null) return const MissingScreen(title: '가입 신청 현황');
    final p = store.person(store.session.employeeId);
    return Scaffold(
      appBar: const AppHeader('가입 신청 현황'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 28, bottom: 8),
            child: Column(
              children: [
                Container(
                  width: 96,
                  height: 96,
                  alignment: Alignment.center,
                  decoration:
                      const BoxDecoration(color: AppColors.accentSoft, shape: BoxShape.circle),
                  child: Text('…', style: AppText.style(44, FontWeight.w500, AppColors.accent)),
                ),
                const SizedBox(height: 12),
                Text('사장님 승인을 기다리고 있어요',
                    textAlign: TextAlign.center, style: AppText.style(22, FontWeight.w500)),
                const SizedBox(height: 12),
                Text('승인되면 알림으로 알려드릴게요',
                    textAlign: TextAlign.center,
                    style: AppText.style(15, FontWeight.w400, AppColors.textSecondary)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(st.name, style: AppText.style(17, FontWeight.w500))),
                    const Pill.accent('승인 대기'),
                  ],
                ),
                if (m?.requestedAt != null) ...[
                  const SizedBox(height: 12),
                  Text('신청 일시  ${dotDate(DateTime.parse(m!.requestedAt!))} ${clock(DateTime.parse(m.requestedAt!))}',
                      style: AppText.style(13, FontWeight.w400, AppColors.textSecondary)),
                ],
                const SizedBox(height: 12),
                Text('신청자  ${p.fullName} (알바생)',
                    style: AppText.style(13, FontWeight.w400, AppColors.textSecondary)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const NoteBox('데모: 사장님이 승인하면 새로고침으로 확인할 수 있어요. 아래 데모 버튼으로 바로 승인할 수도 있어요.',
              color: AppColors.info, background: AppColors.infoSoft),
        ],
      ),
      bottomNavigationBar: BottomBar(
        children: [
          AppButton('새로고침', onPressed: () => _refresh(context)),
          if (m != null && m.status == StaffStatus.pending)
            AppButton(
              '사장님이 승인한 것으로 (데모)',
              variant: AppButtonVariant.soft,
              onPressed: () {
                AppScope.read(context).approveJoin(m.id, wage: minimumWage2026);
                _approved(context);
              },
            ),
          AppButton('코드 다시 입력',
              variant: AppButtonVariant.outline, onPressed: () => Navigator.pop(context)),
        ],
      ),
    );
  }
}
