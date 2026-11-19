import 'package:flutter/material.dart';

import '../../data/api_client.dart';
import '../../data/app_scope.dart';
import '../../data/app_store.dart';
import '../../data/format.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import 'employer_parts.dart';

/// 매장 정보 수정 (사장님 앱): 이름 · 주소 · 평일/주말·공휴일 영업시간.
class StoreInfoEditScreen extends StatefulWidget {
  const StoreInfoEditScreen({super.key});

  @override
  State<StoreInfoEditScreen> createState() => _StoreInfoEditScreenState();
}

class _StoreInfoEditScreenState extends State<StoreInfoEditScreen> {
  late final TextEditingController _name;
  late final TextEditingController _address;
  late int _open, _close, _wOpen, _wClose;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final s = AppScope.read(context).store;
    _name = TextEditingController(text: s.name);
    _address = TextEditingController(text: s.address);
    _open = s.openMin;
    _close = s.closeMin;
    _wOpen = s.weekendOpenMin;
    _wClose = s.weekendCloseMin;
  }

  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
    super.dispose();
  }

  /// 종료 시각이 시작보다 이르거나 같으면 익일 마감(+24시간)으로 본다.
  static int _closeAfter(int open, int closeClock) => closeClock <= open ? closeClock + 1440 : closeClock;

  static String _closeLabel(int m) => m > 1440 ? '익일 ${hm(m)}' : m == 1440 ? '24:00' : hm(m);

  Future<void> _pick(bool weekend, bool end) async {
    final open = weekend ? _wOpen : _open;
    final close = weekend ? _wClose : _close;
    final t = await pickTime(context, end ? close : open);
    if (t == null || !mounted) return;
    setState(() {
      final o = end ? open : t;
      final c = _closeAfter(o, end ? t : close % 1440);
      if (weekend) {
        _wOpen = o;
        _wClose = c;
      } else {
        _open = o;
        _close = c;
      }
    });
  }

  Future<void> _save() async {
    final store = AppScope.read(context);
    final s = store.store;
    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final name = _name.text.trim();
    final address = _address.text.trim();
    setState(() => _saving = true);
    try {
      await store.updateStoreSettings(
        name: name != s.name ? name : null,
        address: address != s.address ? address : null,
        openMin: _open != s.openMin ? _open : null,
        closeMin: _close != s.closeMin ? _close : null,
        weekendOpenMin: _wOpen != s.weekendOpenMin ? _wOpen : null,
        weekendCloseMin: _wClose != s.weekendCloseMin ? _wClose : null,
      );
      if (!mounted) return;
      nav.pop();
      showToastOn(messenger, '매장 정보를 저장했어요');
    } on ApiException catch (e) {
      if (mounted) showToast(context, e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _hours(String label, bool weekend, int open, int close) => LabeledField(
        label,
        child: Row(children: [
          Expanded(child: FieldBox(hm(open), onTap: () => _pick(weekend, false))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text('–', style: AppText.style(15, FontWeight.w400, AppColors.textSecondary)),
          ),
          Expanded(child: FieldBox(_closeLabel(close), onTap: () => _pick(weekend, true))),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context).store;
    final name = _name.text.trim();
    final address = _address.text.trim();
    final changed = name != s.name ||
        address != s.address ||
        _open != s.openMin ||
        _close != s.closeMin ||
        _wOpen != s.weekendOpenMin ||
        _wClose != s.weekendCloseMin;
    final error = name.isEmpty
        ? '매장 이름을 입력해 주세요'
        : address.isEmpty
            ? '주소를 입력해 주세요'
            : AppStore.validateHours(_open, _close, _wOpen, _wClose);
    final canSave = changed && error == null && !_saving;
    return Scaffold(
      appBar: const AppHeader('매장 정보 수정'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        children: [
          LabeledField('매장 이름',
              child: AppTextField(
                  controller: _name, hint: '매장 이름', maxLength: 100, onChanged: (_) => setState(() {}))),
          const SizedBox(height: 8),
          LabeledField('주소',
              child: AppTextField(
                  controller: _address, hint: '도로명 주소', maxLength: 255, onChanged: (_) => setState(() {}))),
          const SizedBox(height: 8),
          _hours('평일 영업시간', false, _open, _close),
          const SizedBox(height: 16),
          _hours('주말·공휴일 영업시간', true, _wOpen, _wClose),
          const SizedBox(height: 8),
          Text('종료 시각이 시작보다 이르면 다음 날(익일) 마감으로 저장해요.',
              style: AppText.style(12, FontWeight.w400, AppColors.textSecondary)),
          if (error != null) ...[
            const SizedBox(height: 12),
            Text(error, style: AppText.style(13, FontWeight.w400, AppColors.danger)),
          ],
        ],
      ),
      bottomNavigationBar: BottomBar(
        child: AppButton(_saving ? '저장 중…' : '저장',
            variant: canSave ? AppButtonVariant.primary : AppButtonVariant.soft,
            onPressed: canSave ? _save : null),
      ),
    );
  }
}
