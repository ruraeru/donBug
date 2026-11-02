import 'package:flutter/material.dart';

import '../../widgets/common.dart';
import 'employer_flow_widgets.dart';
import 'employer_widgets.dart';
import 'store_code_screen.dart';

/// 매장 만들기 (Figma 47:41).
class StoreCreateScreen extends StatefulWidget {
  const StoreCreateScreen({super.key});

  @override
  State<StoreCreateScreen> createState() => _StoreCreateScreenState();
}

class _StoreCreateScreenState extends State<StoreCreateScreen> {
  int _size = 0;
  int _deduction = 0;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: const AppHeader('매장 만들기'),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          children: [
            const LabeledField('상호명', child: FieldBox('카페 커푸치노')),
            const SizedBox(height: 14),
            const LabeledField('사업장 주소', child: FieldBox('서울특별시 마포구 와우산로 94')),
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
                options: const ['3.3%', '4대보험', '없음'],
                selected: _deduction,
                onChanged: (i) => setState(() => _deduction = i),
              ),
            ),
            const SizedBox(height: 14),
            const NoteBox(
              '5인 미만 사업장은 연차·가산수당 적용 기준이 달라요. 이 설정에 맞춰 급여가 계산돼요.',
              color: EmpColors.info,
              background: EmpColors.infoSoft,
            ),
          ],
        ),
        bottomNavigationBar: BottomBar(children: [
          AppButton(
            '매장 만들기',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const StoreCodeScreen()),
            ),
          ),
        ]),
      );
}
