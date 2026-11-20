import 'dart:convert';

import 'package:donbug/data/ai_api.dart';
import 'package:donbug/data/api_client.dart';
import 'package:donbug/data/app_scope.dart';
import 'package:donbug/data/app_store.dart';
import 'package:donbug/data/models.dart';
import 'package:donbug/data/seed.dart';
import 'package:donbug/screens/employee/employee_my_screen.dart';
import 'package:donbug/screens/employer/ai_answer_detail_screen.dart';
import 'package:donbug/screens/employer/ai_labor_assistant_screen.dart';
import 'package:donbug/screens/web/web_ai_assistant_screen.dart';
import 'package:donbug/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _now = DateTime(2026, 5, 14, 14, 30);

Future<(AppStore, List<String>)> _store(int status, String body) async {
  SharedPreferences.setMockInitialValues({
    'donbug.access': 't',
    'donbug.refresh': 'r',
  });
  final prefs = await SharedPreferences.getInstance();
  final sent = <String>[];
  final api = ApiClient(
    prefs: prefs,
    baseUrl: 'http://x',
    client: MockClient((req) async {
      sent.add('${req.method} ${req.url.path} ${req.body}');
      return http.Response.bytes(utf8.encode(body), status);
    }),
  );
  return (AppStore(buildSeed(_now), now: () => _now, api: api), sent);
}

void main() {
  test('askLaborQuestion: 경로·본문·응답 파싱', () async {
    final (s, sent) = await _store(
      200,
      '{"answer":"네","createdAt":"2026-05-14T14:30:00"}',
    );
    final r = await askLaborQuestion(s.api!, '7', '주휴수당?');
    expect(r.answer, '네');
    expect(r.citations, isEmpty); // 예전 서버: citations 없음
    expect(
      sent.single,
      'POST /api/v1/stores/7/ai/labor-questions {"question":"주휴수당?"}',
    );
  });

  test('서버 에러는 message 그대로', () async {
    final (s, _) = await _store(
      503,
      '{"code":"AI_DISABLED","message":"AI 도우미가 아직 설정되지 않았어요"}',
    );
    try {
      await askLaborQuestion(s.api!, '7', 'q');
      fail('throw 해야 해요');
    } catch (e) {
      expect(aiErrorText(e), 'AI 도우미가 아직 설정되지 않았어요');
    }
  });

  testWidgets('서버 모드 화면: 질문 → 답 표시', (t) async {
    final (s, sent) = await _store(
      200,
      '{"answer":"줘야 해요","createdAt":"2026-05-14T14:30:00"}',
    );
    await t.pumpWidget(
      AppScope(
        store: s,
        child: const MaterialApp(home: AiLaborAssistantScreen()),
      ),
    );
    expect(find.textContaining('추후 개발 예정'), findsNothing);
    await t.enterText(find.byType(TextField), '주휴수당?');
    await t.tap(find.byIcon(Icons.arrow_upward_rounded));
    await t.pumpAndSettle();
    expect(find.text('줘야 해요'), findsOneWidget);
    expect(sent, hasLength(1));
  });

  test('askLaborQuestion: citations 파싱', () async {
    final (s, _) = await _store(200,
        '{"answer":"네","citations":["근로기준법 제55조","근로기준법 제18조"],"createdAt":"2026-05-14T14:30:00"}');
    final r = await askLaborQuestion(s.api!, '7', 'q');
    expect(r.citations, ['근로기준법 제55조', '근로기준법 제18조']);
  });

  test('auditLabor: 경로·파싱·정렬·기본값', () async {
    final (s, sent) = await _store(200, jsonEncode({
      'summary': '요약',
      'aiUsed': true,
      'createdAt': '2026-05-14T14:30:00',
      'findings': [
        {'code': 'OVER_40', 'severity': 'low', 'title': '낮음', 'detail': 'd', 'action': 'a'},
        {'code': 'X', 'severity': 'weird', 'title': '모름'},
        {'code': 'MIN_WAGE', 'severity': 'high', 'title': '높음', 'staffIds': ['12'], 'citations': ['최저임금법 제6조']},
        {'code': 'CERT_MISSING', 'severity': 'medium', 'title': '보통', 'staffIds': null},
      ],
    }));
    final a = await auditLabor(s.api!, '7');
    expect(sent.single, 'POST /api/v1/stores/7/ai/labor-audit ');
    expect(a.summary, '요약');
    expect(a.aiUsed, isTrue);
    expect([for (final f in a.findings) f.title], ['높음', '보통', '낮음', '모름']);
    expect(a.findings[3].severity, AuditSeverity.low);
    expect(a.findings[0].staffIds, ['12']);
    expect(a.findings[0].citations, ['최저임금법 제6조']);
    expect(a.findings[1].staffIds, isEmpty);
    expect(a.findings[3].citations, isEmpty);
    expect(a.findings[3].action, '');

    final (s2, _) = await _store(200, '{"summary":"없어요"}');
    final b = await auditLabor(s2.api!, '7');
    expect(b.aiUsed, isFalse);
    expect(b.findings, isEmpty);
  });

  group('웹 W7', () {
    /// 질문·점검을 경로별로 흉내 내는 가짜 서버. 사장님(카페) 세션.
    Future<(AppStore, List<String>)> web(WidgetTester t,
        {Size size = const Size(1440, 900), int auditStatus = 200, Object? audit}) async {
      SharedPreferences.setMockInitialValues({'donbug.access': 't', 'donbug.refresh': 'r'});
      final prefs = await SharedPreferences.getInstance();
      final sent = <String>[];
      final api = ApiClient(
        prefs: prefs,
        baseUrl: 'http://x',
        client: MockClient((req) async {
          sent.add('${req.method} ${req.url.path}');
          if (req.url.path.endsWith('/labor-questions')) {
            return http.Response.bytes(
                utf8.encode('{"answer":"줘야 해요","citations":["근로기준법 제55조"],"createdAt":"2026-05-14T14:30:00"}'),
                200);
          }
          if (req.url.path.endsWith('/labor-audit')) {
            return http.Response.bytes(
                utf8.encode(auditStatus == 200
                    ? jsonEncode(audit)
                    : '{"code":"AI_RATE_LIMIT","message":"잠시 뒤에 다시 물어봐 주세요"}'),
                auditStatus);
          }
          return http.Response('', 204);
        }),
      );
      final s = AppStore(buildSeed(_now), now: () => _now, api: api)..login(Role.employer);
      t.view.physicalSize = size;
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      await t.pumpWidget(AppScope(
          store: s,
          child: MaterialApp(theme: appTheme, home: const Scaffold(body: WebAiAssistantScreen()))));
      await t.pumpAndSettle();
      return (s, sent);
    }

    // 시드 id 는 매번 같다: 같은 시드로 만든 store 의 직원 id 를 서버 응답에 쓴다.
    final seeded = AppStore(buildSeed(_now), now: () => _now)..login(Role.employer);

    Map<String, Object?> auditOf({int repeat = 1, bool aiUsed = true}) {
      final s = seeded;
      final ids = [for (final x in s.activeStaff) x.id];
      return {
        'summary': '확인할 항목이 있어요. ' * repeat,
        'aiUsed': aiUsed,
        'createdAt': '2026-05-14T14:30:00',
        'findings': [
          for (var i = 0; i < repeat; i++) ...[
            {'code': 'OVER_40', 'severity': 'low', 'title': '주 40시간 초과 $i', 'detail': '긴 설명 ' * repeat,
              'action': '근무를 줄여요', 'staffIds': ids, 'citations': ['근로기준법 제50조']},
            {'code': 'MIN_WAGE', 'severity': 'high', 'title': '최저임금 미만 $i', 'detail': '시급 9,000원',
              'action': '시급을 올려요', 'staffIds': [ids.first], 'citations': ['최저임금법 제6조']},
            {'code': 'CERT_MISSING', 'severity': 'medium', 'title': '보건증 미등록 $i', 'detail': '',
              'action': '', 'staffIds': [], 'citations': []},
          ],
        ],
      };
    }

    testWidgets('질문 → 답과 근거 칩, 라벨은 AI', (t) async {
      final (_, sent) = await web(t);
      expect(find.textContaining('Claude'), findsNothing);
      expect(find.textContaining('AI 기반'), findsOneWidget);
      await t.enterText(find.byType(TextField), '주휴수당?');
      await t.tap(find.text('보내기'));
      await t.pumpAndSettle();
      expect(find.text('줘야 해요'), findsOneWidget);
      expect(find.text('근로기준법 제55조'), findsOneWidget);
      expect(sent, ['POST /api/v1/stores/${seeded.store.id}/ai/labor-questions']);
    });

    testWidgets('점검: 높음→낮음 순, 직원 이름 누르면 직원 상세', (t) async {
      final (s, sent) = await web(t, audit: auditOf(aiUsed: false));
      await t.tap(find.text('점검하기'));
      await t.pumpAndSettle();
      expect(find.text('매장 노무 점검 결과'), findsOneWidget);
      final y = [for (final x in ['최저임금 미만 0', '보건증 미등록 0', '주 40시간 초과 0']) t.getTopLeft(find.text(x)).dy];
      expect(y[0] < y[1] && y[1] < y[2], isTrue);
      expect(find.text('최저임금법 제6조'), findsOneWidget);
      expect(find.textContaining('기본 안내'), findsOneWidget);
      expect(sent, ['POST /api/v1/stores/${s.store.id}/ai/labor-audit']);
      final first = s.personOf(s.activeStaff.first).name;
      await t.tap(find.text(first).first);
      await t.pumpAndSettle();
      expect(find.text('직원 상세'), findsOneWidget);
    });

    testWidgets('점검: 항목 없음', (t) async {
      await web(t, audit: {'summary': '문제 없어요', 'aiUsed': false, 'findings': []});
      await t.tap(find.text('점검하기'));
      await t.pumpAndSettle();
      expect(find.text('찾은 위험 항목이 없어요'), findsOneWidget);
      expect(find.text('문제 없어요'), findsOneWidget);
    });

    testWidgets('점검: 에러는 서버 message 토스트', (t) async {
      await web(t, auditStatus: 429);
      await t.tap(find.text('점검하기'));
      await t.pump();
      await t.pump(const Duration(milliseconds: 100));
      expect(find.text('잠시 뒤에 다시 물어봐 주세요'), findsOneWidget);
      expect(find.text('매장 노무 점검 결과'), findsNothing);
      await t.pumpAndSettle(const Duration(seconds: 5));
    });

    for (final size in const [Size(1440, 900), Size(1280, 800), Size(1024, 768), Size(800, 1000)]) {
      testWidgets('긴 점검 결과 넘침 없음 ${size.width.toInt()}', (t) async {
        await web(t, size: size, audit: auditOf(repeat: 6));
        await t.tap(find.text('점검하기'));
        await t.pumpAndSettle();
        expect(find.text('매장 노무 점검 결과'), findsOneWidget);
        expect(t.takeException(), isNull);
      });
    }
  });

  group('모바일', () {
    Future<(AppStore, List<String>)> mobile(WidgetTester t, Size size, {Role role = Role.employee}) async {
      final (s, sent) = await _store(200,
          '{"answer":"대상이에요","citations":["근로기준법 제55조"],"createdAt":"2026-05-14T14:30:00"}');
      s.login(role);
      t.view.physicalSize = size;
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      await t.pumpWidget(AppScope(
          store: s,
          child: MaterialApp(
              theme: appTheme,
              home: role == Role.employee
                  ? const Scaffold(body: EmployeeMyScreen())
                  : const AiLaborAssistantScreen())));
      await t.pumpAndSettle();
      return (s, sent);
    }

    for (final size in const [Size(360, 640), Size(390, 844)]) {
      testWidgets('알바생 MY → AI 도우미 · 근거 칩 · 상세 ${size.width.toInt()}', (t) async {
        final (s, sent) = await mobile(t, size);
        await t.scrollUntilVisible(find.text('AI 노무 도우미'), 100);
        await t.tap(find.text('AI 노무 도우미'));
        await t.pumpAndSettle();
        expect(find.byType(AiLaborAssistantScreen), findsOneWidget);
        expect(find.text('주휴수당은 꼭 줘야 하나요?'), findsNothing);
        expect(find.text('AI'), findsOneWidget);
        await t.tap(find.text('저는 주휴수당 대상인가요?'));
        await t.pumpAndSettle();
        expect(t.takeException(), isNull);
        expect(sent.single,
            'POST /api/v1/stores/${s.session.storeId}/ai/labor-questions {"question":"저는 주휴수당 대상인가요?"}');
        expect(find.text('대상이에요'), findsOneWidget);
        expect(find.text('근로기준법 제55조'), findsOneWidget);
        await t.tap(find.text('대상이에요'));
        await t.pumpAndSettle();
        expect(find.byType(AiAnswerDetailScreen), findsOneWidget);
        expect(find.text('근로기준법 제55조'), findsOneWidget);
        expect(t.takeException(), isNull);
      });
    }

    testWidgets('사장님 화면은 사장님 추천 질문', (t) async {
      await mobile(t, const Size(390, 844), role: Role.employer);
      expect(find.text('주휴수당은 꼭 줘야 하나요?'), findsOneWidget);
      expect(find.text('저는 주휴수당 대상인가요?'), findsNothing);
      expect(find.text('노동법이나 매장 관리, 궁금한 걸 편하게 물어보세요.'), findsOneWidget);
    });

    testWidgets('데모 모드 MY 에는 AI 줄이 없다', (t) async {
      final s = AppStore(buildSeed(_now), now: () => _now)..login(Role.employee);
      await t.pumpWidget(AppScope(
          store: s, child: MaterialApp(theme: appTheme, home: const Scaffold(body: EmployeeMyScreen()))));
      await t.pumpAndSettle();
      expect(find.text('AI 노무 도우미'), findsNothing);
      expect(find.text('내 서류'), findsOneWidget);
    });
  });
}
