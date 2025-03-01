// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'character.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CharacterStatus _$CharacterStatusFromJson(Map<String, dynamic> json) =>
    CharacterStatus(
      name: json['name'] as String,
      type: json['type'] as String,
      value: json['value'] as String?,
      numberValue: (json['numberValue'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$CharacterStatusToJson(CharacterStatus instance) =>
    <String, dynamic>{
      'name': instance.name,
      'type': instance.type,
      'value': instance.value,
      'numberValue': instance.numberValue,
    };

Character _$CharacterFromJson(Map<String, dynamic> json) => Character(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      coverImageUrl: json['coverImageUrl'] as String?,
      userSetting: json['userSetting'] as String?,
      useMarkdown: json['useMarkdown'] as bool? ?? false,
      hasStatus: json['hasStatus'] as bool? ?? false,
      statusList: (json['statusList'] as List<dynamic>?)
              ?.map((e) => CharacterStatus.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      backgroundOpacity: (json['backgroundOpacity'] as num?)?.toDouble() ?? 0.5,
      userBubbleColor: json['userBubbleColor'] as String? ?? '#2196F3',
      aiBubbleColor: json['aiBubbleColor'] as String? ?? '#1A1A1A',
      userTextColor: json['userTextColor'] as String? ?? '#FFFFFF',
      aiTextColor: json['aiTextColor'] as String? ?? '#FFFFFF',
    );

Map<String, dynamic> _$CharacterToJson(Character instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'coverImageUrl': instance.coverImageUrl,
      'userSetting': instance.userSetting,
      'useMarkdown': instance.useMarkdown,
      'hasStatus': instance.hasStatus,
      'statusList': instance.statusList,
      'backgroundOpacity': instance.backgroundOpacity,
      'userBubbleColor': instance.userBubbleColor,
      'aiBubbleColor': instance.aiBubbleColor,
      'userTextColor': instance.userTextColor,
      'aiTextColor': instance.aiTextColor,
    };
