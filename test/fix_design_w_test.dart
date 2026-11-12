import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:donbug/widgets/common.dart';

void main() {
  test('WonInputFormatter: 쉼표 · 숫자만 · 커서', () {
    const f = WonInputFormatter();
    final v = f.formatEditUpdate(
        TextEditingValue.empty, const TextEditingValue(text: '10320', selection: TextSelection.collapsed(offset: 5)));
    expect(v.text, '10,320');
    expect(v.selection.baseOffset, 6);
    final w = f.formatEditUpdate(v, const TextEditingValue(text: 'a1', selection: TextSelection.collapsed(offset: 2)));
    expect(w.text, '1');
    expect(f.formatEditUpdate(v, const TextEditingValue(text: '')).text, '');
    expect(wonDigits('10,320'), 10320);
    expect(wonDigits(''), isNull);
  });

  testWidgets('AppTextField won: 쉼표 + 원 단위', (tester) async {
    final c = TextEditingController();
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: AppTextField(controller: c, won: true))));
    await tester.enterText(find.byType(TextField), '12500');
    expect(c.text, '12,500');
    expect(find.text('원'), findsOneWidget);
  });
}
