import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/app_scope.dart';
import 'data/app_store.dart';
import 'data/models.dart';
import 'screens/employee/employee_shell.dart';
import 'screens/employee/login_screen.dart';
import 'screens/employer/employer_shell.dart';
import 'screens/web/web_shell.dart';
import 'theme.dart';

const _storageKey = 'donbug.state';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final store = AppStore.load(
    prefs.getString(_storageKey),
    onSave: (json) => prefs.setString(_storageKey, json),
  );
  runApp(MyApp(store: store));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.store});

  final AppStore store;

  @override
  Widget build(BuildContext context) => AppScope(
        store: store,
        child: MaterialApp(
          title: '돈벌래',
          debugShowCheckedModeBanner: false,
          theme: appTheme,
          home: _home(),
        ),
      );

  // shortcut: 웹은 사장님 대시보드로 바로 진입(하드코딩 화면), 웹 연결 단계에서 교체.
  Widget _home() {
    if (kIsWeb) return const WebShell();
    final s = store.session;
    if (!s.loggedIn) return const LoginScreen();
    return s.role == Role.employee ? const EmployeeShell() : const EmployerShell();
  }
}
