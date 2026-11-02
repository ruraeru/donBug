import 'package:flutter/material.dart';

import '../../theme.dart';
import '../../widgets/common.dart';
import 'notice_detail_screen.dart';

/// A7 공지 수신함 (탭 루트).
class EmployeeNoticeScreen extends StatefulWidget {
  const EmployeeNoticeScreen({super.key});

  @override
  State<EmployeeNoticeScreen> createState() => _EmployeeNoticeScreenState();
}

class _EmployeeNoticeScreenState extends State<EmployeeNoticeScreen> {
  static const _filters = ['전체', '중요', '안 읽음 2'];
  int _filter = 0;

  void _openDetail() => Navigator.push(
      context, MaterialPageRoute(builder: (_) => const NoticeDetailScreen()));

  @override
  Widget build(BuildContext context) => SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  Expanded(child: Text('공지', style: AppText.style(24, FontWeight.w700))),
                  GestureDetector(
                    onTap: () {},
                    child: Text('모두 읽음',
                        style: AppText.style(14, FontWeight.w500, AppColors.primary)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                children: [
                  Row(
                    children: [
                      for (var i = 0; i < _filters.length; i++) ...[
                        if (i > 0) const SizedBox(width: 8),
                        _FilterChip(
                          _filters[i],
                          selected: i == _filter,
                          onTap: () => setState(() => _filter = i),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                  _pinnedCard(),
                  const SizedBox(height: 12),
                  _NoticeCard(
                    tag: const Pill('일반', color: AppColors.info, background: AppColors.infoSoft),
                    title: '6월 근무표가 확정되었어요',
                    body: '변경이 필요하면 5/25까지 휴무 신청으로 남겨주세요.',
                    meta: '사장님 · 5/13 18:40',
                    status: Text('안 읽음', style: AppText.style(12, FontWeight.w700, AppColors.danger)),
                    onTap: _openDetail,
                  ),
                  const SizedBox(height: 12),
                  _NoticeCard(
                    tag: const Pill('노무'),
                    title: '보건증 만료 30일 전 알림 안내',
                    body: '보건증은 만료 30일·14일·7일 전에 알림이 와요. 갱신 후 사진을 등록해 주세요.',
                    meta: '사장님 · 5/10 10:05',
                    status: Text('읽음 · 5/10 11:21',
                        style: AppText.style(12, FontWeight.w500, AppColors.primary)),
                    read: true,
                    onTap: _openDetail,
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _pinnedCard() => Material(
        color: AppColors.accentSoft,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.accent, width: 1.5),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: _openDetail,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Pill('중요', color: AppColors.onPrimary, background: AppColors.accent),
                    SizedBox(width: 6),
                    Pill('상단 고정',
                        color: AppColors.textSecondary, background: AppColors.surface),
                  ],
                ),
                const SizedBox(height: 10),
                Text('5/17(토) 매장 위생 점검 안내', style: AppText.style(17, FontWeight.w700)),
                const SizedBox(height: 10),
                Text(
                  '보건소 위생 점검이 예정되어 있어요. 당일 근무자는 앞치마·위생모를 꼭 착용하고, 보건증 원본을 지참해 주세요.',
                  style: AppText.style(13, FontWeight.w400, AppColors.textSecondary),
                ),
                const SizedBox(height: 10),
                _MetaRow(
                  '사장님 · 5/14 09:12',
                  Text('안 읽음', style: AppText.style(12, FontWeight.w700, AppColors.danger)),
                ),
                const SizedBox(height: 10),
                AppButton('확인했어요', verticalPadding: 13, fontSize: 15, onPressed: () {}),
              ],
            ),
          ),
        ),
      );
}

class _FilterChip extends StatelessWidget {
  const _FilterChip(this.label, {required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : AppColors.surface,
            border: selected ? null : Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            label,
            style: selected
                ? AppText.style(13, FontWeight.w700, AppColors.onPrimary)
                : AppText.style(13, FontWeight.w500, AppColors.textSecondary),
          ),
        ),
      );
}

class _MetaRow extends StatelessWidget {
  const _MetaRow(this.meta, this.status);

  final String meta;
  final Widget status;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(
            child: Text(meta,
                style: AppText.style(12, FontWeight.w400, AppColors.textTertiary)),
          ),
          status,
        ],
      );
}

class _NoticeCard extends StatelessWidget {
  const _NoticeCard({
    required this.tag,
    required this.title,
    required this.body,
    required this.meta,
    required this.status,
    required this.onTap,
    this.read = false,
  });

  final Widget tag;
  final String title;
  final String body;
  final String meta;
  final Widget status;
  final VoidCallback onTap;
  final bool read;

  @override
  Widget build(BuildContext context) => AppCard(
        padding: const EdgeInsets.all(18),
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            tag,
            const SizedBox(height: 8),
            Text(
              title,
              style: AppText.style(
                  16, FontWeight.w700, read ? AppColors.textSecondary : AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              body,
              style: AppText.style(13, FontWeight.w400,
                  read ? AppColors.textTertiary : AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            _MetaRow(meta, status),
          ],
        ),
      );
}
