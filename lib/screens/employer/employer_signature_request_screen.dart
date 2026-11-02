import 'package:flutter/material.dart';
import 'employer_parts.dart';
import '../../widgets/common.dart';


/// 전자서명 요청 완료 (Figma 48:462).
class EmployerSignatureRequestScreen extends StatelessWidget {
  const EmployerSignatureRequestScreen({super.key});

  @override
  Widget build(BuildContext context) => SuccessStepsScaffold(
        title: '서명 요청을 보냈어요',
        message: '서연님이 서명하면 PDF가 자동 보관돼요',
        steps: const [
          (state: StepStatus.done, title: '사장님 서명', subtitle: '방금 전'),
          (state: StepStatus.current, title: '근로자 서명', subtitle: '서연님 서명 대기'),
          (state: StepStatus.pending, title: 'PDF 보관', subtitle: '서명 완료 후 자동 저장'),
        ],
        ctaLabel: '서류 목록으로',
        onCta: () => Navigator.pop(context),
      );
}
