import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../data/api_client.dart';
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

/// A6 QR 출근 인증. 서버 모드는 카메라로 POS 의 QR 을 스캔하고, 데모는 스캔 영역을 탭하면 인증된다.
class QrCheckInScreen extends StatefulWidget {
  const QrCheckInScreen({super.key, required this.shiftId});

  final String shiftId;

  @override
  State<QrCheckInScreen> createState() => _QrCheckInScreenState();
}

class _QrCheckInScreenState extends State<QrCheckInScreen> {
  String get shiftId => widget.shiftId;

  /// 서버 응답을 기다리는 중이면 true (중복 스캔 방지).
  bool _busy = false;

  void _done(String attendanceId) => Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => ClockInDoneScreen(attendanceId: attendanceId)),
      );

  // 데모: 출근 기록을 만들고 출근 완료 화면으로 교체.
  void _scanned(BuildContext context) {
    final store = AppScope.read(context);
    final block = store.clockInBlock(store.shiftById(shiftId)!);
    if (block != null) return showToast(context, block);
    _done(store.clockIn(shiftId).id);
  }

  // 서버: 스캔한 문자열을 서버에 보내 검증. 성공일 때만 완료 화면.
  Future<void> _detected(BarcodeCapture capture) async {
    final token = capture.barcodes.map((b) => b.rawValue).whereType<String>().firstOrNull;
    if (token == null || _busy) return;
    final store = AppScope.read(context);
    final block = store.clockInBlock(store.shiftById(shiftId)!);
    if (block != null) return showToast(context, block);
    _busy = true;
    try {
      final a = await store.clockInRemote(shiftId, token);
      if (mounted) _done(a.id);
    } on ApiException catch (e) {
      if (mounted) showToast(context, e.code == 'INVALID_QR' ? '유효하지 않은 QR 이에요. POS 화면의 QR 을 다시 스캔해 주세요' : e.message);
    } catch (_) {
      if (mounted) showToast(context, '서버와 통신하지 못했어요');
    }
    // 같은 토스트가 연달아 뜨지 않게 잠시 쉰 뒤 다시 스캔 가능.
    await Future<void>.delayed(const Duration(seconds: 2));
    _busy = false;
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
                    if (store.remote)
                      const SizedBox(width: 64)
                    else
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
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text('${store.store.name} · ${shiftTime(shift)} 근무',
                            style: AppText.style(
                                13, FontWeight.w500, AppColors.onPrimary)),
                      ),
                      const SizedBox(height: 20),
                      if (store.remote)
                        Container(
                          key: const ValueKey('qr-camera'),
                          width: 260,
                          height: 260,
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.primary, width: 4),
                            borderRadius: BorderRadius.circular(28),
                          ),
                          child: MobileScanner(
                            onDetect: _detected,
                            errorBuilder: (context, e) => Center(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Text('카메라를 쓸 수 없어요. 설정에서 카메라 권한을 허용해 주세요',
                                    textAlign: TextAlign.center,
                                    style: AppText.style(13, FontWeight.w500, AppColors.onPrimary)),
                              ),
                            ),
                          ),
                        )
                      else
                        GestureDetector(
                          key: const ValueKey('qr-scan'),
                          onTap: () => _scanned(context),
                          child: const _ScanBox(),
                        ),
                      const SizedBox(height: 20),
                      Text(
                          store.remote
                              ? 'POS 화면의 QR 코드를\n사각형 안에 맞춰주세요'
                              : 'POS 화면의 QR 코드를\n사각형 안에 맞춰주세요\n(데모: 사각형을 탭하세요)',
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
              if (!store.remote)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                child: Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
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
