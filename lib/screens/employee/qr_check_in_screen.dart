import 'package:flutter/material.dart';

import '../../theme.dart';
import 'clock_in_done_screen.dart';

const _qrBg = AppColors.textPrimary;

// Figma QR 코드 그림 그대로 (21×21, '#' = 검은 칸).
const _qr = [
  '#######.#.###.#######',
  '#.....#.###.#.#.....#',
  '#.###.#...#...#.###.#',
  '#.###.#...###.#.###.#',
  '#.###.#.#.#...#.###.#',
  '#.....#.#.#...#.....#',
  '#######.#####.#######',
  '........#...#........',
  '..#.##..#..##.##.#..#',
  '#....#..####...##..#.',
  '.##.....#.#.##..#...#',
  '....#.#####....#.##.#',
  '.##..###.....##.#..##',
  '........##.#.#..#.#..',
  '#######.#.##.#.##.###',
  '#.....#..#..##.#....#',
  '#.###.#.##..#....##.#',
  '#.###.#..#.#...#.#...',
  '#.###.#....#......###',
  '#.....#...##..##.....',
  '#######.#####..#.####',
];

/// A6 QR 출근 인증. 스캔 영역을 탭하면 인증 성공(더미)으로 처리한다.
class QrCheckInScreen extends StatelessWidget {
  const QrCheckInScreen({super.key});

  // 홈에 true 를 돌려주고 출근 완료 화면으로 교체.
  void _scanned(BuildContext context) => Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ClockInDoneScreen()),
        result: true,
      );

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: _qrBg,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                child: Row(
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('닫기',
                          style: AppText.style(
                              15, FontWeight.w500, AppColors.onPrimary)),
                    ),
                    Expanded(
                      child: Text('출근 인증',
                          textAlign: TextAlign.center,
                          style: AppText.style(
                              17, FontWeight.w700, AppColors.onPrimary)),
                    ),
                    TextButton(
                      onPressed: () {},
                      child: Text('도움말',
                          style: AppText.style(
                              15, FontWeight.w500, AppColors.textTertiary)),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text('카페 커푸치노 · 14:00 – 20:00 근무',
                            style: AppText.style(
                                13, FontWeight.w700, AppColors.onPrimary)),
                      ),
                      const SizedBox(height: 20),
                      GestureDetector(
                        onTap: () => _scanned(context),
                        child: const _ScanBox(),
                      ),
                      const SizedBox(height: 20),
                      Text('POS 화면의 QR 코드를\n사각형 안에 맞춰주세요',
                          textAlign: TextAlign.center,
                          style: AppText.style(
                              16, FontWeight.w700, AppColors.onPrimary)),
                      const SizedBox(height: 20),
                      Text('위·변조 방지를 위해 매장 안에서만 인증돼요',
                          textAlign: TextAlign.center,
                          style: AppText.style(
                              12, FontWeight.w400, AppColors.textTertiary)),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 34),
                child: Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.accentSoft,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    '네트워크가 끊겨도 출근 기록은 기기에 안전하게 저장되고, 연결되면 자동으로 동기화돼요',
                    style: AppText.style(12, FontWeight.w500),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}

class _ScanBox extends StatelessWidget {
  const _ScanBox();

  @override
  Widget build(BuildContext context) => Container(
        width: 260,
        height: 260,
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.primary, width: 4),
          borderRadius: BorderRadius.circular(28),
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(21),
              child: Column(
                children: [
                  for (final row in _qr)
                    Row(
                      children: [
                        for (final c in row.split(''))
                          Container(
                            width: 10,
                            height: 10,
                            color: c == '#' ? _qrBg : null,
                          ),
                      ],
                    ),
                ],
              ),
            ),
            Positioned(
              left: 7,
              right: 7,
              top: 120,
              child: Container(
                height: 3,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ],
        ),
      );
}
