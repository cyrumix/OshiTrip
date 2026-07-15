import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_trip/features/social/domain/profile.dart';

void main() {
  group('profileInvariantError（サーバー CHECK と一致, §1）', () {
    test('表示名があり上限内なら null（有効）', () {
      expect(profileInvariantError(displayName: 'あさい'), isNull);
      expect(
        profileInvariantError(
          displayName: 'あさい',
          bio: '推し活してます',
          favoriteName: 'ARASHI',
        ),
        isNull,
      );
    });

    test('表示名が空/空白のみは拒否', () {
      expect(profileInvariantError(displayName: ''), isNotNull);
      expect(profileInvariantError(displayName: '   '), isNotNull);
    });

    test('表示名が上限超過は拒否', () {
      final tooLong = 'あ' * (kDisplayNameMaxLength + 1);
      expect(profileInvariantError(displayName: tooLong), isNotNull);
      // 上限ちょうどは許容。
      expect(
        profileInvariantError(displayName: 'あ' * kDisplayNameMaxLength),
        isNull,
      );
    });

    test('ひとこと・推し名が上限超過は拒否', () {
      expect(
        profileInvariantError(
          displayName: 'あさい',
          bio: 'あ' * (kBioMaxLength + 1),
        ),
        isNotNull,
      );
      expect(
        profileInvariantError(
          displayName: 'あさい',
          favoriteName: 'あ' * (kFavoriteNameMaxLength + 1),
        ),
        isNotNull,
      );
    });
  });

  test('copyWith は指定フィールドだけを差し替える', () {
    final base = Profile(
      userId: 'u1',
      displayName: 'あさい',
      friendCode: 'OSHI-7K3P-Q9A2',
      createdAt: DateTime.utc(2026, 7, 11),
      updatedAt: DateTime.utc(2026, 7, 11),
    );
    final updated = base.copyWith(searchable: true, bio: 'こんにちは');
    expect(updated.userId, 'u1');
    expect(updated.displayName, 'あさい');
    expect(updated.searchable, isTrue);
    expect(updated.bio, 'こんにちは');
    // 既定値は保持。
    expect(updated.acceptsFriendRequests, isTrue);
    // friend_code はサーバー採番のため copyWith でも保持する。
    expect(updated.friendCode, 'OSHI-7K3P-Q9A2');
  });

  test('friendCode は未指定なら空（サーバーから取得して埋める）', () {
    final p = Profile(
      userId: 'u1',
      displayName: 'あさい',
      createdAt: DateTime.utc(2026, 7, 11),
      updatedAt: DateTime.utc(2026, 7, 11),
    );
    expect(p.friendCode, isEmpty);
  });
}
