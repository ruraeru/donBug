import 'package:flutter_test/flutter_test.dart';

import 'package:donbug/main.dart';

void main() {
  testWidgets('앱이 로그인 화면으로 시작한다', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    expect(tester.takeException(), isNull);
  });
}
