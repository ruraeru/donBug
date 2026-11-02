import 'package:flutter/material.dart';

import '../../theme.dart';
import '../../widgets/common.dart';
import 'employee_widgets.dart';

/// 공지 상세.
class NoticeDetailScreen extends StatelessWidget {
  const NoticeDetailScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: const AppHeader('공지'),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          children: [
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Pill('필독', color: kDanger, background: kDangerSoft),
                      const SizedBox(width: 8),
                      Text('5/12 · 사장님',
                          style: AppText.style(12, FontWeight.w400, AppColors.textTertiary)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text('5월 마감 청소 방법 안내', style: AppText.style(20, FontWeight.w700)),
                  const SizedBox(height: 12),
                  const Divider(height: 1, color: AppColors.border),
                  const SizedBox(height: 12),
                  Text(
                    '5월부터 마감 근무자는 아래 순서로 청소해 주세요.\n\n'
                    '1. 에스프레소 머신 세척 및 그룹 헤드 청소\n'
                    '2. 홀 바닥 · 테이블 소독\n'
                    '3. 쓰레기 분리배출 후 마감 체크리스트 작성\n\n'
                    '체크리스트는 앱 공지 하단에서 확인할 수 있어요.',
                    style: AppText.style(15).copyWith(height: 1.6),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            AppCard(
              child: Row(
                children: [
                  Expanded(
                    child: Text('확인 현황',
                        style: AppText.style(14, FontWeight.w700, AppColors.textSecondary)),
                  ),
                  Text('3 / 5명', style: AppText.style(14, FontWeight.w700, AppColors.primary)),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: BottomBar(
          child: AppButton('확인했어요 (필독)', onPressed: () => Navigator.pop(context)),
        ),
      );
}
