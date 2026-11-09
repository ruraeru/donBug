import 'package:flutter/material.dart';

import '../../data/models.dart';
import '../../widgets/common.dart';
import '../../widgets/demo_menu.dart';

/// 가입 승인 완료 → 알바생 메인.
class JoinApprovedScreen extends StatelessWidget {
  const JoinApprovedScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            children: const [
              SuccessHero(
                title: '카페 커푸치노에\n가입됐어요',
                subtitle: '이제 근무표와 급여를 앱에서 확인할 수 있어요',
              ),
              SizedBox(height: 16),
              AppCard(
                child: Column(
                  children: [
                    KeyValueRow('소속 매장', '카페 커푸치노'),
                    SizedBox(height: 14),
                    KeyValueRow('시급', '10,030원'),
                    SizedBox(height: 14),
                    KeyValueRow('급여 공제', '사업소득세 3.3%'),
                  ],
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: BottomBar(
          child: AppButton(
            '홈으로 가기',
            onPressed: () => openShell(context, Role.employee),
          ),
        ),
      );
}
