import 'package:oshi_trip/core/config/env.dart';
import 'package:oshi_trip/features/genba/domain/genba.dart';
import 'package:oshi_trip/features/itinerary/domain/itinerary_entry.dart';
import 'package:oshi_trip/features/itinerary/domain/itinerary_leg.dart';
import 'package:oshi_trip/features/itinerary/domain/itinerary_plan.dart';
import 'package:oshi_trip/features/itinerary/domain/itinerary_spot.dart';
import 'package:oshi_trip/features/itinerary/domain/itinerary_spot_link.dart';
import 'package:oshi_trip/features/itinerary/domain/itinerary_value_origin.dart';
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

Transport makeTransportRef({
  String id = 'transport-1',
  String genbaId = 'genba-1',
  String ownerId = 'user-1',
  TransportDirection direction = TransportDirection.outbound,
  TransportMethod? method,
  String? fromPlace,
  String? toPlace,
}) {
  return Transport(
    id: id,
    genbaId: genbaId,
    ownerId: ownerId,
    direction: direction,
    method: method,
    fromPlace: fromPlace,
    toPlace: toPlace,
    createdAt: fixedCreatedAt,
    updatedAt: fixedCreatedAt,
  );
}

Lodging makeLodgingRef({
  String id = 'lodging-1',
  String genbaId = 'genba-1',
  String ownerId = 'user-1',
  String? name,
}) {
  return Lodging(
    id: id,
    genbaId: genbaId,
    ownerId: ownerId,
    name: name,
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

ItineraryPlan makeItineraryPlan({
  String id = 'plan-1',
  String genbaId = 'genba-1',
  String ownerId = 'user-1',
  String title = '遠征プラン',
  String? memo,
  DateTime? startDate,
  DateTime? endDate,
  String timeZoneId = 'Asia/Tokyo',
  String? coverImageLocalPath,
  int sortOrder = 0,
}) {
  return ItineraryPlan(
    id: id,
    genbaId: genbaId,
    ownerId: ownerId,
    title: title,
    memo: memo,
    startDate: startDate,
    endDate: endDate,
    timeZoneId: timeZoneId,
    coverImageLocalPath: coverImageLocalPath,
    sortOrder: sortOrder,
    createdAt: fixedCreatedAt,
    updatedAt: fixedCreatedAt,
  );
}

ItinerarySpot makeItinerarySpot({
  String id = 'spot-1',
  String planId = 'plan-1',
  String ownerId = 'user-1',
  ItinerarySpotSource source = ItinerarySpotSource.manual,
  String name = '展望台',
  ItinerarySpotCategory category = ItinerarySpotCategory.sightseeing,
  String? address,
  ItineraryValueOrigin dataOrigin = ItineraryValueOrigin.userProvided,
  String? rightsBasis,
  double? latitude,
  double? longitude,
  String? userImageLocalPath,
  String? memo,
}) {
  return ItinerarySpot(
    id: id,
    planId: planId,
    ownerId: ownerId,
    source: source,
    name: name,
    category: category,
    address: address,
    dataOrigin: dataOrigin,
    rightsBasis: rightsBasis,
    latitude: latitude,
    longitude: longitude,
    userImageLocalPath: userImageLocalPath,
    memo: memo,
    createdAt: fixedCreatedAt,
    updatedAt: fixedCreatedAt,
  );
}

ItinerarySpotLink makeItinerarySpotLink({
  String id = 'link-1',
  String spotId = 'spot-1',
  String ownerId = 'user-1',
  ItinerarySpotLinkKind kind = ItinerarySpotLinkKind.official,
  String url = 'https://example.com',
  String? label,
  int sortOrder = 0,
}) {
  return ItinerarySpotLink(
    id: id,
    spotId: spotId,
    ownerId: ownerId,
    kind: kind,
    url: url,
    label: label,
    sortOrder: sortOrder,
    createdAt: fixedCreatedAt,
    updatedAt: fixedCreatedAt,
  );
}

ItineraryEntry makeItineraryEntry({
  String id = 'entry-1',
  String planId = 'plan-1',
  String ownerId = 'user-1',
  ItineraryEntryKind kind = ItineraryEntryKind.note,
  String? spotId,
  String? transportId,
  String? lodgingId,
  String? titleOverride,
  DateTime? startAt,
  DateTime? endAt,
  DateTime? localDate,
  String? timeZoneId,
  int bufferBeforeMinutes = 0,
  int bufferAfterMinutes = 0,
  String? memo,
  int sortOrder = 0,
  DateTime? createdAt,
}) {
  return ItineraryEntry(
    id: id,
    planId: planId,
    ownerId: ownerId,
    kind: kind,
    spotId: spotId,
    transportId: transportId,
    lodgingId: lodgingId,
    titleOverride: titleOverride,
    startAt: startAt,
    endAt: endAt,
    localDate: localDate,
    timeZoneId: timeZoneId,
    bufferBeforeMinutes: bufferBeforeMinutes,
    bufferAfterMinutes: bufferAfterMinutes,
    memo: memo,
    sortOrder: sortOrder,
    createdAt: createdAt ?? fixedCreatedAt,
    updatedAt: fixedCreatedAt,
  );
}

ItineraryLeg makeItineraryLeg({
  String id = 'leg-1',
  String planId = 'plan-1',
  String ownerId = 'user-1',
  String originEntryId = 'entry-1',
  String destinationEntryId = 'entry-2',
  ItineraryLegSource source = ItineraryLegSource.manual,
  ItineraryTravelMode travelMode = ItineraryTravelMode.walking,
  DateTime? departureAt,
  DateTime? arrivalAt,
  int? durationMinutes,
  int? distanceMeters,
  int? fareAmountMinor,
  String? fareCurrency,
  ItineraryValueOrigin valueOrigin = ItineraryValueOrigin.userProvided,
  String? rightsBasis,
}) {
  return ItineraryLeg(
    id: id,
    planId: planId,
    ownerId: ownerId,
    originEntryId: originEntryId,
    destinationEntryId: destinationEntryId,
    source: source,
    travelMode: travelMode,
    departureAt: departureAt,
    arrivalAt: arrivalAt,
    durationMinutes: durationMinutes,
    distanceMeters: distanceMeters,
    fareAmountMinor: fareAmountMinor,
    fareCurrency: fareCurrency,
    valueOrigin: valueOrigin,
    rightsBasis: rightsBasis,
    createdAt: fixedCreatedAt,
    updatedAt: fixedCreatedAt,
  );
}
