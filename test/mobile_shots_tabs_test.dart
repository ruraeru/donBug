// 모바일 탭 화면(알바생 5 · 사장님 5) 스크린샷. 사용법은 mobile_shots.dart 참고.
import 'package:donbug/data/models.dart';
import 'package:donbug/screens/employee/employee_shell.dart';
import 'package:donbug/screens/employer/employer_shell.dart';
import 'package:flutter_test/flutter_test.dart';

import 'mobile_shots.dart';

void main() {
  for (final (role, home, tabs) in [
    (Role.employee, const EmployeeShell(), ['홈', '근무표', '급여', '공지', 'MY']),
    (Role.employer, const EmployerShell(), ['홈', '근무표', '인건비', '서류', '공지']),
  ]) {
    testWidgets('${role.name} 탭', (tester) async {
      await tester.runAsync(loadShotFonts);
      await pumpShot(tester, home, store: shotStore(role: role), height: 1400);
      for (final tab in tabs) {
        await tester.tap(find.text(tab).last);
        await settle(tester);
        await shot(tester, '${role.name}_tab_$tab');
      }
    });
  }
}
