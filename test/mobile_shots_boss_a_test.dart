// 사장님 모바일 화면(boss-a 담당) 스크린샷. 사용법은 mobile_shots.dart 참고.
import 'package:donbug/data/models.dart';
import 'package:donbug/screens/employer/attendance_detail_screen.dart';
import 'package:donbug/screens/employer/attendance_screen.dart';
import 'package:donbug/screens/employer/employer_dashboard_screen.dart';
import 'package:donbug/screens/employer/employer_labor_cost_screen.dart';
import 'package:donbug/screens/employer/employer_payroll_detail_screen.dart';
import 'package:donbug/screens/employer/employer_payroll_settings_screen.dart';
import 'package:donbug/screens/employer/employer_schedule_screen.dart';
import 'package:donbug/screens/employer/schedule_template_screen.dart';
import 'package:donbug/screens/employer/shift_add_screen.dart';
import 'package:donbug/screens/employer/store_code_screen.dart';
import 'package:donbug/screens/employer/store_create_screen.dart';
import 'package:donbug/screens/employer/store_settings_screen.dart';
import 'package:donbug/screens/employer/substitute_approval_screen.dart';
import 'package:donbug/screens/employer/substitute_done_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'mobile_shots.dart';

void main() {
  testWidgets('사장님 화면 (boss-a)', (tester) async {
    await tester.runAsync(loadShotFonts);
    final s = shotStore(role: Role.employer);
    final staffId = s.activeStaff.first.id;
    final shiftId = s.shiftsOn(s.today).first.id;
    final subId = s.pendingSubs.first.id;
    final screens = <String, Widget>{
      'dashboard': const Scaffold(body: EmployerDashboardScreen()),
      'schedule': const Scaffold(body: EmployerScheduleScreen()),
      'shift_add': ShiftAddScreen(date: s.today),
      'template': const ScheduleTemplateScreen(),
      'labor_cost': const Scaffold(body: EmployerLaborCostScreen()),
      'payroll_detail': EmployerPayrollDetailScreen(
          staffId: staffId, month: DateTime(s.today.year, s.today.month)),
      'payroll_settings': EmployerPayrollSettingsScreen(staffId: staffId),
      'attendance': const AttendanceScreen(),
      'attendance_detail': AttendanceDetailScreen(shiftId: shiftId),
      'sub_approval': const SubstituteApprovalScreen(),
      'sub_done': SubstituteDoneScreen(requestId: subId),
      'store_settings': const StoreSettingsScreen(),
      'store_create': const StoreCreateScreen(),
      'store_code': const StoreCodeScreen(),
    };
    for (final e in screens.entries) {
      await pumpShot(tester, e.value, store: s, height: 1400);
      await shot(tester, 'boss_a_${e.key}');
    }
  });
}
