import 'package:flutter/material.dart';
import 'home_tab.dart';
import 'schedule_tab.dart';
import 'salary_tab.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const HomeTab(),        // 인덱스 0: 홈 화면
    const ScheduleTab(),    // 인덱스 1: 근무표 화면
    const SalaryTab(),      // 인덱스 2: 급여 화면
    const Center(child: Text('공지 화면')),
    const Center(child: Text('MY 화면')),
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
          BottomNavigationBarItem(icon: Icon(Icons.attach_money_rounded), label: '급여'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications_none_rounded), label: '공지'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline_rounded), label: 'MY'),
        ],
      ),
    );
  }
}