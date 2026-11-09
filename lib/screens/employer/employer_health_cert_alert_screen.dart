import 'package:flutter/material.dart';

import '../../data/app_scope.dart';
import '../../data/format.dart';
import '../../widgets/common.dart';
import 'employer_parts.dart';

/// 보건증 갱신 요청 발송 완료 (Figma 48:297). 자동 알림 일정은 만료일 기준.
class EmployerHealthCertAlertScreen extends StatelessWidget {
  const EmployerHealthCertAlertScreen({super.key, required this.staffId});

  final String staffId;

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final s = store.staffById(staffId);
    if (s == null) return const MissingScreen();
    final p = store.personOf(s);
    final left = store.certDaysLeft(p);
    final expiry = p.certExpiry == null ? null : parseYmd(p.certExpiry!);
    final steps = <StepItem>[];
    if (expiry != null) {
      final days = [...p.certAlertDays]..sort((a, b) => b - a);
      for (final d in days) {
        final at = expiry.subtract(Duration(days: d));
        final past = at.isBefore(store.today);
        if (!past && steps.every((x) => x.state != StepStatus.current)) {
          steps.add((
            state: StepStatus.current,
            title: '${left! >= 0 ? 'D-$left' : '만료'} (지금)',
            subtitle: '수동 갱신 요청'
          ));
        }
        steps.add((
          state: past ? StepStatus.done : StepStatus.pending,
          title: d == 0 ? 'D-Day' : 'D-$d',
          subtitle: '${at.month}/${at.day} · ${past ? '발송 완료' : '자동 발송'}',
        ));
      }
    }
    return SuccessStepsScaffold(
      title: '갱신 요청을 보냈어요',
      message: '${p.name}님께 ${left == null ? '보건증 등록' : left >= 0 ? 'D-$left' : '만료'} 알림이 발송됐어요',
      stepsHeader: expiry == null ? null : '자동 알림 일정',
      steps: steps,
      ctaLabel: '서류 목록으로',
      onCta: () => Navigator.pop(context),
    );
  }
}
