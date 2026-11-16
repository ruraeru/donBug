import 'dart:convert';

import 'package:donbug/data/ai_api.dart';
import 'package:donbug/data/api_client.dart';
import 'package:donbug/data/app_scope.dart';
import 'package:donbug/data/app_store.dart';
import 'package:donbug/data/seed.dart';
import 'package:donbug/screens/employer/ai_labor_assistant_screen.dart';
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
}
