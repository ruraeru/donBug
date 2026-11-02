import 'package:flutter/material.dart';

import '../../theme.dart';
import '../../widgets/common.dart';
import 'employer_widgets.dart';
import 'notice_read_status_screen.dart';

enum NoticeResult { published, reminded }

/// 공지 발행 완료 / 리마인드 발송 완료.
class NoticeResultScreen extends StatelessWidget {
  const NoticeResultScreen(this.result, {super.key});

  final NoticeResult result;

  @override
  Widget build(BuildContext context) {
    final published = result == NoticeResult.published;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: Column(
            children: [
              const SizedBox(height: 28),
              Container(
                width: 96,
                height: 96,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.primarySoft,
                  shape: BoxShape.circle,
                ),
                child: Text('✓',
                    style: AppText.style(44, FontWeight.w700, AppColors.primary)),
              ),
              const SizedBox(height: 12),
              Text(
                published ? '공지를 발송했어요' : '리마인드를 보냈어요',
                textAlign: TextAlign.center,
                style: AppText.style(22, FontWeight.w700),
              ),
              const SizedBox(height: 12),
              Text(
                published
                    ? '직원 5명에게 푸시 알림을 보냈어요'
                    : '아직 확인하지 않은 하윤, 서연님께만 알림이 갔어요',
                textAlign: TextAlign.center,
                style: AppText.style(15, FontWeight.w400, AppColors.textSecondary),
              ),
              const SizedBox(height: 24),
              published ? const _NoticeCard() : const _RemindCard(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomBar(children: [
        AppButton(
          published ? '확인 현황 보기' : '공지 목록으로',
          // 완료 화면은 스택에 남기지 않는다: 현황은 교체, 목록은 pop.
          onPressed: published
              ? () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const NoticeReadStatusScreen()),
                  )
              : () => Navigator.pop(context),
        ),
      ]),
    );
  }
}

class _NoticeCard extends StatelessWidget {
  const _NoticeCard();

  @override
  Widget build(BuildContext context) => AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Pill('필독',
                    color: EmpColors.danger, background: EmpColors.dangerSoft),
                const SizedBox(width: 8),
                Text('방금 전',
                    style: AppText.style(
                        12, FontWeight.w400, AppColors.textTertiary)),
              ],
            ),
            const SizedBox(height: 10),
            Text('5월 마감 청소 방법 안내', style: AppText.style(17, FontWeight.w700)),
            const SizedBox(height: 10),
            Text(
              '5월부터 마감 근무자는 아래 순서로 청소해 주세요.',
              style: AppText.style(13, FontWeight.w400, AppColors.textSecondary),
            ),
          ],
        ),
      );
}

class _RemindCard extends StatelessWidget {
  const _RemindCard();

  @override
  Widget build(BuildContext context) => const AppCard(
        child: Column(
          children: [
            KeyValueRow('발송 대상', '2명'),
            SizedBox(height: 14),
            KeyValueRow('발송 방식', '푸시 알림 (FCM)'),
            SizedBox(height: 14),
            KeyValueRow('다음 자동 리마인드', '내일 09:00'),
          ],
        ),
      );
}
