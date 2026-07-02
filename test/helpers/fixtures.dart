import 'package:oshi_expedition/core/config/env.dart';
import 'package:oshi_expedition/features/genba/domain/genba.dart';

/// development + Supabase未設定 = デモモードの環境設定。
const demoEnv = AppEnv(
  flavor: Flavor.development,
  supabaseUrl: '',
  supabaseAnonKey: '',
  logLevelName: 'debug',
);

final fixedCreatedAt = DateTime.utc(2026, 1, 1);

Genba makeGenba({
  String id = 'genba-1',
  String ownerId = 'user-1',
  String artistName = 'テストアーティスト',
  String title = 'テスト公演',
  required DateTime eventDate,
  int? doorTimeMinutes,
  int? startTimeMinutes,
  int? endTimeMinutes,
  bool isCanceled = false,
  DateTime? manualEndedAt,
  RequirementStatus transportRequirement = RequirementStatus.unknown,
  RequirementStatus lodgingRequirement = RequirementStatus.unknown,
  bool? isExpedition,
}) {
  return Genba(
    id: id,
    ownerId: ownerId,
    artistName: artistName,
    title: title,
    eventDate: eventDate,
    doorTimeMinutes: doorTimeMinutes,
    startTimeMinutes: startTimeMinutes,
    endTimeMinutes: endTimeMinutes,
    isCanceled: isCanceled,
    manualEndedAt: manualEndedAt,
    transportRequirement: transportRequirement,
    lodgingRequirement: lodgingRequirement,
    isExpedition: isExpedition,
    createdAt: fixedCreatedAt,
    updatedAt: fixedCreatedAt,
  );
}

Ticket makeTicket({
  String id = 'ticket-1',
  String genbaId = 'genba-1',
  String ownerId = 'user-1',
  TicketAcquisition acquisition = TicketAcquisition.notApplied,
  String? seat,
}) {
  return Ticket(
    id: id,
    genbaId: genbaId,
    ownerId: ownerId,
    acquisitionStatus: acquisition,
    seat: seat,
    createdAt: fixedCreatedAt,
    updatedAt: fixedCreatedAt,
  );
}

GenbaTodo makeTodo({
  String id = 'todo-1',
  String genbaId = 'genba-1',
  String ownerId = 'user-1',
  String name = '銀テを拾う',
  bool isDone = false,
  DateTime? dueDate,
  TodoPriority priority = TodoPriority.normal,
}) {
  return GenbaTodo(
    id: id,
    genbaId: genbaId,
    ownerId: ownerId,
    name: name,
    isDone: isDone,
    dueDate: dueDate,
    priority: priority,
    createdAt: fixedCreatedAt,
    updatedAt: fixedCreatedAt,
  );
}
