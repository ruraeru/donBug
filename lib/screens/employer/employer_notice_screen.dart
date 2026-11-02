import 'package:flutter/material.dart';

import '../../theme.dart';
import '../../widgets/common.dart';
import 'notice_read_status_screen.dart';
import 'notice_result_screen.dart';

/// B3 공지 작성 (사장님 공지 탭 루트).
class EmployerNoticeScreen extends StatelessWidget {
  const EmployerNoticeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    void openStatus() => Navigator.push(context,
        MaterialPageRoute(builder: (_) => const NoticeReadStatusScreen()));

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                Expanded(
                    child: Text('공지', style: AppText.style(24, FontWeight.w700))),
                const Pill('새 공지'),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: Column(
                children: [
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Input(
                          initialValue: '5월 마감 청소 안내',
                          style: AppText.style(16, FontWeight.w700),
                        ),
                        const SizedBox(height: 12),
                        _Input(
                          initialValue:
                              '이번 주부터 마감 조는 음료 머신 세척까지 부탁드려요. 체크리스트는 사물함 옆에 붙여두었어요.',
                          style: AppText.style(14).copyWith(height: 1.5),
                          maxLines: null,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '발송 대상',
                                style: AppText.style(13, FontWeight.w500,
                                    AppColors.textSecondary),
                              ),
                            ),
                            const Pill('전체 근로자 5명'),
                          ],
                        ),
                        const SizedBox(height: 12),
                        AppButton(
                          '전체 발송',
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const NoticeResultScreen(
                                  NoticeResult.published),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('최근 공지', style: AppText.style(15, FontWeight.w700)),
                        const SizedBox(height: 12),
                        _NoticeRow(
                          title: '5/12 휴게시간 변경 안내',
                          date: '어제',
                          chip: const Pill('읽음 5/5'),
                          onTap: openStatus,
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Divider(height: 1, color: AppColors.border),
                        ),
                        _NoticeRow(
                          title: '신메뉴 레시피 교육',
                          date: '5/10',
                          chip: const Pill.accent('읽음 4/5'),
                          onTap: openStatus,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Input extends StatelessWidget {
  const _Input({required this.initialValue, required this.style, this.maxLines = 1});

  final String initialValue;
  final TextStyle style;
  final int? maxLines;

  @override
  Widget build(BuildContext context) => TextFormField(
        initialValue: initialValue,
        style: style,
        maxLines: maxLines,
        decoration: InputDecoration(
          isDense: true,
          filled: true,
          fillColor: AppColors.bg,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      );
}

class _NoticeRow extends StatelessWidget {
  const _NoticeRow({
    required this.title,
    required this.date,
    required this.chip,
    this.onTap,
  });

  final String title;
  final String date;
  final Widget chip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: AppText.style(14, FontWeight.w700),
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(date,
                      style: AppText.style(
                          12, FontWeight.w400, AppColors.textTertiary)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            chip,
          ],
        ),
      );
}
