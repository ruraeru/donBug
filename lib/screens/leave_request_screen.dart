// lib/screens/leave_request_screen.dart
import 'package:flutter/material.dart';

class LeaveRequestScreen extends StatefulWidget {
  const LeaveRequestScreen({super.key});

  @override
  State<LeaveRequestScreen> createState() => _LeaveRequestScreenState();
}

class _LeaveRequestScreenState extends State<LeaveRequestScreen> {
  final TextEditingController _reasonController = TextEditingController(text: '치과 진료 예약이 있어서 근무가 어려워요. 대타 구해지면 알려주세요.');
  bool _sendAlarmToColleagues = true;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8), // 전체 배경색
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F6F8),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF222222)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '휴무 신청',
          style: TextStyle(
            color: Color(0xFF222222),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
        titleSpacing: 0, // 뒤로가기 버튼과 타이틀 사이 간격 좁히기
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(24.0),
                children: [
                  // 휴무할 근무
                  const Text(
                    '휴무할 근무',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF666666)),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9).withOpacity(0.5), // 연한 초록 배경
                      border: Border.all(color: const Color(0xFF5D8A66), width: 1), // 초록 테두리
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '5/16(금) 10:00 - 16:00',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF222222)),
                            ),
                            SizedBox(height: 4),
                            Text(
                              '주방 · 6시간',
                              style: TextStyle(fontSize: 13, color: Color(0xFF888888)),
                            ),
                          ],
                        ),
                        const Icon(Icons.check_rounded, color: Color(0xFF5D8A66), size: 28),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 사유 입력
                  const Text(
                    '사유',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF666666)),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: TextField(
                      controller: _reasonController,
                      maxLines: 5, // 여러 줄 입력 가능
                      maxLength: 200, // 최대 글자 수
                      decoration: const InputDecoration(
                        hintText: '사유를 입력해주세요.',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(20),
                        counterStyle: TextStyle(color: Color(0xFFAAAAAA), fontSize: 12),
                      ),
                      style: const TextStyle(fontSize: 15, color: Color(0xFF222222), height: 1.5),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 동료에게 대타 알림 보내기 스위치
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '동료에게 대타 알림 보내기',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF222222)),
                            ),
                            SizedBox(height: 4),
                            Text(
                              '같은 매장 근로자 5명에게 전송',
                              style: TextStyle(fontSize: 12, color: Color(0xFFAAAAAA)),
                            ),
                          ],
                        ),
                        // 커스텀 색상 스위치
                        Switch(
                          value: _sendAlarmToColleagues,
                          onChanged: (value) {
                            setState(() {
                              _sendAlarmToColleagues = value;
                            });
                          },
                          activeColor: Colors.white,
                          activeTrackColor: const Color(0xFF5D8A66),
                          inactiveThumbColor: Colors.white,
                          inactiveTrackColor: const Color(0xFFE0E0E0),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 하단 안내 메시지
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8EAF6), // 연한 파란색 배경
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      '신청하면 사장님께도 알림이 가요. 대타가 확정되면 근무표가 자동으로 바뀝니다.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF5C6BC0), // 파란 텍스트
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 하단 고정 완료 버튼
            Container(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24), // SafeArea를 고려한 여백
              color: Colors.white, // 바닥쪽은 흰색 배경
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    // 완료 버튼 로직
                    Navigator.pop(context); // 임시로 다시 근무표로 돌아가기
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5D8A66),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    '휴무 신청하고 대타 구하기',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}