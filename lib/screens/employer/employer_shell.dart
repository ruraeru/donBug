import 'package:flutter/material.dart';

import '../../widgets/tab_shell.dart';
import 'employer_dashboard_screen.dart';
import 'employer_documents_screen.dart';
import 'employer_labor_cost_screen.dart';
import 'employer_notice_screen.dart';
import 'employer_schedule_screen.dart';

/// 사장님 메인: 홈 · 근무표 · 인건비 · 서류 · 공지.
class EmployerShell extends StatelessWidget {
  const EmployerShell({super.key});

  @override
  Widget build(BuildContext context) => const TabShell(tabs: [
        (icon: 'tab_home', label: '홈', page: EmployerDashboardScreen()),
        (icon: 'tab_calendar', label: '근무표', page: EmployerScheduleScreen()),
        (icon: 'tab_labor', label: '인건비', page: EmployerLaborCostScreen()),
        (icon: 'tab_docs', label: '서류', page: EmployerDocumentsScreen()),
        (icon: 'tab_notice', label: '공지', page: EmployerNoticeScreen()),
      ]);
}
