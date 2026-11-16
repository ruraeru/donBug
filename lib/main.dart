import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/api_client.dart';
import 'data/app_scope.dart';
import 'data/app_store.dart';
import 'data/models.dart';
import 'data/seed.dart';
import 'widgets/common.dart';
import 'screens/employee/employee_shell.dart';
import 'screens/employee/login_screen.dart';
import 'screens/employer/employer_shell.dart';
import 'screens/mobile_boot.dart';
import 'screens/web/web_boot.dart';
import 'screens/web/web_shell.dart';
import 'screens/web/web_view_mode.dart';
import 'theme.dart';

const _storageKey = 'donbug.state';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  // 서버 모드는 상태를 기기에 저장하지 않는다. 자리표시 시드는 reload 끝나기 전엔 화면에 안 나온다(WebBoot 가 로딩 표시).
  final store = useApi
      ? AppStore(buildSeed(DateTime.now()), api: ApiClient(prefs: prefs))
      : AppStore.load(
          prefs.getString(_storageKey),
          onSave: (json) => prefs.setString(_storageKey, json),
        );
  // 웹은 사장님 전용. 저장본이 알바생 역할이어도 사장님 매장으로 연다.
  if (kIsWeb) store.session.role = Role.employer;
  runApp(MyApp(store: store));
}

final messengerKey = GlobalKey<ScaffoldMessengerState>();
final navigatorKey = GlobalKey<NavigatorState>();

class MyApp extends StatefulWidget {
  const MyApp({super.key, required this.store});

  final AppStore store;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  Timer? _poll;

  // 서버 모드: 다른 사람이 한 일(대타 요청·지원, 가입 신청 등)이 보이도록 주기적으로, 앱으로 돌아올 때 다시 읽는다.
  Future<void> _refresh() => widget.store.refreshNow(quiet: true);

  /// 변경 신호 기다리기(롱 폴링): 내 매장이 바뀌면 서버가 바로 응답하고, 그때 다시 읽는다.
  Future<void> _watchChanges() async {
    final st = widget.store;
    var since = -1;
    while (mounted) {
      if (!st.api!.hasToken || !st.session.loggedIn) {
        await Future<void>.delayed(const Duration(seconds: 5));
        continue;
      }
      try {
        final j = await st.api!.get('/api/v1/me/changes?since=$since') as Map<String, dynamic>;
        since = (j['seq'] as num).toInt();
        if (j['changed'] == true) await _refresh();
      } catch (_) {
        await Future<void>.delayed(const Duration(seconds: 5));
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  @override
  void initState() {
    super.initState();
    if (widget.store.remote) {
      WidgetsBinding.instance.addObserver(this);
      // 변경 신호가 끊겼을 때를 대비한 주기 확인.
      _poll = Timer.periodic(const Duration(seconds: 60), (_) => _refresh());
      _watchChanges();
    }
    widget.store.remoteError.addListener(_showError);
    // 서버 모드: 토큰 갱신이 실패하면 로그인으로. 웹은 WebBoot 가 로그인 화면을 띄운다.
    if (widget.store.remote) {
      widget.store.api!.onUnauthorized = () => navigatorKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute(
              builder: (_) => kIsWeb ? WebBoot(store: widget.store) : const LoginScreen()),
          (_) => false);
    }
  }

  @override
  void dispose() {
    _poll?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    widget.store.remoteError.removeListener(_showError);
    super.dispose();
  }

  void _showError() {
    final msg = widget.store.remoteError.value;
    final m = messengerKey.currentState;
    if (msg == null || m == null) return;
    widget.store.remoteError.value = null;
    showToastOn(m, msg);
  }

  @override
  Widget build(BuildContext context) => AppScope(
    store: widget.store,
    child: MaterialApp(
      title: '돈벌래',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: messengerKey,
      navigatorKey: navigatorKey,
      theme: appTheme,
      // 웹 모바일 화면: PC 에서도 폰 폭으로 가운데에 보여 준다.
      builder: (context, child) => GestureDetector(
        // 빈 곳을 누르면 키보드를 내린다 (숫자 키패드엔 닫기 키가 없다). 버튼 탭은 안쪽이 먼저 받는다.
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: !kIsWeb
            ? child
            : ValueListenableBuilder<bool>(
                valueListenable: webMobileFrame,
                builder: (context, on, _) => !on
                    ? child!
                    : ColoredBox(
                        color: AppColors.border,
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 480),
                            child: child,
                          ),
                        ),
                      ),
              ),
      ),
      home: _home(),
    ),
  );

  Widget _home() {
    if (kIsWeb && widget.store.remote) return WebBoot(store: widget.store);
    // shortcut: 데모 웹은 로그인 없이 사장님 대시보드로 바로 진입.
    if (kIsWeb) return const WebShell();
    if (widget.store.remote) return const MobileBoot();
    final s = widget.store.session;
    if (!s.loggedIn) return const LoginScreen();
    return s.role == Role.employee
        ? const EmployeeShell()
        : const EmployerShell();
  }
}
