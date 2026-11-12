import 'package:flutter/material.dart';

import '../../data/app_scope.dart';
import '../../data/format.dart';
import '../../data/models.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import 'notice_read_status_screen.dart';

enum NoticeResult { published, reminded }

/// 공지 발행 완료 / 리마인드 발송 완료.
class NoticeResultScreen extends StatelessWidget {
  const NoticeResultScreen(this.result,
      {super.key, required this.noticeId, this.remindedNames = const []});

  final NoticeResult result;
  final String noticeId;

  /// 리마인드를 받은 직원 이름.
  final List<String> remindedNames;

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final n = store.noticeById(noticeId);
    if (n == null) return const MissingScreen();
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
                    style: AppText.style(44, FontWeight.w500, AppColors.primary)),
              ),
              const SizedBox(height: 12),
              Text(
                published ? '공지를 발송했어요' : '리마인드를 보냈어요',
                textAlign: TextAlign.center,
                style: AppText.style(22, FontWeight.w500),
              ),
              const SizedBox(height: 12),
              Text(
                published
                    ? '직원 ${store.activeStaff.length}명에게 알림을 보냈어요'
                    : '아직 확인하지 않은 ${remindedNames.join(', ')}님께만 알림이 갔어요',
                textAlign: TextAlign.center,
                style: AppText.style(15, FontWeight.w400, AppColors.textSecondary),
              ),
              const SizedBox(height: 24),
              published
                  ? _NoticeCard(notice: n, now: store.now)
                  : _RemindCard(count: remindedNames.length),
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
                        builder: (_) => NoticeReadStatusScreen(noticeId: noticeId)),
                  )
              : () => Navigator.pop(context),
        ),
      ]),
    );
  }
}

class _NoticeCard extends StatelessWidget {
  const _NoticeCard({required this.notice, required this.now});

  final Notice notice;
  final DateTime now;

  @override
  Widget build(BuildContext context) => AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (notice.required) ...[
                  const Pill('필독', color: AppColors.danger, background: AppColors.dangerSoft),
                  const SizedBox(width: 8),
                ],
                Text(relative(DateTime.parse(notice.createdAt), now),
                    style: AppText.style(12, FontWeight.w400, AppColors.textTertiary)),
              ],
            ),
            const SizedBox(height: 10),
            Text(notice.title, style: AppText.style(17, FontWeight.w500)),
            const SizedBox(height: 10),
            Text(notice.body,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: AppText.style(13, FontWeight.w400, AppColors.textSecondary)),
          ],
        ),
      );
}

class _RemindCard extends StatelessWidget {
  const _RemindCard({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) => AppCard(
        child: Column(
          children: [
            KeyValueRow('발송 대상', '$count명'),
            const SizedBox(height: 14),
            const KeyValueRow('발송 방식', '앱 알림 (데모: 알림 센터)'),
          ],
        ),
      );
}
