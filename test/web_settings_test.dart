import 'package:donbug/data/models.dart';
import 'package:donbug/screens/web/web_settings_screen.dart';
import 'package:donbug/screens/web/web_staff_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'widget_test.dart' show employerStore, pumpAt;

PartRow _p(String name, int s, int e) => PartRow(1, '1', name, PartTone.open, s, e, 0, 1);

String? _err({int o = 480, int c = 1320, int wo = 480, int wc = 1320, List<PartRow> parts = const []}) =>
    settingsError(openMin: o, closeMin: c, weekendOpenMin: wo, weekendCloseMin: wc, parts: parts);

void main() {
  test('설정 검증 문구', () {
    expect(_err(), isNull);
    expect(_err(o: 600, c: 600), '평일 영업 종료 시각은 시작 시각보다 늦어야 합니다.');
    expect(_err(wo: 600, wc: 500), '주말·공휴일 영업 종료 시각은 시작 시각보다 늦어야 합니다.');
    expect(_err(o: 0, c: 1500), '영업시간은 24시간을 넘을 수 없습니다.');
    expect(_err(o: 480, c: 1560), isNull); // 익일 02:00 마감
    expect(_err(parts: [_p(' ', 480, 720)]), '파트 이름을 입력하세요.');
    expect(_err(parts: [_p('오픈', 720, 720)]), '오픈 종료 시각은 시작 시각보다 늦어야 합니다.');
  });

  test('휴게 · 새 파트 규칙', () {
    expect([partBreakFor(239), partBreakFor(240), partBreakFor(480)], [0, 30, 60]);
    final base = [_p('오픈', 480, 720), _p('마감', 1020, 1320)];
    final n = newPartRow(9, base, 480, 1320);
    expect((n.name, n.startMin, n.endMin, n.need), ('새 파트', 480, 720, 1)); // 마지막 파트가 마감까지 → 영업 시작부터
    final open = newPartRow(9, [_p('오픈', 480, 720)], 480, 1320);
    expect((open.startMin, open.endMin, open.breakMin, open.tone), (720, 960, 30, PartTone.middle));
  });

  test('고정 파트 토글', () {
    final f = List.generate(7, (_) => <String>[]);
    final one = toggleFixedCell(f, 2, '오픈');
    expect(one[2], ['오픈']);
    expect(f[2], isEmpty);
    final row = toggleFixedPart(one, '오픈');
    expect(row.every((d) => d.contains('오픈')), isTrue);
    expect(toggleFixedPart(row, '오픈').every((d) => d.isEmpty), isTrue);
    final col = toggleFixedDay(f, 0, ['오픈', '마감']);
    expect(col[0], ['오픈', '마감']);
    expect(toggleFixedDay(col, 0, ['오픈', '마감'])[0], isEmpty);
  });

  test('직원 근무시간 검증 · 고용 형태', () {
    expect(workHoursError(List.filled(7, null)), '근무 요일을 하나 이상 고르세요.');
    expect(workHoursError([WorkHours(540, 1080), ...List.filled(6, null)]), isNull);
    expect(workHoursBad(WorkHours(600, 600)), isTrue);
    expect(employmentKind(StaffKind.manager, flex: true), StaffKind.manager);
    expect(employmentKind(StaffKind.minor, flex: false), StaffKind.minor);
    expect(employmentKind(StaffKind.partTimer, flex: true), StaffKind.fulltime);
    expect(employmentKind(StaffKind.fulltime, flex: false), StaffKind.partTimer);
  });

  for (final w in [1440.0, 1280.0, 1024.0, 800.0]) {
    testWidgets('매장 설정 · 직원 시트 넘침 없음 @${w.toInt()}', (tester) async {
      final store = employerStore();
      await pumpAt(tester, const WebSettingsScreen(), Size(w, 900), store: store);
      expect(tester.takeException(), isNull);
      expect(find.text('알바생 근무 파트'), findsOneWidget);
      expect(find.text('10,320원 (2026년)'), findsOneWidget);

      final kid = store.activeStaff.firstWhere((s) => !s.kind.flex).id;
      await pumpAt(tester, Scaffold(body: SizedBox(width: 480, child: FixedWorkEditor(staffId: kid))),
          Size(w, 900), store: store);
      expect(tester.takeException(), isNull);
      final flex = store.activeStaff.firstWhere((s) => s.kind.flex).id;
      await pumpAt(tester, Scaffold(body: SizedBox(width: 480, child: FixedWorkEditor(staffId: flex))),
          Size(w, 900), store: store);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('파트 추가하면 저장 활성, 되돌리기', (tester) async {
    final store = employerStore();
    await pumpAt(tester, const WebSettingsScreen(), const Size(1440, 1200), store: store);
    await tester.tap(find.text('+ 파트 추가').first); // 알바생 카드
    await tester.pumpAndSettle();
    expect(find.text('새 파트'), findsOneWidget);
    expect(find.byType(TextFormField), findsWidgets);
    await tester.tap(find.text('되돌리기'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
