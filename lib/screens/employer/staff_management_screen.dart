import 'package:flutter/material.dart';

import '../../theme.dart';
import '../../widgets/common.dart';
import 'employer_widgets.dart';
import 'staff_detail_screen.dart';

/// 직원 관리.
class StaffManagementScreen extends StatelessWidget {
  const StaffManagementScreen({super.key});

  static const _staff = [
    ('지', '지민', '오픈 · 10,030원', AppColors.primary, AppColors.primarySoft),
    ('수', '수빈', '오픈 · 10,030원', AppColors.accent, AppColors.accentSoft),
    ('하', '하윤', '마감 · 10,030원', EmpColors.info, EmpColors.infoSoft),
    ('태', '태우', '미들 · 10,030원', AppColors.primary, AppColors.primarySoft),
    ('서', '서연', '미들 · 10,500원', EmpColors.danger, EmpColors.dangerSoft),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppHeader('직원 관리', actions: [
          TextButton(
            onPressed: () {},
            child: Text('+ 초대',
                style: AppText.style(14, FontWeight.w700, AppColors.primary)),
          ),
          const SizedBox(width: 8),
        ]),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          children: [
            const Row(
              children: [
                Expanded(
                  child: _Stat('재직', '5',
                      background: AppColors.primarySoft,
                      labelColor: AppColors.primary),
                ),
                SizedBox(width: 8),
                Expanded(child: _Stat('신규 승인 대기', '0')),
              ],
            ),
            for (final (initial, name, sub, fg, bg) in _staff) ...[
              const SizedBox(height: 10),
              PersonRow(
                avatar: InitialAvatar(initial, color: fg, background: bg),
                title: name,
                subtitle: sub,
                trailing: Text('›',
                    style: AppText.style(
                        22, FontWeight.w400, AppColors.textTertiary)),
                // shortcut: 상세는 수빈 더미 고정, 실데이터 연결 시 직원 넘기기.
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const StaffDetailScreen())),
              ),
            ],
          ],
        ),
      );
}

class _Stat extends StatelessWidget {
  const _Stat(
    this.label,
    this.value, {
    this.background = AppColors.surface,
    this.labelColor = AppColors.textSecondary,
  });

  final String label;
  final String value;
  final Color background;
  final Color labelColor;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(label, style: AppText.style(12, FontWeight.w400, labelColor)),
            const SizedBox(height: 2),
            Text(value, style: AppText.style(22, FontWeight.w700)),
          ],
        ),
      );
}
