import 'package:flutter/material.dart';
import 'employer_home_tab.dart';
import 'document_tab.dart';
import 'employer_notice_tab.dart'; // ★ 새로 만든 사장님 공지 화면 import

class EmployerMainScreen extends StatefulWidget {
  const EmployerMainScreen({super.key});

  @override
  State<EmployerMainScreen> createState() => _EmployerMainScreenState();
}

class _EmployerMainScreenState extends State<EmployerMainScreen> {
  int _selectedIndex = 4; // 개발 테스트를 위해 4번(공지 탭)이 먼저 열리도록 임시 변경했습니다. (기본값 0)

  final List<Widget> _pages = [
    const EmployerHomeTab(),                  // 0: 사장님 홈
    const Center(child: Text('사장님 근무표 관리 화면')), // 1: 근무표
    const Center(child: Text('사장님 인건비 화면')),     // 2: 인건비
    const DocumentTab(),                      // 3: 서류
    const EmployerNoticeTab(),                // ★ 4: 사장님 공지 탭 연결
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFF5D8A66),
        unselectedItemColor: const Color(0xFFBDBDBD),
        selectedFontSize: 12,
        unselectedFontSize: 12,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: '홈'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month_outlined), label: '근무표'),
          BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet_outlined), label: '인건비'),
          BottomNavigationBarItem(icon: Icon(Icons.description_outlined), label: '서류'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications_none_rounded), label: '공지'), // ★ 공지 아이콘
        ],
      ),
    );
  }
}