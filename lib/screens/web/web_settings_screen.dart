import 'package:flutter/material.dart';

import '../../data/api_client.dart';
import '../../data/app_scope.dart';
import '../../data/format.dart';
import '../../data/models.dart';
import '../../data/payroll.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import 'web_common.dart';

const _day = 1440;

/// 법정 휴게: 4시간마다 30분 (레퍼런스 partBreakFor).
int partBreakFor(int durationMin) => durationMin ~/ 240 * 30;

/// 0 → '00:00', 1440 → '24:00' (파트 끝은 24:00 까지 고른다).
String _t(int m) => '${(m ~/ 60).toString().padLeft(2, '0')}:${(m % 60).toString().padLeft(2, '0')}';

/// 파트 한 줄의 편집 값. 저장할 때 [PartTemplate] 으로 바꾼다.
class PartRow {
  PartRow(this.uid, this.id, this.name, this.tone, this.startMin, this.endMin, this.breakMin, this.need);

  /// 목록 안에서 줄을 구분하는 값(서버 id 와 별개, 새 줄도 가진다).
  final int uid;

  /// 서버 id. 새 파트는 ''.
  final String id;
  String name;
  PartTone tone;
  int startMin, endMin, breakMin, need;

  PartRow copy() => PartRow(uid, id, name, tone, startMin, endMin, breakMin, need);

  @override
  bool operator ==(Object other) =>
      other is PartRow &&
      other.id == id &&
      other.name == name &&
      other.tone == tone &&
      other.startMin == startMin &&
      other.endMin == endMin &&
      other.breakMin == breakMin &&
      other.need == need;

  @override
  int get hashCode => Object.hash(id, name, tone, startMin, endMin, breakMin, need);
}

/// 저장을 막는 이유. 없으면 null. 문구는 레퍼런스 Settings.tsx 와 같다.
String? settingsError({
  required int openMin,
  required int closeMin,
  required int weekendOpenMin,
  required int weekendCloseMin,
  required List<PartRow> parts,
}) {
  if (openMin >= closeMin) return '평일 영업 종료 시각은 시작 시각보다 늦어야 합니다.';
  if (weekendOpenMin >= weekendCloseMin) return '주말·공휴일 영업 종료 시각은 시작 시각보다 늦어야 합니다.';
  if (closeMin - openMin > _day || weekendCloseMin - weekendOpenMin > _day) {
    return '영업시간은 24시간을 넘을 수 없습니다.';
  }
  for (final p in parts) {
    if (p.name.trim().isEmpty) return '파트 이름을 입력하세요.';
    if (p.startMin >= p.endMin) return '${p.name} 종료 시각은 시작 시각보다 늦어야 합니다.';
  }
  return null;
}

/// 새 파트: 마지막 파트 끝(없거나 마감 이후면 영업 시작)부터 4시간, 색은 돌려 쓴다.
PartRow newPartRow(int uid, List<PartRow> parts, int openMin, int closeMin) {
  final sorted = [...parts]..sort((a, b) => a.startMin.compareTo(b.startMin));
  final last = sorted.isEmpty ? null : sorted.last;
  // 파트 시각은 24:00 까지만 고를 수 있어 익일 마감이어도 자정에서 자른다.
  final close = closeMin < _day ? closeMin : _day;
  final start = last != null && last.endMin < close ? last.endMin : openMin;
  final end = (start + 240) < close ? start + 240 : close;
  return PartRow(uid, '', '새 파트', PartTone.values[parts.length % PartTone.values.length], start,
      end, partBreakFor(end - start), 1);
}

Color toneColor(PartTone t) => switch (t) {
      PartTone.open => AppColors.primary,
      PartTone.middle => AppColors.info,
      PartTone.close => AppColors.accent,
    };

/// 매장 설정 (레퍼런스 pages/Settings.tsx): 기본 정보 · 영업시간 · 사업장 규모 · 알바생 근무 파트 · 기존 설정.
class WebSettingsScreen extends StatefulWidget {
  const WebSettingsScreen({super.key});

  @override
  State<WebSettingsScreen> createState() => _WebSettingsScreenState();
}

class _WebSettingsScreenState extends State<WebSettingsScreen> {
  late String _name;
  late int _open, _close, _wOpen, _wClose;
  late SizeMode _sizeMode;
  late bool _notice, _push;
  late Deduction _deduction;
  late List<PartRow> _parts;
  late List<PartRow> _savedParts;
  int _uid = 0;

  /// 되돌리기·저장 때 입력 칸을 새로 그리려고 키에 섞는다.
  int _gen = 0;
  bool _saving = false;
  String? _serverError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final s = AppScope.read(context).store;
    _name = s.name;
    _open = s.openMin;
    _close = s.closeMin;
    _wOpen = s.weekendOpenMin;
    _wClose = s.weekendCloseMin;
    _sizeMode = s.sizeMode;
    _notice = s.noticeRequiredDefault;
    _push = s.substitutePush;
    _deduction = s.defaultDeduction;
    _savedParts = [
      for (final p in s.parts)
        PartRow(_uid++, p.id, p.name, p.tone, p.startMin, p.endMin, p.breakMin, p.need)
    ];
    _parts = [for (final p in _savedParts) p.copy()];
    _gen++;
  }

  bool _dirty(Store s) =>
      _name != s.name ||
      _open != s.openMin ||
      _close != s.closeMin ||
      _wOpen != s.weekendOpenMin ||
      _wClose != s.weekendCloseMin ||
      _sizeMode != s.sizeMode ||
      _notice != s.noticeRequiredDefault ||
      _push != s.substitutePush ||
      _deduction != s.defaultDeduction ||
      _parts.length != _savedParts.length ||
      [for (var i = 0; i < _parts.length; i++) _parts[i] != _savedParts[i]].contains(true);

  String? get _error => settingsError(
      openMin: _open,
      closeMin: _close,
      weekendOpenMin: _wOpen,
      weekendCloseMin: _wClose,
      parts: _parts);

  void _setPart(PartRow p, {String? name, int? start, int? end, int? breakMin, int? need}) {
    setState(() {
      if (name != null) p.name = name;
      if (need != null) p.need = need;
      if (breakMin != null) p.breakMin = breakMin;
      if (start != null || end != null) {
        p.startMin = start ?? p.startMin;
        p.endMin = end ?? p.endMin;
        // 시간을 바꾸면 휴게를 4시간당 30분으로 다시 잡는다. 휴게만 고치면 그대로 둔다.
        p.breakMin = partBreakFor(p.endMin - p.startMin).clamp(0, 120);
      }
    });
  }

  Future<void> _removePart(PartRow p) async {
    if (p.id.isNotEmpty) {
      final ok = await showConfirmDialog(context,
          title: '${p.name} 파트를 지울까요?',
          message: '저장하면 이 파트로 잡힌 근무는 파트 없는 근무로 바뀌고, 직원의 고정 근무 파트에서도 빠져요.',
          confirmLabel: '지우기',
          confirmVariant: AppButtonVariant.danger);
      if (!ok || !mounted) return;
    }
    setState(() => _parts.remove(p));
  }

  Future<void> _pickSize(SizeMode mode) async {
    if (mode == SizeMode.auto) return setState(() => _sizeMode = mode);
    final label = mode == SizeMode.under5 ? '5인 미만' : '5인 이상';
    final ok = await showConfirmDialog(context,
        title: '사업장 규모를 직접 정할까요?',
        message: '$label 사업장으로 고정합니다. 연장·야간 가산수당 및 주 52시간 제한 규칙이 변경됩니다.\n'
            '구성원 수가 바뀌어도 자동으로 갱신되지 않습니다. 저장해야 반영됩니다.',
        confirmLabel: '$label으로 적용');
    if (ok && mounted) setState(() => _sizeMode = mode);
  }

  Future<void> _save() async {
    final store = AppScope.read(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() {
      _saving = true;
      _serverError = null;
    });
    try {
      await store.updateStoreSettings(
        name: _name.trim().isEmpty ? '내 매장' : _name.trim(),
        openMin: _open,
        closeMin: _close,
        weekendOpenMin: _wOpen,
        weekendCloseMin: _wClose,
        sizeMode: _sizeMode,
        noticeRequiredDefault: _notice,
        substitutePush: _push,
        defaultDeduction: _deduction,
      );
      await store.saveParts([for (final p in _parts) _toPart(p)]);
      if (!mounted) return;
      setState(_load);
      showToastOn(messenger, '매장 설정을 저장했어요');
    } on ApiException catch (e) {
      if (mounted) setState(() => _serverError = e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  PartTemplate _toPart(PartRow p) => PartTemplate(p.name.trim(), p.startMin, p.endMin, p.need,
      id: p.id, tone: p.tone, breakMin: p.breakMin);

  Widget _card(String title, {String? sub, Widget? trailing, required Widget child}) => AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: AppText.style(16, FontWeight.w500)),
                if (sub != null) ...[
                  const SizedBox(height: 4),
                  Text(sub, style: AppText.style(12, FontWeight.w400, AppColors.textSecondary)),
                ],
              ]),
            ),
            ?trailing,
          ]),
          const SizedBox(height: 16),
          child,
        ]),
      );

  Widget _hours(String label, int open, int close, void Function(int, int) set) {
    final next = close > _day;
    final shownEnd = next ? close - _day : close;
    return webField(
      '영업시간 · $label',
      Wrap(spacing: 8, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
        TimeRange(
            label: '$label 영업',
            start: open,
            end: shownEnd,
            onChanged: (a, b) => set(a, next ? b + _day : b)),
        Semantics(
          button: true,
          toggled: next,
          label: '$label 영업 종료 익일',
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            // 켜면 종료에 24시간을 더한다. 24:00(자정)이면 익일 01:00 으로.
            onTap: () => set(open, next ? close - _day : (close % _day) + _day < _day + 60 ? _day + 60 : (close % _day) + _day),
            child: next
                ? const Pill('익일')
                : Pill('익일', color: AppColors.textSecondary, background: AppColors.bg),
          ),
        ),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final s = store.store;
    final dirty = _dirty(s);
    final error = _error;
    final shownError = error ?? _serverError;
    final activeCount = store.activeStaff.length;
    final autoSmall = activeCount < 5;
    final small = switch (_sizeMode) {
      SizeMode.auto => autoSmall,
      SizeMode.under5 => true,
      SizeMode.over5 => false,
    };
    return WebPage(
      title: '매장 설정',
      subtitle: s.name,
      actions: [
        WebButton('되돌리기',
            style: WebButtonStyle.outline,
            onPressed: dirty && !_saving ? () => setState(_load) : null),
        WebButton(_saving ? '저장 중…' : '저장',
            onPressed: dirty && error == null && !_saving ? _save : null),
      ],
      children: [
        if (shownError != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
                color: AppColors.dangerSoft, borderRadius: BorderRadius.circular(12)),
            child: Text(shownError, style: AppText.style(14, FontWeight.w400, AppColors.danger)),
          ),
        _card('기본 정보',
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              webField(
                  '매장 이름',
                  TextFormField(
                    key: ValueKey('name$_gen'),
                    initialValue: _name,
                    onChanged: (v) => setState(() => _name = v),
                    decoration: _inputDeco('내 매장'),
                    style: AppText.style(15),
                  )),
              const SizedBox(height: 16),
              Wrap(spacing: 24, runSpacing: 16, children: [
                _hours('평일', _open, _close, (a, b) => setState(() {
                      _open = a;
                      _close = b;
                    })),
                _hours('주말·공휴일', _wOpen, _wClose, (a, b) => setState(() {
                      _wOpen = a;
                      _wClose = b;
                    })),
              ]),
              const SizedBox(height: 16),
              webField(
                '사업장 규모',
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: WebSegmented(
                      labels: const ['자동 판정 (권장)', '5인 이상 강제 적용', '5인 미만 강제 적용'],
                      selected: switch (_sizeMode) {
                        SizeMode.auto => 0,
                        SizeMode.over5 => 1,
                        SizeMode.under5 => 2,
                      },
                      onChanged: (i) => _pickSize(
                          const [SizeMode.auto, SizeMode.over5, SizeMode.under5][i]),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(spacing: 8, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [
                    Pill('${_sizeMode == SizeMode.auto ? '자동 산정 중' : '수동 설정'}: '
                        '${small ? '5인 미만' : '5인 이상'} 사업장 적용'),
                    Text(
                        '${_sizeMode == SizeMode.auto ? '등록 구성원 $activeCount명 기준으로 자동 갱신' : ''}'
                        '${small ? ' · 연장·야간 가산 없음' : ' · 연장·야간 가산, 주 52시간 적용'}',
                        style: AppText.style(12, FontWeight.w400, AppColors.textSecondary)),
                  ]),
                ]),
              ),
              const SizedBox(height: 16),
              webField('최저시급', Text('${wonText(minimumWage2026)} (2026년)', style: AppText.style(15))),
            ])),
        _card(
          '알바생 근무 파트',
          sub: '시작 시각 순으로 보여줍니다. 휴게시간은 근무 4시간마다 30분으로 자동 설정되며, 직접 고칠 수 있습니다.',
          trailing: WebButton('+ 파트 추가',
              height: 36,
              style: WebButtonStyle.outline,
              onPressed: () => setState(() => _parts.add(newPartRow(_uid++, _parts, _open, _close)))),
          child: Column(children: [
            if (_parts.isEmpty) const EmptyNote('파트가 없어요. 파트를 추가하세요.'),
            for (final p in ([..._parts]..sort((a, b) => a.startMin.compareTo(b.startMin))))
              _partRow(p),
          ]),
        ),
        _card('알림·공제',
            child: Column(children: [
              ToggleCard(
                flat: true,
                title: '공지 필독 기본',
                subtitle: '새 공지를 올릴 때 필독을 기본으로 켜요',
                value: _notice,
                onChanged: (v) => setState(() => _notice = v),
              ),
              ToggleCard(
                flat: true,
                title: '대타 알림',
                subtitle: '대타 요청이 오면 알림을 보내요',
                value: _push,
                onChanged: (v) => setState(() => _push = v),
              ),
              const SizedBox(height: 12),
              webField(
                  '기본 공제',
                  WebSelect<Deduction>(
                    value: _deduction,
                    items: [for (final d in Deduction.values) (d, d.label)],
                    onChanged: (d) => setState(() => _deduction = d),
                  ),
                  help: '직원 가입 승인 때 기본으로 고르는 공제예요'),
            ])),
      ],
    );
  }

  InputDecoration _inputDeco(String hint) => InputDecoration(
        isDense: true,
        hintText: hint,
        hintStyle: AppText.style(15, FontWeight.w400, AppColors.textTertiary),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary)),
      );

  Widget _partRow(PartRow p) => Container(
        key: ValueKey('part${p.uid}'),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.border))),
        child: Wrap(spacing: 12, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
          Row(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 12,
              height: 28,
              decoration: BoxDecoration(
                  color: toneColor(p.tone).withValues(alpha: .25),
                  border: Border.all(color: toneColor(p.tone)),
                  borderRadius: BorderRadius.circular(6)),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 150,
              child: TextFormField(
                key: ValueKey('pn${p.uid}_$_gen'),
                initialValue: p.name,
                onChanged: (v) => _setPart(p, name: v),
                decoration: _inputDeco('파트 이름').copyWith(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10)),
                style: AppText.style(13),
              ),
            ),
          ]),
          TimeRange(
              label: p.name,
              start: p.startMin,
              end: p.endMin,
              onChanged: (a, b) => _setPart(p, start: a, end: b)),
          Row(mainAxisSize: MainAxisSize.min, children: [
            Text('휴게 ', style: AppText.style(12, FontWeight.w400, AppColors.textSecondary)),
            _MiniSelect<int>(
              label: '${p.name} 휴게',
              value: p.breakMin,
              items: [
                for (final m in {0, 30, 60, 90, 120, p.breakMin}.toList()..sort()) (m, '$m분')
              ],
              onChanged: (v) => _setPart(p, breakMin: v),
            ),
          ]),
          Row(mainAxisSize: MainAxisSize.min, children: [
            Text('필요 ', style: AppText.style(12, FontWeight.w400, AppColors.textSecondary)),
            SizedBox(
              width: 56,
              child: TextFormField(
                key: ValueKey('pneed${p.uid}_$_gen'),
                initialValue: '${p.need}',
                keyboardType: TextInputType.number,
                onChanged: (v) => _setPart(p, need: (int.tryParse(v) ?? 0).clamp(0, 99)),
                decoration: _inputDeco('').copyWith(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10)),
                style: AppText.style(13),
              ),
            ),
            Text(' 명', style: AppText.style(12, FontWeight.w400, AppColors.textSecondary)),
          ]),
          TextButton(
            onPressed: () => _removePart(p),
            child: Text('삭제', style: AppText.style(13, FontWeight.w500, AppColors.danger)),
          ),
        ]),
      );
}

/// 15분 단위 24시간제 시작–종료 선택 (0–24:00).
class TimeRange extends StatelessWidget {
  const TimeRange(
      {super.key, required this.label, required this.start, required this.end, required this.onChanged});

  final String label;
  final int start, end;
  final void Function(int start, int end) onChanged;

  @override
  Widget build(BuildContext context) => Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(10)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          _MiniSelect<int>(
              label: '$label 시작',
              value: start,
              items: _times,
              onChanged: (v) => onChanged(v, end)),
          Text('–', style: AppText.style(13, FontWeight.w400, AppColors.textTertiary)),
          _MiniSelect<int>(
              label: '$label 종료',
              value: end,
              items: _times,
              onChanged: (v) => onChanged(start, v)),
        ]),
      );
}

final List<(int, String)> _times = [for (var m = 0; m <= _day; m += 15) (m, _t(m))];

class _MiniSelect<T> extends StatelessWidget {
  const _MiniSelect(
      {required this.label, required this.value, required this.items, required this.onChanged});

  final String label;
  final T value;
  final List<(T, String)> items;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) => Semantics(
        label: label,
        child: DropdownButtonHideUnderline(
          child: DropdownButton<T>(
            value: value,
            isDense: true,
            borderRadius: BorderRadius.circular(10),
            dropdownColor: AppColors.surface,
            style: DefaultTextStyle.of(context)
                .style
                .merge(AppText.style(13, FontWeight.w400, AppColors.textPrimary)),
            items: [
              for (final (v, l) in items) DropdownMenuItem<T>(value: v, child: Text(l)),
            ],
            onChanged: (v) => v == null ? null : onChanged(v),
          ),
        ),
      );
}
