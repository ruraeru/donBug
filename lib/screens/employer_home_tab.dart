import 'package:flutter/material.dart';

class EmployerHomeTab extends StatelessWidget {
  const EmployerHomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          // 상단 헤더 (매장명, 사장님 역할 및 날짜)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '카페 커푸치노',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF222222)),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '사장님 · 5/14(수)',
                    style: TextStyle(fontSize: 14, color: Color(0xFF888888)),
                  ),
                ],
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.notifications_none_rounded, size: 28),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // [메인 카드] 이번 달 예상 인건비 (초록색)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF5D8A66), // 메인 초록색
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '이번 달 예상 인건비',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                SizedBox(height: 8),
                Text(
                  '₩ 4,812,000',
                  style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 12),
                Text(
                  '지난달 대비 -3% · 근로자 5명',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // [서브 카드 2개] 오늘 근무 / 대타 모집
          Row(
            children: [
              // 오늘 근무 카드
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('오늘 근무', style: TextStyle(fontSize: 13, color: Color(0xFF888888))),
                      SizedBox(height: 8),
                      Text('3명', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF222222))),
                      SizedBox(height: 4),
                      Text('출근 2 · 대기 1', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF5D8A66))), // 초록 텍스트
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16), // 카드 사이 간격
              // 대타 모집 카드
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('대타 모집', style: TextStyle(fontSize: 13, color: Color(0xFF888888))),
                      SizedBox(height: 8),
                      Text('1건', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF222222))),
                      SizedBox(height: 4),
                      Text('지원자 2명', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFF57F17))), // 주황 텍스트
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // [경고 카드 1] 인력 공백 주의 (베이지색)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E1), // 연한 베이지/노란색
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        '인력 공백 주의',
                        style: TextStyle(color: Color(0xFFF57F17), fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const Text('5분 전', style: TextStyle(fontSize: 12, color: Color(0xFFAAAAAA))),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  '5/16(금) 10:00-16:00 주방',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF222222)),
                ),
                const SizedBox(height: 6),
                const Text(
                  '지민님이 휴무를 신청했어요 · 대타 지원 2명',
                  style: TextStyle(fontSize: 13, color: Color(0xFF666666)),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5D8A66),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('지원자 확인하고 확정', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // [경고 카드 2] 보건증 만료 알림 (연한 분홍색)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFFFEBEE), // 연한 분홍/빨간색
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        '보건증 D-12',
                        style: TextStyle(color: Color(0xFFE53935), fontSize: 12, fontWeight: FontWeight.bold), // 빨간 텍스트
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Color(0xFFE53935)),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  '수빈님 보건증이 곧 만료돼요',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF222222)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}