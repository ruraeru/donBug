import 'package:flutter/material.dart';

import '../../data/app_scope.dart';
import '../../data/format.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import 'employee_parts.dart';

/// 보건증 등록: 사진(데모) · 만료일 · 만료 알림.
class HealthCertRegisterScreen extends StatefulWidget {
  const HealthCertRegisterScreen({super.key});

  @override
  State<HealthCertRegisterScreen> createState() => _HealthCertRegisterScreenState();
}

class _HealthCertRegisterScreenState extends State<HealthCertRegisterScreen> {
  static const _alerts = [(30, 'D-30', '한 달 전 알림'), (14, 'D-14', null), (7, 'D-7', null), (0, 'D-Day', null)];

  bool _photo = false;
  late DateTime _expiry;
  late Set<int> _days;

  @override
  void initState() {
    super.initState();
    final store = AppScope.read(context);
    final p = store.person(store.session.employeeId);
    _expiry = DateTime(store.today.year + 1, store.today.month, store.today.day);
    _days = p.certAlertDays.toSet();
  }

  Future<void> _pickDate() async {
    final today = AppScope.read(context).today;
    final d = await showDatePicker(
      context: context,
      initialDate: _expiry,
      firstDate: today,
      lastDate: DateTime(today.year + 3),
    );
    if (d != null) setState(() => _expiry = d);
  }

  void _submit() {
    if (!_photo) return showToast(context, '보건증 사진을 올려 주세요');
    AppScope.read(context).uploadHealthCert(
        expiry: _expiry, alertDays: _days.toList()..sort((a, b) => b - a));
    Navigator.pop(context);
    showToast(context, '보건증을 등록했어요');
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: const AppHeader('보건증 등록'),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          children: [
            Material(
              color: _photo ? AppColors.primarySoft : AppColors.surface,
              shape: RoundedRectangleBorder(
                side: BorderSide(color: _photo ? AppColors.primary : AppColors.border),
                borderRadius: BorderRadius.circular(20),
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                // shortcut: 데모라 실제 카메라·앨범 대신 탭하면 사진이 선택된 것으로 처리.
                onTap: () => setState(() => _photo = !_photo),
                child: SizedBox(
                  height: 180,
                  width: double.infinity,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(_photo ? Icons.check_circle : Icons.add,
                          size: 40, color: AppColors.primary),
                      const SizedBox(height: 8),
                      Text(_photo ? '보건증 사진 선택됨 (데모)' : '보건증 사진 올리기',
                          style: AppText.style(15, FontWeight.w500)),
                      const SizedBox(height: 8),
                      Text(_photo ? '다시 탭하면 선택을 취소해요' : '카메라 촬영 또는 앨범에서 선택 · 데모는 탭',
                          style: AppText.style(12, FontWeight.w400, AppColors.textSecondary)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('만료일', style: AppText.style(14, FontWeight.w500, AppColors.textSecondary)),
            const SizedBox(height: 8),
            FieldBox(dotDate(_expiry), onTap: _pickDate),
            const SizedBox(height: 16),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('만료 알림 받기',
                      style: AppText.style(14, FontWeight.w500, AppColors.textSecondary)),
                  for (final (d, label, caption) in _alerts) ...[
                    const SizedBox(height: 12),
                    CheckLine(label,
                        caption: caption,
                        value: _days.contains(d),
                        onChanged: (v) => setState(() => v ? _days.add(d) : _days.remove(d))),
                  ],
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: BottomBar(child: AppButton('등록하기', onPressed: _submit)),
      );
}
