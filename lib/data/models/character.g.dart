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
      greeting: json['greeting'] as String?,
      useMarkdown: json['useMarkdown'] as bool? ?? false,
      useAlgorithmFormat: json['useAlgorithmFormat'] as bool? ?? true,
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
      model: json['model'] as String? ?? 'gemini-2.0-flash',
      useAdvancedSettings: json['useAdvancedSettings'] as bool? ?? false,
      temperature: (json['temperature'] as num?)?.toDouble() ?? 0.7,
      topP: (json['topP'] as num?)?.toDouble() ?? 1.0,
      presencePenalty: (json['presencePenalty'] as num?)?.toDouble() ?? 0.0,
      frequencyPenalty: (json['frequencyPenalty'] as num?)?.toDouble() ?? 0.0,
      maxTokens: (json['maxTokens'] as num?)?.toInt() ?? 2000,
      streamResponse: json['streamResponse'] as bool? ?? true,
      enableDistillation: json['enableDistillation'] as bool? ?? false,
      distillationRounds: (json['distillationRounds'] as num?)?.toInt() ?? 20,
      distillationModel:
          json['distillationModel'] as String? ?? 'gemini-distill',
    );

Map<String, dynamic> _$CharacterToJson(Character instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'coverImageUrl': instance.coverImageUrl,
      'userSetting': instance.userSetting,
      'greeting': instance.greeting,
      'useMarkdown': instance.useMarkdown,
      'useAlgorithmFormat': instance.useAlgorithmFormat,
      'hasStatus': instance.hasStatus,
      'statusList': instance.statusList,
      'backgroundOpacity': instance.backgroundOpacity,
      'userBubbleColor': instance.userBubbleColor,
      'aiBubbleColor': instance.aiBubbleColor,
      'userTextColor': instance.userTextColor,
      'aiTextColor': instance.aiTextColor,
      'model': instance.model,
      'useAdvancedSettings': instance.useAdvancedSettings,
      'temperature': instance.temperature,
      'topP': instance.topP,
      'presencePenalty': instance.presencePenalty,
      'frequencyPenalty': instance.frequencyPenalty,
      'maxTokens': instance.maxTokens,
      'streamResponse': instance.streamResponse,
      'enableDistillation': instance.enableDistillation,
      'distillationRounds': instance.distillationRounds,
      'distillationModel': instance.distillationModel,
    };
