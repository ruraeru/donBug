import 'package:flutter/material.dart';

import '../../data/app_scope.dart';
import '../../data/app_store.dart';
import '../../data/format.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import 'attendance_detail_screen.dart';
import 'employer_parts.dart';

/// 근태 현황 (Figma 47:402). 날짜를 바꿔 지난 기록도 본다.
class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  DateTime? _day;

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final day = _day ?? store.today;
    final shifts = store.shiftsOn(day);
    // 출근(정상) · 지각(근무 중 포함) · 대기 · 미출근
    String bucket(s) {
      final st = store.attendanceStatus(s);
      if (st == AttStatus.waiting || st == AttStatus.absent) return st.name;
      return store.lateMinutes(s) > 0 ? 'late' : 'normal';
    }
    final buckets = [for (final s in shifts) bucket(s)];
    int count(String b) => buckets.where((x) => x == b).length;
    final summary = [
      ('출근', count('normal'), AttStatus.normal),
      ('지각', count('late'), AttStatus.late),
      ('대기', count('waiting'), AttStatus.waiting),
      ('미출근', count('absent'), AttStatus.absent),
    ];
    return Scaffold(
      appBar: AppHeader(day == store.today ? '오늘 근태' : '근태 현황', actions: [
        IconButton(
          tooltip: '이전 날',
          onPressed: () => setState(() => _day = day.subtract(const Duration(days: 1))),
          icon: const Icon(Icons.chevron_left_rounded, size: 28),
        ),
        Text(md(day), style: AppText.style(14, FontWeight.w500, AppColors.primary)),
        IconButton(
          tooltip: '다음 날',
          onPressed: day == store.today
              ? null
              : () => setState(() => _day = day.add(const Duration(days: 1))),
          icon: Icon(Icons.chevron_right_rounded,
              size: 28, color: day == store.today ? AppColors.border : AppColors.textPrimary),
        ),
      ]),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        children: [
          Row(
            children: [
              for (var i = 0; i < summary.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(child: _summary(summary[i].$1, summary[i].$2, summary[i].$3)),
              ],
            ],
          ),
          if (shifts.isEmpty) const EmptyNote('이날 근무가 없어요'),
          for (final s in shifts) ...[
            const SizedBox(height: 12),
            Builder(builder: (context) {
              final st = store.attendanceStatus(s);
              final (label, fg, bg) = attStyle(st);
              final a = store.attendanceFor(s.id);
              final late = store.lateMinutes(s);
              final sub = switch (st) {
                AttStatus.waiting => '${hm(s.startMin)} 출근 예정 · ${s.part}',
                AttStatus.absent => '${shiftTime(s)} · 출근 기록 없음',
                AttStatus.working =>
                  '${clock(DateTime.parse(a!.clockIn))} 출근 · 근무 중${late > 0 ? ' · $late분 지각' : ''}',
                _ =>
                  '${clock(DateTime.parse(a!.clockIn))}–${clock(DateTime.parse(a.clockOut!))}'
                      '${late > 0 ? ' · $late분 지각' : ' · 정상'}${a.editReason != null ? ' · 수정됨' : ''}',
              };
              return PersonRow(
                avatar: MemberAvatar(store.staffById(s.staffId)!),
                title: store.nameOf(s.staffId),
                subtitle: sub,
                trailing: st == AttStatus.normal || st == AttStatus.working
                    ? Text(label,
                        style: AppText.style(13, FontWeight.w400, AppColors.textSecondary))
                    : Pill(label, color: fg, background: bg),
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => AttendanceDetailScreen(shiftId: s.id))),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _summary(String label, int n, AttStatus style) {
    final alert = n > 0 && (style == AttStatus.late || style == AttStatus.absent);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Text(label, style: AppText.style(12, FontWeight.w400, AppColors.textSecondary)),
          const SizedBox(height: 4),
          Text('$n',
              style: AppText.style(22, FontWeight.w500,
                  alert ? AppColors.danger : AppColors.textPrimary)),
        ],
      ),
    );
  }
}
