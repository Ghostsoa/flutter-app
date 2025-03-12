// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'voice_setting.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VoiceSetting _$VoiceSettingFromJson(Map<String, dynamic> json) => VoiceSetting(
      voiceId: json['voice_id'] as String? ?? 'female-yujie',
      speed: (json['speed'] as num?)?.toDouble() ?? 1.0,
      vol: (json['vol'] as num?)?.toDouble() ?? 1.0,
      pitch: (json['pitch'] as num?)?.toInt() ?? 0,
      emotion: json['emotion'] as String? ?? 'happy',
      cacheLimit: (json['cache_limit'] as num?)?.toInt() ?? 20,
    );

Map<String, dynamic> _$VoiceSettingToJson(VoiceSetting instance) =>
    <String, dynamic>{
      'voice_id': instance.voiceId,
      'speed': instance.speed,
      'vol': instance.vol,
      'pitch': instance.pitch,
      'emotion': instance.emotion,
      'cache_limit': instance.cacheLimit,
    };
