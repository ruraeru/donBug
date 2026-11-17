import 'package:flutter/material.dart';

import '../../data/api_client.dart';
import '../../data/app_scope.dart';
import '../../data/app_store.dart';
import '../../data/format.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import 'employer_parts.dart';

/// 근태 상세 · 수정 (Figma 47:453). 출근 기록이 없으면 새로 만든다.
class AttendanceDetailScreen extends StatefulWidget {
  const AttendanceDetailScreen({super.key, required this.shiftId});

  final String shiftId;

  @override
  State<AttendanceDetailScreen> createState() => _AttendanceDetailScreenState();
}

class _AttendanceDetailScreenState extends State<AttendanceDetailScreen> {
  final _reason = TextEditingController();
  int? _in;
  int? _out;
  bool _outTouched = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final store = AppScope.read(context);
    final s = store.shiftById(widget.shiftId);
    if (s == null) return;
    final a = store.attendanceFor(s.id);
    final day = parseYmd(s.date);
    int minutesOf(String iso) => DateTime.parse(iso).difference(day).inMinutes;
    _in = a == null ? s.startMin : minutesOf(a.clockIn);
    _out = a?.clockOut == null ? s.endAbs : minutesOf(a!.clockOut!);
    _reason.text = a?.editReason ?? '';
  }

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    final store = AppScope.read(context);
    final s = store.shiftById(widget.shiftId)!;
    if (_reason.text.trim().isEmpty) return showToast(context, '수정 사유를 입력해 주세요');
    var out = _out!;
    if (out <= _in!) out += 1440;
    final day = parseYmd(s.date);
    final inAt = day.add(Duration(minutes: _in!));
    final a = store.attendanceFor(s.id);
    // 근무 중(퇴근 없음)인 기록은 퇴근을 건드리지 않았으면 그대로 둔다. 새 기록은 소정 종료가 지났을 때만 기본 퇴근을 보낸다.
    final sendOut = _outTouched ||
        (a != null ? a.clockOut != null : !store.shiftEnd(s).isAfter(store.now));
    final outAt = sendOut ? day.add(Duration(minutes: out)) : null;
    final reason = _reason.text.trim();
    if (!store.remote) {
      a == null
          ? store.createAttendance(s.id, clockIn: inAt, clockOut: outAt, reason: reason)
          : store.editAttendance(a.id, clockIn: inAt, clockOut: outAt, reason: reason);
    } else {
      setState(() => _saving = true);
      try {
        await store.saveAttendanceRemote(
            attendanceId: a?.id, shiftId: s.id, clockIn: inAt, clockOut: outAt, reason: reason);
      } on ApiException catch (e) {
        if (mounted) {
          setState(() => _saving = false);
          showToast(context, e.message);
        }
        return;
      } catch (_) {
        if (mounted) {
          setState(() => _saving = false);
          showToast(context, '서버와 통신하지 못했어요');
        }
        return;
      }
    }
    if (!mounted) return;
    Navigator.pop(context);
    showToast(context, '근태 기록을 저장했어요');
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final s = store.shiftById(widget.shiftId);
    if (s == null) return const MissingScreen(title: '근태 상세');
    final a = store.attendanceFor(s.id);
    final late = store.lateMinutes(s);
    final st = store.attendanceStatus(s);
    final (label, fg, bg) = attStyle(st);
    final small = AppText.style(12, FontWeight.w400, AppColors.textSecondary);
    return Scaffold(
      appBar: const AppHeader('근태 상세 · 수정'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        children: [
          AppCard(
            child: Column(
              children: [
                Row(
                  children: [
                    MemberAvatar(store.staffById(s.staffId)!),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${store.nameOf(s.staffId)} · ${s.part}',
                              style: AppText.style(16, FontWeight.w500)),
                          Text('${shiftDay(s)} 예정 ${shiftTime(s)}', style: small),
                        ],
                      ),
                    ),
                    late > 0 || st == AttStatus.waiting || st == AttStatus.absent
                        ? (late > 0
                            ? Pill('지각 $late분', color: AppColors.danger, background: AppColors.dangerSoft)
                            : Pill(label, color: fg, background: bg))
                        : Text(label,
                            style: AppText.style(13, FontWeight.w400, AppColors.textSecondary)),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1, color: AppColors.border),
                const SizedBox(height: 12),
                KeyValueRow('실제 출근', a == null ? '-' : clock(DateTime.parse(a.clockIn))),
                const SizedBox(height: 12),
                KeyValueRow('실제 퇴근',
                    a?.clockOut == null ? (a == null ? '-' : '근무 중') : clock(DateTime.parse(a!.clockOut!))),
                const SizedBox(height: 12),
                KeyValueRow('인증 방식', a == null ? '-' : (a.editReason == null ? 'QR' : 'MANUAL (수정됨)')),
                const SizedBox(height: 12),
                KeyValueRow('연장 근무', a == null ? '-' : duration(store.overtimeMinutes(a))),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(a == null ? '기록 직접 입력' : '기록 수정',
                    style: AppText.style(14, FontWeight.w500, AppColors.textSecondary)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: LabeledField('출근',
                          child: FieldBox(hm(_in!), onTap: () async {
                            final m = await pickTime(context, _in!);
                            if (m != null) setState(() => _in = m);
                          })),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: LabeledField('퇴근',
                          child: FieldBox(hm(_out!), onTap: () async {
                            final m = await pickTime(context, _out!);
                            if (m != null) {
                              setState(() {
                                _out = m;
                                _outTouched = true;
                              });
                            }
                          })),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                LabeledField('수정 사유 (필수)',
                    child: AppTextField(controller: _reason, hint: '예: 지하철 지연, 사전 연락 받음')),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const NoteBox(
            '수정하면 기록이 MANUAL로 남고 급여가 자동으로 다시 계산돼요.',
            color: AppColors.textSecondary,
            background: AppColors.bg,
          ),
        ],
      ),
      bottomNavigationBar: BottomBar(children: [AppButton('수정 저장', onPressed: _save)]),
    );
  }
}
