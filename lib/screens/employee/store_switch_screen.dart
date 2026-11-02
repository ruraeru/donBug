import 'package:flutter/material.dart';

import '../../theme.dart';
import '../../widgets/common.dart';
import 'employee_widgets.dart';

/// 근무 매장 전환.
class StoreSwitchScreen extends StatefulWidget {
  const StoreSwitchScreen({super.key});

  @override
  State<StoreSwitchScreen> createState() => _StoreSwitchScreenState();
}

class _StoreSwitchScreenState extends State<StoreSwitchScreen> {
  static const _stores = [
    ('커', AppColors.primary, AppColors.primarySoft, '카페 커푸치노', '홀 서빙 · 시급 10,030원'),
    ('편', kInfo, kInfoSoft, '편의점 모아', '야간 근무 · 시급 10,500원'),
  ];
  int _current = 0;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: const AppHeader('근무 매장'),
        body: ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          itemCount: _stores.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, i) {
            final (letter, fg, bg, name, sub) = _stores[i];
            final selected = i == _current;
            return Material(
              color: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: selected
                    ? const BorderSide(color: AppColors.primary, width: 2)
                    : const BorderSide(color: AppColors.border),
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => setState(() => _current = i),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                  child: Row(
                    children: [
                      LetterAvatar(letter, color: fg, background: bg),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name, style: AppText.style(16, FontWeight.w700)),
                            Text(sub,
                                style: AppText.style(
                                    12, FontWeight.w400, AppColors.textSecondary)),
                          ],
                        ),
                      ),
                      if (selected) ...[const SizedBox(width: 12), const Pill('현재')],
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        bottomNavigationBar: BottomBar(
          child: AppButton(
            '매장 코드로 추가 가입',
            variant: AppButtonVariant.outline,
            onPressed: () {},
          ),
        ),
      );
}
