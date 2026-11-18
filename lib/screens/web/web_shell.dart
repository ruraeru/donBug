import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../data/app_scope.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import '../profile_edit_screen.dart';
import 'web_ai_assistant_screen.dart';
import 'web_boot.dart';
import 'web_common.dart';
import 'web_create_store_screen.dart';
import 'web_dashboard_screen.dart';
import 'web_documents_screen.dart';
import 'web_notice_screen.dart';
import 'web_payroll_screen.dart';
import 'web_pos_qr_screen.dart';
import 'web_schedules_screen.dart';
import 'web_settings_screen.dart';
import 'web_staff_screen.dart';
import 'web_substitute_screen.dart';
import 'web_templates_screen.dart';
import 'web_view_mode.dart';

/// 웹 메뉴 번호 ([WebShell] 순서).
abstract final class WebMenu {
  static const dashboard = 0;
  static const schedule = 1;
  static const staff = 2;
  static const substitute = 3;
  static const payroll = 4;
  static const documents = 5;
  static const notice = 6;
  static const ai = 7;
  static const templates = 8;
  static const settings = 9;
}

/// 사장님 웹 셸. 폭 1100 이상은 사이드바(240), 800–1100 은 아이콘 레일, 800 미만은 상단 바 + 서랍.
class WebShell extends StatefulWidget {
  const WebShell({super.key});

  /// 다른 웹 메뉴로 이동.
  static void open(BuildContext context, int page) =>
      context.findAncestorStateOfType<_WebShellState>()?._select(page);

  @override
  State<WebShell> createState() => _WebShellState();
}

class _WebShellState extends State<WebShell> {
  static const _menu = [
    ('대시보드', 'tab_home'),
    ('근무표', 'tab_calendar'),
    ('직원 관리', 'tab_my'),
    ('대타 승인', 'send'),
    ('인건비', 'tab_salary'),
    ('서류·컴플라이언스', 'tab_docs'),
    ('공지', 'tab_notice'),
    ('AI 노무 도우미', 'alert_circle'),
    ('템플릿', 'tab_docs'),
    ('매장 설정', 'tab_labor'),
  ];

  final _scaffold = GlobalKey<ScaffoldState>();

  /// 800 경계에서 부모 위치가 바뀌어도 화면 상태가 남도록 내용에 같은 key 를 준다.
  final _contentKey = GlobalKey();
  int _page = 0;

  Future<void> _select(int i) async {
    if (i != _page && AppScope.read(context).scheduleDirty) {
      final ok = await showConfirmDialog(context,
          title: '저장하지 않은 변경 사항이 있어요',
          message: '이동하면 저장하지 않은 근무표 변경 사항이 사라져요.',
          confirmLabel: '이동',
          confirmVariant: AppButtonVariant.danger);
      if (!ok || !mounted) return;
    }
    if (_scaffold.currentState?.isDrawerOpen ?? false) Navigator.pop(context);
    setState(() => _page = i);
  }

  Widget _content() => KeyedSubtree(key: _contentKey, child: _pageBody());

  Widget _pageBody() => switch (_page) {
        0 => const WebDashboardScreen(),
        1 => const WebSchedulesScreen(),
        2 => const WebStaffScreen(),
        3 => const WebSubstituteScreen(),
        4 => const WebPayrollScreen(),
        5 => const WebDocumentsScreen(),
        6 => const WebNoticeScreen(),
        8 => const WebTemplatesScreen(),
        9 => const WebSettingsScreen(),
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

  /// 매장 이름 → 소유 매장 전환 메뉴 + 새 매장 추가(서버 모드).
  Future<void> _switchStore() async {
    final store = AppScope.read(context);
    if (store.scheduleDirty) {
      return showToast(context, '저장하지 않은 근무표 변경 사항이 있어요. 저장한 뒤 전환해 주세요');
    }
    final picked = await showWebDialog<String>(context,
        title: '매장 전환',
        builder: (context, _) => Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                for (final st in store.ownedStores)
                  ListTile(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    title: Text(st.name, style: AppText.style(15, FontWeight.w500)),
                    subtitle: Text(st.code,
                        style: AppText.style(12, FontWeight.w400, AppColors.textSecondary)),
                    trailing: st.id == store.store.id
                        ? Text('현재', style: AppText.style(13, FontWeight.w500, AppColors.primary))
                        : null,
                    onTap: () => Navigator.pop(context, st.id),
                  ),
                if (store.remote) ...[
                  const SizedBox(height: 8),
                  WebButton('+ 새 매장 추가',
                      style: WebButtonStyle.outline,
                      expand: true,
                      onPressed: () => Navigator.pop(context, '')),
                ],
              ]),
            ));
    if (picked == null || !mounted) return;
    if (picked.isEmpty) return _addStore();
    if (picked == store.store.id) return;
    if (!store.switchOwnerStore(picked)) {
      return showToast(context, '저장하지 않은 근무표 변경 사항이 있어요. 저장한 뒤 전환해 주세요');
    }
    _done(store.store.name);
  }

  void _done(String name) {
    _select(WebMenu.dashboard);
    showToast(context, '$name 매장으로 전환했어요');
  }

  void _addStore() => Navigator.of(context).push(MaterialPageRoute(
        builder: (route) => WebCreateStoreScreen(
          onCancel: () => Navigator.pop(route),
          onCreate: ({required name, required address, required isSmall, required deduction}) async {
            final store = AppScope.read(context);
            await store.createStoreRemote(
                name: name, address: address, isSmall: isSmall, deduction: deduction);
            if (!route.mounted || !mounted) return;
            Navigator.pop(route);
            _done(store.store.name);
          },
        ),
      ));

  void _openProfile() => showWebDialog<void>(context,
      title: '내 프로필',
      builder: (ctx, _) => ProfileForm(
            onSaved: () => Navigator.pop(ctx),
            layout: (_, fields, save) => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [...fields, const SizedBox(height: 20), save],
            ),
          ));

  void _openPos() =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const WebPosQrScreen()));

  /// 메뉴 옆 숫자(대타 승인 대기 · 가입 대기).
  int _badge(int i) {
    final store = AppScope.of(context);
    return switch (i) {
      WebMenu.substitute => store.pendingSubs.length,
      WebMenu.staff => store.pendingStaff.length,
      _ => 0,
    };
  }

  Widget _profileButton(bool rail) => rail
      ? IconButton(
          tooltip: '내 프로필',
          onPressed: _openProfile,
          icon: const Icon(Icons.person_outline, size: 22, color: AppColors.textTertiary),
        )
      : TextButton(
          onPressed: _openProfile,
          child: Text('내 프로필', style: AppText.style(12, FontWeight.w500, AppColors.textTertiary)),
        );

  Widget _sidebar({required bool rail}) => ColoredBox(
        color: AppColors.surface,
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: rail ? 12 : 20, vertical: 24),
            child: Column(children: [
              Expanded(
                child: ListView(children: [
                  _Logo(compact: rail, onTap: _switchStore),
                  for (var i = 0; i < _menu.length; i++) ...[
                    _MenuItem(
                      label: _menu[i].$1,
                      icon: _menu[i].$2,
                      active: i == _page,
                      rail: rail,
                      badge: _badge(i),
                      onTap: () => _select(i),
                    ),
                    const SizedBox(height: 6),
                  ],
                ]),
              ),
              const SizedBox(height: 6),
              if (AppScope.of(context).remote) ...[
                rail
                    ? IconButton(
                        tooltip: '매장 POS 모드 열기',
                        onPressed: _openPos,
                        icon: const AppIcon('scan', color: AppColors.textPrimary),
                      )
                    : WebButton('매장 POS 모드 열기',
                        style: WebButtonStyle.dark, height: 46, expand: true, onPressed: _openPos),
                _profileButton(rail),
                rail
                    ? IconButton(
                        tooltip: '모바일 화면',
                        onPressed: () => openMobileView(context),
                        icon: const Icon(Icons.smartphone, size: 22, color: AppColors.textTertiary),
                      )
                    : TextButton(
                        onPressed: () => openMobileView(context),
                        child: Text('모바일 화면',
                            style: AppText.style(12, FontWeight.w500, AppColors.textTertiary)),
                      ),
                rail
                    ? IconButton(
                        tooltip: '로그아웃',
                        onPressed: () => WebBoot.logout(context),
                        icon: const Icon(Icons.logout, size: 22, color: AppColors.textTertiary),
                      )
                    : TextButton(
                        onPressed: () => WebBoot.logout(context),
                        child: Text('로그아웃',
                            style: AppText.style(12, FontWeight.w500, AppColors.textTertiary)),
                      ),
              ] else ...[
              rail
                  ? Column(children: [
                      IconButton(
                        tooltip: '매장 POS 모드 열기',
                        onPressed: _openPos,
                        icon: const AppIcon('scan', color: AppColors.textPrimary),
                      ),
                      IconButton(
                        tooltip: '데모 데이터 초기화',
                        onPressed: () => _resetDemo(context),
                        icon: const Icon(Icons.restart_alt, size: 22, color: AppColors.textTertiary),
                      ),
                    ])
                  : WebButton('매장 POS 모드 열기',
                      style: WebButtonStyle.dark, height: 46, expand: true, onPressed: _openPos),
              _profileButton(rail),
              if (!rail)
                TextButton(
                  onPressed: () => _resetDemo(context),
                  child: Text('데모 데이터 초기화',
                      style: AppText.style(12, FontWeight.w500, AppColors.textTertiary)),
                ),
              ],
            ]),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, c) {
        final w = c.maxWidth;
        if (w < 800) {
          return Scaffold(
            key: _scaffold,
            backgroundColor: AppColors.bg,
            appBar: AppBar(
              backgroundColor: AppColors.surface,
              surfaceTintColor: Colors.transparent,
              title: Text(_menu[_page].$1, style: AppText.style(17, FontWeight.w500)),
            ),
            drawer: Drawer(width: 260, child: _sidebar(rail: false)),
            body: _content(),
          );
        }
        final rail = w < 1100;
        return Scaffold(
          key: _scaffold,
          backgroundColor: AppColors.bg,
          body: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            SizedBox(width: rail ? 76 : 240, child: _sidebar(rail: rail)),
            Expanded(child: _content()),
          ]),
        );
      });
}

class _Logo extends StatelessWidget {
  const _Logo({required this.compact, required this.onTap});

  final bool compact;

  /// 매장 전환 메뉴.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final name = AppScope.of(context).store.name;
    final icon = ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SvgPicture.asset('assets/images/app_icon.svg', width: 36, height: 36),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: EdgeInsets.fromLTRB(compact ? 4 : 6, 4, 4, 4),
          child: compact
              ? Tooltip(message: '$name · 매장 전환', child: icon)
              : Row(children: [
                  icon,
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('돈벌래', style: AppText.style(16, FontWeight.w500)),
                      Text(name,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.style(11, FontWeight.w400, AppColors.textSecondary)),
                    ]),
                  ),
                  const Icon(Icons.unfold_more_rounded, size: 18, color: AppColors.textTertiary),
                ]),
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.label,
    required this.icon,
    required this.active,
    required this.rail,
    required this.badge,
    required this.onTap,
  });

  final String label, icon;
  final bool active, rail;
  final int badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.primary : AppColors.textSecondary;
    final iconWidget = AppIcon(icon, size: 20, color: color);
    final item = Material(
      color: active ? AppColors.primarySoft : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: rail ? 0 : 14, vertical: 12),
          child: rail
              ? Center(child: CountBadge(count: badge, child: iconWidget))
              : Row(children: [
                  iconWidget,
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.style(15, FontWeight.w500, color)),
                  ),
                  if (badge > 0)
                    Text('$badge', style: AppText.style(13, FontWeight.w500, color)),
                ]),
        ),
      ),
    );
    final ringed = FocusRing(child: item);
    return rail ? Tooltip(message: label, child: ringed) : ringed;
  }
}
