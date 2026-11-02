import 'package:flutter/material.dart';

import '../../theme.dart';
import '../../widgets/common.dart';
import 'join_pending_screen.dart';

/// 매장 코드 입력.
class StoreCodeScreen extends StatelessWidget {
  const StoreCodeScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: const AppHeader('매장 가입'),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          children: [
            Text('사장님께 받은\n매장 코드를 입력해주세요',
                style: AppText.style(22, FontWeight.w700)),
            const SizedBox(height: 16),
            Row(
              children: [
                for (final (i, c) in 'CAFE8K2D'.split('').indexed) ...[
                  if (i > 0) const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      height: 52,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        border: Border.all(color: AppColors.primary),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(c, style: AppText.style(20, FontWeight.w700)),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
            const AppButton('QR 코드로 입력하기', variant: AppButtonVariant.outline),
            const SizedBox(height: 16),
            const NoteBox(
              '매장 코드는 사장님 앱의 [매장 설정]에서 확인할 수 있어요. 여러 매장에서 일하면 코드를 추가로 입력하세요.',
              color: AppColors.info,
              background: AppColors.infoSoft,
            ),
          ],
        ),
        bottomNavigationBar: BottomBar(
          child: AppButton(
            '가입 신청하기',
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const JoinPendingScreen())),
          ),
        ),
      );
}
