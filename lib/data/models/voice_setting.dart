import 'package:json_annotation/json_annotation.dart';

part 'voice_setting.g.dart';

@JsonSerializable()
class VoiceSetting {
  @JsonKey(name: 'voice_id', defaultValue: 'female-yujie')
  final String voiceId;

  @JsonKey(defaultValue: 1.0)
  final double speed;

  @JsonKey(defaultValue: 1.0)
  final double vol;

  @JsonKey(defaultValue: 0)
  final int pitch;

  @JsonKey(defaultValue: 'happy')
  final String emotion;

  @JsonKey(name: 'cache_limit', defaultValue: 20)
  final int cacheLimit;

  const VoiceSetting({
    required this.voiceId,
    required this.speed,
    required this.vol,
    required this.pitch,
    required this.emotion,
    required this.cacheLimit,
  });

  factory VoiceSetting.fromJson(Map<String, dynamic> json) =>
      _$VoiceSettingFromJson(json);

  Map<String, dynamic> toJson() => _$VoiceSettingToJson(this);

  VoiceSetting copyWith({
    String? voiceId,
    double? speed,
    double? vol,
    int? pitch,
    String? emotion,
    int? cacheLimit,
  }) {
    return VoiceSetting(
      voiceId: voiceId ?? this.voiceId,
      speed: speed ?? this.speed,
      vol: vol ?? this.vol,
      pitch: pitch ?? this.pitch,
      emotion: emotion ?? this.emotion,
      cacheLimit: cacheLimit ?? this.cacheLimit,
    );
  }

  static const VoiceSetting defaultSetting = VoiceSetting(
    voiceId: 'female-yujie',
    speed: 1.0,
    vol: 1.0,
    pitch: 0,
    emotion: 'happy',
    cacheLimit: 20,
  );
}
