import 'package:flutter/material.dart';

import '../data/app_scope.dart';
import '../data/models.dart';
import '../screens/employee/employee_shell.dart';
import '../screens/employee/login_screen.dart';
import '../screens/employer/employer_shell.dart';
import '../theme.dart';
import 'common.dart';

/// 로그인 상태로 [role] 셸을 연다. 이전 화면은 모두 닫는다(탭·로컬 상태 초기화).
void openShell(BuildContext context, Role role) {
  AppScope.read(context).login(role);
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(
        builder: (_) =>
            role == Role.employee ? const EmployeeShell() : const EmployerShell()),
    (_) => false,
  );
}

/// 로그아웃 후 로그인 화면으로.
void logoutToLogin(BuildContext context) {
  AppScope.read(context).logout();
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => const LoginScreen()),
    (_) => false,
  );
}

/// 데모 전용 메뉴: 역할 전환 · 데이터 초기화. 알바생 MY 와 사장님 매장 설정에 둔다.
class DemoMenu extends StatelessWidget {
  const DemoMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final role = AppScope.of(context).role;
    final other = role == Role.employee ? Role.employer : Role.employee;
    final chevron =
        Text('›', style: AppText.style(22, FontWeight.w400, AppColors.textTertiary));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Text('데모', style: AppText.style(14, FontWeight.w700, AppColors.textSecondary)),
          const SizedBox(width: 8),
          const Pill('시연용', color: AppColors.info, background: AppColors.infoSoft),
        ]),
        const SizedBox(height: 10),
        PersonRow(
          avatar: const LetterAvatar('전', color: AppColors.info, background: AppColors.infoSoft),
          title: other == Role.employer ? '사장님 화면으로 전환' : '알바생 화면으로 전환',
          subtitle: '같은 데이터로 다른 역할을 확인해요',
          trailing: chevron,
          onTap: () => openShell(context, other),
        ),
        const SizedBox(height: 12),
        PersonRow(
          avatar: const LetterAvatar('초',
              color: AppColors.danger, background: AppColors.dangerSoft),
          title: '데모 데이터 초기화',
          subtitle: '처음 상태로 되돌려요',
          trailing: chevron,
          onTap: () async {
            final ok = await showConfirmDialog(
              context,
              title: '데모 데이터를 초기화할까요?',
              message: '출퇴근 기록, 대타 요청, 공지 등 지금까지 바꾼 내용이 모두 처음 상태로 돌아가요.',
              confirmLabel: '초기화',
              confirmVariant: AppButtonVariant.danger,
            );
            if (!ok || !context.mounted) return;
            AppScope.read(context).resetDemo();
            openShell(context, role);
          },
        ),
      ],
    );
  }
}
