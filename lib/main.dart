import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'screens/employee/login_screen.dart';
import 'screens/web/web_shell.dart';
import 'theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '돈벌래',
      debugShowCheckedModeBanner: false,
      theme: appTheme,
      // shortcut: 웹은 사장님 대시보드로 바로 진입, 웹 로그인 화면이 디자인되면 교체.
      home: kIsWeb ? const WebShell() : const LoginScreen(),
    );
  }
}
