import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_trip/features/genba/application/memo_template_providers.dart';
import 'package:oshi_trip/features/genba/domain/memo_content.dart';
import 'package:oshi_trip/features/genba/domain/memo_template_presets.dart';

/// 既定メモテンプレート（§7.7 改訂）: 5件・全て自由メモ・名前指定・雛形の初期化。
void main() {
  test('デフォルトは5件ですべて自由メモ、名前は指定どおり', () {
    expect(kMemoTemplatePresets, hasLength(5));
    expect(kMemoTemplatePresets.every((p) => p.kind == MemoKind.free), isTrue);
    expect(
      kMemoTemplatePresets.map((p) => p.name),
      ['自由メモ', '物販', '集合', '周辺施設', '注意事項'],
    );
  });

  test('memoPresetsOfKind: free は5件、他の種類は0件', () {
    expect(memoPresetsOfKind(MemoKind.free), hasLength(5));
    expect(memoPresetsOfKind(MemoKind.checklist), isEmpty);
    expect(memoPresetsOfKind(MemoKind.bingo), isEmpty);
    expect(memoPresetsOfKind(MemoKind.vote), isEmpty);
  });

  test('集合プリセットは today_card 互換の meetup 区分を持つ', () {
    final meetup = kMemoTemplatePresets.firstWhere((p) => p.name == '集合');
    expect(meetup.category, MemoCategory.meetup);
    expect(meetup.title, '集合場所');
  });

  test('MemoTemplateOption.fromPreset は isPreset=true', () {
    final option = MemoTemplateOption.fromPreset(kMemoTemplatePresets.first);
    expect(option.isPreset, isTrue);
    expect(option.name, '自由メモ');
    expect(option.kind, MemoKind.free);
  });

  test('blueprintContent は状態（チェック・BINGO選択・票）を初期化する', () {
    const content = MemoContent(
      checklist: [
        MemoChecklistItem(id: 'i', text: 'x', checked: true),
      ],
      bingo: MemoBingo(size: 3, cells: ['a'], selected: [0, 1]),
      vote: MemoVote(
        options: [MemoVoteOption(id: 'o', text: 'A')],
        votes: [MemoVoteRecord(voterId: 'u', optionId: 'o')],
      ),
    );
    final blueprint = blueprintContent(content)!;
    // 文言・選択肢・サイズは残す。
    expect(blueprint.checklist.single.text, 'x');
    expect(blueprint.bingo!.cells, ['a']);
    expect(blueprint.vote!.options, hasLength(1));
    // 状態はリセット。
    expect(blueprint.checklist.single.checked, isFalse);
    expect(blueprint.bingo!.selected, isEmpty);
    expect(blueprint.vote!.votes, isEmpty);
  });

  test('blueprintContent(null) は null', () {
    expect(blueprintContent(null), isNull);
  });
}
