import 'package:flutter/material.dart';

import '../../theme.dart';
import '../../widgets/common.dart';
import 'web_common.dart';

/// W8 POS 동적 QR / W9 POS 출근 완료(전체 화면). [checkedIn] 이면 W9:
/// QR 흐리게 + 출근 완료 토스트.
class WebPosQrScreen extends StatelessWidget {
  const WebPosQrScreen({super.key, this.checkedIn = false});

  final bool checkedIn;

  // (이름, 상태, 글자색, 배경)
  static const _today = [
    ('지민', '10:00 출근', AppColors.primary, AppColors.primarySoft),
    ('수빈', '10:12 출근 · 지각', WebColors.danger, WebColors.dangerSoft),
    ('태우', '14:02 출근', WebColors.info, WebColors.infoSoft),
  ];

  @override
  Widget build(BuildContext context) {
    final qr = Opacity(
      opacity: checkedIn ? 0.35 : 1,
      child: Container(
        width: 380,
        height: 380,
        decoration: BoxDecoration(
            color: AppColors.surface, borderRadius: BorderRadius.circular(28)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('QR', style: AppText.style(64, FontWeight.w700, AppColors.textTertiary)),
            const SizedBox(height: 8),
            Text('동적 QR 코드',
                style: AppText.style(14, FontWeight.w400, AppColors.textTertiary)),
          ],
        ),
      ),
    );

    return Scaffold(
      backgroundColor: AppColors.textPrimary,
      body: SafeArea(
        child: Stack(fit: StackFit.expand, children: [
          Column(children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 36),
              child: Row(children: [
                // 디자인에 닫기 버튼이 없어 로고 탭으로 POS 모드를 빠져나간다.
                GestureDetector(
                  onTap: () => Navigator.of(context).popUntil((r) => r.isFirst),
                  child: Row(children: [
                    Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(12)),
                      child: Text('₩',
                          style: AppText.style(18, FontWeight.w700, AppColors.onPrimary)),
                    ),
                    const SizedBox(width: 12),
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('카페 커푸치노',
                          style: AppText.style(18, FontWeight.w700, AppColors.surface)),
                      Text('매장 POS · 출퇴근 인증',
                          style: AppText.style(
                              12, FontWeight.w400, AppColors.textTertiary)),
                    ]),
                  ]),
                ),
                const Spacer(),
                Text('14:02', style: AppText.style(32, FontWeight.w700, AppColors.surface)),
              ]),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(48, 0, 48, 48),
                child: Center(
                  child: Wrap(
                    spacing: 48,
                    runSpacing: 48,
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: checkedIn
                            ? null
                            : () => Navigator.of(context).push(MaterialPageRoute(
                                builder: (_) => const WebPosQrScreen(checkedIn: true))),
                        child: Column(mainAxisSize: MainAxisSize.min, children: [
                          qr,
                          const SizedBox(height: 22),
                          Text('스마트폰으로 QR을 스캔해 출퇴근을 기록하세요',
                              textAlign: TextAlign.center,
                              style: AppText.style(22, FontWeight.w700, AppColors.surface)),
                          const SizedBox(height: 22),
                          Row(mainAxisSize: MainAxisSize.min, children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: const BoxDecoration(
                                  color: AppColors.primary, shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 10),
                            Text('18초 후 QR이 자동으로 바뀌어요',
                                style: AppText.style(
                                    15, FontWeight.w400, AppColors.textTertiary)),
                          ]),
                        ]),
                      ),
                      Container(
                        width: 380,
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(24)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('오늘 출근 현황', style: AppText.style(16, FontWeight.w700)),
                            for (final (name, status, fg, bg) in _today) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                    color: AppColors.bg,
                                    borderRadius: BorderRadius.circular(12)),
                                child: Row(children: [
                                  Expanded(
                                      child: Text(name,
                                          style: AppText.style(14, FontWeight.w700))),
                                  Pill(status, color: fg, background: bg),
                                ]),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ]),
          if (checkedIn)
            Positioned(
              top: 96,
              left: 0,
              right: 0,
              child: const Center(child: _CheckedInToast()),
            ),
        ]),
      ),
    );
  }
}

class _CheckedInToast extends StatelessWidget {
  const _CheckedInToast();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
        decoration: BoxDecoration(
            color: AppColors.primary, borderRadius: BorderRadius.circular(20)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration:
                const BoxDecoration(color: AppColors.surface, shape: BoxShape.circle),
            child: Text('✓', style: AppText.style(18, FontWeight.w700, AppColors.primary)),
          ),
          const SizedBox(width: 14),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('태우님 출근 완료',
                style: AppText.style(18, FontWeight.w700, AppColors.onPrimary)),
            Text('14:02 · QR 인증 · 정상 출근',
                style: AppText.style(13, FontWeight.w400, AppColors.onPrimary)),
          ]),
        ]),
      );
}
