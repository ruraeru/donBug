import 'package:donbug/data/models.dart';
import 'package:donbug/screens/web/web_dashboard_screen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Shift shift(int start, int end) => Shift(
      id: 's1', storeId: 'st', staffId: 'f1', date: '2026-11-10',
      startMin: start, endMin: end, part: '마감');

  test('야간 근무의 자정 이후 출근은 다음 날', () {
    expect(attendanceInMin(shift(1320, 120), 10), 1450); // 22:00–02:00, 00:10 출근
    expect(attendanceInMin(shift(1320, 120), 1310), 1310); // 21:50 일찍 출근
    expect(attendanceInMin(shift(600, 1080), 10), 10); // 주간 근무는 그대로
  });

  test('직원 근무 현황 주 이동은 state 범위 안', () {
    final today = DateTime(2026, 11, 18); // 수
    // 지난달 1일(10/1 목)이 든 주 월요일 9/28 = 이번 주(11/16)에서 -7주
    expect(clampWeek(today, -20), -7);
    // 3개월 뒤 말일 2027-02-28(일)이 든 주 월요일 2/22 = +14주
    expect(clampWeek(today, 30), 14);
    expect(clampWeek(today, 3), 3);
  });
}
