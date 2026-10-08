import 'package:flutter/material.dart';

class DocumentTab extends StatelessWidget {
  const DocumentTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          // 상단 타이틀
          const Text(
            '서류 · 컴플라이언스',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF222222),
            ),
          ),
          const SizedBox(height: 24),

          // [카드 1] 노무 체크리스트
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
                // 카드 헤더 (타이틀 + 사업장 규모 뱃지)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '노무 체크리스트',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF222222),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8EAF6), // 연한 남색 배경
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        '5인 미만 사업장',
                        style: TextStyle(
                          color: Color(0xFF5C6BC0),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 체크리스트 항목들
                _buildChecklistItem(Icons.check, const Color(0xFF5D8A66), '근로계약서 작성 · 교부'),
                _buildDivider(),
                _buildChecklistItem(Icons.check, const Color(0xFF5D8A66), '최저임금 준수 (시급 10,320원)'),
                _buildDivider(),
                _buildChecklistItem(Icons.check, const Color(0xFF5D8A66), '주휴수당 지급'),
                _buildDivider(),
                _buildChecklistItem(Icons.error_outline, const Color(0xFFE53935), '보건증 갱신 필요 · 1명', isAlert: true), // 경고 항목
              ],
            ),
          ),
          const SizedBox(height: 16),

          // [카드 2] 근로자별 서류 상태
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
                  '근로자별 서류',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF222222),
                  ),
                ),
                const SizedBox(height: 16),

                // 직원별 서류 상태 리스트
                _buildWorkerDocumentRow('지민', '계약서 완료', '보건증 정상', isAlertBadge2: false),
                _buildDivider(),
                _buildWorkerDocumentRow('수빈', '계약서 완료', '보건증 D-12', isAlertBadge2: true), // 보건증 만료 임박
                _buildDivider(),
                _buildWorkerDocumentRow('현우', '계약서 완료', '보건증 정상', isAlertBadge2: false),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 하단 버튼 (전자 근로계약서 작성)
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () {
                // TODO: 근로계약서 작성 화면으로 이동
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5D8A66),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                '전자 근로계약서 작성',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // 체크리스트 행(Row) 생성 헬퍼 함수
  Widget _buildChecklistItem(IconData icon, Color iconColor, String text, {bool isAlert = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 12),
          Text(
            text,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isAlert ? FontWeight.bold : FontWeight.w500,
              color: isAlert ? const Color(0xFFE53935) : const Color(0xFF444444), // 경고면 빨간색, 정상은 짙은 회색
            ),
          ),
        ],
      ),
    );
  }

  // 구분선 생성 헬퍼 함수
  Widget _buildDivider() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 12.0),
      child: Divider(color: Color(0xFFEEEEEE), height: 1),
    );
  }

  // 직원별 서류 뱃지 행(Row) 생성 헬퍼 함수
  Widget _buildWorkerDocumentRow(String name, String badge1, String badge2, {required bool isAlertBadge2}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          name,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF222222)),
        ),
        Row(
          children: [
            // 첫 번째 뱃지 (계약서 상태 - 회색)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                badge1,
                style: const TextStyle(color: Color(0xFF888888), fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 8),
            // 두 번째 뱃지 (보건증 상태 - 정상: 초록 / 경고: 빨강)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isAlertBadge2 ? const Color(0xFFFFEBEE) : const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                badge2,
                style: TextStyle(
                  color: isAlertBadge2 ? const Color(0xFFE53935) : const Color(0xFF5D8A66),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}