import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:signature/signature.dart';

import '../theme.dart';

/// 서버 모드 서명 패드. 그린 서명을 PNG 로 뽑는다 (`controller.toPngBytes()`).
class SignatureInput extends StatelessWidget {
  const SignatureInput({super.key, required this.controller});

  final SignatureController controller;

  static SignatureController newController() => SignatureController(
      penStrokeWidth: 3, penColor: Colors.black, exportBackgroundColor: Colors.white);

  /// 비어 있으면 null.
  static Future<Uint8List?> png(SignatureController c) async =>
      c.isEmpty ? null : c.toPngBytes();

  @override
  Widget build(BuildContext context) => Container(
        height: 140,
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(children: [
          Positioned.fill(
              child: Signature(
                  controller: controller, backgroundColor: Colors.transparent)),
          Positioned(
            right: 8,
            top: 4,
            child: TextButton(
              onPressed: controller.clear,
              child: Text('지우기',
                  style: AppText.style(13, FontWeight.w500, AppColors.textSecondary)),
            ),
          ),
        ]),
      );
}
