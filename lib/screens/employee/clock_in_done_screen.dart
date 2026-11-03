import 'package:flutter/material.dart';

import '../../widgets/common.dart';
import '../../theme.dart';

/// 출근 완료 → 홈(근무 중).
class ClockInDoneScreen extends StatelessWidget {
  const ClockInDoneScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            children: const [
              SuccessHero(title: '출근이 완료됐어요', subtitle: '14:02 · QR 스캔 인증'),
              SizedBox(height: 16),
              AppCard(
                child: Column(
                  children: [
                    KeyValueRow('오늘 근무', '14:00 – 20:00'),
                    SizedBox(height: 14),
                    KeyValueRow('인증 방식', '매장 POS QR'),
                    SizedBox(height: 14),
                    KeyValueRow('지각 여부', '정상 출근'),
                    SizedBox(height: 14),
                    KeyValueRow('예상 일급', '₩55,667'),
                  ],
                ),
              ),
              SizedBox(height: 16),
              NoteBox('퇴근도 같은 방법으로 인증하면 근무시간이 자동 계산돼요.',
                  color: AppColors.info, background: AppColors.infoSoft),
            ],
          ),
        ),
        bottomNavigationBar: BottomBar(
          child: AppButton('홈으로 가기', onPressed: () => Navigator.pop(context)),
        ),
      );
}
