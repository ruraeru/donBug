import 'package:flutter/material.dart';

import '../../data/app_scope.dart';
import '../../data/app_store.dart';
import '../../data/format.dart';
import '../../data/models.dart';
import '../../data/payroll.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import 'staff_approval_screen.dart';
import 'staff_management_screen.dart';
import 'substitute_approval_screen.dart';

/// 흰 트랙 안 선택 칩(5인 미만/이상, 파트 등).
class SegmentedPicker extends StatelessWidget {
  const SegmentedPicker({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  final List<String> options;
  final int selected;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            for (var i = 0; i < options.length; i++) ...[
              if (i > 0) const SizedBox(width: 4),
              Expanded(
                child: GestureDetector(
                  onTap: () => onChanged(i),
                  child: Container(
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: i == selected ? AppColors.primary : null,
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Text(
                      options[i],
                      style: AppText.style(
                        14,
                        FontWeight.w700,
                        i == selected
                            ? AppColors.onPrimary
                            : AppColors.textTertiary,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      );
}

/// − n명 + 카운터.
class CountStepper extends StatelessWidget {
  const CountStepper({super.key, required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int> onChanged;

  Widget _circle(String label, Color bg, Color fg, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
          child: Text(label, style: AppText.style(16, FontWeight.w700, fg)),
        ),
      );

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _circle('−', AppColors.bg, AppColors.textSecondary,
              () => onChanged(value > 0 ? value - 1 : 0)),
          const SizedBox(width: 14),
          Text('$value명', style: AppText.style(16, FontWeight.w700)),
          const SizedBox(width: 14),
          _circle('+', AppColors.primary, AppColors.onPrimary,
              () => onChanged(value + 1)),
        ],
      );
}

/// 작은 버튼(높이 36 · radius 10). filled=false 면 흰 배경 + border.
class SmallButton extends StatelessWidget {
  const SmallButton(
    this.label, {
    super.key,
    this.onPressed,
    this.background = AppColors.primary,
    this.color = AppColors.onPrimary,
    this.outlined = false,
  });

  const SmallButton.outline(this.label, {super.key, this.onPressed})
      : background = AppColors.surface,
        color = AppColors.textSecondary,
        outlined = true;

  final String label;
  final VoidCallback? onPressed;
  final Color background;
  final Color color;
  final bool outlined;

  @override
  Widget build(BuildContext context) => Material(
        color: background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: outlined
              ? const BorderSide(color: AppColors.border)
              : BorderSide.none,
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed ?? () {},
          child: Container(
            height: 36,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Text(label, style: AppText.style(13, FontWeight.w700, color)),
          ),
        ),
      );
}

typedef StepItem = ({StepStatus state, String title, String subtitle});

/// 완료 화면: 큰 체크 + 제목/설명 + 단계 타임라인 카드 + 하단 CTA.
class SuccessStepsScaffold extends StatelessWidget {
  const SuccessStepsScaffold({
    super.key,
    required this.title,
    required this.message,
    required this.steps,
    required this.ctaLabel,
    required this.onCta,
    this.stepsHeader,
  });

  final String title;
  final String message;
  final String? stepsHeader;
  final List<StepItem> steps;
  final String ctaLabel;
  final VoidCallback onCta;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Column(
              children: [
                const SizedBox(height: 28),
                Container(
                  width: 96,
                  height: 96,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                      color: AppColors.primarySoft, shape: BoxShape.circle),
                  child: Text('✓',
                      style: AppText.style(44, FontWeight.w700, AppColors.primary)),
                ),
                const SizedBox(height: 12),
                Text(title,
                    textAlign: TextAlign.center,
                    style: AppText.style(22, FontWeight.w700)),
                const SizedBox(height: 12),
                Text(message,
                    textAlign: TextAlign.center,
                    style: AppText.style(15, FontWeight.w400, AppColors.textSecondary)),
                const SizedBox(height: 24),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (stepsHeader != null) ...[
                        Text(stepsHeader!,
                            style: AppText.style(
                                14, FontWeight.w700, AppColors.textSecondary)),
                        const SizedBox(height: 16),
                      ],
                      for (var i = 0; i < steps.length; i++) ...[
                        if (i > 0) const SizedBox(height: 16),
                        StepRow(steps[i].state, steps[i].title, steps[i].subtitle),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: BottomBar.button(ctaLabel, onPressed: onCta),
      );
}

/// 파트별 칩 색.
(Color, Color) partColors(String part) => switch (part) {
      '오픈' => (AppColors.primary, AppColors.primarySoft),
      '미들' => (AppColors.info, AppColors.infoSoft),
      '마감' => (AppColors.accent, AppColors.accentSoft),
      _ => (AppColors.danger, AppColors.dangerSoft),
    };

/// 출근 상태 칩: (문구, 글자색, 배경색).
(String, Color, Color) attStyle(AttStatus s) => switch (s) {
      AttStatus.normal => ('출근', AppColors.primary, AppColors.primarySoft),
      AttStatus.late => ('지각', AppColors.danger, AppColors.dangerSoft),
      AttStatus.working => ('근무 중', AppColors.info, AppColors.infoSoft),
      AttStatus.waiting => ('대기', AppColors.accent, AppColors.accentSoft),
      AttStatus.absent => ('미출근', AppColors.danger, AppColors.dangerSoft),
    };

/// 시각 선택. 하루 기준 분을 돌려준다.
Future<int?> pickTime(BuildContext context, int minutes) async {
  final t = await showTimePicker(
    context: context,
    initialTime: TimeOfDay(hour: (minutes ~/ 60) % 24, minute: minutes % 60),
  );
  return t == null ? null : t.hour * 60 + t.minute;
}

/// 시급 · 공제 입력 다이얼로그 (가입 승인용). 최저임금 미만은 막는다.
Future<(int, Deduction)?> showWageDialog(BuildContext context,
    {required String title, required int wage, required Deduction deduction}) {
  final ctrl = TextEditingController(text: '$wage');
  var d = deduction;
  String? error;
  return showDialog<(int, Deduction)>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => Dialog(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppText.style(18, FontWeight.w700)),
              const SizedBox(height: 16),
              LabeledField('시급 (원)',
                  child: AppTextField(controller: ctrl, keyboardType: TextInputType.number)),
              if (error != null) ...[
                const SizedBox(height: 6),
                Text(error!, style: AppText.style(12, FontWeight.w500, AppColors.danger)),
              ],
              const SizedBox(height: 14),
              Text('공제 유형', style: AppText.style(14, FontWeight.w700, AppColors.textSecondary)),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: SegmentedPicker(
                  options: [for (final x in Deduction.values) x.short],
                  selected: d.index,
                  onChanged: (i) => setState(() => d = Deduction.values[i]),
                ),
              ),
              const SizedBox(height: 20),
              Row(children: [
                Expanded(
                  child: AppButton('취소',
                      variant: AppButtonVariant.outline,
                      verticalPadding: 13,
                      fontSize: 15,
                      onPressed: () => Navigator.pop(context)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AppButton('승인', verticalPadding: 13, fontSize: 15, onPressed: () {
                    final w = int.tryParse(ctrl.text.replaceAll(RegExp(r'[^0-9]'), ''));
                    if (w == null || w < minimumWage2026) {
                      setState(() => error = '2026 최저임금 ${wonText(minimumWage2026)} 이상이어야 해요');
                      return;
                    }
                    Navigator.pop(context, (w, d));
                  }),
                ),
              ]),
            ],
          ),
        ),
      ),
    ),
  );
}

/// 직원 한 명 고르기 (대타 직접 배정 등).
Future<Staff?> pickStaff(BuildContext context, List<Staff> candidates, {required String title}) =>
    showModalBottomSheet<Staff>(
      context: context,
      backgroundColor: AppColors.bg,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        final store = AppScope.read(context);
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            children: [
              Text(title, style: AppText.style(18, FontWeight.w700)),
              const SizedBox(height: 14),
              if (candidates.isEmpty) const EmptyNote('배정할 수 있는 직원이 없어요'),
              for (final s in candidates) ...[
                PersonRow(
                  avatar: MemberAvatar(s),
                  title: store.personOf(s).name,
                  subtitle: '${s.part} · 시급 ${wonText(s.wage)}',
                  onTap: () => Navigator.pop(context, s),
                ),
                const SizedBox(height: 10),
              ],
            ],
          ),
        );
      },
    );

/// 사장님 알림 → 관련 화면.
Widget? employerTarget(BuildContext context, AppNotification n) => switch (n.type) {
      'sub' => const SubstituteApprovalScreen(),
      'join' => const StaffApprovalScreen(),
      'cert' || 'contract' => const StaffManagementScreen(),
      _ => null,
    };
