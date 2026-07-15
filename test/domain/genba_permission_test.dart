import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_trip/features/sharing/domain/genba_permission.dart';
import 'package:oshi_trip/features/sharing/domain/share.dart';

void main() {
  group('genbaPermissionFor（サーバー 0031 の可否と一致）', () {
    test('owner は全操作可・共有バッジなし', () {
      final p = genbaPermissionFor(isOwner: true);
      expect(p.role, GenbaAccessRole.owner);
      expect(p.canView, isTrue);
      expect(p.canEditContent, isTrue);
      expect(p.canManageMembers, isTrue);
      expect(p.canDeleteGenba, isTrue);
      expect(p.isShared, isFalse);
    });

    test('editor は閲覧・編集可、削除/メンバー管理は不可、共有バッジあり', () {
      final p =
          genbaPermissionFor(isOwner: false, memberRole: ShareRole.editor);
      expect(p.role, GenbaAccessRole.editor);
      expect(p.canView, isTrue);
      expect(p.canEditContent, isTrue);
      expect(p.canManageMembers, isFalse);
      expect(p.canDeleteGenba, isFalse);
      expect(p.isShared, isTrue);
    });

    test('viewer は閲覧のみ、編集/管理は不可、共有バッジあり', () {
      final p =
          genbaPermissionFor(isOwner: false, memberRole: ShareRole.viewer);
      expect(p.role, GenbaAccessRole.viewer);
      expect(p.canView, isTrue);
      expect(p.canEditContent, isFalse);
      expect(p.canManageMembers, isFalse);
      expect(p.isShared, isTrue);
    });

    test('未共有は一切不可', () {
      final p = genbaPermissionFor(isOwner: false);
      expect(p.role, GenbaAccessRole.none);
      expect(p.canView, isFalse);
      expect(p.canEditContent, isFalse);
      expect(p.isShared, isFalse);
    });

    test('owner 判定は memberRole より優先する', () {
      final p = genbaPermissionFor(isOwner: true, memberRole: ShareRole.viewer);
      expect(p.role, GenbaAccessRole.owner);
      expect(p.canManageMembers, isTrue);
    });
  });

  test('label', () {
    expect(genbaPermissionFor(isOwner: true).label, 'オーナー');
    expect(
      genbaPermissionFor(isOwner: false, memberRole: ShareRole.editor).label,
      '編集可',
    );
    expect(
      genbaPermissionFor(isOwner: false, memberRole: ShareRole.viewer).label,
      '閲覧のみ',
    );
  });
}
