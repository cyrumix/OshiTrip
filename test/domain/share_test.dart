import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_trip/features/sharing/domain/share.dart';

/// 現場共有ドメイン（Phase 5 前提基盤）: 共有行の不変条件・role コード・
/// 項目grant の安全側既定を検証する。
void main() {
  group('shareInvariantError', () {
    test('editor/viewer かつ grantee≠owner なら妥当（null）', () {
      expect(
        shareInvariantError(
          ownerId: 'u1',
          granteeId: 'u2',
          role: ShareRole.editor,
        ),
        isNull,
      );
      expect(
        shareInvariantError(
          ownerId: 'u1',
          granteeId: 'u2',
          role: ShareRole.viewer,
        ),
        isNull,
      );
    });

    test('自分自身へは共有できない', () {
      expect(
        shareInvariantError(
          ownerId: 'u1',
          granteeId: 'u1',
          role: ShareRole.viewer,
        ),
        isNotNull,
      );
    });

    test('共有先が空は不可', () {
      expect(
        shareInvariantError(
          ownerId: 'u1',
          granteeId: '  ',
          role: ShareRole.viewer,
        ),
        isNotNull,
      );
    });

    test('owner ロールは共有行にできない（editor/viewer のみ）', () {
      expect(
        shareInvariantError(
          ownerId: 'u1',
          granteeId: 'u2',
          role: ShareRole.owner,
        ),
        isNotNull,
      );
    });
  });

  group('ShareRole コード', () {
    test('code 往復（editor/viewer）', () {
      expect(ShareRole.editor.code, 'editor');
      expect(ShareRole.viewer.code, 'viewer');
      expect(shareRoleFromCode('editor'), ShareRole.editor);
      expect(shareRoleFromCode('viewer'), ShareRole.viewer);
    });

    test('owner/未知コードは共有行の role として null', () {
      expect(shareRoleFromCode('owner'), isNull);
      expect(shareRoleFromCode('bogus'), isNull);
      expect(shareRoleFromCode(null), isNull);
    });
  });

  group('FieldGrants', () {
    test('既定は全項目 false（安全側）', () {
      const g = FieldGrants();
      expect(g.ticketImage, isFalse);
      expect(g.reservationNumber, isFalse);
      expect(g.address, isFalse);
      expect(g.impression, isFalse);
    });

    test('copyWith で一部だけ許可でき、等価判定が効く', () {
      const g = FieldGrants();
      final g2 = g.copyWith(address: true);
      expect(g2.address, isTrue);
      expect(g2.ticketImage, isFalse);
      expect(g2, const FieldGrants(address: true));
      expect(g2 == g, isFalse);
    });
  });
}
