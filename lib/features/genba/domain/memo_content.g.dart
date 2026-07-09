// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'memo_content.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$MemoChecklistItemImpl _$$MemoChecklistItemImplFromJson(
        Map<String, dynamic> json) =>
    _$MemoChecklistItemImpl(
      id: json['id'] as String,
      text: json['text'] as String? ?? '',
      checked: json['checked'] as bool? ?? false,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$$MemoChecklistItemImplToJson(
        _$MemoChecklistItemImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'text': instance.text,
      'checked': instance.checked,
      'sort_order': instance.sortOrder,
    };

_$MemoBingoImpl _$$MemoBingoImplFromJson(Map<String, dynamic> json) =>
    _$MemoBingoImpl(
      size: (json['size'] as num?)?.toInt() ?? 3,
      cells:
          (json['cells'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              const <String>[],
      selected: (json['selected'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          const <int>[],
    );

Map<String, dynamic> _$$MemoBingoImplToJson(_$MemoBingoImpl instance) =>
    <String, dynamic>{
      'size': instance.size,
      'cells': instance.cells,
      'selected': instance.selected,
    };

_$MemoVoteOptionImpl _$$MemoVoteOptionImplFromJson(Map<String, dynamic> json) =>
    _$MemoVoteOptionImpl(
      id: json['id'] as String,
      text: json['text'] as String? ?? '',
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$$MemoVoteOptionImplToJson(
        _$MemoVoteOptionImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'text': instance.text,
      'sort_order': instance.sortOrder,
    };

_$MemoVoteRecordImpl _$$MemoVoteRecordImplFromJson(Map<String, dynamic> json) =>
    _$MemoVoteRecordImpl(
      voterId: json['voter_id'] as String,
      optionId: json['option_id'] as String,
    );

Map<String, dynamic> _$$MemoVoteRecordImplToJson(
        _$MemoVoteRecordImpl instance) =>
    <String, dynamic>{
      'voter_id': instance.voterId,
      'option_id': instance.optionId,
    };

_$MemoVoteImpl _$$MemoVoteImplFromJson(Map<String, dynamic> json) =>
    _$MemoVoteImpl(
      description: json['description'] as String? ?? '',
      options: (json['options'] as List<dynamic>?)
              ?.map((e) => MemoVoteOption.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <MemoVoteOption>[],
      votes: (json['votes'] as List<dynamic>?)
              ?.map((e) => MemoVoteRecord.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <MemoVoteRecord>[],
      allowDuplicate: json['allow_duplicate'] as bool? ?? false,
    );

Map<String, dynamic> _$$MemoVoteImplToJson(_$MemoVoteImpl instance) =>
    <String, dynamic>{
      'description': instance.description,
      'options': instance.options.map((e) => e.toJson()).toList(),
      'votes': instance.votes.map((e) => e.toJson()).toList(),
      'allow_duplicate': instance.allowDuplicate,
    };

_$MemoContentImpl _$$MemoContentImplFromJson(Map<String, dynamic> json) =>
    _$MemoContentImpl(
      checklist: (json['checklist'] as List<dynamic>?)
              ?.map(
                  (e) => MemoChecklistItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <MemoChecklistItem>[],
      bingo: json['bingo'] == null
          ? null
          : MemoBingo.fromJson(json['bingo'] as Map<String, dynamic>),
      vote: json['vote'] == null
          ? null
          : MemoVote.fromJson(json['vote'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$MemoContentImplToJson(_$MemoContentImpl instance) =>
    <String, dynamic>{
      'checklist': instance.checklist.map((e) => e.toJson()).toList(),
      'bingo': instance.bingo?.toJson(),
      'vote': instance.vote?.toJson(),
    };
