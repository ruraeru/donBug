import 'package:flutter/material.dart';

import '../../data/app_scope.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import 'employer_parts.dart';

/// 근무표 템플릿 · 필요 인원 (Figma 47:355).
class ScheduleTemplateScreen extends StatefulWidget {
  const ScheduleTemplateScreen({super.key});

  @override
  State<ScheduleTemplateScreen> createState() => _ScheduleTemplateScreenState();
}

class _ScheduleTemplateScreenState extends State<ScheduleTemplateScreen> {
  static const _options = [
    ('지난주 근무표 복사', '이번 주에 없는 근무만 지난주 그대로 채워요'),
    ('필요 인원만 저장', '근무는 그대로 두고 파트별 필요 인원만 바꿔요'),
  ];

  late final List<int> _need = [for (final p in AppScope.read(context).store.parts) p.need];
  int _template = 0;

  void _apply() {
    final copied = AppScope.read(context)
        .applyTemplate(needs: _need, copyLastWeek: _template == 0);
    Navigator.pop(context);
    showToast(context, _template == 0 ? '지난주 근무 $copied건을 복사했어요' : '필요 인원을 저장했어요');
  }

  @override
  Widget build(BuildContext context) {
    final parts = AppScope.of(context).store.parts;
    return Scaffold(
      appBar: const AppHeader('템플릿 · 필요 인원'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('파트별 필요 인원',
                    style: AppText.style(14, FontWeight.w500, AppColors.textSecondary)),
                for (var i = 0; i < parts.length; i++) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: Text(parts[i].name, style: AppText.style(15, FontWeight.w500))),
                      CountStepper(value: _need[i], onChanged: (v) => setState(() => _need[i] = v)),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          LabeledField(
            '이번 주 적용 방식',
            child: Column(
              children: [
                for (var i = 0; i < _options.length; i++) ...[
                  if (i > 0) const SizedBox(height: 8),
                  _option(i),
                ],
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomBar(children: [AppButton('이번 주에 적용', onPressed: _apply)]),
    );
  }

  Widget _option(int i) {
    final on = i == _template;
    return GestureDetector(
      onTap: () => setState(() => _template = i),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: on ? AppColors.primary : AppColors.border, width: on ? 2 : 1),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_options[i].$1, style: AppText.style(15, on ? FontWeight.w500 : FontWeight.w400)),
                  Text(_options[i].$2,
                      style: AppText.style(12, FontWeight.w400, AppColors.textSecondary)),
                ],
              ),
            ),
            if (on) const Icon(Icons.check_rounded, size: 20, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}
