import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../../../core/providers.dart';
import '../domain/genba.dart';
import '../domain/memo_template.dart';
import '../domain/memo_template_presets.dart';

/// ユーザー保存のメモテンプレート一覧。
final userMemoTemplatesProvider = StreamProvider<List<MemoTemplate>>(
  (ref) => ref.watch(memoTemplateRepositoryProvider).watchAll(),
);

/// 指定した種類のテンプレート選択肢（プリセット＋ユーザー保存、その種類のみ）。
/// プリセットは先頭・ローディング中も出す。
final memoTemplateOptionsProvider =
    Provider.family<List<MemoTemplateOption>, MemoKind>((ref, kind) {
  final presets =
      memoPresetsOfKind(kind).map(MemoTemplateOption.fromPreset).toList();
  final user = (ref.watch(userMemoTemplatesProvider).valueOrNull ?? const [])
      .where((t) => t.kind == kind)
      .map(MemoTemplateOption.fromTemplate)
      .toList();
  return [...presets, ...user];
});

/// メモテンプレートの操作（保存）。
final memoTemplateActionsProvider =
    Provider<MemoTemplateActions>(MemoTemplateActions.new);

class MemoTemplateActions {
  MemoTemplateActions(this.ref);

  final Ref ref;
  static const _uuid = Uuid();

  String? get _ownerId => ref.read(authRepositoryProvider).currentUser?.id;
  DateTime get _now => ref.read(clockProvider).now().toUtc();

  /// メモの構成をテンプレートとして保存する。既に作成済みのメモには影響しない
  /// （別 id の新規テンプレートを作るコピー方式）。投票の票・チェック・BINGO の
  /// 選択状態は雛形に残さず、適用時に初期状態から始める。
  Future<Result<void>> saveMemoAsTemplate({
    required String name,
    required GenbaMemo memo,
  }) async {
    final owner = _ownerId;
    if (owner == null || owner.isEmpty) {
      return const Err(AuthFailure(message: 'ログインが必要です'));
    }
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return const Err(ValidationFailure('テンプレート名を入力してください'));
    }
    final now = _now;
    final template = MemoTemplate(
      id: _uuid.v4(),
      ownerId: owner,
      name: trimmed,
      kind: memo.kind,
      category: memo.category,
      title: memo.title,
      body: memo.body,
      content: blueprintContent(memo.content),
      createdAt: now,
      updatedAt: now,
    );
    return ref.read(memoTemplateRepositoryProvider).upsertTemplate(template);
  }
}

/// 雛形用に、状態（チェック・BINGO選択・票）を初期化した content を返す。
MemoContent? blueprintContent(MemoContent? content) {
  if (content == null) return null;
  return content.copyWith(
    checklist: [
      for (final i in content.checklist) i.copyWith(checked: false),
    ],
    bingo: content.bingo?.copyWith(selected: const []),
    vote: content.vote?.copyWith(votes: const []),
  );
}
