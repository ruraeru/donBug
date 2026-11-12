// 알바생 영상: 김태우의 하루 (2026-05-14 미들 14–20, 카페 커푸치노).
// 녹화: VIDEO_DIR=<폴더> ./flutter/bin/flutter test test/demo/employee_demo_test.dart --update-goldens
import 'package:donbug/data/app_store.dart';
import 'package:donbug/data/models.dart';
import 'package:donbug/main.dart';
import 'package:donbug/screens/employee/employee_parts.dart';
import 'package:donbug/widgets/common.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'recorder.dart';

void main() {
  testWidgets('알바생 하루', (tester) async {
    final store = AppStore.seeded(now: DateTime(2026, 5, 14, 13, 55))..switchRole(Role.employee);
    final noticeTitle = store.storeNotices.first.title;
    final rec = Recorder(tester, 'employee');
    final back = find.text('‹');
    final scroll = find.byType(Scrollable);

    await rec.start(MyApp(store: store), caption: '돈벌래 — 알바생 하루');
    await rec.hold(1200);

    // 1. 로그인
    await rec.tap(find.text('카카오로 시작하기'), caption: '카카오로 간편하게 시작해요');
    await rec.tap(find.text('동의하고 계속하기'), caption: '필수 항목에 동의해요');
    await rec.tap(find.text('알바생이에요'), caption: '역할은 알바생을 골라요', ms: 800);
    await rec.tap(find.text('다음'), caption: '다니는 매장의 코드를 입력해요');
    await rec.enter(find.byType(TextField), 'CAFE-8K2D', ms: 1100);
    await rec.tap(find.text('가입 신청하기'), caption: '가입한 매장이라 바로 들어가요', ms: 1100);
    await rec.say('커푸치노 알바생 홈이에요', ms: 1200);

    // 2. QR 출근
    await rec.say('오늘 미들 14시–20시 근무가 있어요', ms: 1400);
    await rec.tap(find.text('출근하기'), caption: '출근하기를 눌러요');
    await rec.say('매장 POS 의 QR 을 스캔해요', ms: 1100);
    await rec.tap(find.byKey(const ValueKey('qr-scan')), caption: 'QR 을 찍으면 바로 출근돼요', ms: 1400);
    await rec.tap(find.text('홈으로 가기'), caption: '출근 완료, 홈으로 돌아가요');
    await rec.say('홈에 근무 중으로 표시돼요', ms: 1600);

    // 3. 근무표
    await rec.tap(find.text('근무표').last, caption: '근무표에서 이번 주 근무를 봐요', ms: 1600);
    await rec.tap(find.widgetWithText(AppCard, '16'), caption: '5월 16일 토요일 근무를 열어요');
    await rec.say('같은 시간 근무자도 볼 수 있어요', ms: 1200);

    // 4. 대타 요청
    await rec.tap(find.text('휴무 · 대타 신청'), caption: '이 날은 어려워서 대타를 구해요');
    await rec.enter(find.byType(TextField), '가족 모임이 있어서 근무가 어려워요');
    await rec.say('사유를 적어요', ms: 1200);
    await rec.tap(find.text('휴무 신청하고 대타 구하기'), caption: '동료와 사장님께 알림이 가요', ms: 1600);
    await rec.tap(find.text('요청 현황 보기'), caption: '요청 현황에서 진행 단계를 봐요');
    await rec.say('동료 수락 → 사장님 승인 순서예요', ms: 1900);
    await rec.tap(back, caption: '홈으로 돌아가요', ms: 600);

    // 5. 급여
    await rec.tap(find.text('급여').last, caption: '급여 탭에서 이번 달 예상 급여를 봐요', ms: 1900);
    await rec.tap(find.text('이번 달 예상 실수령액'), caption: '명세서를 열어요', ms: 1900);
    await rec.drag(scroll.first, const Offset(0, -330));
    await rec.say('주휴수당과 공제까지 한눈에 보여요', ms: 2000);
    await rec.tap(back, caption: '급여 탭으로 돌아가요', ms: 600);

    // 6. 서류 · 서명
    await rec.tap(find.text('MY').last, caption: 'MY 에서 내 서류를 열어요', ms: 800);
    await rec.tap(find.text('내 서류'));
    await rec.say('근로계약서 서명이 필요해요', ms: 1400);
    await rec.tap(find.text('확인하고 서명하기'), caption: '계약서를 확인하고 서명해요');
    await rec.drag(scroll.first, const Offset(0, -400));
    await rec.drag(find.byType(SignaturePad), const Offset(150, 30), steps: 12, ms: 200);
    await rec.drag(find.byType(SignaturePad), const Offset(-110, -45), steps: 10, ms: 400);
    await rec.say('손가락으로 서명해요', ms: 1100);
    await rec.tap(find.text('계약 내용을 모두 확인했어요'), caption: '내용을 확인했다고 체크해요', ms: 700);
    await rec.tap(find.text('서명하고 제출'), caption: '서명하고 제출하면 끝이에요', ms: 1400);
    await rec.say('서명 완료', ms: 1400);
    await rec.tap(back, ms: 500);

    // 7. 공지
    await rec.tap(find.text('공지').last, caption: '공지 탭에서 새 소식을 확인해요', ms: 1200);
    await rec.tap(find.text(noticeTitle), caption: '공지를 열어 읽어요');
    await rec.tap(find.text('확인했어요 (필독)'), caption: '확인했어요를 누르면 읽음으로 남아요', ms: 1400);
    await rec.say('사장님은 확인 현황을 볼 수 있어요', ms: 1600);

    // 8. 끝
    await rec.say('QR 출근부터 대타 · 급여 · 서명까지 앱 하나로', ms: 2000);
    await rec.finish(tailMs: 800);
  });
}
