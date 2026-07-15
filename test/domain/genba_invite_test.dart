import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_trip/features/sharing/domain/genba_invite.dart';
import 'package:oshi_trip/features/sharing/domain/share.dart';

void main() {
  final now = DateTime.utc(2026, 7, 11, 12);

  group('inviteValidityError（revoked→expired→exhausted の順, §3/§7）', () {
    test('制約なしは有効（null）', () {
      expect(
        inviteValidityError(
          revokedAt: null,
          expiresAt: null,
          maxUses: null,
          usedCount: 0,
          now: now,
        ),
        isNull,
      );
    });

    test('無効化済みは invite_revoked（期限・上限より優先）', () {
      expect(
        inviteValidityError(
          revokedAt: now.subtract(const Duration(minutes: 1)),
          expiresAt: now.subtract(const Duration(days: 1)),
          maxUses: 1,
          usedCount: 5,
          now: now,
        ),
        'invite_revoked',
      );
    });

    test('期限切れは invite_expired', () {
      expect(
        inviteValidityError(
          revokedAt: null,
          expiresAt: now.subtract(const Duration(seconds: 1)),
          maxUses: null,
          usedCount: 0,
          now: now,
        ),
        'invite_expired',
      );
      // 未来の期限は有効。
      expect(
        inviteValidityError(
          revokedAt: null,
          expiresAt: now.add(const Duration(hours: 1)),
          maxUses: null,
          usedCount: 0,
          now: now,
        ),
        isNull,
      );
    });

    test('使用上限到達は invite_exhausted', () {
      expect(
        inviteValidityError(
          revokedAt: null,
          expiresAt: null,
          maxUses: 2,
          usedCount: 2,
          now: now,
        ),
        'invite_exhausted',
      );
      // 上限未満は有効。
      expect(
        inviteValidityError(
          revokedAt: null,
          expiresAt: null,
          maxUses: 2,
          usedCount: 1,
          now: now,
        ),
        isNull,
      );
    });
  });

  group('inviteUrlFor / inviteTokenFromUrl', () {
    test('URL 組み立て', () {
      expect(inviteUrlFor('abc123'), 'https://oshitrip.app/invite/abc123');
    });

    test('標準 URL からトークンを取り出す', () {
      expect(
        inviteTokenFromUrl('https://oshitrip.app/invite/deadbeef1234'),
        'deadbeef1234',
      );
    });

    test('末尾スラッシュ・クエリ付きでも取り出す', () {
      expect(
        inviteTokenFromUrl('https://oshitrip.app/invite/deadbeef1234?x=1'),
        'deadbeef1234',
      );
    });

    test('16進トークンの直貼りを受け付ける', () {
      expect(inviteTokenFromUrl('  0123456789abcdef  '), '0123456789abcdef');
    });

    test('invite を含まない URL・空・非トークン文字列は null', () {
      expect(inviteTokenFromUrl('https://oshitrip.app/genba/xyz'), isNull);
      expect(inviteTokenFromUrl(''), isNull);
      expect(inviteTokenFromUrl('   '), isNull);
      expect(inviteTokenFromUrl('not a token'), isNull);
    });
  });

  group('inviteJoinStatusFromCode', () {
    test('コードを列挙へ変換', () {
      expect(inviteJoinStatusFromCode('joined'), InviteJoinStatus.joined);
      expect(
        inviteJoinStatusFromCode('already_member'),
        InviteJoinStatus.alreadyMember,
      );
      expect(inviteJoinStatusFromCode('owner'), InviteJoinStatus.owner);
    });
  });

  test('GenbaInvite.isValidAt / url / 既定 role=viewer', () {
    final invite = GenbaInvite(
      id: 'i1',
      genbaId: 'g1',
      ownerId: 'u1',
      token: 'abcdef123456',
      expiresAt: now.add(const Duration(days: 1)),
      createdAt: now,
      updatedAt: now,
    );
    expect(invite.defaultRole, ShareRole.viewer);
    expect(invite.url, 'https://oshitrip.app/invite/abcdef123456');
    expect(invite.isValidAt(now), isTrue);
    expect(
      invite.isValidAt(now.add(const Duration(days: 2))),
      isFalse, // 期限切れ
    );
  });
}
