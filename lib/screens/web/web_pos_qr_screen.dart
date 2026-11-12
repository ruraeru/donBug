import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../data/app_scope.dart';
import '../../data/app_store.dart';
import '../../data/format.dart';
import '../../data/models.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import '../employer/employer_parts.dart';

/// W8 POS 동적 QR / W9 POS 출근 완료(전체 화면).
///
/// 데모: QR 을 누르면 오늘 아직 출근하지 않은 다음 근무자가 출근한다(W9 토스트).
class WebPosQrScreen extends StatefulWidget {
  const WebPosQrScreen({super.key});

  @override
  State<WebPosQrScreen> createState() => _WebPosQrScreenState();
}

class _WebPosQrScreenState extends State<WebPosQrScreen> {
  static const _qrSeconds = 18;

  late final Timer _timer;
  int _tick = 0;

  /// 출근 완료 토스트 (이름, 설명). 3초 뒤 사라진다.
  (String, String)? _checked;
  int _checkedAt = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _tick++;
        if (_tick - _checkedAt >= 3) _checked = null;
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _scan() {
    final store = AppScope.read(context);
    final next = store
        .shiftsOn(store.today)
        .where((s) => store.attendanceFor(s.id) == null && !store.shiftEnd(s).isBefore(store.now))
        .firstOrNull;
    if (next == null) return showToast(context, '오늘 출근할 근무가 없어요');
    final a = store.clockIn(next.id);
    final late = store.lateMinutes(next);
    setState(() {
      _checkedAt = _tick;
      _checked = (
        '${store.nameOf(next.staffId)}님 출근 완료',
        '${clock(DateTime.parse(a.clockIn))} · QR 인증 · ${late > 0 ? '$late분 지각' : '정상 출근'}',
      );
    });
  }

  /// 오늘 출근 현황 한 줄: (상태 문구, 글자색, 배경).
  (String, Color, Color) _status(AppStore store, Shift s) {
    final a = store.attendanceFor(s.id);
    final st = store.attendanceStatus(s);
    final (label, fg, bg) = attStyle(st);
    if (a == null) {
      return (st == AttStatus.waiting ? '${hm(s.startMin)} 출근 예정' : label, fg, bg);
    }
    final inText = '${clock(DateTime.parse(a.clockIn))} 출근';
    if (a.clockOut != null) {
      return ('$inText · ${clock(DateTime.parse(a.clockOut!))} 퇴근', fg, bg);
    }
    if (st == AttStatus.working && store.lateMinutes(s) > 0) {
      return ('$inText · 지각', AppColors.danger, AppColors.dangerSoft);
    }
    return (inText, fg, bg);
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final checkedIn = _checked != null;
    final today = store.shiftsOn(store.today);
    final qr = Opacity(
      opacity: checkedIn ? 0.35 : 1,
      child: Container(
        width: 380,
        height: 380,
        alignment: Alignment.center,
        decoration: BoxDecoration(
            color: AppColors.surface, borderRadius: BorderRadius.circular(28)),
        child: Semantics(
          label: '출근 QR 코드',
          child: CustomPaint(
            key: const ValueKey('pos-qr'),
            size: const Size.square(300),
            painter: _QrPainter(_tick ~/ _qrSeconds),
          ),
        ),
      ),
    );
    return Scaffold(
      backgroundColor: AppColors.textPrimary,
      body: SafeArea(
        child: Stack(fit: StackFit.expand, children: [
          Column(children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 36),
              child: Row(children: [
                // 디자인에 닫기 버튼이 없어 로고 탭으로 POS 모드를 빠져나간다.
                GestureDetector(
                  onTap: () => Navigator.of(context).popUntil((r) => r.isFirst),
                  child: Row(children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SvgPicture.asset('assets/images/app_icon.svg', width: 40, height: 40),
                    ),
                    const SizedBox(width: 12),
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(store.store.name,
                          style: AppText.style(18, FontWeight.w500, AppColors.surface)),
                      Text('매장 POS · 출퇴근 인증',
                          style: AppText.style(
                              12, FontWeight.w400, AppColors.textTertiary)),
                    ]),
                  ]),
                ),
                const Spacer(),
                Text(clock(store.now), style: AppText.style(32, FontWeight.w500, AppColors.surface)),
              ]),
            ),
            Expanded(
              // 남는 높이가 있으면 화면 가운데(머리 줄 높이만큼 위로 보정), 넘치면 스크롤.
              child: LayoutBuilder(builder: (context, c) => SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(48, 0, 48, 112),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: max(0, c.maxHeight - 112)),
                  child: Center(
                    child: Wrap(
                      spacing: 48,
                      runSpacing: 48,
                      alignment: WrapAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: checkedIn ? null : _scan,
                          child: Column(mainAxisSize: MainAxisSize.min, children: [
                            qr,
                            const SizedBox(height: 22),
                            Text('스마트폰으로 QR을 스캔해 출퇴근을 기록하세요',
                                textAlign: TextAlign.center,
                                style: AppText.style(22, FontWeight.w500, AppColors.surface)),
                            const SizedBox(height: 22),
                            Row(mainAxisSize: MainAxisSize.min, children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: const BoxDecoration(
                                    color: AppColors.primary, shape: BoxShape.circle),
                              ),
                              const SizedBox(width: 10),
                              Text('${_qrSeconds - _tick % _qrSeconds}초 후 QR이 자동으로 바뀌어요',
                                  style: AppText.style(
                                      15, FontWeight.w400, AppColors.textTertiary)),
                            ]),
                          ]),
                        ),
                        Container(
                          width: 380,
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(24)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('오늘 출근 현황', style: AppText.style(16, FontWeight.w500)),
                              if (today.isEmpty) const EmptyNote('오늘 근무가 없어요'),
                              for (final s in today) ...[
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 10),
                                  decoration: BoxDecoration(
                                      color: AppColors.bg,
                                      borderRadius: BorderRadius.circular(12)),
                                  child: Row(children: [
                                    Expanded(
                                        child: Text(store.nameOf(s.staffId),
                                            style: AppText.style(14, FontWeight.w500))),
                                    Builder(builder: (_) {
                                      final (label, fg, bg) = _status(store, s);
                                      return Pill(label, color: fg, background: bg);
                                    }),
                                  ]),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )),
            ),
          ]),
          if (_checked case (final title, final caption))
            Positioned(
              bottom: 32,
              left: 0,
              right: 0,
              child: Center(child: _CheckedInToast(title, caption)),
            ),
        ]),
      ),
    );
  }
}

class _CheckedInToast extends StatelessWidget {
  const _CheckedInToast(this.title, this.caption);

  final String title, caption;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
        decoration: BoxDecoration(
            color: AppColors.primary, borderRadius: BorderRadius.circular(20)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration:
                const BoxDecoration(color: AppColors.surface, shape: BoxShape.circle),
            child: const Icon(Icons.check_rounded, size: 20, color: AppColors.primary),
          ),
          const SizedBox(width: 14),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title,
                style: AppText.style(18, FontWeight.w500, AppColors.onPrimary)),
            Text(caption,
                style: AppText.style(13, FontWeight.w400, AppColors.onPrimary)),
          ]),
        ]),
      );
}

/// 출근 QR 무늬(프로토타입). [seed] 가 바뀌면 무늬가 바뀐다. 실제로 읽히는 QR 은 아니다.
class _QrPainter extends CustomPainter {
  const _QrPainter(this.seed);

  final int seed;
  static const _n = 25;

  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.width / _n;
    final ink = Paint()
      ..color = AppColors.textPrimary
      ..isAntiAlias = false;
    final paper = Paint()
      ..color = AppColors.surface
      ..isAntiAlias = false;
    final corners = [(0, 0), (_n - 7, 0), (0, _n - 7)];
    bool inCorner(int x, int y) =>
        corners.any((c) => x >= c.$1 - 1 && x <= c.$1 + 7 && y >= c.$2 - 1 && y <= c.$2 + 7);
    final rnd = Random(seed);
    for (var y = 0; y < _n; y++) {
      for (var x = 0; x < _n; x++) {
        if (!inCorner(x, y) && rnd.nextBool()) {
          canvas.drawRect(Rect.fromLTWH(x * cell, y * cell, cell, cell), ink);
        }
      }
    }
    // 세 모서리 위치 표시: 7칸 검정 · 5칸 흰색 · 3칸 검정.
    for (final (x, y) in corners) {
      final o = Offset(x * cell, y * cell);
      canvas.drawRect(o & Size.square(cell * 7), ink);
      canvas.drawRect(o + Offset(cell, cell) & Size.square(cell * 5), paper);
      canvas.drawRect(o + Offset(cell * 2, cell * 2) & Size.square(cell * 3), ink);
    }
  }

  @override
  bool shouldRepaint(_QrPainter old) => old.seed != seed;
}
