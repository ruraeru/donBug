import 'package:flutter/material.dart';

import '../../widgets/common.dart';
import 'employee_parts.dart';
import 'employee_shell.dart';
import 'employee_widgets.dart';

/// 가입 승인 완료 → 알바생 메인.
class JoinApprovedScreen extends StatelessWidget {
  const JoinApprovedScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            children: const [
              DoneHero(
                title: '카페 커푸치노에\n가입됐어요',
                subtitle: '이제 근무표와 급여를 앱에서 확인할 수 있어요',
              ),
              SizedBox(height: 16),
              AppCard(
                child: Column(
                  children: [
                    KvRow('소속 매장', '카페 커푸치노'),
                    SizedBox(height: 14),
                    KvRow('시급', '10,030원'),
                    SizedBox(height: 14),
                    KvRow('급여 공제', '사업소득세 3.3%'),
                  ],
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: BottomBar(
          child: AppButton(
            '홈으로 가기',
            onPressed: () => Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const EmployeeShell()),
              (_) => false,
            ),
          ),
        ),
      );
}
