import 'package:flutter/material.dart';

import '../../theme.dart';
import '../../widgets/common.dart';
import 'employer_flow_widgets.dart';
import 'employer_widgets.dart';
import 'schedule_template_screen.dart';

/// 근무 추가 (Figma 47:297).
class ShiftAddScreen extends StatefulWidget {
  const ShiftAddScreen({super.key});

  @override
  State<ShiftAddScreen> createState() => _ShiftAddScreenState();
}

class _ShiftAddScreenState extends State<ShiftAddScreen> {
  static const _staff = [
    (initial: '태', color: AppColors.primary, bg: AppColors.primarySoft),
    (initial: '서', color: EmpColors.info, bg: EmpColors.infoSoft),
    (initial: '하', color: AppColors.accent, bg: AppColors.accentSoft),
  ];

  int _part = 1;
  final Set<int> _picked = {0, 1};
  int _need = 2;
  bool _repeat = true;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: const AppHeader('근무 추가'),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          children: [
            const LabeledField('날짜', child: FieldBox('2026.05.14 (수)')),
            const SizedBox(height: 14),
            LabeledField(
              '파트',
              child: SegmentedPicker(
                options: const ['오픈', '미들', '마감'],
                selected: _part,
                onChanged: (i) => setState(() => _part = i),
              ),
            ),
            const SizedBox(height: 14),
            const Row(
              children: [
                Expanded(child: LabeledField('시작', child: FieldBox('14:00'))),
                SizedBox(width: 12),
                Expanded(child: LabeledField('종료', child: FieldBox('20:00'))),
              ],
            ),
            const SizedBox(height: 14),
            LabeledField(
              '근로자',
              child: Row(
                children: [
                  for (var i = 0; i < _staff.length; i++) ...[
                    if (i > 0) const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () => setState(() =>
                          _picked.contains(i) ? _picked.remove(i) : _picked.add(i)),
                      child: Avatar(
                        _staff[i].initial,
                        color: _staff[i].color,
                        background: _staff[i].bg,
                        selected: _picked.contains(i),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),
            AppCard(
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                          child: Text('필요 인원',
                              style: AppText.style(15, FontWeight.w500))),
                      CountStepper(
                          value: _need,
                          onChanged: (v) => setState(() => _need = v)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                          child: Text('매주 반복',
                              style: AppText.style(15, FontWeight.w500))),
                      Switch(
                        value: _repeat,
                        activeTrackColor: AppColors.primary,
                        activeThumbColor: AppColors.onPrimary,
                        onChanged: (v) => setState(() => _repeat = v),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: BottomBar(children: [
          // Figma 프로토타입: 근무 등록 → 근무표 템플릿.
          AppButton(
            '근무 등록',
            onPressed: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const ScheduleTemplateScreen()),
            ),
          ),
        ]),
      );
}
