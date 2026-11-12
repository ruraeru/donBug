import 'package:flutter/material.dart';

import '../../data/app_scope.dart';
import '../../data/format.dart';
import '../../data/models.dart';
import '../../data/payroll.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import 'employer_parts.dart';
import 'employer_signature_request_screen.dart';

/// 근로계약서 작성 (Figma 48:425). 사장님 서명 후 직원에게 서명 요청.
class EmployerContractWriteScreen extends StatefulWidget {
  const EmployerContractWriteScreen({super.key, this.staffId});

  final String? staffId;

  @override
  State<EmployerContractWriteScreen> createState() => _EmployerContractWriteScreenState();
}

class _EmployerContractWriteScreenState extends State<EmployerContractWriteScreen> {
  String? _staffId;
  late DateTime _start;
  late DateTime _end;
  final _wage = TextEditingController();
  final _hours = TextEditingController();
  final _days = TextEditingController();
  final _duty = TextEditingController();

  @override
  void initState() {
    super.initState();
    final store = AppScope.read(context);
    _start = store.today;
    _end = DateTime(_start.year + 1, _start.month, _start.day - 1);
    final first = widget.staffId ??
        store.activeStaff.where((s) => !(s.contract?.signed ?? false)).firstOrNull?.id ??
        store.activeStaff.firstOrNull?.id;
    if (first != null) _select(first);
  }

  @override
  void dispose() {
    for (final c in [_wage, _hours, _days, _duty]) {
      c.dispose();
    }
    super.dispose();
  }

  /// 직원 정보로 칸을 채운다 (근무 요일·주 시간은 예정 근무에서).
  void _select(String staffId) {
    final store = AppScope.read(context);
    final s = store.staffById(staffId)!;
    final upcoming = store
        .shiftsOfStaff(s.id)
        .where((x) => !parseYmd(x.date).isBefore(store.today))
        .take(14)
        .toList();
    final weekdays = upcoming.map((x) => parseYmd(x.date).weekday).toSet().toList()..sort();
    final weekMinutes = upcoming
        .where((x) => mondayOf(parseYmd(x.date)) == mondayOf(store.today))
        .fold(0, (m, x) => m + x.scheduledMinutes);
    _staffId = staffId;
    _wage.text = wonInput(s.wage);
    _hours.text = '${(weekMinutes / 60).round()}';
    _days.text = weekdays.map((d) => weekday(DateTime(2024, 1, d))).join('·');
    _duty.text = s.contract?.duty.isNotEmpty == true ? s.contract!.duty : s.part;
  }

  List<String> get _missing => [
        if (_duty.text.trim().isEmpty) '업무 내용',
        if (int.tryParse(_hours.text) == null) '소정근로시간',
        if (_days.text.trim().isEmpty) '근무 요일',
        if (wonDigits(_wage.text) == null) '임금',
      ];

  Future<void> _pick(bool start) async {
    final d = await showDatePicker(
      context: context,
      initialDate: start ? _start : _end,
      firstDate: DateTime(_start.year - 1),
      lastDate: DateTime(_start.year + 3),
    );
    if (d != null) setState(() => start ? _start = d : _end = d);
  }

  void _submit() {
    if (_staffId == null) return showToast(context, '직원을 골라 주세요');
    if (_missing.isNotEmpty) return showToast(context, '${_missing.join(', ')}을(를) 입력해 주세요');
    final wage = wonDigits(_wage.text)!;
    if (wage < minimumWage2026) {
      return showToast(context, '시급은 2026 최저임금 ${wonText(minimumWage2026)} 이상이어야 해요');
    }
    if (!_end.isAfter(_start)) return showToast(context, '계약 종료일이 시작일보다 뒤여야 해요');
    AppScope.read(context).createContract(
      _staffId!,
      Contract(
        start: ymd(_start),
        end: ymd(_end),
        wage: wage,
        weeklyHours: int.parse(_hours.text),
        workDays: _days.text.trim(),
        duty: _duty.text.trim(),
      ),
    );
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => EmployerSignatureRequestScreen(staffId: _staffId!)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final s = store.staffById(_staffId);
    final missing = _missing;
    return Scaffold(
      appBar: const AppHeader('근로계약서 작성'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        children: [
          if (s == null)
            const EmptyNote('계약서를 작성할 직원이 없어요')
          else
            AppCard(
              onTap: () async {
                final pick = await pickStaff(context, store.activeStaff, title: '계약할 직원');
                if (pick != null) setState(() => _select(pick.id));
              },
              child: Row(
                children: [
                  MemberAvatar(s),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(store.personOf(s).fullName, style: AppText.style(16, FontWeight.w500)),
                        Text('표준 근로계약서 · 탭해서 직원 변경',
                            style: AppText.style(12, FontWeight.w400, AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  Text(s.contract == null ? '신규' : '재작성', style: AppText.style(13, FontWeight.w400, AppColors.textSecondary)),
                ],
              ),
            ),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
                child: LabeledField('계약 시작', child: FieldBox(dotDate(_start), onTap: () => _pick(true)))),
            const SizedBox(width: 12),
            Expanded(
                child: LabeledField('계약 종료', child: FieldBox(dotDate(_end), onTap: () => _pick(false)))),
          ]),
          const SizedBox(height: 16),
          LabeledField('시급 (원)',
              child: AppTextField(
                  controller: _wage,
                  won: true,
                  onChanged: (_) => setState(() {}))),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
              child: LabeledField('주 소정근로시간',
                  child: AppTextField(
                      controller: _hours,
                      keyboardType: TextInputType.number,
                      hint: '시간',
                      suffix: '시간',
                      onChanged: (_) => setState(() {}))),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: LabeledField('근무 요일',
                  child: AppTextField(
                      controller: _days, hint: '예: 화·목·토', onChanged: (_) => setState(() {}))),
            ),
          ]),
          const SizedBox(height: 16),
          LabeledField('업무 내용',
              child: AppTextField(controller: _duty, hint: '예: 홀 서빙', onChanged: (_) => setState(() {}))),
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text('필수 항목 점검', style: AppText.style(14, FontWeight.w500)),
                    ),
                    missing.isEmpty
                        ? Text('누락 항목 없음', style: AppText.style(13, FontWeight.w400, AppColors.textSecondary))
                        : Pill('${missing.length}개 누락',
                            color: AppColors.danger, background: AppColors.dangerSoft),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  missing.isEmpty
                      ? '근무 장소 · 업무 내용 · 소정근로시간 · 임금 · 휴일 필수 항목이 모두 입력됐어요.'
                      : '${missing.join(', ')} 항목을 채워 주세요.',
                  style: AppText.style(13, FontWeight.w400, AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomBar.button('서명 요청 보내기', onPressed: _submit),
    );
  }
}
