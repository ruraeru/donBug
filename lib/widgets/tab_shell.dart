import 'package:flutter/material.dart';

import '../theme.dart';
import 'common.dart';

typedef TabItem = ({String icon, String label, Widget page});

/// Figma "Tab Bar": 흰 배경 · 상단 border · 아이콘 24 · 라벨 11.
class TabShell extends StatefulWidget {
  const TabShell({super.key, required this.tabs});

  final List<TabItem> tabs;

  /// 탭 루트 화면 안에서 다른 탭으로 전환할 때: `TabShell.of(context)?.select(1)`.
  static TabShellState? of(BuildContext context) =>
      context.findAncestorStateOfType<TabShellState>();

  @override
  State<TabShell> createState() => TabShellState();
}

class TabShellState extends State<TabShell> {
  int _index = 0;

  void select(int index) => setState(() => _index = index);

  @override
  Widget build(BuildContext context) => Scaffold(
        body: IndexedStack(
          index: _index,
          children: [for (final t in widget.tabs) t.page],
        ),
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          padding: const EdgeInsets.fromLTRB(8, 10, 8, 10),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                for (var i = 0; i < widget.tabs.length; i++)
                  Expanded(child: _tab(i)),
              ],
            ),
          ),
        ),
      );

  Widget _tab(int i) {
    final selected = i == _index;
    final color = selected ? AppColors.primary : AppColors.textTertiary;
    return InkWell(
      onTap: () => setState(() => _index = i),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIcon(widget.tabs[i].icon, color: color),
          const SizedBox(height: 4),
          Text(
            widget.tabs[i].label,
            style: AppText.style(
              11,
              selected ? FontWeight.w700 : FontWeight.w500,
              color,
            ),
          ),
        ],
      ),
    );
  }
}
