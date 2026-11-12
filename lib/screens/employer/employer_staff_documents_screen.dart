import 'package:flutter/material.dart';

import '../../data/app_scope.dart';
import '../../data/format.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import 'employer_contract_write_screen.dart';
import 'employer_documents_screen.dart';
import 'employer_health_cert_alert_screen.dart';

/// 직원 서류 상세 (Figma 48:269).
class EmployerStaffDocumentsScreen extends StatelessWidget {
  const EmployerStaffDocumentsScreen({super.key, required this.staffId});

  final String staffId;

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final s = store.staffById(staffId);
    if (s == null) return const MissingScreen(title: '서류');
    final p = store.personOf(s);
    final c = s.contract;
    return Scaffold(
      appBar: AppHeader('${p.name} · 서류'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        children: [
          AppCard(
            child: Column(
              children: [
                _header('보건증', certPill(store.certDaysLeft(p))),
                const SizedBox(height: 12),
                Container(
                  height: 110,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(14)),
                  child: Text(p.certHasPhoto ? '보건증 사진 (등록됨 · 데모)' : '등록된 사진 없음',
                      style: AppText.style(13, FontWeight.w400, AppColors.textTertiary)),
                ),
                const SizedBox(height: 12),
                KeyValueRow('만료일', p.certExpiry == null ? '-' : dotDate(parseYmd(p.certExpiry!))),
                const SizedBox(height: 12),
                AppButton(
                  '갱신 요청 보내기',
                  verticalPadding: 17,
                  // 완료 화면은 뒤로가기 대신 "서류 목록으로"로 끝나므로 교체.
                  onPressed: () {
                    AppScope.read(context).requestCertRenewal(s.id);
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => EmployerHealthCertAlertScreen(staffId: s.id)),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          AppCard(
            child: Column(
              children: [
                _header('근로계약서', contractPill(c)),
                const SizedBox(height: 10),
                if (c != null)
                  KeyValueRow('계약 기간',
                      '${dotDate(parseYmd(c.start))} ~ ${dotDate(parseYmd(c.end))}',
                      valueWeight: FontWeight.w400),
                if (c == null || !c.signed) ...[
                  const SizedBox(height: 12),
                  AppButton(
                    c == null ? '계약서 작성' : '계약서 다시 작성',
                    variant: AppButtonVariant.soft,
                    onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => EmployerContractWriteScreen(staffId: s.id))),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(String title, Widget chip) => Row(
        children: [
          Expanded(child: Text(title, style: AppText.style(17, FontWeight.w500))),
          chip,
        ],
      );
}
