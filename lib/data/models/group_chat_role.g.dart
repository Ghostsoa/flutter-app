// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'group_chat_role.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GroupChatRole _$GroupChatRoleFromJson(Map<String, dynamic> json) =>
    GroupChatRole(
      id: json['id'] as String?,
      name: json['name'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String?,
      description: json['description'] as String? ?? '',
      model: json['model'] as String? ?? 'gemini-2.0-flash',
      useAdvancedSettings: json['useAdvancedSettings'] as bool? ?? false,
      temperature: (json['temperature'] as num?)?.toDouble() ?? 0.7,
      topP: (json['topP'] as num?)?.toDouble() ?? 1.0,
      presencePenalty: (json['presencePenalty'] as num?)?.toDouble() ?? 0.0,
      frequencyPenalty: (json['frequencyPenalty'] as num?)?.toDouble() ?? 0.0,
      maxTokens: (json['maxTokens'] as num?)?.toInt() ?? 2000,
    );

Map<String, dynamic> _$GroupChatRoleToJson(GroupChatRole instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'avatarUrl': instance.avatarUrl,
      'description': instance.description,
      'model': instance.model,
      'useAdvancedSettings': instance.useAdvancedSettings,
      'temperature': instance.temperature,
      'topP': instance.topP,
      'presencePenalty': instance.presencePenalty,
      'frequencyPenalty': instance.frequencyPenalty,
      'maxTokens': instance.maxTokens,
    };
