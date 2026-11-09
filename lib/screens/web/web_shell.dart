import 'package:flutter/material.dart';

import '../../data/app_scope.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import 'web_ai_assistant_screen.dart';
import 'web_common.dart';
import 'web_dashboard_screen.dart';
import 'web_documents_screen.dart';
import 'web_notice_screen.dart';
import 'web_payroll_screen.dart';
import 'web_pos_qr_screen.dart';
import 'web_schedule_screen.dart';
import 'web_schedule_variants_view.dart';
import 'web_staff_screen.dart';

/// 사장님 웹: 왼쪽 Sidebar(240) + 메뉴별 콘텐츠 영역.
class WebShell extends StatefulWidget {
  const WebShell({super.key});

  @override
  State<WebShell> createState() => _WebShellState();
}

class _WebShellState extends State<WebShell> {
  static const _menu = ['대시보드', '근무표', '직원 관리', '인건비', '서류·컴플라이언스', '공지', 'AI 노무 도우미'];
  int _page = 0;
  bool _altSchedule = false;

  Widget _content() => switch (_page) {
        0 => WebDashboardScreen(onNavigate: (i) => setState(() => _page = i)),
        1 => Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 12, 32, 0),
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => setState(() => _altSchedule = !_altSchedule),
                  child: Text(_altSchedule ? '기본 보기' : '다른 보기',
                      style: AppText.style(13, FontWeight.w700, AppColors.primary)),
                ),
              ),
            ),
            Expanded(
              child: _altSchedule
                  ? const WebScheduleVariantsView()
                  : const WebScheduleScreen(),
            ),
          ]),
        2 => const WebStaffScreen(),
        3 => const WebPayrollScreen(),
        4 => const WebDocumentsScreen(),
        5 => const WebNoticeScreen(),
        _ => const WebAiAssistantScreen(),
      };

  Future<void> _resetDemo(BuildContext context) async {
    final ok = await showConfirmDialog(
      context,
      title: '데모 데이터를 초기화할까요?',
      message: '바꾼 내용이 모두 사라지고 처음 데이터로 돌아가요.',
      confirmLabel: '초기화',
      confirmVariant: AppButtonVariant.danger,
    );
    if (ok && context.mounted) AppScope.read(context).resetDemo();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.bg,
        body: Row(children: [
          SizedBox(
            width: 240,
            child: ColoredBox(
              color: AppColors.surface,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Column(children: [
                  Expanded(
                    child: ListView(children: [
                      const _Logo(),
                      for (var i = 0; i < _menu.length; i++) ...[
                        _MenuItem(
                          label: _menu[i],
                          active: i == _page,
                          onTap: () => setState(() => _page = i),
                        ),
                        const SizedBox(height: 6),
                      ],
                    ]),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: double.infinity,
                    child: WebButton(
                      '매장 POS 모드 열기',
                      style: WebButtonStyle.dark,
                      height: 46,
                      onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const WebPosQrScreen())),
                    ),
                  ),
                  TextButton(
                    onPressed: () => _resetDemo(context),
                    child: Text('데모 데이터 초기화',
                        style: AppText.style(12, FontWeight.w500, AppColors.textTertiary)),
                  ),
                ]),
              ),
            ),
          ),
          Expanded(child: _content()),
        ]),
      );
}

class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 6, bottom: 24),
        child: Row(children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
                color: AppColors.primary, borderRadius: BorderRadius.circular(10)),
            child: Text('₩', style: AppText.style(16, FontWeight.w700, AppColors.onPrimary)),
          ),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('돈벌래', style: AppText.style(16, FontWeight.w700)),
            Text(AppScope.of(context).store.name,
                style: AppText.style(11, FontWeight.w400, AppColors.textSecondary)),
          ]),
        ]),
      );
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({required this.label, required this.active, required this.onTap});

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.primary : AppColors.textSecondary;
    return Material(
      color: active ? AppColors.primarySoft : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(children: [
            // Figma 메뉴 아이콘은 테두리 사각형 placeholder.
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                border: Border.all(
                    color: active ? AppColors.primary : AppColors.textTertiary,
                    width: 2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.style(
                      15, active ? FontWeight.w700 : FontWeight.w500, color)),
            ),
          ]),
        ),
      ),
    );
  }
}
