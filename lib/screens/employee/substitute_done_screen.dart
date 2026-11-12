import 'package:flutter/material.dart';

import '../../data/app_scope.dart';
import '../../data/app_store.dart';
import '../../data/format.dart';
import '../../data/models.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import 'substitute_status_screen.dart';

/// request: 대타 신청 완료(44:602) · apply: 대타 지원 완료(44:803).
enum SubstituteDoneKind { request, apply }

class SubstituteDoneScreen extends StatelessWidget {
  const SubstituteDoneScreen(this.kind, {super.key, required this.requestId});

  final SubstituteDoneKind kind;
  final String requestId;

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final r = store.subById(requestId);
    final s = store.shiftById(r?.shiftId);
    if (r == null || s == null) return const MissingScreen();
    final request = kind == SubstituteDoneKind.request;
    final peers = store.activeStaff.length - 1;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          children: [
            SuccessHero(
              title: request ? '대타 요청을 보냈어요' : '지원이 완료됐어요',
              subtitle: request
                  ? (r.notifyPeers
                      ? '같은 매장 동료 $peers명과 사장님께 알림을 보냈어요'
                      : '사장님께 알림을 보냈어요')
                  : '사장님이 승인하면 근무표에 바로 반영돼요',
            ),
            const SizedBox(height: 16),
            AppCard(child: request ? _requestSummary(store, r, s) : _applySteps(store, r)),
          ],
        ),
      ),
      bottomNavigationBar: BottomBar(
        child: request
            ? AppButton(
                '요청 현황 보기',
                onPressed: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const SubstituteStatusScreen()),
                ),
              )
            : AppButton(
                '홈으로 가기',
                onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
              ),
      ),
    );
  }

  Widget _requestSummary(AppStore store, SubstituteRequest r, Shift s) => Column(
        children: [
          KeyValueRow('근무', '${shiftDay(s)} ${shiftTime(s)}'),
          const SizedBox(height: 12),
          KeyValueRow('사유', r.reason),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text('상태',
                    style: AppText.style(14, FontWeight.w400, AppColors.textSecondary)),
              ),
              Pill.accent(subStatusLabel(r)),
            ],
          ),
        ],
      );

  Widget _applySteps(AppStore store, SubstituteRequest r) => Column(
        children: [
          StepRow(StepStatus.done, '지원 완료', relative(store.now, store.now)),
          const SizedBox(height: 16),
          StepRow(
              r.status == SubStatus.approved ? StepStatus.done : StepStatus.current,
              '사장님 승인',
              r.status == SubStatus.approved ? '승인됨' : '대기 중'),
          const SizedBox(height: 16),
          StepRow(r.status == SubStatus.approved ? StepStatus.done : StepStatus.pending,
              '근무표 반영', '승인 후 알림'),
        ],
      );
}

/// 대타 요청 상태 문구.
String subStatusLabel(SubstituteRequest r) => switch (r.status) {
      SubStatus.open => r.applicantIds.isEmpty ? '지원 대기' : '지원 ${r.applicantIds.length}명',
      SubStatus.accepted => '사장님 승인 대기',
      SubStatus.approved => '승인 완료',
      SubStatus.rejected => '거절됨',
      SubStatus.cancelled => '취소됨',
    };
