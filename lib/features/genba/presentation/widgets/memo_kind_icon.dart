import 'package:flutter/material.dart';

import '../../domain/memo_content.dart';

/// メモ種類のアイコン（一覧・選択・管理で共通利用）。
IconData memoKindIcon(MemoKind kind) => switch (kind) {
      MemoKind.free => Icons.sticky_note_2_outlined,
      MemoKind.checklist => Icons.checklist_rtl,
      MemoKind.bingo => Icons.grid_view_rounded,
      MemoKind.vote => Icons.how_to_vote_outlined,
    };
