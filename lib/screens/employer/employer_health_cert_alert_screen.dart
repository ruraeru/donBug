import 'package:flutter/material.dart';
import 'employer_parts.dart';
import '../../widgets/common.dart';


/// 보건증 만료 알림 발송 완료 (Figma 48:297).
class EmployerHealthCertAlertScreen extends StatelessWidget {
  const EmployerHealthCertAlertScreen({super.key});

  @override
  Widget build(BuildContext context) => SuccessStepsScaffold(
        title: '갱신 요청을 보냈어요',
        message: '수빈님과 사장님께 D-12 알림이 발송됐어요',
        stepsHeader: '자동 알림 일정',
        steps: const [
          (state: StepStatus.done, title: 'D-30', subtitle: '5/26 · 발송 완료'),
          (state: StepStatus.done, title: 'D-14', subtitle: '5/12 · 발송 완료'),
          (state: StepStatus.current, title: 'D-12 (지금)', subtitle: '수동 갱신 요청'),
          (
            state: StepStatus.pending,
            title: 'D-7 · D-Day',
            subtitle: '5/19 · 5/26 자동 발송'
          ),
        ],
        ctaLabel: '서류 목록으로',
        onCta: () => Navigator.pop(context),
      );
}
