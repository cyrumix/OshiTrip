import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../../../core/providers.dart';
import '../../../core/time/date_only.dart';
import '../domain/genba.dart';

/// 現場作成/編集フォームの状態。下書きとして自動保存され再開できる（§2.1）。
class GenbaFormState {
  const GenbaFormState({
    this.artistName = '',
    this.title = '',
    this.eventDate,
    this.oshiGroupId,
    this.oshiMemberIds = const [],
    this.venue = '',
    this.doorTimeMinutes,
    this.startTimeMinutes,
    this.endTimeMinutes,
    this.performanceType = '',
    this.isExpedition,
    this.transportRequirement = RequirementStatus.unknown,
    this.lodgingRequirement = RequirementStatus.unknown,
    this.restoredFromDraft = false,
  });

  final String artistName;
  final String title;
  final DateTime? eventDate;
  final String? oshiGroupId;
  final List<String> oshiMemberIds;
  final String venue;
  final int? doorTimeMinutes;
  final int? startTimeMinutes;
  final int? endTimeMinutes;
  final String performanceType;
  final bool? isExpedition;
  final RequirementStatus transportRequirement;
  final RequirementStatus lodgingRequirement;

  /// 下書きから復元されたか（UIで「下書きを復元しました」表示用）。
  final bool restoredFromDraft;

  bool get isValid =>
      artistName.trim().isNotEmpty &&
      title.trim().isNotEmpty &&
      eventDate != null;

  GenbaFormState copyWith({
    String? artistName,
    String? title,
    DateTime? eventDate,
    bool clearEventDate = false,
    String? oshiGroupId,
    bool clearOshiGroupId = false,
    List<String>? oshiMemberIds,
    String? venue,
    int? doorTimeMinutes,
    bool clearDoorTime = false,
    int? startTimeMinutes,
    bool clearStartTime = false,
    int? endTimeMinutes,
    bool clearEndTime = false,
    String? performanceType,
    bool? isExpedition,
    bool clearIsExpedition = false,
    RequirementStatus? transportRequirement,
    RequirementStatus? lodgingRequirement,
    bool? restoredFromDraft,
  }) {
    return GenbaFormState(
      artistName: artistName ?? this.artistName,
      title: title ?? this.title,
      eventDate: clearEventDate ? null : (eventDate ?? this.eventDate),
      oshiGroupId: clearOshiGroupId ? null : (oshiGroupId ?? this.oshiGroupId),
      oshiMemberIds: oshiMemberIds ?? this.oshiMemberIds,
      venue: venue ?? this.venue,
      doorTimeMinutes:
          clearDoorTime ? null : (doorTimeMinutes ?? this.doorTimeMinutes),
      startTimeMinutes:
          clearStartTime ? null : (startTimeMinutes ?? this.startTimeMinutes),
      endTimeMinutes:
          clearEndTime ? null : (endTimeMinutes ?? this.endTimeMinutes),
      performanceType: performanceType ?? this.performanceType,
      isExpedition:
          clearIsExpedition ? null : (isExpedition ?? this.isExpedition),
      transportRequirement: transportRequirement ?? this.transportRequirement,
      lodgingRequirement: lodgingRequirement ?? this.lodgingRequirement,
      restoredFromDraft: restoredFromDraft ?? this.restoredFromDraft,
    );
  }

  Map<String, dynamic> toDraftJson() => {
        'artist_name': artistName,
        'title': title,
        'event_date': eventDate == null ? null : formatDateOnly(eventDate!),
        'oshi_group_id': oshiGroupId,
        'oshi_member_ids': oshiMemberIds,
        'venue': venue,
        'door_time_minutes': doorTimeMinutes,
        'start_time_minutes': startTimeMinutes,
        'end_time_minutes': endTimeMinutes,
        'performance_type': performanceType,
        'is_expedition': isExpedition,
        'transport_requirement': transportRequirement.name,
        'lodging_requirement': lodgingRequirement.name,
      };

  static GenbaFormState fromDraftJson(Map<String, dynamic> json) {
    RequirementStatus req(String? name) => RequirementStatus.values.firstWhere(
          (r) => r.name == name,
          orElse: () => RequirementStatus.unknown,
        );
    return GenbaFormState(
      artistName: (json['artist_name'] as String?) ?? '',
      title: (json['title'] as String?) ?? '',
      eventDate: json['event_date'] == null
          ? null
          : parseDateOnly(json['event_date'] as String),
      oshiGroupId: json['oshi_group_id'] as String?,
      oshiMemberIds:
          ((json['oshi_member_ids'] as List<dynamic>?) ?? const []).cast(),
      venue: (json['venue'] as String?) ?? '',
      doorTimeMinutes: json['door_time_minutes'] as int?,
      startTimeMinutes: json['start_time_minutes'] as int?,
      endTimeMinutes: json['end_time_minutes'] as int?,
      performanceType: (json['performance_type'] as String?) ?? '',
      isExpedition: json['is_expedition'] as bool?,
      transportRequirement: req(json['transport_requirement'] as String?),
      lodgingRequirement: req(json['lodging_requirement'] as String?),
      restoredFromDraft: true,
    );
  }

  static GenbaFormState fromGenba(Genba g) => GenbaFormState(
        artistName: g.artistName,
        title: g.title,
        eventDate: g.eventDate,
        oshiGroupId: g.oshiGroupId,
        oshiMemberIds: g.oshiMemberIds,
        venue: g.venue ?? '',
        doorTimeMinutes: g.doorTimeMinutes,
        startTimeMinutes: g.startTimeMinutes,
        endTimeMinutes: g.endTimeMinutes,
        performanceType: g.performanceType ?? '',
        isExpedition: g.isExpedition,
        transportRequirement: g.transportRequirement,
        lodgingRequirement: g.lodgingRequirement,
      );
}

/// 引数: 編集対象の現場ID（null = 新規作成）。
class GenbaFormController
    extends AutoDisposeFamilyAsyncNotifier<GenbaFormState, String?> {
  String get _draftKey => arg == null ? 'genba_form_new' : 'genba_form_$arg';

  Genba? _editing;

  @override
  Future<GenbaFormState> build(String? arg) async {
    if (arg != null) {
      final aggregate =
          await ref.read(genbaRepositoryProvider).watchById(arg).first;
      final genba = aggregate?.genba;
      if (genba != null) {
        _editing = genba;
        return GenbaFormState.fromGenba(genba);
      }
    }
    final draft = await ref.read(draftStoreProvider).load(_draftKey);
    if (draft != null) {
      try {
        return GenbaFormState.fromDraftJson(
          jsonDecode(draft) as Map<String, dynamic>,
        );
      } catch (_) {
        // 壊れた下書きは破棄する。
        await ref.read(draftStoreProvider).clear(_draftKey);
      }
    }
    return const GenbaFormState();
  }

  /// フィールド更新＋下書き自動保存。
  /// （`update` は AsyncNotifier の既存メンバーと衝突するため `mutate`）
  void mutate(GenbaFormState Function(GenbaFormState s) transform) {
    final current = state.valueOrNull ?? const GenbaFormState();
    final next = transform(current);
    state = AsyncData(next);
    // 自動保存は完了を待たない。
    // ignore: unawaited_futures
    ref
        .read(draftStoreProvider)
        .save(_draftKey, jsonEncode(next.toDraftJson()));
  }

  /// 遠征の有無の回答から交通・宿泊の要否既定値も設定する。
  void setExpedition(bool? value) {
    mutate((s) {
      if (value == null) {
        return s.copyWith(
          clearIsExpedition: true,
          transportRequirement: RequirementStatus.unknown,
          lodgingRequirement: RequirementStatus.unknown,
        );
      }
      return s.copyWith(
        isExpedition: value,
        transportRequirement:
            value ? RequirementStatus.required : RequirementStatus.notRequired,
        lodgingRequirement:
            value ? RequirementStatus.required : RequirementStatus.notRequired,
      );
    });
  }

  /// 保存。成功時は保存した現場IDを返す。
  Future<Result<String>> submit() async {
    final form = state.valueOrNull;
    if (form == null || !form.isValid) {
      return const Err(
        ValidationFailure('グループ／アーティスト名・公演名・日付を入力してください'),
      );
    }
    final owner = ref.read(authRepositoryProvider).currentUser?.id;
    if (owner == null) {
      return const Err(AuthFailure(message: 'ログインが必要です'));
    }
    final now = ref.read(clockProvider).now().toUtc();
    final base = _editing;
    final genba = Genba(
      id: base?.id ?? const Uuid().v4(),
      ownerId: base?.ownerId ?? owner,
      artistName: form.artistName.trim(),
      title: form.title.trim(),
      eventDate: dateOnly(form.eventDate!),
      oshiGroupId: form.oshiGroupId,
      oshiMemberIds: form.oshiMemberIds,
      venue: form.venue.trim().isEmpty ? null : form.venue.trim(),
      doorTimeMinutes: form.doorTimeMinutes,
      startTimeMinutes: form.startTimeMinutes,
      endTimeMinutes: form.endTimeMinutes,
      performanceType: form.performanceType.trim().isEmpty
          ? null
          : form.performanceType.trim(),
      performanceId: base?.performanceId,
      isExpedition: form.isExpedition,
      transportRequirement: form.transportRequirement,
      lodgingRequirement: form.lodgingRequirement,
      isCanceled: base?.isCanceled ?? false,
      manualEndedAt: base?.manualEndedAt,
      createdAt: base?.createdAt ?? now,
      updatedAt: now,
    );
    final result = await ref.read(genbaRepositoryProvider).upsertGenba(genba);
    final failure = result.failureOrNull;
    if (failure != null) return Err(failure);
    await ref.read(draftStoreProvider).clear(_draftKey);
    return Ok(genba.id);
  }
}

final genbaFormControllerProvider = AsyncNotifierProvider.autoDispose
    .family<GenbaFormController, GenbaFormState, String?>(
  GenbaFormController.new,
);
