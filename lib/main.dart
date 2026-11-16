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

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    widget.store.remoteError.addListener(_showError);
    // 앱 서버 모드: 토큰 갱신이 실패하면 로그인 화면으로. (웹은 WebBoot 가 처리)
    if (!kIsWeb && useApi) {
      widget.store.api!.onUnauthorized = () => navigatorKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
    }
  }

  @override
  void dispose() {
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
      home: _home(),
    ),
  );

  Widget _home() {
    if (kIsWeb && useApi) return WebBoot(store: widget.store);
    // shortcut: 데모 웹은 로그인 없이 사장님 대시보드로 바로 진입.
    if (kIsWeb) return const WebShell();
    if (useApi) return const MobileBoot();
    final s = widget.store.session;
    if (!s.loggedIn) return const LoginScreen();
    return s.role == Role.employee
        ? const EmployeeShell()
        : const EmployerShell();
  }
}
