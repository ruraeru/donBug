import 'package:flutter/material.dart';

import '../../theme.dart';
import '../../widgets/common.dart';
import 'employer_flow_widgets.dart';
import 'employer_widgets.dart';

/// 근무표 템플릿 · 필요 인원 (Figma 47:355).
class ScheduleTemplateScreen extends StatefulWidget {
  const ScheduleTemplateScreen({super.key});

  @override
  State<ScheduleTemplateScreen> createState() => _ScheduleTemplateScreenState();
}

class _ScheduleTemplateScreenState extends State<ScheduleTemplateScreen> {
  static const _parts = ['오픈', '미들', '마감'];
  static const _templates = ['지난주 근무표 복사', '평일 기본 템플릿', '주말 기본 템플릿'];

  final _need = [2, 2, 2];
  int _template = 0;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: const AppHeader('템플릿 · 필요 인원'),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          children: [
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('파트별 필요 인원',
                      style: AppText.style(
                          14, FontWeight.w700, AppColors.textSecondary)),
                  for (var i = 0; i < _parts.length; i++) ...[
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                            child: Text(_parts[i],
                                style: AppText.style(15, FontWeight.w500))),
                        CountStepper(
                          value: _need[i],
                          onChanged: (v) => setState(() => _need[i] = v),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),
            LabeledField(
              '템플릿 복사',
              child: Column(
                children: [
                  for (var i = 0; i < _templates.length; i++) ...[
                    if (i > 0) const SizedBox(height: 8),
                    _option(i),
                  ],
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: BottomBar(children: [
          AppButton('이번 주에 적용', onPressed: () => Navigator.pop(context)),
        ]),
      );

  Widget _option(int i) {
    final on = i == _template;
    return GestureDetector(
      onTap: () => setState(() => _template = i),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: on ? AppColors.primary : AppColors.border,
            width: on ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(_templates[i],
                  style: AppText.style(15, on ? FontWeight.w700 : FontWeight.w400)),
            ),
            if (on)
              Text('✓', style: AppText.style(16, FontWeight.w700, AppColors.primary)),
          ],
        ),
      ),
    );
  }
}
