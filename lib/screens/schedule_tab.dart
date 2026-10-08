import 'package:flutter/material.dart';
import 'leave_request_screen.dart'; // 새롭게 추가한 휴무 신청 화면 import

class ScheduleTab extends StatelessWidget {
  const ScheduleTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Stack(
        children: [
          // 스크롤 가능한 본문 영역
          ListView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 100), // 하단 버튼이 가리지 않게 여백 추가
            children: [
              // 상단 타이틀 & 주차 뱃지
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '근무표',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF222222)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      '5월 2주차',
                      style: TextStyle(color: Color(0xFF5D8A66), fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 주간 달력
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildDayItem('월', '12', hasDot: true),
                  _buildDayItem('화', '13'),
                  _buildDayItem('수', '14', isSelected: true, hasDot: true), // 오늘
                  _buildDayItem('목', '15'),
                  _buildDayItem('금', '16', hasDot: true),
                  _buildDayItem('토', '17', hasDot: true),
                  _buildDayItem('일', '18'),
                ],
              ),
              const SizedBox(height: 32),

              // 이번 주 내 근무 리스트 타이틀
              const Text(
                '이번 주 내 근무',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF222222)),
              ),
              const SizedBox(height: 16),

              // 근무 리스트 카드들
              _buildShiftCard('월', '12', '14:00 - 20:00', '홀', '완료', const Color(0xFFF0F0F0), const Color(0xFF888888)),
              const SizedBox(height: 12),
              _buildShiftCard('수', '14', '14:00 - 20:00', '홀', '오늘', const Color(0xFFE8F5E9), const Color(0xFF5D8A66)),
              const SizedBox(height: 12),
              _buildShiftCard('금', '16', '10:00 - 16:00', '주방', '휴무 신청 중', const Color(0xFFFFF3E0), const Color(0xFFFF9800)),
              const SizedBox(height: 12),
              _buildShiftCard('토', '17', '16:00 - 22:00', '홀', '대타 확정', const Color(0xFFE8EAF6), const Color(0xFF5C6BC0)),
            ],
          ),

          // 하단 플로팅 버튼 (휴무/대타 신청)
          Positioned(
            bottom: 24,
            left: 24,
            right: 24,
            child: SizedBox(
              height: 56,
              child: ElevatedButton.icon(
                onPressed: () {
                  // 휴무 신청 화면으로 이동
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LeaveRequestScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.near_me_outlined, size: 22),
                label: const Text(
                  '휴무 · 대타 신청',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5D8A66),
                  foregroundColor: Colors.white,
                  elevation: 4,
                  shadowColor: Colors.black.withOpacity(0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 상단 주간 달력 요일 아이템 빌더
  Widget _buildDayItem(String day, String date, {bool isSelected = false, bool hasDot = false}) {
    return Container(
      width: 44,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF5D8A66) : Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Text(
            day,
            style: TextStyle(
              fontSize: 13,
              color: isSelected ? Colors.white70 : const Color(0xFF888888),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            date,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : const Color(0xFF222222),
            ),
          ),
          const SizedBox(height: 4),
          // 점(Dot) 표시 영역
          Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: hasDot
                  ? (isSelected ? Colors.white : const Color(0xFF5D8A66))
                  : Colors.transparent,
              shape: BoxShape.circle,
            ),
          )
        ],
      ),
    );
  }

  // 근무 일정 카드 빌더
  Widget _buildShiftCard(String day, String date, String time, String role, String badgeText, Color badgeBgColor, Color badgeTextColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 좌측 요일/날짜
          Column(
            children: [
              Text(day, style: const TextStyle(fontSize: 13, color: Color(0xFF888888))),
              const SizedBox(height: 2),
              Text(date, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF222222))),
            ],
          ),
          const SizedBox(width: 20),
          // 중앙 시간 및 장소
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$time · $role',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF222222)),
                ),
                const SizedBox(height: 4),
                const Text(
                  '카페 카푸치노',
                  style: TextStyle(fontSize: 13, color: Color(0xFF888888)),
                ),
              ],
            ),
          ),
          // 우측 상태 뱃지
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: badgeBgColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              badgeText,
              style: TextStyle(
                color: badgeTextColor,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}