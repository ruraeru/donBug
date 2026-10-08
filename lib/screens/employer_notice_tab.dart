import 'package:flutter/material.dart';

class EmployerNoticeTab extends StatefulWidget {
  const EmployerNoticeTab({super.key});

  @override
  State<EmployerNoticeTab> createState() => _EmployerNoticeTabState();
}

class _EmployerNoticeTabState extends State<EmployerNoticeTab> {
  // 사진과 동일하게 초기 텍스트를 미리 채워둡니다.
  final TextEditingController _titleController = TextEditingController(text: '5월 마감 청소 안내');
  final TextEditingController _contentController = TextEditingController(
      text: '이번 주부터 마감 조는 음료 머신 세척까지 부탁드려요. 체크리스트는 사물함 옆에 붙여두었어요.');

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          // 상단 타이틀 & 뱃지
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '공지',
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
                  '새 공지',
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

          // [카드 1] 공지 작성 영역
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
                // 제목 입력 필드
                TextField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFFF5F6F8), // 연한 회색 배경
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    hintText: '공지 제목',
                  ),
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF222222)),
                ),
                const SizedBox(height: 12),

                // 내용 입력 필드
                TextField(
                  controller: _contentController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFFF5F6F8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    hintText: '공지 내용',
                  ),
                  style: const TextStyle(fontSize: 14, color: Color(0xFF444444), height: 1.5),
                ),
                const SizedBox(height: 20),

                // 발송 대상 안내
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '발송 대상',
                      style: TextStyle(fontSize: 13, color: Color(0xFF888888)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        '전체 근로자 5명',
                        style: TextStyle(
                          color: Color(0xFF5D8A66),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 전체 발송 버튼
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      // TODO: 공지 발송 로직
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
                      '전체 발송',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // [카드 2] 최근 공지 리스트
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
                  '최근 공지',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF222222),
                  ),
                ),
                const SizedBox(height: 16),

                // 공지 리스트 항목들
                _buildRecentNoticeRow(
                  title: '5/12 휴게시간 변경 안내',
                  date: '어제',
                  readBadgeText: '읽음 5/5',
                  isAllRead: true, // 모두 읽음 (초록색)
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                  child: Divider(color: Color(0xFFEEEEEE), height: 1),
                ),
                _buildRecentNoticeRow(
                  title: '신메뉴 레시피 교육',
                  date: '5/10',
                  readBadgeText: '읽음 4/5',
                  isAllRead: false, // 덜 읽음 (주황색)
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // 최근 공지 행(Row) 헬퍼 함수
  Widget _buildRecentNoticeRow({
    required String title,
    required String date,
    required String readBadgeText,
    required bool isAllRead,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 공지 제목 & 날짜
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF222222),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              date,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFFAAAAAA),
              ),
            ),
          ],
        ),
        // 읽음 상태 뱃지
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isAllRead ? const Color(0xFFE8F5E9) : const Color(0xFFFFF8E1), // 초록 vs 주황 배경
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            readBadgeText,
            style: TextStyle(
              color: isAllRead ? const Color(0xFF5D8A66) : const Color(0xFFF57F17), // 초록 vs 주황 텍스트
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}