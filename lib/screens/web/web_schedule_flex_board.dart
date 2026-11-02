import 'package:flutter/material.dart';

import '../../theme.dart';
import '../../widgets/common.dart';
import 'web_schedule_common.dart';
import 'web_common.dart';

/// W2-E 유동 스케줄 보드 (Figma 57:846).
/// 금요일 '0 / 1 부족' 칸을 누르면 오픈 배정 팝오버가 열린다.
class WebScheduleFlexBoard extends StatefulWidget {
  const WebScheduleFlexBoard({super.key});

  @override
  State<WebScheduleFlexBoard> createState() => _WebScheduleFlexBoardState();
}

class _WebScheduleFlexBoardState extends State<WebScheduleFlexBoard> {
  static const _nameW = 107.0;
  static const _cellW = 86.0;
  static const _cellH = 48.0;
  static const _gap = 6.0;

  /// 지민만 대타 구함 · 휴무 신청이 들어간 주. 나머지는 W2-C와 같다.
  static final _codes = [
    ['10:00', '10:30', 'S', 'X2', 'R', 'C', 'X3'],
    ...webWeekCodes.skip(1),
  ];

  static const _candidates = [
    (2, '가용 · 이번 주 오픈 1회', true),
    (4, '가용 · 이번 주 휴무 누적 2회', true),
    (3, '휴무 신청 중 · 불가', false),
  ];

  static const _requests = [
    ('서연 · 목 휴무 신청', '사유: 시험 · 신청 5/11', false),
    ('지민 · 금 휴무 신청', '사유: 병원 · 신청 5/12', false),
    ('수빈 · 수 대타 요청', '지원자 1명 (하윤)', true),
  ];

  bool _showAssign = true;

  int _count(int day, String code) =>
      _codes.where((row) => row[day] == code).length;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const WebScheduleHeader(
            subtitle: 'E · 유동 스케줄 — 휴무 신청과 대타를 반영해 빈 오픈·마감을 채우기',
            action: '임시 저장',
          ),
          const SizedBox(height: 16),
          const WebScheduleToolbar(
            dateLabel: '5/12 – 5/18',
            modes: ['주간', '월간'],
            selectedMode: 0,
            chips: [
              WebGreyChip('휴무 칸의 숫자 = 월 누적 휴무'),
              WebGreyChip('직원 5명 · 고정 파트 3명'),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: AppCard(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: _board(),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(width: 300, child: _requestPanel()),
            ],
          ),
        ],
      );

  Widget _board() => Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const SizedBox(width: _nameW),
                for (var d = 0; d < 7; d++) _dayHeader(d),
              ]),
              for (var i = 0; i < webStaff.length; i++) _staffRow(i),
              const SizedBox(height: 8),
              _needRow('필요 오픈 1', 'O'),
              _needRow('필요 마감 1', 'C'),
            ],
          ),
          if (_showAssign)
            Positioned(left: 341, top: 113, width: 328, child: _assignPopover()),
        ],
      );

  Widget _dayHeader(int d) {
    final weekend = webWeekendColors(d);
    return Container(
      width: _cellW,
      height: _cellH,
      margin: const EdgeInsets.only(right: _gap, bottom: 9),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: weekend?.$1 ?? AppColors.surface,
        border: weekend == null ? Border.all(color: AppColors.border) : null,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text('${webWeekdays[d]} ${12 + d}',
          style: AppText.style(14, FontWeight.w700, weekend?.$2 ?? AppColors.textPrimary)),
    );
  }

  Widget _staffRow(int i) => Padding(
        padding: const EdgeInsets.only(bottom: _gap),
        child: Row(
          children: [
            SizedBox(
              width: _nameW,
              child: Row(
                children: [
                  StaffAvatar(webStaff[i], size: 30),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(webStaff[i].name, style: AppText.style(13, FontWeight.w700)),
                      Text('가용 유동',
                          style: AppText.style(10, FontWeight.w400, AppColors.textTertiary)),
                    ],
                  ),
                ],
              ),
            ),
            for (final c in _codes[i])
              Padding(
                padding: const EdgeInsets.only(right: _gap),
                child: WebShiftCell(
                  c,
                  width: _cellW,
                  height: _cellH,
                  showRange: false,
                  circleBadge: false,
                  fontSize: 12,
                ),
              ),
          ],
        ),
      );

  Widget _needRow(String label, String code) => Padding(
        padding: const EdgeInsets.only(bottom: _gap),
        child: Row(
          children: [
            SizedBox(
              width: _nameW,
              child: Text(label,
                  style: AppText.style(11, FontWeight.w700, AppColors.textSecondary)),
            ),
            for (var d = 0; d < 7; d++) _needCell(_count(d, code)),
          ],
        ),
      );

  Widget _needCell(int have) {
    final short = have < 1;
    return GestureDetector(
      onTap: short ? () => setState(() => _showAssign = !_showAssign) : null,
      child: Container(
        width: _cellW,
        height: 34,
        margin: const EdgeInsets.only(right: _gap),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: short ? AppColors.dangerSoft : AppColors.primarySoft,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          short ? '$have / 1 부족' : '$have / 1',
          style: AppText.style(
              13, FontWeight.w700, short ? AppColors.danger : AppColors.primary),
        ),
      ),
    );
  }

  Widget _assignPopover() => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.primary, width: 2),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('금 5/16 · 오픈 배정', style: AppText.style(14, FontWeight.w700)),
                  Text('07:00–16:00 · 가용한 직원만 표시',
                      style: AppText.style(11, FontWeight.w400, AppColors.textSecondary)),
                ],
              ),
            ),
            for (final (staff, note, ok) in _candidates) ...[
              const SizedBox(height: 8),
              Opacity(
                opacity: ok ? 1 : 0.6,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.bg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      StaffAvatar(webStaff[staff], size: 26),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(webStaff[staff].name,
                                style: AppText.style(13, FontWeight.w700,
                                    ok ? AppColors.textPrimary : AppColors.textTertiary)),
                            Text(note,
                                style: AppText.style(10, FontWeight.w400,
                                    ok ? AppColors.textSecondary : AppColors.danger)),
                          ],
                        ),
                      ),
                      if (ok)
                        WebButton(
                          '배정',
                          height: 26,
                          fontSize: 12,
                          radius: 6,
                          onPressed: () => setState(() => _showAssign = false),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      );

  Widget _requestPanel() => AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text('변경 요청', style: AppText.style(16, FontWeight.w700))),
                Pill('${_requests.length}건',
                    color: AppColors.danger, background: AppColors.dangerSoft),
              ],
            ),
            for (final (title, note, confirm) in _requests) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.bg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(title, style: AppText.style(14, FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(note,
                        style: AppText.style(12, FontWeight.w400, AppColors.textSecondary)),
                    const SizedBox(height: 10),
                    if (confirm)
                      const WebButton('확정', height: 34, radius: 10)
                    else
                      const Row(
                        children: [
                          Expanded(
                            child: WebButton('반려',
                                style: WebButtonStyle.outline, height: 34, radius: 10),
                          ),
                          SizedBox(width: 8),
                          Expanded(child: WebButton('승인', height: 34, radius: 10)),
                        ],
                      ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.accentSoft,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                '금요일 오픈이 비어 있어요. 승인 시 자동으로 빈 칸 후보를 추천해 드려요.',
                style: AppText.style(12, FontWeight.w400, AppColors.accent),
              ),
            ),
          ],
        ),
      );
}
