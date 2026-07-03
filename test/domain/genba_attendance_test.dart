import 'package:flutter_test/flutter_test.dart';

import 'package:oshi_trip/core/images/image_upload_status.dart';
import 'package:oshi_trip/features/genba/domain/genba.dart';

import '../helpers/fixtures.dart';

void main() {
  Genba base() => makeGenba(eventDate: DateTime(2026, 8, 1));

  group('normalizeAttendance（中止 ⟹ 参加状態 canceled）', () {
    test('中止なのに参加状態が canceled でなければ canceled へ矯正する', () {
      final g = base().copyWith(
        isCanceled: true,
        attendanceStatus: AttendanceStatus.planned,
      );
      expect(
        normalizeAttendance(g).attendanceStatus,
        AttendanceStatus.canceled,
      );
    });

    test('中止でない現場の attended はそのまま保持する（勝手に消さない）', () {
      final g = base().copyWith(
        isCanceled: false,
        attendanceStatus: AttendanceStatus.attended,
      );
      expect(
        normalizeAttendance(g).attendanceStatus,
        AttendanceStatus.attended,
      );
    });

    test('既定は planned', () {
      expect(base().attendanceStatus, AttendanceStatus.planned);
    });
  });

  group('heroImage getter（チケット画像とは別の明確な型）', () {
    test('参照が一切無ければ null（画像なしで縮退できる）', () {
      expect(base().heroImage, isNull);
    });

    test('local/storage/alt のいずれかがあれば型を返す', () {
      final g = base().copyWith(
        heroImageLocalPath: 'images/user-1/hero/x.jpg',
        heroImageAltText: '公演の様子',
        heroImageUploadStatus: ImageUploadStatus.uploaded,
        heroImageStoragePath: 'hero/x.jpg',
      );
      final hero = g.heroImage;
      expect(hero, isNotNull);
      expect(hero!.localPath, 'images/user-1/hero/x.jpg');
      expect(hero.storagePath, 'hero/x.jpg');
      expect(hero.altText, '公演の様子');
      expect(hero.uploadStatus, ImageUploadStatus.uploaded);
    });

    test('hero 画像フィールドはチケット画像フィールドと独立している', () {
      // hero 画像を設定してもチケット由来の値には一切依存しない（別用途・別列）。
      final g = base().copyWith(heroImageLocalPath: 'hero.jpg');
      expect(g.heroImage?.localPath, 'hero.jpg');
      // Genba にチケット画像フィールドは存在しない（Ticket 側に分離されている）。
    });
  });
}
