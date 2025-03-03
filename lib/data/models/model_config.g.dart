// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'model_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ModelConfig _$ModelConfigFromJson(Map<String, dynamic> json) => ModelConfig(
      model: json['model'] as String,
      temperature: (json['temperature'] as num?)?.toDouble() ?? 0.7,
      topP: (json['topP'] as num?)?.toDouble() ?? 1.0,
      maxTokens: (json['maxTokens'] as num?)?.toInt() ?? 8196,
      presencePenalty: (json['presencePenalty'] as num?)?.toDouble() ?? 0.0,
      frequencyPenalty: (json['frequencyPenalty'] as num?)?.toDouble() ?? 0.0,
      streamResponse: json['streamResponse'] as bool? ?? true,
      enableDistillation: json['enableDistillation'] as bool? ?? false,
      distillationRounds: (json['distillationRounds'] as num?)?.toInt() ?? 20,
      distillationModel:
          json['distillationModel'] as String? ?? 'gemini-1.5-pro',
    );

Map<String, dynamic> _$ModelConfigToJson(ModelConfig instance) =>
    <String, dynamic>{
      'model': instance.model,
      'temperature': instance.temperature,
      'topP': instance.topP,
      'maxTokens': instance.maxTokens,
      'presencePenalty': instance.presencePenalty,
      'frequencyPenalty': instance.frequencyPenalty,
      'streamResponse': instance.streamResponse,
      'enableDistillation': instance.enableDistillation,
      'distillationRounds': instance.distillationRounds,
      'distillationModel': instance.distillationModel,
    };
