import 'package:flutter/material.dart';

class SalaryTab extends StatelessWidget {
  const SalaryTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          // 상단 타이틀 & 월 뱃지
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '급여',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF222222),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  '5월',
                  style: TextStyle(
                    color: Color(0xFF5D8A66),
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // [카드 1] 이번 달 예상 실수령액 (초록색 카드)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF5D8A66),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '이번 달 예상 실수령액',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                SizedBox(height: 12),
                Text(
                  '₩ 842,257',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  '급여일 5/25 · 누적 근무 62시간',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // [카드 2] 급여 내역 (상세 계산)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '급여 내역',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF222222),
                  ),
                ),
                const SizedBox(height: 16),
                _buildSalaryDetailRow('기본급 (62시간 × 10,320원)', '₩ 639,840'),
                const SizedBox(height: 12),
                _buildSalaryDetailRow('주휴수당', '₩ 231,160'),

                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                  child: Divider(color: Color(0xFFEEEEEE), height: 1),
                ),

                _buildSalaryDetailRow('총 급여', '₩ 871,000', isBold: true),
                const SizedBox(height: 12),
                _buildSalaryDetailRow('원천징수 (3.3%)', '-₩ 28,743', valueColor: const Color(0xFFE53935)), // 빨간색

                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                  child: Divider(color: Color(0xFFEEEEEE), height: 1),
                ),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '실수령액',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF222222),
                      ),
                    ),
                    const Text(
                      '₩ 842,257',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF5D8A66), // 초록색 강조
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // [카드 3] 최근 출퇴근 기록
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '최근 출퇴근 기록',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF222222),
                  ),
                ),
                const SizedBox(height: 20),
                _buildCommuteHistoryRow('5/12(월)', '14:02 - 20:01', '5.9h'),
                const SizedBox(height: 16),
                _buildCommuteHistoryRow('5/10(토)', '16:00 - 22:05', '6.1h'),
                const SizedBox(height: 16),
                _buildCommuteHistoryRow('5/09(금)', '10:01 - 16:00', '6.0h'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 급여 내역 행(Row) 생성 헬퍼 함수
  Widget _buildSalaryDetailRow(String title, String value, {Color? valueColor, bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 14, color: Color(0xFF666666)),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: valueColor ?? const Color(0xFF222222),
          ),
        ),
      ],
    );
  }

  // 출퇴근 기록 행(Row) 생성 헬퍼 함수
  Widget _buildCommuteHistoryRow(String date, String time, String hours) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        SizedBox(
          width: 70, // 날짜 영역 고정 너비
          child: Text(
            date,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF222222)),
          ),
        ),
        Expanded(
          child: Text(
            time,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: Color(0xFF888888)),
          ),
        ),
        SizedBox(
          width: 40, // 시간 영역 고정 너비
          child: Text(
            hours,
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF222222)),
          ),
        ),
      ],
    );
  }
}