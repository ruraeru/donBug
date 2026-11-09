import 'package:flutter/material.dart';

import '../../data/app_scope.dart';
import '../../data/format.dart';
import '../../widgets/common.dart';
import 'employer_parts.dart';

/// 전자서명 요청 완료 (Figma 48:462).
class EmployerSignatureRequestScreen extends StatelessWidget {
  const EmployerSignatureRequestScreen({super.key, required this.staffId});

  final String staffId;

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final s = store.staffById(staffId);
    final c = s?.contract;
    if (s == null || c == null) return const MissingScreen();
    final name = store.personOf(s).name;
    final signed = c.employeeSignedAt != null;
    return SuccessStepsScaffold(
      title: '서명 요청을 보냈어요',
      message: '$name님이 서명하면 PDF가 자동 보관돼요',
      steps: [
        (
          state: StepStatus.done,
          title: '사장님 서명',
          subtitle: relative(DateTime.parse(c.ownerSignedAt!), store.now)
        ),
        (
          state: signed ? StepStatus.done : StepStatus.current,
          title: '근로자 서명',
          subtitle: signed ? '$name님 서명 완료' : '$name님 서명 대기'
        ),
        (
          state: signed ? StepStatus.done : StepStatus.pending,
          title: 'PDF 보관',
          subtitle: signed ? '보관됨 (데모)' : '서명 완료 후 자동 저장'
        ),
      ],
      ctaLabel: '서류 목록으로',
      onCta: () => Navigator.pop(context),
    );
  }
}
