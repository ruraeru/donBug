import 'package:flutter/material.dart';

import '../../data/app_scope.dart';
import '../../data/app_store.dart';
import '../../data/format.dart';
import '../../data/models.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import 'web_common.dart';

/// 유동 근무(매니저·정직원) 근무의 파트 이름. 파트 목록에 없는 이름은 모두 유동 근무로 본다.
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

/// 06:00–24:00 15분 단위(+ 이미 그 밖의 값이면 그 값도).
List<int> _times(int a, int b) => ({for (var m = 360; m <= 1440; m += 15) m, a, b}.toList()..sort());

/// W2 근무 추가 · 수정 창 (레퍼런스 ShiftDialog). [shift] 가 있으면 수정, 없으면 [date]에 추가.
/// 직원 = 근무/연차/휴무 + 시간 미정, 알바생 = 파트 또는 직접 입력. 편집기(초안 모드)에서는 로컬에만 반영된다.
Future<void> showShiftDialog(BuildContext context,
    {Shift? shift, required DateTime date, String? staffId, String? part}) {
  final store = AppScope.read(context);
  final staffList = [...store.flexStaff, ...store.partStaff];
  final parts = store.store.parts;
  // 파트 칸 빈 칸: 그 파트 알바 중 그날 근무 없는 사람이 기본 구성원.
  final busy = store.scheduleOn(date).map((x) => x.staffId).toSet();
  final partPeople = store.partStaff.where((s) => s.part == part).toList();
  var who = store.staffById(shift?.staffId ?? staffId) ??
      (part == flexPart ? store.flexStaff.firstOrNull : null) ??
      partPeople.where((s) => !busy.contains(s.id)).firstOrNull ??
      partPeople.firstOrNull ??
      staffList.first;
  PartTemplate? partOf(String? name) => parts.where((p) => p.name == name).firstOrNull;
  // null = 직접 입력(파트 없음)
  PartTemplate? pt = shift == null ? (partOf(part ?? who.part) ?? parts.firstOrNull) : partOf(shift.part);
  var kind = shift?.kind ?? ShiftKind.work;
  var start = shift?.startMin ?? (who.kind.flex ? 540 : pt?.startMin ?? 540);
  var end = shift == null ? (who.kind.flex ? 1080 : pt?.endMin ?? 1080) : shift.endAbs;
  if (end > 1440 && shift == null) end = 1440;
  var tbd = shift?.timeTbd ?? false;
  // 수정 창에서 시간이 06–24 밖이면 그대로 보여 주기만 한다.
  int span() => end - start;
  var breakMin = shift?.breakMin ?? AppStore.defaultBreak(span());
  String? error;

  void setTimes(int a, int b, StateSetter set) => set(() {
        start = a;
        end = b;
        breakMin = AppStore.defaultBreak(span());
      });

  void pickWho(Staff s, StateSetter set) => set(() {
        who = s;
        if (s.kind.flex) {
          pt = null;
        } else {
          pt = partOf(s.part) ?? pt ?? parts.firstOrNull;
          start = pt?.startMin ?? start;
          end = pt == null ? end : (pt!.endMin <= pt!.startMin ? pt!.endMin + 1440 : pt!.endMin);
          breakMin = pt?.breakMin ?? AppStore.defaultBreak(span());
        }
      });

  void save(BuildContext ctx, StateSetter set) {
    if (kind == ShiftKind.work && end <= start) {
      return set(() => error = '퇴근 시각은 출근 시각보다 늦어야 해요');
    }
    final legal = AppStore.defaultBreak(span());
    if (kind == ShiftKind.work && breakMin < legal) {
      return set(() => error = '법정 최소 휴게는 $legal분이에요');
    }
    final partName = who.kind.flex ? flexPart : (pt?.name ?? flexPart);
    final endMin = end > 1440 ? end - 1440 : end;
    if (kind == ShiftKind.work && !tbd) {
      final draft = Shift(
          id: shift?.id ?? '',
          storeId: store.store.id,
          staffId: who.id,
          date: ymd(date),
          startMin: start,
          endMin: endMin,
          part: partName);
      final other = store.overlappingShift(who.id, draft);
      if (other != null) {
        return set(() => error = '${shiftDay(other)} ${shiftTime(other)}에 이미 근무가 있어요');
      }
    }
    final isTbd = who.kind.flex && kind == ShiftKind.work && tbd;
    if (shift == null) {
      store.addShift(
          date: date,
          startMin: start,
          endMin: endMin,
          part: partName,
          staffIds: [who.id],
          breakMin: kind == ShiftKind.work ? breakMin : 0,
          kind: kind,
          timeTbd: isTbd);
    } else {
      store.updateShift(shift.id,
          staffId: who.id,
          startMin: start,
          endMin: endMin,
          part: partName,
          breakMin: kind == ShiftKind.work ? breakMin : 0,
          kind: kind,
          timeTbd: isTbd);
    }
    Navigator.pop(ctx);
  }

  return showWebDialog<void>(
    context,
    title: '${weekday(date)} ${date.month}/${date.day} 근무 ${shift == null ? '추가' : '수정'}',
    builder: (ctx, set) {
      final times = _times(start, end);
      final breaks = {0, 30, 60, 90, 120, breakMin}.toList()..sort();
      return Column(
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
          if (who.kind.flex) ...[
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
          ],
          if (kind == ShiftKind.work && !who.kind.flex) ...[
            const SizedBox(height: 16),
            webField(
              '파트',
              WebSelect<PartTemplate?>(
                value: pt,
                items: [
                  for (final p in parts) (p, '${p.name} ${range(p.startMin, p.endMin)}'),
                  (null, '직접 입력'),
                ],
                onChanged: (p) => set(() {
                  pt = p;
                  if (p != null) {
                    start = p.startMin;
                    end = p.endMin <= p.startMin ? p.endMin + 1440 : p.endMin;
                    breakMin = p.breakMin;
                  }
                }),
              ),
            ),
          ],
          if (kind == ShiftKind.work) ...[
            const SizedBox(height: 16),
            webPair(
              webField('출근',
                  WebSelect<int>(value: start, items: [for (final m in times) (m, hm(m))], onChanged: (m) => setTimes(m, end, set))),
              webField('퇴근',
                  WebSelect<int>(value: end, items: [for (final m in times) (m, hm(m))], onChanged: (m) => setTimes(start, m, set))),
            ),
            const SizedBox(height: 16),
            webPair(
              webField(
                '휴게',
                WebSelect<int>(
                  value: breakMin,
                  items: [for (final b in breaks) (b, '$b분')],
                  onChanged: (b) => set(() => breakMin = b),
                ),
                help: '법정 최소 ${AppStore.defaultBreak(span())}분',
              ),
              webField('휴게 시작', const FieldBox('자동'), help: '근무 중간'),
            ),
            if (who.kind.flex) ...[
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
          ],
          if (kind == ShiftKind.leave) ...[
            const SizedBox(height: 10),
            Text('연차는 입력한 근무 시각만큼(휴게 제외) 유급으로 계산돼요. 이날 근무는 삭제돼요.',
                style: AppText.style(12, FontWeight.w400, AppColors.textSecondary)),
          ],
          if (kind == ShiftKind.off) ...[
            const SizedBox(height: 10),
            Text('이날 근무와 연차를 모두 비워요.',
                style: AppText.style(12, FontWeight.w400, AppColors.textSecondary)),
          ],
          if (error != null) ...[
            const SizedBox(height: 12),
            Text(error!, style: AppText.style(13, FontWeight.w500, AppColors.danger)),
          ],
        ],
      );
    },
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
