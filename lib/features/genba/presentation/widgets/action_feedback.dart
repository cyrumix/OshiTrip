import 'package:flutter/material.dart';

import '../../../../core/error/failure.dart';

/// [Failure]（null=成功）を一貫して処理する: 失敗時は理由を SnackBar で示し、
/// 成功していない操作を成功表示しない（H-07/M-01）。
void handleActionResult(BuildContext context, Failure? failure) {
  if (failure == null) return;
  if (!context.mounted) return;
  ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(failure.message)));
}
