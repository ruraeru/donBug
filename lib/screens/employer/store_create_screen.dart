import 'package:flutter/material.dart';

import '../../data/app_scope.dart';
import '../../data/models.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import 'employer_parts.dart';
import 'store_code_screen.dart';

/// 매장 만들기 (Figma 47:41). 데모 사장님은 매장이 하나라 그 매장 정보를 채워 둔다.
class StoreCreateScreen extends StatefulWidget {
  const StoreCreateScreen({super.key});

  @override
  State<StoreCreateScreen> createState() => _StoreCreateScreenState();
}

class _StoreCreateScreenState extends State<StoreCreateScreen> {
  late final TextEditingController _name;
  late final TextEditingController _address;
  late int _size;
  late int _deduction;

  @override
  void initState() {
    super.initState();
    final store = AppScope.read(context);
    final st = store.storeById(store.session.ownerStoreId)!;
    _name = TextEditingController(text: st.name);
    _address = TextEditingController(text: st.address);
    _size = st.isSmall ? 0 : 1;
    _deduction = st.defaultDeduction.index;
  }

  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
    super.dispose();
  }

  void _submit() {
    if (_name.text.trim().isEmpty || _address.text.trim().isEmpty) {
      return showToast(context, '상호명과 주소를 입력해 주세요');
    }
    AppScope.read(context).createStore(
      name: _name.text.trim(),
      address: _address.text.trim(),
      isSmall: _size == 0,
      deduction: Deduction.values[_deduction],
    );
    Navigator.push(context, MaterialPageRoute(builder: (_) => const StoreCodeScreen()));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: const AppHeader('매장 만들기'),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          children: [
            LabeledField('상호명', child: AppTextField(controller: _name, hint: '예: 카페 커푸치노')),
            const SizedBox(height: 14),
            LabeledField('사업장 주소', child: AppTextField(controller: _address, hint: '도로명 주소')),
            const SizedBox(height: 14),
            LabeledField(
              '상시 근로자 수',
              child: SegmentedPicker(
                options: const ['5인 미만', '5인 이상'],
                selected: _size,
                onChanged: (i) => setState(() => _size = i),
              ),
            ),
            const SizedBox(height: 14),
            LabeledField(
              '기본 급여 공제',
              child: SegmentedPicker(
                options: [for (final d in Deduction.values) d.short],
                selected: _deduction,
                onChanged: (i) => setState(() => _deduction = i),
              ),
            ),
            const SizedBox(height: 14),
            const NoteBox(
              '5인 미만 사업장은 연차·가산수당 적용 기준이 달라요. 이 설정에 맞춰 급여가 계산돼요.',
              color: AppColors.info,
              background: AppColors.infoSoft,
            ),
          ],
        ),
        bottomNavigationBar: BottomBar(children: [AppButton('매장 만들기', onPressed: _submit)]),
      );
}
