import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:donbug/screens/employer/ai_labor_assistant_screen.dart';
import 'package:donbug/screens/employer/employer_dashboard_screen.dart';
import 'package:donbug/screens/employer/employer_documents_screen.dart';

import 'widget_test.dart' show employerStore, pumpAt;

/// 사장님 앱 AI 노무 도우미 진입: 홈 줄 · 서류 탭 버튼.
void main() {
  const sizes = [Size(360, 640), Size(390, 844)];

  Future<void> openAndBack(WidgetTester tester, String label, String rootText) async {
    final entry = find.text(label);
    await tester.scrollUntilVisible(entry, 200, scrollable: find.byType(Scrollable).first);
    await tester.tap(entry);
    await tester.pumpAndSettle();
    expect(find.byType(AiLaborAssistantScreen), findsOneWidget);
    expect(find.text('AI 노무 도우미'), findsOneWidget); // 헤더 제목
    await tester.tap(find.text('‹'));
    await tester.pumpAndSettle();
    expect(find.byType(AiLaborAssistantScreen), findsNothing);
    expect(find.text(rootText), findsOneWidget);
  }

  for (final size in sizes) {
    testWidgets('홈 → AI 노무 도우미 → 뒤로 (${size.width.toInt()}×${size.height.toInt()})',
        (tester) async {
      await pumpAt(tester, const Scaffold(body: EmployerDashboardScreen()), size,
          store: employerStore());
      expect(tester.takeException(), isNull);
      await openAndBack(tester, 'AI 노무 도우미', '직원 관리');
      expect(tester.takeException(), isNull);
    });

    testWidgets('서류 탭 → AI 노무 도우미 → 뒤로 (${size.width.toInt()}×${size.height.toInt()})',
        (tester) async {
      await pumpAt(tester, const Scaffold(body: EmployerDocumentsScreen()), size,
          store: employerStore());
      expect(tester.takeException(), isNull);
      await openAndBack(tester, 'AI 노무 도우미에게 물어보기', '노무 체크리스트');
      expect(tester.takeException(), isNull);
    });
  }
}
