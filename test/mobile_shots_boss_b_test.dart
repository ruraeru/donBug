// 사장님 서류 · 직원 · 공지 · AI 화면 스크린샷. 사용법은 mobile_shots.dart 참고.
import 'package:donbug/data/models.dart';
import 'package:donbug/screens/employer/ai_answer_detail_screen.dart';
import 'package:donbug/screens/employer/ai_labor_assistant_screen.dart';
import 'package:donbug/screens/employer/employer_contract_write_screen.dart';
import 'package:donbug/screens/employer/employer_documents_screen.dart';
import 'package:donbug/screens/employer/employer_health_cert_alert_screen.dart';
import 'package:donbug/screens/employer/employer_notice_screen.dart';
import 'package:donbug/screens/employer/employer_signature_request_screen.dart';
import 'package:donbug/screens/employer/employer_staff_documents_screen.dart';
import 'package:donbug/screens/employer/notice_read_status_screen.dart';
import 'package:donbug/screens/employer/notice_result_screen.dart';
import 'package:donbug/screens/employer/staff_approval_screen.dart';
import 'package:donbug/screens/employer/staff_detail_screen.dart';
import 'package:donbug/screens/employer/staff_management_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'mobile_shots.dart';

void main() {
  testWidgets('사장님 서류 · 직원 · 공지 · AI', (tester) async {
    await tester.runAsync(loadShotFonts);
    final store = shotStore(role: Role.employer);
    final staff = store.activeStaff;
    final unsigned = staff.firstWhere((s) => !(s.contract?.signed ?? false));
    final signed = staff.firstWhere((s) => s.contract?.signed ?? false);
    final notice = store.storeNotices.first;

    final screens = <String, Widget>{
      'documents': const EmployerDocumentsScreen(),
      'staff_documents': EmployerStaffDocumentsScreen(staffId: signed.id),
      'health_alert': EmployerHealthCertAlertScreen(staffId: signed.id),
      'contract_write': EmployerContractWriteScreen(staffId: unsigned.id),
      'staff_management': const StaffManagementScreen(),
      'staff_detail': StaffDetailScreen(staffId: signed.id),
      'staff_approval': const StaffApprovalScreen(),
      'notice': const EmployerNoticeScreen(),
      'notice_read': NoticeReadStatusScreen(noticeId: notice.id),
      'notice_result': NoticeResultScreen(NoticeResult.published, noticeId: notice.id),
      'ai': const AiLaborAssistantScreen(),
      'ai_detail': const AiAnswerDetailScreen(),
    };
    for (final e in screens.entries) {
      await pumpShot(tester, e.value, store: store, height: 1000);
      await shot(tester, e.key);
    }
    // 서명 요청 완료는 계약서가 있어야 한다.
    store.createContract(
        unsigned.id,
        Contract(
            start: '2026-05-14', end: '2027-05-13', wage: unsigned.wage, weeklyHours: 15, workDays: '화·목', duty: '홀'));
    await pumpShot(tester, EmployerSignatureRequestScreen(staffId: unsigned.id), store: store);
    await shot(tester, 'signature_request');
  });
}
