import 'package:flutter/material.dart';

import '../../theme.dart';
import '../../widgets/common.dart';
import 'web_common.dart';

/// W3 직원 관리 (콘텐츠 영역).
class WebStaffScreen extends StatefulWidget {
  const WebStaffScreen({super.key});

  @override
  State<WebStaffScreen> createState() => _WebStaffScreenState();
}

class _WebStaffScreenState extends State<WebStaffScreen> {
  static const _filters = ['전체 5', '오픈 2', '미들 2', '마감 1'];

  // (이름, 아바타색, 아바타배경, 파트, 시급, 공제, 서류, 서류색, 서류배경)
  static const _staff = [
    ('지민', AppColors.primary, AppColors.primarySoft, '오픈', '10,030원', '3.3%', '정상', AppColors.primary, AppColors.primarySoft),
    ('수빈', AppColors.accent, AppColors.accentSoft, '오픈', '10,030원', '3.3%', '보건증 D-12', WebColors.danger, WebColors.dangerSoft),
    ('하윤', WebColors.info, WebColors.infoSoft, '마감', '10,030원', '3.3%', '계약서 미서명', AppColors.accent, AppColors.accentSoft),
    ('도현', WebColors.danger, WebColors.dangerSoft, '마감', '10,030원', '4대보험', '정상', AppColors.primary, AppColors.primarySoft),
    ('서연', AppColors.primary, AppColors.primarySoft, '미들', '10,500원', '3.3%', '정상', AppColors.primary, AppColors.primarySoft),
  ];

  int _filter = 0;

  @override
  Widget build(BuildContext context) => WebPage(
        title: '직원 관리',
        subtitle: '재직 5명 · 승인 대기 0명',
        actions: const [WebButton('+ 직원 초대')],
        children: [
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
            child: Column(children: [
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                runSpacing: 12,
                children: [
                  Container(
                    width: 300,
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                        color: AppColors.bg, borderRadius: BorderRadius.circular(12)),
                    child: TextField(
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        hintText: '이름 검색',
                        hintStyle: AppText.style(
                            14, FontWeight.w400, AppColors.textTertiary),
                      ),
                      style: AppText.style(14),
                    ),
                  ),
                  Wrap(spacing: 8, children: [
                    for (var i = 0; i < _filters.length; i++)
                      GestureDetector(
                        onTap: () => setState(() => _filter = i),
                        child: i == _filter
                            ? Pill(_filters[i])
                            : Pill(_filters[i],
                                color: AppColors.textSecondary,
                                background: AppColors.bg),
                      ),
                  ]),
                ],
              ),
              const SizedBox(height: 14),
              WebTable(
                columns: const ['이름', '파트', '시급', '공제', '서류', '상태', ''],
                flex: const [230, 120, 130, 150, 230, 120, 120],
                rows: [
                  for (final s in _staff)
                    [
                      webNameCell(s.$1, s.$2, s.$3),
                      webCellText(s.$4),
                      webCellText(s.$5),
                      webCellText(s.$6),
                      Pill(s.$7, color: s.$8, background: s.$9),
                      const Pill('재직'),
                      webCellText('상세 ›'),
                    ],
                ],
              ),
            ]),
          ),
        ],
      );
}
