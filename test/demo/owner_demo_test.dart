// 사장님 시연 영상 (카페 커푸치노). 사용법은 recorder.dart 참고.
import 'package:donbug/data/app_store.dart';
import 'package:donbug/data/models.dart';
import 'package:donbug/main.dart';
import 'package:donbug/widgets/common.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'recorder.dart';

void main() {
  testWidgets('사장님 하루', (tester) async {
    // 알바생 영상에서 김태우가 한 일을 미리 적용한다.
    final store = AppStore.seeded(now: DateTime(2026, 5, 14, 13, 55))
      ..switchRole(Role.employee);
    final taewoo = store.myStaff!;
    store.clockIn(store.shiftsOn(store.today).firstWhere((s) => s.staffId == taewoo.id).id);
    final sat = store.shiftsOfStaff(taewoo.id).firstWhere((s) => s.date == '2026-05-16');
    final req = store.requestSubstitute(sat.id, reason: '친구 결혼식');
    store.simulatePeerAccept(req.id);
    store.signContract();
    final notice = store.storeNotices.first;
    store.markNoticeRead(notice.id);
    final peer = store.nameOf(store.subById(req.id)!.acceptedId);
    final dohyun = store.pendingStaff.first;
    final dohyunName = store.personOf(dohyun).name;
    final jimin = store.activeStaff.firstWhere((s) => s.personId == 'p-jimin');
    final jiminName = store.personOf(jimin).name;
    expect(store.session.loggedIn, isFalse);

    final r = Recorder(tester, 'owner');
    await r.start(MyApp(store: store), caption: '돈벌래 — 사장님 하루');
    await r.say('카페 커푸치노 사장님이 앱을 열어요', ms: 1200);

    // 1. 로그인
    await r.tap(find.text('카카오로 시작하기'), caption: '카카오로 간편하게 시작해요', ms: 700);
    await r.say('필수 항목만 동의하면 돼요', ms: 1200);
    await r.tap(find.text('동의하고 계속하기'), caption: '동의하고 계속해요', ms: 700);
    await r.tap(find.text('사장님이에요'), caption: '역할은 사장님을 골라요', ms: 700);
    await r.tap(find.text('다음'), caption: '매장 정보는 이미 채워져 있어요', ms: 700);
    await r.tap(find.text('매장 만들기').last, caption: '매장을 만들면 직원 초대 코드가 나와요');
    await r.say('이 코드로 직원이 가입해요', ms: 1400);
    await r.tap(find.text('직원 승인하러 가기'));
    await r.tap(find.text('대시보드로 이동'), caption: '사장님 홈으로 들어가요');

    // 2. 대시보드
    await r.say('오늘 출근 현황과 처리할 일이 한눈에 보여요', ms: 2400);
    await r.drag(find.byType(Scrollable).first, const Offset(0, -300));
    await r.say('가입 신청 · 보건증 만료도 홈에서 챙겨요', ms: 2200);

    // 3. 대타 승인
    await r.tap(find.text('대타 모집'), caption: '알바생의 대타 요청이 들어왔어요');
    final card = find.ancestor(
        of: find.textContaining('친구 결혼식'), matching: find.byType(AppCard));
    await r.say('5월 16일 미들 · 태우 → $peer', ms: 2200);
    await r.tap(find.descendant(of: card.first, matching: find.text('승인하고 반영')),
        caption: '승인하면 근무표가 바로 바뀌어요');
    await r.say('대타가 확정됐어요', ms: 2400);
    await r.tap(find.text('대시보드로 이동'), caption: '홈으로 돌아가요', ms: 700);

    // 4. 근무표
    await r.tap(find.text('근무표').last, caption: '근무표에서 확인해요');
    await r.tap(find.text('16'), caption: '5월 16일을 열어요');
    await r.say('미들 근무가 $peer · 대타로 바뀌었어요', ms: 2400);

    // 5. 직원 승인
    await r.tap(find.text('홈').last, caption: '홈으로 돌아가요', ms: 700);
    await r.tap(find.textContaining('가입 신청'), caption: '새로 가입을 신청한 직원이 있어요');
    await r.tap(find.text('승인하고 시급 설정'), caption: '$dohyunName님 시급을 정해 승인해요');
    await r.say('시급은 최저임금 이상으로만 정할 수 있어요', ms: 1600);
    await r.tap(find.text('승인'), caption: '가입을 승인했어요', ms: 1800);
    await r.tap(find.text('‹'));

    // 6. 서류
    await r.tap(find.text('서류').last, caption: '서류 현황을 봐요');
    await r.say('태우님 근로계약서는 서명 완료로 바뀌었어요', ms: 2400);
    await r.say('수빈님 보건증은 D-12, 곧 갱신해야 해요', ms: 2400);

    // 7. 급여
    await r.tap(find.text('인건비').last, caption: '이번 달 인건비를 봐요');
    await r.say('근로자별 지급 예정액이 자동 계산돼요', ms: 2200);
    await r.tap(find.text(jiminName), caption: '$jiminName님 급여를 열어요');
    await r.say('출근 기록으로 세전 · 공제 · 실수령액을 계산해요', ms: 2400);
    await r.tap(find.text('‹'));

    // 8. 공지
    await r.tap(find.text('공지').last, caption: '공지를 작성해요');
    await r.enter(find.widgetWithText(TextField, '제목'), '이번 주 토요일 마감 안내');
    await r.enter(find.widgetWithText(TextField, '내용을 입력해 주세요'),
        '토요일은 30분 일찍 마감해요. 정리 잘 부탁해요.');
    await r.tap(find.text('필독 (확인 여부 추적)'), caption: '필독으로 확인 여부도 추적해요');
    await r.tap(find.text('전체 발송'), caption: '전체 직원에게 발송해요');
    await r.say('공지를 발송했어요', ms: 1800);
    await r.tap(find.text('확인 현황 보기'), caption: '누가 읽었는지 바로 보여요', ms: 1000);
    await r.tap(find.text('‹'));
    await r.tap(find.textContaining(notice.title), caption: '지난 공지는 태우님이 확인했어요', ms: 2200);

    // 9. 끝
    await r.say('출근 · 대타 · 서류 · 급여 · 공지까지 한 앱에서', ms: 1800);
    await r.finish(tailMs: 500);
  });
}
