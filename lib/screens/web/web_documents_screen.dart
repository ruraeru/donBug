import 'package:flutter/material.dart';

import '../../data/app_scope.dart';
import '../../data/app_store.dart';
import '../../data/format.dart';
import '../../data/models.dart';
import '../../theme.dart';
import '../../data/payroll.dart';
import '../../widgets/common.dart';
import 'web_common.dart';
import 'web_staff_screen.dart';

/// 노무 체크리스트: (항목, 완료?). 모두 매장 데이터에서 판정한다.
List<(String, bool)> laborChecklist(AppStore store) {
  final staff = store.activeStaff;
  return [
    ('근로계약서 서면 교부', staff.every((s) => s.contract?.signed ?? false)),
    ('4대보험·3.3% 공제 설정', staff.every((s) => s.deduction != Deduction.none)),
    // shortcut: 상시 근로자 수를 지금 재직 인원으로 근사. 정확히 하려면 월 평균 인원이 필요하다.
    (store.store.isSmall ? '5인 미만 사업장 설정 확인' : '5인 이상: 가산수당 · 연차 적용',
        store.store.isSmall == (staff.length < 5)),
    ('보건증 만료 관리', staff.every((s) => (store.certDaysLeft(store.personOf(s)) ?? -1) > 30)),
    ('급여명세서 교부 (앱 자동)', true),
  ];
}

/// W5 서류·컴플라이언스 (콘텐츠 영역).
class WebDocumentsScreen extends StatelessWidget {
  const WebDocumentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final items = laborChecklist(store);
    final staff = store.activeStaff;
    return WebPage(
      title: '서류 · 컴플라이언스',
      subtitle: '보건증 · 근로계약서 · 노무 체크리스트',
      actions: [
        WebButton('+ 계약서 작성',
            onPressed: () => showContractDialog(context)),
      ],
      children: [
        WebSplit(
          leftWidth: 420,
          gap: 20,
          breakpoint: 1000,
          left: AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(
                      child: Text('노무 체크리스트', style: AppText.style(16, FontWeight.w500))),
                  Text('${items.where((x) => x.$2).length}/${items.length} 완료',
                      style: AppText.style(13, FontWeight.w400, AppColors.textSecondary)),
                ]),
                for (final (label, done) in items) ...[
                  const SizedBox(height: 16),
                  Row(children: [
                    Container(
                      width: 24,
                      height: 24,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: done ? AppColors.primary : AppColors.surface,
                        shape: BoxShape.circle,
                        border: done ? null : Border.all(color: AppColors.border),
                      ),
                      child: done
                          ? const Icon(Icons.check_rounded, size: 16, color: AppColors.onPrimary)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        label,
                        style: AppText.style(14, FontWeight.w500,
                            done ? AppColors.textPrimary : AppColors.textSecondary),
                      ),
                    ),
                  ]),
                ],
              ],
            ),
          ),
          right: AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('직원별 서류', style: AppText.style(16, FontWeight.w500)),
                const SizedBox(height: 14),
                if (staff.isEmpty) const EmptyNote('재직 중인 직원이 없어요'),
                WebTable(
                  columns: const ['직원', '보건증', '만료일', '근로계약서'],
                  flex: const [170, 170, 130, 160],
                  onRowTap: (i) => showStaffSheet(context, staff[i].id),
                  rows: [
                    for (final s in staff)
                      [
                        webStaffCell(store, s),
                        certPill(store.certDaysLeft(store.personOf(s))),
                        webCellText(store.personOf(s).certExpiry == null
                            ? '-'
                            : dotDate(parseYmd(store.personOf(s).certExpiry!))),
                        contractPill(s.contract),
                      ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// 근로계약서 상태. 서명 완료는 조용한 글자, 손볼 것만 칩.
Widget contractPill(Contract? c) => switch (c) {
      null => Pill.accent('미작성'),
      Contract(signed: true) => webCellText('서명 완료'),
      _ => Pill.accent('서명 대기'),
    };

/// 전자 근로계약서 작성 · 서명 요청. 근무 요일 · 주 시간은 앞으로 2주 근무에서 채운다.
Future<void> showContractDialog(BuildContext context, {String? staffId}) {
  final store = AppScope.read(context);
  final candidates = store.activeStaff;
  if (candidates.isEmpty) return Future.value();
  var who = store.staffById(staffId) ?? candidates.first;
  final wage = TextEditingController(), hoursCtrl = TextEditingController();
  final days = TextEditingController(), duty = TextEditingController();
  var start = store.today, end = DateTime(store.today.year + 1, store.today.month, store.today.day);
  String? error;

  void fill(Staff s) {
    who = s;
    final upcoming = store
        .shiftsOfStaff(s.id)
        .where((x) => !parseYmd(x.date).isBefore(store.today))
        .take(14)
        .toList();
    final weekdays = upcoming.map((x) => parseYmd(x.date).weekday).toSet().toList()..sort();
    final weekMin = upcoming
        .where((x) => mondayOf(parseYmd(x.date)) == mondayOf(store.today))
        .fold(0, (m, x) => m + x.scheduledMinutes);
    wage.text = '${s.wage}';
    hoursCtrl.text = '${(weekMin / 60).round()}';
    days.text = weekdays.map((d) => weekday(DateTime(2024, 1, d))).join('·');
    duty.text = s.contract?.duty.isNotEmpty == true ? s.contract!.duty : s.part;
  }

  fill(who);
  Future<void> pickDate(BuildContext ctx, StateSetter set, bool isStart) async {
    final d = await showDatePicker(
        context: ctx,
        initialDate: isStart ? start : end,
        firstDate: DateTime(store.today.year - 1),
        lastDate: DateTime(store.today.year + 3));
    if (d != null) set(() => isStart ? start = d : end = d);
  }

  return showWebDialog<void>(
    context,
    title: '근로계약서 작성',
    width: 520,
    builder: (ctx, set) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      webField(
          '직원',
          WebSelect<Staff>(
            value: who,
            items: [for (final s in candidates) (s, '${store.personOf(s).fullName} (${s.kind.label})')],
            onChanged: (s) => set(() => fill(s)),
          )),
      const SizedBox(height: 14),
      webPair(
        webField('계약 시작', FieldBox(dotDate(start), onTap: () => pickDate(ctx, set, true))),
        webField('계약 종료', FieldBox(dotDate(end), onTap: () => pickDate(ctx, set, false))),
      ),
      const SizedBox(height: 14),
      webPair(
        webField('시급 (원)', AppTextField(controller: wage, keyboardType: TextInputType.number)),
        webField('주 소정근로시간', AppTextField(controller: hoursCtrl, keyboardType: TextInputType.number)),
      ),
      const SizedBox(height: 14),
      webField('근무 요일', AppTextField(controller: days, hint: '예: 월·수·금')),
      const SizedBox(height: 14),
      webField('업무 내용', AppTextField(controller: duty, hint: '예: 홀 서빙')),
      if (error != null) ...[
        const SizedBox(height: 12),
        Text(error!, style: AppText.style(13, FontWeight.w500, AppColors.danger)),
      ],
    ]),
    actions: (ctx, set) => [
      WebButton('취소', style: WebButtonStyle.outline, onPressed: () => Navigator.pop(ctx)),
      WebButton('서명하고 요청 보내기', onPressed: () {
        final w = int.tryParse(wage.text.replaceAll(RegExp(r'[^0-9]'), ''));
        final h = int.tryParse(hoursCtrl.text);
        if (w == null || w < minimumWage2026) {
          return set(() => error = '시급은 2026 최저임금 ${wonText(minimumWage2026)} 이상이어야 해요');
        }
        if (h == null || days.text.trim().isEmpty || duty.text.trim().isEmpty) {
          return set(() => error = '주 시간 · 근무 요일 · 업무 내용을 채워 주세요');
        }
        if (!end.isAfter(start)) return set(() => error = '종료일이 시작일보다 뒤여야 해요');
        store.createContract(
            who.id,
            Contract(
              start: ymd(start),
              end: ymd(end),
              wage: w,
              weeklyHours: h,
              workDays: days.text.trim(),
              duty: duty.text.trim(),
            ));
        Navigator.pop(ctx);
        showToast(context, '${store.personOf(who).name}님에게 서명 요청을 보냈어요');
      }),
    ],
  );
}
