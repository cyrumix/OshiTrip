import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/auth/local_data_scope.dart';
import '../../../core/error/failure.dart';
import '../../../core/error/result.dart';
import '../../../core/providers.dart';
import '../../../core/time/date_only.dart';
import '../../oshi/domain/oshi.dart';
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
    this.venueAddress = '',
    this.venueGooglePlaceId,
    this.doorTimeMinutes,
    this.startTimeMinutes,
    this.endTimeMinutes,
    this.performanceType,
    this.performanceTypeOther = '',
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

  /// 会場の住所・Google Place ID（会場のGoogle連携。候補選択で反映・保存する）。
  final String venueAddress;
  final String? venueGooglePlaceId;
  final int? doorTimeMinutes;
  final int? startTimeMinutes;
  final int? endTimeMinutes;
  final PerformanceType? performanceType;

  /// [PerformanceType.other] のときの補足自由入力。
  final String performanceTypeOther;
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
    String? venueAddress,
    String? venueGooglePlaceId,
    bool clearVenueGooglePlaceId = false,
    int? doorTimeMinutes,
    bool clearDoorTime = false,
    int? startTimeMinutes,
    bool clearStartTime = false,
    int? endTimeMinutes,
    bool clearEndTime = false,
    PerformanceType? performanceType,
    bool clearPerformanceType = false,
    String? performanceTypeOther,
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
      venueAddress: venueAddress ?? this.venueAddress,
      venueGooglePlaceId: clearVenueGooglePlaceId
          ? null
          : (venueGooglePlaceId ?? this.venueGooglePlaceId),
      doorTimeMinutes:
          clearDoorTime ? null : (doorTimeMinutes ?? this.doorTimeMinutes),
      startTimeMinutes:
          clearStartTime ? null : (startTimeMinutes ?? this.startTimeMinutes),
      endTimeMinutes:
          clearEndTime ? null : (endTimeMinutes ?? this.endTimeMinutes),
      performanceType: clearPerformanceType
          ? null
          : (performanceType ?? this.performanceType),
      performanceTypeOther: performanceTypeOther ?? this.performanceTypeOther,
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
        'venue_address': venueAddress,
        'venue_google_place_id': venueGooglePlaceId,
        'door_time_minutes': doorTimeMinutes,
        'start_time_minutes': startTimeMinutes,
        'end_time_minutes': endTimeMinutes,
        'performance_type': performanceType?.code,
        'performance_type_other': performanceTypeOther,
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
      venueAddress: (json['venue_address'] as String?) ?? '',
      venueGooglePlaceId: json['venue_google_place_id'] as String?,
      doorTimeMinutes: json['door_time_minutes'] as int?,
      startTimeMinutes: json['start_time_minutes'] as int?,
      endTimeMinutes: json['end_time_minutes'] as int?,
      performanceType:
          performanceTypeFromCode(json['performance_type'] as String?),
      performanceTypeOther: (json['performance_type_other'] as String?) ?? '',
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
        venueAddress: g.venueAddress ?? '',
        venueGooglePlaceId: g.venueGooglePlaceId,
        doorTimeMinutes: g.doorTimeMinutes,
        startTimeMinutes: g.startTimeMinutes,
        endTimeMinutes: g.endTimeMinutes,
        performanceType: g.performanceType,
        performanceTypeOther: g.performanceTypeOther ?? '',
        isExpedition: g.isExpedition,
        transportRequirement: g.transportRequirement,
        lodgingRequirement: g.lodgingRequirement,
      );
}

/// 引数: 編集対象の現場ID（null = 新規作成）。
class GenbaFormController
    extends AutoDisposeFamilyAsyncNotifier<GenbaFormState, String?> {
  String get _draftKey => arg == null ? 'genba_form_new' : 'genba_form_$arg';

  /// 現在の owner（未認証なら null）。下書きは owner 単位で分離する（C-01）。
  String? get _ownerId {
    final scope = ref.read(localDataScopeProvider);
    return scope is LocalDataScopeAuthenticated ? scope.ownerId : null;
  }

  Genba? _editing;

  @override
  Future<GenbaFormState> build(String? arg) async {
    // 認証状態の復元中（起動直後の一瞬）は「未認証」と確定させず、
    // 復元完了を待ってから owner を決める（前ownerの下書き/空状態を
    // 誤って確定させない, C-01 要件7）。
    final user = await ref.watch(currentUserProvider.future);
    final owner = user?.id;

    if (arg != null) {
      final aggregate =
          await ref.read(genbaRepositoryProvider).watchById(arg).first;
      final genba = aggregate?.genba;
      if (genba != null) {
        _editing = genba;
        return GenbaFormState.fromGenba(genba);
      }
    }
    if (owner == null) return const GenbaFormState();
    final draft = await ref.read(draftStoreProvider).load(owner, _draftKey);
    if (draft != null) {
      try {
        return GenbaFormState.fromDraftJson(
          jsonDecode(draft) as Map<String, dynamic>,
        );
      } catch (_) {
        // 壊れた下書きは破棄する。
        await ref.read(draftStoreProvider).clear(owner, _draftKey);
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
    final owner = _ownerId;
    if (owner == null) return;
    // 自動保存は完了を待たない。
    // ignore: unawaited_futures
    ref
        .read(draftStoreProvider)
        .save(owner, _draftKey, jsonEncode(next.toDraftJson()));
  }

  /// 推しグループを選択/解除する。グループを変更・解除したら、以前のグループに
  /// 属する推しメンバー ID は不正になるため必ずクリアする（同じグループを選び
  /// 直した場合は保持する）。アーティスト名の反映は presentation 側で行う。
  void selectOshiGroup(String? groupId, {String? artistName}) {
    mutate((s) {
      if (groupId == null) {
        return s.copyWith(clearOshiGroupId: true, oshiMemberIds: const []);
      }
      final groupChanged = s.oshiGroupId != groupId;
      return s.copyWith(
        oshiGroupId: groupId,
        artistName: artistName ?? s.artistName,
        oshiMemberIds: groupChanged ? const [] : s.oshiMemberIds,
      );
    });
  }

  /// 推しメンバーの選択トグル（複数選択）。選択中のグループに属する ID のみを
  /// 想定するが、ここでは単純に集合として増減させる（グループ変更時は
  /// [selectOshiGroup] がまとめてクリアする）。
  void toggleOshiMember(String memberId, bool selected) {
    mutate((s) {
      final ids = [...s.oshiMemberIds];
      if (selected) {
        if (!ids.contains(memberId)) ids.add(memberId);
      } else {
        ids.remove(memberId);
      }
      return s.copyWith(oshiMemberIds: ids);
    });
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

  /// 保存直前に、選択中の推しグループ・推しメンを実データ（現在ownerの
  /// [OshiRepository.watchAll]）と照合する。
  ///
  /// - グループが削除済み・別owner（owner分離により watchAll に現れない）なら
  ///   グループ・メンバー選択の両方を解除する。
  /// - メンバーは「選択中のグループに実在して初めて有効」とし、削除済み・
  ///   別グループ・別ownerのIDは黙って保存せず除外する。
  /// - 除外が発生した場合のみ利用者へ知らせるメッセージを返す（保存自体は
  ///   ブロックしない — オプショナルな関連付けのために現場登録全体を失敗
  ///   させるのは要件§9「事前のマイ推し登録を必須にしない」の意図に反する。
  ///   方針は docs/decisions.md に記録）。
  /// - **推しデータ自体の取得（[OshiRepository.watchAll]）が失敗した場合は
  ///   例外を外へ漏らさず [Err] を返す**。この場合は除外による安全な保存を
  ///   継続できない（実在確認そのものができないため）ため [submit] 側で
  ///   保存全体を中断する（R5再々レビュー）。
  Future<
      Result<
          ({
            String? groupId,
            List<String> memberIds,
            String? correctionMessage,
          })>> _validateOshiSelection(GenbaFormState form) async {
    if (form.oshiGroupId == null) {
      return Ok(
        (
          groupId: null,
          memberIds: const <String>[],
          correctionMessage: form.oshiMemberIds.isEmpty
              ? null
              : '推しグループが未選択のため、推しメンの選択もクリアしました',
        ),
      );
    }
    final List<OshiGroupWithMembers> groups;
    try {
      groups = await ref.read(oshiRepositoryProvider).watchAll().first;
    } catch (e) {
      return Err(StorageFailure(message: '推しデータの読み込みに失敗しました', cause: e));
    }
    final matchedGroup =
        groups.firstWhereOrNull((g) => g.group.id == form.oshiGroupId);
    if (matchedGroup == null) {
      // 削除済み、または別owner（owner分離により watchAll に現れない）。
      return const Ok(
        (
          groupId: null,
          memberIds: <String>[],
          correctionMessage: '選択していた推しグループが見つからないため、推しの選択を解除しました',
        ),
      );
    }
    final validMemberIds = matchedGroup.members.map((m) => m.id).toSet();
    final keptMemberIds =
        form.oshiMemberIds.where(validMemberIds.contains).toList();
    final droppedCount = form.oshiMemberIds.length - keptMemberIds.length;
    return Ok(
      (
        groupId: matchedGroup.group.id,
        memberIds: keptMemberIds,
        correctionMessage: droppedCount == 0
            ? null
            : '削除済みまたは別グループの推しメン$droppedCount件を選択から除外しました',
      ),
    );
  }

  /// 保存。成功時は保存した現場IDと、推し選択を安全側へ補正した場合の
  /// 案内メッセージ（無ければ null）を返す。
  Future<Result<({String id, String? oshiCorrectionMessage})>> submit() async {
    final form = state.valueOrNull;
    if (form == null || !form.isValid) {
      return const Err(
        ValidationFailure('グループ／アーティスト名・公演名・日付を入力してください'),
      );
    }
    final owner = _ownerId;
    if (owner == null) {
      return const Err(AuthFailure(message: 'ログインが必要です'));
    }
    final oshiResult = await _validateOshiSelection(form);
    final oshiFailure = oshiResult.failureOrNull;
    // 推しデータの取得自体に失敗した場合、実在確認ができないため安全な
    // 除外もできない。現場を不完全な状態で保存せず、ここで中断する
    // （R5再々レビュー）。
    if (oshiFailure != null) return Err(oshiFailure);
    final oshiValidation = oshiResult.valueOrNull!;
    final now = ref.read(clockProvider).now().toUtc();
    final base = _editing;
    final newEventDate = dateOnly(form.eventDate!);
    // 日程（公演日）を変更した場合、既存の手動終演時刻は「変更前の公演日」を
    // 前提にした値であり、そのまま持ち越すと変更後の公演日でも終演済み・
    // 思い出扱いに誤判定される（例: 過去日で終演済みにした後、未来日へ
    // 再スケジュールしても「もう終わった現場」に見えてしまう）。公演日が
    // 変わったら手動終演を解除し、新しい日程から状態を再導出させる（H-07）。
    final eventDateChanged = base != null && base.eventDate != newEventDate;
    final genba = Genba(
      id: base?.id ?? const Uuid().v4(),
      ownerId: base?.ownerId ?? owner,
      artistName: form.artistName.trim(),
      title: form.title.trim(),
      eventDate: newEventDate,
      oshiGroupId: oshiValidation.groupId,
      oshiMemberIds: oshiValidation.memberIds,
      venue: form.venue.trim().isEmpty ? null : form.venue.trim(),
      venueAddress:
          form.venueAddress.trim().isEmpty ? null : form.venueAddress.trim(),
      venueGooglePlaceId: form.venueGooglePlaceId,
      doorTimeMinutes: form.doorTimeMinutes,
      startTimeMinutes: form.startTimeMinutes,
      endTimeMinutes: form.endTimeMinutes,
      performanceType: form.performanceType,
      // 補足自由入力は「その他」のときだけ保持する（空は null）。
      performanceTypeOther: form.performanceType == PerformanceType.other &&
              form.performanceTypeOther.trim().isNotEmpty
          ? form.performanceTypeOther.trim()
          : null,
      performanceId: base?.performanceId,
      isExpedition: form.isExpedition,
      transportRequirement: form.transportRequirement,
      lodgingRequirement: form.lodgingRequirement,
      isCanceled: base?.isCanceled ?? false,
      manualEndedAt: eventDateChanged ? null : base?.manualEndedAt,
      createdAt: base?.createdAt ?? now,
      updatedAt: now,
    );
    final result = await ref.read(genbaRepositoryProvider).upsertGenba(genba);
    final failure = result.failureOrNull;
    if (failure != null) return Err(failure);
    await ref.read(draftStoreProvider).clear(owner, _draftKey);
    return Ok(
      (id: genba.id, oshiCorrectionMessage: oshiValidation.correctionMessage),
    );
  }
}

final genbaFormControllerProvider = AsyncNotifierProvider.autoDispose
    .family<GenbaFormController, GenbaFormState, String?>(
  GenbaFormController.new,
);
