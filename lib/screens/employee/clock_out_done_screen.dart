import 'package:flutter/material.dart';

import '../../theme.dart';
import '../../widgets/common.dart';
import 'employee_parts.dart';
import 'employee_widgets.dart';

/// 퇴근 완료: 오늘 근무 요약.
class ClockOutDoneScreen extends StatelessWidget {
  const ClockOutDoneScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            children: const [
              DoneHero(title: '오늘도 수고했어요', subtitle: '5/14(수) 근무 요약'),
              SizedBox(height: 16),
              AppCard(
                child: Column(
                  children: [
                    KvRow('출근', '14:02'),
                    SizedBox(height: 14),
                    KvRow('퇴근', '20:05'),
                    SizedBox(height: 14),
                    KvRow('실근무', '5시간 33분 (휴게 30분)'),
                    SizedBox(height: 14),
                    KvRow('연장 근무', '5분'),
                    SizedBox(height: 14),
                    Divider(height: 1, color: AppColors.border),
                    SizedBox(height: 14),
                    KvRow('오늘 일급', '₩55,667',
                        valueSize: 20,
                        valueColor: AppColors.primary,
                        labelStyle: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            height: 1.4)),
                  ],
                ),
              ),
            ],
          ),
        ),
        // true 를 돌려주면 홈이 근무표 탭으로 전환한다.
        bottomNavigationBar: BottomBar(
          child: AppButton('근무표 보기',
              onPressed: () => Navigator.pop(context, true)),
        ),
      );
}
