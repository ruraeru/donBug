import 'package:flutter/material.dart';

import '../../data/app_scope.dart';
import '../../data/app_store.dart';
import '../../data/format.dart';
import '../../data/models.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import '../employer/employer_parts.dart';
import 'web_common.dart';

/// 유동 근무(매니저·정직원) 근무의 파트 이름.
const flexPart = '직원';

/// 근무표에 쓰는 이름: '김민지 (알바)'.
String staffLabel(AppStore store, Staff s) => '${store.personOf(s).fullName} (${s.kind.label})';

/// 근무를 [day]로 옮길 때 겹침 · 지난 날짜를 막는다. 막으면 사유를, 괜찮으면 null.
String? moveProblem(AppStore store, Shift s, {required DateTime day, String? staffId, int? start, int? end}) {
  if (day.isBefore(store.today)) return '지난 날짜로는 옮길 수 없어요';
  if (s.kind != ShiftKind.work || s.timeTbd) return null;
  final draft = Shift(
    id: s.id,
    storeId: s.storeId,
    staffId: staffId ?? s.staffId,
    date: ymd(day),
    startMin: start ?? s.startMin,
    endMin: end ?? s.endMin,
    part: s.part,
  );
  final other = store.overlappingShift(draft.staffId, draft);
  return other == null
      ? null
      : '${store.nameOf(draft.staffId)}님은 ${shiftDay(other)} ${shiftTime(other)}에 이미 근무가 있어요';
}

/// W2 근무 추가 · 수정 창 (Figma 151:10302 · 151:10579 · 151:10930).
/// [shift] 가 있으면 수정, 없으면 [date]에 추가.
Future<void> showShiftDialog(BuildContext context,
    {Shift? shift, required DateTime date, String? staffId, String? part}) {
  final store = AppScope.read(context);
  final staffList = [...store.flexStaff, ...store.partStaff];
  final parts = store.store.parts;
  var who = store.staffById(shift?.staffId ?? staffId) ??
      (part == flexPart ? store.flexStaff.firstOrNull : null) ??
      staffList.first;
  PartTemplate? partOf(String name) => parts.where((p) => p.name == name).firstOrNull;
  var pt = partOf(shift?.part ?? part ?? who.part) ?? parts.first;
  var kind = shift?.kind ?? ShiftKind.work;
  var start = shift?.startMin ?? (who.kind.flex ? 540 : pt.startMin);
  var end = shift?.endMin ?? (who.kind.flex ? 1080 : pt.endMin);
  int span() => (end <= start ? end + 1440 : end) - start;
  var breakMin = shift?.breakMin ?? AppStore.defaultBreak(span());
  var tbd = shift?.timeTbd ?? false;
  String? error;

  void pickWho(Staff s, StateSetter set) => set(() {
        who = s;
        if (!s.kind.flex) {
          pt = partOf(s.part) ?? pt;
          start = pt.startMin;
          end = pt.endMin;
          breakMin = AppStore.defaultBreak(span());
        }
      });

  Future<void> pickClock(BuildContext ctx, StateSetter set, bool isStart) async {
    final v = await pickTime(ctx, isStart ? start : end);
    if (v == null) return;
    set(() {
      isStart ? start = v : end = v;
      final min = AppStore.defaultBreak(span());
      if (breakMin < min) breakMin = min;
    });
  }

  void save(BuildContext ctx, StateSetter set) {
    final legal = AppStore.defaultBreak(span());
    if (kind == ShiftKind.work && breakMin < legal) {
      return set(() => error = '법정 최소 휴게는 $legal분이에요');
    }
    final partName = who.kind.flex ? flexPart : pt.name;
    if (kind == ShiftKind.work && !tbd) {
      final draft = Shift(
          id: shift?.id ?? '',
          storeId: store.store.id,
          staffId: who.id,
          date: ymd(date),
          startMin: start,
          endMin: end,
          part: partName);
      final other = store.overlappingShift(who.id, draft);
      if (other != null) {
        return set(() => error = '${shiftDay(other)} ${shiftTime(other)}에 이미 근무가 있어요');
      }
    }
    if (shift == null) {
      store.addShift(
          date: date,
          startMin: start,
          endMin: end,
          part: partName,
          staffIds: [who.id],
          breakMin: breakMin,
          kind: kind,
          timeTbd: tbd);
    } else {
      store.updateShift(shift.id,
          staffId: who.id,
          startMin: start,
          endMin: end,
          part: partName,
          breakMin: breakMin,
          kind: kind,
          timeTbd: tbd);
    }
    Navigator.pop(ctx);
  }

  final breaks = {0, 30, 60, 90, breakMin}.toList()..sort();
  return showWebDialog<void>(
    context,
    title: '${weekday(date)} ${date.month}/${date.day} 근무 ${shift == null ? '추가' : '수정'}',
    builder: (ctx, set) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        webField(
          '구성원',
          WebSelect<Staff>(
            value: who,
            enabled: shift == null,
            items: [for (final s in staffList) (s, staffLabel(store, s))],
            onChanged: (s) => pickWho(s, set),
          ),
        ),
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerLeft,
          child: WebSegmented(
            labels: [for (final k in ShiftKind.values) k.label],
            selected: kind.index,
            itemWidth: 64,
            onChanged: (i) => set(() => kind = ShiftKind.values[i]),
          ),
        ),
        if (kind == ShiftKind.work && !who.kind.flex) ...[
          const SizedBox(height: 16),
          webField(
            '파트',
            WebSelect<PartTemplate>(
              value: pt,
              items: [for (final p in parts) (p, '${p.name} ${range(p.startMin, p.endMin)}')],
              onChanged: (p) => set(() {
                pt = p;
                start = p.startMin;
                end = p.endMin;
                breakMin = AppStore.defaultBreak(span());
              }),
            ),
          ),
        ],
        if (kind != ShiftKind.off) ...[
          const SizedBox(height: 16),
          webPair(
            webField('출근', FieldBox(hm(start), onTap: () => pickClock(ctx, set, true))),
            webField('퇴근', FieldBox(hm(end), onTap: () => pickClock(ctx, set, false))),
          ),
        ],
        if (kind == ShiftKind.work) ...[
          const SizedBox(height: 16),
          webPair(
            webField(
              '휴게',
              WebSelect<int>(
                value: breakMin,
                items: [for (final b in breaks) (b, b == 0 ? '없음' : '$b분')],
                onChanged: (b) => set(() => breakMin = b),
              ),
              help: '법정 최소 ${AppStore.defaultBreak(span())}분',
            ),
            webField('휴게 시작', const FieldBox('자동'), help: '근무 중간'),
          ),
          const SizedBox(height: 14),
          InkWell(
            onTap: () => set(() => tbd = !tbd),
            borderRadius: BorderRadius.circular(8),
            child: Row(children: [
              Checkbox(
                value: tbd,
                activeColor: AppColors.primary,
                onChanged: (v) => set(() => tbd = v ?? false),
              ),
              Text('시간 미정 (확정 전 본인 확인 필요)', style: AppText.style(14)),
            ]),
          ),
        ],
        if (kind == ShiftKind.leave) ...[
          const SizedBox(height: 10),
          Text('연차는 ${hours(span())} 유급으로 계산돼요',
              style: AppText.style(12, FontWeight.w400, AppColors.textSecondary)),
        ],
        if (error != null) ...[
          const SizedBox(height: 12),
          Text(error!, style: AppText.style(13, FontWeight.w500, AppColors.danger)),
        ],
      ],
    ),
    leading: shift == null
        ? null
        : (ctx, set) => WebButton('삭제', style: WebButtonStyle.danger, onPressed: () {
              store.deleteShift(shift.id);
              Navigator.pop(ctx);
            }),
    actions: (ctx, set) => [
      WebButton('취소', style: WebButtonStyle.outline, onPressed: () => Navigator.pop(ctx)),
      WebButton('저장', onPressed: () => save(ctx, set)),
    ],
  );
}
