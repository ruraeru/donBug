import 'package:flutter/material.dart';

import '../../theme.dart';
import '../../widgets/common.dart';
import 'web_common.dart';

/// W5 서류·컴플라이언스 (콘텐츠 영역).
class WebDocumentsScreen extends StatefulWidget {
  const WebDocumentsScreen({super.key});

  @override
  State<WebDocumentsScreen> createState() => _WebDocumentsScreenState();
}

class _WebDocumentsScreenState extends State<WebDocumentsScreen> {
  static const _items = [
    '근로계약서 서면 교부',
    '4대보험·3.3% 공제 설정',
    '5인 미만 연차 적용 여부 확인',
    '보건증 만료 관리',
    '급여명세서 교부',
  ];

  // (이름, 아바타색, 배경, 보건증 라벨, 보건증색, 보건증배경, 만료일, 계약서 라벨, 계약서 완료?)
  static const _rows = [
    ('지민', AppColors.primary, AppColors.primarySoft, '정상', AppColors.primary, AppColors.primarySoft, '2027.01.18', '서명 완료', true),
    ('수빈', AppColors.accent, AppColors.accentSoft, 'D-12', WebColors.danger, WebColors.dangerSoft, '2026.05.26', '서명 완료', true),
    ('하윤', WebColors.info, WebColors.infoSoft, '정상', AppColors.primary, AppColors.primarySoft, '2026.11.02', '서명 필요', false),
    ('도현', WebColors.danger, WebColors.dangerSoft, 'D-45', AppColors.accent, AppColors.accentSoft, '2026.06.28', '서명 완료', true),
    ('서연', AppColors.primary, AppColors.primarySoft, '정상', AppColors.primary, AppColors.primarySoft, '2027.03.09', '서명 대기', false),
  ];

  final _done = [true, true, true, false, false];

  @override
  Widget build(BuildContext context) => WebPage(
        title: '서류 · 컴플라이언스',
        subtitle: '보건증 · 근로계약서 · 5인 미만 사업장 체크리스트',
        actions: const [WebButton('+ 계약서 작성')],
        children: [
          WebSplit(
            leftWidth: 420,
            gap: 20,
            breakpoint: 1000,
            left: AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(
                        child:
                            Text('노무 체크리스트', style: AppText.style(16, FontWeight.w700))),
                    Pill.accent('${_done.where((d) => d).length} / ${_items.length} 완료'),
                  ]),
                  for (var i = 0; i < _items.length; i++) ...[
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: () => setState(() => _done[i] = !_done[i]),
                      child: Row(children: [
                        Container(
                          width: 24,
                          height: 24,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: _done[i] ? AppColors.primary : AppColors.surface,
                            shape: BoxShape.circle,
                            border: _done[i] ? null : Border.all(color: AppColors.border),
                          ),
                          child: _done[i]
                              ? Text('✓',
                                  style: AppText.style(
                                      13, FontWeight.w700, AppColors.onPrimary))
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _items[i],
                            style: AppText.style(14, FontWeight.w500,
                                _done[i] ? AppColors.textPrimary : AppColors.textSecondary),
                          ),
                        ),
                      ]),
                    ),
                  ],
                ],
              ),
            ),
            right: AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('직원별 서류', style: AppText.style(16, FontWeight.w700)),
                  const SizedBox(height: 14),
                  WebTable(
                    columns: const ['직원', '보건증', '만료일', '근로계약서'],
                    flex: const [170, 170, 130, 160],
                    rows: [
                      for (final r in _rows)
                        [
                          webNameCell(r.$1, r.$2, r.$3),
                          Pill(r.$4, color: r.$5, background: r.$6),
                          webCellText(r.$7),
                          r.$9 ? Pill(r.$8) : Pill.accent(r.$8),
                        ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      );
}
