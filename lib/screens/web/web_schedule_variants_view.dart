import 'package:flutter/material.dart';

import 'web_schedule_common.dart';
import 'web_schedule_daily_timeline.dart';
import 'web_schedule_flex_board.dart';
import 'web_schedule_monthly_stack.dart';
import 'web_schedule_weekly_calendar.dart';
import 'web_schedule_weekly_matrix.dart';

/// 웹 근무표 변형 W2-A~E (Figma 섹션 53:2). 사이드바 없는 콘텐츠 영역만.
/// 높이가 정해진 곳(예: 셸의 Expanded)에 넣는다.
class WebScheduleVariantsView extends StatefulWidget {
  const WebScheduleVariantsView({super.key});

  @override
  State<WebScheduleVariantsView> createState() => _WebScheduleVariantsViewState();
}

class _WebScheduleVariantsViewState extends State<WebScheduleVariantsView> {
  static const _labels = [
    'A 일간 타임라인',
    'B 주간 캘린더',
    'C 주간 매트릭스',
    'D 월간 4주',
    'E 유동 보드',
  ];

  int _variant = 0;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(32, 20, 32, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: WebSegmented(
                labels: _labels,
                selected: _variant,
                itemWidth: null,
                onChanged: (i) => setState(() => _variant = i),
              ),
            ),
            const SizedBox(height: 20),
            switch (_variant) {
              0 => const WebScheduleDailyTimeline(),
              1 => const WebScheduleWeeklyCalendar(),
              2 => const WebScheduleWeeklyMatrix(),
              3 => const WebScheduleMonthlyStack(),
              _ => const WebScheduleFlexBoard(),
            },
          ],
        ),
      );
}
