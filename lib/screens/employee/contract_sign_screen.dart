import 'package:flutter/material.dart';

import '../../data/app_scope.dart';
import '../../data/format.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import 'employee_parts.dart';

/// 전자 근로계약서 확인 · 서명 (현재 매장).
class ContractSignScreen extends StatefulWidget {
  const ContractSignScreen({super.key});

  @override
  State<ContractSignScreen> createState() => _ContractSignScreenState();
}

class _ContractSignScreenState extends State<ContractSignScreen> {
  bool _agree = false;
  bool _signed = false;

  void _submit() {
    if (!_agree) return showToast(context, '계약 내용을 확인했다고 체크해 주세요');
    if (!_signed) return showToast(context, '서명해 주세요');
    AppScope.read(context).signContract();
    Navigator.pop(context);
    showToast(context, '근로계약서에 서명했어요');
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final c = store.myStaff?.contract;
    if (c == null) return const MissingScreen(title: '전자 근로계약서');
    final terms = [
      ('근무 장소', store.store.name),
      ('업무 내용', c.duty.isEmpty ? store.myStaff!.part : c.duty),
      ('계약 기간', '${dotDate(parseYmd(c.start))} ~ ${dotDate(parseYmd(c.end))}'),
      ('소정근로시간', '주 ${c.weeklyHours}시간 (${c.workDays})'),
      ('임금', '시급 ${wonText(c.wage)}'),
      ('휴일', '주휴일 일요일'),
    ];
    return Scaffold(
      appBar: const AppHeader('전자 근로계약서'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(child: Text('표준 근로계약서', style: AppText.style(17, FontWeight.w700))),
                  c.signed ? const Pill('서명 완료') : const Pill.accent('서명 필요'),
                ]),
                const SizedBox(height: 12),
                const Divider(height: 1, color: AppColors.border),
                for (final (label, value) in terms) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text(label, style: AppText.style(14, FontWeight.w400, AppColors.textSecondary)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(value,
                            textAlign: TextAlign.right, style: AppText.style(14, FontWeight.w700)),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (c.signed)
            NoteBox('${dotDate(DateTime.parse(c.employeeSignedAt!))}에 서명했어요.',
                color: AppColors.primary, background: AppColors.primarySoft)
          else ...[
            SignaturePad(onChanged: (v) => setState(() => _signed = v)),
            const SizedBox(height: 16),
            CheckLine('계약 내용을 모두 확인했어요',
                value: _agree, onChanged: (v) => setState(() => _agree = v)),
          ],
        ],
      ),
      bottomNavigationBar: BottomBar(
        child: c.signed
            ? AppButton('닫기',
                variant: AppButtonVariant.outline, onPressed: () => Navigator.pop(context))
            : AppButton('서명하고 제출', onPressed: _submit),
      ),
    );
  }
}
