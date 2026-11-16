import 'package:donbug/data/app_store.dart';
import 'package:donbug/data/seed.dart';
import 'package:donbug/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('빈 곳을 누르면 키보드(포커스)가 내려간다', (t) async {
    await t.pumpWidget(MyApp(store: AppStore(buildSeed(DateTime(2026, 5, 14, 14, 30)))));
    navigatorKey.currentState!.push(MaterialPageRoute(
        builder: (_) => const Scaffold(
            body: Column(children: [TextField(key: Key('f')), Expanded(child: SizedBox())]))));
    await t.pumpAndSettle();
    bool focused() => t.widget<EditableText>(find.byType(EditableText)).focusNode.hasFocus;
    await t.tap(find.byKey(const Key('f')));
    await t.pump();
    expect(focused(), isTrue);
    await t.tapAt(const Offset(200, 500));
    await t.pump();
    expect(focused(), isFalse);
  });
}
