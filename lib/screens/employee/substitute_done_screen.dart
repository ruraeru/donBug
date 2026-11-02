import 'package:flutter/material.dart';

import '../../theme.dart';
import '../../widgets/common.dart';
import 'employee_parts.dart';
import 'employee_widgets.dart';
import 'substitute_status_screen.dart';

/// request: 대타 신청 완료(44:602) · apply: 대타 지원 완료(44:803).
enum SubstituteDoneKind { request, apply }

class SubstituteDoneScreen extends StatelessWidget {
  const SubstituteDoneScreen(this.kind, {super.key});

  final SubstituteDoneKind kind;

  @override
  Widget build(BuildContext context) {
    final request = kind == SubstituteDoneKind.request;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          children: [
            DoneHero(
              title: request ? '대타 요청을 보냈어요' : '지원이 완료됐어요',
              subtitle: request
                  ? '같은 매장 동료 4명에게 알림을 보냈어요'
                  : '사장님이 승인하면 근무표에 바로 반영돼요',
            ),
            const SizedBox(height: 16),
            AppCard(child: request ? _requestSummary() : _applySteps()),
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
                onPressed: () =>
                    Navigator.popUntil(context, (route) => route.isFirst),
              ),
      ),
    );
  }

  Widget _requestSummary() => Column(
        children: [
          const KvRow('근무', '5/16(금) 10:00–16:00'),
          const SizedBox(height: 14),
          const KvRow('사유', '병원 진료'),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Text('상태',
                    style: AppText.style(14, FontWeight.w400, AppColors.textSecondary)),
              ),
              const Pill.accent('지원 대기'),
            ],
          ),
        ],
      );

  Widget _applySteps() => const Column(
        children: [
          StepRow(StepStatus.done, '지원 완료', '방금 전'),
          SizedBox(height: 16),
          StepRow(StepStatus.current, '사장님 승인', '대기 중'),
          SizedBox(height: 16),
          StepRow(StepStatus.pending, '근무표 반영', '승인 후 알림'),
        ],
      );
}
