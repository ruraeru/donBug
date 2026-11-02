import 'package:flutter/material.dart';

import '../../theme.dart';
import '../../widgets/common.dart';
import 'web_common.dart';

/// W1 사장님 웹 대시보드 (콘텐츠 영역).
class WebDashboardScreen extends StatelessWidget {
  const WebDashboardScreen({super.key, this.onWriteNotice});

  /// "+ 공지 작성" → 공지 관리 메뉴로 이동(WebShell 이 연결).
  final VoidCallback? onWriteNotice;

  @override
  Widget build(BuildContext context) => WebPage(
        title: '안녕하세요, 사장님',
        subtitle: '2026년 5월 14일 수요일',
        gap: 16,
        actions: [
          WebButton('+ 공지 작성', onPressed: onWriteNotice),
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border),
            ),
            child: Text('알림',
                style: AppText.style(11, FontWeight.w700, AppColors.textSecondary)),
          ),
        ],
        children: const [
          WebRow(children: [
            _Kpi('이번 달 예상 인건비', '₩ 4,812,000', '지난달 대비 -3% · 근로자 5명',
                bg: AppColors.primary, fg: AppColors.onPrimary),
            _Kpi('오늘 근무', '3명', '출근 2 · 대기 1'),
            _Kpi('대타 승인 대기', '2건', '수빈 · 하윤 요청', bg: AppColors.accentSoft),
            _Kpi('보건증 만료 임박', 'D-12', '수빈님 · 30·14·7일 전 알림',
                bg: AppColors.dangerSoft, valueColor: AppColors.danger),
          ]),
          WebSplit(
            breakpoint: 1000,
            left: _WeekCard(),
            right: Column(children: [
              _SubstituteCard(),
              SizedBox(height: 16),
              _RiskCard(),
            ]),
          ),
        ],
      );
}

class _Kpi extends StatelessWidget {
  const _Kpi(this.label, this.value, this.caption,
      {this.bg = AppColors.surface, this.fg, this.valueColor});

  final String label, value, caption;
  final Color bg;
  final Color? fg, valueColor;

  @override
  Widget build(BuildContext context) => AppCard(
        color: bg,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: AppText.style(13, FontWeight.w500, fg ?? AppColors.textSecondary)),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(value,
                  style: AppText.style(
                      28, FontWeight.w700, valueColor ?? fg ?? AppColors.textPrimary)),
            ),
            const SizedBox(height: 6),
            Text(caption,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.style(12, FontWeight.w400, fg ?? AppColors.textSecondary)),
          ],
        ),
      );
}

enum _S { soft, today, sub }

class _WeekCard extends StatelessWidget {
  const _WeekCard();

  static const _days = ['월 12', '화 13', '수 14', '목 15', '금 16', '토 17', '일 18'];

  // null = 빈칸. today 는 오늘(수) 열 강조, sub 는 대타.
  static const _rows = <(String, List<(String, _S)?>)>[
    ('지민', [('14–20', _S.soft), null, ('14–20', _S.today), ('14–20', _S.soft), null, ('10–16', _S.soft), null]),
    ('수빈', [('10–16', _S.soft), ('10–16', _S.soft), ('14–18 대타', _S.sub), null, ('10–16', _S.soft), null, ('10–16', _S.soft)]),
    ('하윤', [null, ('18–22', _S.soft), null, ('18–22', _S.soft), ('10–16 대타', _S.sub), ('18–22', _S.soft), null]),
    ('도현', [('18–22', _S.soft), null, ('18–22', _S.today), null, ('18–22', _S.soft), null, ('10–16', _S.soft)]),
    ('서연', [null, ('14–20', _S.soft), ('10–16', _S.today), null, ('14–20', _S.soft), ('10–16', _S.soft), null]),
  ];

  @override
  Widget build(BuildContext context) => AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(
                  child: Text('이번 주 근무표', style: AppText.style(17, FontWeight.w700))),
              Text('‹', style: AppText.style(18, FontWeight.w400, AppColors.textSecondary)),
              const SizedBox(width: 8),
              Text('5/12 – 5/18', style: AppText.style(13, FontWeight.w700)),
              const SizedBox(width: 8),
              Text('›', style: AppText.style(18, FontWeight.w400, AppColors.textSecondary)),
            ]),
            const SizedBox(height: 12),
            SizedBox(
              height: 30,
              child: Row(children: [
                const SizedBox(width: 84),
                for (final d in _days)
                  Expanded(
                    child: Center(
                      child: d == '수 14'
                          ? Pill(d,
                              color: AppColors.onPrimary,
                              background: AppColors.primary)
                          : Text(d,
                              style: AppText.style(
                                  12, FontWeight.w500, AppColors.textTertiary)),
                    ),
                  ),
              ]),
            ),
            for (final (name, cells) in _rows) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 48,
                child: Row(children: [
                  SizedBox(
                      width: 84,
                      child: Text(name, style: AppText.style(14, FontWeight.w700))),
                  for (final c in cells)
                    Expanded(
                      child: c == null
                          ? const SizedBox()
                          : Center(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: switch (c.$2) {
                                  _S.soft => WebTag(c.$1),
                                  _S.today => WebTag(c.$1,
                                      color: AppColors.onPrimary,
                                      background: AppColors.primary),
                                  _S.sub => WebTag(c.$1,
                                      color: AppColors.accent,
                                      background: AppColors.accentSoft),
                                },
                              ),
                            ),
                    ),
                ]),
              ),
            ],
            const SizedBox(height: 18),
            const Wrap(spacing: 14, children: [
              _Legend(AppColors.primarySoft, '근무'),
              _Legend(AppColors.accentSoft, '대타 모집·승인 대기'),
            ]),
          ],
        ),
      );
}

class _Legend extends StatelessWidget {
  const _Legend(this.color, this.label);

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 12,
          height: 12,
          decoration:
              BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
        ),
        const SizedBox(width: 6),
        Text(label, style: AppText.style(12, FontWeight.w400, AppColors.textSecondary)),
      ]);
}

class _SubstituteCard extends StatelessWidget {
  const _SubstituteCard();

  @override
  Widget build(BuildContext context) => AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(
                  child: Text('대타 승인 대기', style: AppText.style(15, FontWeight.w700))),
              Text('전체 보기 ›',
                  style: AppText.style(12, FontWeight.w500, AppColors.primary)),
            ]),
            const SizedBox(height: 12),
            const _SubItem('5/14(수) 18:00–22:00', '수빈 → 지민 수락', '승인', true),
            const SizedBox(height: 12),
            const _SubItem('5/16(금) 10:00–16:00', '하윤 · 동료 응답 대기', '재알림', false),
          ],
        ),
      );
}

class _SubItem extends StatelessWidget {
  const _SubItem(this.title, this.caption, this.action, this.primary);

  final String title, caption, action;
  final bool primary;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
            color: AppColors.bg, borderRadius: BorderRadius.circular(14)),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: AppText.style(13, FontWeight.w700)),
              Text(caption,
                  style: AppText.style(12, FontWeight.w400, AppColors.textSecondary)),
            ]),
          ),
          const SizedBox(width: 10),
          WebTag(
            action,
            color: primary ? AppColors.onPrimary : AppColors.textSecondary,
            background: primary ? AppColors.primary : AppColors.surface,
            border: primary ? null : AppColors.border,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          ),
        ]),
      );
}

class _RiskCard extends StatelessWidget {
  const _RiskCard();

  @override
  Widget build(BuildContext context) => AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('노무 리스크 알림', style: AppText.style(15, FontWeight.w700)),
            const SizedBox(height: 12),
            const _Risk(AppColors.danger, AppColors.dangerSoft, '보건증 만료 D-12',
                '수빈님 · 갱신 후 사진 등록 필요'),
            const SizedBox(height: 12),
            const _Risk(AppColors.accent, AppColors.accentSoft, '전자 근로계약서 미서명 1건',
                '서연님 · 서명 요청 보내기'),
            const SizedBox(height: 12),
            const _Risk(AppColors.info, AppColors.infoSoft, '5인 미만 체크리스트 3/5 완료',
                '가산수당 미적용 설정 확인됨'),
          ],
        ),
      );
}

class _Risk extends StatelessWidget {
  const _Risk(this.color, this.soft, this.title, this.caption);

  final Color color, soft;
  final String title, caption;

  @override
  Widget build(BuildContext context) => Row(children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: soft,
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: AppText.style(13, FontWeight.w700)),
            Text(caption,
                style: AppText.style(12, FontWeight.w400, AppColors.textSecondary)),
          ]),
        ),
      ]);
}
