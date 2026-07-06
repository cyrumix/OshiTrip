import 'package:oshi_trip/core/config/env.dart';
import 'package:oshi_trip/features/genba/domain/genba.dart';
import 'package:oshi_trip/features/templates/domain/todo_template.dart';

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
  String? venue,
  String? oshiGroupId,
  int? doorTimeMinutes,
  int? startTimeMinutes,
  int? endTimeMinutes,
  bool isCanceled = false,
  AttendanceStatus attendanceStatus = AttendanceStatus.planned,
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
    venue: venue,
    oshiGroupId: oshiGroupId,
    doorTimeMinutes: doorTimeMinutes,
    startTimeMinutes: startTimeMinutes,
    endTimeMinutes: endTimeMinutes,
    isCanceled: isCanceled,
    attendanceStatus: attendanceStatus,
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
  TodoItemType type = TodoItemType.todo,
  bool isDone = false,
  DateTime? dueDate,
  String? assignee,
  String? memo,
  int sortOrder = 0,
  TodoPriority priority = TodoPriority.normal,
}) {
  return GenbaTodo(
    id: id,
    genbaId: genbaId,
    ownerId: ownerId,
    name: name,
    type: type,
    isDone: isDone,
    dueDate: dueDate,
    assignee: assignee,
    memo: memo,
    sortOrder: sortOrder,
    priority: priority,
    createdAt: fixedCreatedAt,
    updatedAt: fixedCreatedAt,
  );
}

TodoTemplate makeTemplate({
  String id = 'tpl-1',
  String ownerId = 'user-1',
  String name = 'マイテンプレート',
  TodoItemType itemType = TodoItemType.todo,
}) {
  return TodoTemplate(
    id: id,
    ownerId: ownerId,
    name: name,
    itemType: itemType,
    createdAt: fixedCreatedAt,
    updatedAt: fixedCreatedAt,
  );
}

TodoTemplateItem makeTemplateItem({
  String id = 'tpl-item-1',
  String templateId = 'tpl-1',
  String ownerId = 'user-1',
  String name = '項目',
  TodoPriority? priority,
  String? memo,
  int sortOrder = 0,
}) {
  return TodoTemplateItem(
    id: id,
    templateId: templateId,
    ownerId: ownerId,
    name: name,
    priority: priority,
    memo: memo,
    sortOrder: sortOrder,
    createdAt: fixedCreatedAt,
    updatedAt: fixedCreatedAt,
  );
}
