/// 화면 표시용 포맷 함수.
library;

import 'models.dart';

const _weekdays = ['월', '화', '수', '목', '금', '토', '일'];

String _comma(int n) {
  final s = n.abs().toString();
  final b = StringBuffer(n < 0 ? '-' : '');
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
    b.write(s[i]);
  }
  return b.toString();
}

/// '1,234원'. 화면 전체 금액 표기를 하나로 맞춘다.
String won(int n) => n < 0 ? '-${_comma(-n)}원' : '${_comma(n)}원';

/// '1,234원'
String wonText(int n) => '${_comma(n)}원';

/// '1,234'
String comma(int n) => _comma(n);

DateTime dayOf(DateTime t) => DateTime(t.year, t.month, t.day);

/// 'yyyy-MM-dd'
String ymd(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

DateTime parseYmd(String s) => DateTime.parse(s);

/// 'yyyy-MM'
String ym(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}';

String weekday(DateTime d) => _weekdays[d.weekday - 1];

/// '5/14(수)'
String md(DateTime d) => '${d.month}/${d.day}(${weekday(d)})';

/// '2026.05.14'
String dotDate(DateTime d) =>
    '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';

/// 하루 기준 분 → '14:00' (1440 이상이면 다음날 시각).
String hm(int minutes) {
  final m = minutes % 1440;
  return '${(m ~/ 60).toString().padLeft(2, '0')}:${(m % 60).toString().padLeft(2, '0')}';
}

/// 시각 → '14:02'
String clock(DateTime t) => hm(t.hour * 60 + t.minute);

/// '10:00 – 16:00'
String range(int startMin, int endMin) => '${hm(startMin)} – ${hm(endMin)}';

/// 분 → '5시간 30분' / '6시간'
String duration(int minutes) {
  final h = minutes ~/ 60, m = minutes % 60;
  if (h == 0) return '$m분';
  return m == 0 ? '$h시간' : '$h시간 $m분';
}

/// 분 → '62h' / '5.5h'
String hours(int minutes) {
  final h = minutes / 60;
  return h == h.roundToDouble() ? '${h.round()}h' : '${h.toStringAsFixed(1)}h';
}

/// 'D-12' / 'D-Day' / 'D+3'
String dDay(DateTime target, DateTime today) {
  final d = dayOf(target).difference(dayOf(today)).inDays;
  if (d == 0) return 'D-Day';
  return d > 0 ? 'D-$d' : 'D+${-d}';
}

/// '방금 전' / '12분 전' / '3시간 전' / '어제' / '5/10'
String relative(DateTime t, DateTime now) {
  final diff = now.difference(t);
  if (diff.inMinutes < 1) return '방금 전';
  if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
  if (dayOf(t) == dayOf(now)) return '${diff.inHours}시간 전';
  if (dayOf(now).difference(dayOf(t)).inDays == 1) return '어제';
  return '${t.month}/${t.day}';
}

/// 그 주 월요일.
DateTime mondayOf(DateTime d) => dayOf(d).subtract(Duration(days: d.weekday - 1));

/// 근무 날짜 '5/14(수)'
String shiftDay(Shift s) => md(parseYmd(s.date));

/// '14:00 – 20:00'
String shiftTime(Shift s) => range(s.startMin, s.endMin);

/// '6시간 · 미들 · 휴게 30분'
String shiftCaption(Shift s) =>
    '${duration(s.endAbs - s.startMin)} · ${s.part}${s.breakMin > 0 ? ' · 휴게 ${s.breakMin}분' : ''}';
