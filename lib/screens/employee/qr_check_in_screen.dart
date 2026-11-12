import 'package:flutter/material.dart';

import '../../data/app_scope.dart';
import '../../data/format.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
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

/// A6 QR 출근 인증. 데모: 스캔 영역을 탭하면 인증 성공으로 출근 기록을 만든다.
class QrCheckInScreen extends StatelessWidget {
  const QrCheckInScreen({super.key, required this.shiftId});

  final String shiftId;

  // 출근 기록을 만들고 출근 완료 화면으로 교체.
  void _scanned(BuildContext context) {
    final a = AppScope.read(context).clockIn(shiftId);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => ClockInDoneScreen(attendanceId: a.id)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final shift = store.shiftById(shiftId);
    if (shift == null) return const MissingScreen(title: '출근 인증');
    return Scaffold(
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
                              17, FontWeight.w500, AppColors.onPrimary)),
                    ),
                    TextButton(
                      onPressed: () => showConfirmDialog(context,
                          title: '데모 안내',
                          message: '실제 앱은 카메라로 매장 POS 의 QR 을 스캔해요. 데모에서는 사각형을 탭하면 인증돼요.',
                          confirmLabel: '확인'),
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
                        child: Text('${store.store.name} · ${shiftTime(shift)} 근무',
                            style: AppText.style(
                                13, FontWeight.w500, AppColors.onPrimary)),
                      ),
                      const SizedBox(height: 20),
                      GestureDetector(
                        key: const ValueKey('qr-scan'),
                        onTap: () => _scanned(context),
                        child: const _ScanBox(),
                      ),
                      const SizedBox(height: 20),
                      Text('POS 화면의 QR 코드를\n사각형 안에 맞춰주세요\n(데모: 사각형을 탭하세요)',
                          textAlign: TextAlign.center,
                          style: AppText.style(
                              16, FontWeight.w500, AppColors.onPrimary)),
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
