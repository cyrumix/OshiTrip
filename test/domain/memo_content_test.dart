import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_trip/features/genba/domain/memo_content.dart';

/// メモ種類の純粋ロジック（§7.7 改訂）: BINGO 判定・投票（重複可否）・JSON往復。
void main() {
  group('MemoBingo 判定', () {
    MemoBingo bingo(int size, List<int> selected) => MemoBingo(
          size: size,
          cells: List.filled(size * size, ''),
          selected: selected,
        );

    test('3×3 横1列で BINGO', () {
      final b = bingo(3, [0, 1, 2]);
      expect(b.lineCount, 1);
      expect(b.hasBingo, isTrue);
    });

    test('3×3 縦1列で BINGO', () {
      expect(bingo(3, [0, 3, 6]).lineCount, 1);
    });

    test('3×3 斜め（両方向）で BINGO', () {
      expect(bingo(3, [0, 4, 8]).lineCount, 1);
      expect(bingo(3, [2, 4, 6]).lineCount, 1);
    });

    test('3×3 複数列そろうと BINGO 数が増える', () {
      // 横0行(0,1,2) と 縦0列(0,3,6) が同時に揃う → 2。
      expect(bingo(3, [0, 1, 2, 3, 6]).lineCount, 2);
    });

    test('4×4 / 5×5 でも判定できる', () {
      expect(bingo(4, [0, 1, 2, 3]).lineCount, 1); // 横
      expect(bingo(5, [0, 6, 12, 18, 24]).lineCount, 1); // 斜め
      expect(bingo(5, [4, 8, 12, 16, 20]).lineCount, 1); // 逆斜め
    });

    test('揃っていなければ BINGO ではない', () {
      expect(bingo(3, [0, 1]).lineCount, 0);
      expect(bingo(3, [0, 1]).hasBingo, isFalse);
      expect(bingo(5, [0, 1, 2, 3]).lineCount, 0);
    });

    test('トグル: 選択→解除で判定が戻る', () {
      var b = bingo(3, [0, 1]);
      b = b.toggle(2); // 揃う
      expect(b.selected, containsAll([0, 1, 2]));
      expect(b.hasBingo, isTrue);
      b = b.toggle(2); // 解除
      expect(b.selected, isNot(contains(2)));
      expect(b.hasBingo, isFalse);
    });

    test('範囲外トグルは無視', () {
      final b = bingo(3, []);
      expect(b.toggle(9).selected, isEmpty);
      expect(b.toggle(-1).selected, isEmpty);
    });
  });

  group('MemoVote 投票', () {
    MemoVoteOption opt(String id) => MemoVoteOption(id: id, text: id);
    MemoVote base({bool dup = false}) => MemoVote(
          options: [opt('a'), opt('b'), opt('c')],
          allowDuplicate: dup,
        );

    test('投票すると得票が増える', () {
      final v = base().castVote(voterId: 'u1', optionId: 'a');
      expect(v.countFor('a'), 1);
      expect(v.hasVoted('u1', 'a'), isTrue);
    });

    test('同じ票を再度入れると取り消し（トグル）', () {
      var v = base().castVote(voterId: 'u1', optionId: 'a');
      v = v.castVote(voterId: 'u1', optionId: 'a');
      expect(v.countFor('a'), 0);
      expect(v.hasVoted('u1', 'a'), isFalse);
    });

    test('重複OFF: 1人1票（別の選択肢へ入れると切り替わる）', () {
      var v = base().castVote(voterId: 'u1', optionId: 'a');
      v = v.castVote(voterId: 'u1', optionId: 'b');
      expect(v.countFor('a'), 0);
      expect(v.countFor('b'), 1);
      expect(v.votes.where((x) => x.voterId == 'u1'), hasLength(1));
    });

    test('重複ON: 同じ人が複数の選択肢へ投票できる', () {
      var v = base(dup: true).castVote(voterId: 'u1', optionId: 'a');
      v = v.castVote(voterId: 'u1', optionId: 'b');
      expect(v.countFor('a'), 1);
      expect(v.countFor('b'), 1);
      expect(v.votes.where((x) => x.voterId == 'u1'), hasLength(2));
    });

    test('複数ユーザーの票を独立に保持（将来の複数人共有を見据える）', () {
      var v = base().castVote(voterId: 'u1', optionId: 'a');
      v = v.castVote(voterId: 'u2', optionId: 'a');
      expect(v.countFor('a'), 2);
    });
  });

  group('MemoContent JSON 往復', () {
    test('checklist/bingo/vote を含む content が round-trip する', () {
      const content = MemoContent(
        checklist: [
          MemoChecklistItem(id: 'i1', text: 'ペンライト', checked: true),
        ],
        bingo: MemoBingo(size: 3, cells: ['a', 'b'], selected: [0]),
        vote: MemoVote(
          description: '説明',
          options: [MemoVoteOption(id: 'o1', text: 'A')],
          votes: [MemoVoteRecord(voterId: 'u1', optionId: 'o1')],
          allowDuplicate: true,
        ),
      );
      final restored = MemoContent.fromJson(content.toJson());
      expect(restored, content);
    });
  });
}
