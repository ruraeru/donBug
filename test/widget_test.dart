import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:donbug/data/app_scope.dart';
import 'package:donbug/data/app_store.dart';
import 'package:donbug/data/format.dart';
import 'package:donbug/data/models.dart';
import 'package:donbug/main.dart';
import 'package:donbug/screens/employee/contract_sign_screen.dart';
import 'package:donbug/screens/employee/employee_shell.dart';
import 'package:donbug/screens/employee/health_cert_register_screen.dart';
import 'package:donbug/screens/employee/join_pending_screen.dart';
import 'package:donbug/screens/employee/kakao_consent_screen.dart';
import 'package:donbug/screens/employee/leave_request_screen.dart';
import 'package:donbug/screens/employee/my_documents_screen.dart';
import 'package:donbug/screens/employee/notice_detail_screen.dart';
import 'package:donbug/screens/employee/notification_center_screen.dart';
import 'package:donbug/screens/employee/payslip_detail_screen.dart';
import 'package:donbug/screens/employee/shift_detail_screen.dart';
import 'package:donbug/screens/employee/store_code_screen.dart';
import 'package:donbug/screens/employee/store_switch_screen.dart';
import 'package:donbug/screens/employee/substitute_detail_screen.dart';
import 'package:donbug/screens/employee/substitute_status_screen.dart';
import 'package:donbug/screens/employee/work_log_screen.dart';
import 'package:donbug/screens/employer/attendance_detail_screen.dart';
import 'package:donbug/screens/employer/attendance_screen.dart';
import 'package:donbug/screens/employer/employer_parts.dart';
import 'package:donbug/screens/employer/employer_payroll_detail_screen.dart';
import 'package:donbug/screens/employer/employer_payroll_settings_screen.dart';
import 'package:donbug/screens/employer/employer_contract_write_screen.dart';
import 'package:donbug/screens/employer/employer_documents_screen.dart';
import 'package:donbug/screens/employer/employer_health_cert_alert_screen.dart';
import 'package:donbug/screens/employer/employer_notice_screen.dart';
import 'package:donbug/screens/employer/employer_shell.dart';
import 'package:donbug/screens/employer/employer_signature_request_screen.dart';
import 'package:donbug/screens/employer/employer_staff_documents_screen.dart';
import 'package:donbug/screens/employer/notice_read_status_screen.dart';
import 'package:donbug/screens/employer/notice_result_screen.dart';
import 'package:donbug/screens/employer/schedule_template_screen.dart';
import 'package:donbug/screens/employer/shift_add_screen.dart';
import 'package:donbug/screens/employer/staff_approval_screen.dart';
import 'package:donbug/screens/employer/staff_management_screen.dart';
import 'package:donbug/screens/employer/store_code_screen.dart' as employer;
import 'package:donbug/screens/employer/store_create_screen.dart';
import 'package:donbug/screens/employer/store_settings_screen.dart';
import 'package:donbug/screens/employer/substitute_approval_screen.dart';
import 'package:donbug/screens/employer/substitute_done_screen.dart' as employer;
import 'package:donbug/screens/employer/staff_detail_screen.dart';
import 'package:donbug/screens/web/web_common.dart';
import 'package:donbug/widgets/common.dart';
import 'package:donbug/screens/web/web_pos_qr_screen.dart';
import 'package:donbug/screens/web/web_shell.dart';
import 'package:donbug/theme.dart';

/// 테스트 기준 시각: 2026-05-14(수) 14:30 (Figma 화면과 같은 날).
final testNow = DateTime(2026, 5, 14, 14, 30);

AppStore testStore() => AppStore.seeded(now: testNow);

AppStore employerStore() => testStore()..switchRole(Role.employer);

String subinId(AppStore s) => s.activeStaff.firstWhere((x) => s.personOf(x).name == '수빈').id;

Future<AppStore> pumpAt(WidgetTester tester, Widget home, Size size,
    {AppStore? store}) async {
  final s = store ?? testStore();
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
      AppScope(store: s, child: MaterialApp(key: UniqueKey(), theme: appTheme, home: home)));
  await tester.pumpAndSettle();
  return s;
}

/// 스스로 닫히는 화면용: 빈 화면 위에 [page]를 push 한다.
Future<AppStore> openPage(WidgetTester tester, Widget page, {AppStore? store}) async {
  final s = await pumpAt(
      tester,
      Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () =>
                Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
            child: const Text('open'),
          ),
        ),
      ),
      const Size(390, 844),
      store: store);
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return s;
}

/// 하단 탭을 하나씩 눌러 모든 탭 루트 화면이 오류·넘침 없이 그려지는지 본다.
Future<void> visitTabs(WidgetTester tester, List<String> labels) async {
  for (final label in labels) {
    await tester.tap(find.text(label).last);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: '탭: $label');
  }
}

void main() {
  testWidgets('앱이 로그인 화면으로 시작한다', (tester) async {
    await tester.pumpWidget(MyApp(store: testStore()));
    expect(find.text('카카오로 시작하기'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('알바생 탭 화면', (tester) async {
    await pumpAt(tester, const EmployeeShell(), const Size(390, 844));
    await visitTabs(tester, ['근무표', '급여', '공지', 'MY', '홈']);
  });

  testWidgets('사장님 탭 화면', (tester) async {
    await pumpAt(tester, const EmployerShell(), const Size(390, 844), store: employerStore());
    await visitTabs(tester, ['근무표', '인건비', '서류', '공지', '홈']);
  });

  testWidgets('대시보드 매장 이름 → 매장 설정', (tester) async {
    await pumpAt(tester, const EmployerShell(), const Size(390, 844), store: employerStore());
    await tester.tap(find.text('카페 커푸치노'));
    await tester.pumpAndSettle();
    expect(find.text('매장 설정'), findsOneWidget);
  });

  testWidgets('대타 거절: 취소하면 남고, 확인하면 닫히고 스낵바', (tester) async {
    final store = await pumpAt(tester, const EmployerShell(), const Size(390, 844),
        store: employerStore());
    final req = store.pendingSubs.firstWhere((r) => r.status == SubStatus.accepted);
    await tester.tap(find.text('지원자 확인하고 확정'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('거절'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();
    expect(find.text('대타 승인'), findsOneWidget);

    await tester.tap(find.text('거절'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('거절하기'));
    await tester.pumpAndSettle();
    expect(find.text('대타 승인'), findsNothing);
    expect(find.text('대타 요청을 거절했어요'), findsOneWidget);
    expect(req.status, SubStatus.rejected);
  });

  testWidgets('직원 상세 내보내기 → 확인 후 닫힘', (tester) async {
    final store = employerStore();
    final id = subinId(store);
    await openPage(tester, StaffDetailScreen(staffId: id), store: store);
    await tester.tap(find.text('매장에서 내보내기'));
    await tester.pumpAndSettle();
    expect(find.text('수빈님을 매장에서 내보낼까요?'), findsOneWidget);
    await tester.tap(find.text('내보내기'));
    await tester.pumpAndSettle();
    expect(find.text('수빈님을 매장에서 내보냈어요'), findsOneWidget);
    expect(store.staffById(id)!.status, StaffStatus.left);
  });

  testWidgets('알바생: 출근 → 퇴근 기록', (tester) async {
    final store = await pumpAt(tester, const EmployeeShell(), const Size(390, 844));
    await tester.tap(find.text('출근하기'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('qr-scan')));
    await tester.pumpAndSettle();
    expect(find.text('출근이 완료됐어요'), findsOneWidget);
    expect(find.text('30분 지각'), findsOneWidget); // 14:00 근무 · 14:30 출근
    expect(store.isWorking, isTrue);

    await tester.tap(find.text('홈으로 가기'));
    // 근무 중 카드는 1초 타이머가 있어 pumpAndSettle 대신 pump.
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.textContaining('근무 중 · 14:30 출근'), findsOneWidget);

    await tester.tap(find.text('퇴근하기'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.text('퇴근하기').last);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('오늘도 수고했어요'), findsOneWidget);
    expect(store.isWorking, isFalse);
  });

  testWidgets('알바생: 휴무 신청 → 요청 현황 → 동료 수락(데모)', (tester) async {
    final store = await pumpAt(tester, const EmployeeShell(), const Size(390, 844));
    await tester.tap(find.text('근무표').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('휴무 · 대타 신청'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('휴무 신청하고 대타 구하기'));
    await tester.pumpAndSettle();
    expect(find.text('사유를 입력해 주세요'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '치과 진료');
    await tester.tap(find.text('휴무 신청하고 대타 구하기'));
    await tester.pumpAndSettle();
    expect(find.text('대타 요청을 보냈어요'), findsOneWidget);
    expect(store.mySubs.first.reason, '치과 진료');

    await tester.tap(find.text('요청 현황 보기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('동료 수락 (데모)'));
    await tester.pumpAndSettle();
    expect(find.textContaining('님이 수락했어요'), findsOneWidget);
    expect(find.text('사장님 승인 대기'), findsOneWidget);
  });

  testWidgets('알바생: 매장 전환하면 홈이 그 매장 기준', (tester) async {
    await pumpAt(tester, const EmployeeShell(), const Size(390, 844));
    expect(find.text('카페 커푸치노 · 알바생'), findsOneWidget);
    await tester.tap(find.text('MY').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('근무 매장 전환'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('편의점 모아'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('홈').last);
    await tester.pumpAndSettle();
    expect(find.text('편의점 모아 · 알바생'), findsOneWidget);
  });

  testWidgets('알바생 상세 화면들이 오류 없이 그려진다', (tester) async {
    final store = testStore();
    final shift = store.myUpcomingShifts.first;
    final sub = store.subsAvailableToMe.first;
    final notice = store.storeNotices.first;
    final month = DateTime(2026, 5);
    final pages = <String, Widget>{
      'shift': ShiftDetailScreen(shiftId: shift.id),
      'leave': LeaveRequestScreen(shiftId: shift.id),
      'subDetail': SubstituteDetailScreen(requestId: sub.id),
      'subStatus': const SubstituteStatusScreen(initialTab: 1),
      'payslip': PayslipDetailScreen(month: month),
      'workLog': WorkLogScreen(month: month),
      'notice': NoticeDetailScreen(noticeId: notice.id),
      'notifications': const NotificationCenterScreen(),
      'docs': const MyDocumentsScreen(),
      'cert': const HealthCertRegisterScreen(),
      'contract': const ContractSignScreen(),
      'storeSwitch': const StoreSwitchScreen(),
      'storeCode': const StoreCodeScreen(),
      'joinPending': const JoinPendingScreen(storeId: 'st-cafe'),
      'kakao': const KakaoConsentScreen(),
      'missing': const ShiftDetailScreen(shiftId: 'nope'),
    };
    for (final e in pages.entries) {
      await pumpAt(tester, e.value, const Size(390, 844), store: store);
      expect(tester.takeException(), isNull, reason: e.key);
    }
  });

  testWidgets('역할 간: 알바생 대타 신청 → 동료 수락 → 사장님 승인 → 근무자 교체', (tester) async {
    final store = testStore();
    final shift = store.myUpcomingShifts.firstWhere((s) => s.date != '2026-05-14');
    final me = store.myStaff!.id;
    final r = store.requestSubstitute(shift.id, reason: '치과 진료');
    expect(store.simulatePeerAccept(r.id), isTrue);
    store.switchRole(Role.employer);

    await pumpAt(tester, const SubstituteApprovalScreen(), const Size(390, 844), store: store);
    expect(find.textContaining('요청 · 치과 진료'), findsOneWidget);
    await tester.tap(find.text('승인하고 반영').first);
    await tester.pumpAndSettle();
    expect(find.text('대타가 확정됐어요'), findsOneWidget);

    expect(r.status, SubStatus.approved);
    expect(shift.staffId, isNot(me));
    store.switchRole(Role.employee);
    expect(store.myShifts.contains(shift), isFalse);
  });

  testWidgets('사장님: 가입 승인 → 시급 입력 → 재직', (tester) async {
    final store = await pumpAt(tester, const StaffApprovalScreen(), const Size(390, 844),
        store: employerStore());
    final d = store.pendingStaff.single;
    await tester.tap(find.text('승인하고 시급 설정'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '9000');
    await tester.tap(find.text('승인'));
    await tester.pumpAndSettle();
    expect(find.textContaining('최저임금'), findsOneWidget); // 최저임금 미만 막음
    await tester.enterText(find.byType(TextField), '10800');
    await tester.tap(find.text('승인'));
    await tester.pumpAndSettle();
    expect(d.active, isTrue);
    expect(d.wage, 10800);
    expect(find.text('대기 중인 가입 신청이 없어요'), findsOneWidget);
  });

  testWidgets('사장님: 근태 직접 입력 · 근무 추가', (tester) async {
    final store = employerStore();
    final waiting = store.shiftsOn(store.today).firstWhere((s) => store.attendanceFor(s.id) == null);
    await openPage(tester, AttendanceDetailScreen(shiftId: waiting.id), store: store);
    await tester.tap(find.text('수정 저장'));
    await tester.pumpAndSettle();
    expect(find.text('수정 사유를 입력해 주세요'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '태그 오류로 수기 입력');
    await tester.tap(find.text('수정 저장'));
    await tester.pumpAndSettle();
    expect(store.attendanceFor(waiting.id)?.editReason, '태그 오류로 수기 입력');

    final before = store.shiftsOn(store.today).length;
    await openPage(tester, ShiftAddScreen(date: store.today), store: store);
    await tester.tap(find.text('지민'));
    await tester.tap(find.text('근무 등록'));
    await tester.pumpAndSettle();
    expect(store.shiftsOn(store.today).length, before + 1);
  });

  testWidgets('사장님 화면들이 오류 없이 그려진다', (tester) async {
    final store = employerStore();
    final subin = subinId(store);
    final shift = store.shiftsOn(store.today).first;
    final approved = store.storeSubs.firstWhere((r) => r.status == SubStatus.approved);
    final pages = <String, Widget>{
      'attendance': const AttendanceScreen(),
      'attDetail': AttendanceDetailScreen(shiftId: shift.id),
      'approval': const SubstituteApprovalScreen(),
      'subDone': employer.SubstituteDoneScreen(requestId: approved.id),
      'payDetail': EmployerPayrollDetailScreen(staffId: subin, month: DateTime(2026, 5)),
      'paySettings': EmployerPayrollSettingsScreen(staffId: subin),
      'staff': const StaffManagementScreen(),
      'staffDetail': StaffDetailScreen(staffId: subin),
      'staffApproval': const StaffApprovalScreen(),
      'storeCreate': const StoreCreateScreen(),
      'storeCode': const employer.StoreCodeScreen(),
      'storeSettings': const StoreSettingsScreen(),
      'template': const ScheduleTemplateScreen(),
      'shiftAdd': ShiftAddScreen(date: store.today),
      'notifications': const NotificationCenterScreen(),
    };
    for (final e in pages.entries) {
      await pumpAt(tester, e.value, const Size(390, 844), store: store);
      expect(tester.takeException(), isNull, reason: e.key);
    }
  });

  testWidgets('역할 간: 사장님 공지 발행 → 알바생 확인 → 확인 현황 반영', (tester) async {
    final store = await pumpAt(tester, const EmployerNoticeScreen(), const Size(390, 844),
        store: employerStore());
    await tester.enterText(find.byType(TextField).at(0), '냉장고 정리');
    await tester.enterText(find.byType(TextField).at(1), '퇴근 전 유통기한 확인');
    await tester.tap(find.text('전체 발송'));
    await tester.pumpAndSettle();
    expect(find.text('공지를 발송했어요'), findsOneWidget);
    final n = store.storeNotices.firstWhere((x) => x.title == '냉장고 정리');

    store.switchRole(Role.employee);
    store.markNoticeRead(n.id);
    store.switchRole(Role.employer);

    await pumpAt(tester, NoticeReadStatusScreen(noticeId: n.id), const Size(390, 844), store: store);
    expect(find.text('1 / 5명 (20%)'), findsOneWidget);
    await tester.tap(find.text('미확인자에게 리마인드'));
    await tester.pumpAndSettle();
    expect(find.text('리마인드를 보냈어요'), findsOneWidget);
  });

  testWidgets('사장님: 근로계약서 작성 → 서명 요청', (tester) async {
    final store = employerStore();
    final seo = store.activeStaff.firstWhere((x) => store.personOf(x).name == '서연');
    await openPage(tester, EmployerContractWriteScreen(staffId: seo.id), store: store);
    await tester.tap(find.text('서명 요청 보내기'));
    await tester.pumpAndSettle();
    expect(find.text('서명 요청을 보냈어요'), findsOneWidget);
    expect(seo.contract!.ownerSignedAt, isNotNull);
    expect(seo.contract!.employeeSignedAt, isNull);
  });

  testWidgets('사장님 서류 · 공지 화면들이 오류 없이 그려진다', (tester) async {
    final store = employerStore();
    final subin = subinId(store);
    final notice = store.storeNotices.first;
    final pages = <String, Widget>{
      'docs': const EmployerDocumentsScreen(),
      'staffDocs': EmployerStaffDocumentsScreen(staffId: subin),
      'certAlert': EmployerHealthCertAlertScreen(staffId: subin),
      'contract': const EmployerContractWriteScreen(),
      'signature': EmployerSignatureRequestScreen(staffId: subin),
      'notice': const EmployerNoticeScreen(),
      'readStatus': NoticeReadStatusScreen(noticeId: notice.id),
      'published': NoticeResultScreen(NoticeResult.published, noticeId: notice.id),
      'reminded': NoticeResultScreen(NoticeResult.reminded,
          noticeId: notice.id, remindedNames: const ['하윤', '서연']),
    };
    for (final e in pages.entries) {
      await pumpAt(tester, e.value, const Size(390, 844), store: store);
      expect(tester.takeException(), isNull, reason: e.key);
    }
  });

  testWidgets('웹 셸: 모든 메뉴가 오류 없이 그려진다', (tester) async {
    await pumpAt(tester, const WebShell(), const Size(1440, 1024), store: employerStore());
    await visitTabs(tester, ['직원 관리', '인건비', '서류·컴플라이언스', '공지', 'AI 노무 도우미', '대시보드', '근무표']);
    await tester.tap(find.text('다른 보기'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('웹 대시보드: 대타 승인 → 근무표에 반영', (tester) async {
    final store = await pumpAt(tester, const WebShell(), const Size(1440, 1024),
        store: employerStore());
    final req = store.pendingSubs.firstWhere((r) => r.status == SubStatus.accepted);
    await tester.tap(find.widgetWithText(WebButton, '승인'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('승인').last);
    await tester.pumpAndSettle();
    expect(store.subById(req.id)!.status, SubStatus.approved);
    expect(store.shiftById(req.shiftId)!.staffId, req.acceptedId);
  });

  testWidgets('웹 직원 관리: 행을 누르면 모바일 상세 패널, 뒤로 가면 닫힘', (tester) async {
    await pumpAt(tester, const WebShell(), const Size(1440, 1024), store: employerStore());
    await tester.tap(find.text('직원 관리'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('상세 ›').first);
    await tester.pumpAndSettle();
    expect(find.byType(StaffDetailScreen), findsOneWidget);
    await tester.tap(find.descendant(of: find.byType(AppHeader), matching: find.byType(InkWell)).first);
    await tester.pumpAndSettle();
    expect(find.byType(StaffDetailScreen), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('웹 근무표: 직원을 칸에 끌어다 놓으면 배정', (tester) async {
    final store = await pumpAt(tester, const WebShell(), const Size(1440, 1024),
        store: employerStore());
    await tester.tap(find.text('근무표'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('›'));
    await tester.pumpAndSettle();
    final before = store.state.shifts.length;
    // 다음 주 일요일 마지막 파트 칸(마지막 DragTarget)으로, 그날 근무가 없는 직원을 끌어 놓는다.
    final sunday = mondayOf(store.today).add(const Duration(days: 13));
    final free = store.activeStaff
        .firstWhere((m) => store.shiftsOn(sunday).every((s) => s.staffId != m.id));
    final name = store.personOf(free).name;
    final from = tester.getCenter(find.descendant(
        of: find.byType(Draggable<String>), matching: find.text(name)));
    final to = tester.getCenter(find.byType(DragTarget<String>).last);
    final g = await tester.startGesture(from);
    await g.moveBy(const Offset(-20, 0));
    await g.moveTo(to);
    await g.up();
    await tester.pumpAndSettle();
    expect(store.state.shifts.length, before + 1);
    expect(store.shiftsOn(sunday).where((s) => s.staffId == free.id), hasLength(1));
  });

  testWidgets('웹 공지: 미확인자 리마인드', (tester) async {
    final store = await pumpAt(tester, const WebShell(), const Size(1440, 1024),
        store: employerStore());
    await tester.tap(find.text('공지'));
    await tester.pumpAndSettle();
    final n = store.storeNotices.first;
    await tester.tap(find.text('미확인자 리마인드'));
    await tester.pumpAndSettle();
    expect(store.noticeById(n.id)!.remindedAt, isNotNull);
  });

  testWidgets('웹 POS: QR 을 누르면 다음 근무자 출근', (tester) async {
    final store = employerStore();
    await pumpAt(tester, const WebPosQrScreen(), const Size(1440, 1024), store: store);
    final waiting =
        store.shiftsOn(store.today).where((s) => store.attendanceFor(s.id) == null).length;
    await tester.tap(find.text('QR'));
    await tester.pump();
    expect(find.textContaining('출근 완료'), findsOneWidget);
    expect(
        store.shiftsOn(store.today).where((s) => store.attendanceFor(s.id) == null).length,
        waiting - 1);
    await tester.pump(const Duration(seconds: 4));
    expect(find.textContaining('출근 완료'), findsNothing);
  });

  testWidgets('웹 패널: 모바일 화면들이 패널 안에서 열리고 닫힌다', (tester) async {
    final store = await pumpAt(tester, const WebShell(), const Size(1440, 1024),
        store: employerStore());
    final ctx = tester.element(find.byType(WebShell));
    final subin = subinId(store);
    final t = store.today;
    final pages = <String, Widget>{
      'notifications': const NotificationCenterScreen(onOpen: employerTarget),
      'attendance': const AttendanceScreen(),
      'subs': const SubstituteApprovalScreen(),
      'code': const StoreCodeScreen(),
      'approval': const StaffApprovalScreen(),
      'payroll': EmployerPayrollDetailScreen(staffId: subin, month: DateTime(t.year, t.month)),
      'docs': EmployerStaffDocumentsScreen(staffId: subin),
      'contract': const EmployerContractWriteScreen(),
      'notice': const Scaffold(body: EmployerNoticeScreen()),
      'template': const ScheduleTemplateScreen(),
      'shiftAdd': ShiftAddScreen(date: t),
    };
    for (final e in pages.entries) {
      showMobilePanel(ctx, e.value);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: e.key);
      expect(find.byWidget(e.value), findsOneWidget, reason: e.key);
      await tester.tap(find.byTooltip('닫기'));
      await tester.pumpAndSettle();
      expect(find.byWidget(e.value), findsNothing, reason: e.key);
    }

    // 화면을 모두 닫는 이동(pushAndRemoveUntil)은 패널을 닫는다.
    showMobilePanel(ctx, const StaffApprovalScreen());
    await tester.pumpAndSettle();
    await tester.tap(find.text('대시보드로 이동'));
    await tester.pumpAndSettle();
    expect(find.byType(StaffApprovalScreen), findsNothing);
    expect(find.byType(EmployerShell), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
