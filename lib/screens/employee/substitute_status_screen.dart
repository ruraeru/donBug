import 'package:flutter/material.dart';

import '../../theme.dart';
import '../../widgets/common.dart';
import 'employee_parts.dart';
import 'employee_widgets.dart';
import 'substitute_detail_screen.dart';

/// 대타 요청 현황: 내 요청 / 지원 가능 세그먼트.
class SubstituteStatusScreen extends StatefulWidget {
  const SubstituteStatusScreen({super.key});

  @override
  State<SubstituteStatusScreen> createState() => _SubstituteStatusScreenState();
}

class _SubstituteStatusScreenState extends State<SubstituteStatusScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: const AppHeader('대타'),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Expanded(child: _segment(0, '내 요청')),
                  const SizedBox(width: 4),
                  Expanded(child: _segment(1, '지원 가능')),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (_tab == 0) _myRequest(context) else _available(context),
          ],
        ),
      );

  Widget _segment(int i, String label) {
    final selected = _tab == i;
    return Material(
      color: selected ? AppColors.primary : Colors.transparent,
      borderRadius: BorderRadius.circular(11),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => setState(() => _tab = i),
        child: SizedBox(
          height: 40,
          child: Center(
            child: Text(
              label,
              style: AppText.style(14, FontWeight.w700,
                  selected ? AppColors.onPrimary : AppColors.textTertiary),
            ),
          ),
        ),
      ),
    );
  }

  Widget _myRequest(BuildContext context) => AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('5/16(금) 10:00–16:00',
                      style: AppText.style(17, FontWeight.w700)),
                ),
                const Pill.accent('지원 1명'),
              ],
            ),
            const SizedBox(height: 16),
            Text('사유: 병원 진료',
                style: AppText.style(13, FontWeight.w400, AppColors.textSecondary)),
            const SizedBox(height: 16),
            const StepRow(StepStatus.done, '요청 전송', '방금 전'),
            const SizedBox(height: 16),
            const StepRow(StepStatus.current, '동료 지원', '하윤님이 지원했어요'),
            const SizedBox(height: 16),
            const StepRow(StepStatus.pending, '사장님 승인', '대기'),
            const SizedBox(height: 16),
            const StepRow(StepStatus.pending, '근무표 반영', '승인 후 자동 반영'),
            const SizedBox(height: 16),
            Material(
              color: kDangerSoft,
              borderRadius: BorderRadius.circular(14),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => Navigator.pop(context),
                child: SizedBox(
                  height: 54,
                  width: double.infinity,
                  child: Center(
                    child: Text('요청 취소',
                        style: AppText.style(16, FontWeight.w700, kDanger)),
                  ),
                ),
              ),
            ),
          ],
        ),
      );

  // shortcut: Figma has no 지원 가능 frame here; one card linking to 대타 상세.
  Widget _available(BuildContext context) => AvatarRow(
        avatar: const LetterAvatar('수',
            color: AppColors.accent, background: AppColors.accentSoft),
        title: '5/14(수) 18:00 – 22:00',
        subtitle: '수빈님의 요청 · 병원 진료',
        trailing: const Pill.accent('대타 구해요'),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SubstituteDetailScreen()),
        ),
      );
}
