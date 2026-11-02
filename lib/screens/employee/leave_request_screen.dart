import 'package:flutter/material.dart';

import '../../theme.dart';
import '../../widgets/common.dart';
import 'employee_parts.dart';
import 'employee_widgets.dart';
import 'substitute_done_screen.dart';

/// A4 휴무·대타 신청.
class LeaveRequestScreen extends StatefulWidget {
  const LeaveRequestScreen({super.key});

  @override
  State<LeaveRequestScreen> createState() => _LeaveRequestScreenState();
}

class _LeaveRequestScreenState extends State<LeaveRequestScreen> {
  final _reason = TextEditingController(
      text: '치과 진료 예약이 있어서 근무가 어려워요. 대타 구해지면 알려주세요.');
  bool _notify = true;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final label = AppText.style(14, FontWeight.w700, AppColors.textSecondary);
    return Scaffold(
      appBar: const AppHeader('휴무 신청'),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        children: [
          Text('휴무할 근무', style: label),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              border: Border.all(color: AppColors.primary),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('5/16(금) 10:00 – 16:00',
                          style: AppText.style(16, FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text('주방 · 6시간',
                          style: AppText.style(
                              12, FontWeight.w400, AppColors.textSecondary)),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                const AppIcon('check', size: 22),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text('사유', style: label),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                TextField(
                  controller: _reason,
                  maxLines: null,
                  maxLength: 200,
                  style: AppText.style(15),
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration.collapsed(hintText: '사유를 입력해 주세요')
                      .copyWith(counterText: ''),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text('${_reason.text.length} / 200',
                      style: AppText.style(12, FontWeight.w400, AppColors.textTertiary)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppCard(
            radius: 16,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('동료에게 대타 알림 보내기',
                          style: AppText.style(15, FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text('같은 매장 근로자 5명에게 전송',
                          style: AppText.style(
                              12, FontWeight.w400, AppColors.textSecondary)),
                    ],
                  ),
                ),
                Switch(
                  value: _notify,
                  activeTrackColor: AppColors.primary,
                  onChanged: (v) => setState(() => _notify = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const NoteBox('신청하면 사장님께도 알림이 가요. 대타가 확정되면 근무표가 자동으로 바뀝니다.',
              color: kInfo, background: kInfoSoft),
        ],
      ),
      bottomNavigationBar: BottomBar(
        child: AppButton(
          '휴무 신청하고 대타 구하기',
          onPressed: () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => const SubstituteDoneScreen(SubstituteDoneKind.request),
            ),
          ),
        ),
      ),
    );
  }
}
