import 'package:flutter/material.dart';

import '../../theme.dart';
import '../../widgets/common.dart';
import '../employer/store_create_screen.dart';
import 'store_code_screen.dart';

/// 역할 선택: 알바생 → 매장 코드 입력, 사장님 → 매장 생성.
class RoleSelectScreen extends StatefulWidget {
  const RoleSelectScreen({super.key});

  @override
  State<RoleSelectScreen> createState() => _RoleSelectScreenState();
}

class _RoleSelectScreenState extends State<RoleSelectScreen> {
  bool _employee = true;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: const AppHeader('역할 선택'),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          children: [
            Text('어떤 역할로 사용하시나요?',
                style: AppText.style(22, FontWeight.w500)),
            const SizedBox(height: 16),
            Text('나중에 설정에서 바꿀 수 없으니 신중히 골라주세요',
                style:
                    AppText.style(14, FontWeight.w400, AppColors.textSecondary)),
            const SizedBox(height: 16),
            _RoleCard(
              letter: '알',
              title: '알바생이에요',
              caption: '근무표 · 출퇴근 · 급여를 확인해요',
              selected: _employee,
              onTap: () => setState(() => _employee = true),
            ),
            const SizedBox(height: 16),
            _RoleCard(
              letter: '사',
              title: '사장님이에요',
              caption: '매장 · 직원 · 인건비를 관리해요',
              selected: !_employee,
              onTap: () => setState(() => _employee = false),
            ),
          ],
        ),
        bottomNavigationBar: BottomBar(
          child: AppButton(
            '다음',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => _employee
                    ? const StoreCodeScreen()
                    : const StoreCreateScreen(),
              ),
            ),
          ),
        ),
      );
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.letter,
    required this.title,
    required this.caption,
    required this.selected,
    required this.onTap,
  });

  final String letter;
  final String title;
  final String caption;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: selected
              ? const BorderSide(color: AppColors.primary, width: 2)
              : const BorderSide(color: AppColors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected ? AppColors.primarySoft : AppColors.bg,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    letter,
                    style: AppText.style(24, FontWeight.w500,
                        selected ? AppColors.primary : AppColors.textTertiary),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: AppText.style(17, FontWeight.w500)),
                      const SizedBox(height: 2),
                      Text(caption,
                          style: AppText.style(
                              13, FontWeight.w400, AppColors.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}
