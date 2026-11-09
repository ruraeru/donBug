import 'dart:async';

import 'package:flutter/material.dart';

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
    return (st == AttStatus.working && store.lateMinutes(s) > 0 ? '$inText · 지각' : inText, fg, bg);
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
        decoration: BoxDecoration(
            color: AppColors.surface, borderRadius: BorderRadius.circular(28)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('QR', style: AppText.style(64, FontWeight.w700, AppColors.textTertiary)),
            const SizedBox(height: 8),
            Text('동적 QR 코드',
                style: AppText.style(14, FontWeight.w400, AppColors.textTertiary)),
          ],
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
                    Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(12)),
                      child: Text('₩',
                          style: AppText.style(18, FontWeight.w700, AppColors.onPrimary)),
                    ),
                    const SizedBox(width: 12),
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(store.store.name,
                          style: AppText.style(18, FontWeight.w700, AppColors.surface)),
                      Text('매장 POS · 출퇴근 인증',
                          style: AppText.style(
                              12, FontWeight.w400, AppColors.textTertiary)),
                    ]),
                  ]),
                ),
                const Spacer(),
                Text(clock(store.now), style: AppText.style(32, FontWeight.w700, AppColors.surface)),
              ]),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(48, 0, 48, 48),
                child: Center(
                  child: Wrap(
                    spacing: 48,
                    runSpacing: 48,
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: checkedIn ? null : _scan,
                        child: Column(mainAxisSize: MainAxisSize.min, children: [
                          qr,
                          const SizedBox(height: 22),
                          Text('스마트폰으로 QR을 스캔해 출퇴근을 기록하세요',
                              textAlign: TextAlign.center,
                              style: AppText.style(22, FontWeight.w700, AppColors.surface)),
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
                            Text('오늘 출근 현황', style: AppText.style(16, FontWeight.w700)),
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
                                          style: AppText.style(14, FontWeight.w700))),
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
            ),
          ]),
          if (_checked case (final title, final caption))
            Positioned(
              top: 96,
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
            child: Text('✓', style: AppText.style(18, FontWeight.w700, AppColors.primary)),
          ),
          const SizedBox(width: 14),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title,
                style: AppText.style(18, FontWeight.w700, AppColors.onPrimary)),
            Text(caption,
                style: AppText.style(13, FontWeight.w400, AppColors.onPrimary)),
          ]),
        ]),
      );
}
