import 'package:drift/drift.dart';

import '../../../core/db/app_database.dart';
import '../domain/share.dart';

/// GenbaShare ↔ Drift 行 / Supabase JSON の変換（`genba_mappers.dart` 準拠）。
///
/// GenbaShare は freezed ではなく素のクラスのため、ここで明示変換する。
/// 日時はローカル Drift では ISO8601(UTC) 文字列、ドメインでは DateTime。

GenbaShare shareFromRow(GenbaShareRow row) => GenbaShare(
      id: row.id,
      ownerId: row.ownerId,
      genbaId: row.genbaId,
      granteeId: row.granteeId,
      role: shareRoleFromCode(row.role) ?? ShareRole.viewer,
      fieldGrants: FieldGrants(
        ticketImage: row.grantTicketImage,
        reservationNumber: row.grantReservation,
        address: row.grantAddress,
        impression: row.grantImpression,
      ),
      version: row.version,
      createdAt: DateTime.parse(row.createdAt),
      updatedAt: DateTime.parse(row.updatedAt),
    );

GenbaSharesCompanion shareToCompanion(GenbaShare share) => GenbaSharesCompanion(
      id: Value(share.id),
      ownerId: Value(share.ownerId),
      genbaId: Value(share.genbaId),
      granteeId: Value(share.granteeId),
      role: Value(share.role.code),
      grantTicketImage: Value(share.fieldGrants.ticketImage),
      grantReservation: Value(share.fieldGrants.reservationNumber),
      grantAddress: Value(share.fieldGrants.address),
      grantImpression: Value(share.fieldGrants.impression),
      version: Value(share.version),
      createdAt: Value(share.createdAt.toUtc().toIso8601String()),
      updatedAt: Value(share.updatedAt.toUtc().toIso8601String()),
    );

/// Supabase 送出用 JSON（列名は snake_case で `genba_shares` と一致）。
/// version/id/owner_id は apply_mutation 側でサーバー管理・矯正されるが、
/// 契約明示のため含める。
Map<String, dynamic> shareToJson(GenbaShare share) => {
      'id': share.id,
      'owner_id': share.ownerId,
      'genba_id': share.genbaId,
      'grantee_id': share.granteeId,
      'role': share.role.code,
      'grant_ticket_image': share.fieldGrants.ticketImage,
      'grant_reservation': share.fieldGrants.reservationNumber,
      'grant_address': share.fieldGrants.address,
      'grant_impression': share.fieldGrants.impression,
      'version': share.version,
      'created_at': share.createdAt.toUtc().toIso8601String(),
      'updated_at': share.updatedAt.toUtc().toIso8601String(),
    };

GenbaShare shareFromJson(Map<String, dynamic> json) => GenbaShare(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String,
      genbaId: json['genba_id'] as String,
      granteeId: json['grantee_id'] as String,
      role: shareRoleFromCode(json['role'] as String?) ?? ShareRole.viewer,
      fieldGrants: FieldGrants(
        ticketImage: json['grant_ticket_image'] as bool? ?? false,
        reservationNumber: json['grant_reservation'] as bool? ?? false,
        address: json['grant_address'] as bool? ?? false,
        impression: json['grant_impression'] as bool? ?? false,
      ),
      version: (json['version'] as num?)?.toInt() ?? 1,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );

GenbaSharesCompanion shareJsonToCompanion(Map<String, dynamic> json) =>
    shareToCompanion(shareFromJson(json));
