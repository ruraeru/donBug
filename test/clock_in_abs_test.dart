import 'package:donbug/data/models.dart';
import 'package:donbug/screens/employer/employer_parts.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Shift shift(int start, int end) =>
      Shift(id: 's1', storeId: 'st', staffId: 'x', date: '2026-11-10', startMin: start, endMin: end, part: '마감');

  test('자정을 넘는 근무: 자정 이후 출근은 다음 날', () {
    final s = shift(22 * 60, 2 * 60);
    expect(clockInAbs(s, 10), 1450); // 00:10
    expect(clockInAbs(s, 21 * 60 + 30), 21 * 60 + 30); // 일찍 온 21:30 은 그날
    expect(clockInAbs(s, 22 * 60 + 5), 22 * 60 + 5);
    expect(clockInAbs(s, 1450), 1450); // 이미 다음 날 기준
  });

  test('보통 근무는 그대로', () {
    expect(clockInAbs(shift(9 * 60, 18 * 60), 8 * 60), 8 * 60);
  });
}
