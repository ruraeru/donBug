import 'package:flutter/material.dart';

import '../../data/app_scope.dart';
import '../../data/format.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import 'staff_approval_screen.dart';
import 'staff_detail_screen.dart';
import 'store_code_screen.dart';

/// 직원 관리.
class StaffManagementScreen extends StatelessWidget {
  const StaffManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final staff = store.activeStaff;
    final pending = store.pendingStaff.length;
    return Scaffold(
      appBar: AppHeader('직원 관리', actions: [
        TextButton(
          onPressed: () => Navigator.push(
              context, MaterialPageRoute(builder: (_) => const StoreCodeScreen(invite: true))),
          child: Text('+ 초대', style: AppText.style(14, FontWeight.w500, AppColors.primary)),
        ),
        const SizedBox(width: 8),
      ]),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        children: [
          Row(
            children: [
              Expanded(
                child: _Stat('재직', '${staff.length}'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _Stat('신규 승인 대기', '$pending',
                    onTap: pending == 0
                        ? null
                        : () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) => const StaffApprovalScreen()))),
              ),
            ],
          ),
          for (final s in staff) ...[
            const SizedBox(height: 12),
            PersonRow(
              avatar: MemberAvatar(s),
              title: store.personOf(s).name,
              subtitle: '${s.part} · ${wonText(s.wage)}',
              trailing: const Icon(Icons.chevron_right_rounded, size: 24, color: AppColors.textTertiary),
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => StaffDetailScreen(staffId: s.id))),
            ),
          ],
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(
    this.label,
    this.value, {
    this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => AppCard(
        radius: 16,
        onTap: onTap,
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            Text(label, style: AppText.style(12, FontWeight.w400, AppColors.textSecondary)),
            const SizedBox(height: 2),
            Text(value, style: AppText.style(22, FontWeight.w500)),
          ],
        ),
      );
}
