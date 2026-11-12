// 알바생 화면 전체 스크린샷. 사용법은 mobile_shots.dart 참고.
import 'package:donbug/screens/employee/clock_in_done_screen.dart';
import 'package:donbug/screens/employee/clock_out_done_screen.dart';
import 'package:donbug/screens/employee/contract_sign_screen.dart';
import 'package:donbug/screens/employee/employee_shell.dart';
import 'package:donbug/screens/employee/health_cert_register_screen.dart';
import 'package:donbug/screens/employee/join_approved_screen.dart';
import 'package:donbug/screens/employee/join_pending_screen.dart';
import 'package:donbug/screens/employee/kakao_consent_screen.dart';
import 'package:donbug/screens/employee/leave_request_screen.dart';
import 'package:donbug/screens/employee/login_screen.dart';
import 'package:donbug/screens/employee/my_documents_screen.dart';
import 'package:donbug/screens/employee/notice_detail_screen.dart';
import 'package:donbug/screens/employee/notification_center_screen.dart';
import 'package:donbug/screens/employee/payslip_detail_screen.dart';
import 'package:donbug/screens/employee/qr_check_in_screen.dart';
import 'package:donbug/screens/employee/role_select_screen.dart';
import 'package:donbug/screens/employee/shift_detail_screen.dart';
import 'package:donbug/screens/employee/store_code_screen.dart';
import 'package:donbug/screens/employee/store_switch_screen.dart';
import 'package:donbug/screens/employee/substitute_detail_screen.dart';
import 'package:donbug/screens/employee/substitute_done_screen.dart';
import 'package:donbug/screens/employee/substitute_status_screen.dart';
import 'package:donbug/screens/employee/work_log_screen.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'mobile_shots.dart';

void main() {
  testWidgets('알바생 화면', (tester) async {
    await tester.runAsync(loadShotFonts);
    final probe = shotStore();
    final month = DateTime(2026, 5, 1);
    final prev = DateTime(2026, 4, 1);
    final shiftId = probe.myShifts.first.id;
    final todayShift = probe.myTodayShift!.id;
    final att = probe.state.attendance.firstWhere((a) => a.staffId == probe.myStaff!.id).id;
    final noticeId = probe.storeNotices.first.id;
    final subOther = probe.subsAvailableToMe.isNotEmpty
        ? probe.subsAvailableToMe.first.id
        : probe.storeSubs.first.id;
    final subMine = (probe.mySubs.isNotEmpty ? probe.mySubs.first : probe.storeSubs.first).id;

    final screens = <String, Widget Function()>{
      'login': () => const LoginScreen(),
      'kakao': () => const KakaoConsentScreen(),
      'role': () => const RoleSelectScreen(),
      'storecode': () => const StoreCodeScreen(),
      'join_pending': () => const JoinPendingScreen(storeId: 'st-cafe'),
      'join_approved': () => const JoinApprovedScreen(storeId: 'st-cafe'),
      'store_switch': () => const StoreSwitchScreen(),
      'shell': () => const EmployeeShell(),
      'shift_detail': () => ShiftDetailScreen(shiftId: shiftId),
      'qr': () => QrCheckInScreen(shiftId: todayShift),
      'clock_in_done': () => ClockInDoneScreen(attendanceId: att),
      'clock_out_done': () => ClockOutDoneScreen(attendanceId: att),
      'leave': () => LeaveRequestScreen(shiftId: shiftId),
      'sub_status': () => const SubstituteStatusScreen(),
      'sub_detail': () => SubstituteDetailScreen(requestId: subOther),
      'sub_done_req': () => SubstituteDoneScreen(SubstituteDoneKind.request, requestId: subMine),
      'sub_done_apply': () => SubstituteDoneScreen(SubstituteDoneKind.apply, requestId: subOther),
      'payslip': () => PayslipDetailScreen(month: prev),
      'payslip_cur': () => PayslipDetailScreen(month: month),
      'worklog': () => WorkLogScreen(month: month),
      'notice_detail': () => NoticeDetailScreen(noticeId: noticeId),
      'notification': () => const NotificationCenterScreen(),
      'documents': () => const MyDocumentsScreen(),
      'contract': () => const ContractSignScreen(),
      'health': () => const HealthCertRegisterScreen(),
    };
    for (final e in screens.entries) {
      await pumpShot(tester, e.value(), store: shotStore(), height: 1400);
      await shot(tester, e.key);
    }
    await pumpShot(tester, const SubstituteStatusScreen(), store: shotStore(), height: 1400);
    await tester.tap(find.textContaining('지원 가능'));
    await settle(tester);
    await shot(tester, 'sub_status_2');
    // 탭 화면
    await pumpShot(tester, const EmployeeShell(), store: shotStore(), height: 1400);
    for (final tab in ['근무표', '급여', '공지', 'MY']) {
      await tester.tap(find.text(tab).last);
      await settle(tester);
      await shot(tester, 'tab_$tab');
    }
  });
}
