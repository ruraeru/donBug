import 'package:flutter/material.dart';
import 'home_tab.dart';
import 'schedule_tab.dart';
import 'salary_tab.dart';

class EmployeeMainScreen extends StatefulWidget {
  const EmployeeMainScreen({super.key});

  @override
  State<EmployeeMainScreen> createState() => _EmployeeMainScreenState();
}

class _EmployeeMainScreenState extends State<EmployeeMainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const HomeTab(),
    const ScheduleTab(),
    const SalaryTab(),
    const Center(child: Text('알바생 공지 화면')),
    const Center(child: Text('알바생 MY 화면')),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFF5D8A66),
        unselectedItemColor: const Color(0xFFBDBDBD),
        selectedFontSize: 12,
        unselectedFontSize: 12,
        onTap: (index) => setState(() => _selectedIndex = index),
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