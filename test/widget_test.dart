import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:donbug/data/app_scope.dart';
import 'package:donbug/data/app_store.dart';
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
import 'package:donbug/screens/employer/employer_shell.dart';
import 'package:donbug/screens/employer/staff_detail_screen.dart';
import 'package:donbug/screens/web/web_shell.dart';
import 'package:donbug/theme.dart';

/// 테스트 기준 시각: 2026-05-14(수) 14:30 (Figma 화면과 같은 날).
final testNow = DateTime(2026, 5, 14, 14, 30);

AppStore testStore() => AppStore.seeded(now: testNow);

Future<AppStore> pumpAt(WidgetTester tester, Widget home, Size size,
    {AppStore? store}) async {
  final s = store ?? testStore();
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
      AppScope(store: s, child: MaterialApp(theme: appTheme, home: home)));
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
    await pumpAt(tester, const EmployerShell(), const Size(390, 844));
    await visitTabs(tester, ['근무표', '인건비', '서류', '공지', '홈']);
  });

  testWidgets('대시보드 매장 이름 → 매장 설정', (tester) async {
    await pumpAt(tester, const EmployerShell(), const Size(390, 844));
    await tester.tap(find.text('카페 커푸치노'));
    await tester.pumpAndSettle();
    expect(find.text('매장 설정'), findsOneWidget);
  });

  testWidgets('대타 거절: 취소하면 남고, 확인하면 닫히고 스낵바', (tester) async {
    await pumpAt(tester, const EmployerShell(), const Size(390, 844));
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
  });

  testWidgets('직원 상세 내보내기 → 확인 후 닫힘', (tester) async {
    await pumpAt(
        tester,
        Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const StaffDetailScreen())),
              child: const Text('open'),
            ),
          ),
        ),
        const Size(390, 844));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('매장에서 내보내기'));
    await tester.pumpAndSettle();
    expect(find.text('수빈님을 매장에서 내보낼까요?'), findsOneWidget);
    await tester.tap(find.text('내보내기'));
    await tester.pumpAndSettle();
    expect(find.text('수빈님을 매장에서 내보냈어요'), findsOneWidget);
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

  testWidgets('웹 셸', (tester) async {
    await pumpAt(tester, const WebShell(), const Size(1440, 1024));
    expect(tester.takeException(), isNull);
  });
}
