import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../core/db/app_database.dart';
import '../domain/genba.dart';

/// Drift 行 ⇄ ドメインエンティティのマッピング。
///
/// JSON（サーバー行 / Outbox payload）とのマッピングはエンティティ側の
/// `fromJson/toJson`（snake_case）が担う。
Genba genbaFromRow(GenbaRow row) => Genba(
      id: row.id,
      ownerId: row.ownerId,
      artistName: row.artistName,
      title: row.title,
      eventDate: DateTime.parse(row.eventDate),
      oshiGroupId: row.oshiGroupId,
      oshiMemberIds:
          (jsonDecode(row.oshiMemberIds) as List<dynamic>).cast<String>(),
      venue: row.venue,
      doorTimeMinutes: row.doorTimeMinutes,
      startTimeMinutes: row.startTimeMinutes,
      endTimeMinutes: row.endTimeMinutes,
      performanceType: row.performanceType,
      performanceId: row.performanceId,
      isExpedition: row.isExpedition,
      transportRequirement: _requirement(row.transportRequirement),
      lodgingRequirement: _requirement(row.lodgingRequirement),
      isCanceled: row.isCanceled,
      manualEndedAt:
          row.manualEndedAt == null ? null : DateTime.parse(row.manualEndedAt!),
      createdAt: DateTime.parse(row.createdAt),
      updatedAt: DateTime.parse(row.updatedAt),
    );

GenbasCompanion genbaToCompanion(Genba g) => GenbasCompanion.insert(
      id: g.id,
      ownerId: g.ownerId,
      artistName: g.artistName,
      title: g.title,
      eventDate: _date(g.eventDate),
      oshiGroupId: Value(g.oshiGroupId),
      oshiMemberIds: Value(jsonEncode(g.oshiMemberIds)),
      venue: Value(g.venue),
      doorTimeMinutes: Value(g.doorTimeMinutes),
      startTimeMinutes: Value(g.startTimeMinutes),
      endTimeMinutes: Value(g.endTimeMinutes),
      performanceType: Value(g.performanceType),
      performanceId: Value(g.performanceId),
      isExpedition: Value(g.isExpedition),
      transportRequirement: Value(_requirementName(g.transportRequirement)),
      lodgingRequirement: Value(_requirementName(g.lodgingRequirement)),
      isCanceled: Value(g.isCanceled),
      manualEndedAt: Value(g.manualEndedAt?.toUtc().toIso8601String()),
      createdAt: _ts(g.createdAt),
      updatedAt: _ts(g.updatedAt),
    );

Ticket ticketFromRow(TicketRow row) => Ticket(
      id: row.id,
      genbaId: row.genbaId,
      ownerId: row.ownerId,
      acquisitionStatus: _enumFromJson(
        TicketAcquisition.values,
        row.acquisitionStatus,
        TicketAcquisition.notApplied,
      ),
      paymentStatus: _enumFromJson(
        TicketPayment.values,
        row.paymentStatus,
        TicketPayment.unpaid,
      ),
      issuanceStatus: _enumFromJson(
        TicketIssuance.values,
        row.issuanceStatus,
        TicketIssuance.notIssued,
      ),
      seat: row.seat,
      entryNumber: row.entryNumber,
      gate: row.gate,
      url: row.url,
      imagePath: row.imagePath,
      imageLocalPath: row.imageLocalPath,
      memo: row.memo,
      createdAt: DateTime.parse(row.createdAt),
      updatedAt: DateTime.parse(row.updatedAt),
    );

TicketsCompanion ticketToCompanion(Ticket t) => TicketsCompanion.insert(
      id: t.id,
      genbaId: t.genbaId,
      ownerId: t.ownerId,
      acquisitionStatus: Value(_snake(t.acquisitionStatus.name)),
      paymentStatus: Value(_snake(t.paymentStatus.name)),
      issuanceStatus: Value(_snake(t.issuanceStatus.name)),
      seat: Value(t.seat),
      entryNumber: Value(t.entryNumber),
      gate: Value(t.gate),
      url: Value(t.url),
      imagePath: Value(t.imagePath),
      imageLocalPath: Value(t.imageLocalPath),
      memo: Value(t.memo),
      createdAt: _ts(t.createdAt),
      updatedAt: _ts(t.updatedAt),
    );

Transport transportFromRow(TransportRow row) => Transport(
      id: row.id,
      genbaId: row.genbaId,
      ownerId: row.ownerId,
      direction: row.direction == 'inbound'
          ? TransportDirection.inbound
          : TransportDirection.outbound,
      method: row.method,
      fromPlace: row.fromPlace,
      toPlace: row.toPlace,
      departAt: row.departAt == null ? null : DateTime.parse(row.departAt!),
      arriveAt: row.arriveAt == null ? null : DateTime.parse(row.arriveAt!),
      reservationNumber: row.reservationNumber,
      url: row.url,
      memo: row.memo,
      createdAt: DateTime.parse(row.createdAt),
      updatedAt: DateTime.parse(row.updatedAt),
    );

TransportsCompanion transportToCompanion(Transport t) =>
    TransportsCompanion.insert(
      id: t.id,
      genbaId: t.genbaId,
      ownerId: t.ownerId,
      direction: Value(t.direction.name),
      method: Value(t.method),
      fromPlace: Value(t.fromPlace),
      toPlace: Value(t.toPlace),
      departAt: Value(t.departAt?.toUtc().toIso8601String()),
      arriveAt: Value(t.arriveAt?.toUtc().toIso8601String()),
      reservationNumber: Value(t.reservationNumber),
      url: Value(t.url),
      memo: Value(t.memo),
      createdAt: _ts(t.createdAt),
      updatedAt: _ts(t.updatedAt),
    );

Lodging lodgingFromRow(LodgingRow row) => Lodging(
      id: row.id,
      genbaId: row.genbaId,
      ownerId: row.ownerId,
      name: row.name,
      checkinDate:
          row.checkinDate == null ? null : DateTime.parse(row.checkinDate!),
      checkoutDate:
          row.checkoutDate == null ? null : DateTime.parse(row.checkoutDate!),
      address: row.address,
      reservationNumber: row.reservationNumber,
      url: row.url,
      memo: row.memo,
      createdAt: DateTime.parse(row.createdAt),
      updatedAt: DateTime.parse(row.updatedAt),
    );

LodgingsCompanion lodgingToCompanion(Lodging l) => LodgingsCompanion.insert(
      id: l.id,
      genbaId: l.genbaId,
      ownerId: l.ownerId,
      name: Value(l.name),
      checkinDate: Value(l.checkinDate == null ? null : _date(l.checkinDate!)),
      checkoutDate:
          Value(l.checkoutDate == null ? null : _date(l.checkoutDate!)),
      address: Value(l.address),
      reservationNumber: Value(l.reservationNumber),
      url: Value(l.url),
      memo: Value(l.memo),
      createdAt: _ts(l.createdAt),
      updatedAt: _ts(l.updatedAt),
    );

GenbaTodo todoFromRow(TodoRow row) => GenbaTodo(
      id: row.id,
      genbaId: row.genbaId,
      ownerId: row.ownerId,
      name: row.name,
      dueDate: row.dueDate == null ? null : DateTime.parse(row.dueDate!),
      isDone: row.isDone,
      assignee: row.assignee,
      priority: _enumFromJson(
        TodoPriority.values,
        row.priority,
        TodoPriority.normal,
      ),
      memo: row.memo,
      sortOrder: row.sortOrder,
      createdAt: DateTime.parse(row.createdAt),
      updatedAt: DateTime.parse(row.updatedAt),
    );

TodosCompanion todoToCompanion(GenbaTodo t) => TodosCompanion.insert(
      id: t.id,
      genbaId: t.genbaId,
      ownerId: t.ownerId,
      name: t.name,
      dueDate: Value(t.dueDate == null ? null : _date(t.dueDate!)),
      isDone: Value(t.isDone),
      assignee: Value(t.assignee),
      priority: Value(t.priority.name),
      memo: Value(t.memo),
      sortOrder: Value(t.sortOrder),
      createdAt: _ts(t.createdAt),
      updatedAt: _ts(t.updatedAt),
    );

GenbaMemo memoFromRow(GenbaMemoRow row) => GenbaMemo(
      id: row.id,
      genbaId: row.genbaId,
      ownerId: row.ownerId,
      category: _enumFromJson(
        MemoCategory.values,
        row.category,
        MemoCategory.free,
      ),
      body: row.body,
      createdAt: DateTime.parse(row.createdAt),
      updatedAt: DateTime.parse(row.updatedAt),
    );

GenbaMemosCompanion memoToCompanion(GenbaMemo m) => GenbaMemosCompanion.insert(
      id: m.id,
      genbaId: m.genbaId,
      ownerId: m.ownerId,
      category: m.category.name,
      body: Value(m.body),
      createdAt: _ts(m.createdAt),
      updatedAt: _ts(m.updatedAt),
    );

String _date(DateTime d) {
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '${d.year}-$m-$day';
}

String _ts(DateTime d) => d.toUtc().toIso8601String();

RequirementStatus _requirement(String value) => switch (value) {
      'required' => RequirementStatus.required,
      'not_required' => RequirementStatus.notRequired,
      _ => RequirementStatus.unknown,
    };

String _requirementName(RequirementStatus s) => switch (s) {
      RequirementStatus.required => 'required',
      RequirementStatus.notRequired => 'not_required',
      RequirementStatus.unknown => 'unknown',
    };

/// snake_case 文字列から enum を復元（不明値は既定値でフォールバック）。
T _enumFromJson<T extends Enum>(List<T> values, String raw, T fallback) {
  final camel = _camel(raw);
  for (final v in values) {
    if (v.name == camel || v.name == raw) return v;
  }
  return fallback;
}

String _camel(String snake) {
  final parts = snake.split('_');
  return parts.first +
      parts
          .skip(1)
          .map((p) => p.isEmpty ? '' : p[0].toUpperCase() + p.substring(1))
          .join();
}

String _snake(String camel) => camel.replaceAllMapped(
      RegExp('[A-Z]'),
      (m) => '_${m.group(0)!.toLowerCase()}',
    );
