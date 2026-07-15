import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_trip/features/social/domain/friendship.dart';

void main() {
  group('friendshipStatusFromCode / code', () {
    test('往復変換が一致する', () {
      for (final s in FriendshipStatus.values) {
        expect(friendshipStatusFromCode(s.code), s);
      }
    });
    test('未知コード・null は none', () {
      expect(friendshipStatusFromCode(null), FriendshipStatus.none);
      expect(friendshipStatusFromCode('???'), FriendshipStatus.none);
    });
  });

  group('canSendFriendRequest（無制限検索禁止, §2/§7）', () {
    test('searchable な相手には申請できる', () {
      expect(
        canSendFriendRequest(
          selfId: 'u1',
          targetId: 'u2',
          targetSearchable: true,
          targetAcceptsRequests: true,
          sharesGenba: false,
        ),
        isNull,
      );
    });

    test('同一現場の共有メンバーには申請できる（searchable でなくても）', () {
      expect(
        canSendFriendRequest(
          selfId: 'u1',
          targetId: 'u2',
          targetSearchable: false,
          targetAcceptsRequests: true,
          sharesGenba: true,
        ),
        isNull,
      );
    });

    test('searchable でも同一現場メンバーでもない相手には申請できない', () {
      expect(
        canSendFriendRequest(
          selfId: 'u1',
          targetId: 'u2',
          targetSearchable: false,
          targetAcceptsRequests: true,
          sharesGenba: false,
        ),
        isNotNull,
      );
    });

    test('相手が申請を受け付けていない/ブロック/自分自身は不可', () {
      expect(
        canSendFriendRequest(
          selfId: 'u1',
          targetId: 'u2',
          targetSearchable: true,
          targetAcceptsRequests: false,
          sharesGenba: true,
        ),
        isNotNull,
      );
      expect(
        canSendFriendRequest(
          selfId: 'u1',
          targetId: 'u2',
          targetSearchable: true,
          targetAcceptsRequests: true,
          sharesGenba: true,
          isBlocked: true,
        ),
        isNotNull,
      );
      expect(
        canSendFriendRequest(
          selfId: 'u1',
          targetId: 'u1',
          targetSearchable: true,
          targetAcceptsRequests: true,
          sharesGenba: true,
        ),
        isNotNull,
      );
    });
  });

  group('friendshipRespondError（受信者かつ pending のみ）', () {
    test('受信者が pending へ応答できる', () {
      expect(
        friendshipRespondError(
          status: FriendshipStatus.pending,
          isReceiver: true,
        ),
        isNull,
      );
    });
    test('受信者でなければ応答できない', () {
      expect(
        friendshipRespondError(
          status: FriendshipStatus.pending,
          isReceiver: false,
        ),
        isNotNull,
      );
    });
    test('pending 以外へは応答できない', () {
      expect(
        friendshipRespondError(
          status: FriendshipStatus.accepted,
          isReceiver: true,
        ),
        isNotNull,
      );
    });
  });

  test('Friendship.otherId / isReceiver', () {
    final f = Friendship(
      id: 'f1',
      requesterId: 'u1',
      receiverId: 'u2',
      status: FriendshipStatus.pending,
      createdAt: DateTime.utc(2026, 7, 11),
      updatedAt: DateTime.utc(2026, 7, 11),
    );
    expect(f.otherId('u1'), 'u2');
    expect(f.otherId('u2'), 'u1');
    expect(f.isReceiver('u2'), isTrue);
    expect(f.isReceiver('u1'), isFalse);
  });
}
