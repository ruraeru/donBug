import 'package:flutter/material.dart';

import '../../data/app_scope.dart';
import '../../data/app_store.dart';
import '../../data/format.dart';
import '../../data/models.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import 'employer_parts.dart';

/// 근무 추가 (Figma 47:297). [shift] 를 주면 그 근무를 고치는 수정 모드(삭제 버튼 포함).
class ShiftAddScreen extends StatefulWidget {
  const ShiftAddScreen({super.key, required this.date, this.shift});

  final DateTime date;
  final Shift? shift;

  @override
  State<ShiftAddScreen> createState() => _ShiftAddScreenState();
}

class _ShiftAddScreenState extends State<ShiftAddScreen> {
  late DateTime _date = widget.date;
  int _part = 0;
  late int _start;
  late int _end;
  final Set<String> _picked = {};
  late int _need;
  bool _repeat = false;

  bool get _edit => widget.shift != null;

  @override
  void initState() {
    super.initState();
    _applyPart(0);
    final sh = widget.shift;
    if (sh != null) {
      final i = AppScope.read(context).store.parts.indexWhere((p) => p.name == sh.part);
      if (i >= 0) _part = i;
      _start = sh.startMin;
      _end = sh.endMin;
      _picked.add(sh.staffId);
    }
  }

  void _applyPart(int i) {
    final p = AppScope.read(context).store.parts[i];
    _part = i;
    _start = p.startMin;
    _end = p.endMin;
    _need = p.need;
  }

  Future<void> _pickDate() async {
    final today = AppScope.read(context).today;
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: _edit && _date.isBefore(today) ? _date : today,
      lastDate: today.add(const Duration(days: 180)),
    );
    if (d != null) setState(() => _date = d);
  }

  /// 겹치는 근무가 있으면 안내하고 true.
  bool _overlaps(AppStore store, String part, int weeks) {
    for (final id in _picked) {
      for (var w = 0; w < weeks; w++) {
        final d = dayOf(_date).add(Duration(days: 7 * w));
        final draft = Shift(
            id: widget.shift?.id ?? '',
            storeId: store.store.id,
            staffId: id,
            date: ymd(d),
            startMin: _start,
            endMin: _end,
            part: part);
        final o = store.overlappingShift(id, draft);
        if (o != null) {
          showToast(context,
              '${store.nameOf(id)}님은 ${md(d)} ${shiftTime(o)} 근무와 겹쳐요');
          return true;
        }
      }
    }
    return false;
  }

  Future<void> _delete() async {
    final store = AppScope.read(context);
    final sh = widget.shift!;
    final ok = await showConfirmDialog(context,
        title: '${store.nameOf(sh.staffId)}님 근무를 삭제할까요?',
        message: '${shiftDay(sh)} ${shiftTime(sh)} ${sh.part}',
        confirmLabel: '삭제',
        confirmVariant: AppButtonVariant.danger);
    if (!ok || !mounted) return;
    if (!store.deleteShift(sh.id)) {
      return showToast(context, '출근 기록이 있는 근무는 삭제할 수 없어요');
    }
    Navigator.pop(context);
    showToast(context, '근무를 삭제했어요');
  }

  void _submit() {
    final store = AppScope.read(context);
    if (_picked.isEmpty) return showToast(context, '근로자를 한 명 이상 골라 주세요');
    if (_overlaps(store, store.store.parts[_part].name, _edit || !_repeat ? 1 : 4)) return;
    if (_edit) {
      store.updateShift(widget.shift!.id,
          staffId: _picked.first,
          date: _date,
          startMin: _start,
          endMin: _end,
          part: store.store.parts[_part].name);
      Navigator.pop(context);
      return showToast(context, '근무를 수정했어요');
    }
    final needs = [for (final p in store.store.parts) p.need];
    needs[_part] = _need;
    store.applyTemplate(needs: needs);
    final created = store.addShift(
      date: _date,
      startMin: _start,
      endMin: _end,
      part: store.store.parts[_part].name,
      staffIds: _picked.toList(),
      repeatWeeks: _repeat ? 4 : 1,
    );
    Navigator.pop(context);
    showToast(context, '근무 ${created.length}건을 등록했어요');
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final parts = store.store.parts;
    return Scaffold(
      appBar: AppHeader(_edit ? '근무 수정' : '근무 추가'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        children: [
          LabeledField('날짜', child: FieldBox('${dotDate(_date)} (${weekday(_date)})', onTap: _pickDate)),
          const SizedBox(height: 16),
          LabeledField(
            '파트',
            child: SegmentedPicker(
              options: [for (final p in parts) p.name],
              selected: _part,
              onChanged: (i) => setState(() => _applyPart(i)),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: LabeledField('시작',
                    child: FieldBox(hm(_start), onTap: () async {
                      final m = await pickTime(context, _start);
                      if (m != null) setState(() => _start = m);
                    })),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: LabeledField('종료',
                    child: FieldBox(hm(_end), onTap: () async {
                      final m = await pickTime(context, _end);
                      if (m != null) setState(() => _end = m);
                    })),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LabeledField(
            '근로자',
            child: Wrap(
              spacing: 12,
              runSpacing: 10,
              children: [
                for (final s in store.activeStaff)
                  GestureDetector(
                    onTap: () => setState(() {
                      if (_edit) {
                        _picked
                          ..clear()
                          ..add(s.id);
                      } else {
                        _picked.contains(s.id) ? _picked.remove(s.id) : _picked.add(s.id);
                      }
                    }),
                    child: Column(children: [
                      _Avatar(s.id, selected: _picked.contains(s.id)),
                      const SizedBox(height: 4),
                      Text(store.personOf(s).name,
                          style: AppText.style(12, FontWeight.w500, AppColors.textSecondary)),
                    ]),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (!_edit) AppCard(
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                        child: Text('${parts[_part].name} 필요 인원',
                            style: AppText.style(15, FontWeight.w500))),
                    CountStepper(value: _need, onChanged: (v) => setState(() => _need = v)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text('매주 반복 (4주)', style: AppText.style(15, FontWeight.w500)),
                    ),
                    GestureDetector(
                      onTap: () => setState(() => _repeat = !_repeat),
                      child: AppToggle(_repeat),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomBar(children: [
        AppButton(_edit ? '수정 저장' : '근무 등록', onPressed: _submit),
        if (_edit)
          AppButton('근무 삭제', variant: AppButtonVariant.danger, onPressed: _delete),
      ]),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar(this.staffId, {required this.selected});

  final String staffId;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final s = store.staffById(staffId)!;
    final (fg, bg) = toneColors(s.tone);
    return LetterAvatar(store.personOf(s).letter, color: fg, background: bg, selected: selected);
  }
}
