// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'group_chat.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GroupChat _$GroupChatFromJson(Map<String, dynamic> json) => GroupChat(
      id: json['id'] as String?,
      name: json['name'] as String,
      setting: json['setting'] as String?,
      greeting: json['greeting'] as String?,
      backgroundImageData: json['backgroundImageData'] as String?,
      useMarkdown: json['useMarkdown'] as bool? ?? false,
      showDecisionProcess: json['showDecisionProcess'] as bool? ?? false,
      streamResponse: json['streamResponse'] as bool? ?? true,
      enableDistillation: json['enableDistillation'] as bool? ?? false,
      distillationRounds: (json['distillationRounds'] as num?)?.toInt() ?? 20,
      distillationModel: json['distillationModel'] as String?,
      roles: (json['roles'] as List<dynamic>)
          .map((e) => GroupChatRole.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$GroupChatToJson(GroupChat instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'setting': instance.setting,
      'greeting': instance.greeting,
      'backgroundImageData': instance.backgroundImageData,
      'useMarkdown': instance.useMarkdown,
      'showDecisionProcess': instance.showDecisionProcess,
      'streamResponse': instance.streamResponse,
      'enableDistillation': instance.enableDistillation,
      'distillationRounds': instance.distillationRounds,
      'distillationModel': instance.distillationModel,
      'roles': instance.roles,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };
