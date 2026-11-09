import 'package:flutter/material.dart';

import '../../data/app_store.dart';
import '../../data/format.dart';
import '../../data/models.dart';
import '../../theme.dart';
import '../../widgets/common.dart';

/// 24px 원 체크 + 라벨. [onChanged]가 있으면 탭으로 켜고 끈다.
class CheckLine extends StatelessWidget {
  const CheckLine(this.label,
      {super.key, this.caption, this.value = true, this.onChanged});

  final String label;
  final String? caption;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onChanged == null ? null : () => onChanged!(!value),
        child: _row(),
      );

  Widget _row() => Row(
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: value ? AppColors.primary : AppColors.surface,
              shape: BoxShape.circle,
              border: value ? null : Border.all(color: AppColors.border, width: 2),
            ),
            child: value
                ? const Icon(Icons.check, size: 16, color: AppColors.onPrimary)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppText.style(15, FontWeight.w500)),
                if (caption != null)
                  Text(caption!, style: AppText.style(12, FontWeight.w400, AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      );
}

/// 날짜 + 칩 / 큰 시간 / 설명 카드 (근무 상세, 대타 상세).
class ShiftHeroCard extends StatelessWidget {
  const ShiftHeroCard({
    super.key,
    required this.date,
    required this.chip,
    required this.time,
    required this.caption,
  });

  final String date;
  final String chip;
  final String time;
  final String caption;

  @override
  Widget build(BuildContext context) => AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                    child: Text(date, style: AppText.style(22, FontWeight.w700))),
                Pill.accent(chip),
              ],
            ),
            const SizedBox(height: 12),
            Text(time, style: AppText.style(30, FontWeight.w700)),
            const SizedBox(height: 12),
            Text(caption,
                style:
                    AppText.style(13, FontWeight.w400, AppColors.textSecondary)),
          ],
        ),
      );
}

/// 탭 루트 화면 상단: 큰 제목 + 오른쪽 칩.
class TabTitle extends StatelessWidget {
  const TabTitle(this.title, {super.key, this.chip});

  final String title;
  final String? chip;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            Expanded(child: Text(title, style: AppText.style(24, FontWeight.w700))),
            if (chip != null) Pill(chip!),
          ],
        ),
      );
}

/// 내 근무 한 건의 상태 칩: (문구, 글자색, 배경색).
(String, Color, Color) shiftStatus(AppStore store, Shift s) {
  final req = store.pendingSubFor(s.id);
  if (req != null) {
    return req.status == SubStatus.accepted
        ? ('대타 수락됨', AppColors.accent, AppColors.accentSoft)
        : ('휴무 신청 중', AppColors.accent, AppColors.accentSoft);
  }
  switch (store.attendanceStatus(s)) {
    case AttStatus.working:
      return ('근무 중', AppColors.primary, AppColors.primarySoft);
    case AttStatus.normal:
    case AttStatus.late:
      return ('완료', AppColors.textSecondary, AppColors.bg);
    case AttStatus.absent:
      return ('미출근', AppColors.danger, AppColors.dangerSoft);
    case AttStatus.waiting:
      break;
  }
  if (s.isSubstitute) return ('대타 확정', AppColors.info, AppColors.infoSoft);
  if (s.date == ymd(store.today)) return ('오늘', AppColors.primary, AppColors.primarySoft);
  return (dDay(parseYmd(s.date), store.today), AppColors.textSecondary, AppColors.bg);
}


/// 손가락으로 그리는 서명 칸(데모: 획이 있는지만 쓴다).
class SignaturePad extends StatefulWidget {
  const SignaturePad({super.key, required this.onChanged});

  final ValueChanged<bool> onChanged;

  @override
  State<SignaturePad> createState() => _SignaturePadState();
}

class _SignaturePadState extends State<SignaturePad> {
  final _strokes = <List<Offset>>[];

  void _clear() {
    setState(_strokes.clear);
    widget.onChanged(false);
  }

  @override
  Widget build(BuildContext context) => Container(
        height: 140,
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            if (_strokes.isEmpty)
              Center(
                child: Text('여기에 서명해주세요',
                    style: AppText.style(14, FontWeight.w400, AppColors.textTertiary)),
              ),
            Positioned.fill(
              child: GestureDetector(
                onPanStart: (d) {
                  setState(() => _strokes.add([d.localPosition]));
                  widget.onChanged(true);
                },
                onPanUpdate: (d) => setState(() => _strokes.last.add(d.localPosition)),
                child: CustomPaint(painter: _InkPainter(_strokes)),
              ),
            ),
            if (_strokes.isNotEmpty)
              Positioned(
                right: 8,
                top: 4,
                child: TextButton(
                  onPressed: _clear,
                  child: Text('지우기',
                      style: AppText.style(13, FontWeight.w500, AppColors.textSecondary)),
                ),
              ),
          ],
        ),
      );
}

class _InkPainter extends CustomPainter {
  _InkPainter(this.strokes);

  final List<List<Offset>> strokes;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.textPrimary
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    for (final s in strokes) {
      final path = Path()..moveTo(s.first.dx, s.first.dy);
      for (final p in s.skip(1)) {
        path.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_InkPainter old) => true;
}
