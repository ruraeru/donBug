import 'package:flutter/material.dart';
import 'screens/login_screen.dart';

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
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF5D8A66)),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF5F6F8), // 전체 옅은 회색 배경
      ),
      home: const LoginScreen(),
    );
  }
}