import 'package:flutter/material.dart';

import '../../widgets/tab_shell.dart';
import 'employee_home_screen.dart';
import 'employee_my_screen.dart';
import 'employee_notice_screen.dart';
import 'employee_salary_screen.dart';
import 'employee_schedule_screen.dart';

/// 알바생 메인: 홈 · 근무표 · 급여 · 공지 · MY.
class EmployeeShell extends StatelessWidget {
  const EmployeeShell({super.key});

  @override
  Widget build(BuildContext context) => const TabShell(tabs: [
        (icon: 'tab_home', label: '홈', page: EmployeeHomeScreen()),
        (icon: 'tab_calendar', label: '근무표', page: EmployeeScheduleScreen()),
        (icon: 'tab_salary', label: '급여', page: EmployeeSalaryScreen()),
        (icon: 'tab_notice', label: '공지', page: EmployeeNoticeScreen()),
        (icon: 'tab_my', label: 'MY', page: EmployeeMyScreen()),
      ]);
}
