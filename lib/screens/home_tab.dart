import 'package:flutter/material.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('안녕하세요, 지민님', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF222222))),
                  SizedBox(height: 4),
                  Text('카페 카푸치노 · 알바생', style: TextStyle(fontSize: 14, color: Color(0xFF888888))),
                ],
              ),
              IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_none_rounded, size: 28)),
            ],
          ),
          const SizedBox(height: 24),
          // 오늘 근무 카드
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: const Color(0xFF5D8A66), borderRadius: BorderRadius.circular(20)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('오늘 근무', style: TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 8),
                const Text('14:00 - 20:00', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                const Text('6시간 · 홀 서빙 · 휴게 30분', style: TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.qr_code_scanner, size: 20),
                    label: const Text('출근하기', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF5D8A66),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Center(child: Text('매장 POS의 QR 코드 또는 NFC 스티커를 태그하세요', style: TextStyle(color: Colors.white60, fontSize: 12))),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // 예상 실수령액 카드
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('이번 달 예상 실수령액', style: TextStyle(fontSize: 14, color: Color(0xFF666666), fontWeight: FontWeight.w600)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(20)),
                      child: const Text('세후 반영', style: TextStyle(color: Color(0xFF5D8A66), fontSize: 12, fontWeight: FontWeight.bold)),
                    )
                  ],
                ),
                const SizedBox(height: 16),
                const Text('₩ 842,257', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF222222))),
                const SizedBox(height: 12),
                const Text('근무 62시간 · 세금 3.3% 반영 · 지난달보다 +12%', style: TextStyle(fontSize: 13, color: Color(0xFF888888))),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // 대타 구해요 카드
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: const Color(0xFFFFF8E1), borderRadius: BorderRadius.circular(20)),
                      child: const Text('대타 구해요', style: TextStyle(color: Color(0xFFF57F17), fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                    const Text('방금 전', style: TextStyle(fontSize: 12, color: Color(0xFFAAAAAA)))
                  ],
                ),
                const SizedBox(height: 12),
                const Text('5/14(수) 18:00 - 22:00', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF222222))),
                const SizedBox(height: 8),
                const Text('수빈님이 대타를 찾고 있어요 · 사유: 병원 진료', style: TextStyle(fontSize: 13, color: Color(0xFF666666))),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: TextButton(
                    onPressed: () {},
                    style: TextButton.styleFrom(
                      backgroundColor: const Color(0xFFEFEFEF),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('지원하기', style: TextStyle(color: Color(0xFF5D8A66), fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}