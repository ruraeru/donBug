import 'package:flutter/material.dart';
import 'main_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(flex: 3),
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: const Color(0xFF5D8A66),
                  borderRadius: BorderRadius.circular(24),
                ),
                alignment: Alignment.center,
                child: const Text('₩', style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
              const SizedBox(height: 24),
              const Text(
                '돈벌래',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF222222), letterSpacing: -0.5),
              ),
              const SizedBox(height: 16),
              const Text(
                '사장님의 행정 부담은 덜고,\n알바생의 권리는 지키는\n스마트 매장 관리',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: Color(0xFF777777), height: 1.5),
              ),
              const Spacer(flex: 4),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    // 메인 화면(탭바 화면)으로 이동
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const MainScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFEE500),
                    foregroundColor: Colors.black87,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('카카오로 시작하기', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                ),
              ),
              const SizedBox(height: 16),
              const Text('로그인 후 사장님 / 알바생 역할을 선택해요', style: TextStyle(fontSize: 13, color: Color(0xFFAAAAAA))),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}