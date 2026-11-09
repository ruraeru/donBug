import 'package:flutter/material.dart';

import '../../data/app_scope.dart';
import '../../data/format.dart';
import '../../data/models.dart';
import '../../widgets/common.dart';
import '../../widgets/demo_menu.dart';

/// 가입 승인 완료 → 알바생 메인(그 매장).
class JoinApprovedScreen extends StatelessWidget {
  const JoinApprovedScreen({super.key, required this.storeId});

  final String storeId;

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final st = store.storeById(storeId);
    final m = store.membership(store.session.employeeId, storeId);
    if (st == null || m == null) return const MissingScreen();
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          children: [
            SuccessHero(
              title: '${st.name}에\n가입됐어요',
              subtitle: '이제 근무표와 급여를 앱에서 확인할 수 있어요',
            ),
            const SizedBox(height: 16),
            AppCard(
              child: Column(
                children: [
                  KeyValueRow('소속 매장', st.name),
                  const SizedBox(height: 14),
                  KeyValueRow('시급', wonText(m.wage)),
                  const SizedBox(height: 14),
                  KeyValueRow('급여 공제', m.deduction.label),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomBar(
        child: AppButton(
          '홈으로 가기',
          onPressed: () {
            AppScope.read(context).switchStore(storeId);
            openShell(context, Role.employee);
          },
        ),
      ),
    );
  }
}
