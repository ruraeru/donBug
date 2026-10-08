import 'package:flutter/material.dart';
import 'employer_main_screen.dart';
import 'employee_main_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // 로딩 상태를 관리하는 변수
  bool _isLoading = false;

  // [테스트용 변수]
  // 이 값을 'employer'(사장님) 또는 'employee'(알바생)로 바꿔가며 테스트해 보세요.
  final String _mockUserRole = 'employer';

  // 카카오 로그인 및 역할 라우팅 함수
  Future<void> _handleLogin() async {
    setState(() {
      _isLoading = true; // 로딩 시작
    });

    // 1. 카카오 로그인 및 서버 통신 대기시간 시뮬레이션 (1.5초)
    // 실제 개발 시에는 여기에 await KakaoLogin API 및 백엔드 유저 정보 요청 코드가 들어갑니다.
    await Future.delayed(const Duration(milliseconds: 1500));

    if (!mounted) return;

    // 2. 서버에서 받은 역할(Role) 값에 따라 화면 자동 분기
    if (_mockUserRole == 'employer') {
      // 사장님 계정인 경우
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const EmployerMainScreen()),
      );
    } else {
      // 알바생 계정인 경우
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const EmployeeMainScreen()),
      );
    }
  }

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

              // 카카오 로그인 버튼 영역
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  // 로딩 중일 때는 버튼 클릭을 막기 위해 null 할당
                  onPressed: _isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFEE500),
                    disabledBackgroundColor: const Color(0xFFFEE500).withOpacity(0.6), // 로딩 시 반투명
                    foregroundColor: Colors.black87,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: Colors.black54,
                    ),
                  ) // 로딩 중일 땐 빙글빙글 도는 스피너 표시
                      : const Text(
                    '카카오로 시작하기',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '등록된 정보에 따라 알맞은 화면으로 이동합니다',
                style: TextStyle(fontSize: 13, color: Color(0xFFAAAAAA)),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}